function figH = plotRigidBodiesMarkers(frameNumber, ...
    rigidBodyData, rigidBodyMarkerData,figH)

figure(figH);


for indexBody=1:1:length(rigidBodyData)

    %Plot the body frame
    r0B0 = rigidBodyData(indexBody).r0B0(frameNumber,:);

    xyzw = rigidBodyData(indexBody).xyzw(frameNumber,:);
    xyzw = xyzw ./ sqrt(xyzw*(xyzw'));

    rmB0 = convertQuaternionToRotationMatrix(...
        xyzw(1,1),xyzw(1,2),xyzw(1,3),xyzw(1,4));


    for indexAxis=1:1:3
        naxis=zeros(3,1);
        naxis(indexAxis,1)=0.05;
        naxis=rmB0*naxis;
        axisColor = [0,0,0];
        axisColor(1,indexAxis)=1;
        plot3([r0B0(1,1);r0B0(1,1)+naxis(1,1)],...
              [r0B0(1,2);r0B0(1,2)+naxis(2,1)],...
              [r0B0(1,3);r0B0(1,3)+naxis(3,1)],...
              'Color',axisColor,...
              'LineWidth',1);
        hold on;

        axisTipColor = axisColor;
        if(rigidBodyData(indexBody).interpolated(frameNumber,1)==1)
            axisTipColor = [1,0,1];
        end

        plot3(r0B0(1,1)+naxis(1,1),...
              r0B0(1,2)+naxis(2,1),...
              r0B0(1,3)+naxis(3,1),...
              's','Color',axisTipColor,...
              'LineWidth',1,...
              'MarkerSize',7,...
              'MarkerFaceColor', axisTipColor);
        hold on;        
        axis square;        
    end

end

for indexMarker = 1:1:length(rigidBodyMarkerData)

    %Plot the labelled measured marker position
    plot3(rigidBodyMarkerData(indexMarker).r0M0(frameNumber,1),...
          rigidBodyMarkerData(indexMarker).r0M0(frameNumber,2),...
          rigidBodyMarkerData(indexMarker).r0M0(frameNumber,3),...
          'x','Color',[0,1,1]);    
    hold on;

    uniqueMarkerName = [rigidBodyMarkerData(indexMarker).parentName,...
                    '_',rigidBodyMarkerData(indexMarker).markerName];
    uniqueMarkerName=replaceCharacter(uniqueMarkerName,'_',' ');

    text(rigidBodyMarkerData(indexMarker).r0M0(frameNumber,1),...
          rigidBodyMarkerData(indexMarker).r0M0(frameNumber,2),...
          rigidBodyMarkerData(indexMarker).r0M0(frameNumber,3),...
          uniqueMarkerName);

    %Plot the position of the rigid body marker position
    indexParent = ...
        rigidBodyMarkerData(indexMarker).parentIndex;
    rBMB = rigidBodyMarkerData(indexMarker).rBMB';

    r0B0 = rigidBodyData(indexParent).r0B0(frameNumber,:);
    xyzw = rigidBodyData(indexParent).xyzw(frameNumber,:);
    rmB0 = convertQuaternionToRotationMatrix(...
        xyzw(1,1),xyzw(1,2),xyzw(1,3),xyzw(1,4));
    r0M0 = (r0B0' + rmB0*rBMB)';

    markerColor = [0,0,0];
    if(rigidBodyMarkerData(indexMarker).interpolated(frameNumber,1)==1)
        markerColor = [1,0,1];
    end

    plot3(r0M0(1,1),r0M0(1,2),r0M0(1,3),'^',...
        'Color',markerColor,'MarkerFaceColor',markerColor,...
        'MarkerSize',7);
    hold on;
    plot3([r0B0(1,1),r0M0(1,1)],...
         [r0B0(1,2),r0M0(1,2)],...
         [r0B0(1,3),r0M0(1,3)],'-','Color',markerColor,'LineWidth',1);
    hold on;
    axis square;   
end

xlabel('X');
ylabel('Y');
zlabel('Z');

title(sprintf('Interpolated Data %i',frameNumber));
here=1;
