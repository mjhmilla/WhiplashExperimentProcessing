%%
% @author: Jakob Vilsmeier
% @date: 1/3/2023 
%
% Description
% This function will evaluate the kinematics of the head and the muscles 
% and will compare male and female participants to see if the groups
% differ in their responses to acceleration. To evaluate these kinematic
% quantities this function makes use of the output from OpenSim's iktool
% and analyzetool (currently evaluated in main_runOpenSimTools.m)
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
assert(flag_dataSet==0,'Error: Code has not yet been updated to work',...
    ' with the 2023 dataset, which includes a different marker layout.');

%Offsets to mark the 
% indexMovementStartOffset: index before the movement
% indexMovementEndOffset  : index after the movement
indexMovementStartOffset    = 200;
indexMovementEndOffset      = 400;

% Pull in the modeling classes straight from the OpenSim distribution
import org.opensim.modeling.*

% Check that we are starting in the correct directory
currentDirContents= dir;
currentDirectory = pwd; 

assert(contains( currentDirContents(1).folder(1,(end-5):1:end),[filesep,'code'])==1,...
       ['Error: script must be started in the code directory']);

addpath('algorithms/');
addpath('inputOutput/');

codeDir = currentDirContents(1).folder;
cd ..;
startDir= pwd; 
switch flag_dataSet
    case 0
        dataDir   = fullfile(startDir,'data2022');
        opensimDir= fullfile(startDir,'opensim2022');
        outputDir = fullfile(startDir,'output2022');
    case 1
        dataDir = fullfile(startDir,'data2023');        
        opensimDir=fullfile(startDir,'opensim2023');
        outputDir = fullfile(startDir,'output2023');
        
    otherwise assert(0,'Error: unknown dataset');
end

skipTheseFolders = {'participant21_presentation'};

cd(opensimDir);
dataDirContents = dir;
participantFolderList = [];
for i=1:1:length(dataDirContents)



    flag_ignoreFolder=0;
    for indexIgnore = 1:1:length(skipTheseFolders)
        if(contains(dataDirContents(i).name,skipTheseFolders{indexIgnore}))
            flag_ignoreFolder=1;
        end
    end

    if(dataDirContents(i).isdir==1 && ...
       contains(dataDirContents(i).name,'participant') && flag_ignoreFolder==0)
       participantFolderList = ...
           [participantFolderList;...
            {dataDirContents(i).name} ];
           disp(dataDirContents(i).name);
    end
end

participantDirContents = dir;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% measurement frequency [Hz]
samplingFrequencyHz=200;

% detect_on = 1 -> strains and errors will be investigated in time range from acceleration onset to offset 
% dettect_on_off= 0 -> strains and errors will be investigated in specific detection window 
detect_on_off=0; 
      
% detection window after impact [s]
detection_window= 2; 
% % 
% % order of cases (A or B)
% % trial_case= [{'A'},{'A'},{'B'},{'B'},{'A'},{'A'},{'B'},{'A'},{'A'},...
% %              {'A'},{'B'},{'B'},{'A'},{'A'},{'A'},{'B'},{'B'},{'B'}];
% % 
% % order of sex : 1 for men, 0 for women
% % sex=[1 1 0 1 0 1 1 0 1 0 0 0 1 0 0 1 1 0];

% marker names
markerNames = ...
  [{'RZP' },...
   {'RZF' },...
   {'GLA' },...
   {'LZF' },...
   {'LZP' },...
   {'RUN' },...  
   {'LUN' },...  
   {'HY'  },...  
   {'RCAJ'},...
   {'SJN' },...
   {'LCAJ'},...
   {'RC'  },...
   {'LC'  },...
   {'LN'  },...
   {'RN'  }];

nummark= length(markerNames);

%MM: This comment is not clear enough.
% define which actuator should be summarized into one muscle, each muscle
% is one row in the matrix, fill the rest with nan
actuators_idx= [1 2 nan nan; ...
                3 nan nan nan; ...
                4 5 nan nan; ...
                6 7 nan nan; ...
                8 nan nan nan; ...
                9 nan nan nan; ...
                10 nan nan nan; ...
                11 12 nan nan; ...
                13 nan nan nan; ...
                14 15 nan nan; ...
                16 17 nan nan; ...
                18 nan nan nan; ...
                19 nan nan nan; ...
                20 nan nan nan; ...
                21 23 25 nan; ...
                22 24 26 nan; ...
                27 29 31 nan; ...
                28 30 32 nan; ...
                33 35 37 39; ...
                34 36 38 40; ...
                41 43 nan nan; ...
                42 44 nan nan; ...
                45 47 49 nan; ...
                46 48 50 nan;  ...
                51 53 55 nan; ...
                52 54 56 nan; ...
                57 nan nan nan; ...
                58 nan nan nan; ...
                59 61 63 nan; ...
                60 62 64 nan;...
                65 67 nan nan; ...
                66 68 nan nan; ...
                69 71 nan nan; ...
                70 72 nan nan];

