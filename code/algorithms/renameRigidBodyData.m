function rigidBodyData = ...
    renameRigidBodyData(rigidBodyData,...
                parentName,markerName,newMarkerName)

%Rename the markers

for indexBody=1:1:length(rigidBodyData)
    for indexMarker=1:1:length(rigidBodyData(indexBody).markerNames)
        for indexRename = 1:1:length(newMarkerName)
            if(     contains(rigidBodyData(indexBody).bodyName,...
                             parentName{indexRename}) ...
                &&  contains(rigidBodyData(indexBody).markerNames{indexMarker},...
                             markerName{indexRename}))
    
                rigidBodyData(indexBody).markerNames{indexMarker} = ...
                    newMarkerName{indexRename};

            end
        end
    end
end