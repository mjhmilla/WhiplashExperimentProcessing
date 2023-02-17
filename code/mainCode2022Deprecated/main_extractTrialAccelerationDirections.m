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
addpath(['algorithms',slashChar]);
addpath(['inputOutput',slashChar]);

cd(codeFolder);
cd(['..',slashChar,'/data']);
dataFolder = pwd();

cd(codeFolder);
cd(['..',slashChar,'/output']);
outputFolder = pwd();

cd(codeFolder);

carBiopacFolder = ['car/biopac'];

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

flag_AccProcessing =1;
%0: raw
%1: Acceleration signal zero-phase low-pass filtered.

%%
% Accelerometer processing
%%
accelerometerLowpassFilterFrequency = 10;

minimumAcceleration = 0.25;
%If the car accelerometer is less than this value the EMG data is not
%processed

%%
%Acceleration Processing
%%

%See the documentation for findOnsetUsingAdaptiveThreshold for details
peakMiddleThresholdPercentile     = 0.975;
peakMaximumThresholdScalingAcc    = 0.2;
peakBaseThresholdScaling          = 0.1;


onsetKmeansParameters = struct('numberOfClusters',2,... 
                               'standardDeviationThreshold', 3);

minimumSamplesBetweenIntervals = round(0.050*carBiopacSampleFrequency);



