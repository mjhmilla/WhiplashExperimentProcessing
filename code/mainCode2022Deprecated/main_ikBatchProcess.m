
% Pull in the modeling classes straight from the OpenSim distribution
import org.opensim.modeling.*

% move to directory where this subject's files are kept
subjectDir = uigetdir('testData', 'Select the folder that contains the current subject data');

% Go to the folder in the subject's folder where .trc files are
trc_data_folder = uigetdir(subjectDir, 'Select the folder that contains the marker data files in .trc format.');

% specify where results will be printed.
results_folder = uigetdir(subjectDir, 'Select the folder where the IK Results will be printed.');

% Choose a generic setup file to work from
[genericSetupForIK,genericSetupPath,~] = ...
    uigetfile([subjectDir,'/*.xml'],'Pick the a generic setup file to for this subject/model as a basis for changes.');

ikTool = InverseKinematicsTool([genericSetupPath genericSetupForIK]);

% Get the model
[modelFile,modelFilePath,FilterIndex] = ...
    uigetfile([subjectDir,'/*.osim'],'Pick the the model file to be used.');

% Load the model and initialize
model = Model(fullfile(modelFilePath, modelFile));
initState=model.initSystem();

slashChar = '\';
idxSlash = strfind(results_folder,slashChar);
subjectNumber=results_folder(1,idxSlash(end-1)+1:idxSlash(end)-1);

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

accuracy= ikTool.get_accuracy();
accuracy= accuracy/10;
ikTool.set_accuracy(accuracy);




trialsForIK = dir(fullfile(trc_data_folder, '*.trc'));

nTrials = size(trialsForIK);
%%

% Loop through the trials
for trial= 1:nTrials
%     nTrials


    % Get the name of the file for this trial
    markerFile = trialsForIK(trial).name;

    % Create name of trial from .trc file name
    name = regexprep(markerFile,'.trc','');
    fullpath = fullfile(trc_data_folder, markerFile);

    trc_data = osimTableToStruct(TimeSeriesTableVec3(fullpath));

    % Get trc data to determine time range
    markerData = MarkerData(fullpath);

    ik_result_file_first_frame= fullfile(results_folder, [name '_ik_first_frame.mot']);
    ik_result_file= fullfile(results_folder, [name '_ik.mot']);

 %% ------------------ IK for first frame---------------- %%

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



    fprintf(['Performing IK (first frame) on cycle # ' num2str(trial) '\n']);

    % Define Output Name
    ikTool.setOutputMotionFileName(ik_result_file_first_frame);

    % Run first IK
    ikTool.run();

 %% ------ Loading the results from the first IK step--------%%
    spine_file= fullfile(results_folder, [name '_ik_first_frame.mot']);
    spine_coordinates = osimTableToStruct(TimeSeriesTable(spine_file));

%% ------- Place the model to ik-result from first frame-----%%
    model.updCoordinateSet().get('gndx').setDefaultValue(spine_coordinates.gndx);
    model.updCoordinateSet().get('gndy').setDefaultValue(spine_coordinates.gndy);
    model.updCoordinateSet().get('gndz').setDefaultValue(spine_coordinates.gndz);

 %% ---------------- Changing the Coordinates--------------- %%
    model.updCoordinateSet().get('gndpitch').setDefaultLocked(false);
    model.updCoordinateSet().get('gndx').setDefaultLocked(true);
    model.updCoordinateSet().get('gndy').setDefaultLocked(true);
    model.updCoordinateSet().get('gndz').setDefaultLocked(true);

 %% ------------------ IK for whole remaining trial ---------------- %%

    % Get initial and final time
    initial_time = markerData.getStartFrameTime();
    final_time = markerData.getLastFrameTime();
    ikTool.setStartTime(initial_time);
    ikTool.setEndTime(final_time);

    ikTool.setResultsDir(results_folder)
    ikTool.set_report_marker_locations(true);
    ikTool.set_report_errors(false);

    % Define Output Name
    ikTool.setOutputMotionFileName(ik_result_file);

    % Save the settings in a setup file
    outfile = ['Setup_IK_' name '.xml'];
    ikTool.print(fullfile(genericSetupPath, outfile));

    fprintf(['Performing remaining IK on cycle # ' num2str(trial) '\n']);
    % Run second IK
    ikTool.run();

%     state = model.getWorkingState();
%     skull= model.getBodySet().get('skull');
%     skull_loc(1,:)= osimVec3ToArray(skull.getPositionInGround(state));

    % save files as .sto
    ik_marker_file = fullfile(results_folder, [name '_ik_model_marker_locations']);
    ik_marker_file_sto= strrep(ik_marker_file,'_marker_locations','_marker_locations.sto');
    copyfile(ik_marker_file, ik_marker_file_sto)
    delete(ik_marker_file);

    %% -------------- calculate marker error -------------%%
%     marker_locations= osimTableToStruct(TimeSeriesTable(ik_marker_file_sto));
%
%     t= (1:length(trc_data.SJN)).*0.005;
%
%     for marker=1:length(markerNames)
%
%
%        e_x= trc_data.(markerNames{marker})(:,1).*(1/10);
%        e_y= trc_data.(markerNames{marker})(:,2).*(1/10);
%        e_z= trc_data.(markerNames{marker})(:,3).*(1/10);
%
%        m_x= marker_locations.([markerNames{marker},'_tx']).*100;
%        m_y= marker_locations.([markerNames{marker},'_ty']).*100;
%        m_z= marker_locations.([markerNames{marker},'_tz']).*100;
%
%        error(trial).name= markerFile;
%        error(trial).(markerNames{marker})= sqrt(((e_x)-(m_x)).^2+((e_y)-(m_y)).^2+((e_z)-(m_z)).^2);
%
%     end

end

% cd(results_folder)
%
% % save([subjectNumber '_marker_error'],'error')

fprintf('COMPLETED \n');


