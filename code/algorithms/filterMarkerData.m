function [rigidBodyMarkers] = filterMarkerData(rigidBodyMarkers,...
                            lowPassFilterFrequency, sampleFrequency)

[b,a]=butter(2,lowPassFilterFrequency/(0.5*sampleFrequency),'low');

for indexMarker=1:1:length(rigidBodyMarkers)
    for indexXYZ = 1:1:3
        rigidBodyMarkers(indexMarker).r0M0(:,indexXYZ) = ...
            filtfilt(b,a,rigidBodyMarkers(indexMarker).r0M0(:,indexXYZ));
    end
end

