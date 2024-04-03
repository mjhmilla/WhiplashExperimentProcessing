clc;
close all;
clear all;


addpath('algorithms');

%%
% Test the function that extracts the axis angle representation of a 
% rotation matrix
%%

%Check that the axis-angle functions work by
% 1. Creating a rotation matrix using a specificed axis and angle.
% 2. Extract the axis and angle from the rotation matrix
% 3. Make sure the axis and angle match in steps 1 and 2


numberOfTests       = 10;
numericalTolerance  = eps*100;

for iterationTest = 1:1:numberOfTests

    %A random normalized vector for our axis
    u0 = 2.*(rand(3,1)-[1;1;1].*0.5);
    u0 = u0./sqrt(u0'*u0);
    
    %A random angle between [-pi, pi]
    theta0 = rand(1,1)*(pi*0.5);
    
    %Generate the rotation matrix
    R = createRotationMatrixFromAxisAngle(u0(1,1),u0(2,1),u0(3,1),theta0);
    
    %Extract the axis and angle
    [u1, theta1] = extractAxisAngleFromRotationMatrix(R);
    
    %Make sure the extracted axis and angle matches the one used to create
    %the matrix
    
    uErr = u1-u0; %Should be a vector of zeros
    if(abs(uErr)>numericalTolerance)
        here=1;
    end    
    assert(abs(sqrt(uErr'*uErr)) < numericalTolerance);
    
    thetaErr = theta1-theta0;
    if(abs(thetaErr)>numericalTolerance)
        here=1;
    end
    assert(abs(thetaErr)< numericalTolerance);

end


%%
% An example of using extractAxisAngleFromRotationMatrix to get the 
% transformation from the torso frame to the head frame
%%

%Create a test rotation matrix that rotates a vector from the world frame
%to the head frame
uH     = [0;1;0];
thetaH = pi/5;

G_R_H = 

rmpath('algorithms');
