function success = extractOnsetTimesFromBiopacData(...
                        inputFolder,outputFolder,codeFolder,...
                        slashChar,messageLevel,...
                        flag_removeECGPeaksFromEMGData,...
                        flag_plotOnset, flag_writeOnsetDataToFile)

success = 0;


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
% 1. Identify ECG peaks in the ECG channels
% 2. For each peak, go to the each of the EMG signals and high pass
%    filter the data that is +/- the windowDuration
ecgRemovalFilterWindowParams = struct('windowDuration',0.16,...
                                      'highpassFilterFrequency',20);

%%
% Accelerometer processing
%%
colorOnset      = [0,0,1];

accelerometerLowpassFilterFrequency = 10;

minimumAcceleration = 0.25;
%Trials in which the acceleration of the car is less than minimumAcceleration
%are ignored.

noiseWindowNorm     = [0,0.29];
signalWindowNorm    = [0.3,0.99];

typeOfNoiseModelAcc = 2;
% 0: Uses an exponential law to model the noise
% 1: Uses a power law to model the noise
% 2: Uses a mixture of Gaussians to model the noise. This approach
%    does a reasonable job for many strange looking distributions.

lowFrequencyFilterCutoffAcc = 10;
% An onset is accepted only if both the filtered version of the signal
% and the raw signal have values that have a low probability of being
% noise. This additional filtering is in place so that very short lived
% transients are ignored.

maxAcceptableNoiseProbabilityAcc = 0.001;
% A peak is treated as being noise if there is a 
% maxAcceptableNoiseProbability probability, or less, of it being noise.
% The probability that a point is noise is evaluated by the noise model
% which has been fit to data the beginning of the trial.

numberOfNoiseSubWindowsAcc = 5;
% The segment of data that is used to build the noise model is segmented
% numberOfNoiseSubWindowsAcc different sections. Only sections that contain
% similar data (greater than 10% chance that the segments are the same)
% are used to build the noise model.

minimumTimingGapAcc = 0.100; 
% A signal must be minimumTimingGapAcc or longer to be accepted as a 
% signal. Similarly, if a signal must go to zero for longer than 
% minimumTimingGapAcc to be considered off.

maximumAcceptableHeadMovementTime =  1;
%Here we pick a generous window following the acceleration onset in which
%we allow the head movement signal to be included.

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
% findOnsetUsingNoiseModel 
%%
flag_plotOnsetAlgorithmDetails=1;

typeOfNoiseModel = 2;
% 0: Uses an exponential law to model the noise
% 1: Uses a power law to model the noise
% 2: Uses a mixture of Gaussians to model the noise. This approach
%    does a reasonable job for many strange looking distributions.

maxAcceptableNoiseProbability = 0.001;
% A peak is treated as being noise if there is a 
% maxAcceptableNoiseProbability probability, or less, of it being noise.
% The probability that a point is noise is evaluated by the noise model
% which has been fit to data the beginning of the trial. Note that
% the values for this parameter depend on the noise model:
%
% Exponential law noise model (typeOfNoiseModel=0)
%   This noise model goes to zero exponentially. You can set 
%   maxAcceptableNoiseProbability to quite small values and the 
%   function onset function will still work
%
% Power law noise model (typeOfNoiseModel=0)
%   This noise model goes to zero slowly - it has a 'fat tail'. 
%   If you set maxAcceptableNoiseProbability to small values the 
%   onset detection system will not find any onsets.

numberOfNoiseSubWindows = 5;
% The segment of data that is used to build the noise model is segmented
% numberOfNoiseSubWindowsAcc different sections. Only sections that contain
% similar data (greater than 10% chance that the segments are the same)
% are used to build the noise model.

lowFrequencyFilterCutoff = 10;
% An onset is accepted only if both the filtered version of the signal
% and the raw signal have values that have a low probability of being
% noise. This additional filtering is in place so that very short lived
% transients are ignored.


minimumAcceptableOnsetTime = 0;
%Here a negative value means that the EMG signal started before the
%acceleration. This could happen if somehow the person was aware the
%acceleration was about to happen and tensed in preparation.

