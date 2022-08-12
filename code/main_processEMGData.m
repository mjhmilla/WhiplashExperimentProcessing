clc;
close all;
clear all;



% / : linux
% \ : windows
slashChar = '/';

%%
%Check that we're in the correct directory
%%
localPath = pwd();
idxSlash = strfind(localPath,slashChar);
parentFolder      = localPath(1,idxSlash(end):end);
grandParentFolder = localPath(1,idxSlash(end-1):idxSlash(end));
assert(contains(parentFolder,'code'));
assert(contains(grandParentFolder,'WhiplashExperimentProcessing'));

codeFolder=localPath;


%%
% Folders
%%
addpath('algorithms/');
addpath('inputOutput/');


%For a simple example here I'll manually set the folder that we 
%are going to process. For the real script these folders will
%be processed one-by-one
%mvcFolder = ['../data/00_raw/mvc/biopac/02May2022_Monday/',...
%               '2022_05_02_Subject1_0830'];

carBiopacFolder = ['../data/00_raw/car/biopac/02May2022_Monday/',...
               'Proband4_2022_05_02'];

%%
% Biopac information
%%
carBiopacSampleFrequency =2000; %Hz
emgKeyword      = 'EMG100C';
ecgKeyword      = 'ECG';
accCarKeyword   = '- TSD109C -';
accHeadKeyword  = '- TSD109C2 / TSD109C3 -';
triggerKeyword  = 'Trigger';
loadcellKeyword = 'loadcell';
forceKeyword    = 'Force';


%%
% Biopac data to use for onset detection:
%%

flag_EMGProcessing =1;
%0: raw
%1: EMG: ECG signal reduced
%2: EMG: ECG signal removed + envelope calculated

flag_AccProcessing =0;
%0: raw
%1: Acceleration signal zero-phase low-pass filtered.

%%
%Ecg removal settings
%%

%Parameters for Norman's special ECG removal algorithm: 
% window & highpass filter
ecgRemovalFilterWindowParams = struct('windowDuration',0.16,...
                                      'highpassFilterFrequency',20);

%%
% Accelerometer processing
%%
accelerometerLowpassFilterFrequency = 10;

%%
%EMG processing
%%
emgEnvelopeLowpassFilterFrequency   = 10;

onsetKmeansParameters = struct('numberOfClusters',2,... 
                               'standardDeviationThreshold', 3);

%See the documentation for findOnsetUsingAdaptiveThreshold for details
peakMiddleThresholdPercentile     = 0.975;
peakMaximumThresholdScalingEMG    = 1;
peakMaximumThresholdScalingAcc    = 1;
peakBaseThresholdScaling          = 0.1;

minimumSamplesBetweenIntervals = round(0.050*carBiopacSampleFrequency);


switch flag_EMGProcessing
    case 0
        peakMaximumThresholdScalingEMG    = 5.0;
    case 1
        peakMaximumThresholdScalingEMG    = 3.5;
    case 2
        peakMaximumThresholdScalingEMG    = 1.0;
end 

switch flag_AccProcessing
    case 0
        peakMaximumThresholdScalingAcc    = 0.5;
    case 1
        peakMaximumThresholdScalingAcc    = 0.5;
    case 2
        peakMaximumThresholdScalingAcc    = 0.5;
end 

%%
% findOnsetWithinWindow 
%%

noiseThresholdPercentile = 0.95;

%%
% Onset settings
%%
minimumAcceptableOnsetTime = 0;
%Here a negative value means that the EMG signal started before the
%acceleration. This could happen if somehow the person was aware the
%acceleration was about to happen and tensed in preparation.

maximumAcceptableOnsetTime =  1;
%Here we pick a generous window following the acceleration onset in which
%we allow EMG signal onsets to be included.

maximumAcceptableNoiseProbability = 0.01;
%A peak is treated as being noise if there is a 
% maximumAcceptableNoiseProbability chanc of it being noise.

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
% Process the data
%%

%Go to the car-biopac-folder 
cd(carBiopacFolder);
filesCarBiopacFolder = dir();
cd(codeFolder);

