function [frameTimeData, rigidBodyData, rigidBodyMarkerData] ...
    = interpolateRigidBodyMotionAndMarkers(...
            motiveColData,motiveHeader,bodyNames,...
            flag_exportRigidBodyMarkers)


n = motiveHeader.Total_Frames_in_Take;
assert(contains(motiveHeader.Rotation_Type,'Quaternion'));

frameTimeData = zeros(n,2);
frameTimeData(:,1) = [1:1:n]';
dt =1/motiveHeader.Capture_Frame_Rate;
frameTimeData(:,2) = [dt:dt:(n*dt)]';


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

            rigidBodyData(indexBody).interpolated=zeros(n,1);

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

            %normalize the quaternions
            qM = sqrt( rigidBodyData(indexBody).xyzw(:,1).^2 ...
                     + rigidBodyData(indexBody).xyzw(:,2).^2 ...
                     + rigidBodyData(indexBody).xyzw(:,3).^2 ...
                     + rigidBodyData(indexBody).xyzw(:,4).^2);

            rigidBodyData(indexBody).xyzw(:,1) = ...
                rigidBodyData(indexBody).xyzw(:,1)./qM;

            rigidBodyData(indexBody).xyzw(:,2) = ...
                rigidBodyData(indexBody).xyzw(:,2)./qM;

            rigidBodyData(indexBody).xyzw(:,3) = ...
                rigidBodyData(indexBody).xyzw(:,3)./qM;

            rigidBodyData(indexBody).xyzw(:,4) = ...
                rigidBodyData(indexBody).xyzw(:,4)./qM;

            %Copy over the movement of the rigid body origin
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
    if(flag_found==0)
        here=1;
    end
    assert(flag_found==1);
    %Copy the information of the body fixed markers over
    flag_found=0;
    indexColumn=1;
    while indexColumn < length(motiveColData)
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
        end
        indexColumn=indexColumn+1;

    end

end



%%
% Populate the basic information of each marker: its name, the name of the
% parent body, the id of the parent body, and the position of the marker
% in the local axis
%%
rigidBodyMarkerData(nMarkers) = ...
    struct('r0M0',zeros(n,3),'parentName','',...
            'parentIndex',nan,'rBMB',zeros(1,3),'markerName','',...
            'markerIndex',0,'interpolated',zeros(n,1));


indexMarker=1;
for indexBody = 1:1:length(rigidBodyData)
    for indexBodyMarker=1:1:length(rigidBodyData(indexBody).markerNames)
        %Rigid body marker data
        rigidBodyMarkerData(indexMarker).parentName ...
            = rigidBodyData(indexBody).bodyName;

        rigidBodyMarkerData(indexMarker).parentIndex= indexBody;

        rigidBodyMarkerData(indexMarker).markerName = ...
            rigidBodyData(indexBody).markerNames{indexBodyMarker};

        rigidBodyMarkerData(indexMarker).markerIndex= indexBodyMarker;

      
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
        assert(flag_found==1);
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
        
        %Normalize the quaternion
        qM = sqrt(w*w + rx*rx + ry*ry + rz*rz);
        w = w/qM;
        rx = rx/qM;
        ry = ry/qM;
        rz = rz/qM;
        rmB0  = convertQuaternionToRotationMatrix(rx,ry,rz,w);
        rm0B = rmB0';
        %Go the the column for the current body-fixed marker
        indexColumn=1;
        flag_found=0;

        while indexColumn < length(motiveColData) && flag_found==0
            if(      strcmp(motiveColData(indexColumn).Type,'Rigid_Body_Marker') ...
                && contains(motiveColData(indexColumn).Name,...
                            rigidBodyData(indexBody).bodyName)...
                && contains(motiveColData(indexColumn).Name,...
                            rigidBodyMarkerData(indexMarker).markerName)...            
                &&   strcmp(motiveColData(indexColumn).Measure,'Position') ...
                &&   strcmp(motiveColData(indexColumn).Coordinate,'X'))

                flag_found=1;                
            else
                indexColumn=indexColumn+1;
            end
        end       
        assert(flag_found==1);


        %Populate the measured position of the labelled marker
        r0M0 = zeros(3,1);
        r0M0(1,1) = motiveColData(indexColumn).data(lowErrorFrame,1); 

        indexColumn=indexColumn+1;        
        r0M0(2,1) = motiveColData(indexColumn).data(lowErrorFrame,1); 

        indexColumn=indexColumn+1;   
        r0M0(3,1) = motiveColData(indexColumn).data(lowErrorFrame,1); 
        

        assert(contains(motiveColData(indexColumn).Name,...
                        rigidBodyMarkerData(indexMarker).markerName));
        assert(strcmp(motiveColData(indexColumn).Coordinate,'Z'));

        %Evaluate the local transformation from the rigid body to the
        %marker in the coordinates of the rigid body
        rBMB = rm0B*(r0M0-r0B0);

        rigidBodyMarkerData(indexMarker).rBMB=rBMB';

        %%
        %Go the the column for the labelled marker
        %%
        indexColumn=1;
        flag_found=0;
        nameLabelledMarker = [rigidBodyData(indexBody).bodyName,':',... 
                              rigidBodyMarkerData(indexMarker).markerName];

        markerType = '';
        if(flag_exportRigidBodyMarkers==1)
            markerType ='Rigid_Body_Marker';
        else
            markerType = 'Marker';
        end

        while indexColumn < length(motiveColData) && flag_found==0
            if(      strcmp(motiveColData(indexColumn).Type,markerType) ...
                && contains(motiveColData(indexColumn).Name,nameLabelledMarker)...
                &&   strcmp(motiveColData(indexColumn).Measure,'Position') ...
                &&   strcmp(motiveColData(indexColumn).Coordinate,'X'))

                flag_found=1;                
            else
                indexColumn=indexColumn+1;
            end
        end       
        assert(flag_found==1);

        rigidBodyMarkerData(indexMarker).r0M0(:,1) = ...
            motiveColData(indexColumn).data(:,1);

        indexColumn=indexColumn+1;
        rigidBodyMarkerData(indexMarker).r0M0(:,2) = ...
            motiveColData(indexColumn).data(:,1);   

        indexColumn=indexColumn+1;         
        rigidBodyMarkerData(indexMarker).r0M0(:,3) = ...
            motiveColData(indexColumn).data(:,1);

        rigidBodyMarkerData(indexMarker).interpolated = zeros(n,1);



        indexMarker=indexMarker+1;
    end
