clc;
close all;
clear all;


% 0: 2022 data set
% 1: 2023 data set
flag_dataSet = 0;

flag_plotAcceleration=1;

flag_runOneParticipant  = 0;
runThisParticipant      = 1;

%0: No extra messages
%1: Messages at every major processing step
messageLevel = 1;

minimumTrialTime              = 1;


if(flag_plotAcceleration==1)
    figAcceleration=figure;
end

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

%These are the default values for the onset detection algorithm. For
%documentation on these fields please see main_emgBatchProcess.m
flag_plotOnsetAlgorithmDetails                          = 1;
onsetDetectionSettings.typeOfNoiseModel                 = 2;
onsetDetectionSettings.noiseWindowInNormalizedTime      = [0,0.29];
onsetDetectionSettings.signalWindowInNormalizedTime     = [0.3,0.99];
onsetDetectionSettings.maxAcceptableNoiseProbability    = 0.001;
onsetDetectionSettings.numberOfNoiseSubWindows          = 5;
onsetDetectionSettings.lowFrequencyFilterCutoff         = 10;
onsetDetectionSettings.minimumAcceptableOnsetTime       = 0;
onsetDetectionSettings.maximumAcceptableOnsetTime       =  1;
onsetDetectionSettings.minimumTimingGap                 = 0.050; 

%%
% Paths
%%
%adds the 'algorithms' and 'inputOutput' paths to the places where Matlab
%will look for functions. If these lines are omitted then Matlab cannot
%find the 'getParticipantFolders' function
addpath('algorithms');
addpath('inputOutput');

%Check that Matlab is currently in the code directory
localPath=pwd();
[parentFolderPath,parentFolder] = fileparts(localPath);

assert(contains(parentFolder,'code'));
assert(contains(parentFolderPath,'WhiplashExperimentProcessing'));

whiplashFolder= parentFolderPath;
codeFolder=localPath;

dataSetFolder = [];
outputSetFolder=[];
numberOfParticipants = 0;

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

%%
% Setup the output plots
%%
maxPlotRows          = 4;
maxPlotCols          = 3;
plotWidthCm          = 24.0; 
plotHeightCm         = 5.0;
plotHorizMarginCm    = 3.5;
plotVertMarginCm     = 3.5;

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
% Go get the head acceleration
%%
participantFirst = 1;
participantLast  = numberOfParticipants;
if(flag_runOneParticipant==1)
    participantFirst = runThisParticipant;
    participantLast  = runThisParticipant;
end

for indexParticipant = participantFirst:1:participantLast

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

            participantCarMetaData= ...
               getParticipantCarDataMay2022(indexParticipant);            

		case 1
	        participantMetaData = ...
                 getParticipantDataFebruary2023(indexParticipant);

            participantCarMetaData= ...
               getParticipantCarDataFebruary2023(indexParticipant);

		otherwise
			assert(0,'Error: flag_dataSet must be 0 or 1');    
    end
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
    if(exist('carAccelerationPulse','var'))
        clear('carAccelerationPulse');
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

    %Make the output struct
    if(exist('carAccelerationPulse','var'))
        clear('carAccelerationPulse');
    end
    
    %Define the struct
    carAccelerationPulse(numberOfTrialsToAnalyze) ...
        = struct(...
            'acceleration',[],...
            'id',indexParticipant,...
            'filePath','',...
            'fileName','',...
            'fileNumber',0,...
            'condition','',...
            'block','',...
            'carDirection','',...              
            'flag_ignoreTrial',0,...
            'flag_carMoved', 0);

    %Initialize the struct
    for indexFile = 1:1:length(carAccelerationPulse)
        carAccelerationPulse(indexFile).time                  = [];
        carAccelerationPulse(indexFile).acceleration          = [];
        carAccelerationPulse(indexFile).id                    = indexParticipant;
        carAccelerationPulse(indexFile).filePath              = [];
        carAccelerationPulse(indexFile).fileName              = [];
        carAccelerationPulse(indexFile).fileNumber            = 0;
        carAccelerationPulse(indexFile).condition             = [];
        carAccelerationPulse(indexFile).block                 = [];
        carAccelerationPulse(indexFile).carDirection          = [];
        carAccelerationPulse(indexFile).flag_ignoreTrial      = 1;
        carAccelerationPulse(indexFile).flag_carMoved         = 0;
    end

    %Scan the car meta data to
    % 1. Build a list of file names to process
    % 2. Note any missing file names that are not in the  'ignoreTheseFileNumbers' list,
    [carAccelerationPulse, listOfFilesToProcess] ...
        = updateParticipantEmgDataFileNames(carAccelerationPulse, ...
                                            filesInCarBiopacFolder, ...
                                            indexOfMatFilesInCarBiopacFolderList, ...
                                            participantCarMetaData);

    flag_firstPlot=ones(4,1); 
    if(flag_plotAcceleration==1)
        clf(figAcceleration);
    end

    for indexFileList = 1:1:length(listOfFilesToProcess)

        indexFile = listOfFilesToProcess(1,indexFileList);
    
        fileName = carAccelerationPulse(indexFile).fileName;

        if(messageLevel > 0)
            fprintf('  Loading: %i.\t%s\n',indexFileList,fileName);
        end	

	    [trialCondition, trialBlock, flag_ignoreTrial] = ...
            getTrialConditionAndBlock(  fileName,...
                                        participantCarMetaData);  

        carAccelerationPulse(indexFile).condition=trialCondition;
        carAccelerationPulse(indexFile).block=trialBlock;
        carAccelerationPulse(indexFile).flag_ignoreTrial = flag_ignoreTrial;

        if(messageLevel > 0)
            strIgnore='';
            if(flag_ignoreTrial)
                strIgnore = '*ignore';
            end
            fprintf('    %s\t%s\t%s\n',trialCondition,trialBlock, strIgnore);
        end	        

        fileNameBiopacData = ...
        	fullfile(  carAccelerationPulse(indexFile).filePath,fileName);

        %carBiopacDataRaw is left in its un processed form.
        carBiopacDataRaw = load(fileNameBiopacData);  

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

            carAccelerationPulse(indexFile).flag_ignoreTrial = 1;

        else
            %%
            %Check if the car accelerated
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

            figOnset       = [];
            flag_plotOnset = 0;
            indexSubplot   = [];
            subPlotPanelLocal   = [];
            colorOnset     = [0,0,0];

		    [biopacSignalIntervals,flag_carMoved,indexSubplot,figOnset] ...
                    = extractAccelerationInterval(...
                            timeV,...
                            carBiopacDataRaw,...   
                            biopacSignalIntervals,...        
                            minimumAcceleration,...
                            onsetDetectionSettings,...
                            biopacIndices,...
                            biopacKeywords,...
                            biopacParameters,...
                            flag_plotOnset,...
                            indexSubplot,...
                            subPlotPanelLocal,...
                            colorOnset,...                        
                            figOnset);

            %%
            % Get the direction of the car's acceleration
            %%
            carDirection = 'Static';
            if(flag_carMoved==1)
    	        carDirection = extractCarAccelerationDirection(...
					        carBiopacDataRaw,...
                            biopacSignalIntervals,...
                            biopacIndices);
            end 

            

            if(strcmp(carDirection,'Static')==0)
                switch carDirection
                    case 'Forwards'
                        subInterval=biopacSignalIntervals(biopacIndices.indexAccCarY).intervalIndices;
                    case 'Backwards'
                        subInterval=biopacSignalIntervals(biopacIndices.indexAccCarY).intervalIndices;                     
                    case 'Left'
                        subInterval=biopacSignalIntervals(biopacIndices.indexAccCarX).intervalIndices;                       
                    case 'Right'
                        subInterval=biopacSignalIntervals(biopacIndices.indexAccCarX).intervalIndices;
                end            
                subInterval =[min(subInterval):1:max(subInterval)]'; 
    
                carAccelerationPulse(indexFile).time = timeV;%(subInterval,1);