% number of muscle actuators
numact=72;

% define the names of the summarized muscles
muscles_names= [{'DIG R'},{'GEN R'},{'MYL R'},{'STYL R'},{'STH R'},{'STT R'},{'OMO R'},...
                   {'DIG L'},{'GEN L'},{'MYL L'},{'STYL L'},{'STH L'},{'STT L'},{'OMO L'},...
                   {'SCM R'},{'SCM L'},{'SCL R'},{'SCL L'},{'LG R'},{'LG L'},...
                   {'TRP R'},{'TRP L'},{'SPL R'},{'SPL L'},...
                   {'SEMI R'},{'SEMI L'},...
                   {'LevScap R'},{'LevScap L'},{'ERSP R'},{'ERSP  L'},...
                   {'RecCap R'},{'RecCap L'},{'OblCap R'},{'OblCap L'}]';
%number of muscles
nummuscle= length(muscles_names);

% number of mucles != number of rows in actuator-matrix
assert(nummuscle==length(actuators_idx))

% name of acceleration directions
directions_name=[{'forward'},{'backward'},{'right'},{'left'}];
numdirec= length(directions_name);

coordinate_names=[{'gndpitch'},{'gndroll'},{'gndyaw'},{'pitch2'},{'roll2'},{'yaw2'},{'pitch1'},{'roll1'},{'yaw1'}];
numcoord= length(coordinate_names);

% p value for wilcoxon test
p_value= 0.05;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loading the data of all participants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


strain_all= struct([]);
coordinates_all=struct([]);
model_marker_all=struct([]);
raw_marker_all=struct([]);


for indexParticipant = 1:1:length(participantFolderList)

    
    disp(['Processing: ', participantFolderList{indexParticipant}]);
    participantFolder = participantFolderList{indexParticipant};
    idStr= participantFolder(1,end-1:end);

    sub{indexParticipant}.number=participantFolder;
    sub{indexParticipant}.idStr= str2num(idStr); 
    
    participantData=...
         getParticipantDataMay2022(str2num(idStr));
    sub{indexParticipant}.sex=participantData.sex;
    
    switch participantData.sex
        case 'm'
            sex(indexParticipant)=1;
        otherwise
            sex(indexParticipant)=0;
    end
  
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
%     flag_analyzeFolder=0;
%     flag_ikFolder=0;
%     flag_postprocessingFolder=0;
% 
%     flag_osimFile=0;
%     flag_ikSetupFile=0;
%     flag_analyzeSetupFile=0;
%  
% 
%     analyzeDir=[opensimDir,filesep,participantFolder,filesep,'analyze'];
%     assert(exist(analyzeDir,'dir')== 7,...
%           sprintf('Error: this directory does not exist: %s',analyzeDir))
%     flag_analyzeFolder=1;
%         
%     genericSetupFileAnalyze=[participantFolder,'_Setup_Analyze.xml'];
%     genericSetupPathAnalyze= [analyzeDir,filesep];
%     assert(exist(genericSetupFileAnalyze,'file')==2,... 
%            sprintf('Error: this file does not exist: %s',genericSetupFileAnalyze));
%     flag_analyzeSetupFile=1;
%     
%     ikDir=[participantFolder,filesep,'ik'];
%     assert(exist([participantFolder,filesep,'ik'],'dir')== 7,...
%            sprintf('Error: this folder does not exist: %s',ikDir));
%     flag_ikFolder=1;
% 
% 
%     genericSetupFileIK=[ikDir,filesep,'ik_setup.xml'];
%     assert(exist(genericSetupFileIK,'file')== 2,...
%            sprintf('Error: this file does not exist: %s',genericSetupFileIK));
%     flag_ikSetupFile=1;
% 
%     postprocessingDir=[participantDir,filesep,'postprocessing']
%     assert( exist([participantDir,filesep,'postprocessing'],'dir')== 7,...
%             sprintf('Error: this folder does not exist: %s',postprocessingDir))
%     flag_postprocessingFolder=1;
   osimFile = ['subject',idStr,'_scaled.osim'];
   osimPath = [opensimDir,filesep,participantFolder,filesep,osimFile];

   assert( exist(osimPath,'file')== 2,...
           sprintf('Error: this file does not exist: %s',osimFile));
   flag_osimFile=1;
    
   % get participant data
   participantCarData=getParticipantCarDataMay2022(str2num(idStr));

   blockFiles{indexParticipant}=participantCarData.blockFileNumbers(2,:);
   block{indexParticipant}=participantCarData.block;
   fileNumbers{indexParticipant}=participantCarData.ignoreTheseOptitrackFileNumbers;
    
   cd(codeDir)                
   results=postCalculations(codeDir,dataDir,opensimDir,outputDir,...
                  osimPath,indexMovementStartOffset,indexMovementEndOffset,idStr,filesep);
   assert(numact==length(results(1).strain_fiber));
        
   strain_all(indexParticipant).name= participantFolder ;
   strain_all(indexParticipant).values= results; 