%Go and find the first *.mat file 
indexMatFile = [];
for indexFile=1:1:length(filesCarBiopacFolder)
    if(contains(filesCarBiopacFolder(indexFile).name,'.mat'))
        indexMatFile = [indexMatFile;indexFile];
    end
end

idx=10;
fprintf('Loading: \t%s\n',filesCarBiopacFolder(indexMatFile(idx,1)).name);
carBiopacDataRaw = load([filesCarBiopacFolder(indexMatFile(idx,1)).folder,...
                     slashChar,...
                      filesCarBiopacFolder(indexMatFile(idx,1)).name]);

%Keep the original raw file on hand for plotting
carBiopacData=carBiopacDataRaw;
timeV = [];
dt=(1/carBiopacSampleFrequency);
duration = (size(carBiopacData.data,1)/carBiopacSampleFrequency);
timeV = [dt:dt:duration]';


fprintf('  Channel labels:\n');
for i=1:1:size(carBiopacData.labels,1)
    fprintf('  %i.\t%s\n',i,carBiopacData.labels(i,:));  
end

% build a table of indices
labelKeywords = {...
  'STR_L',...                                              
  'STR_R',...                                              
  'TRO_L',...                                              
  'TRO_R',...                                              
  'TRU_L',...                                              
  'TRU_R',...                                              
  'ECG'  ,...                                              
  'Ax - TSD109C',...             
  'Ay - TSD109C',...             
  'Az - TSD109C',...             
  'Force loadcell',...                     
  'ax2 - TSD109C2',...
  'ay2 - TSD109C2',...
  'az2 - TSD109C2',...
  'Trigger - Custom',...                            
  'Force in N'};

biopacIndices = struct(...
  'indexSTR_L',0,...                                              
  'indexSTR_R',0,...                                              
  'indexTRO_L',0,...                                              
  'indexTRO_R',0,...                                              
  'indexTRU_L',0,...                                              
  'indexTRU_R',0,...                                              
  'indexECG'  ,0,...                                              
  'indexAccCarX',0,...             
  'indexAccCarY',0,...             
  'indexAccCarZ',0,...             
  'indexLoadCell',0,...                     
  'indexAccHeadX',0,...
  'indexAccHeadY',0,...
  'indexAccHeadZ',0,...
  'indexTrigger',0,...                            
  'indexForce',0);

biopacFields = fields(biopacIndices);

for i=1:1:size(carBiopacData.labels,1)
    found=0;
    for j=1:1:length(labelKeywords)        
        if(contains(carBiopacData.labels(i,:),labelKeywords{j}) ...
                && found==0)
            biopacIndices.(biopacFields{j})=i;
            found=1;
        elseif((contains(carBiopacData.labels(i,:),labelKeywords{j}) ...
                && found==1))
            assert(0,'Error: label keywords are not unique');
        end

    end
end

%Check that the time unit is ms
assert(contains(carBiopacData.isi_units,'ms'));
%Check that the time unit scaling is 0.5 - 0.5ms per data point, or 2000Hz
assert(carBiopacData.isi == 0.5);

%%
% Remove the ECG waveforms from the EMG data
%%
if(flag_EMGProcessing >= 1)
    carBiopacData = removeEcgFromEmg(carBiopacData, emgKeyword, ecgKeyword,...
        ecgRemovalFilterWindowParams, ...
        carBiopacSampleFrequency);
end

%%
% Calculate the EMG envelope
%%
if(flag_EMGProcessing >= 2)
    carBiopacData = calcEmgEnvelope(carBiopacData,emgKeyword, ...
        emgEnvelopeLowpassFilterFrequency, carBiopacSampleFrequency);
end

%%
% Smooth the accelerometer data
%%

if(flag_AccProcessing >= 1)
    carBiopacData = smoothAccelerations(carBiopacData,accCarKeyword,...
        accelerometerLowpassFilterFrequency,carBiopacSampleFrequency);
    
    carBiopacData = smoothAccelerations(carBiopacData,accHeadKeyword,...
        accelerometerLowpassFilterFrequency,carBiopacSampleFrequency);

end


%%
% Identify the signal onset
%%

