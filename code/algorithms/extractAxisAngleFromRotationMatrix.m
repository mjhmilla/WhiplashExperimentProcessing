function [u,theta] = extractAxisAngleFromRotationMatrix(R)
%%
% Formula to convert a rotation matrix to an axis angle representation 
% taken from Wikipedia
% https://en.wikipedia.org/wiki/Rotation_matrix#Conversion_from_rotation_matrix_to_axis%E2%80%93angle
%
% @author Matthew Millard
% @date 2023/ 01/ 02
%
% @param    R: a 3x3 rotation matrix
% @returns  u: the axis about which the rotation is completed
% @returns  theta: the angle in radians of the rotation
%%

%assert(size(R,1)==3);
%assert(size(R,2)==3);
numericalTolerance = 1e-6;

%The cross-product matrix of u is given by 
%
% uX = R-R'
%
% but only if R-R' is not equal to zero

%assert(norm(R-R') > numericalTolerance);

%
%If you're unfamiliar with the cross-product matrix, its given by
%
% uX = [ 0, -z, y ]
%      [ z,  0,-x ]
%      [-y,  x, 0 ]
%
% Multiplying uX by another vector b is equivalent to taking the cross product
% of u and b.
RRt = R-R';

u = [RRt(3,2);...
     RRt(1,3);...
     RRt(2,1)];

%Normalize u
u = u./sqrt(u'*u);
%assert( abs( (u'*u)-1 ) < numericalTolerance );


uX = [       0,-u(3,1), u(2,1);...
        u(3,1),      0,-u(1,1);...
       -u(2,1), u(1,1),     0];
%assert(norm(uX'+uX)<numericalTolerance);

%Find the angle by forming a vector v that's perpendicular to u, rotating it
%using R, and then using basic trigonometry to extract theta.

[val, idx] = min(abs(u));
x         = zeros(3,1);
x(idx,1)  = 1;

v = uX*x;
v = v./sqrt(v'*v);

%assert(abs(u'*v) < numericalTolerance);

w = R*v;
%assert( abs(w'*w -1) < numericalTolerance);

%Using the cross product definition (v x w = |v||w|sin(theta)u) extract the 
%signed version of theta 

vX = [       0, -v(3,1),  v(2,1); ...
        v(3,1),       0, -v(1,1); ...
       -v(2,1),  v(1,1),      0];

%assert(norm(vX+vX') < numericalTolerance);

wM = sqrt(w'*w);
vM = sqrt(v'*v);

vXw   = vX*w;
theta = asin( (vXw ./ (wM*vM))' * u );





