function [rigidBodyData, rigidBodyMarkerData] = ...
    moveDataToFrame(rigidBodyData,rigidBodyMarkerData,frame)



%Rotate all of the marker data about the origin
for indexMarker=1:1:length(rigidBodyMarkerData)
   for i = 1:1:size(rigidBodyMarkerData(indexMarker).r0M0,1)
       rigidBodyMarkerData(indexMarker).r0M0(i,:) = ...
           (frame.rm * rigidBodyMarkerData(indexMarker).r0M0(i,:)')';
   end
end


%Translate all of the marker data to bring the reference marker to the desired
%position at the first row that contains valid data
rMN0 = [0,0,0];
flag_setOffsetVector=0;
indexRefMarker=1;
frameNumber=1;
while indexRefMarker < length(rigidBodyMarkerData) && flag_setOffsetVector==0
    if(contains(rigidBodyMarkerData(indexRefMarker).markerName,...
            frame.markerName))
        frameNumber=1;
        while sum(isnan(rigidBodyMarkerData(indexRefMarker).r0M0(frameNumber,:))) > 0
            frameNumber=frameNumber+1;
        end
        rMN0 = frame.r0N0' - rigidBodyMarkerData(indexRefMarker).r0M0(frameNumber,:);
        %rMN0 = - rigidBodyMarkerData(indexRefMarker).r0M0(frameNumber,:);
        flag_setOffsetVector=1;
    else
        indexRefMarker=indexRefMarker+1;
    end
end

%Apply the offset vector to all data
rMN0v = ones(size(rigidBodyMarkerData(indexRefMarker).r0M0));
rMN0v(:,1) = rMN0v(:,1).*rMN0(1,1);
rMN0v(:,2) = rMN0v(:,2).*rMN0(1,2);
rMN0v(:,3) = rMN0v(:,3).*rMN0(1,3);

for indexMarker=1:1:length(rigidBodyMarkerData)
    rigidBodyMarkerData(indexMarker).r0M0 = ...
        rigidBodyMarkerData(indexMarker).r0M0 + rMN0v;
end

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

%Translate all of the frames by rMN0
for indexBody=1:1:length(rigidBodyData)
    rigidBodyData(indexBody).r0B0 = rigidBodyData(indexBody).r0B0+rMN0v; 
end

% rawMarkerData(nMarkers) = ...
%     struct('r0M0',zeros(n,3),'parentName','',...
%            'parentIndex',nan,'markerName','','markerIndex',0);
% 
% %raw marker data        
% rawMarkerData(indexMarker).parentName ...
%     = rigidBodyData(indexBody).bodyName;
% 
% rawMarkerData(indexMarker).parentIndex= indexBody;
% 
% rawMarkerData(indexMarker).markerName = ...
%     rigidBodyData(indexBody).markerNames{indexBodyMarker};   
% 
% rawMarkerData(indexMarker).markerIndex= indexBodyMarker;



%Adjust all of the labelled raw marker data




%Get the offset vector
% rPQ0 =zeros(1,3);
% 
% 
% flag_offsetVector = 0;
% for indexMarker=1:1:length(rigidBodyMarkerData)
%     if(contains(rigidBodyMarkerData(indexMarker).markerName, ...
%                 frame.markerName))
%         assert(flag_offsetVector==0);
%         indexParent = rigidBodyMarkerData(indexMarker).parentIndex;
%         r0B0 = rigidBodyData(indexParent).r0B0(frameNumber,:);
%         xyzw = rigidBodyData(indexParent).xyzw(frameNumber,:);
%         rmB0 = convertQuaternionToRotationMatrix(...
%             xyzw(1,1),xyzw(1,2),xyzw(1,3),xyzw(1,4));
%         rBMB = rigidBodyMarkerData(indexMarker).rBMB';
%         r0M0 = (r0B0' + rmB0*rBMB)';
% 
%         rPQ0 = -r0M0;
%         flag_offsetVector=1;
%     end
% end


% rPQ0v = ones(size(rigidBodyMarkerData(indexRefMarker).r0M0));
% rPQ0v(:,1) = rPQ0v(:,1).*rPQ0(1,1);
% rPQ0v(:,2) = rPQ0v(:,2).*rPQ0(1,2);
% rPQ0v(:,3) = rPQ0v(:,3).*rPQ0(1,3);


