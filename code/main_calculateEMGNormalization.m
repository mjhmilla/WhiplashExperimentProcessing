%% main_CelineUndChrista 
clc
clear all
close all;

% 0: 2022 data set
% 1: 2023 data set
flag_dataSet = 1;

flag_plotData = 1;

modeScanForMissingFiles= 0;
modeProcess            = 1;
scriptMode             = modeProcess; %modeScanForMissingFiles;

flag_runOneParticipant  = 0;
runThisParticipant      = 1;

%%
% Constants
%%

%Parameters for Norman's special ECG removal algorithm: 
% 1. Identify ECG peaks in the ECG channels
% 2. For each peak, go to the each of the EMG signals and high pass
%    filter the data at highpassFilterFrequency (in Hz) that is +/- the 
%    windowDuration in seconds
%
% CC: I could have picked better variable names here:
%  windowDurationInSeconds
%  highpassFilterFrequencyInHz
%
ecgRemovalFilterWindowParams = struct('windowDurationInSeconds',0.16,...
                                      'highpassFilterFrequencyInHz',20);

%This is used for all low pass filters that are applied to the EMG data
%in evaluating the EMG envelope and in any other processing.
%
% CC: What would have been a better variable name for
% lowFrequencyFilterCutoff?
lowFrequencyFilterCutoffInHz = 10;


