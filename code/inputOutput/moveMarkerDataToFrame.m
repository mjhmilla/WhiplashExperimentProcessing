function [markerData,offset] = moveMarkerDataToFrame(markerData,...
                                frame,offset,flag_useDeprecatedOffset)


%Rotate all of the marker data about the origin
for indexMarker=1:1:length(markerData)
   for i = 1:1:size(markerData(indexMarker).r0M0,1)
       markerData(indexMarker).r0M0(i,:) = ...
           (frame.rm * markerData(indexMarker).r0M0(i,:)')';
   end
end

if(isempty(offset))
    offset = calcOffsetVector(markerData,...
                                   frame,...
                                   flag_useDeprecatedOffset);
end

%Apply the offset vector to all data
rMN0v = ones(size(markerData(1).r0M0));
rMN0v(:,1) = rMN0v(:,1).*offset(1,1);
rMN0v(:,2) = rMN0v(:,2).*offset(1,2);
rMN0v(:,3) = rMN0v(:,3).*offset(1,3);

for indexMarker=1:1:length(markerData)
    markerData(indexMarker).r0M0 = ...
        markerData(indexMarker).r0M0 + rMN0v;
end

