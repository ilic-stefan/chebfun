function [Q, R, E] = qr(f, outputFlag, methodFlag)
%QR   QR factorisation of an array-valued CHEBTECH.
%   [Q, R] = QR(F) returns a QR factorisation of F such that F = Q*R, where the
%   CHEBTECH Q is orthogonal (with respect to the continuous L^2 norm on [-1,1])
%   and of the same size as F and R is an m x m upper-triangular matrix when F
%   has m columns.
%
%   [Q, R, E] = QR(F) produces unitary Q, upper-triangular R, and a permutation
%   matrix E so that F*E = Q*R. The column permutation E is chosen to reduce
%   fill-in in R.
%
%   [Q, R, E] = QR(F, 'vector') returns the permutation information as a vector
%   instead of a matrix.  That is, E is a row vector such that F(:,E) = Q*R.
%   Similarly, [Q, R, E] = QR(F, 'matrix') returns a permutation matrix E. This
%   is the default behavior.
%
%   QR(F, 'vector', METHOD) or QR(F, 'vector', METHOD) specifies which method
%   to use in computing the QR factorisation. METHOD = 'built-in' will form a
%   weighted Legendre-Vandermonde matrix and orthogonalise this with the
%   standard Matlab QR algorithm. METHOD = 'householder' uses the technique
%   described in [1]. METHOD = 'built-in' is the default option.
%
%   [1] L.N. Trefethen, "Householder triangularization of a quasimatrix", IMA J
%   Numer Anal (2010) 30 (4): 887-897.

% Copyright 2014 by The University of Oxford and The Chebfun Developers.
% See http://www.chebfun.org/ for Chebfun information.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Developer note: Typically 'householder' will be slower than 'built-in', but
% should be more stable.
%
% Developer note: In the built-in approach, one could use a Chebyshev grid of
% double the size (rather than the Legendre grid), but given the complexity
% costs of QR vs. the cost of the transformation, it seems Legendre is
% preferable.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Deal with empty case:
if ( isempty(f) )
    Q = f;
    R = [];
    E = [];
    return
end

% Default options:
defaultMethod = 'built-in';
%defaultMethod = 'householder';
defaultOutput = 'matrix';

if ( nargin < 3 || isempty(methodFlag) )
    methodFlag = defaultMethod;
end
if ( nargin < 2 || isempty(outputFlag) )
    outputFlag = defaultOutput;
end

% If f has only one column we simply scale it.
if ( size(f, 2) == 1 )
    R = sqrt(innerProduct(f, f));
    Q = f./R;
    E = 1;
    return
end

% Simplify so that we don't do any extra work: (QR is O(m*n^2)? :/ )
f = simplify(f);

% Decide which algorithm to use:
if ( strcmpi(methodFlag, 'householder') )
    % Call Trefethen's Householder implementation:
    [Q, R, E] = qr_householder(f, outputFlag);
else
    % The 'built-in' algorithm. i.e., qeighted discrete QR():
    if ( nargout == 3 )
        [Q, R, E] = qr_builtin(f, outputFlag);
    else
        [Q, R] = qr_builtin(f, outputFlag);
    end
end

%% Update epslevel
% Since we don't know how to do this properly, we essentially assume that QR has
% condition number one. Therefore we assume Q has the same global accuracy as f,
% and simply factor out the new vscale. TODO: It may be sensible to include some
% knowledge of R here?
col_acc = f.epslevel.*f.vscale;  % Accuracy of each column in f.
glob_acc = max(col_acc);         % The best of these.
epslevelApprox = glob_acc./Q.vscale; % Scale out vscale of Q.
Q.epslevel = updateEpslevel(Q, epslevelApprox);

end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [f, R, E] = qr_builtin(f, outputFlag)

persistent WP invWP type
% Persistently store these matrices, which only depend on the length of the
% input (and the type of chebtech!), not the data. This is very helpful for
% CHEBFUN2 which relies heavily on QR.

% We must enforce that f.coeffs has at least as many rows as columns:
[n, m] = size(f);
if ( n < m )
    f = prolong(f, m);
    n = m;
end

