%%
% @author: Matthew Millard
% @date: 19/12/2023 
%
%
% Description:
% This function loads the scaled passenger model and
%
% 1. Runs the IKTool for 1 frame and allows the pelvis ground point to
%    go to the location that satisfies the marker locations and the 
%    default coordinates for the pitch, roll, yaw, and lumbar spine angles.
%
% 2. The ground positions are set to the ones identified in #1 and the 
%    IKTool is now run on the entire span of data with, in addition to #1, a 
%    penalty term on gndx, gndy, and gndz.
%
%%


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

assert(flag_dataSet==0,'Error: Code has not yet been updated to work',...
    ' with the 2023 dataset, which includes a different marker layout.');


flag_runIKTool      = 1;

runThisParticipant  =  []; %[{'participant01'}];%[{'participant17'}];
runTheseTrials      = [1]; %[1];%[2];

%
% Pull in the modeling classes straight from the OpenSim distribution
%
import org.opensim.modeling.*

%
% Check that we are starting in the correct directory
%
currentDirContents  = dir;
currentDirectory    = pwd; 

assert( contains( currentDirContents(1).folder(1,(end-5):1:end),'code')==1,...
        'Error: script must be started in the code directory');
codeDir = pwd;
addpath('algorithms/');
addpath('inputOutput/');

codeDir = currentDirContents(1).folder;
cd ..;
startDir= pwd; 
switch flag_dataSet
    case 0
        dataDir   	= 	fullfile(startDir,'data2022');
        opensimDir	=	fullfile(startDir,'opensim2022');
    case 1
        dataDir 	= 	fullfile(startDir,'data2023');        
        opensimDir	=	fullfile(startDir,'opensim2023');        
    otherwise assert(0,'Error: unknown dataset');
end

cd(opensimDir);
dataDirContents = dir;
participantFolderList = [];

if(isempty(runThisParticipant))
    for i=1:1:length(dataDirContents)
        if( dataDirContents(i).isdir==1 && ...
            contains(dataDirContents(i).name,'participant') && ...
            length(dataDirContents(i).name) == 13 )
           participantFolderList = ...
               [participantFolderList;...
                {dataDirContents(i).name} ];
           here=1;
        end
    end
else
    participantFolderList=runThisParticipant;
end

participantCount = length(participantFolderList);
if(isempty(runThisParticipant) == 0)
    participantCount = 1;
end

