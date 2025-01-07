function figH = plotMotiveData(frameNumber,colData,bodyNames,bodyColors,figH)

figure(figH);

indexColumn=3;
mkrPos = zeros(1,3);
colCount = 0;
while(indexColumn < (length(colData)-3))

    %%
    % Plot the rigid frame data
    %%
    flag_incrementColumn=1;
    if(strcmp(colData(indexColumn).Type,'Rigid_Body') ...
        && strcmp(colData(indexColumn).Measure,'Rotation') ...
        && strcmp(colData(indexColumn).Coordinate,'X'))
        
        rx = colData(indexColumn).data(frameNumber,1);
        indexColumn=indexColumn+1;
        
        assert(strcmp(colData(indexColumn).Coordinate,'Y'));        
        ry = colData(indexColumn).data(frameNumber,1);
        indexColumn=indexColumn+1;        

        assert(strcmp(colData(indexColumn).Coordinate,'Z')); 
        rz = colData(indexColumn).data(frameNumber,1);        
        indexColumn=indexColumn+1;

        assert(strcmp(colData(indexColumn).Coordinate,'W')); 
        w = colData(indexColumn).data(frameNumber,1);
        indexColumn=indexColumn+1;

        assert( strcmp( colData(indexColumn).Type,'Rigid_Body') ...
             && strcmp(colData(indexColumn).Measure,'Position') ...
             && strcmp(    colData(indexColumn).Coordinate,'X') );

        x = colData(indexColumn).data(frameNumber,1);

        indexColumn=indexColumn+1;
        assert(strcmp(colData(indexColumn).Coordinate,'Y'));
        y = colData(indexColumn).data(frameNumber,1);

        indexColumn=indexColumn+1;        
        assert(strcmp(colData(indexColumn).Coordinate,'Z'));        
        z = colData(indexColumn).data(frameNumber,1);

        %%
        % Get the body color
        %%
        s = strfind(colData(indexColumn).Name,':');
        s=s-1;
        bodyName = colData(indexColumn).Name(1,1:s);

        mkrColor = [0,0,0];
        for indexBody=1:1:length(bodyNames)
            if(contains(bodyName,bodyNames{indexBody}))
                mkrColor = bodyColors(indexBody,:);
            end
        end

        plot3(x,y,z,'+','Color',mkrColor,'MarkerFaceColor',mkrColor);                                        
        hold on;
        axis square;
        xlabel('X');
        ylabel('Y');
        zlabel('Z');                                                                           
        hold on;
        axis square;

        %%
        % Form the rotation matrix
        %%
        xyzw = [rx,ry,rz,w];
        xyzw = xyzw ./ sqrt(xyzw*(xyzw'));

        rm0B = convertQuaternionToRotationMatrix(...
            xyzw(1,1),xyzw(1,2),xyzw(1,3),xyzw(1,4));
        %rm=rm';
        xyz = [x;y;z];
        for indexAxis=1:1:3
            naxis=zeros(3,1);
            naxis(indexAxis,1)=0.1;
            naxis=rm0B'*naxis;
            axisColor = [0,0,0];
            axisColor(1,indexAxis)=1;
            plot3([xyz(1,1);xyz(1,1)+naxis(1,1)],...
                  [xyz(2,1);xyz(2,1)+naxis(2,1)],...
                  [xyz(3,1);xyz(3,1)+naxis(3,1)],...
                  'Color',axisColor);
            hold on;
            axis square;
            
        end

        %%
        % Get all of the body-fixed markers
        %%
        indexColumn=indexColumn+1;  
        assert(strcmp(colData(indexColumn).Measure,'Mean_Marker_Error'));
        indexColumn=indexColumn+1;          
        while( strcmp( colData(indexColumn).Type,'Rigid_Body_Marker') ...
             && contains(colData(indexColumn).Name,bodyName) ...
             && strcmp(colData(indexColumn).Measure,'Position') ...
             && strcmp(    colData(indexColumn).Coordinate,'X')   )

            lxyz = zeros(3,1); % l for local
            lxyz(1,1) =colData(indexColumn).data(frameNumber,1);

            indexColumn=indexColumn+1;
            assert(colData(indexColumn).Coordinate,'Y');
            lxyz(2,1) =colData(indexColumn).data(frameNumber,1);

            indexColumn=indexColumn+1;
            assert(colData(indexColumn).Coordinate,'Z');
            lxyz(3,1) =colData(indexColumn).data(frameNumber,1);
            
            gxyz = lxyz;% + xyz; %g for global marker position;

            plot3([xyz(1,1);gxyz(1,1)],...
                  [xyz(2,1);gxyz(2,1)],...
                  [xyz(3,1);gxyz(3,1)],...
                  'Color',mkrColor);
            plot3(gxyz(1,1),...
                  gxyz(2,1),...
                  gxyz(3,1),...
                  'x','Color',mkrColor);
            hold on;
            axis square;
             
            indexColumn = indexColumn+1;
            assert(strcmp(colData(indexColumn).Measure,'Marker_Quality'));
            indexColumn=indexColumn+1;
                            
        end
        here=1;
        flag_incrementColumn=0;
    end
    %%
    % Plot the labelled marker data
    %%
    if(strcmp(colData(indexColumn).Type,'Marker') ...
        && isempty(strfind(colData(indexColumn).Name,':Marker'))==0 ...
        && strcmp(colData(indexColumn).Measure,'Position') ...
        && strcmp(colData(indexColumn).Coordinate,'X'))

        x= colData(indexColumn).data(frameNumber,1);    
        indexColumn=indexColumn+1;
        assert(strcmp(colData(indexColumn).Coordinate,'Y'));
        y= colData(indexColumn).data(frameNumber,1);    
        indexColumn=indexColumn+1;
        assert(strcmp(colData(indexColumn).Coordinate,'Z'));
        z= colData(indexColumn).data(frameNumber,1);    

            
        s = strfind(colData(indexColumn).Name,':');
        s=s-1;
        bodyName = colData(indexColumn).Name(1,1:s);

        mkrColor = [0,0,0];
        for indexBody=1:1:length(bodyNames)
            if(contains(bodyName,bodyNames{indexBody}))
                mkrColor = bodyColors(indexBody,:);
            end
        end

        plot3(x,y,z,'o','Color',mkrColor,'MarkerFaceColor',[1,1,1]);                                        
        hold on;
        axis square;
        xlabel('X');
        ylabel('Y');
        zlabel('Z');       
        title(sprintf('Raw Motive Data (%i)',frameNumber));
        hold on;

        indexColumn=indexColumn+1;
        flag_incrementColumn=0;

    end
    xlim([-0.2,0.2]);
    ylim([-0.1,0.3]);
    zlim([-0.3,0.1]);
    if(flag_incrementColumn==1)        
        indexColumn=indexColumn+1;
    end
end