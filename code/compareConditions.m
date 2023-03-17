
function dataParticipantCondition=...
    compareConditions(participantFirst,participantLast,...
                        dataSetFolder, outputSetFolder, ...
                        conditionsTemplate,...
                        firstMuscleBiopacIndex,lastMuscleBiopacIndex,...
                        numberOfMuscles,noDataNumber)

        
%         dataAllTimes=struct('participant01','',...
%         'participant02','',...
%         'participant03','');
   
numberOfParticipants = participantLast-participantFirst + 1;
dataParticipantCondition(numberOfParticipants) = struct('conditions',[]); 

for indexParticipant = participantFirst:1:participantLast


    strNum =num2str(indexParticipant);
    if(length(strNum)<2)
        strNum = ['0',strNum];
    end
    participantLabel = ['participant',strNum];
   

    disp('----------------------------------------');
    disp(participantLabel);
    disp('----------------------------------------');


    [inputFolders,outputFolders]=getParticipantFolders(indexParticipant,...
                                            dataSetFolder,outputSetFolder);

    filesInAllParticipants  = dir(outputFolders.common);
    fileNameEmgPipelineOutput = ['emgPipelineOutput_', participantLabel,'.mat'];
    currentFile             = fullfile(outputFolders.common,...
                                       fileNameEmgPipelineOutput);
    tmp=load(currentFile);
    if(exist('participantEmgData','var'))
        clear('participantEmgData');
    end
    participantEmgData = tmp.participantEmgData;

    conditionsToCompare = conditionsTemplate;


    dataParticipantCondition(indexParticipant).conditions=conditionsTemplate;
   

    for indexTrial=1:1:length(participantEmgData)

        if(participantEmgData(indexTrial).flag_ignoreTrial == 0)        
            id                      = participantEmgData(indexTrial).id;
        
            condition               = participantEmgData(indexTrial).condition;
            carDirection            = participantEmgData(indexTrial).carDirection;
            block                   = participantEmgData(indexTrial).block;
        
            biopacIndices           = participantEmgData(indexTrial).biopacIndices;
            biopacSignalIntervals   = participantEmgData(indexTrial).biopacSignalIntervals;
        
            flag_ignoreTrial        = participantEmgData(indexTrial).flag_ignoreTrial;
            flag_carMoved           = participantEmgData(indexTrial).flag_carMoved;
            for indexMuscle =firstMuscleBiopacIndex:1:lastMuscleBiopacIndex
                flag_ignorePreactivatedMuscles(indexMuscle) = participantEmgData(indexTrial).biopacSignalIntervals(indexMuscle).flag_isMusclePreactivated; 
            end 



            disp([num2str(indexTrial),' ',condition,' ', carDirection,' ',...
                  num2str(flag_carMoved),' ',num2str(flag_ignoreTrial)]);
            if(indexTrial==6)
                here=1;
            end

            if(flag_carMoved==1 && flag_ignoreTrial == 0)


                for indexCondition=1:1:length(conditionsToCompare)

                    if(isempty(conditionsToCompare(indexCondition).columnNames)==1)
                        conditionsToCompare(indexCondition).columnNames = [];
                        indexNames = fieldnames(participantEmgData(indexTrial).biopacIndices);
                        for indexMuscle=firstMuscleBiopacIndex:1:lastMuscleBiopacIndex
                            muscleName = indexNames{indexMuscle};
                            i=strfind(muscleName,'x');
                            muscleName = muscleName(1,(i+1):end);
                            conditionsToCompare(indexCondition).columnNames = [...
                                conditionsToCompare(indexCondition).columnNames,...
                                {muscleName}];
                        end
                    end

                    conditionCorrect = strcmp(conditionsToCompare(indexCondition).condition,...
                                        condition);
                    directionCorrect = strcmp(conditionsToCompare(indexCondition).carDirection,...
                                        carDirection);



                    if( conditionCorrect && directionCorrect)


                        onsetRowVector              = ones(1,numberOfMuscles).*noDataNumber;
                        maxMagnitudeRowVector       = ones(1,numberOfMuscles).*noDataNumber;
                        indexParticipantRowVector   = ones(1,numberOfMuscles).*noDataNumber;
                        indexTrialRowVector         = ones(1,numberOfMuscles).*noDataNumber;

                        indexMuscleNotPreactivated = zeros(1,lastMuscleBiopacIndex);
                        for indexMuscle=firstMuscleBiopacIndex:1:lastMuscleBiopacIndex
                            if flag_ignorePreactivatedMuscles(indexMuscle)== 0
                                indexMuscleNotPreactivated(indexMuscle) = indexMuscle;
                            end
                            if indexMuscleNotPreactivated(indexMuscle)~= 0

                                if(biopacSignalIntervals(indexMuscle).flag_maximumValueExceedsThreshold ...
                                   && biopacSignalIntervals(biopacIndices.indexAccCarX).flag_maximumValueExceedsThreshold)
    
                                    onsetTime       = ...
                                          biopacSignalIntervals(               indexMuscle).intervalTimes(1,1) ...
                                        - biopacSignalIntervals(biopacIndices.indexAccCarX).intervalTimes(1,1);
    
                                    maxMagnitude    = biopacSignalIntervals(indexMuscle).intervalMaximumValue;
    
                                    onsetRowVector(1,indexMuscle)           = onsetTime;
                                    maxMagnitudeRowVector(1,indexMuscle)    = maxMagnitude;
                                    indexParticipantRowVector(1,indexMuscle)=indexParticipant;
                                    indexTrialRowVector(1,indexMuscle)      = indexTrial;
                                end
                            end 
                        end


                        conditionsToCompare(indexCondition).times = [...
                            conditionsToCompare(indexCondition).times; ...
                            onsetRowVector];

                        conditionsToCompare(indexCondition).magnitudes = [...
                            conditionsToCompare(indexCondition).magnitudes;...
                            maxMagnitudeRowVector];

                        conditionsToCompare(indexCondition).participantIndex =[...
                            conditionsToCompare(indexCondition).participantIndex;...
                            indexParticipantRowVector];

                        conditionsToCompare(indexCondition).trialIndex = [...
                            conditionsToCompare(indexCondition).trialIndex;...
                            indexTrialRowVector];

                        conditionsToCompare(indexCondition).fileName = [...
                            conditionsToCompare(indexCondition).fileName;...                        
                            {participantEmgData(indexTrial).fileName}];

%                         for indexPosition=participantFirst:length(conditionsToCompare(indexCondition).times):participantLast*...
%                                 length(conditionsToCompare(indexCondition).times)
%                             timesAllParticipants(indexPosition)= conditionsToCompare(indexCondition).times;
%                             amplitudeAllParticpants(indexPosition)= conditionsToCompare(indexCondition).magnitudes;
%                             
%                         end
                                           


                    end
                end
                
            end
        end



    end

    dataParticipantCondition(indexParticipant).conditions = ...
                    conditionsToCompare;    
    here=1;

end    
    %save the data
    %dataName = sprintf(['emgOnsetAndAmplitude_%s.mat'],  participantLabel);
    %dataPath = fullfile(outputFolders.common,dataName);
    %save(dataPath,'conditionsToCompare');    
    

%     a(indexParticipant)=convertCharsToStrings(participantLabel);
%     dataAllTimes.participant01=conditionsToCompare(indexCondition).times;
%     fileNameEmgOnsetAndAmplitude = ['emgOnsetAndAmplitude_', participantLabel,'.mat'];
%     outputFile             = fullfile(outputFolders.common,...
%                                        fileNameEmgOnsetAndAmplitude);
%     result(indexParticipant)=load(outputFile);
