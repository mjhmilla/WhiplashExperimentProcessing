clc;
close all;
clear all;

%%
% Folders
%%

% / : linux
% \ : windows
slashChar = '/';

% Set this to the full path of the code directory
codeFolder = ['/home/mmillard/work/code/stuttgart/',...
              'FKFS/WhiplashExperimentProcessing/code'];

%For a simple example here I'll manually set the folder that we 
%are going to process. For the real script these folders will
%be processed one-by-one
mvcFolder = ['../data/00_raw/mvc/biopac/02May2022_Monday/',...
               '2022_05_02_Subject1_0830'];

carBiopacFolder = ['../data/00_raw/car/biopac/02May2022_Monday/',...
               'Proband1_2022_05_02'];

%%
% Biopac information
%%
carBiopacSampleFrequency =2000; %Hz
emgKeyword      = 'EMG100C';
ecgKeyword      = 'ECG';
acc1Keyword     = 'TSD109C';
acc2Keyword     = 'TSD109C2';
triggerKeyword  = 'Trigger';
loadcellKeyword = 'loadcell';
forceKeyword    = 'Force';

%%
%Ecg removal settings
%%

flag_ecgRemovalAlgorithm = 0;
% 0: Window & filter 
% 1: LSQ and subtract (not yet implemented)

ecgRemovalFilterWindowParams = struct('windowDuration',0.16,...
                                      'highpassFilterFrequency',20);
%Hof AL. A simple method to remove ECG artifacts from trunk muscle 
%MG signals. Journal of Electromyography and Kinesiology. 2009;6(19):e554-5.

%%
%EMG processing
%%
emgEnvelopeLowpassFilterFrequency = 5;

onsetKmeansParameters = struct('numberOfClusters',2,... 
                               'standardDeviationThreshold', 3);

onsetPercentileThreshold = 0.975;


%%
%Plotting configuration
%%
numberOfHorizontalPlotColumnsGeneric = 3;
numberOfVerticalPlotRowsGeneric      = 3;
plotWidthCm          = 4.5; 
plotHeightCm         = 4.5;
plotHorizMarginCm    = 1.5;
plotVertMarginCm     = 1.5;

[subPlotPanel, ...
 pageWidthCm, ...
 pageHeightCm]= ...
      plotConfigGeneric(  numberOfHorizontalPlotColumnsGeneric,...
                          numberOfVerticalPlotRowsGeneric,...
                          plotWidthCm,...
                          plotHeightCm,...
                          plotHorizMarginCm,...
                          plotVertMarginCm);


%%
%Check that we're in the correct directory
%%
localPath = pwd();
idxSlash = strfind(localPath,slashChar);
parentFolder      = localPath(1,idxSlash(end):end);
grandParentFolder = localPath(1,idxSlash(end-1):idxSlash(end));
assert(contains(parentFolder,'code'));
assert(contains(grandParentFolder,'WhiplashExperimentProcessing'));

%%
%Go to the car-biopac-folder 
%%
cd(carBiopacFolder);
filesCarBiopacFolder = dir();
cd(codeFolder);

%Go and find the first *.mat file 
indexMatFile = 0;
for indexFile=1:1:length(filesCarBiopacFolder)
    if(contains(filesCarBiopacFolder(indexFile).name,'.mat') ...
            && indexMatFile==0)
        indexMatFile = indexFile;
    end
end


fprintf('Loading: \t%s\n',filesCarBiopacFolder(indexMatFile).name);
carBiopacData = load([filesCarBiopacFolder(indexMatFile).folder,...
                     slashChar,...
                      filesCarBiopacFolder(indexMatFile).name]);
fprintf('  Channel labels:\n');


for i=1:1:size(carBiopacData.labels,1)
    fprintf('  %i.\t%s\n',i,carBiopacData.labels(i,:));  
end

%Check that the time unit is ms
assert(contains(carBiopacData.isi_units,'ms'));
%Check that the time unit scaling is 0.5 - 0.5ms per data point, or 2000Hz
assert(carBiopacData.isi == 0.5);

%%
% Remove the ECG waveforms from the EMG data
%%
carBiopacDataA = removeEcgFromEmg(carBiopacData, emgKeyword, ecgKeyword,...
    ecgRemovalFilterWindowParams, ...
    carBiopacSampleFrequency,flag_ecgRemovalAlgorithm);

