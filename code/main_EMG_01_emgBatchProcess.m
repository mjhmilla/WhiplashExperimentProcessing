flag_useDefaultInitialization=0;
if(exist('flag_outerLoopMode','var') == 0)
    flag_useDefaultInitialization=1;
else    
    if(flag_outerLoopMode==0)
        flag_useDefaultInitialization=1;
    end
end
if(flag_useDefaultInitialization==1)
    clc
    clear all
    close all;    
    % 0: 2022 data set
    % 1: 2023 data set
    flag_dataSet = 0; 
end

flag_plotOnset = 1;


messageLevel = 1;

minimumTrialTime              = 1;
startWithThisParticipant      = 1;

% Flags to process a specific part of the data set
flag_runParticipantSubInterval  = 0;
runThisParticipantFirst         = 0;
runThisParticipantLast          = 0;

flag_runOneParticipant          = 0;
runThisParticipant              = 0;

flag_runOneTrial                = 0;
runThisTrial                    = 0;


assert((flag_runParticipantSubInterval && flag_runOneParticipant) == 0 ...
    || (flag_runParticipantSubInterval || flag_runOneParticipant) == 0,...
       'Error: these two options (flag_runParticipantSubInterval and',...
       ' flag_runOneParticipant) cannot be used at the same time.');

if(flag_runOneTrial==1)
    assert(flag_runOneParticipant == 1,...
          ['Error: flag_runOneTrial can only be used if',...
           ' flag_runOneParticipant is set to one']);
end

%%
%output flags
%%

lowFrequencyFilterCutoff = 10;%Hz
%%
%EMG Processing options
%%
flag_useFilteredSignal = 1;
%0: The onset times of the raw EMG signal is returned
%1: The onset times of the filtered EMG signal is returned (recommended)

emgEnvelopeLowpassFilterFrequency   = lowFrequencyFilterCutoff;


%Parameters for Norman's special ECG removal algorithm: 
% 1. Identify ECG peaks in the ECG channels
% 2. For each peak, go to the each of the EMG signals and high pass
%    filter the data that is +/- the windowDuration
ecgRemovalFilterWindowParams = struct('windowDurationInSeconds',0.16,...
                                      'highpassFilterFrequencyInHz',50);



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
% Data set dependent variables
%%
switch(flag_dataSet)
	case 0
		dataSetFolder = fullfile(whiplashFolder,'data2022');
		outputSetFolder=fullfile(whiplashFolder,'output2022');        
		numberOfParticipants=21;

        firstMuscleBiopacIndex = 1;
        lastMuscleBiopacIndex  = 6;

        numberOfMuscles = lastMuscleBiopacIndex-firstMuscleBiopacIndex+1;
	case 1
		dataSetFolder = fullfile(whiplashFolder,'data2023');
		outputSetFolder=fullfile(whiplashFolder,'output2023');
		numberOfParticipants=28;    

        firstMuscleBiopacIndex = 1;
        lastMuscleBiopacIndex  = 6;
        
        numberOfMuscles = lastMuscleBiopacIndex-firstMuscleBiopacIndex+1;

		disp('Important: the TRU_L and TRU_R are really SCP_L and SCP_R');
        disp('Important: the head accelerometer was never attached to the head. (Matts fault)');
		
	otherwise
		assert(0,'Error: flag_dataSet must be 0 or 1');
end


participantFirst = 1;

if(isempty(startWithThisParticipant)==0)
    participantFirst=startWithThisParticipant;
end

participantLast  = numberOfParticipants;
if(flag_runOneParticipant==1)
    participantFirst = runThisParticipant;
    participantLast  = runThisParticipant;
end

if(flag_runParticipantSubInterval==1)
    participantFirst = runThisParticipantFirst;
    participantLast  = runThisParticipantLast;
end


