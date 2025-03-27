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
flag_quickCheck     = 1; %Will only process 1 second of data
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
    
        participantFolderPath = [startDir,filesep,'opensim2022',filesep,...
            participantFolder];

        ikSetupFile = [participantFolderPath,filesep,...
                       'IK_Setup.xml'];
	
        copyfile(defaultIKSetupFile,ikSetupFile);        

        %
        %Open the model file   
        %
        modelFile = [participantFolderPath,filesep,participantFolder,'_scaled.osim'];

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
            i=i-1;
            motFileOneFrame = [motFile(1:i),'_1Frame.mot'];
            motFileAll = [motFile(1:i),'_All.mot'];

            outputMotionFileKeyWord = '<output_motion_file>';

            outputMotionFile = ...
                [startDir,filesep,'opensim2022',filesep,...
                 participantFolder,filesep,'ik',filesep,...
                 motFileOneFrame];

            outputMotionFileReplacement = ...
                ['<output_motion_file>',...
                 outputMotionFile,...
                 '</output_motion_file>'];

            %
            % gndx, gndy, gndz related variables
            %
            gndxEnableKeyWord = '<apply>gndx_enable</apply>';
            gndxEnableReplacement = '<apply>false</apply>';
            gndyEnableKeyWord = '<apply>gndy_enable</apply>';
            gndyEnableReplacement = '<apply>false</apply>';
            gndzEnableKeyWord = '<apply>gndz_enable</apply>';
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
                 outputMotionFileKeyWord;...
                 gndxEnableKeyWord;...
                 gndyEnableKeyWord;...
                 gndzEnableKeyWord;...
                 gndxValueKeyWord;...
                 gndyValueKeyWord;...
                 gndzValueKeyWord;...
                 markerFileKeyWord};

            replacementLines = ...
                {timeRangeReplacement;...
                 outputMotionFileReplacement;...
                 gndxEnableReplacement;...
                 gndyEnableReplacement;...
                 gndzEnableReplacement;...
                 gndxValueReplacement;...
                 gndyValueReplacement;...
                 gndzValueReplacement;...
                 markerFileReplacement};

            ikSetupFileOneFrame = ikSetupFile;
            i=strfind(ikSetupFileOneFrame,'.xml');
            i=i-1;
            ikSetupFileOneFrame = [ikSetupFileOneFrame(1,1:i),'_1Frame.xml'];
           
            success = findReplaceLinesInFile(...
                        ikSetupFile,...
                        ikSetupFileOneFrame, ...
                        findLinesWithThisKeyword, ...
                        replacementLines );            

            %
            % Run the IKTool for a short time to get the position of the 
            % seat-pelvis joint when gndpitch, gndroll, gndyaw, and the 
            % lumbar spine generalized coordinates meet their default
            % targets
            %        
            cd(participantFolderPath);
            ikTool = InverseKinematicsTool(ikSetupFileOneFrame);
            ikTool.setModel(model);
            ikTool.run();
            cd('..');

            %
            % Load the single frame IK data set and get the position of
            % the pelvis-ground joint
            %
            motCoordsData = Storage(outputMotionFile);

            modelCoordSet   = model.getCoordinateSet();
            nCoords         = modelCoordSet.getSize();
            gndxyz          = [1,1,1].*nan;
            gndName         = {'gndx','gndy','gndz'};
            idxGnd          = 1;

            for z=0:1:(nCoords-1)
                coordValue = ArrayDouble();
                currentCoord = modelCoordSet.get(z);
                coordName = currentCoord.getName();
                if(idxGnd <= 3)
                    if( strfind(coordName,gndName{idxGnd})==1)
                        motCoordsData.getDataColumn(currentCoord.getName(),...
                                                    coordValue);
                        gndxyz(1,idxGnd) = coordValue.getitem(0);
                        idxGnd=idxGnd+1;
                    end
                end
            end

            %
            % In the next IK configuration set gndx, gndy, and gndz
            % and put penalty terms on each
            %
            timeRangeReplacement = ...
                sprintf('<time_range>%1.3f %1.3f</time_range>',...
                         timeStart, timeEnd);            

            if(flag_quickCheck==1)
                timeRangeReplacement = ...
                    sprintf('<time_range>%1.3f %1.3f</time_range>',...
                             (timeStart+0.25), (timeStart+0.50));            
            end

            outputMotionFile = ...
                [startDir,filesep,'opensim2022',filesep,...
                 participantFolder,filesep,'ik',filesep,...
                 motFileAll];

            outputMotionFileReplacement = ...
                ['<output_motion_file>',...
                 outputMotionFile,...
                 '</output_motion_file>'];

            %
            % gndx, gndy, gndz related variables
            %
            gndxEnableKeyWord       = '<apply>gndx_enable</apply>';
            gndxEnableReplacement   = '<apply>true</apply>';
            gndyEnableKeyWord       = '<apply>gndy_enable</apply>';
            gndyEnableReplacement   = '<apply>true</apply>';
            gndzEnableKeyWord       = '<apply>gndz_enable</apply>';
            gndzEnableReplacement   = '<apply>true</apply>';

            gndxValueKeyWord        = '<value>gndx_value';
            gndxValueReplacement    = ...
                sprintf('<value>%1.6f</value>',gndxyz(1,1));

            gndyValueKeyWord        = '<value>gndy_value';
            gndyValueReplacement    = ...
                sprintf('<value>%1.6f</value>',gndxyz(1,2));

            gndzValueKeyWord        = '<value>gndz_value';
            gndzValueReplacement    = ... 
                sprintf('<value>%1.6f</value>',gndxyz(1,3));

            findLinesWithThisKeyword = ...
                {timeRangeKeyWord;...
                 outputMotionFileKeyWord;...
                 gndxEnableKeyWord;...
                 gndyEnableKeyWord;...
                 gndzEnableKeyWord;...
                 gndxValueKeyWord;...
                 gndyValueKeyWord;...
                 gndzValueKeyWord;...
                 markerFileKeyWord};

            replacementLines = ...
                {timeRangeReplacement;...
                 outputMotionFileReplacement;...
                 gndxEnableReplacement;...
                 gndyEnableReplacement;...
                 gndzEnableReplacement;...
                 gndxValueReplacement;...
                 gndyValueReplacement;...
                 gndzValueReplacement;...
                 markerFileReplacement};


            ikSetupFileAllFrames = ikSetupFile;
            i=strfind(ikSetupFileAllFrames,'.xml');
            i=i-1;
            ikSetupFileAllFrames = [ikSetupFileAllFrames(1,1:i),...
                                    '_AllFrames.xml'];
           
            success = findReplaceLinesInFile(...
                        ikSetupFile,...
                        ikSetupFileAllFrames, ...
                        findLinesWithThisKeyword, ...
                        replacementLines );            

            %
            % Run the IKTool for all of the data
            %        
            cd(participantFolderPath);
            ikTool = InverseKinematicsTool(ikSetupFileAllFrames);
            ikTool.setModel(model);
            ikTool.set_report_marker_locations(true);
            ikTool.run();
            cd('..');       

            %
            % Copy the IK marker files over 
            %
            cd(participantFolderPath);
            markerErrorsSto = trcFile;
            i = strfind(markerErrorsSto,'.trc');
            i=i-1;
            markerErrorsSto = [markerErrorsSto(1:i),...
                              '_ik_marker_errors.sto'];
            markerLocationsSto = [markerErrorsSto(1:i),...
                                 '_ik_model_marker_locations.sto'];
            movefile('_ik_marker_errors.sto',...
                ['ik_markers',filesep,markerErrorsSto]);

            movefile('_ik_model_marker_locations.sto',...
                ['ik_markers',filesep,markerLocationsSto]);

            cd('..');


            %
            % Load the model marker locations & the experimental marker
            % measurements
            %
        
            cd(participantFolderPath);
            ikMarkerFile    = ['ik_markers',filesep,markerLocationsSto];
            motMarkerData   = Storage(ikMarkerFile);
            motColLabels = motMarkerData.getColumnLabels;
            nLabels = motColLabels.size();
            
            dt      = 1/double(trcMetaData.OrigDataRate);
            nFrames = double(trcMetaData.NumFrames);
            trcTime = ([1:1:nFrames]').*dt;

            trcDataScaling = 1;
            if(strfind(trcMetaData.Units,'mm')==1)
                trcDataScaling=0.001;
            end

            for i=1:1:length(trcMarkerData)

                %Get the trc marker location
                markerName = trcMarkerData(i).markerName;

                %Extract time,x,y,z data from the model
                coordEndings ={'_tx','_ty','_tz'};
                coordValues = [];
                for j=0:1:3
                    coordNameTarget='time';
                    if(j>=1)
                        coordNameTarget = [markerName,coordEndings{j}];
                    end
                    modelMarkerLocation = ArrayDouble();
                    z=0;
                    found=0;
                    
                    while(found==0 && z < (nLabels-1))
                        coordName    = motColLabels.get(z);
                        if(strfind(coordNameTarget,coordName)==1)
                            if(strfind(coordNameTarget,'time')==1)
                                motMarkerData.getTimeColumn(modelMarkerLocation);
                            else
                                motMarkerData.getDataColumn(coordName,...
                                                            modelMarkerLocation);
                            end
                            found=1;
                        end
                        z=z+1;
                    end
                    vec=[];
                    nItems=modelMarkerLocation.size()-1;
                    for z=0:1:nItems
                        vec=[vec(:);modelMarkerLocation.get(z)];
                    end
                    coordValues = [coordValues, vec];
                end
                
                %Evaluate the error between the TRC and model markers
                %at the points in time from the IK solution

                markerError = zeros(size(coordValues,1),1);

                for j=1:1:size(coordValues,1)
                    t       = coordValues(j,1);
                    ikXYZ   = interp1(coordValues(:,1),...
                                      coordValues(:,2:4),t);
                    expXYZ  = interp1(trcTime,trcMarkerData(i).r0M0,t);
                    expXYZ = expXYZ.*trcDataScaling;
                    rXYZ = ikXYZ-expXYZ;
                    markerError(j,1) = sqrt(sum(rXYZ.^2));
                end

                
                disp('You are here');
                % To dos
                % 1. Make a table that has time, error1, ...
                % 2. Make a header that has time, markerName1,...
                % 3. Write a csv file of marker errors
                % 4. Make a box-and-whisker plot of all of the
                %    marker errors. Put names on the plot + IK weight
               
            end

            cd('..');
            % The TRC was already loaded
            % [trcMetaData, trcFrameTime, trcMarkerData]


        end
        		
    end


end
cd(codeDir);