numberOfSignals = size(carBiopacData.data,2);
carBiopacDataPeakIntervals(numberOfSignals) ...
    = struct('intervals',[],'middleThresholds',[],'maximumThresholds',[]);


indexSubplot=1;
flag_plotOnset =1;
if(flag_plotOnset==1)
    figOnset = figure;
end

flag_accHead = 0;
flag_accCar = 0;


%%
%1. Extract the onset time for the acceleration of the car
%%
for i=[biopacIndices.indexAccCarX,biopacIndices.indexAccHeadX]

    %Identify signal onset times from the norm of the acceleration
    accX = carBiopacData.data(:,i);
    accX = accX-median(accX);
    accY = carBiopacData.data(:,i+1);
    accY = accY-median(accY);
    accZ = carBiopacData.data(:,i+2);
    accZ = accZ-median(accZ);
    accNorm = (accX.^2+accY.^2+accZ.^2).^0.5;

    flag_plotOnsetDetails=0;
    [peakIntervals,...
        peakMiddleThresholds,...
        peakMaximumThresholds] = ...
        findOnsetUsingAdaptiveThreshold(accNorm, ...
                                peakMiddleThresholdPercentile,...
                                peakMaximumThresholdScalingAcc,...
                                peakBaseThresholdScaling,...
                                minimumSamplesBetweenIntervals,...
                                flag_plotOnsetDetails);

    for j=i:1:(i+2)
        carBiopacDataPeakIntervals(j).intervals   = ...
            peakIntervals;
        carBiopacDataPeakIntervals(j).middleThresholds = ...
            peakMiddleThresholds;
        carBiopacDataPeakIntervals(j).maximumThresholds = ...
            peakMaximumThresholds;
    end

    dataLabel='';
    if(contains(carBiopacData.labels(i,:),accHeadKeyword))
        dataLabel = 'Accelerometer: Head';

    end
    if(contains(carBiopacData.labels(i,:),accCarKeyword))
        dataLabel = 'Accelerometer: Car';
    end

    if(flag_plotOnset)
        [figOnset,indexSubplot] = ...
            addOnsetPlot(timeV, accNorm,...
                    [1, length(timeV)],...
                    carBiopacDataPeakIntervals(i),...
                    dataLabel,...
                    figOnset, subPlotPanel, indexSubplot);
    end
end

%%
% Identify the onset of EMG that occurs in a window after the car begins to
% move
%%

for i=1:1:size(carBiopacData.labels,1)
    if(contains(carBiopacData.labels(i,:),emgKeyword))
        
        indexAccStart = ...
            carBiopacDataPeakIntervals(biopacIndices.indexAccCarX).intervals(1,1);

        indicesOfWindow = [indexAccStart,indexAccStart] ...
            + [minimumAcceptableOnsetTime,...
               maximumAcceptableOnsetTime].*carBiopacSampleFrequency;
        indicesOfWindow = round(indicesOfWindow);



        flag_plotDetails=1;

        [peakInterval, noiseProbability,dataTransformed] = ...
            findOnsetWithinWindow(  carBiopacData.data(:,i), ...
                                    indicesOfWindow,...
                                    noiseThresholdPercentile,...
                                    maximumAcceptableNoiseProbability,...
                                    carBiopacSampleFrequency,...
                                    flag_plotDetails);


        carBiopacDataPeakIntervals(i).intervals   = ...
            [min(peakInterval),max(peakInterval)];
        carBiopacDataPeakIntervals(i).middleThresholds = ...
            nan;
        carBiopacDataPeakIntervals(i).maximumThresholds = ...
            nan;

        if(flag_plotOnset)
            dataLabel = carBiopacData.labels(i,:);
            dataLabel = dataLabel(1,1:max(30,length(dataLabel)));



            [figOnset,indexSubplot] = ...
                addOnsetPlot(timeV, dataTransformed,...
                        indicesOfWindow,...
                        carBiopacDataPeakIntervals(i),...
                        dataLabel,...
                        figOnset, subPlotPanel, indexSubplot);

        end
    end

end


%%
% Calculate delay times between each EMG channel & the head/car
% acceleration onset. Store the result in a table and write the table
% to a csv file
%%

