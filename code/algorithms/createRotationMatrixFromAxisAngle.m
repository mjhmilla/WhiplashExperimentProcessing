function R = createRotationMatrixFromAxisAngle(ux,uy,uz,th)
%%
% Formula to convert axis angle representation to a rotation matrix
% taken from Wikipedia
%  
% http://en.wikipedia.org/wiki/Rotation_matrix#Conversion_from_and_to_axis-angle
%
% @author Matthew Millard
% @date 2013/ 6/ 14
%%
R = zeros(3,3);

c = cos(th);
s = sin(th);

R(1,1) = c + ux*ux*(1-c);
R(1,2) = ux*uy*(1-c)-uz*s;
R(1,3) = ux*uz*(1-c)+uy*s;

R(2,1) = uy*ux*(1-c)+uz*s;
R(2,2) = c + uy*uy*(1-c);
R(2,3) = uy*uz*(1-c)-ux*s;

R(3,1) = uz*ux*(1-c)-uy*s;
R(3,2) = uz*uy*(1-c)+ux*s;
R(3,3) = c + uz*uz*(1-c);

