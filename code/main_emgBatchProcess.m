clc;
close all;
clear all;

opengl('save','software');

% 0: 2022 data set
% 1: 2023 data set
flag_dataSet   = 1;
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

assert(flag_runParticipantSubInterval && flag_runOneParticipant == 0,...
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
                                      'highpassFilterFrequencyInHz',20);



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
			%Note: this is currently empty
			disp('Warning: not implemented getParticipantDataMay2022');
            disp('Warning: not implemented getParticipantMvcDataMay2022');
            disp('Warning: not implemented getParticipantCarDataMay2022');

		case 1

            %Christa & Celine: Look at 
            %
            %   inputOutput/getParticipantDataFebruary2023.m 
            %   inputOutput/getParticipantMvcDataFebruary2023.m
            %   inputOutput/getParticipantCarDataFebruary2023.m
            %
            %  and consider filling in the data for the rest of the participants
            %  if you need this information

	        participantMetaData = ...
                 getParticipantDataFebruary2023(indexParticipant);


            [participantMvcMetaData, indicesMvcData] =...
            	 getParticipantMvcDataFebruary2023(indexParticipant);

            participantCarMetaData= ...
               getParticipantCarDataFebruary2023(indexParticipant);

		otherwise
			assert(0,'Error: flag_dataSet must be 0 or 1');    
	end



    %%
    % Christa & Celine: load the participant's MVC data here
    %%
    cd(outputFolders.common);
    %load a list of all of the file names in this folder
    outputAllParticipants = pwd();
    filesInAllParticipants = dir(outputAllParticipants);
    currentFile = ['emgMvcMaxOutput_', participantLabel,'.mat'];
    %search for the one with emgMvcMaxOutput_participant##
    participantMvcData = load(currentFile);
    cd(codeFolder)
    
    cd(outputFolders.common);
    %load a list of all of the file names in this folder
    outputAllParticipants = pwd();
    filesInAllParticipants = dir(outputAllParticipants);
    currentFile = ['emgMvcMaxOutput_', participantLabel,'.mat'];
    %search for the one with emgMvcMaxOutput_participant##
    participantMvcData = load(currentFile);
    cd(codeFolder)
    
    %
    % Get the biopac files from the car
    %
	cd(inputFolders.carBiopac);    
	filesInCarBiopacFolder = dir();
	cd(codeFolder);    

    %Build a list of just the *.mat files
	indexMatFile = [];
	for indexFile=1:1:length(filesInCarBiopacFolder)
        if(contains(filesInCarBiopacFolder(indexFile).name,'.mat'))
            indexMatFile = [indexMatFile;indexFile];
        end
	end

    %Make the output struct
    if(exist('participantEmgData','var'))
        clear('participantEmgData');
    end

    participantEmgData(length(filesInCarBiopacFolder)) ...
        = struct(...
            'id',indexParticipant,...
            'fileName','',...
            'condition','',...
            'block','',...
            'carDirection','',...             
            'biopacSignalIntervals',[],...
            'biopacIndices',[],...
            'flag_ignoreTrial',0,...
            'flag_carMoved', 0);

    for indexFile = 1:1:length(participantEmgData)
        participantEmgData(indexFile).id                    = indexParticipant;
        participantEmgData(indexFile).fileName              = [];
        participantEmgData(indexFile).condition             = [];
        participantEmgData(indexFile).block                 = [];
        participantEmgData(indexFile).carDirection          = [];
        participantEmgData(indexFile).biopacSignalIntervals = [];
        participantEmgData(indexFile).biopacIndices         = [];
        participantEmgData(indexFile).flag_ignoreTrial      = 0;
        participantEmgData(indexFile).flag_carMoved         = 0;
    end


    indexTrialStart = 1;
    indexTrialEnd = length(indexMatFile);

    if(flag_runOneTrial==1)
        indexTrialStart=runThisTrial;
        indexTrialEnd = runThisTrial;
    end
    
    %Scan the car meta data to see if any files are missing
    for indexCondition = 1:1:length(participantCarMetaData.condition)
        fileNumberStart = participantCarMetaData.blockFileNumbers(indexCondition,1);
        fileNumberEnd   = participantCarMetaData.blockFileNumbers(indexCondition,2);
        for indexFileNumber = fileNumberStart:1:fileNumberEnd
            flag_fileFound = 0;
            fileNoSubStr = [num2str(indexFileNumber),'.mat'];
            for indexFile = 1:1:length(indexMatFile)
                if(contains(filesInCarBiopacFolder(indexMatFile(indexFile,1)).name ,fileNoSubStr))
                    flag_fileFound=1;
                end
            end
            if(flag_fileFound==0)
                fprintf('  Missing: file number %i of (%s, %s)\n',...
                    indexFileNumber,...
                    participantMvcData.condition{indexCondition,1},...
                    participantMvcData.block{indexCondition,1});
            end
        end
    end

    for indexFile = indexTrialStart:1:indexTrialEnd

        if(indexFile>=11)
            here=1;
        end
        
		fileName = filesInCarBiopacFolder(indexMatFile(indexFile,1)).name;		

        if(messageLevel > 0)
            fprintf('  Loading: %i.\t%s\n',indexFile,filesInCarBiopacFolder(indexMatFile(indexFile,1)).name);
        end	

	    [trialCondition, trialBlock, flag_ignoreTrial] = ...
            getTrialConditionAndBlock(fileName,participantCarMetaData);

        if(messageLevel > 0)
            strIgnore='';
            if(flag_ignoreTrial)
                strIgnore = '*ignore';
            end
            fprintf('    %s\t%s\t%s\n',trialCondition,trialBlock, strIgnore);
        end	        

        fileNameBiopacData = ...
        	fullfile(filesInCarBiopacFolder(indexMatFile(indexFile,1)).folder,...
        	filesInCarBiopacFolder(indexMatFile(indexFile,1)).name);

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

        %Christa & Celine: you can normalize the EMG signals from 
        %the biopac data here.

        % normalizeEmg(carBiopacDataEnv, ..
        %              participantMvcData,...
        %              biopacIndices,...
        %              biopacKeywords);
        %
        carBiopacDataNorm = carBiopacDataEnv;

        flag_plotNormDebugData=0;
        if(flag_plotNormDebugData==1)
            figNormDebugData=figure;
        end
        for indexMuscle=firstMuscleBiopacIndex:1:lastMuscleBiopacIndex

            directionAllValues = [];
            for indexDirection=1:1:size(participantMvcData.biopacSignalNorm,1)

                directionRowVector = ...
                   [participantMvcData.biopacSignalNorm(indexDirection, 1).max(indexMuscle),...
                    participantMvcData.biopacSignalNorm(indexDirection, 2).max(indexMuscle)];

                directionAllValues=[directionAllValues;...
                                    directionRowVector];


            end
                muscleMax(indexMuscle)=max(directionAllValues, [], 'all');
                carBiopacDataNorm.data(:,indexMuscle) = ...
                    carBiopacDataNorm.data(:,indexMuscle)./muscleMax(indexMuscle);
                if(flag_plotNormDebugData==1)
                    figure(figNormDebugData);
                    subplot(2,3,indexMuscle-firstMuscleBiopacIndex+1);
                    lineColor=[0,0,1];
                    if(min(carBiopacDataNorm.data(:,indexMuscle))<=0 || ...
                       max(carBiopacDataNorm.data(:,indexMuscle))>=1.25)
                        lineColor=[1,0,0];
                    end

                    plot(timeV, carBiopacDataNorm.data(:,indexMuscle),...
                        'Color',lineColor);
                    hold on;
                    xlabel('Time (s)');
                    ylabel('Norm. EMG (mvc)');
                    muscleName = biopacChannels{indexMuscle};
                    i0 = strfind(muscleName,'_');
                    muscleName(i0)=' ';
                    title(muscleName);
                    box off;
                    axis tight;
                end
        end        

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


        if(length(timeV) > biopacParameters.sampleFrequencyHz*minimumTrialTime)
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

    
    
            %Save the data to a struct
            participantEmgData(indexFile) ...
            = struct(...
                'id',           indexParticipant,...
                'fileName',     fileName,...
                'condition',    trialCondition,...
                'block',        trialBlock,...
                'carDirection', carDirection,...             
                'biopacSignalIntervals',biopacSignalIntervals,...
                'biopacIndices',biopacIndices,...
                'flag_ignoreTrial',flag_ignoreTrial,...
                'flag_carMoved',   flag_carMoved);
    
            %Replace spaces in the file name with '_'
            fileName = filesInCarBiopacFolder(indexMatFile(indexFile,1)).name;
		    idxSpace = strfind(fileName,' ');
		    idxPoint = strfind(fileName,'.');
		    assert(length(idxPoint)==1);
		    fileNameNoSpace = fileName(1,1:(idxPoint-1));
		    fileNameNoSpace(1,idxSpace) = '_';    
    
    
            if(flag_plotOnset==1)
            
                figOnset = configPlotExporter( figOnset,...
                                                pageWidthCm,...
                                                pageHeightCm);
    
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