indexHeadAcc = 0;
indexCarAcc  = 0;

onsetData = [{'EMG_Ch_Name'},...
             {'OnsetDelay_CarAcc_ms'},...
             {'OnsetDelay_HeadAcc_ms'}];

%Go get the indices of the head and car accelerometers
for i=1:1:size(carBiopacData.labels,1)
    if(contains(carBiopacData.labels(i,:),accCarKeyword))
        indexCarAcc=i;
    end
    if(contains(carBiopacData.labels(i,:),accHeadKeyword))
        indexHeadAcc=i;
    end    
end

carAccOnsetTime = ...
    timeV(carBiopacDataPeakIntervals(indexCarAcc).intervals(1,1),1);
headAccOnsetTime = ...
    timeV(carBiopacDataPeakIntervals(indexHeadAcc).intervals(1,1),1);

%Go and calculate the difference in onset time.
for i=1:1:size(carBiopacData.labels,1)
    if(contains(carBiopacData.labels(i,:),emgKeyword))
        flag_onsetTimeFound=0;
        j = 1;

        if(size(carBiopacDataPeakIntervals(i).intervals,1) >= 1)
            while(j <=  size(carBiopacDataPeakIntervals(i).intervals,1)...
                    && flag_onsetTimeFound==0)
                %If there is more than one onset that is within the bounds
                %then we accept the first one
                emgOnsetTime=...
                    timeV(carBiopacDataPeakIntervals(i).intervals(j,1),1);
                emgCarTime = emgOnsetTime-carAccOnsetTime;
                emgHeadTime = emgOnsetTime-headAccOnsetTime;            
                if(  emgCarTime >= minimumAcceptableOnsetTime ...
                        && emgCarTime <= maximumAcceptableOnsetTime ...
                        && emgHeadTime >= minimumAcceptableOnsetTime ...
                        && emgHeadTime <= maximumAcceptableOnsetTime ...
                        && flag_onsetTimeFound == 0)
    
                    emgLabel = carBiopacData.labels(i,:);
                    %These labels contain some characters that look like
                    %spaces, but are not. Strip them out
                    labelKeep = [];
                    for m=1:1:length(emgLabel)
                        mNum = str2double(emgLabel(1,m));
                        mIsNumber=0;
                        if(isempty(mNum)==0 && isnan(mNum)==0)
                            mIsNumber=1;
                        end
                        if( mIsNumber ...
                                || isletter(emgLabel(1,m))...
                                || isspace(emgLabel(1,m))...
                                || emgLabel(1,m)=='-')
                            labelKeep=[labelKeep,m];
                        end
                    end
                    emgLabel = emgLabel(1,labelKeep);
                    emgLabel = strtrim(emgLabel);
                    emgLabel = replaceCharacter(emgLabel,' ','_');
                    onsetData = [onsetData;...
                        {emgLabel},...
                            {sprintf('%1.3f',emgCarTime*1000)},...
                            {sprintf('%1.3f',emgHeadTime*1000)}];
    
                    flag_onsetTimeFound=1;
                end
                j=j+1;
            end
        end
    end
end

fileNameOnset = sprintf('../output/table_Onset_EMG%i_Acc%i.csv',...
                            flag_EMGProcessing,flag_AccProcessing);

fid = fopen(fileNameOnset,'w');

fprintf('\n\nOnset Times\n');
for i=1:1:size(onsetData,1)
    for j=1:1:size(onsetData,2)
        %print to file
        fprintf(fid,'%s,',onsetData{i,j});        
        %print to screen
        if(j <= 1 || i==1)
            fprintf('%s\t',onsetData{i,j});        
        else
            fprintf('%s\t\t\t',onsetData{i,j});
        end
    end
    fprintf(fid,'\n');
    fprintf('\n');

end
fclose(fid);

if(flag_plotOnset==1)

    figOnset = configPlotExporter( figOnset,...
                                    pageWidthCm,...
                                    pageHeightCm);
    print('-dpdf', sprintf('../output/fig_Onset_EMG%i_Acc%i.pdf',...
                    flag_EMGProcessing,flag_AccProcessing));

end

here=1;

