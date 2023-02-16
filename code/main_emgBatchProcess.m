clc;
close all;
clear all;

flag_dataSet = 1;
% 0: 2022 data set
% 1: 2023 data set

flag_plotOnset = 1;

messageLevel = 1;


%%
%output flags
%%

flag_writeTabularDataToFile = 1;


lowFrequencyFilterCutoff = 10;%Hz
%%
%EMG Processing options
%%
emgEnvelopeLowpassFilterFrequency   = lowFrequencyFilterCutoff;


%Parameters for Norman's special ECG removal algorithm: 
% 1. Identify ECG peaks in the ECG channels
% 2. For each peak, go to the each of the EMG signals and high pass
%    filter the data that is +/- the windowDuration
ecgRemovalFilterWindowParams = struct('windowDuration',0.16,...
                                      'highpassFilterFrequency',20);



%%
%Accelerometer Processing options
%%
accelerometerLowpassFilterFrequency = 10;

%Trials in which the acceleration of the car is less than minimumAcceleration
%are ignored.
minimumAcceleration = 0.25;


%%
% Onset Detection Algorithm Settings
%%

flag_plotOnsetAlgorithmDetails=1;


onsetDetectionSettings.typeOfNoiseModel = 2;
% 0: Uses an exponential law to model the noise
% 1: Uses a power law to model the noise
% 2: Uses a mixture of Gaussians to model the noise. This approach
%    does a reasonable job for many strange looking distributions.

%The acceleration should not take place in this normalized time interval: this
%time interval is used to define the noise distribution
onsetDetectionSettings.noiseWindowInNormalizedTime     = [0,0.29];

%The acceleration should show up between this normalized time interval
onsetDetectionSettings.signalWindowInNormalizedTime    = [0.3,0.99];

onsetDetectionSettings.maxAcceptableNoiseProbability = 0.001;
% A peak is treated as being noise if there is a 
% maxAcceptableNoiseProbability probability, or less, of it being noise.
% The probability that a point is noise is evaluated by the noise model
% which has been fit to data the beginning of the trial. Note that
% the values for this parameter depend on the noise model:
%
% Exponential law noise model 					(typeOfNoiseModel=0)
%   This noise model goes to zero exponentially. You can set 
%   maxAcceptableNoiseProbability to quite small values and the 
%   function onset function will still work
%
% Power law noise model 						(typeOfNoiseModel=1)
%   This noise model goes to zero slowly - it has a 'fat tail'. 
%   If you set maxAcceptableNoiseProbability to small values the 
%   onset detection system will not find any onsets.
%
% Mixture of Gaussians noise model 				(typeOfNoiseModel=2)
%   This noise model goes to zero exponentially. You can set 
%   maxAcceptableNoiseProbability to quite small values and the 
%   function onset function will still work

onsetDetectionSettings.numberOfNoiseSubWindows = 5;
% The segment of data that is used to build the noise model is segmented
% numberOfNoiseSubWindowsAcc different sections. Only sections that contain
% similar data (greater than 10% chance that the segments are the same)
% are used to build the noise model.

onsetDetectionSettings.lowFrequencyFilterCutoff = 10;
% An onset is accepted only if both the filtered version of the signal
% and the raw signal have values that have a low probability of being
% noise. This additional filtering is in place so that very short lived
% transients are ignored.


onsetDetectionSettings.minimumAcceptableOnsetTime = 0;
%Here a negative value means that the EMG signal started before the
%acceleration. This could happen if somehow the person was aware the
%acceleration was about to happen and tensed in preparation.

onsetDetectionSettings.maximumAcceptableOnsetTime =  1;
%Here we pick a generous window following the acceleration onset in which
%we allow EMG signal onsets to be included. Note that this onset time will
%be placed after the latest of the two onset times: car acceleration and
%head acceleration.

onsetDetectionSettings.minimumTimingGap = 0.050; 
% A signal must be minimumTimingGap or longer to be accepted as a 
% signal. Similarly, if a signal must go to zero for longer than 
% minimumTimingGap to be considered off.




%%
%Plot options
%%
colorOnset      = [0,0,1];

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
%Paths
%%
addpath('algorithms');
addpath('inputOutput');


