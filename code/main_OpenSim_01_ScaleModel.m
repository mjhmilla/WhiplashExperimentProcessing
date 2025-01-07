%%
% @author: Matthew Millard
% @date: 19/12/2023 
%
%
% Description:
% This function takes the generic passenger model and:
%
% 1. Uniformly scales the ribcage, lumbar spine, and pelvis to be consistent 
%    with the (norm) distance between the C7 and hip-joint center as reported in 
%    De Leva (Table 4). This distance in the passengerModel is 0.6095 m
%
%	:C7 to hip joint: 
%		male 	603.3mm / 1741mm 
%			= 0.3465249856404365
%		female	614.8mm / 1735mm
%			= 0.3543515850144092
%
%	These are so close that I'm just going to use an average
%
%	normLength_C7_HJC_Height = 0.350438285327423
%
% 	De Leva P. Adjustments to Zatsiorsky-Seluyanov's segment inertia parameters. 
% 	Journal of biomechanics. 1996 Sep 1;29(9):1223-30.
%
% 2. Scale the following using the markers
% a. HeadWidth 			(LZP-RZP)  	: XYZ skull and jaw
% b. ShoulderWidth 		(LCAJ-RCAJ)	: XZ of the torso
% c. NeckLength 		(SJN-RZP)   : XYZ of cerv1-cerv7
% d. ClavicleLength_L 	(SJN-LCAJ)	: XYZ of lscapula and lclavicle
% e. ClavicleLength_R 	(SJN-RCAJ)	: XYZ of rscapula and rclavicle
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

normLength_c7_hjc_height 	= 0.350438285327423;
default_c7_hjc 				= 0.6095;
default_height 				= 1.74;

flag_runScaleTool      = 1;

runThisParticipant = [{'participant01'}];%[{'participant17'}];
runTheseTrials = [1];%[2];

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

for indexParticipant=1:1:length(participantFolderList)
    
	
    participantFolder = participantFolderList{indexParticipant};
    fprintf('%s: \n',participantFolder);   
    idStr = participantFolder(end-1:end);
	id = str2num(idStr);


    if(flag_runScaleTool==1)    
	    fileNumber 		= 1; 
	    timeNormSample 	= 0; %0 is the start, 1 is the end
    
        %
	    % Make updates to the few files in which the first file at its 
	    % starting time cannot be used for scaling. We require that the  
	    % participant have a neutral posture to be used for scaling.
        %
	    switch flag_dataSet
		    case 0
			    switch id
				    case 1
					    fileNumber = 1;
					    timeNormSample = 1;				
			    end
		    otherwise assert(0,'Error: unknown dataset');
	    end
    
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
	    % Copy over the default model file and the scale setup file
        %
	    defaultModelFile = [startDir,filesep,'opensim2022',filesep,...
            'models',filesep,'passengerModel.osim'];
	    defaultScaleFile = [startDir,filesep,'opensim2022',filesep,...
            'models',filesep,'Scale_Setup.xml'];
    
        modelFile = [startDir,filesep,'opensim2022',filesep,...
            participantFolder,filesep,participantFolder,'.osim'];
        scaleTmpFile = [startDir,filesep,'opensim2022',filesep,...
            participantFolder,filesep,'Scale_',participantFolder,'_temp.xml'];
        scaleFile = [startDir,filesep,'opensim2022',filesep,...
            participantFolder,filesep,'Scale_',participantFolder,'.xml'];
	
        copyfile(defaultModelFile,modelFile);        

        %
        %Open the model file   
        %
        model = Model(modelFile);
        model.initSystem();
        model.setName(participantFolder);

        %
        % Set the manual scale factors
        %

        fprintf('\t%s: \n','running the Scale Tool');  
		switch flag_dataSet
			case 0
				participantData     = getParticipantDataMay2022(id);
                participantCarData  = getParticipantCarDataMay2022(id);
			case 1
				participantData     = getParticipantDataFebruary2023(id);
                participantCarData  = getParticipantCarDataFebruary2023(id);
			otherwise assert(0,'Error: unknown dataset');
		end	

        scalingMarkerFilePath = ...
            ['..',filesep,...
            '..',filesep,...
            'data2022',filesep,...
            participantFolder,filesep,...
            'car',filesep,...
            'optitrack',filesep,...
            'trc',filesep,...
            participantCarData.scalingMarkerFile];

        modelNameKeyWord        = '<ScaleTool name';
        modelNameReplacement    = sprintf('<ScaleTool name="%s">', ...
                                           [participantFolder,'_scaled']) ;

        modelFileKeyWord        = '<model_file>';
        modelFileReplacement    = sprintf('<model_file>%s</model_file>',...
                                   [participantFolder,'.osim']);

        markerSetFileKeyWord    = '<marker_set_file>';
        markerSetFileReplacement = sprintf('<marker_set_file>%s</marker_set_file>',...
                                   scalingMarkerFilePath);

		l_c7_hjc 		= participantData.height*normLength_c7_hjc_height;
		scaling_c7_hjc 	= l_c7_hjc / default_c7_hjc;

        scaleKeyWord = '<scales>';
        scaleReplacement = sprintf('<scales> %1.6f %1.6f %1.6f</scales>',...
                          scaling_c7_hjc,scaling_c7_hjc,scaling_c7_hjc);

        %idxFileSep = strfind(scalingMarkerFilePath,'\');
        %scalingMarkerFilePath(1,idxFileSep) = '/';

        markerKeyWord = '<marker_file>';
        markerReplacement = sprintf('<marker_file>%s</marker_file>',...
                                    scalingMarkerFilePath);

        timeKeyWord     = '<time_range>';
        timeReplacement = ...
            sprintf('<time_range> %1.4f %1.4f</time_range>',...
                        participantCarData.scalingTimeRange(1,1),...
                        participantCarData.scalingTimeRange(1,2));

        staticPoseKeyWord = '<output_motion_file>';
        staticPoseReplacement = ...
            sprintf('<output_motion_file>%s</output_motion_file>',...
                        [participantFolder,'_staticPose.mot']);

        outputModelFileKeyWord = '<output_model_file>';
        outputModelFileReplacement = ...
            sprintf('<output_model_file>%s</output_model_file>',...
                        [participantFolder,'_scaled.osim']);

        outputMarkerFileKeyWord = '<output_marker_file>';
        outputMarkerFileReplacement = ...
            sprintf('<output_marker_file>%s</output_marker_file>',...
                        [participantFolder,'_scaled_markers.osim']);


        findLinesWithThisKeyword = ...
            {modelNameKeyWord;...
             modelFileKeyWord;...
             markerSetFileKeyWord; ...
             scaleKeyWord;...
             markerKeyWord;...
             timeKeyWord;...
             staticPoseKeyWord;...
             outputModelFileKeyWord;...
             outputMarkerFileKeyWord};

        replacementLines = ...
            {modelNameReplacement;...
             modelFileReplacement;...
             markerSetFileReplacement;...
             scaleReplacement;...
             markerReplacement; ...
             timeReplacement;...
             staticPoseReplacement;...
             outputModelFileReplacement;...
             outputMarkerFileReplacement};

        success = findReplaceLinesInFile(defaultScaleFile,scaleFile, ...
            findLinesWithThisKeyword, replacementLines );
        

        %
        % Set file to use for scaling and also for the marker adjustment
        %
		
		
		
		

    end


end
cd(codeDir);