maximumAcceptableOnsetTime =  1;
%Here we pick a generous window following the acceleration onset in which
%we allow EMG signal onsets to be included. Note that this onset time will
%be placed after the latest of the two onset times: car acceleration and
%head acceleration.

minimumTimingGap = 0.050; 
% A signal must be minimumTimingGap or longer to be accepted as a 
% signal. Similarly, if a signal must go to zero for longer than 
% minimumTimingGap to be considered off.


%%
%Plotting configuration
%%
maxPlotRows          = 4;
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



%%
% Process the data
%%

%Go to the car-biopac-folder 
cd(inputFolder);
filesinputFolder = dir();
cd(codeFolder);

%Go and find the first *.mat file 
indexMatFile = [];
for indexFile=1:1:length(filesinputFolder)
    if(contains(filesinputFolder(indexFile).name,'.mat'))
        indexMatFile = [indexMatFile;indexFile];
    end
end

for indexFile = 1:1:length(indexMatFile)

    close all;

    fileName = filesinputFolder(indexMatFile(indexFile,1)).name;
    idxSpace = strfind(fileName,' ');
    idxPoint = strfind(fileName,'.');
    assert(length(idxPoint)==1);
    fileNameNoSpace = fileName(1,1:(idxPoint-1));
    fileNameNoSpace(1,idxSpace) = '_';


    if(messageLevel > 0)
        fprintf('  Loading: \t%s\n',filesinputFolder(indexMatFile(indexFile,1)).name);
    end

    carBiopacDataRaw = load([filesinputFolder(indexMatFile(indexFile,1)).folder,...
                         slashChar,...
                          filesinputFolder(indexMatFile(indexFile,1)).name]);
    
    %Keep the original raw file on hand for plotting
    carBiopacData=carBiopacDataRaw;


    timeV = [];
    dt=(1/carBiopacSampleFrequency);
    duration = (size(carBiopacData.data,1)/carBiopacSampleFrequency);
    timeV = [dt:dt:duration]';
    
    if(messageLevel > 1)
        fprintf('    Channel labels:\n');
        for i=1:1:size(carBiopacData.labels,1)
            fprintf('    %i.\t%s\n',i,carBiopacData.labels(i,:));  
        end
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
    if(flag_EMGProcessing >= 1 && flag_removeECGPeaksFromEMGData)
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
        = struct('intervals',[]);
    
    
    indexSubplot=1;
    if(flag_plotOnset==1)
        figOnset = figure;
    end
    
    flag_accHead = 0;
    flag_accCar = 0;
    
    
    %%
    %1. Extract the onset time for the acceleration of the car
    %%
    flag_carMoved = 0;
    for i=[biopacIndices.indexAccCarX,biopacIndices.indexAccHeadX]
    
        %Identify signal onset times from the norm of the acceleration
        accX = carBiopacData.data(:,i);
        accX = accX-median(accX);
        accY = carBiopacData.data(:,i+1);
        accY = accY-median(accY);
        accZ = carBiopacData.data(:,i+2);
        accZ = accZ-median(accZ);
        accNorm = (accX.^2+accY.^2+accZ.^2).^0.5;
    
        if(max(accNorm) > minimumAcceleration)

            if(i== biopacIndices.indexAccCarX)
                flag_carMoved=1;
            end

            if(flag_carMoved ==1)

                noiseWindowIndicies= [];
                signalWindowIndices= [];
                if(i== biopacIndices.indexAccCarX)
                    noiseWindowIndices  = round(noiseWindowNorm.*length(accNorm));
                    signalWindowIndices = round(signalWindowNorm.*length(accNorm));                

                else
                    minNoiseIdx = 1;
                    maxNoiseIdx = carBiopacDataPeakIntervals(biopacIndices.indexAccCarX).intervals(1,1);
                    noiseWindowIndices = [minNoiseIdx, maxNoiseIdx];

                    maxSignalIdx = round(0.99.*length(accNorm));
                    signalWindowIndices = [maxNoiseIdx,maxSignalIdx];
                end
        
                flag_plotOnsetAlgorithmDetails=0;

                [peakIntervalRaw,...
                 peakIntervalFiltered,...
                 noiseBlocks,...
                 dataTrans,...
                 dataTransFilt] = ...
                   findOnsetUsingNoiseModel(accNorm, ...
                                            signalWindowIndices,...
                                            noiseWindowIndices,...
                                            numberOfNoiseSubWindows,...
                                            maxAcceptableNoiseProbabilityAcc,...
                                            minimumTimingGapAcc,...
                                            lowFrequencyFilterCutoffAcc,...
                                            carBiopacSampleFrequency,...
                                            typeOfNoiseModelAcc,...
                                            flag_plotOnsetAlgorithmDetails);



                %Pick the interval with the highest acceleration   
                peakIntervalFilteredUpd=[];

                if(max(dataTransFilt) > minimumAcceleration)
                    if(i== biopacIndices.indexAccCarX && ...
                            size(peakIntervalFiltered,1) > 1)
                       maxAccVal = zeros(size(peakIntervalFiltered,1),1);
                       for k=1:1:size(peakIntervalFiltered,1)
                           i0=peakIntervalFiltered(k,1);
                           i1=peakIntervalFiltered(k,2);                       
                           maxAccVal(k,1)=max(dataTransFilt(i0:1:i1,1));
                       end
                       [val,idx]=max(maxAccVal);
                        peakIntervalFilteredUpd=peakIntervalFiltered(idx,:);
                    elseif(isempty(peakIntervalFiltered)==0)
                        peakIntervalFilteredUpd = peakIntervalFiltered(1,:);
                    end
                else 
                    if(i== biopacIndices.indexAccCarX)
                        flag_carMoved=0;
                    end
                end
                for k=1:1:3
                    carBiopacDataPeakIntervals(i+k-1).intervals   = ...
                        peakIntervalFilteredUpd;
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
                        addOnsetPlot(   timeV, ...
                                        dataTrans,...
                                        dataTransFilt,...
                                        signalWindowIndices,...
                                        noiseBlocks,...
                                        peakIntervalFiltered,...
                                        colorOnset,...
                                        dataLabel,...
                                        figOnset, ...
                                        subPlotPanel, ...
                                        indexSubplot);                   
                end
            end
        end
    end
    
    %%
    % Identify the onset of EMG that occurs in a window after the car begins to
    % move
    %%
    if(flag_carMoved==1)

        for i=1:1:size(carBiopacData.labels,1)
            if(contains(carBiopacData.labels(i,:),emgKeyword))

                assert(isempty(carBiopacDataPeakIntervals(biopacIndices.indexAccCarX).intervals)==0);

                %Take the first identified acceleration interval in the
                %signal window
                indexAccMin = carBiopacDataPeakIntervals(biopacIndices.indexAccCarX).intervals(1,:);
                indexAccMax = carBiopacDataPeakIntervals(biopacIndices.indexAccCarX).intervals(1,:);                

                %If the head also moves, include its movement in definining
                %the minimum and maximum times.
                if(isempty(carBiopacDataPeakIntervals(biopacIndices.indexAccHeadX).intervals)==0)
                    indexAccMin = ...
                        min( carBiopacDataPeakIntervals(biopacIndices.indexAccCarX).intervals(1,:),...
                             carBiopacDataPeakIntervals(biopacIndices.indexAccHeadX).intervals(1,:));
            
                    indexAccMax = ...
                        max( carBiopacDataPeakIntervals(biopacIndices.indexAccCarX).intervals(1,:),...
                             carBiopacDataPeakIntervals(biopacIndices.indexAccHeadX).intervals(1,:));
                end

                timeAccMin = timeV(indexAccMin,1);
                timeAccMax = timeV(indexAccMax,1);
                timeWindowStart = timeAccMin+minimumAcceptableOnsetTime;
                timeWindowEnd   = timeAccMax+maximumAcceptableOnsetTime; 
        
                signalWindowIndices = ...
                    [timeWindowStart,timeWindowEnd].*carBiopacSampleFrequency;
        
                signalWindowIndices = round(signalWindowIndices);
        
                noiseWindowIndices = [1,round(indexAccMin*0.95)];
        
                flag_plotOnsetAlgorithmDetails=0;
        
               [peakIntervalRaw,...
                peakIntervalFiltered, ...
                noiseBlocks,...
                dataTrans,...
                dataTransFilt] = ...
                    findOnsetUsingNoiseModel(  carBiopacData.data(:,i), ...
                                            signalWindowIndices,...
                                            noiseWindowIndices,...
                                            numberOfNoiseSubWindows,...
                                            maxAcceptableNoiseProbability,...
                                            minimumTimingGap,...
                                            lowFrequencyFilterCutoff,...
                                            carBiopacSampleFrequency,...
                                            typeOfNoiseModel,...
                                            flag_plotOnsetAlgorithmDetails);
        
        
               if(isempty(peakIntervalRaw)==0)
                    carBiopacDataPeakIntervals(i).intervals   = ...
                        [peakIntervalRaw(1,:)];
               end
        
                if(flag_plotOnset)
                    dataLabel = carBiopacData.labels(i,:);
                    dataLabel = dataLabel(1,1:max(30,length(dataLabel)));

                    figure(figOnset);
                    maxPlotCols = size(subPlotPanel,2);
                    maxPlotRows = size(subPlotPanel,1);
                    
                    row = ceil(indexSubplot/maxPlotCols);
                    col = max(1,indexSubplot-(row-1)*maxPlotCols);
                    
                    subplot('Position',reshape(subPlotPanel(row,col,:),1,4));  

                    [figOnset,indexSubplot] = ...                        
                        addOnsetPlot(   timeV, ...
                                        dataTrans,...
                                        dataTransFilt,...
                                        signalWindowIndices,...
                                        noiseBlocks,...
                                        peakIntervalFiltered,...
                                        colorOnset,...
                                        dataLabel,...
                                        figOnset, ...
                                        subPlotPanel, ...
                                        indexSubplot);   
     
                     here=1;
        
                end
            end
        
        end
        
        
        
        %%
        % Calculate delay times between each EMG channel & the head/car
        % acceleration onset. Store the result in a table and write the table
        % to a csv file
        %%
        indexCarAcc = biopacIndices.indexAccCarX;
        indexHeadAcc= biopacIndices.indexAccHeadX;
        onsetData=[];
        carAccOnsetTime = ...
            timeV(carBiopacDataPeakIntervals(indexCarAcc).intervals(1,1),1);
        headAccOnsetTime = max(timeV);

        if(isempty(carBiopacDataPeakIntervals(indexHeadAcc).intervals)==0)
            headAccOnsetTime = ...
                timeV(carBiopacDataPeakIntervals(indexHeadAcc).intervals(1,1),1);
        end
                
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
        
        if(flag_writeOnsetDataToFile==1)
            fileNameOnset = sprintf([outputFolder,'%stable_Onset_EMG%i_Acc%i.csv'],...
                                        slashChar,flag_EMGProcessing,flag_AccProcessing);
            
            fid = fopen(fileNameOnset,'w');
            fprintf(fid,'Name,DelayCarToEMG,DelayHeadToEMG\n');
    
            if(messageLevel > 0)
                fprintf('\n  Channel\t\tCar-Onset\tHead-Onset\n');
            end
            for i=1:1:size(onsetData,1)
                for j=1:1:size(onsetData,2)
                    %print to file
                    fprintf(fid,'%s,',onsetData{i,j});        
                    %print to screen
                    if(messageLevel > 0)                
                        if(j <= 1 || i==1)
                            fprintf('  %s\t',onsetData{i,j});        
                        else
                            fprintf('  %s\t',onsetData{i,j});
                        end
                    end
                end
                fprintf(fid,'\n');
                if(messageLevel > 0)
                    fprintf('\n');
                end
            
            end
            fclose(fid);
        end
        
        if(flag_plotOnset==1)
        
            figOnset = configPlotExporter( figOnset,...
                                            pageWidthCm,...
                                            pageHeightCm);
            print('-dpng', sprintf([outputFolder,'%sfig_Onset_EMG%i_Acc%i_%s.png'],...
                            slashChar,flag_EMGProcessing,flag_AccProcessing,...
                            fileNameNoSpace));
            here=1;
        
        end
    end

end
success = 1;