% Project the values onto a Legendre grid: (where integrals of polynomials
% p_n*q_n will be computed exactly and on an n-point grid)
if ( (length(WP) ~= n && n <= 4000) || ((~isempty(type) && isa(f, type)) && n <= 4000)  )
    xc = f.chebpts(n);
    vc = f.barywts(n);
    [xl, wl, vl] = legpts(n);
    P = barymat(xl, xc, vc);     % Map from Chebyshev values to Legendre values.
    W = spdiags(sqrt(wl.'), 0, n, n); % Weighted QR with Gauss-Legendre weights.
    Winv = spdiags(1./sqrt(wl.'), 0, n, n);    % Undo the weighting used for QR.
    Pinv = barymat(xc, xl, vl); % Revert to Chebyshev grid (from Legendre grid).
    % Persistent storage:
    WP = W*P;
    invWP = Pinv*Winv;
    type = class(f);
end

if ( n <= 4000 )
    % Compute the weighted QR factorisation:
    values = f.coeffs2vals(f.coeffs);
    if ( nargout == 3 )
        [Q, R, E] = qr(WP * values, 0);
        % For consistency with the MATLAB QR behavior:
        if ( (nargin == 1) || ...
                ~(strcmpi(outputFlag, 'vector') || isequal(outputFlag, 0)) )
            % Return E in matrix form:
            I = eye(m);
            E = I(:,E);
        end
    else
        %converted = chebfun.ndct( f.coeffs );
        converted = WP * values;
        [Q, R] = qr(converted, 0);
    end
    
    % Revert to the Chebyshev grid (and remove the weight and enforce diag(R) >= 0).
    s = sign(diag(R));
    s(~s) = 1;
    S = spdiags(s, 0, m, m);
    Q = invWP*Q*S;                 % Fix Q.
    R = S*R;                       % Fix R.
    
    % Apply data to chebtech:
    f.coeffs = f.vals2coeffs(Q);   % Compute new coefficients.
    f.vscale = max(abs(Q), [], 1); % Update vscale
        
else
    % Got to use fast transforms now because we cannot store nxn matrices,
    % where n>>4000. (Same algorithm as when n <= 4000, except we never form
    % a large dense matrix.)
    
    % Compute the weighted QR factorisation:
    [ignored, wl, ignored] = legpts(n);
    W = spdiags(sqrt(wl.'), 0, n, n);
    if ( nargout == 3 )
        converted = W*chebfun.ndct( f.coeffs ); % does WP * values
        [Q, R, E] = qr( converted , 0);
        % For consistency with the MATLAB QR behavior:
        if ( (nargin == 1) || ...
                ~(strcmpi(outputFlag, 'vector') || isequal(outputFlag, 0)) )
            % Return E in matrix form:
            I = eye(m);
            E = I(:,E);
        end
    else
        converted = W*chebfun.ndct( f.coeffs ); % does WP * values
        [Q, R] = qr(converted, 0);
    end
    
    % Revert to the Chebyshev grid (and remove the weight and enforce diag(R) >= 0).
    s = sign(diag(R));
    s(~s) = 1;
    S = spdiags(s, 0, m, m);
    Winv = spdiags(1./sqrt(wl.'), 0, n, n);
    Q = Winv*Q*S;                 % Fix Q.
    Q_coeffs = leg2cheb( chebfun.idlt( Q ) );
    Q = f.coeffs2vals( Q_coeffs ); 
    R = S*R;                       % Fix R.
    
    % Apply data to chebtech:
    f.coeffs = Q_coeffs;           % Compute new coefficients.
    f.vscale = max(abs(Q), [], 1); % Update vscale     
    
end



end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [f, R, Eperm] = qr_householder(f, flag)

% Get some useful values
[n, numCols] = size(f);
tol = max(f.epslevel.*f.vscale);

% Make the discrete analog of f:
newN = 2*max(n, numCols);
A = get(prolong(f, newN), 'values');

% Create the Chebyshev nodes and quadrature weights:
x = f.chebpts(newN);
w = f.quadwts(newN);

% Define the inner product as an anonymous function:
ip = @(f, g) w * (conj(f) .* g);

% Generate a discrete E (Legendre-Chebyshev-Vandermonde matrix) directly:
E = ones(size(A));
E(:,2) = x;
for k = 3:numCols % Recurrence relation:
    E(:,k) = ((2*k - 3)*x.*E(:,k-1) - (k - 2)*E(:,k-2)) / (k - 1);
end
% Scaling:
for k = 1:numCols
    E(:,k) = E(:,k) * sqrt((2*k - 1) / 2);
end
% Call the abstract QR method:
[Q, R] = abstractQR(A, E, ip, @(v) norm(v, inf), tol);

% Compute the corresponding Chebyshev coefficients:
f.coeffs = f.vals2coeffs(Q);
% Trim the unneeded ones:
f.coeffs(newN/2+1:end,:) = [];

% Update the vscale:
f.vscale = getvscl(f);

% Additional output argument:
if ( nargout == 3 )
    if ( nargin == 2 && strcmp(flag, 'vector') )
        Eperm = 1:numCols;
    else
        Eperm = eye(numCols);
    end
end

end
