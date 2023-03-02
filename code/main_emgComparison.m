%%main_emgComparison
clc;
close all;
clear all;

%Notes to improve participantEmgData
% 1. Get rid of the first 2 elements
% 2. Change flag_ignoreTrial to flag_useTrial

% 0: 2022 data set
% 1: 2023 data set
flag_dataSet    = 1;
participantFirst= 1;
participantLast = 1;

%Input
noDataNumber = 0;
firstMuscleBiopacIndex=1;
lastMuscleBiopacIndex=6;
numberOfMuscles = lastMuscleBiopacIndex-firstMuscleBiopacIndex+1;
                    
numberOfConditions = 2;
conditionsToCompare(numberOfConditions) ...
    = struct('condition','',... 
             'carDirection','',...
             'columnNames',      [],... 
             'times',            [],...
             'magnitudes',       [],...
             'participantIndex',[],...
             'trialIndex',      [],...
             'fileName'  ,      []);

conditionsToCompare(1).condition='nominal';
conditionsToCompare(1).direction='Forward';

conditionsToCompare(2).condition='seatBack';
conditionsToCompare(2).direction='Forward';

%Local folders
addpath('inputOutput');

%Check that Matlab is currently in the code directory
localPath=pwd();
[parentFolderPath,parentFolder] = fileparts(localPath);

assert(contains(parentFolder,'code'));
assert(contains(parentFolderPath,'WhiplashExperimentProcessing'));

whiplashFolder= parentFolderPath;
codeFolder=localPath;

switch(flag_dataSet)
	case 0
		dataSetFolder = fullfile(whiplashFolder,'data2022');
		outputSetFolder=fullfile(whiplashFolder,'output2022');        
		numberOfParticipants=21;

	case 1
		dataSetFolder = fullfile(whiplashFolder,'data2023');
		outputSetFolder=fullfile(whiplashFolder,'output2023');
		numberOfParticipants=28;    
		disp('Important: the TRU_L and TRU_R are really SCP_L and SCP_R');
        disp('Important: the head accelerometer was never attached to the head. (Matts fault)');
		
	otherwise
		assert(0,'Error: flag_dataSet must be 0 or 1');
end



%% load the data from emgPipelineOutput_participantXX
indexParticipant = participantFirst;


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
load(currentFile);
%participantEmgData




%%


for indexTrial=1:1:length(participantEmgData)

    id                      = participantEmgData(indexTrial).id;

    condition               = participantEmgData(indexTrial).condition;
    carDirection            = participantEmgData(indexTrial).carDirection;
    block                   = participantEmgData(indexTrial).block;
    
    biopacIndices           = participantEmgData(indexTrial).biopacIndices;
    biopacSignalIntervals   = participantEmgData(indexTrial).biopacSignalIntervals;

    flag_ignoreTrial        = participantEmgData(indexTrial).flag_ignoreTrial;
    flag_carMoved           = participantEmgData(indexTrial).flag_carMoved;


    if(isempty(id)==0)
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
                directionCorrect = strcmp(conditionsToCompare(indexCondition).direction,...
                                    carDirection);



                if( conditionCorrect && directionCorrect)


                    onsetRowVector              = ones(1,numberOfMuscles).*noDataNumber;
                    maxMagnitudeRowVector       = ones(1,numberOfMuscles).*noDataNumber;
                    indexParticipantRowVector   = ones(1,numberOfMuscles).*noDataNumber;
                    indexTrialRowVector         = ones(1,numberOfMuscles).*noDataNumber;

                    for indexMuscle=firstMuscleBiopacIndex:1:lastMuscleBiopacIndex


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

                end
            end
        end
    end

    here=1;

end


%Build a plot that contains a box-whisker illustration for each 
%condition

%Perform a Wilcoxon ranksum test to test the probability that the two
%distributions are the same.
