function result=normalizeEmgEnvelope(carBiopacDataNorm,firstMuscleBiopacIndex,...
    lastMuscleBiopacIndex,participantMvcData,timeV,biopacChannels)

 flag_plotNormDebugData=0;
        if(flag_plotNormDebugData==1)
            figNormDebugData=figure;
        end
        for indexMuscle=firstMuscleBiopacIndex:1:lastMuscleBiopacIndex

            directionAllValues = [];
            for indexDirection=1:1:size(participantMvcData.biopacSignalNorm,1)

                directionRowVector = ...
                   [participantMvcData.biopacSignalNorm(indexDirection, 1).max(indexMuscle),...
                    participantMvcData.biopacSignalNorm(indexDirection, 2).max(indexMuscle)];

                directionAllValues=[directionAllValues;...
                                    directionRowVector];


            end
                muscleMax(indexMuscle)=max(directionAllValues, [], 'all');
                carBiopacDataNorm.data(:,indexMuscle) = ...
                    carBiopacDataNorm.data(:,indexMuscle)./muscleMax(indexMuscle);
                result=carBiopacDataNorm.data;
                if(flag_plotNormDebugData==1)
                    figure(figNormDebugData);
                    subplot(2,3,indexMuscle-firstMuscleBiopacIndex+1);
                    lineColor=[0,0,1];
                    if(min(carBiopacDataNorm.data(:,indexMuscle))<=0 || ...
                       max(carBiopacDataNorm.data(:,indexMuscle))>=1.25)
                        lineColor=[1,0,0];
                    end

                    plot(timeV, carBiopacDataNorm.data(:,indexMuscle),...
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

end