%         % load model marker
%         model_marker_files= dir(fullfile(ikDir,'*.sto'));        
%         model_marker_all(indexParticipant).name=  participantFolder ;
%         for i= 1:length(model_marker_files)
%             model_marker_all(indexParticipant).values(i)= osimTableToStruct(TimeSeriesTable(fullfile(model_marker_files(i).folder,model_marker_files(i).name)));
%         end

    % load raw marker
    raw_marker_files= dir(fullfile(trcDir,'*raw.trc'));        
    raw_marker_all(indexParticipant).name=  participantFolder ;
    for i2= 1:length(raw_marker_files)
        raw_marker_all(indexParticipant).values(i2)= ...
            osimTableToStruct(...
            TimeSeriesTableVec3(fullfile(raw_marker_files(i2).folder,...
                                         raw_marker_files(i2).name)));
    end

%         % load coordinate data
%         coordinate_files= dir(fullfile(ikDir,'*ik.mot'));        
%         coordinates_all(indexParticipant).name= participantFolder ;
%         for i3= 1:length(coordinate_files)
%             coordinates_all(indexParticipant).values(i3)= osimTableToStruct(TimeSeriesTable(fullfile( coordinate_files(i3).folder, coordinate_files(i3).name)));
%             for raddeg= 4:9 
%                     coordinates_all(indexParticipant).values(i3).(coordinate_names{raddeg})=rad2deg(coordinates_all(indexParticipant).values(i3).(coordinate_names{raddeg}));
%             end
%         end


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Bunch all of the data together
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cd(dir_code);

for subject= 1:length(participantFolderList)

    %  marker error calculation
    error_all(subject).name= sub{subject}.number; 
    error_all(subject).value=calc_error(model_marker_all(subject).values,raw_marker_all(subject).values,markerNames);
    
        switch  block{subject}
            case 'A'
                forward= [3 8 12]; 
                backward= [4 5 10]; 
                right= [1 7 11]; 
                left= [2 6 9]; 
                disp([subjects{subject},' had case A'])
            case 'B'
                forward= [5 6 9]; 
                backward= [3 4 8]; 
                right= [1 10 12]; 
                left= [2 7 11]; 
                disp([subjects{subject},' had case B'])
        end
    
    
    % ignore the error trials 
            for w= 1:numdirec
                numidx= [1 2 3];

                    directions{1}=forward; 
                    directions{2}=backward; 
                    directions{3}=right; 
                    directions{4}=left; 

      if isempty(fileNumbers{subject})==0
          % [val,pos]=intersect(participantCarData.ignoreTheseOptitrackFileNumbers,directions{w}); 
          [tf, loc] = ismember(fileNumbers{subject},directions{w});
          if isempty(tf) ==0
              directions{w}(loc)=[]; 
              numidx((4-length(tf)):end)= [];
          end
      end

               
