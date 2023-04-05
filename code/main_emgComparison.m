%%main_emgComparison
clc;
close all;
clear all;

flag_subtractMeanHeadOnsetTimesFrom2023EmgData = 0;

%Notes to improve participantEmgData
% 1. Get rid of the first 2 elements
% 2. Change flag_ignoreTrial to flag_useTrial

% 0: 2022 data set
% 1: 2023 data set
flag_dataSet    = 1;


dataSet2022 = 0; %Constant: do not change
dataSet2023 = 1; %Constant: do not change

participantFirst= 1;
participantLast = 28;

percentileSet       = [0.05;0.25;0.5;0.75;0.95];

%Input
noDataNumber = -1;
firstMuscleBiopacIndex=1;
lastMuscleBiopacIndex=6;
numberOfMuscles = lastMuscleBiopacIndex-firstMuscleBiopacIndex+1;
                    
numberOfConditions = 4;
conditionsToCompare(numberOfConditions) ...
    = struct('condition','',... 
             'carDirection','',...
             'columnNames',      [],... 
             'times',            [],...
             'magnitudes',       [],...
             'participantIndex',[],...
             'trialIndex',      [],...
             'fileName'  ,      []);

disp('Participant 1 in 2023 breaks left/right analysis');
disp('because they did not have 3 repeats collected. Blocks X and Y need');
disp('to be updated');
conditionsToCompare(1).condition='nominal';
conditionsToCompare(1).carDirection='Forward';

conditionsToCompare(2).condition='seatBack';
conditionsToCompare(2).carDirection='Forward';

conditionsToCompare(3).condition='nominal';
conditionsToCompare(3).carDirection='Backwards';

conditionsToCompare(4).condition='seatBack';
conditionsToCompare(4).carDirection='Backwards';

directionNames = {'Forward','Backwards','Right','Left'};
indexForward   = 1;
indexBackwards = 2;
indexRight     = 3;
indexLeft      = 4;

muscleNames = {'STR:L','STR:R','TRO:L','TRO:R','SPL:L','SPL:R'};

%Local folders
addpath('inputOutput');
addpath('algorithms');

%Check that Matlab is currently in the code directory
localPath=pwd();
[parentFolderPath,parentFolder] = fileparts(localPath);

assert(contains(parentFolder,'code'));
assert(contains(parentFolderPath,'WhiplashExperimentProcessing'));

whiplashFolder= parentFolderPath;
codeFolder=localPath;


[meanHeadOnsetTimes2022, stdHeadOnsetTimes2022, headOnsetTimes2022] ...
    = calculateMeanAccHead(dataSet2022);

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


dataParticipantConditions=buildConditionDataTable(participantFirst,participantLast,dataSetFolder,...
    outputSetFolder,conditionsToCompare,firstMuscleBiopacIndex,...
    lastMuscleBiopacIndex,numberOfMuscles,noDataNumber);

here=1;


%% create struct/array for plot
%should include all trials for all participants and muscles for one
%condition

outputOnsetTimes(numberOfConditions) ...
    = struct('allMuscles',[]);


outputAmplitude(numberOfConditions)...
     = struct('allMuscles',[]);



% This function does 2 things
% 1. Gets the number of times a trial x condition is repeated (sizeArray)
% 2. Makes a vector of indices to hold all of the 
%       participants x trial x condition
%
disp('Block X. Update this code to something easier to understand');
indexParticipant=1;
for indexCondition=1:1:length(conditionsToCompare)
    sizeArray(:,indexCondition) =...
        height(dataParticipantConditions(...
                indexParticipant).conditions(indexCondition).times);
    storedPosition(indexCondition,:) = ...
        [1:sizeArray(indexCondition):participantLast*sizeArray(indexCondition)];
end 

%
% This function fishes out all of the onset times for a specific muscle
% and groups it across the entire data set but separated by condition.
%
% Consider replacing this with an accumulation.
%
disp('Block Y. Update this code to something easier to understand');
for indexParticipant = participantFirst:1:participantLast
    for indexCondition=1:1:length(conditionsToCompare)
        for indexMuscle = firstMuscleBiopacIndex:1:lastMuscleBiopacIndex
            outputOnsetTimes(indexCondition).allMuscles(storedPosition(indexCondition,indexParticipant):...
                storedPosition(indexCondition,indexParticipant)+sizeArray(indexCondition)-1,indexMuscle)...
                = dataParticipantConditions(indexParticipant).conditions...
                (indexCondition).times(:,indexMuscle);

            outputAmplitude(indexCondition).allMuscles(storedPosition(indexCondition,indexParticipant):...
                storedPosition(indexCondition,indexParticipant)+sizeArray(indexCondition)-1,indexMuscle)...
                = dataParticipantConditions(indexParticipant).conditions...
                (indexCondition).magnitudes(:,indexMuscle);
            
        end
    end 