for indexParticipant=participantFirst:1:participantLast

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
	        participantMetaData = ...
                 getParticipantDataMay2022(indexParticipant);

            [participantMvcMetaData, indicesMvcData] =...
            	 getParticipantMvcDataMay2022(indexParticipant);

            participantCarMetaData= ...
               getParticipantCarDataMay2022(indexParticipant);            

		case 1
	        participantMetaData = ...
                 getParticipantDataFebruary2023(indexParticipant);

            [participantMvcMetaData, indicesMvcData] =...
            	 getParticipantMvcDataFebruary2023(indexParticipant);

            participantCarMetaData= ...
               getParticipantCarDataFebruary2023(indexParticipant);

		otherwise
			assert(0,'Error: flag_dataSet must be 0 or 1');    
	end

    %
    % Load the participant's processed MVC file
    %
    cd(outputFolders.common);
    currentFile = ['emgMvcMaxOutput_', participantLabel,'.mat'];
    participantMvcData = load(currentFile);
    cd(codeFolder)
    
    %
    % Get the biopac files from the car
    %
	cd(inputFolders.carBiopac);    
	filesInCarBiopacFolder = dir();
	cd(codeFolder);    

    %Build a list of just the *.mat files
	indexOfMatFilesInCarBiopacFolderList = [];
	for indexFile=1:1:length(filesInCarBiopacFolder)
        if(contains(filesInCarBiopacFolder(indexFile).name,'.mat'))
            indexOfMatFilesInCarBiopacFolderList = ...
                [indexOfMatFilesInCarBiopacFolderList;indexFile];
        end
	end

    %Make the output struct
    if(exist('participantEmgData','var'))
        clear('participantEmgData');
    end

    
    %Count the number of trials to analyze
    numberOfTrialsToAnalyze = 0;
    for i=1:1:size(participantCarMetaData.blockFileNumbers,1)

        if(sum(isnan(participantCarMetaData.blockFileNumbers(i,:)))==0)
            numberOfTrialsToAnalyze = ...
                numberOfTrialsToAnalyze ...
                + (  participantCarMetaData.blockFileNumbers(i,2) ...
                    -participantCarMetaData.blockFileNumbers(i,1) + 1);
        end

    end

    %Define the struct
    participantEmgData(numberOfTrialsToAnalyze) ...
        = struct(...
            'id',indexParticipant,...
            'filePath','',...
            'fileName','',...
            'fileNumber',0,...
            'condition','',...
            'block','',...
            'carDirection','',...             
            'biopacSignalIntervals',[],...
            'biopacIndices',[],...
            'biopacProblemChannels',[],...
            'flag_ignoreTrial',0,...
            'flag_carMoved', 0);

    %Initialize the struct
    for indexFile = 1:1:length(participantEmgData)

        participantEmgData(indexFile).id                    = indexParticipant;
        participantEmgData(indexFile).filePath              = [];
        participantEmgData(indexFile).fileName              = [];
        participantEmgData(indexFile).fileNumber            = 0;
        participantEmgData(indexFile).condition             = [];
        participantEmgData(indexFile).block                 = [];
        participantEmgData(indexFile).carDirection          = [];
        participantEmgData(indexFile).biopacSignalIntervals = [];
        participantEmgData(indexFile).biopacIndices         = [];
        participantEmgData(indexFile).biopacProblemChannels = [];
        participantEmgData(indexFile).flag_ignoreTrial      = 1;
        participantEmgData(indexFile).flag_carMoved         = 0;

    end


    
    %Scan the car meta data to
    % 1. Build a list of file names to process
    % 2. Note any missing file names that are not in the  'ignoreTheseFileNumbers' list,
    [participantEmgData, listOfFilesToProcess] ...
        = updateParticipantEmgDataFileNames(participantEmgData, ...
                                            filesInCarBiopacFolder, ...
                                            indexOfMatFilesInCarBiopacFolderList, ...
                                            participantCarMetaData);


    if(flag_runOneTrial==1)
        listOfFilesToProcess=listOfFilesToProcess(1,runThisTrial);
    end

    for indexFileList = 1:1:length(listOfFilesToProcess)

        indexFile = listOfFilesToProcess(1,indexFileList);
    
        fileName = participantEmgData(indexFile).fileName;

        if(messageLevel > 0)
            fprintf('  Loading: %i.\t%s\n',indexFileList,fileName);
        end	

	    [trialCondition, trialBlock, flag_ignoreTrial] = ...
            getTrialConditionAndBlock(  fileName,...
                                        participantCarMetaData);
        

        participantEmgData(indexFile).condition=trialCondition;
        participantEmgData(indexFile).block=trialBlock;
        participantEmgData(indexFile).flag_ignoreTrial = flag_ignoreTrial;

        if(messageLevel > 0)
            strIgnore='';
            if(flag_ignoreTrial)
                strIgnore = '*ignore';
            end
            fprintf('    %s\t%s\t%s\n',trialCondition,trialBlock, strIgnore);
        end	        

        fileNameBiopacData = ...
        	fullfile(  participantEmgData(indexFile).filePath,fileName);

        %carBiopacDataRaw is left in its un processed form.
        carBiopacDataRaw = load(fileNameBiopacData);
             
        %%
        %%
        if(messageLevel > 1)
            fprintf('    Channel labels:\n');
            for i=1:1:size(carBiopacDataRaw.labels,1)
                fprintf('    %i.\t%s\n',i,carBiopacDataRaw.labels(i,:));  
            end
        end

        %Get the indices that correspond to the known biopac channel names
		[biopacParameters, biopacKeywords, ...
 		 biopacChannels, biopacIndices] = getBiopacMetaData(carBiopacDataRaw);        

        %Make the time vector
    	timeV = [];
    	dt=(1/biopacParameters.sampleFrequencyHz);
    	duration = (size(carBiopacDataRaw.data,1)/biopacParameters.sampleFrequencyHz);
    	timeV = [dt:dt:duration]';        

        
        if(length(timeV) < biopacParameters.sampleFrequencyHz*minimumTrialTime ...
                || flag_ignoreTrial==1)
            %%
            %
            % We do not have enough data: save empty struct
            %
            %%
            participantEmgData(indexFile).flag_ignoreTrial = 1;


        else
            %%
            %
            % We have enough data: process it
            %
            %%
            
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

            flag_plotNormDebugData=0;
            muscleIndices = [firstMuscleBiopacIndex:1:lastMuscleBiopacIndex];

            carBiopacDataNorm = normalizeEMGData(carBiopacDataEnv,...
                                    participantMvcData,...
                                    muscleIndices,...
                                    flag_plotNormDebugData);


    

            indexSubplot=1;
            indexSubplotStart=1;        
            figOnset = [];
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

            if(exist('biopacSignalIntervals','var'))
                clear('biopacSignalIntervals');
            end

            biopacSignalIntervals(numberOfSignals) = ...
                struct('intervalIndices',[],...
                        'intervalTimes',[],...
                        'intervalMaximumValue',[],...
                        'flag_maximumValueExceedsThreshold',0);

            %Initialize the structure.
            for indexSignal=1:1:numberOfSignals
                biopacSignalIntervals(numberOfSignals).intervalIndices=[];
                biopacSignalIntervals(numberOfSignals).intervalTimes=[];
                biopacSignalIntervals(numberOfSignals).intervalMaximumValue=[];
                biopacSignalIntervals(numberOfSignals).flag_maximumValueExceedsThreshold = 0;
            end



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
        
            %%
            %
            % Get the direction of the car's acceleration
            %
            %%
            carDirection = 'Static';
            if(flag_carMoved==1)
        	    carDirection = extractCarAccelerationDirection(...
    					    carBiopacDataRaw,...
                            biopacSignalIntervals,...
                            biopacIndices);
            end
            if(messageLevel > 0)
                fprintf('    %s\n',carDirection);
            end	        

            %%
            %
            % Add the trial meta data to the plots
            %
            %%%
            figure(figOnset);
            maxPlotCols = size(subPlotPanel,2);
            maxPlotRows = size(subPlotPanel,1);
            row = ceil(indexSubplotStart/maxPlotCols);
            col = max(1,indexSubplotStart-(row-1)*maxPlotCols);

            subplot('Position',reshape(subPlotPanel(row,col,:),1,4));

            trialMetaData = sprintf('Cond.: %s\nBlock: %s\nCarDir  : %s',...
                trialCondition,trialBlock,carDirection);
            text('Units', 'Normalized', 'Position', [0.05, 0.9], 'string',...
                trialMetaData, 'FontSize',10,...
                'HorizontalAlignment','left',...
                'VerticalAlignment','top');
            hold on;

            here=1;
            %%
            % Onset: EMG
            %
            %   Extract the onset time of the EMG signals that occur after the
            %   acceleration onset
            %%     

            [biopacSignalIntervals,indexSubplot,figOnset] ...
                = extractActiveEMGIntervals(...                       
                        timeV,...
                        carBiopacDataNoEcg,... 
                        carBiopacDataNorm,...
                        biopacSignalIntervals,...
                        onsetDetectionSettings,...
                        biopacIndices,...  
                        biopacKeywords,...
                        biopacParameters,...
                        flag_useFilteredSignal,...
                        flag_carMoved,...
                        flag_plotOnset,...
                        indexSubplot,...
                        subPlotPanel,...
                        colorOnset,...                        
                        figOnset);

            biopacProblemChannels = [];
            if(isempty(participantCarMetaData.biopacProblems)==0)
                for indexProblem=1:1:length(participantCarMetaData.biopacProblems)
                    fileNumber = participantCarMetaData.biopacProblems(indexProblem).trialNumber;
                    if(fileNumber == participantEmgData(indexFile).fileNumber)
                        biopacProblemChannels = participantCarMetaData.biopacProblems(indexProblem).channels;
                    end                    
                end
            end
    
            %Save the data to a struct
            participantEmgData(indexFile).carDirection = carDirection;
            participantEmgData(indexFile).biopacSignalIntervals = biopacSignalIntervals;
            participantEmgData(indexFile).biopacIndices = biopacIndices;
            participantEmgData(indexFile).biopacProblemChannels=biopacProblemChannels;
            participantEmgData(indexFile).flag_ignoreTrial = flag_ignoreTrial;
            participantEmgData(indexFile).flag_carMoved=flag_carMoved;
            

            if(flag_plotOnset==1)
            
                figOnset = configPlotExporter( figOnset,...
                                                pageWidthCm,...
                                                pageHeightCm);
    

                %Replace spaces in the file name with '_'
                idxSpace = strfind(fileName,' ');
                idxPoint = strfind(fileName,'.');
                
                assert(length(idxPoint)==1);
                
                fileNameNoSpace = fileName(1,1:(idxPoint-1));
                fileNameNoSpace(1,idxSpace) = '_';      
                
                plotName = sprintf(['fig_Onset_%s.png'], fileNameNoSpace);
    
                plotPath = fullfile(outputFolders.carBiopac,plotName);
                print('-dpng', plotPath);
    
                close(figOnset);
            
            end
        end
    end
    %Save the struct containing all of the participant's EMG data to file
    outputEmgFileName = ['emgPipelineOutput_',participantLabel,'.mat'];
    outputEmgFilePath = fullfile(outputFolders.common,outputEmgFileName);
    save(outputEmgFilePath, 'participantEmgData');    
end


cd(codeFolder);

