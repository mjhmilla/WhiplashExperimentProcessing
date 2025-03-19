%%
% @author: Jakob Vilsmeier, Matthew Millard
% @date: 1/3/2023 
%        22/6/2023
%
% To dos:
%   Clean up the code: pick descriptive names, consistently tab, choose
%   remove unused code, and add some comments when the name is not
%   sufficient.
%
% Description:
% This function will load each subject specific version of the Mortensen
% et al.'s OpenSim model and use the IK tool to solve for the generalized 
% coordinates of the model that most closely track the participants 
% data. This function will process the entire data set, which takes hours.
%
% https://simtk.org/projects/neckdynamics/
%
% Mortensen JD, Vasavada AN, Merryweather AS. The inclusion of hyoid muscles 
% improve moment generating capacity and dynamic simulations in musculoskeletal 
% models of the head and neck. PloS one. 2018 Jun 28;13(6):e0199912.
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

flag_useIKWithRegularizedPelvisMovement = 1;
flag_applyIKToSmallTimeWindow           = 1;

assert(flag_dataSet==0,'Error: Code has not yet been updated to work',...
    ' with the 2023 dataset, which includes a different marker layout.');

flag_runIKTool      = 1;
flag_runAnalyzeTool = 1;

runThisParticipant = [{'participant01'}];%[{'participant17'}];
runTheseTrials = [];%[2];

% Pull in the modeling classes straight from the OpenSim distribution
import org.opensim.modeling.*

