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

ecgWindowDuration                   = 0.160; %Total window width
ecgWindowHighpassFilterFrequency    = 20;  %20-30 Hz
%Hof AL. A simple method to remove ECG artifacts from trunk muscle 
%MG signals. Journal of Electromyography and Kinesiology. 2009;6(19):e554-5.

%%
%EMG processing
%%
emgEnvelopeLowpassFilterFrequency = 10;
onsetNumberOfClusters = 2;


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
    ecgWindowDuration, ecgWindowHighpassFilterFrequency, ...
    carBiopacSampleFrequency);

%%
% Calculate the EMG envelope
%%
carBiopacDataB = calcEmgEnvelope(carBiopacDataA,emgKeyword, ...
    emgEnvelopeLowpassFilterFrequency, carBiopacSampleFrequency);

%%
% Identify the signal onset
%%
idxSubplot=1;
flag_plotOnset =1;
timeV = [];
if(flag_plotOnset==1)
    dt=(1/carBiopacSampleFrequency);
    duration = (size(carBiopacDataB.data,1)/carBiopacSampleFrequency);
    timeV = [dt:dt:duration]';
    figOnset = figure;
end

for i=1:1:size(carBiopacDataB.labels,1)
    if(contains(carBiopacDataB.labels(i,:),emgKeyword))
        
        if(flag_plotOnset==1 && idxSubplot<=9)
            figure(figOnset);
            subplot(3,3,idxSubplot)
            plot(timeV,carBiopacDataB.data(:,i),'Color',[1,1,1].*0.5);
            hold on;
            box off;
            xlabel('Time');
            ylabel('Volts');
            title(carBiopacDataB.labels(i,:));
        end
        
        [indexOnset, dataLabels] = findOnset(carBiopacDataB.data(:,i),...
            onsetNumberOfClusters);

        if(flag_plotOnset==1 && idxSubplot<=9)
            figure(figOnset);
            subplot(3,3,idxSubplot)
            minVal = min(carBiopacDataB.data(:,i));
            maxVal = max(carBiopacDataB.data(:,i));

            for k=1:1:length(indexOnset)
                plot([1;1].*timeV(indexOnset(k,1)), ...
                     [minVal;maxVal],'Color',[0,0,0]);
                hold on;
                plot([1].*timeV(indexOnset(k,1)), ...
                     [maxVal],'o','Color',[0,0,0]);
                hold on;
            end
        end
        idxSubplot=idxSubplot+1;

    end
end




here=1;