%%
% Paths
%%
%CC: these two lines were missing. The 'addpath' function
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
                                           
    cd(inputFolders.mvcBiopac);    
    filesInMvcBiopacFolder = dir();
    cd(codeFolder);
    
    
    %This snippet should stay: the 2022 data set has a mix of *.acq and *.mat 
    %files
    indexMatFileMvc= [];
    for indexFile=1:1:length(filesInMvcBiopacFolder)
        if(contains(filesInMvcBiopacFolder(indexFile).name,'.mat'))
            indexMatFileMvc = [indexMatFileMvc;indexFile];
        end
    end
    
    %% load emg data
    % CC: camelCase variables start with a lower case :)
    %     And don't forget the other fields returned by getParticipantMvcData
    %     ...
    [mvcData, indicesMvcData, namesMvcData]= ...
        getParticipantMvcDataFebruary2023(indexParticipant);
    
    
    
    [biopacParameters,biopacKeywords,biopacChannels,biopacIndices] ...
        = getBiopacMetaData([]);
    numberOfEmgSignals = length(biopacIndices.indicesOfEmgData);
    %%
    %Plot options
    %%
    if(flag_plotData==1)
        %This struct holds the handles ('h') for each figure. Here we have 
        %one figure per Emg signal, and each figure contains the recordings
        %from the 8 different trails
        figDebugPlotStruct(numberOfEmgSignals)=struct('h',[],'name',[]);
        for i=1:1:numberOfEmgSignals
            figDebugPlotStruct(i).h=figure;
        end
    end
    
    maxPlotRows          = height(mvcData.mvcFiles);
    maxPlotCols          = width(mvcData.mvcFiles);
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
    % Define any memory that is used in the loop
    %%
    %CC: I've added a name field that will be programmatically set. I've also
    %    chosen a slightly shorter name. The name you picked is perfect. It
    %    just makes it difficult to keep the lines to 80 characters long.
    biopacSignalNorm(height(mvcData.mvcFiles),width(mvcData.mvcFiles))...
        =struct('max',nan,...
                'maxFieldNames',[],...
                'name','');
    for i=1:1:size(biopacSignalNorm,1)
        for j=1:1:size(biopacSignalNorm,2)
            biopacSignalNorm(i,j).maxFieldNames = cell(1,numberOfEmgSignals);
        end
    end
    
    
    
    % CC:
    % For loop indexes I usually begin with 'index' so that it is clear that
    % the variable is a counter. I haven't seen the height and width functions
    % until now, so I've learned something :). I usually use row and column, 
    % which are equivalent.
    for indexDirections=1:height(mvcData.mvcFiles)
    
        for indexTrials=1:width(mvcData.mvcFiles)
            biopacSignalNorm(indexDirections,indexTrials).name ...
                = [namesMvcData{1,indexDirections},':',num2str(indexTrials)];
    
            %CC: This is a personal preference (totally optional) but I do like
            % to have a variable name that describes the data that the variable
            % stores. So rather than 'trial' I would use 'fileNameTrial'. If
            % there's only one file name being used in the loop, 'fileName'
            % would also be fine. You can even compact this to one line
            cd(inputFolders.mvcBiopac);
    
            flag_fileExists=1;
            if(exist(mvcData.mvcFiles{indexDirections,indexTrials})==0)
                disp(['  ',mvcData.mvcFiles{indexDirections,indexTrials},' is a missing file']);
                flag_fileExists=0;
            end

            if(flag_fileExists==1 && scriptMode == modeProcess)
                %CC: Curly braces must be used with a cell array so that the 
                %    string is returned, rather than the cell
                mvcBiopacDataRaw = load(mvcData.mvcFiles{...
                                            indexDirections,indexTrials});
                cd(codeFolder);
        
                %CC: If possible avoid copying over variables: 'mvcBiopacDataRaw.data' 
                % In this case it isn't too bad since mvcBiopacDataRaw.data is
                % around 3 mb. When the data becomes bigger this can be a drain on
                % the computer's resources.
                %
                % I've copied these out because the variables aren't being used.
                %MvcDataRawEmg=mvcBiopacDataRaw.data;
                %MvcDataRawLabels=mvcBiopacDataRaw.labels;
                
                %% remove ecg from emg
                
                %CC: With the 'addpath' function above the code you need is
                %available
                %cd('C:\Users\User\Documents\Uni\Bachelor definitiv\WhiplashExperimentProcessing\code');
                
                %CC: I've updated getBiopacMetaData to take in the biopac data
                %    and return a filled biopacIndices struct.
                [biopacParameters,biopacKeywords,biopacChannels,biopacIndices] ...
                    = getBiopacMetaData(mvcBiopacDataRaw);
        
        
                %CC: Any numerical constants (like the window duration) should
                %    be at the very beginning of the file in a named variable: this
                %    makes it clear to anyone using this code in the future that
                %    the constant can be changed. I've moved this variable up,
                %    but left the commented version here.
                %ecgRemovalFilterWindowParams = struct('windowDuration',0.16,...
                %                                  'highpassFilterFrequency',20);
                mvcBiopacDataNoEcg = removeEcgFromEmg(mvcBiopacDataRaw,...
     					                biopacKeywords.emg, ...
     					                biopacKeywords.ecg,...
        				                ecgRemovalFilterWindowParams, ...
        				                biopacParameters.sampleFrequencyHz);
                
                %% emg envelope
                %CC: Again, this is a numerical constant so it should be set at 
                %    the beginning of the script.
                %lowFrequencyFilterCutoff = 10;
                emgEnvelopeLowpassFilterFrequency   = lowFrequencyFilterCutoffInHz;
                
                %CC: This is going to be inefficient in terms of memory because
                %    Matlab has to figure out dynamically how to store everything
                %    in mvcBiopacDataEnv. For now I'm leaving this but it would be
                %    best not to save this data unless you need it.
                %
                %    If you're just saving this data so that you can plot it (which
                %    is great!) then you can plot the data right here. I've updated
                %    the code under this assumption
                %
                mvcBiopacDataEnv = ...
                        calcEmgEnvelope(mvcBiopacDataNoEcg,...
                                        biopacKeywords.emg, ...
                                        emgEnvelopeLowpassFilterFrequency, ...
                                        biopacParameters.sampleFrequencyHz);
        
                % extract maxima & save data 
                %CC: I renamed muscle to indexEmgSignal because we're iterating
                %over EMG signals. When I work with a musculoskeletal model I do 
                %actually use indexMuscle.
                %
                %CC: I've updated the for loop to use biopacIndices.indicesOfEmgData
                %    because additional data sets might not have EMG data ordered
                %    in the same way.
                indexEmgSignalCount=1;
        
                timeV = [];
                if(flag_plotData==1)
                    dt=(1/biopacParameters.sampleFrequencyHz);
    	            duration = (size(mvcBiopacDataRaw.data,1)/biopacParameters.sampleFrequencyHz);
    	            timeV = [dt:dt:duration]';   
                end
        
                for indexEmgSignal=biopacIndices.indicesOfEmgData 
                    %CC: line lengths should be kept to 80 characters long. You can
                    %  have Matlab draw a vertical line at 80 characters in the 
                    %  editor to help you:
                    %  https://de.mathworks.com/help/matlab/ref/matlab.editor-settings.html
                    [mvcValueEnvelope(indexEmgSignal),indexMax]=...
                        max(mvcBiopacDataEnv.data(:,indexEmgSignal));
        
                    %results don't change if we cancel this line
                    %CC: That makes sense because numberOfSignals is not being
                    %    used anywhere.
                    %numberOfSignals = size(mvcBiopacDataRaw.data,indexEmgSignal); 
        
                    %CC: I've defined biopacSignalNorm above, and
                    %pre-allocated the memory.
                    biopacSignalNorm(indexDirections,indexTrials).max = ...
                        mvcValueEnvelope;
        
                    biopacSignalNorm(indexDirections,indexTrials...
                        ).maxFieldNames{indexEmgSignalCount} ...
                        = biopacChannels(indexEmgSignal);
        
        
                    if(flag_plotData==1)                
                        figure(figDebugPlotStruct(indexEmgSignalCount).h);    
                        subplot('Position',...
                            reshape(subPlotPanel(indexDirections,indexTrials,:),1,4));
                        plot(timeV,mvcBiopacDataRaw.data(:,indexEmgSignal),...
                            'Color',[1,1,1].*0.75);
                        hold on;                
                        plot(timeV,mvcBiopacDataEnv.data(:,indexEmgSignal),...
                            'Color',[0,0,0]);
                        hold on;
                        plot(timeV(indexMax,1),...
                             mvcBiopacDataEnv.data(indexMax,indexEmgSignal),...
                            'o','MarkerSize',5,'MarkerFaceColor',[1,0,0]);
                        hold on;
        
                        text(timeV(indexMax,1),...
                             mvcBiopacDataEnv.data(indexMax,indexEmgSignal),... ...
                             sprintf('%1.3f',mvcBiopacDataEnv.data(indexMax,indexEmgSignal)),...
                             'HorizontalAlignment','left',...
                             'VerticalAlignment','bottom',...
                             'FontSize',12);
                        hold on;
        
                        box off;
        
                        xlabel('Index');
                        ylabel('Emg Signal Magnitude');
                        
                        trialName = ...
                            [biopacChannels{1,indexEmgSignal},':',...
                             biopacSignalNorm(indexDirections,indexTrials).name];
        
                        idx=strfind(trialName,'_');
                        trialNameNoUnderscore=trialName;
                        trialNameNoUnderscore(1,idx) =' ';
                        title(trialNameNoUnderscore,...
                            'interpreter','latex',...
                            'FontSize',12);
        
                        xlim([timeV(indexMax,1)-4,timeV(indexMax,1)+4]);
                        ylim([0, max(mvcBiopacDataRaw.data(:,indexEmgSignal))]);
                        
                        figDebugPlotStruct(indexEmgSignalCount).name =...
                            biopacChannels{indexEmgSignal};
        
                        here=1;
                    end
                    indexEmgSignalCount=indexEmgSignalCount+1;
        
                end
            end
        end
    end  
    
    %Save the data
    if(scriptMode == modeProcess)
        indexParticipantStr=num2str(indexParticipant);
        if(length(indexParticipantStr)<2)
            indexParticipantStr = ['0',indexParticipantStr];
        end
        
        participantStr = sprintf('participant%s',indexParticipantStr);
        dataName = sprintf(['emgMvcMaxOutput_%s.mat'],  participantStr);
        dataPath = fullfile(outputFolders.common,dataName);
        save(dataPath,'biopacSignalNorm');
        
        %Save the figures
        for i=1:1:numberOfEmgSignals
        
            figure(figDebugPlotStruct(i).h);
        
            figDebugPlotStruct(i).h...
                = configPlotExporter( figDebugPlotStruct(i).h,...
                                      pageWidthCm,...
                                      pageHeightCm);
        
        
            
            plotName = sprintf(['fig_MVC_%s.png'], ...
                figDebugPlotStruct(i).name);
            
            plotPath = fullfile(outputFolders.mvcBiopac,plotName);
            print('-dpng', plotPath);
            close(figDebugPlotStruct(i).h);
        end
    end
end 



%mvcBiopacDataEnv=...
%    struct(...
%    'Extension', mvcBiopacDataEnv(1,:),...
%    'Right', mvcBiopacDataEnv(2,:),...
%    'Flexion', mvcBiopacDataEnv(3,:),...
%    'Left', mvcBiopacDataEnv(4,:));
 
%CC: Do not hard code the indices and the names. In the 2022 data set the 
%    ordering is completely different. Instead I've added a name field
%    to biopacSignalNorm that gets set in the loop.
%biopacSignalNorm=...
%    struct(...
%    'Extension', biopacSignalNorm(1,:),...
%    'Right', biopacSignalNorm(2,:),...
%    'Flexion', biopacSignalNorm(3,:),...
%    'Left', biopacSignalNorm(4,:));
   
                        
                        
                        
                        
                        