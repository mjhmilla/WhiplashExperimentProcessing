function [timeFrameData, rigidBodyData, rigidBodyMarkerData] ...
    = interpolateRigidBodyMotionAndMarkers(...
            motiveColData,motiveHeader,bodyNames)


n = motiveHeader.Total_Frames_in_Take;
assert(contains(motiveHeader.Rotation_Type,'Quaternion'));

timeFrameData = zeros(n,2);


rigidBodyData(length(bodyNames)) ...
    =struct('r0B0',zeros(n,3),'xyzw',zeros(n,4),'interpolated',zeros(n,1),...
            'bodyName','','markerNames',[]);

%Count the number of markers each body has, save the marker name and the 
%name of its parent
nMarkers = 0;

for indexBody=1:1:length(bodyNames)
    %Copy the kinematic information of each body over
    flag_found=0;
    indexColumn=1;
    while indexColumn < length(motiveColData) && flag_found==0
        if( strcmp( motiveColData(indexColumn).Type,'Rigid_Body') ...
             && contains(motiveColData(indexColumn).Name,bodyNames{indexBody}) ...
             && strcmp(motiveColData(indexColumn).Measure,'Rotation') ...
             && strcmp(motiveColData(indexColumn).Coordinate,'X') )

            rigidBodyData(indexBody).xyzw(:,1) = ...
                motiveColData(indexColumn).data;            
            indexColumn=indexColumn+1;

            rigidBodyData(indexBody).xyzw(:,2) = ...
                motiveColData(indexColumn).data;            
            indexColumn=indexColumn+1;

            rigidBodyData(indexBody).xyzw(:,3) = ...
                motiveColData(indexColumn).data;            
            indexColumn=indexColumn+1;

            rigidBodyData(indexBody).xyzw(:,4) = ...
                motiveColData(indexColumn).data;            
            indexColumn=indexColumn+1;

            rigidBodyData(indexBody).r0B0(:,1) = ...
                motiveColData(indexColumn).data;            
            indexColumn=indexColumn+1;

            rigidBodyData(indexBody).r0B0(:,2) = ...
                motiveColData(indexColumn).data;            
            indexColumn=indexColumn+1;

            rigidBodyData(indexBody).r0B0(:,3) = ...
                motiveColData(indexColumn).data;            
            indexColumn=indexColumn+1;

            flag_found=1;
        else
            indexColumn=indexColumn+1;
        end
    end
    %Copy the information of the body fixed markers over
    flag_found=0;
    indexColumn=1;
    while indexColumn < length(motiveColData) && flag_found==0
        if( strcmp( motiveColData(indexColumn).Type,'Rigid_Body_Marker') ...
             && contains(motiveColData(indexColumn).Name,bodyNames{indexBody}) ...
             && strcmp(motiveColData(indexColumn).Measure,'Position') ...
             && strcmp(motiveColData(indexColumn).Coordinate,'X') )

            i0 = min(strfind(motiveColData(indexColumn).Name,'"'));
            if(isempty(i0))
                i0=1;
            else
                i0=i0+1;
            end
            i1 = strfind(motiveColData(indexColumn).Name,':');
            i2 = max(strfind(motiveColData(indexColumn).Name,'"'));
            if(isempty(i2))
                i2=length(motiveColData(indexColumn).Name);
            else 
                i2=i2-1;
            end

            rigidBodyData(indexBody).bodyName = ...
                motiveColData(indexColumn).Name(1,i0:(i1-1));
            rigidBodyData(indexBody).markerNames = ...
                [rigidBodyData(indexBody).markerNames,...
                 {motiveColData(indexColumn).Name(1,(i1+1):i2)}];

            nMarkers = nMarkers+1;
            
            flag_found=1;
        else
            indexColumn=indexColumn+1;
        end
    end
end

rigidBodyMarkerData(nMarkers) = ...
    struct('r0M0',zeros(n,3),'parentName','',...
            'parentIndex',nan,'rBMB',zeros(1,3),'markerName','');