%%
% Calculate the EMG envelope
%%
carBiopacDataB = calcEmgEnvelope(carBiopacDataA,emgKeyword, ...
    emgEnvelopeLowpassFilterFrequency, carBiopacSampleFrequency);

%%
% Identify the signal onset
%%

carBiopacSignal = carBiopacDataB;


idxSubplot=1;
flag_plotOnset =1;
timeV = [];
if(flag_plotOnset==1)
    dt=(1/carBiopacSampleFrequency);
    duration = (size(carBiopacSignal.data,1)/carBiopacSampleFrequency);
    timeV = [dt:dt:duration]';
    figOnset = figure;
    figAdaptiveThreshold = figure;
end

for i=1:1:size(carBiopacSignal.labels,1)
    if(contains(carBiopacSignal.labels(i,:),emgKeyword))
        
        data=carBiopacSignal.data(:,i);

        data = data-mean(data);
        data = abs(data)./std(data);
       
        %Evaluate the distribution of the data
        [nData,dataEdges] = histcounts(data,100,'Normalization','cdf');

        onsetStandardDeviationThreshold = ...
            interp1(nData,dataEdges(1,2:end),onsetPercentileThreshold);

        if(flag_plotOnset==1 && idxSubplot<=9)
            figure(figOnset);
            %subplot(3,3,idxSubplot)
            row = ceil(idxSubplot/3);
            col = max(1,idxSubplot-(row-1)*3);
            subplot('Position',reshape(subPlotPanel(row,col,:),1,4));

            timeMin=min(timeV);
            timeMax=max(timeV);            
            fill([timeMin;timeMax;timeMax;timeMin;timeMin],...
                 [0;0;1;1;0].*onsetStandardDeviationThreshold,...
                 [1,1,1].*0.75);
            hold on;

            plot(timeV,data,'Color',[0,0,0]);
            hold on;
            box off;
            xlabel('Time');
            ylabel('Std.');            
            title(replaceCharacter(carBiopacSignal.labels(i,:),'_',' '));


            figure(figAdaptiveThreshold);
            row = ceil(idxSubplot/3);
            col = max(1,idxSubplot-(row-1)*3);
            subplot('Position',reshape(subPlotPanel(row,col,:),1,4));

            plot(dataEdges(1,2:end),nData,'Color',[0,0,0]);
            hold on;
            plot(onsetStandardDeviationThreshold ,...
                 onsetPercentileThreshold,'.','MarkerSize',10);
            hold on;
            text(onsetStandardDeviationThreshold, ...
                onsetPercentileThreshold-0.05,...
                sprintf('%1.2f',onsetStandardDeviationThreshold));
            hold on;
            box off;
            xlabel('Std.');
            ylabel('Cumulative Distribution');
            title(replaceCharacter(carBiopacSignal.labels(i,:),'_',' '));

        end

        
        %onsetKmeansParameters.standardDeviationThreshold
        [indexOnset, dataLabels] = findOnsetUsingKmeans(data,...
            onsetKmeansParameters.numberOfClusters, ...
            onsetStandardDeviationThreshold);

        if(flag_plotOnset==1 && idxSubplot<=9)
            figure(figOnset);
            row = ceil(idxSubplot/3);
            col = max(1,idxSubplot-(row-1)*3);
            subplot('Position',reshape(subPlotPanel(row,col,:),1,4));

            minVal = 0;
            maxVal = max(data);
            for k=1:1:size(indexOnset,1)     
                timeStart=timeV(indexOnset(k,1));
                timeEnd=timeV(indexOnset(k,2));      

                plot([1;1].*timeStart,[0;1].*maxVal,'-','Color',[1,0,0]);                
                hold on;
                plot([1].*timeStart,[1].*maxVal,'o','Color',[1,0,0]);                
                hold on;

            end
            box off;
        end
        idxSubplot=idxSubplot+1;

    end
end


figOnset = configPlotExporter( figOnset,...
                                pageWidthCm,...
                                pageHeightCm);

print('-dpdf', '../output/fig_Onset.pdf');

figAdaptiveThreshold = configPlotExporter( figAdaptiveThreshold,...
                                pageWidthCm,...
                                pageHeightCm);

print('-dpdf', '../output/fig_AdaptiveThresholds.pdf');




here=1;