end 


if(flag_subtractMeanHeadOnsetTimesFrom2023EmgData==1)
    for indexCondition = 1:1:length(conditionsToCompare)
        if flag_dataSet == 1
            for indexDirection = 1:1:length(directionNames)
                if strcmp (conditionsToCompare(indexCondition).carDirection, ...
                           directionNames(indexDirection))


                    indexValidData = ...
                        find(outputOnsetTimes(indexCondition).allMuscles ~= noDataNumber);

                    outputOnsetTimes(indexCondition).allMuscles(indexValidData) = ...
                        outputOnsetTimes(indexCondition).allMuscles(indexValidData) ...
                        -meanHeadOnsetTimes2022(indexDirection);
                end
            end 
        end 
    end 
end

%%
%Build a plot that contains a box-whisker illustration for each 
%condition

%% calculate percentiles 

outputPercentiles(numberOfConditions) ...
    = struct('percentilesOnsetTimes',[],...
             'percentilesAmplitudes',[]);

outputValidData(numberOfMuscles)...
    = struct ('validDataOnsetTimes',[],...
              'validDataAmplitudes',[]);

flag_removeNegativeValues=1;

for indexCondition = 1:1:numberOfConditions
    for indexPercentile = 1:1:length(percentileSet)
        for indexMuscle = firstMuscleBiopacIndex:1:lastMuscleBiopacIndex
%             [percentilesOnsetTime(indexPercentile,indexMuscle), validDataOnsetTimes] ...
%                 = getPercentiles(...
%                     outputOnsetTimes(indexCondition).allMuscles(:,indexMuscle),...
%                     percentileSet(indexPercentile),noDataNumber);
%             [percentilesAmplitude(indexPercentile,indexMuscle), validDataAmplitudes] ...
%                 = getPercentiles(outputAmplitude(indexCondition).allMuscles(:,indexMuscle),...
%                 percentileSet(indexPercentile),noDataNumber);
               
            validDataOnsetTimes = extractValidData(...
                outputOnsetTimes(indexCondition).allMuscles(:,indexMuscle),...
                noDataNumber, flag_removeNegativeValues);

            validDataAmplitudes = extractValidData(...
                outputAmplitude(indexCondition).allMuscles(:,indexMuscle),...
                noDataNumber, flag_removeNegativeValues);
            
            percentilesOnsetTime(indexPercentile,indexMuscle) ...
                 = getPercentiles(validDataOnsetTimes,...
                        percentileSet(indexPercentile));

            percentilesAmplitude(indexPercentile,indexMuscle) ...
                 = getPercentiles(validDataAmplitudes,...
                        percentileSet(indexPercentile));


            outputValidData(indexCondition,indexMuscle).validDataOnsetTimes = validDataOnsetTimes;
            outputValidData(indexCondition,indexMuscle).validDataAmplitudes = validDataAmplitudes;

        end 
    end 
    outputPercentiles(indexCondition).percentilesOnsetTimes = percentilesOnsetTime;
    outputPercentiles(indexCondition).percentilesAmplitudes = percentilesAmplitude;
    
end 

%% OnsetTimes 
% Plot the distribution of the data

maxPlotRows          = 3;
maxPlotCols          = 2;
plotWidthCm          = 26.0; 
plotHeightCm         = 5.0;
plotHorizMarginCm    = 1.5;
plotVertMarginCm     = 1.5;

[subPlotPanel, ...
 pageWidthCm, ...
 pageHeightCm]= ...
      plotConfigGeneric(  maxPlotCols,...
                          maxPlotRows,...
                          plotWidthCm,...
                          plotHeightCm,...
                          plotHorizMarginCm,...
                          plotVertMarginCm);