% Populate the basic information of each marker: its name, the name of the
% parent body, the id of the parent body, and the position of the marker
% in the local axis
indexMarker=1;
for indexBody = 1:1:length(rigidBodyData)
    for indexBodyMarker=1:1:length(rigidBodyData(indexBody).markerNames)

        rigidBodyMarkerData(indexMarker).parentName ...
            = rigidBodyData(indexBody).bodyName;

        rigidBodyMarkerData(indexMarker).parentIndex= indexBody;

        rigidBodyMarkerData(indexMarker).markerName = ...
            rigidBodyData(indexBody).markerNames{indexBodyMarker};

        %Find a frame for the rigid body that has a low marker error
        indexColumn=1;
        flag_found=0;
        while indexColumn < length(motiveColData) && flag_found==0
            if(strcmp(motiveColData(indexColumn).Type,'Rigid_Body') ...
                && strcmp(motiveColData(indexColumn).Name,rigidBodyData(indexBody).bodyName)...
                && strcmp(motiveColData(indexColumn).Measure,'Mean_Marker_Error'))

                flag_found=1;                
            else
                indexColumn=indexColumn+1;
            end
        end

        [lowMarkerError, lowErrorFrame] = ...
            min(motiveColData(indexColumn).data(:,1));


        %Retreive the position and orientation of the rigid body
        indexColumn = indexColumn-7;
        assert(strcmp(motiveColData(indexColumn).Name,...
            rigidBodyData(indexBody).bodyName));
        assert(strcmp(motiveColData(indexColumn).Measure,'Rotation'));
        assert(strcmp(motiveColData(indexColumn).Coordinate,'X'));
        
        rx = motiveColData(indexColumn).data(lowErrorFrame,1);
        indexColumn=indexColumn+1;
        ry = motiveColData(indexColumn).data(lowErrorFrame,1);
        indexColumn=indexColumn+1;
        rz = motiveColData(indexColumn).data(lowErrorFrame,1);
        indexColumn=indexColumn+1;
        w  = motiveColData(indexColumn).data(lowErrorFrame,1);
        indexColumn=indexColumn+1; 

        x = motiveColData(indexColumn).data(lowErrorFrame,1);
        indexColumn=indexColumn+1;
        y = motiveColData(indexColumn).data(lowErrorFrame,1);
        indexColumn=indexColumn+1;
        z = motiveColData(indexColumn).data(lowErrorFrame,1);

        r0B0 = [x;y;z];
        r0B  = convertQuaternionToRotationMatrix(w,rx,ry,rz);


        %Go the the column for the current body-fixed marker
        indexColumn=1;
        flag_found=0;
        while indexColumn < length(motiveColData) && flag_found==0
            if(    strcmp(motiveColData(indexColumn).Type,...
                            'Rigid_Body_Marker') ...
                && contains(motiveColData(indexColumn).Name,...
                            rigidBodyData(indexBody).bodyName)...
                && contains(motiveColData(indexColumn).Name,...
                            rigidBodyMarkerData(indexMarker).markerName) ...
                && strcmp(motiveColData(indexColumn).Measure,'Position') ...
                && strcmp(motiveColData(indexColumn).Coordinate,'X'))

                flag_found=1;                
            else
                indexColumn=indexColumn+1;
            end
        end        

        %Extract the position of the marker in the inertial frame (0)
        %in the coordinates of the inerital frame
        r0M0 = zeros(3,1);
        r0M0(1,1) = motiveColData(indexColumn).data(lowErrorFrame,1); 
        rigidBodyMarkerData(indexMarker).r0M0(:,1) = ...
            motiveColData(indexColumn).data(:,1);

        indexColumn=indexColumn+1;        
        r0M0(2,1) = motiveColData(indexColumn).data(lowErrorFrame,1); 
        rigidBodyMarkerData(indexMarker).r0M0(:,2) = ...
            motiveColData(indexColumn).data(:,1);

        indexColumn=indexColumn+1;        
        r0M0(3,1) = motiveColData(indexColumn).data(lowErrorFrame,1); 
        rigidBodyMarkerData(indexMarker).r0M0(:,3) = ...
            motiveColData(indexColumn).data(:,1);

        assert(contains(motiveColData(indexColumn).Name,...
                        rigidBodyMarkerData(indexMarker).markerName));
        assert(strcmp(motiveColData(indexColumn).Coordinate,'Z'));

        %Evaluate the local transformation from the rigid body to the
        %marker in the coordinates of the rigid body
        rBMB = r0B'*(r0M0-r0B0);

        rigidBodyMarkerData(indexMarker).rBMB=rBMB;

         
    end
end

%Find the gaps in the rigid-body data and interpolate 
for indexBody = 1:1:length(rigidBodyData)

    r0B0Gaps = getGapIntervals(rigidBodyData(indexBody).r0B0);
    xyzwGaps = getGapIntervals(rigidBodyData(indexBody).xyzw);

    %Linearly interpolate the gaps
    if(size(r0B0Gaps,1) > 0)

    end
    if(size(xyzwGaps,1) > 0)

    end

end

%Find the marker gaps, use the rigid body model to fill the gaps







