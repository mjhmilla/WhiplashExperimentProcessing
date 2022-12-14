function rigidBodyData = moveRigidBodyDataToFrame(rigidBodyData,frame,offset)

%Rotate all of the rigid body data about the origin
for indexBody=1:1:length(rigidBodyData)
    here=1;
    for i=1:1:size(rigidBodyData(indexBody).xyzw,1)
        rmB0 = convertQuaternionToRotationMatrix( ...
                rigidBodyData(indexBody).xyzw(i,1),...
                rigidBodyData(indexBody).xyzw(i,2),...
                rigidBodyData(indexBody).xyzw(i,3),...
                rigidBodyData(indexBody).xyzw(i,4));

        %rm=rmB0;
        rm = rmB0*frame.rm;               
        rigidBodyData(indexBody).xyzw(i,:) =...
            convertRotationMatrixToQuaternion(rm);
        
        rigidBodyData(indexBody).r0B0(i,:) = ...
            (frame.rm*rigidBodyData(indexBody).r0B0(i,:)')';

    end

end

%Apply the offset vector to all data
rMN0v = ones(size(rigidBodyData(1).r0B0));
rMN0v(:,1) = rMN0v(:,1).*offset(1,1);
rMN0v(:,2) = rMN0v(:,2).*offset(1,2);
rMN0v(:,3) = rMN0v(:,3).*offset(1,3);

%Translate all of the frames by rMN0
for indexBody=1:1:length(rigidBodyData)
    rigidBodyData(indexBody).r0B0 = rigidBodyData(indexBody).r0B0+rMN0v; 
end