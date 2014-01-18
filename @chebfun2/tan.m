function f = tan( f )
% TAN   Tangent of a chebfun2.

% Copyright 2013 by The University of Oxford and The Chebfun Developers.
% See http://www.maths.ox.ac.uk/chebfun/ for Chebfun information.

% Empty check: 
if ( isempty( f ) ) 
    return
end

op = @(x,y) tan( feval( f, x, y ) ); % resample
f = chebfun2( op, f.domain );        % Call constructor.

end