%                 carAccelerationPulse(indexFile).time = ...
%                     carAccelerationPulse(indexFile).time ...
%                    -carAccelerationPulse(indexFile).time(1,1);
    
                carAccelerationPulse(indexFile).acceleration = ...
                    [carBiopacDataRaw.data(:,biopacIndices.indexAccCarX),...
                     carBiopacDataRaw.data(:,biopacIndices.indexAccCarY),...
                     carBiopacDataRaw.data(:,biopacIndices.indexAccCarZ)];
            end

            if(flag_plotAcceleration==1 && strcmp(carDirection,'Static')==0)
                row=1;
                plotTitleText = '';
                switch carDirection
                    case 'Forwards'
                        row=1;
                    case 'Backwards'
                        row=2;                        
                    case 'Left'
                        row=3;                        
                    case 'Right'
                        row=4;                        
                end

                figure(figAcceleration);

                n = (indexFileList-1)/(length(listOfFilesToProcess)-1);
                lineColor = [0,0,0].*n + [0.75,0.75,0.75].*(1-n);

                subplot('Position',reshape(subPlotPanel(row,1,:),1,4));
                    plot(carAccelerationPulse(indexFile).time,...
                         carAccelerationPulse(indexFile).acceleration(:,1),...
                         '-','Color',lineColor);
                    hold on;
                    box off;
                    if(flag_firstPlot(row,1)==1)
                        xlabel('Time (s)');
                        ylabel('Acceleration ($$g$$)');
                        title([carDirection,' ','X']);
                    end
                subplot('Position',reshape(subPlotPanel(row,2,:),1,4));
                    plot(carAccelerationPulse(indexFile).time,...
                         carAccelerationPulse(indexFile).acceleration(:,2),...
                         '-','Color',lineColor);
                    hold on;
                    box off;                    
                    if(flag_firstPlot(row,1)==1)
                        xlabel('Time (s)');
                        ylabel('Acceleration ($$g$$)');
                        title([carDirection,' ','Y']);
                    end
                subplot('Position',reshape(subPlotPanel(row,3,:),1,4));
                    plot(carAccelerationPulse(indexFile).time,...
                         carAccelerationPulse(indexFile).acceleration(:,3),...
                         '-','Color',lineColor);
                    hold on;
                    if(flag_firstPlot(row,1)==1)
                        xlabel('Time (s)');
                        ylabel('Acceleration ($$g$$)');
                        title([carDirection,' ','Z']);
                    end
                    box off;
                    
                flag_firstPlot(row,1)=0;

            end

            

        end
        
    end

    numStr = num2str(indexParticipant);
    if(length(numStr)<2)
        numStr = ['0',numStr];
    end
    fileName = ['carAccelerationPulse_participant',numStr,'.mat'];
    save([outputFolders.common,filesep,fileName],'carAccelerationPulse');

    figFileName = ['fig_carAccelerationPulse_participant',numStr,'.png'];
    saveas(figAcceleration,[outputFolders.common,filesep,figFileName]);


    here=1;
end