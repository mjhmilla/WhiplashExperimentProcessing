clear all;
clc;
close all;

thZ1 = 15*(pi/180);
thY = 45*(pi/180);
thZ3 = 5*(pi/180);

%Rotation about the Z axis
Rz1 = [  cos(thZ1)    sin(thZ1)    0;...
        -sin(thZ1)   cos(thZ1)    0;...
        0           0           1];    
%Rotation about the Y axis    
Ry = [  cos(thY)    0       -sin(thY);...
        0           1       0;...
        sin(thY)    0       cos(thY)];

%Rotation about the Z axis
Rz3 = [  cos(thZ3)    sin(thZ3)    0;...
        -sin(thZ3)   cos(thZ3)    0;...
        0           0           1];

R = Rz3*(Ry*Rz1);

R = [0.8417361422 0.5398891247 0;
     -0.5398891247 0.8417361422 0;
     0 0 1];
%q_r = euler2quat([thZ1 thY thZ3]);

%%
%Make a quaternion from R
%%
t = R(1,1)+R(2,2)+R(3,3)+1;

m00 = R(1,1);
m01 = R(1,2);
m02 = R(1,3);

m10 = R(2,1);
m11 = R(2,2);
m12 = R(2,3);

m20 = R(3,1);
m21 = R(3,2);
m22 = R(3,3);

if t > 0
    S = 0.5 / sqrt(t);
    q(4) = 0.25 / S;
    q(1) = ( m21 - m12 ) * S;
    q(2) = ( m02 - m20 ) * S;
    q(3) = ( m10 - m01 ) * S;
else
  if (m00 > m11)&&(m00 > m22)  
   S = sqrt( 1.0 + m00 - m11 - m22 ) * 2; % S=4*qx 
   q(4) = (m12 - m21) / S;
   q(1) = 0.25 * S;
   q(2) = (m01 + m10) / S; 
   q(3) = (m02 + m20) / S; 
  elseif (m11 > m22)  
   S = sqrt( 1.0 + m11 - m00 - m22 ) * 2; % S=4*qy
   q(4) = (m02 - m20) / S;
   q(1) = (m01 + m10) / S; 
   q(2) = 0.25 * S;
   q(3) = (m12 + m21) / S; 
 else  
   S = sqrt( 1.0 + m22 - m00 - m11 ) * 2; % S=4*qz
   q(4) = (m01 - m10) / S;
   q(1) = (m02 + m20) / S; 
   q(2) = (m12 + m21) / S; 
   q(3) = 0.25 * S;
  end
     
end

%%
%Reconstruct R from q
%%

qx = q(1);
qy = q(2);
qz = q(3);
qw = q(4);

m00_t = 1 - 2*qy^2 - 2*qz^2;
m01_t = 2*qx*qy - 2*qz*qw;
m02_t = 2*qx*qz + 2*qy*qw;
m10_t = 2*qx*qy + 2*qz*qw;
m11_t = 1 - 2*qx^2 - 2*qz^2;
m12_t = 2*qy*qz - 2*qx*qw;
m20_t = 2*qx*qz - 2*qy*qw;
m21_t = 2*qy*qz + 2*qx*qw;
m22_t = 1 - 2*qx^2 - 2*qy^2;

R_t = [ m00_t m01_t m02_t; ...
        m10_t m11_t m12_t; ...
        m20_t m21_t m22_t];
    
disp(R);
disp(R_t);
disp(' ')
disp(q);
disp(' ');
disp(' ');
disp(quatrotate([-q(4),q(1),q(2),q(3)],[1,1,1]));
disp(' ');
disp((R*[1,1,1]')');