%Check that Matlab is currently in the code directory
localPath=pwd();
[parentFolderPath,parentFolder] = fileparts(localPath);

assert(contains(parentFolder,'code'));
assert(contains(parentFolderPath,'WhiplashExperimentProcessing'));

whiplashFolder= parentFolderPath;
codeFolder=localPath;

%Set variables specific to each data set
dataSetFolder  = '';
outputSetFolder= '';
numberOfParticipants=0;

%%
% Data set dependent variables
%%
switch(flag_dataSet)
	case 0
		dataSetFolder = fullfile(whiplashFolder,'data2022');
		outputSetFolder=fullfile(whiplashFolder,'output2022');        
		numberOfParticipants=21;

		[biopacParameters, biopacKeywords, ...
		 biopacChannels, biopacIndices] = getBiopacMetaData();
	case 1
		dataSetFolder = fullfile(whiplashFolder,'data2023');
		outputSetFolder=fullfile(whiplashFolder,'output2023');
		numberOfParticipants=28;	
		disp('Important: the TRU_L and TRU_R are really SCP_L and SCP_R');

		[biopacParameters, biopacKeywords, ...
 		 biopacChannels, biopacIndices] = getBiopacMetaData();		
	otherwise
		assert(0,'Error: flag_dataSet must be 0 or 1');
end






