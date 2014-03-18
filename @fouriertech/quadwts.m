function w = quadwts(n)
%QUADWTS   Quadrature weights for equally spaced points from [-pi,pi)
%   QUADWTS(N) returns the N weights for trapezoid rule.
%

% Copyright 2014 by The University of Oxford and The Chebfun Developers.
% See http://www.chebfun.org for Chebfun information.

w = 2*pi/n*ones(1,n);

end
