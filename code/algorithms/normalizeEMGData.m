function emgData = normalizeEMGData(emgData,mvcData,muscleIndices,flag_plotNormDebugData)

if(flag_plotNormDebugData==1)
    figNormDebugData=figure;
end

firstMuscleBiopacIndex = muscleIndices(1,1);
lastMuscleBiopacIndex  = muscleIndices(1,end);

for indexMuscle=muscleIndices

    directionAllValues = [];
    for indexDirection=1:1:size(mvcData.biopacSignalNorm,1)

        directionRowVector = ...
           [mvcData.biopacSignalNorm(indexDirection, 1).max(indexMuscle),...
            mvcData.biopacSignalNorm(indexDirection, 2).max(indexMuscle)];

        directionAllValues=[directionAllValues;...
                            directionRowVector];


    end
        muscleMax(indexMuscle)=max(directionAllValues, [], 'all');
        emgData.data(:,indexMuscle) = ...
            emgData.data(:,indexMuscle)./muscleMax(indexMuscle);
        if(flag_plotNormDebugData==1)
            figure(figNormDebugData);
            subplot(2,3,indexMuscle-firstMuscleBiopacIndex+1);
            lineColor=[0,0,1];
            if(min(emgData.data(:,indexMuscle))<=0 || ...
               max(emgData.data(:,indexMuscle))>=1.25)
                lineColor=[1,0,0];
            end

            plot(timeV, emgData.data(:,indexMuscle),...
                'Color',lineColor);
            hold on;
            xlabel('Time (s)');
            ylabel('Norm. EMG (mvc)');
            muscleName = biopacChannels{indexMuscle};
            i0 = strfind(muscleName,'_');
            muscleName(i0)=' ';
            title(muscleName);
            box off;
            axis tight;
        end
end  