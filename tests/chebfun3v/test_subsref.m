function pass = test_subsref(pref)
% Test Chebfun3v subsref() command.

if ( nargin == 0)
    pref = chebfunpref;
end
tol = 1000*pref.cheb3Prefs.chebfun3eps;

j = 1;

% Test recursive subsref:
f = chebfun3(@(x,y,z) sin(x.*y.*z));
F = [f; f; f];

G = F(1);
exactCore = G.core;

pass(j) = norm(exactCore(:) - F(1).core(:)) < tol;
j = j+1;

% Composition of a CHEBFUN3V (2 components) with three CHEBFUN3.
f1 = chebfun3(@(x,y,z) x);
f2 = chebfun3(@(x,y,z) y);
f3 = chebfun3(@(x,y,z) z);
G = chebfun3v(@(x,y,z) x + y, @(x,y,z) y);
H = G(f1, f2, f3);
pass(j) = ( norm(H - G) < tol );
j = j+1;

% Composition of a CHEBFUN3V (3 components) with three CHEBFUN3.
f1 = chebfun3(@(x,y,z) x);
f2 = chebfun3(@(x,y,z) y);
f3 = chebfun3(@(x,y,z) z);
G = chebfun3v(@(x,y,z) x + y, @(x,y,z) y, @(x,y,z) z);
H = G(f1, f2, f3);
pass(j) = ( norm(H - G) < tol );
j = j+1;

% Composition of a CHEBFUN3V (2 components) with three CHEBFUN2.
f1 = chebfun2(@(x,y) x);
f2 = chebfun2(@(x,y) y);
f3 = chebfun2(@(x,y) x+y);
G = chebfun3v(@(x,y,z) x + y, @(x,y,z) y + z);
H = G(f1, f2, f3);
H_true = chebfun2v(@(x,y) x + y, @(x,y) x + 2*y);
pass(j) = ( norm(H - H_true) < tol );
j = j+1;

% Composition of a CHEBFUN3V (3 components) with three CHEBFUN2.
f1 = chebfun2(@(x,y) x);
f2 = chebfun2(@(x,y) y);
f3 = chebfun2(@(x,y) x+y);
G = chebfun3v(@(x,y,z) x + y, @(x,y,z) y + z, @(x,y,z) x + z);
H = G(f1, f2, f3);
H_true = chebfun2v(@(x,y) x + y, @(x,y) x + 2*y, @(x,y) 2*x + y);
pass(j) = ( norm(H - H_true) < tol );
j = j+1;

% Composition of a CHEBFUN3V with a CHEBFUN2V.
G = chebfun3v(@(x,y,z) 2*x, @(x,y,z) y - x, @(x,y,z) z);
F = chebfun2v(@(x,y) x, @(x,y) y, @(x,y) x + y);
H = G(F);
H_true = chebfun2v(@(x,y) 2*x, @(x,y) y - x, @(x,y) x + y);
pass(j) = ( norm(H - H_true) < tol );
j = j+1;

% Composition of a CHEBFUN3V with a CHEBFUN3V.
G = chebfun3v(@(x,y,z) x + y + z, @(x,y,z) x - y);
F = chebfun3v(@(x,y,z) 2*x, @(x,y,z) x + y, @(x,y,z) z + 1);
H = G(F);
H_true = chebfun3v(@(x,y,z) 3*x + y + z + 1, @(x,y,z) x - y);
pass(j) = ( norm(H - H_true) < tol );

end