for indexParticipantCount=1:1:participantCount
    
    indexParticipant = 0;
    participantFolder = '';
	if(isempty(runThisParticipant)==0)
        indexParticipant = runThisParticipant(1,1);
        participantFolder = 'participant';
        idStr = num2str(indexParticipant);
        if(length(idStr)<2)
            idStr = ['0',idStr];            
        end
        participantFolder = [participantFolder,idStr];
    else
        indexParticipant = indexParticipantCount;
        participantFolder = participantFolderList{indexParticipant};
    end

    
    fprintf('%s: \n',participantFolder);   
    idStr = participantFolder(end-1:end);
	id = str2num(idStr);


    if(flag_runIKTool==1)    	      
        %
        % Check to make sure that the participant data folder contains 
        % all necessary folders
        %
        flag_carFolder=0;
        flag_trcFolder=0;
    
        carDir=[dataDir,filesep,participantFolder,filesep,'car'];
        assert(exist(carDir,'dir')== 7,...
               sprintf('Error: this directory does not exist: %s',carDir));
        flag_carFolder=1;
    
    
        trcDir=[carDir,filesep,'optitrack',filesep,'trc'];
        assert(exist(trcDir,'dir')== 7,...
               sprintf('Error: this directory does not exist: %s',trcDir));
        flag_trcFolder=1;
        
        assert(flag_carFolder==1,'Error: car folder is missing');
        assert(flag_trcFolder==1,'Error: trc folder is missing');
		
		%
		% Get the list of trc files to use with the IK tool
		%
		cd(trcDir);
		trcDirFiles = dir();
		cd(codeDir);
		indiciesOfValidTrcFiles = [];
		for i=1:1:length(trcDirFiles)
			if(trcDirFiles(i).isdir == 0 ...
			   && contains(trcDirFiles(i).name,'.trc') ...
			   && ~contains(trcDirFiles(i).name,'_raw.trc'))
			   indiciesOfValidTrcFiles = ...
                   [indiciesOfValidTrcFiles; i];
			end
		end

        %
	    % Copy over the default IK file 
        %
	    defaultIKSetupFile = [startDir,filesep,'opensim2022',filesep,...
            'models',filesep,'IK_Setup.xml'];
    
        ikSetupFile = [startDir,filesep,'opensim2022',filesep,...
            participantFolder,filesep,...
            'IK_Setup.xml'];
	
        copyfile(defaultIKSetupFile,ikSetupFile);        

        %
        %Open the model file   
        %
        modelFile = [startDir,filesep,'opensim2022',filesep,...
            participantFolder,filesep,participantFolder,'_scaled.osim'];

        model = Model(modelFile);
        model.initSystem();
        model.setName(participantFolder);

        for indexIK=indiciesOfValidTrcFiles

            %
            % Start and end times
            %
            trcFolder       = trcDirFiles(indexIK).folder;
            trcFile         = trcDirFiles(indexIK).name;
            trcFolderFile   = [trcFolder,filesep,trcFile];

            [trcMetaData, trcFrameTime, trcMarkerData] ...
                = readTRCFile(trcFolderFile);

            timeStart = min(trcFrameTime(2).value);
            timeEnd   = max(trcFrameTime(2).value);

            timeEndOneFrame = trcFrameTime(2).value(2,1);

            timeRangeKeyWord = '<time_range>';            
            timeRangeReplacement = ...
                sprintf('<time_range>%1.3f %1.3f</time_range>',...
                         timeStart, timeEndOneFrame);

            %
            % Output file name
            %

            motFile = trcFile;
            i = strfind(motFile,'.trc');
            motFile = [motFile(1:i),'mot'];

            outputMotionFileKeyWord = '<output_motion_file>';
            outputMotionFileReplacement = ...
                [startDir,filesep,'opensim2022',filesep,...
                 participantFolder,filesep,'ik',filesep];

            %
            % gndx, gndy, gndz related variables
            %
            gndxEnableKeyWord = 'gndx_enable';
            gndxEnableReplacement = '<apply>false</apply>';
            gndyEnableKeyWord = 'gndy_enable';
            gndyEnableReplacement = '<apply>false</apply>';
            gndzEnableKeyWord = 'gndz_enable';
            gndzEnableReplacement = '<apply>false</apply>';

            gndxValueKeyWord = '<value>gndx_value';
            gndxValueReplacement = '<value>0</value>';
            gndyValueKeyWord = '<value>gndy_value';
            gndyValueReplacement = '<value>0</value>';
            gndzValueKeyWord = '<value>gndz_value';
            gndzValueReplacement = '<value>0</value>';

            %
            % marker data
            %

            markerFileKeyWord = '<marker_file>';
            markerFileReplacement = ...
                ['<marker_file>',trcFolderFile,'</marker_file>'];

            %
            % Replace the keywords
            %
            findLinesWithThisKeyword = ...
                {timeRangeKeyWord;...
                 gndxEnableKeyWord;...
                 gndyEnableKeyWord;...
                 gndzEnableKeyWord;...
                 gndxValueKeyWord;...
                 gndyValueKeyWord;...
                 gndzValueKeyWord;...
                 markerFileKeyWord};

            replacementLines = ...
                {timeRangeReplacement;...
                 gndxEnableReplacement;...
                 gndyEnableReplacement;...
                 gndzEnableReplacement;...
                 gndxValueReplacement;...
                 gndyValueReplacement;...
                 gndzValueReplacement;...
                 markerFileReplacement};

            ikSetupFileA = ikSetupFile;
            i=strfind(ikSetupFileA,'.xml');
            i=i-1;
            ikSetupFileA = [ikSetupFileA(1,1:i),'_1Frame.xml'];
           
            success = findReplaceLinesInFile(...
                        ikSetupFile,...
                        ikSetupFileA, ...
                        findLinesWithThisKeyword, ...
                        replacementLines );            

            %
            % Copy over ikSetupFileA and make a setup file that 
            % processes all data and applies a regularization term on the
            % location of the pelvis-seat.
            %

            ikSetupFileB = ikSetupFile;
            i=strfind(ikSetupFileB,'.xml');
            i=i-1;
            ikSetupFileB = [ikSetupFileB(1,1:i),'_AllFrames.xml'];
        end


        %
        % Run the IKTool for a short time to get the position of the 
        % seat-pelvis joint when gndpitch, gndroll, gndyaw, and the 
        % lumbar spine generalized coordinates meet their default
        % targets
        %        
        
        cd(participantFolder);
        scaleTool = ScaleTool(scaleFile);
        scaleTool.run();
        cd('..');
        
        		
    end


end
cd(codeDir);
