function [rigidBodyData,rigidBodyMarkerData]= ...
    renameMarkers(rigidBodyData,rigidBodyMarkerData,...
                parentName,markerName,newMarkerName)

%Rename the markers
for indexMarker=1:1:length(rigidBodyMarkerData)
    for indexRename = 1:1:length(newMarkerName)
        if(     strcmp(parentName{indexRename}, ...
                    rigidBodyMarkerData(indexMarker).parentName) ...
            &&  strcmp(markerName{indexRename}, ...
                    rigidBodyMarkerData(indexMarker).markerName))

            rigidBodyMarkerData(indexMarker).markerName = ...
                newMarkerName{indexRename};
            indexParent=rigidBodyMarkerData(indexMarker).parentIndex;

            for indexParentMarkers=1:1:length(rigidBodyData(indexParent).markerNames)
                if(strcmp(rigidBodyData(indexParent).markerNames{indexParentMarkers},...
                          markerName{indexRename}))
                    rigidBodyData(indexParent).markerNames{indexParentMarkers} = ...
                        newMarkerName{indexRename};
                end
            end
                                        
        end
    end
end