%%
% Noise model
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
for indexParticipant = 1:1:21
    


    %Go to the car-biopac-folder 
    cd(dataFolder);

    participantNum = num2str(indexParticipant);
    if(length(participantNum)<2)
        participantNum = ['0',participantNum];
    end

    participantStr = ['participant',participantNum];

    fprintf('%i.\t%s\n',indexParticipant,participantStr);

    cd(participantStr);
    cd(carBiopacFolder);
    filesCarBiopacFolder = dir();
    cd(codeFolder);

    %Open the output file
    fileNameOnset = sprintf([outputFolder,slashChar,'table_%s_%s.csv'],...
                                participantStr,...
                                'TrialAccelerationDirections');
    
    fid = fopen(fileNameOnset,'w');    
    
    %Go and find the first *.mat file 
    indexMatFile = [];
    for indexFile=1:1:length(filesCarBiopacFolder)
        if(contains(filesCarBiopacFolder(indexFile).name,'.mat'))
            indexMatFile = [indexMatFile;indexFile];
        end
    end
    
    for indexFile = 1:1:length(indexMatFile)
    
        close all;
    
        fileName=filesCarBiopacFolder(indexMatFile(indexFile,1)).name;
        idxSpace = strfind(fileName,' ');
        idxPoint =strfind(fileName,'.');
        assert(length(idxPoint)==1);
        fileNameNoSpace = fileName(1,1:(idxPoint-1));
        fileNameNoSpace(1,idxSpace) = '_';
    
    
        fprintf('  %i.\t%s\n',indexFile,filesCarBiopacFolder(indexMatFile(indexFile,1)).name);
        carBiopacDataRaw = load([filesCarBiopacFolder(indexMatFile(indexFile,1)).folder,...
                             slashChar,...
                              filesCarBiopacFolder(indexMatFile(indexFile,1)).name]);
        
        %Keep the original raw file on hand for plotting
        carBiopacData=carBiopacDataRaw;
        timeV = [];
        dt=(1/carBiopacSampleFrequency);
        duration = (size(carBiopacData.data,1)/carBiopacSampleFrequency);
        timeV = [dt:dt:duration]';
        
        
        %fprintf('  Channel labels:\n');
        %for i=1:1:size(carBiopacData.labels,1)
        %    fprintf('  %i.\t%s\n',i,carBiopacData.labels(i,:));  
        %end
        
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
        % Smooth the accelerometer data
        %%
        
        if(indexParticipant==2 && indexFile==22)
            here=1;
        end

        flag_valid=0;
        directionName = 'invalid';
        if(size(carBiopacData.data,1) > 100)
            flag_valid=1;
        end

        if(flag_AccProcessing >= 1 && flag_valid==1)
            carBiopacData = smoothAccelerations(carBiopacData,accCarKeyword,...
                accelerometerLowpassFilterFrequency,carBiopacSampleFrequency);
            
            carBiopacData = smoothAccelerations(carBiopacData,accHeadKeyword,...
                accelerometerLowpassFilterFrequency,carBiopacSampleFrequency);
        
        end
        
        
        %%
        % Identify the signal onset
        %%
             
        if(flag_valid==1)
            numberOfSignals = size(carBiopacData.data,2);
            carBiopacDataPeakIntervals(numberOfSignals) ...
                = struct(   'intervals',[],...
                            'middleThresholds',[],...
                            'maximumThresholds',[]);
    
    
            indexSubplot=1;
            flag_plotOnset =0;
            if(flag_plotOnset==1)
                figOnset = figure;
            end
            
            flag_accCar = 0;
                    
            %%
            %1. Extract the onset time for the acceleration of the car
            %%
            flag_carMoved = 0;
            i = biopacIndices.indexAccCarX;
        
            %Identify signal onset times from the norm of the acceleration
            accXYZ = carBiopacData.data(:,i:1:(i+2));
            for j=1:1:3
                accXYZ(:,j)=accXYZ(:,j)-median(accXYZ(:,j));
            end
            accNorm = (sum(accXYZ.^2,2)).^0.5;
        
            directionName='static';
    
            if(max(accNorm) > minimumAcceleration)
    
                if(indexFile==4)
                    flag_plotOnsetDetails=1;
                else
                    flag_plotOnsetDetails=0;            
                end
    
                         
    
               
                [peakIntervals,...
                    peakMiddleThresholds,...
                    peakMaximumThresholds] = ...
                    findOnsetUsingAdaptiveThreshold(accNorm, ...
                                            peakMiddleThresholdPercentile,...
                                            peakMaximumThresholdScalingAcc,...
                                            peakBaseThresholdScaling,...
                                            minimumSamplesBetweenIntervals,...
                                            flag_plotOnsetDetails);
            
    
                if(size(peakIntervals)~=1)
                    here=1;
                end
    
                assert(size(peakIntervals,1)==1,...
                    ['Error: more than one acceleration',...
                     ' interval identified in the car']);  
    
                for j=i:1:(i+2)
                    carBiopacDataPeakIntervals(j).intervals   = ...
                        peakIntervals;
                    carBiopacDataPeakIntervals(j).middleThresholds = ...
                        peakMiddleThresholds;
                    carBiopacDataPeakIntervals(j).maximumThresholds = ...
                        peakMaximumThresholds;
                end            
    
                accMax = -inf;
                indexXYZMaxAcc = 0;
    
                for j=1:1:3
                    if(max(abs(accXYZ(:,j))) > accMax)
                        accMax=max(abs(accXYZ(:,j)));
                        indexXYZMaxAcc=j;
                    end
                end
    
    
    
                p0 = peakIntervals(1,1);
                p1 = peakIntervals(1,2);            
    
                switch indexXYZMaxAcc
                    %The +x-axis is pointing left
                    case 1
                        if(median(accXYZ(p0:p1,1)) > 0)
                            directionName='right';                        
                        else
                            directionName='left';                        
                        end
                    %The +y-axis is pointing right                    
                    case 2
                        if(median(accXYZ(p0:p1,1)) > 0)
                            directionName='forwards';                        
                        else
                            directionName='backwards';                        
                        end
                    %The +z-axis is pointing up.
                    %The z acceleration (with the offset removed) should never
                    %be the maximum.
                    case 3
                        assert(0,['Error: the vertical acceleration is',...
                                   ' the maximum. Something is wrong.']);
                        
                    otherwise
                       assert(0,'Error: all directions accelerated equally');
                end
    
                assert(contains(carBiopacData.labels(i,:),accCarKeyword));
                dataLabel = [directionName, ' car acc.'];            
                
                if(flag_plotOnset)
                    [figOnset,indexSubplot] = ...
                        addAccelerationXYZPlot(timeV,...
                                accXYZ,...
                                peakIntervals,...
                                dataLabel,...
                                figOnset, ...
                                subPlotPanel, ...
                                indexSubplot);
                    here=1;
    
                end
              
    
            end
        end

        fprintf(fid,'%i,%s,%s\n',indexFile,fileName,directionName);
            

       

%         for i=1:1:size(onsetData,1)
%             for j=1:1:size(onsetData,2)
%                 %print to file
%                 fprintf(fid,'%s,',onsetData{i,j});        
%                 %print to screen
%                 if(j <= 1 || i==1)
%                     fprintf('%s\t',onsetData{i,j});        
%                 else
%                     fprintf('%s\t\t\t',onsetData{i,j});
%                 end
%             end
%             fprintf(fid,'\n');
%             fprintf('\n');
%         
%         end
%          fclose(fid);
%         
%         if(flag_plotOnset==1)
%         
%             figOnset = configPlotExporter( figOnset,...
%                                             pageWidthCm,...
%                                             pageHeightCm);
%             print('-dpng', sprintf('../output/fig_Onset_EMG%i_Acc%i_%s.png',...
%                             flag_EMGProcessing,flag_AccProcessing,...
%                             fileNameNoSpace));
%         
%         end
    end
    fclose(fid);

end
here=1;