%           switch subjects{subject}
%         
%                     case 'participant12'
%                             forward=[3 12];
%                             if w==1 
%                                 numidx=[1 2];
%                             end
%                     case 'participant13'
%                             forward=[5 6];
%                             if w==1 
%                                 numidx=[1 2];
%                             end                        
%                     case 'participant14'
%                             backward=[4 8];
%                             if w==2
%                                 numidx=[1 2];
%                             end                        
%                     case 'participant19'
%                             backward=[3 4];
%                             if w==2 
%                                 numidx=[1 2];
%                             end                        
%                 end
%       end 
           
                max_error=[]; max_strain=[]; strains={}; displ={}; displ_max=[]; time_strain=[]; coord_cell=[]; displ_time=[];
                model_marker_vec={}; raw_marker_vec={}; max_coord=[]; time_max_coord=[]; min_coord=[]; time_min_coord=[];

               %-------------Marker Positinons Bunching-------------%

                for f= 1:nummark

                     max_error_marker(f).name= markerNames{f};
                     raw_marker_ts(f).name= markerNames{f};
                     model_marker_ts(f).name= markerNames{f};

                     for p1= numidx

                         reference_window= strain_all(subject).values(directions{w}(p1)).reference_idx;
                                        
                        if detect_on_off==1
                            wind= strain_all(subject).values(directions{w}(p1)).onset:strain_all(subject).values(directions{w}(p1)).offset;
                        elseif detect_on_off== 0
                            wind= strain_all(subject).values(directions{w}(p1)).onset:strain_all(subject).values(directions{w}(p1)).onset+(detection_window*samplingFrequencyHz-1);
                        end  
                            model_marker_vec{p1,1}=(model_marker_all(subject).values(directions{w}(p1)).([markerNames{f},'_tx'])...
                                                   -mean(model_marker_all(subject).values(directions{w}(p1)).([markerNames{f},'_tx'])(reference_window))).*100;
                            model_marker_vec{p1,2}=(model_marker_all(subject).values(directions{w}(p1)).([markerNames{f},'_ty'])...
                                                   -mean(model_marker_all(subject).values(directions{w}(p1)).([markerNames{f},'_ty'])(reference_window))).*100;
                            model_marker_vec{p1,3}=(model_marker_all(subject).values(directions{w}(p1)).([markerNames{f},'_tz'])...
                                                   -mean(model_marker_all(subject).values(directions{w}(p1)).([markerNames{f},'_tz'])(reference_window))).*100;
                            raw_marker_vec{p1,1}=(raw_marker_all(subject).values(directions{w}(p1)).(markerNames{f})(:,1)...
                                                   -mean(raw_marker_all(subject).values(directions{w}(p1)).(markerNames{f})(reference_window,1)))./10;
                            raw_marker_vec{p1,2}=(raw_marker_all(subject).values(directions{w}(p1)).(markerNames{f})(:,2)...
                                                   -mean(raw_marker_all(subject).values(directions{w}(p1)).(markerNames{f})(reference_window,2)))./10;
                            raw_marker_vec{p1,3}=(raw_marker_all(subject).values(directions{w}(p1)).(markerNames{f})(:,3)...
                                                   -mean(raw_marker_all(subject).values(directions{w}(p1)).(markerNames{f})(reference_window,3)))./10;
                            max_error(p1,:)= max(error_all(subject).value(directions{w}(p1)).(markerNames{f})(wind));
                     end
                     
                     max_error_marker(f).(directions_name{w})=max_error; 
                     raw_marker_ts(f).(directions_name{w})= raw_marker_vec;
                     model_marker_ts(f).(directions_name{w})= model_marker_vec;
                     
                end
    
                % -------Displacement Bunching----------%

                        for p2= numidx
                            displ{p2,1}=strain_all(subject).values(directions{w}(p2)).('displacement'){1,1}';
                            displ_max(p2,1)= strain_all(subject).values(directions{w}(p2)).('displacement'){1,2};
                            displ_time(p2,1)= strain_all(subject).values(directions{w}(p2)).('displacement'){1,3}./samplingFrequencyHz*1000;
                        end

                         displacement.(directions_name{w})=displ;                                               
                         max_displacement.(directions_name{w})=displ_max;
                         mean_max_displacement.(directions_name{w})=mean(displ_max);
                         time_displacement.(directions_name{w})=displ_time;

                 % -------Strain Bunching----------%
    
                for muscle= 1:numact
                        strain_actuator(muscle).name=strain_all(subject).values(1).strain_fiber{muscle,1};
                        max_strain_actuator(muscle).name=strain_all(subject).values(1).strain_fiber{muscle,1};
                        mean_max_strain_actuator(muscle).name=strain_all(subject).values(1).strain_fiber{muscle,1};
                        time_strain_actuator(muscle).name=strain_all(subject).values(1).strain_fiber{muscle,1};
                                               
                        for p2= numidx
                            strains{p2,1}=strain_all(subject).values(directions{w}(p2)).('strain_fiber'){muscle,2};
                            max_strain(p2,1)= strain_all(subject).values(directions{w}(p2)).('strain_fiber'){muscle,3};
                            time_strain(p2,1)= strain_all(subject).values(directions{w}(p2)).('strain_fiber'){muscle,4}./samplingFrequencyHz*1000;
                        end

                         strain_actuator(muscle).(directions_name{w})=strains;                                               
                         max_strain_actuator(muscle).(directions_name{w})=max_strain;
                         mean_max_strain_actuator(muscle).(directions_name{w})=mean(max_strain);
                         time_strain_actuator(muscle).(directions_name{w})=time_strain;
                         
                end

                 % -----------Coordinates Bunching-----------%

                for coord= 1:numcoord
                        coordinate(coord).name=coordinate_names{coord};
                        max_coordinate(coord).name=coordinate_names{coord};
                        min_coordinate(coord).name=coordinate_names{coord};
 
                        for p3= numidx
                            ref2= strain_all(subject).values(directions{w}(p3)).reference_idx;

                            if detect_on_off==1
                             wind2= strain_all(subject).values(directions{w}(p1)).onset:strain_all(subject).values(directions{w}(p1)).offset;
                            elseif detect_on_off== 0
                             wind2= strain_all(subject).values(directions{w}(p1)).onset:strain_all(subject).values(directions{w}(p1)).onset+(detection_window*samplingFrequencyHz-1);
                            end  

                            coord_cell{p3,1}= coordinates_all(subject).values(directions{w}(p3)).(coordinate_names{coord})...
                                              -mean(coordinates_all(subject).values(directions{w}(p3)).(coordinate_names{coord})(ref2));
                            [max_coord(p3,1),time_max_coord(p3,1)]= max(coord_cell{p3,1}(wind2));
                            [min_coord(p3,1),time_min_coord(p3,1)]= min(coord_cell{p3,1}(wind2));
                        end
                        
                        coordinate(coord).(directions_name{w})=coord_cell;
                        max_coordinate(coord).(directions_name{w})=max_coord;
                        min_coordinate(coord).(directions_name{w})=min_coord;

                end

            end
                            
            subjects(subject).name= subjects{subject};
            subjects(subjects).sex=sub{subject}.sex;
            subjects(subject).strain=   strain_actuator;
            subjects(subject).strain_max=   max_strain_actuator;
            subjects(subject).strain_max_mean=mean_max_strain_actuator;
            subjects(subject).strain_time=  time_strain_actuator;

         
            subjects(subject).displacement=   displacement;
            subjects(subject).displacement_max=   max_displacement;
            subjects(subject).displacement_max_mean=    mean_max_displacement;
            subjects(subject).displacement_time=   time_displacement;

            subjects(subject).max_error= max_error_marker;
            subjects(subject).raw_marker=   raw_marker_ts;
            subjects(subject).model_marker=model_marker_ts;

            subjects(subject).coordinates=coordinate;
            subjects(subject).max_coordinates=max_coordinate;
            subjects(subject).min_coordinates=min_coordinate;
