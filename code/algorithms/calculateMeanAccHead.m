function [meanOnsetTimes, stdOnsetTimes, onsetTimes] = ...
            calculateMeanAccHead(flag_dataSet) 

assert(flag_dataSet==0,'Error: This function has only been implemented for the 2022 dataset');

directionNames = {'Forward','Backwards','Right','Left'};
indexForward   = 1;
indexBackwards = 2;
indexRight     = 3;
indexLeft      = 4;

participantFirst = 1;
participantLast  = 21;
numberOfDirections = length(directionNames);
seatPosition = 'nominal';

minimalOnset = 0;
maximalOnset = 0.3;

carAccChannel = 8;
headAccChannel =12; 

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

onsetTimes(numberOfDirections) = struct('id',[],'indexTrial',[],'headOnsetTime',[]);

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

    for indexTrial = 1:1:length(participantEmgData)
        conditionCorrect = strcmp(participantEmgData(indexTrial).condition,seatPosition);
    
        for indexDirection  = 1:1:numberOfDirections
            carDirectionCorrect = ...
                strcmp(participantEmgData(indexTrial).carDirection,...
                       directionNames(indexDirection));
        
                if conditionCorrect && carDirectionCorrect
                  startAccCar = participantEmgData(indexTrial...
                      ).biopacSignalIntervals(carAccChannel...
                      ).intervalTimes(1);

                  startAccHead = participantEmgData(indexTrial...
                      ).biopacSignalIntervals(headAccChannel...
                      ).intervalTimes(1);

                  onsetHeadAcc = startAccHead-startAccCar;
               
                    if(onsetHeadAcc < minimalOnset)
                        disp(sprintf('Warning: onsetHeadAcc < 0: %1.3f',onsetHeadAcc));
                    end

                    if onsetHeadAcc > minimalOnset && onsetHeadAcc < maximalOnset 
                        onsetTimes(indexDirection).headOnsetTime = ...
                            [onsetTimes(indexDirection).headOnsetTime(:);...
                             onsetHeadAcc];
            
                        onsetTimes(indexDirection).id = ...
                            [onsetTimes(indexDirection).id;...
                             indexParticipant];
            
                        onsetTimes(indexDirection).indexTrial = ...
                            [onsetTimes(indexDirection).indexTrial;...
                             indexTrial];
                    end
                   

                end 
         end 

    end 

end 

% mean and standard deviation of onset times for each direction 

for indexDirection = 1:1:numberOfDirections
    meanOnsetTimes(indexDirection) = mean(onsetTimes(indexDirection).headOnsetTime);
    stdOnsetTimes(indexDirection) = std(onsetTimes(indexDirection).headOnsetTime);
end 

flag_debug = 0;
if(flag_debug==1)
    figDebugHeadOnsetTimes = figure;
    assert(numberOfDirections==4);
    for indexDirection=1:1:numberOfDirections
        subplot(2,2,indexDirection);
        
        [n,edges] = histcounts(onsetTimes(indexDirection).headOnsetTime,'Normalization','probability');
        
        for indexBin=1:1:length(n)
            nA = n(1,indexBin);
            edgeA = edges(1,indexBin);
            edgeB = edges(1,indexBin+1);            
            fill([0;nA;nA;0;0], [edgeA;edgeA;edgeB;edgeB;edgeA],...
                [1,1,1].*0.75);
            hold on;            
        end

        xOffset = max(n)*1.2;
        xDelta  = max(n)*0.1;

        noDataNumber=-1;
        percentileSet=[0.05,0.25,0.5,0.75,0.95]';
        [percentilesOnsetTime, validDataOnsetTimes] = ...
            getPercentiles( onsetTimes(indexDirection).headOnsetTime,...
                            percentileSet,noDataNumber);        
        
        p05 = percentilesOnsetTime(1,1);
        p25 = percentilesOnsetTime(2,1);
        p50 = percentilesOnsetTime(3,1);
        p75 = percentilesOnsetTime(4,1);
        p95 = percentilesOnsetTime(5,1);
        
        %Plot the whisker: from 5-95%
        plot([1;1].*xOffset,[p05;p95],'-','Color',[0,0,0]);
        hold on;
        plot([1].*xOffset,[p05],'o','Color',[0,0,0],'MarkerFaceColor',[0,0,0]);
        hold on;
        plot([1].*xOffset,[p95],'o','Color',[0,0,0],'MarkerFaceColor',[0,0,0]);
        hold on;
        
        
        %Plot the box: from 25-75%
        xL = xOffset-xDelta;
        xR = xOffset+xDelta;
        fill([xL;xR;xR;xL;xL],[p25;p25;p75;p75;p75],[1,1,1]);
        hold on;
        
        %Plot the median whisker
        plot([xL;xR],[p50;p50],'Color',[0,0,0],'LineWidth',2);
        hold on;
        
        xRR = xOffset+2*xDelta;
            for j=1:1:size(percentileSet,1)
                text(xRR, percentilesOnsetTime(j,1), ... 
                     sprintf('%i%s',percentileSet(j,1)*100,'$$^{th}$$'),...
                     'VerticalAlignment','middle',...
                     'HorizontalAlignment','center');
                hold on;
            end
        
        xlabel('Probability');        
        ylabel('Time (s)');
        title(['Head onset time: ', directionNames{indexDirection} ]);
        box off;
        here=1;


    end
end



