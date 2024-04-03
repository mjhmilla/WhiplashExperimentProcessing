function xyzw = convertRotationMatrixToQuaternion(rm)
%%
%
% Code from:
% https://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/
%%

m00 =rm(1,1);
m01 =rm(1,2);
m02 =rm(1,3);

m10 =rm(2,1);
m11 =rm(2,2);
m12 =rm(2,3);

m20 =rm(3,1);
m21 =rm(3,2);
m22 =rm(3,3);

t=m00+m11+m22;

xyzw = zeros(1,4);

if(t > 0)
  s = 0.5 / sqrt(t+1);
  w = 0.25 / s;
  xyzw(1,1) = ( m21 - m12 ) * s;
  xyzw(1,2) = ( m02 - m20 ) * s;
  xyzw(1,3) = ( m10 - m01 ) * s;
  xyzw(1,4) = w;
elseif ((m00 > m11) && (m00 > m22)) 
  s = sqrt(1.0 + m00 - m11 - m22) * 2; 
  qw = (m21 - m12) / s;
  xyzw(1,1) = 0.25 * s;
  xyzw(1,2) = (m01 + m10) / s; 
  xyzw(1,3) = (m02 + m20) / s;
  xyzw(1,4) = qw;
elseif (m11 > m22)  
  s = sqrt(1.0 + m11 - m00 - m22) * 2;
  qw = (m02 - m20) / s;
  xyzw(1,1) = (m01 + m10) / s; 
  xyzw(1,2) = 0.25 * s;
  xyzw(1,3) = (m12 + m21) / s;
  xyzw(1,4) = qw;
else  
  s = sqrt(1.0 + m22 - m00 - m11) * 2; 
  qw = (m10 - m01) / s;
  xyzw(1,1) = (m02 + m20) / s;
  xyzw(1,2) = (m12 + m21) / s;
  xyzw(1,3) = 0.25 * s;
  xyzw(1,4) = qw;
end

%Normalize the quaternion
%qm = sqrt( sum(xyzw.^2));
%xyzw = xyzw./qm;