end

%%
%Find the gaps in the rigid-body data and interpolate 
%%
for indexBody = 1:1:length(rigidBodyData)

    r0B0Gaps = getGapIntervals(rigidBodyData(indexBody).r0B0(:,1));
    xyzwGaps = getGapIntervals(rigidBodyData(indexBody).xyzw(:,1));

    %Linearly interpolate the position gaps
    if(isempty(r0B0Gaps) == 0)
        for indexGap = 1:1:size(r0B0Gaps,1)
            indexStart = r0B0Gaps(indexGap,1)-1;
            indexEnd   = r0B0Gaps(indexGap,2)+1;
            %Only attempt to interpolate gaps that have data at the 
            %beginning and end
            if(indexStart > 0 ...
                    && indexEnd < size(rigidBodyData(indexBody).r0B0,1))
                %Linearly interpolate the gap
                r0B0a = rigidBodyData(indexBody).r0B0(indexStart,:);
                r0B0b = rigidBodyData(indexBody).r0B0(indexEnd,:);
                
                for k = r0B0Gaps(indexGap,1):1:r0B0Gaps(indexGap,2)
                    h =  (k - r0B0Gaps(indexGap,1) ) ...
                        /(r0B0Gaps(indexGap,2)-r0B0Gaps(indexGap,1));
                    rigidBodyData(indexBody).r0B0(k,:) = ...
                        r0B0a.*(1-h) + r0B0b.*(h);
                    rigidBodyData(indexBody).interpolated(k,1)=1;
                end
            end
        end
    end

    %Linearly interpolate the orientation gaps    
    if(isempty(xyzwGaps) == 0)
        for indexGap = 1:1:size(xyzwGaps,1)
            indexStart = xyzwGaps(indexGap,1)-1;
            indexEnd   = xyzwGaps(indexGap,2)+1;
            %Only attempt to interpolate gaps that have data at the 
            %beginning and end
            if(indexStart > 0 ...
                    && indexEnd < size(rigidBodyData(indexBody).xyzw,1))
                %Linearly interpolate the gap
                xyzwa = rigidBodyData(indexBody).xyzw(indexStart,:);
                xyzwb = rigidBodyData(indexBody).xyzw(indexEnd,:);
                
                for k = xyzwGaps(indexGap,1):1:xyzwGaps(indexGap,2)
                    h =  (k - xyzwGaps(indexGap,1) ) ...
                        /(xyzwGaps(indexGap,2)-xyzwGaps(indexGap,1));

                    %Quaternions can be interpolated
                    xyzw = xyzwa.*(1-h) + xyzwb.*(h);
                    %But need to be renormalized
                    xyzw = xyzw ./ sqrt( xyzw*xyzw' );

                    rigidBodyData(indexBody).xyzw(k,:) = xyzw;
                    rigidBodyData(indexBody).interpolated(k,1)=1;
                end
            end
        end
    end

end

%%
%Find the marker gaps, use the rigid body model to fill the gaps
%%
for indexMarker=1:1:length(rigidBodyMarkerData)

    r0M0Gaps = getGapIntervals(rigidBodyMarkerData(indexMarker).r0M0(:,1));

    if(isempty(r0M0Gaps) == 0)
        for indexGap = 1:1:size(r0M0Gaps,1)
            indexStart = r0M0Gaps(indexGap,1)-1;
            indexEnd   = r0M0Gaps(indexGap,2)+1;
            %Only attempt to interpolate gaps that have data at the 
            %beginning and end

            %Linearly interpolate the gap
            indexParent = ...
                rigidBodyMarkerData(indexMarker).parentIndex;
            rBMB = rigidBodyMarkerData(indexMarker).rBMB';
            
            for k = r0M0Gaps(indexGap,1):1:r0M0Gaps(indexGap,2)
                r0B0 = rigidBodyData(indexParent).r0B0(k,:)';
                xyzw  = rigidBodyData(indexParent).xyzw(k,:);
                rmB0 = convertQuaternionToRotationMatrix(...
                    xyzw(1,1),xyzw(1,2),xyzw(1,3),xyzw(1,4));
                r0M0 = r0B0 + rmB0*rBMB;
                rigidBodyMarkerData(indexMarker).r0M0(k,:)=r0M0';
                rigidBodyMarkerData(indexMarker).interpolated(k,1)=1;
            end
            
        end        
    end

end








