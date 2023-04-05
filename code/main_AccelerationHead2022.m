close all
clear all 
clc 

directionNames = {'Forward','Backwards','Right','Left'};
indexForward   = 1;
indexBackwards = 2;
indexRight     = 3;
indexLeft      = 4;

participantFirst = 1;
participantLast  = 21;
numberOfDirections = length(directionNames);
seatPosition = 'nominal';
% numberOfParticipants = participantLast-participantFirst + 1;

%Local folders
addpath('inputOutput');

%Check that Matlab is currently in the code directory
localPath=pwd();
[parentFolderPath,parentFolder] = fileparts(localPath);

assert(contains(parentFolder,'code'));
assert(contains(parentFolderPath,'WhiplashExperimentProcessing'));

whiplashFolder= parentFolderPath;
codeFolder=localPath;

dataSetFolder = fullfile(whiplashFolder,'data2022');
outputSetFolder=fullfile(whiplashFolder,'output2022'); 

% directionStruct(numberOfDirections)...
% = struct ('Forward',[],... 
%           'Backwards',[],...
%           'Right',[],... 
%           'Left',[]);

onsetTimes(numberOfDirections) = struct('id',[],'indexTrial',[],'headOnsetTime',[]);



% directionStruct = struct( 'Forward',[],... 
%                           'Backwards',[],...
%                           'Right',[],... 
%                           'Left',[]);


% these define the total numbers of trials for each direction 
nForward= 0;
nBackwards = 0;
nRight = 0;
nLeft = 0;

for indexParticipant = 2:1:participantLast    %%  ignore first participant 


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


if(exist('onsetHeadAcc','var'))
 clear('onsetHeadAcc');
end

for indexTrial = 1:1:length(participantEmgData)

    if strcmp(participantEmgData(indexTrial).condition,seatPosition) == 1
      
        if  strcmp(participantEmgData(indexTrial).carDirection,'Forward') == 1
            startAccCar = participantEmgData(indexTrial).biopacSignalIntervals(8).intervalTimes(1);
            startAccHead = participantEmgData(indexTrial).biopacSignalIntervals(12).intervalTimes(1);
            if (exist ('onsetHeadAccForward','var'))
                nForward = nForward+1;
                temporaryMeanForward = onsetHeadAccForward;
            end 
            onsetHeadAccForward = startAccHead-startAccCar;
          
            if (exist ('onsetHeadAccPreviousForward','var'))
                arrayOfMeans = ones(1,nForward)*temporaryMeanForward;
                arrayForMeanCalculation = [onsetHeadAccForward, arrayOfMeans];
                meanOnsetHeadAccForward = mean(arrayForMeanCalculation);  
                onsetHeadAccForward = meanOnsetHeadAccForward;
            end 

            onsetTimes(indexForward).headOnsetTime = ...
                [onsetTimes(indexForward).headOnsetTime(:);...
                 onsetHeadAccForward];

            onsetTimes(indexForward).id = ...
                [onsetTimes(indexForward).id;...
                 indexParticipant];

            onsetTimes(indexForward).indexTrial = ...
                [onsetTimes(indexForward).indexTrial;...
                 indexTrial];
            
           
        elseif strcmp(participantEmgData(indexTrial).carDirection,'Backwards') == 1
            startAccCar = participantEmgData(indexTrial).biopacSignalIntervals(8).intervalTimes(1);
            startAccHead = participantEmgData(indexTrial).biopacSignalIntervals(12).intervalTimes(1);
            if (exist ('onsetHeadAccBackwards','var'))
                nBackwards = nBackwards+1;
                temporaryMeanBackwards = onsetHeadAccBackwards;
            end 
            onsetHeadAccBackwards = startAccHead-startAccCar;
          
            if (exist ('onsetHeadAccPreviousBackwards','var'))
                arrayOfMeans = ones(1,nBackwards)*temporaryMeanBackwards;
                arrayForMeanCalculation = [onsetHeadAccBackwards, arrayOfMeans];
                meanOnsetHeadAccBackwards = mean(arrayForMeanCalculation);  
                onsetHeadAccBackwards = meanOnsetHeadAccBackwards;
            end 

           onsetTimes(indexBackwards).headOnsetTime = ...
                [onsetTimes(indexBackwards).headOnsetTime(:);...
                 onsetHeadAccBackwards];

            onsetTimes(indexBackwards).id = ...
                [onsetTimes(indexBackwards).id;...
                 indexParticipant];
            
            onsetTimes(indexBackwards).indexTrial = ...
                [onsetTimes(indexBackwards).indexTrial;...
                 indexTrial];

        elseif strcmp(participantEmgData(indexTrial).carDirection,'Right') == 1
            startAccCar = participantEmgData(indexTrial).biopacSignalIntervals(9).intervalTimes(1);
            startAccHead = participantEmgData(indexTrial).biopacSignalIntervals(13).intervalTimes(1);
           if (exist ('onsetHeadAccRight','var'))
                nRight = nRight+1;
                temporaryMeanRight = onsetHeadAccRight;
            end 
            onsetHeadAccRight = startAccHead-startAccCar;
          
            if (exist ('onsetHeadAccPreviousRight','var'))
                arrayOfMeans = ones(1,nRight)*temporaryMeanRight;
                arrayForMeanCalculation = [onsetHeadAccRight, arrayOfMeans];
                meanOnsetHeadAccRight = mean(arrayForMeanCalculation);  
                onsetHeadAccRight = meanOnsetHeadAccRight;
            end 

           onsetTimes(indexRight).headOnsetTime = ...
                [onsetTimes(indexRight).headOnsetTime(:);...
                 onsetHeadAccRight];

            onsetTimes(indexRight).id = ...
                [onsetTimes(indexRight).id;...
                 indexParticipant];
            
            onsetTimes(indexRight).indexTrial = ...
                [onsetTimes(indexRight).indexTrial;...
                 indexTrial];



        elseif strcmp(participantEmgData(indexTrial).carDirection,'Left') == 1
            startAccCar = participantEmgData(indexTrial).biopacSignalIntervals(9).intervalTimes(1);
            startAccHead = participantEmgData(indexTrial).biopacSignalIntervals(13).intervalTimes(1);
            if (exist ('onsetHeadAccLeft','var'))
                nLeft = nLeft+1;
                temporaryMeanLeft = onsetHeadAccLeft;
            end 
            onsetHeadAccLeft = startAccHead-startAccCar;
          
            if (exist ('onsetHeadAccPreviousLeft','var'))
                arrayOfMeans = ones(1,nLeft)*temporaryMeanLeft;
                arrayForMeanCalculation = [onsetHeadAccLeft, arrayOfMeans];
                meanOnsetHeadAccLeft = mean(arrayForMeanCalculation);  
                onsetHeadAccLeft = meanOnsetHeadAccLeft;
            end 

           onsetTimes(indexLeft).headOnsetTime = ...
                [onsetTimes(indexLeft).headOnsetTime(:);...
                 onsetHeadAccLeft];     

            onsetTimes(indexLeft).id = ...
                [onsetTimes(indexLeft).id;...
                 indexParticipant];
            
            onsetTimes(indexLeft).indexTrial = ...
                [onsetTimes(indexLeft).indexTrial;...
                 indexTrial];           

        end 

    end 
end 

end 


