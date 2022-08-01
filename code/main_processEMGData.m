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
% Accelerometer processing
%%
accelerometerLowpassFilterFrequency = 10;

%%
%EMG processing
%%
emgEnvelopeLowpassFilterFrequency   = 5;

onsetKmeansParameters = struct('numberOfClusters',2,... 
                               'standardDeviationThreshold', 3);

lowerPercentileThreshold = 0.975;
upperThresholdScaling    = 0.5; %


%%
%Plotting configuration
%%
maxPlotRows          = 4;
maxPlotCols          = 3;
plotWidthCm          = 4.5; 
plotHeightCm         = 4.5;
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
% Smooth the accelerometer data
%%
carBiopacDataC = smoothAccelerations(carBiopacDataB,acc1Keyword,...
    accelerometerLowpassFilterFrequency,carBiopacSampleFrequency);

carBiopacDataC = smoothAccelerations(carBiopacDataC,acc2Keyword,...
    accelerometerLowpassFilterFrequency,carBiopacSampleFrequency);

%%
% Identify the signal onset
%%

carBiopacSignal = carBiopacDataC;


idxSubplot=1;
flag_plotOnset =1;
timeV = [];
if(flag_plotOnset==1)
    dt=(1/carBiopacSampleFrequency);
    duration = (size(carBiopacSignal.data,1)/carBiopacSampleFrequency);
    timeV = [dt:dt:duration]';
    figOnset = figure;
end

for i=1:1:size(carBiopacSignal.labels,1)
    if(contains(carBiopacSignal.labels(i,:),emgKeyword) ...
            || contains(carBiopacSignal.labels(i,:),acc1Keyword)...
            || contains(carBiopacSignal.labels(i,:),acc2Keyword))
        


        [peakIntervals, thresholdLower, thresholdUpper] = ...
            findOnsetUsingAdaptiveThreshold(carBiopacSignal.data(:,i), ...
                                    lowerPercentileThreshold,...
                                    upperThresholdScaling);

%         if(    contains(carBiopacSignal.labels(i,:),acc1Keyword)...
%             || contains(carBiopacSignal.labels(i,:),acc2Keyword) )
% 
%            [peakIntervalsNeg, thresholdLowerNeg, thresholdUpperNeg] = ...
%                     findOnsetUsingAdaptiveThreshold(-carBiopacSignal.data(:,i), ...
%                                             lowerPercentileThreshold,...
%                                             upperThresholdScaling);
% 
%             peakIntervals = [peakIntervals;peakIntervalsNeg];
%             
%         end

        if(flag_plotOnset==1 && idxSubplot<=(maxPlotCols*maxPlotRows))
            figure(figOnset);
            row = ceil(idxSubplot/maxPlotCols);
            col = max(1,idxSubplot-(row-1)*maxPlotCols);
            if(col > 3)
                here=1;
            end
            subplot('Position',reshape(subPlotPanel(row,col,:),1,4));


            minVal = min(carBiopacSignal.data(:,i));
            maxVal = max(carBiopacSignal.data(:,i));
            timeMin = min(timeV);
            timeMax = max(timeV);

            fill([timeMin;timeMax;timeMax;timeMin;timeMin],...
                 [minVal;minVal;thresholdLower;thresholdLower;minVal],[1,1,1].*0.75,...
                 'EdgeColor','none');
            hold on;

            plot([timeMin;timeMax],[1;1].*thresholdUpper,'--','Color',[0,0,0]);
            hold on;            
            
            plot(timeV, carBiopacSignal.data(:,i),'Color',[0,0,0]);
            hold on;            
            
            for k=1:1:size(peakIntervals,1)   
                i1 = peakIntervals(k,1);
                i2 = peakIntervals(k,2);
                t0 = timeV(i1,1);
                t1 = timeV(i2,1);     
                v1 = carBiopacSignal.data(i1,i);
                vMax = max(carBiopacSignal.data(i1:i2,i));
                v2 = carBiopacSignal.data(i2,i);

                plot([t0;t1;t1;t0;t0],[v1;v2;vMax;vMax;v1],'Color',[1,0,0]);
                hold on;
                tt = t0-(t1-t0)*0.05;
                vt = v1;
                plot(tt,vt,'o','Color',[1,0,0]);                
                hold on;
                text(tt,vt,sprintf('%1.3f',t0),...
                    'VerticalAlignment','bottom',...
                    'HorizontalAlignment','right');
                hold on;
                %axis tight;
            end
            xlabel('Time (s)');
            ylabel('Value');
            title(replaceCharacter(carBiopacSignal.labels(i,:),'_',' '));
            box off;
        end
        idxSubplot=idxSubplot+1;

    end
end


figOnset = configPlotExporter( figOnset,...
                                pageWidthCm,...
                                pageHeightCm);

print('-dpdf', '../output/fig_Onset.pdf');

here=1;

