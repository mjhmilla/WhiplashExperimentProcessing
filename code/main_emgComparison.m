%%main_emgComparison
clc;
close all;
clear all;

%Input
numberOfConditions = 2;
conditionsToCompare(numberOfConditions) ...
    = struct('condition','',... 
             'direction','',...
             'time',[],...
             'magnitude',[]);


conditionsToCompare(1).condition='nominal';
conditionsToCompare(1).direction='Forward';

conditionsToCompare(2).condition='seatBack';
conditionsToCompare(2).direction='Forward';

%% load the data from emgPipelineOutput_participantXX
flag_dataSet = 1;
participantFirst=1;
participantLast=1;

addpath('inputOutput');

for indexParticipant=participantFirst:1:participantLast

	strNum =num2str(indexParticipant);
    if(length(strNum)<2)
        strNum = ['0',strNum];
    end
    participantLabel = ['participant',strNum];

    disp('----------------------------------------');
    disp(participantLabel);
    disp('----------------------------------------');
end
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

 [inputFolders,outputFolders]=getParticipantFolders(indexParticipant,...
										dataSetFolder,outputSetFolder);
                                    
                                       cd(outputFolders.common);
    %load a list of all of the file names in this folder
    outputAllParticipants = pwd();
    filesInAllParticipants = dir(outputAllParticipants);
    currentFile = ['emgPipelineOutput_', participantLabel,'.mat'];
    %search for the one with emgMvcMaxOutput_participant##
    participantEmgData = load(currentFile);
    cd(codeFolder)

%for loop over all of the trial files for a participantXX (indexTrial)
    %for loop over all of your conditions (indexCondition)
        %if the conditions of the trial match the conditions you're
        %interested in, then store the data
        %   conditionsToCompare(indexCondition).onsetTime = ...
        %       [conditionsToCompare(indexCondition).onsetTime;...
        %        newOnsetDataHere];
        %   conditionsToCompare(indexCondition).magnitude = ...
        %       [conditionsToCompare(indexCondition).magnitude;...
        %        magnitudeDataHere];
       %%
       	cd(inputFolders.carBiopac);    
	filesInCarBiopacFolder = dir();
	cd(codeFolder); 
    indexMatFile = [];
	for indexFile=1:1:length(filesInCarBiopacFolder)
        if(contains(filesInCarBiopacFolder(indexFile).name,'.mat'))
            indexMatFile = [indexMatFile;indexFile];
        end
    end
     for indexFile = 1:1:length(indexMatFile)

       fileNameBiopacData = ...
        	fullfile(filesInCarBiopacFolder(indexMatFile(indexFile,1)).folder,...
        	filesInCarBiopacFolder(indexMatFile(indexFile,1)).name);
     end

        %carBiopacDataRaw is left in its un processed form.
        carBiopacDataRaw = load(fileNameBiopacData);
       [biopacParameters, biopacKeywords, ...
 		 biopacChannels, biopacIndices] = getBiopacMetaData(carBiopacDataRaw);   
       %%
       for indexMuscle=biopacIndices.indicesOfEmgData
       
        for indexTrial=1:1:length(participantEmgData.participantEmgData)-2
             if(isempty...
                     (participantEmgData.participantEmgData(indexTrial)....
                     .biopacSignalIntervals(indexMuscle).intervalTimes)...
                     == 0)
           %problems with comparison of condition one and direction one:
           % when we are using strcmp the result are not correct
           %(distribuition of ones and zeros)
           %accordingly the calculations for the onset and magnitude do not
           %work
           %no problems for condition two and direction two; in the
           %resulting double there are still many zeros that are not
           %necessary, those would have to be deleted
          conditionOne(indexTrial)=...
              strcmp(participantEmgData.participantEmgData(indexTrial).condition,...
              conditionsToCompare(1).condition);
          directionOne(indexTrial)=...
              strcmp(participantEmgData.participantEmgData(indexTrial).carDirection,...
              conditionsToCompare(1).direction);
          conditionTwo(indexTrial)=...
              strcmp(participantEmgData.participantEmgData(indexTrial).condition,...
              conditionsToCompare(2).condition);
          directionTwo(indexTrial)=...
              strcmp(participantEmgData.participantEmgData(indexTrial).carDirection,...
              conditionsToCompare(2).direction);
          % extract values for which condition and direction is correct
            if conditionOne(indexTrial)==1 && directionOne(indexTrial)==1
              % calculate onsetTime
              onsetCarAccelerationOne(indexTrial,:)=...
                  participantEmgData.participantEmgData(indexTrial)...
                  .biopacSignalIntervals(biopacIndices.indexAccCarX).intervalTimes;
              onsetMuscleActivityOne(indexTrial,:)=...
                  participantEmgData.participantEmgData(indexTrial)...
                  .biopacSignalIntervals(indexMuscle).intervalTimes;
          
              onsetTimeFirstCase(indexTrial,indexMuscle)=...
                  onsetMuscleActivityOne(indexTrial,1)-onsetCarAccelerationOne(indexTrial,1);
              %extract amplitude of emg signal
              intervalMaxValOne(indexTrial,indexMuscle)=...
                  participantEmgData.participantEmgData(indexTrial)...
                  .biopacSignalIntervals(indexMuscle).intervalMaximumValue;

          % extract values for which condition and direction is correct
            elseif conditionTwo(indexTrial)==1 && directionTwo(indexTrial)==1
                % calculate onsetTime
              onsetCarAccelerationTwo(indexTrial,:)=...
                  participantEmgData.participantEmgData(indexTrial)...
                  .biopacSignalIntervals(biopacIndices.indexAccCarX).intervalTimes;
              onsetMuscleActivityTwo(indexTrial,:)=...
                  participantEmgData.participantEmgData(indexTrial)...
                  .biopacSignalIntervals(indexMuscle).intervalTimes;

              onsetTimeSecondCase(indexTrial,indexMuscle)=...
                  onsetMuscleActivityTwo(indexTrial,1)-onsetCarAccelerationTwo(indexTrial,1);
              %extract amplitude of emg signal              
               intervalMaxValTwo(indexTrial,indexMuscle)=...
                   participantEmgData.participantEmgData(indexTrial)...
                   .biopacSignalIntervals(indexMuscle).intervalMaximumValue;
            end
             end
        end
       end

%

%Build a plot that contains a box-whisker illustration for each 
%condition

%Perform a Wilcoxon ranksum test to test the probability that the two
%distributions are the same.