% Check that we are starting in the correct directory
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
        dataDir   = fullfile(startDir,'data2022');
        opensimDir=fullfile(startDir,'opensim2022');
    case 1
        dataDir = fullfile(startDir,'data2023');        
        opensimDir=fullfile(startDir,'opensim2023');
        
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
   
    % Check to make sure that the participant data folder contains all necessary
    % folders
    flag_carFolder=0;
    flag_biopacFolder=0;
    flag_trcFolder=0;

    carDir=[dataDir,filesep,participantFolder,filesep,'car'];
    assert(exist(carDir,'dir')== 7,...
           sprintf('Error: this directory does not exist: %s',carDir));
    flag_carFolder=1;

    biopacDir=[carDir,filesep,'biopac'];
    assert(exist(biopacDir,'dir')== 7,...
           sprintf('Error: this directory does not exist: %s',biopacDir));
    flag_biopacFolder=1;

    trcDir=[carDir,filesep,'optitrack',filesep,'trc'];
    assert(exist(trcDir,'dir')== 7,...
           sprintf('Error: this directory does not exist: %s',trcDir));
    flag_trcFolder=1;
    
    % Check to make sure that the participant opensim folder contains all necessary
    % folders
     flag_analyzeFolder=0;
     flag_ikFolder=0;
     flag_postprocessingFolder=0;
    
     flag_osimFile=0;
     flag_ikSetupFile=0;
     flag_analyzeSetupFile=0;
    
     opensimDir=[startDir,filesep,'opensim2022',filesep,participantFolder];
    
    if exist([opensimDir,filesep,'analyze'],'dir')== 7
       flag_analyzeFolder=1;
       analyzeDir=[opensimDir,filesep,'analyze'];
       if exist([analyzeDir,filesep,'participant',idStr,'_Setup_Analyze.xml'],'file')== 2
           flag_analyzeSetupFile=1;
           genericSetupFileAnalyze=[participantFolder,'_Setup_Analyze.xml'];
           genericSetupPathAnalyze= [analyzeDir,filesep];
       end
    end
    if exist([opensimDir,filesep,'ik'],'dir')== 7
       flag_ikFolder=1;
       ikDir=[opensimDir,filesep,'ik'];
       if exist([ikDir,filesep,'ik_setup.xml'],'file')== 2
           flag_ikSetupFile=1;
           genericSetupFileIK='ik_setup.xml';
           genericSetupPathIK= [ikDir,filesep];
       end
    end
    if exist([opensimDir,filesep,'postprocessing'],'dir')== 7
       flag_postprocessingFolder=1;
       postprocessingDir=[opensimDir,filesep,'postprocessing'];
    end
    if exist([opensimDir,filesep,'subject',idStr,'_scaled.osim'],'file')== 2
       flag_osimFile=1;
       osimFile = ['subject',idStr,'_scaled.osim'];
       osimPath = [opensimDir,filesep];
    end
    
    
    assert(flag_analyzeFolder==1,...
        [participantFolder,' opensim folder: does not contain exactly one folder named "analyze"'])
    assert(flag_ikFolder==1,...
        [participantFolder,' opensim folder: does not contain exactly one folder named "ik"']);
    assert(flag_postprocessingFolder==1,...
        [participantFolder,' opensim folder: does not contain exactly one folder named "postprocessing"']);
    assert(flag_osimFile==1,...
        [participantFolder,' opensim folder: does not contain a file named "_scaled.osim"']);
    assert(flag_analyzeSetupFile==1,...
        [participantFolder,' opensim',filesep,'analyze folder: does not contain an analyze setup file']);
    assert(flag_ikSetupFile==1,...
        [participantFolder,' opensim',filesep,'ik folder: does not contain an ik setup file']);
    
    if(flag_runIKTool==1)
    
        fprintf('\t%s: \n','running IKTool');            
        ikTool = InverseKinematicsTool([genericSetupPathIK genericSetupFileIK]);
        
        % Load the model and initialize
        model = Model(fullfile(osimPath, osimFile));
        initState=model.initSystem();
        
        %  marker names
        markerNames = ...
          [{'RZP' },...
           {'RZF' },...
           {'GLA' },...
           {'LZF' },...
           {'LZP' },...
           {'RUN' },... %RUN: right upper neck
           {'LUN' },... %LUN: left upper neck
           {'HY'  },...  %HY: Hyoid
           {'RCAJ'},...
           {'SJN' },...
           {'LCAJ'},...
           {'RC'  },...
           {'LC'  },...
           {'LN'  },...
           {'RN'  }];
        
        % Tell Tool to use the loaded model
        ikTool.setModel(model);
        %methods(ikTool);
        % accuracy= ikTool.get_accuracy();
        % accuracy= accuracy/10;
        % ikTool.set_accuracy(accuracy);
        
        ikTrials = dir(fullfile(trcDir,'*.trc'));
        trialsTrc=ikTrials(find(cellfun(@isempty,regexp({ikTrials.name},'raw'))));
        numberOfTrcFiles = size(trialsTrc,1);
        
        if(isempty(runTheseTrials)==0)
            numberOfTrcFiles=length(runTheseTrials);
        end

        % Loop through the trials
        for trial= 1: numberOfTrcFiles
        %     ikTrialsN
            
            if(isempty(runTheseTrials)==0)
                markerFile = trialsTrc(runTheseTrials(1,trial)).name;
            else
                % Get the name of the file for this trial
                markerFile = trialsTrc(trial).name;

            end
            
        
            

            % Create name of trial from .trc file name
            name = regexprep(markerFile,'.trc','');
            fullpath = fullfile(trcDir, markerFile);
        
            % trc_data = osimTableToStruct(TimeSeriesTableVec3(fullpath));
        
            % Get trc data to determine time range
            markerData = MarkerData(fullpath);
            %methods(markerData);

            % Evaluate the acceleration of the GLA marker to get the time
            % just before and after the pulse to process
            idxGLA      = markerData.getMarkerIndex('GLA');
            numFrames   = markerData.getNumFrames();
            positionGLA = zeros(numFrames,3);
            timeGLA     = zeros(numFrames,1);
            dt =1/markerData.getDataRate();


            for idxFrame=1:1:(numFrames)
                markerFrame = markerData.getFrame(idxFrame-1);
                positionGLA(idxFrame,:)=osimVec3ToArray(markerFrame.getMarker(idxGLA));
                timeGLA(idxFrame,1)= dt*(idxFrame-1);
            end

            velocityGLA= zeros(numFrames,3);
            accelerationGLA= zeros(numFrames,3);
            
            for idxAxis=1:1:3
                velocityGLA(:,idxAxis) = calcCentralDifferenceDataSeries(timeGLA,positionGLA(:,idxAxis));
                accelerationGLA(:,idxAxis) = calcCentralDifferenceDataSeries(timeGLA,velocityGLA(:,idxAxis));
            end
            velocityNormGLA = (velocityGLA(:,1).^2 ...
                                + velocityGLA(:,2).^2 ...
                                + velocityGLA(:,3).^2).^0.5;

            [valMax, idxMax] = max(velocityNormGLA);
            idxStart = max(1, round(idxMax - (1.0/dt)));
            idxEnd   = min(numFrames,round(idxMax + (2.0/dt)));

            timeStart = (idxStart-1)*dt;
            timeEnd   = (idxEnd-1)*dt;

            flag_debug=0;
            if(flag_debug==1)
                figDebug=figure;
                subplot(3,1,1);
                    plot(timeGLA,positionGLA(:,1),'r');
                    hold on;
                    plot(timeGLA,positionGLA(:,2),'g');
                    hold on;
                    plot(timeGLA,positionGLA(:,3),'b');
                    hold on;
                    xlabel('Time (s)');
                    ylabel('Distance (mm)');
                    title('GLA Position');
                subplot(3,1,2);

                    t0=timeGLA(idxStart,1);
                    t1=timeGLA(idxEnd,1);
                    a0=0;
                    a1=valMax;

                    fill([t0,t1,t1,t0,t0],[a0,a0,a1,a1,a0],[1,1,1].*0.75);
                    hold on;


                    plot(timeGLA,velocityGLA(:,1),'r');
                    hold on;
                    plot(timeGLA,velocityGLA(:,2),'g');
                    hold on;
                    plot(timeGLA,velocityGLA(:,3),'b');
                    hold on;

                    plot(timeGLA,velocityNormGLA,'k');
                    hold on;

                    xlabel('Time (s)');
                    ylabel('Velocity (mm/s)');
                    title('GLA Velocity');                    
                subplot(3,1,3);

                    plot(timeGLA,accelerationGLA(:,1),'r');
                    hold on;
                    plot(timeGLA,accelerationGLA(:,2),'g');
                    hold on;
                    plot(timeGLA,accelerationGLA(:,3),'b');
                    hold on;
                   
                    xlabel('Time (s)');
                    ylabel('Acceleration (mm/s^2)');
                    title('GLA Acceleration');                    

            end
            
 


            %idxStart=markerFile.
            


            ikFirstFrame= fullfile(ikDir, [name '_ikFirstFrame.mot']);
            ikResults= fullfile(ikDir, [name '_ik.mot']);
        
            % fix gndpitch
            model.updCoordinateSet().get('gndpitch').setDefaultLocked(true);
            model.updCoordinateSet().get('gndx').setDefaultLocked(false);
            model.updCoordinateSet().get('gndy').setDefaultLocked(false);
            model.updCoordinateSet().get('gndz').setDefaultLocked(false);


            %first time frame
            first_frame= 0.005;
        
            % Setup the ikTool for this trial (only first time frame)
            ikTool.setName(name);
            ikTool.setMarkerDataFileName(fullpath);
            ikTool.setStartTime(first_frame);
            ikTool.setEndTime(first_frame);
            ikTool.set_report_errors(false);
        
            fprintf(['\t\tPerforming IK (first frame) on file "',markerFile,'"' '\n']);
        
            % Define Output Name
            ikTool.setOutputMotionFileName(ikFirstFrame);

            % Run first IK
            ikTool.run();
        
            % Loading the results from the first IK step
            firstFrameFile= fullfile(ikDir, [name '_ikFirstFrame.mot']);
            firstFrameCoord = osimTableToStruct(TimeSeriesTable(firstFrameFile));
        
            % Place the model to ik-result from first frame
            model.updCoordinateSet().get('gndx').setDefaultValue(firstFrameCoord.gndx);
            model.updCoordinateSet().get('gndy').setDefaultValue(firstFrameCoord.gndy);
            model.updCoordinateSet().get('gndz').setDefaultValue(firstFrameCoord.gndz);
            %model.updCoordinateSet().get('gndpitch').setDefaultValue(firstFrameCoord.gndpitch);
            %model.updCoordinateSet().get('gndroll').setDefaultValue(firstFrameCoord.gndroll);
            %model.updCoordinateSet().get('gndyaw').setDefaultValue(firstFrameCoord.gndyaw);


            % Changing the Coordinates Fixations
            model.updCoordinateSet().get('gndpitch').setDefaultLocked(false);
                        
            model.updCoordinateSet().get('gndx').setDefaultLocked(true);
            model.updCoordinateSet().get('gndy').setDefaultLocked(true);
            model.updCoordinateSet().get('gndz').setDefaultLocked(true);

            if(flag_useIKWithRegularizedPelvisMovement==1)
                model.updCoordinateSet().get('gndpitch').setDefaultLocked(false);
                model.updCoordinateSet().get('gndroll').setDefaultLocked(false);
                model.updCoordinateSet().get('gndyaw').setDefaultLocked(false);
                
                model.updCoordinateSet().get('gndx').setDefaultLocked(false);
                model.updCoordinateSet().get('gndy').setDefaultLocked(false);
                model.updCoordinateSet().get('gndz').setDefaultLocked(false);                
            end


        
            % IK for whole remaining trial 
            initial_time = markerData.getStartFrameTime();
            final_time = markerData.getLastFrameTime();
            if(flag_applyIKToSmallTimeWindow==1)
                initial_time=timeStart;
                final_time=timeEnd;
            end


            ikTool.setStartTime(initial_time);
            ikTool.setEndTime(final_time);
        
            ikTool.setResultsDir(ikDir)
            ikTool.set_report_marker_locations(true);
            ikTool.set_report_errors(false);
        
            % Define Output Name
            ikTool.setOutputMotionFileName(ikResults);
        
            %     % Save the settings in a setup file
            %     outfile = ['Setup_IK_' name '.xml'];
            %     ikTool.print(fullfile(genericSetupPath, outfile));
        
            fprintf(['\t\tPerforming remaining IK on file "',markerFile,'"' '\n']);
            % Run second IK
            ikTool.run();
        
            % save files as .sto
            ikMarker = fullfile(ikDir, [name '_ik_model_marker_locations']);
            ikMarkerSto= strrep(ikMarker,'_ik_model_marker_locations','_ikModelMarker.sto');
            copyfile(ikMarker, ikMarkerSto)
            delete(ikMarker);

            here=1;
        
        end
        

    end

    if(flag_runAnalyzeTool==1)
        fprintf('\t%s: \n','running AnalyzeTool');            
        % Analyze Step
        analyzeTool = AnalyzeTool([genericSetupPathAnalyze genericSetupFileAnalyze]);        
        analyzeTrials = dir(fullfile(ikDir, '*_ik.mot'));
        numberOfMotFiles =length(analyzeTrials);
        
        for trial= 1:numberOfMotFiles
            
            % get the name of the file for this trial
            motIKCoordsFile = analyzeTrials(trial).name;
            
            % create name of trial from .trc file name
            name = regexprep(motIKCoordsFile,'_ik.mot','');
            
            % get .mot data to determine time range
            motCoordsData = Storage(fullfile(ikDir, motIKCoordsFile));
            
            initial_time = motCoordsData.getFirstTime();
            final_time = motCoordsData.getLastTime();
                    
            analyzeTool.setName(name);
            analyzeTool.setResultsDir(analyzeDir);
            analyzeTool.setCoordinatesFileName(fullfile(ikDir, motIKCoordsFile));
            analyzeTool.setInitialTime(initial_time);
            analyzeTool.setFinalTime(final_time);   
            
            fprintf(['\t\tPerforming Analyze on file "',name,'"' '\n']);
            analyzeTool.run();
            
        end
        
        % saving relevant files as .sto
        names= [{'_FiberLength'},{'_Length'}];
            
        for j= 1:2        
            relevant_files= dir(fullfile(analyzeDir, ['*',names{j}]));        
            for i=1:length(relevant_files)            
                file= [relevant_files(i).folder,filesep,relevant_files(i).name];
                fileSto= strrep(file,names{j},[names{j},'.sto']);
                copyfile( file, fileSto)
                delete(file);    
            end 
        end
        
    end
end
cd(codeDir);
