function out = isfinite(f)
%ISFINITE   Test if a FOURIERTECH is bounded.
%   ISFINITE(F) returns FALSE if F has any infinite values and TRUE otherwise.
%
% See also ISINF, ISNAN.

% Copyright 2014 by The University of Oxford and The Chebfun Developers. 
% See http://www.chebfun.org/ for Chebfun information.

% Check if values are finite:
out = all(isfinite(f.values(:)));

end
