function frameOffset = calcOffsetVector(rigidBodyMarkerData,frame)

frameOffset          = [0,0,0];
flag_setOffsetVector = 0;
indexReferenceMarker = 1;

frameNumber=1;

while indexReferenceMarker < length(rigidBodyMarkerData) && flag_setOffsetVector==0
    if(contains(rigidBodyMarkerData(indexReferenceMarker).markerName,...
            frame.markerName))
        frameNumber=1;
        while sum(isnan(rigidBodyMarkerData(indexReferenceMarker).r0M0(frameNumber,:))) > 0
            frameNumber=frameNumber+1;
        end
        frameOffset = frame.r0N0' - rigidBodyMarkerData(indexReferenceMarker).r0M0(frameNumber,:);
        %rMN0 = - rigidBodyMarkerData(indexReferenceMarker).r0M0(frameNumber,:);
        flag_setOffsetVector=1;
    else
        indexReferenceMarker=indexReferenceMarker+1;
    end
end