end

% differ sex
female= subjects(find(~sex));
male= subjects(find(sex==1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate means of male /female / all participants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%-------------error mean of all subjects--------------%
[mean_error,~]= mean_of_subjects(subjects,'max_error',directions_name);
[m_mean_error_mean,m_mean_error]= mean_of_subjects(male,'max_error',directions_name);
[f_mean_error_mean,f_mean_error]= mean_of_subjects(female,'max_error',directions_name);

%-------------strain means of all men-----------------%
[m_actuator_strains_mean,m_actuator_strains] = mean_of_subjects(male,'strain_max',directions_name);
[m_actuator_times_mean,~] = mean_of_subjects(male,'strain_time',directions_name);

%-------------strain means of all women---------------%
[f_actuator_strains_mean,f_actuator_strains] = mean_of_subjects(female,'strain_max',directions_name);
[f_actuator_times_mean,~] = mean_of_subjects(female,'strain_time',directions_name);

%-------------displacement means of all men-----------------%
[m_displ_mean,m_displ] = mean_of_subjects(male,'displacement_max',directions_name);
[m_displ_times_mean,~] = mean_of_subjects(male,'displacement_time',directions_name);

%-------------displacement means of all women-----------------%
[f_displ_mean,f_displ] = mean_of_subjects(female,'displacement_max',directions_name);
[f_displ_times_mean,~] = mean_of_subjects(female,'displacement_time',directions_name);

%-------------angle means of all men-----------------%
[m_angle_max_mean,m_angle_max] = mean_of_subjects(male,'max_coordinates',directions_name);
[m_angle_min_mean,m_angle_min] = mean_of_subjects(male,'min_coordinates',directions_name);

%-------------angle means of all men-----------------%
[f_angle_max_mean,f_angle_max] = mean_of_subjects(female,'max_coordinates',directions_name);
[f_angle_min_mean,f_angle_min] = mean_of_subjects(female,'min_coordinates',directions_name);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%--------------------------------time series-------------------------------%%

%-------------coordinate means, std and raw data----------------%
% male coordinates
[m_coord_ts] = calc_time_series(male,'coordinates',directions_name);
% female coordinates
[f_coord_ts] = calc_time_series(female,'coordinates',directions_name);
% all subject coordinates
[coord_ts] = calc_time_series(subjects,'coordinates',directions_name);

% male displacement 
[m_displ_ts] = calc_time_series(male,'displacement',directions_name);
% female displacement 
[f_displ_ts] = calc_time_series(female,'displacement',directions_name);
% all subject displacement 
[displ_ts] = calc_time_series(subjects,'displacement',directions_name);

% male strain
[m_strain_ts] = calc_time_series(male,'strain',directions_name);
% female strain
[f_strain_ts] = calc_time_series(female,'strain',directions_name);

% raw marker
[raw_marker_all_subjects]=calc_time_series(subjects,'raw_marker',directions_name);

% model marker
[model_marker_all_subjects]=calc_time_series(subjects,'model_marker',directions_name);

%-------------------summarize actuators in muscles-------------------% 
[m_muscle_strains,m_muscle_strains_mean,m_muscle_time] = actuator_to_muscles(m_actuator_strains,m_actuator_strains_mean,m_actuator_times_mean,actuators_idx,muscles_names,directions_name);
[f_muscle_strains,f_muscle_strains_mean,f_muscle_time] = actuator_to_muscles(f_actuator_strains,f_actuator_strains_mean,f_actuator_times_mean,actuators_idx,muscles_names,directions_name);


%%%-----------------Wilcoxon test sex on max displacements-------------%
[p_sig_displ,p_displ] = wilcoxon(m_displ,f_displ,p_value,directions_name);

%%%-----------------Wilcoxon test sex on max actuator strains-------------%
[p_sig_strain,p_strain] = wilcoxon(m_actuator_strains,f_actuator_strains,p_value,directions_name);

%%%-----------------Wilcoxon test sex on max angle-------------%
[p_sig_angle_max,p_angle_max] = wilcoxon(m_angle_max,f_angle_max,p_value,directions_name);

%%%-----------------Wilcoxon test sex on min angle-------------%
[p_sig_angle_min,p_angle_min] = wilcoxon(m_angle_min,f_angle_min,p_value,directions_name);

%%%-----------------Wilcoxon test sex on marker error-------------%
[p_sig_error,p_error] = wilcoxon(m_mean_error,f_mean_error,p_value,directions_name);

%%------------------sort after muscle group----------------%%
 
groupnames= {'Hyoid','Ventral','Dorsal','Suboccipital','Lateral'}; 

%--------------------actuators--------------------------------%
hyoid_actuators_idx=1:20;
ventral_actuators_idx= [21:26 33:40]; 
dorsal_actuators_idx= 41:64;
suboccipital_actuators_idx=65:72;
lateral_actuators_idx= 21:32;

group_act_idx=[{hyoid_actuators_idx},{ventral_actuators_idx},{dorsal_actuators_idx},{suboccipital_actuators_idx},{lateral_actuators_idx}];

%---------------------muscles---------------------------------%
hyoid_muscles_idx= 1:14;
ventral_muscles_idx= [15:16 19:20]; 
dorsal_muscles_idx= 21:30;
subocc_muscles_idx= 31:34;
lateral_muscles_idx= 15:18;

group_mus_idx=[{hyoid_muscles_idx},{ventral_muscles_idx},{dorsal_muscles_idx},{subocc_muscles_idx},{lateral_muscles_idx}];

for group= 1:length(groupnames)
    m_actuator_groups.(groupnames{group})=m_actuator_strains_mean(group_act_idx{group});
    f_actuator_groups.(groupnames{group})=f_actuator_strains_mean(group_act_idx{group});

    m_muscle_groups.(groupnames{group})=m_muscle_strains_mean(group_mus_idx{group});
    f_muscle_groups.(groupnames{group})=f_muscle_strains_mean(group_mus_idx{group});
    
    muscle_group_names.(groupnames{group})= muscles_names(group_mus_idx{group});
end

cd(codeDir);
