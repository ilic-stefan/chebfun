function v = prod(f, varargin)
%PROD  Product integral of a chebfun2. 
% 
%   prod(F) returns the chebfun exp(  sum(log(F)) )
% 
%   prod(F,DIM) returns the chebfun exp( sum(log(F),DIM) )
% 
% See also CUMPROD.

% Copyright 2013 by The University of Oxford and The Chebfun Developers.
% See http://www.maths.ox.ac.uk/chebfun/ for Chebfun information.

if ( nargin == 1 ) 
    dim = 1; 
else
    dim = varargin{1}; 
end

v = exp( sum( log(f), dim ) );

end