for indexCondition = 1:1:numberOfConditions
    figDistribution = figure(indexCondition);
    for indexMuscle = firstMuscleBiopacIndex:1:lastMuscleBiopacIndex
        row = ceil(indexMuscle/maxPlotCols);
        col = indexMuscle-(row-1)*maxPlotCols;
       
        subplot('Position',reshape(subPlotPanel(row,col,:),1,4));
        [n,edges] = histcounts(outputValidData(indexCondition,indexMuscle).validDataOnsetTimes,'Normalization','probability');
        

       for indexBin=1:1:length(n)
            nA = n(1,indexBin);
            edgeA = edges(1,indexBin);
            edgeB = edges(1,indexBin+1);            
            fill([0;nA;nA;0;0], [edgeA;edgeA;edgeB;edgeB;edgeA],...
                [1,1,1].*0.75);
            hold on;
       end

    
    %%
    % Make a box and whisker plot beside the probability distribution
    %%
    xOffset = max(n)*1.2;
    xDelta  = max(n)*0.1;
    
    p05 = outputPercentiles(indexCondition).percentilesOnsetTimes(1,indexMuscle);
    p25 = outputPercentiles(indexCondition).percentilesOnsetTimes(2,indexMuscle);
    p50 = outputPercentiles(indexCondition).percentilesOnsetTimes(3,indexMuscle);
    p75 = outputPercentiles(indexCondition).percentilesOnsetTimes(4,indexMuscle);
    p95 = outputPercentiles(indexCondition).percentilesOnsetTimes(5,indexMuscle);
    
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
        for i=1:1:size(percentileSet,1)
            text(xRR, outputPercentiles(indexCondition).percentilesOnsetTimes(i,indexMuscle), ... 
                 sprintf('%i%s',percentileSet(i,1)*100,'$$^{th}$$'),...
                 'HorizontalAlignment','center');
            hold on;
        end
    
    xlabel('Probability');
    ylabel('OnsetTime [s]');
    titleMuscle = char(muscleNames(indexMuscle));
    titleCondition = char(conditionsToCompare(indexCondition).condition);
    titleCarDirection = char(conditionsToCompare(indexCondition).carDirection);
    textTitle = [titleMuscle,', ', titleCondition ,', ', titleCarDirection];
    title(textTitle);
    box off;
    end 
end

%% Amplitude 
% Plot the distribution of the data

for indexCondition = 1:1:numberOfConditions
    figDistribution = figure(indexCondition+numberOfConditions);
    for indexMuscle = firstMuscleBiopacIndex:1:lastMuscleBiopacIndex
        row = ceil(indexMuscle/maxPlotCols);
        col = indexMuscle-(row-1)*maxPlotCols;
       
        subplot('Position',reshape(subPlotPanel(row,col,:),1,4));
        [n,edges] = histcounts(outputValidData(indexCondition,indexMuscle).validDataAmplitudes,'Normalization','probability');
        
        for indexBin=1:1:length(n)
            nA = n(1,indexBin);
            edgeA = edges(1,indexBin);
            edgeB = edges(1,indexBin+1);            
            fill([0;nA;nA;0;0], [edgeA;edgeA;edgeB;edgeB;edgeA],...
                [1,1,1].*0.75);
            hold on;
        end

%         intervalMiddle = zeros(size(n));
%         for i=2:1:size(edges,2)
%             intervalMiddle(1,i-1) = 0.5.*(edges(1,i)+edges(1,i-1));
%         end
%     
%     fill([n';min(n);min(n)],...
%         [intervalMiddle';max(intervalMiddle);min(intervalMiddle)],...
%          [1,1,1].*0.75);
%     hold on;
%     
    
    %%
    % Make a box and whisker plot beside the probability distribution
    %%
    xOffset = max(n)*1.2;
    xDelta  = max(n)*0.1;
    
    p05 = outputPercentiles(indexCondition).percentilesAmplitudes(1,indexMuscle);
    p25 = outputPercentiles(indexCondition).percentilesAmplitudes(2,indexMuscle);
    p50 = outputPercentiles(indexCondition).percentilesAmplitudes(3,indexMuscle);
    p75 = outputPercentiles(indexCondition).percentilesAmplitudes(4,indexMuscle);
    p95 = outputPercentiles(indexCondition).percentilesAmplitudes(5,indexMuscle);
    
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
        for i=1:1:size(percentileSet,1)
            text(xRR, outputPercentiles(indexCondition).percentilesAmplitudes(i,indexMuscle), ... 
                 sprintf('%i%s',percentileSet(i,1)*100,'$$^{th}$$'),...
                 'VerticalAlignment','middle',...
                 'HorizontalAlignment','center');
            hold on;
        end
    
    xlabel('Probability');
    ylabel('Amplitude [mV]');
    titleMuscle = char(muscleNames(indexMuscle));
    titleCondition = char(conditionsToCompare(indexCondition).condition);
    titleCarDirection = char(conditionsToCompare(indexCondition).carDirection);
    textTitle = [titleMuscle,', ', titleCondition ,', ', titleCarDirection];
    title(textTitle);
    box off;
    end 
end


%Perform a Wilcoxon ranksum test to test the probability that the two
%distributions are the same.

for indexMuscle = firstMuscleBiopacIndex:1:lastMuscleBiopacIndex
    probabilityOnsetTimes(indexMuscle) = ranksum(outputValidData(1,indexMuscle).validDataOnsetTimes,outputValidData(2,indexMuscle).validDataOnsetTimes);
    probabilityAmplitudes(indexMuscle) = ranksum(outputValidData(1,indexMuscle).validDataAmplitudes,outputValidData(2,indexMuscle).validDataAmplitudes);
end 