for indexParticipant=1:1:numberOfParticipants

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

	switch(flag_dataSet)
		case 0
			%Note: this is currently empty
			participantData=...
     			getParticipantDataMay2022(indexParticipant);	
		case 1
			%Note: this is partially done			
			participantData=...
     			getParticipantDataFebruary2023(indexParticipant);

		otherwise
			assert(0,'Error: flag_dataSet must be 0 or 1');	
	end

	cd(inputFolders.carBiopac);    
	filesinputFolder = dir();
	cd(codeFolder);	

	%Build a list of just the *.mat files
	indexMatFile = [];
	for indexFile=1:1:length(filesinputFolder)
	    if(contains(filesinputFolder(indexFile).name,'.mat'))
	        indexMatFile = [indexMatFile;indexFile];
	    end
	end

	for indexFile = 1:1:length(indexMatFile)
		fileName = filesinputFolder(indexMatFile(indexFile,1)).name;		

	    if(messageLevel > 0)
	        fprintf('  Loading: \t%s\n',filesinputFolder(indexMatFile(indexFile,1)).name);
	    end	

	    fileNameBiopacData = ...
	    	fullfile(filesinputFolder(indexMatFile(indexFile,1)).folder,...
	    	filesinputFolder(indexMatFile(indexFile,1)).name);

	    %carBiopacDataRaw is not processed
	    carBiopacDataRaw = load(fileNameBiopacData);



        %Make the time vector
    	timeV = [];
    	dt=(1/biopacParameters.sampleFrequencyHz);
    	duration = (size(carBiopacDataRaw.data,1)/biopacParameters.sampleFrequencyHz);
    	timeV = [dt:dt:duration]';

	    if(messageLevel > 1)
	        fprintf('    Channel labels:\n');
	        for i=1:1:size(carBiopacDataRaw.labels,1)
	            fprintf('    %i.\t%s\n',i,carBiopacDataRaw.labels(i,:));  
	        end
	    end

	    %Get the indices that correspond to the known biopac channel names
		biopacFields = fields(biopacIndices);   
		
	    for i=1:1:size(carBiopacDataRaw.labels,1)
	        found=0;
	        for j=1:1:length(biopacChannels)        
	            if(contains(carBiopacDataRaw.labels(i,:),biopacChannels{j}) ...
	                    && found==0)
	                biopacIndices.(biopacFields{j})=i;
	                found=1;
	            elseif((contains(carBiopacDataRaw.labels(i,:),biopacChannels{j}) ...
	                    && found==1))
	                assert(0,'Error: label keywords are not unique');
	            end
	    
	        end
	    end	

	    %Check that the time unit is ms
	    assert(contains(carBiopacDataRaw.isi_units,'ms'));
	    %Check that the time unit scaling is 0.5 - 0.5ms per data point, or 2000Hz
	    assert(carBiopacDataRaw.isi == 0.5);

	    %%
	    %Processing pipeline
	    %%

	    carBiopacDataNoEcg = removeEcgFromEmg(carBiopacDataRaw,...
	     					biopacKeywords.emg, ...
	     					biopacKeywords.ecg,...
            				ecgRemovalFilterWindowParams, ...
            				biopacParameters.sampleFrequencyHz);

        carBiopacDataEnv = calcEmgEnvelope(carBiopacDataNoEcg,...
                            biopacKeywords.emg, ...
                            emgEnvelopeLowpassFilterFrequency, ...
                            biopacParameters.sampleFrequencyHz);

		%%	    
        %EMG Normalization?
	    %  This has not been added, but this would be a good place to
	    %  
        % Go into the MVC data and identify the 2 trials that are
        % within 5% of eachother (or are closest, some were 6%)
        % for each muscle. For this pair of trials:
	    %  1. Remove the ECG data from the EMG data from the 2 trials
	    %  2. Evaluate the envelope of each
        %  3. Extract the maximum value of the envelope
        %  4. Take the average and save this coefficient 
        %%

	    	    

	    indexSubplot=1;
	    if(flag_plotOnset==1)
	        figOnset = figure;
	    end	    
	    %%
	    % Onset: accelerometers
	    %
	    %   Extract the onset time of the acceleration signal for the 
	    %   car and the head. Return the interval with the largest
	    %   acceleration that is greater than the minimum threshold
	    %%	    
		
		numberOfSignals = size(carBiopacDataRaw.data,2);
		biopacSignalIntervals(numberOfSignals) = struct('intervals',[]);

		[biopacSignalIntervals,flag_carMoved,indexSubplot,figOnset] ...
                = extractAccelerationInterval(...
                        timeV,...
                        carBiopacDataNoEcg,...   
                        biopacSignalIntervals,...        
                        minimumAcceleration,...
                        onsetDetectionSettings,...
                        biopacIndices,...
                        biopacKeywords,...
                        biopacParameters,...
                        flag_plotOnset,...
                        indexSubplot,...
                        subPlotPanel,...
                        colorOnset,...                        
                        figOnset);
        here=1;


	    %%
	    % Onset: EMG
	    %
	    %   Extract the onset time of the EMG signals that occur after the
	    %   acceleration onset
	    %%	 
	    if(flag_carMoved==1)
	    	[biopacSignalIntervals,indexSubplot,figOnset] ...
                = extractActiveEMGIntervals(...                       
                        timeV,...
                        carBiopacDataNoEcg,... 
                        biopacSignalIntervals,...
                        onsetDetectionSettings,...
                        biopacIndices,...  
                        biopacKeywords,...
                        biopacParameters,...
                        flag_plotOnset,...
                        indexSubplot,...
                        subPlotPanel,...
                        colorOnset,...                        
                        figOnset);


        end


        %Replace spaces in the file name with '_'
        fileName = filesinputFolder(indexMatFile(indexFile,1)).name
		idxSpace = strfind(fileName,' ');
		idxPoint = strfind(fileName,'.');
		assert(length(idxPoint)==1);
		fileNameNoSpace = fileName(1,1:(idxPoint-1));
		fileNameNoSpace(1,idxSpace) = '_';    

        %%
        %Extract tabular data and save to file
        %%
        if(flag_writeOnsetDataToFile==1)
        	
        	tableName = sprintf('table_Onset_%s.csv'],...
                            fileNameNoSpace);

        	success = writeOnsetDataToFile(timeV,biopacSignalIntervals,...
        				tableName);
	
			assert(success==1,'Error: writeOnsetDataToFile returned 0');
        end        

        %%
        % Save the plot to file
        %%
    	if(flag_plotOnset==1)
        
            figOnset = configPlotExporter( figOnset,...
                                            pageWidthCm,...
                                            pageHeightCm);

            plotName = sprintf('fig_Onset_%s.png'],...
                            fileNameNoSpace);

            plotPath = fullfile(outputFolder.carBiopac,plotName)
            print('-dpng', plotPath);
        
        end
	end


end
