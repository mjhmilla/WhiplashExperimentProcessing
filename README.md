# Description

This repository contains a series of scripts to process kinematic and electromyographic (EMG) data collected of the response of the head and neck to accelerations in the drivers seat of a (mechanically simulated) car. 


## Quick start
1. Download and unzip the participant data from the 2022 experiment into the folder 'data2022' in the git repository. The data is found here **add link to data**

Once all of the individual participant zip files have been unzipped the data2022 directory should have the following subfolders:

* calibration_participant01_participant04/
* calibration_participant05_participant09/
* calibration_participant10_participant15/
* calibration_participant16_participant21/
* participant01/
* participant02/
* participant03/
* participant04/
* participant05/
* participant06/
* participant07/
* participant08/
* participant09/
* participant10/
* participant11/
* participant12/
* participant13/
* participant14/
* participant15/
* participant16/
* participant17/
* participant18/
* participant19/
* participant20/
* participant21/
* protocol/
* domeSignalliste.xlsx


2. Download and unzip the participant data from the 2023 experiment into the folder 'data2023' in the git repository. The data is found here: **add link to data**

Once all of the individual participant zip files have been unzipped the data2023 directory should have the following subfolders :

* optiTrackCalibration_participant01_participant06/
* optiTrackCalibration_participant07_participant12/
* optiTrackCalibration_participant13_participant18/
* optiTrackCalibration_participant19_participant24/
* optiTrackCalibration_participant25_participant28/
* participant01/
* participant02/
* participant03/
* participant04/
* participant05/
* participant06/
* participant07/
* participant08/
* participant09/
* participant10/
* participant11/
* participant12/
* participant13/
* participant14/
* participant15/
* participant16/
* participant17/
* participant18/
* participant19/
* participant20/
* participant21/
* participant22/
* participant23/
* participant24/
* participant25/
* participant26/
* participant27/
* participant28/
* protocol/
* README.txt

3. Download an unzip the OpenSim files for each participant into the folder 'opensim2022' in the git repository. The data is found here: (update link).

Once all of the individual zip files have been unzipped the opensim2022 directory should have the following subfolders:

* models/
* participant01/
* participant02/
* participant03/
* participant04/
* participant05/
* participant06/
* participant08/
* participant10/
* participant11/
* participant12/
* participant13/
* participant14/
* participant16/
* participant17/
* participant18/
* participant19/
* participant20/
* participant21/

Where 'models' should have these files

* Generic_RT_new_joint_22_6dof_neck_markers_c5_pitch2_range.osim
* Geometry/
* IK_Setup.xml
* older_versions/
* Scale_Setup.xml
* subject01_generic.osim
* subject02_generic.osim
* subject03_generic.osim
* subject04_generic.osim
* subject05_generic.osim
* subject06_generic.osim
* subject08_generic.osim
* subject10_generic.osim
* subject11_generic.osim
* subject12_generic.osim
* subject13_generic.osim
* subject14_generic.osim
* subject16_generic.osim
* subject17_generic.osim
* subject18_generic.osim
* subject19_generic.osim
* subject20_generic.osim
* subject21_generic.osim
* Vasavada3DofNeckCoordinateCouplerConstraintCoefficients.ods

and each participant folder should have these contents:

* analyze/
* Geometry/
* ik/
* opensim.log
* participant_01_Scale_Setup.xml
* postprocessing/
* subject01_scaled.osim


4. Run the following scripts to test the EMG processing functionality
   1. main_calculateEMGNormalization.m (approximately 5 minutes)
   2. main_emgBatchProcess.m (3 minutes per participant). To run one participant set

      > flag_runOneParticipant          = 1;
      > runThisParticipant              = 1;
      
   If these scripts run without any errors then the installation is functioning.

5. Install OpenSim with Matlab scripting. As of March 2023 M.Millard has not been able to get OpenSim+Matlab scripting to function on Ubuntu 20.04, though others (Dr. Adam Kewley https://adamkewley.com/) have had success doing this. Instead M.Millard has just installed the OpenSim executable on a Windows machine which has a functioning Matlab scripting interface.

   https://opensimconfluence.atlassian.net/wiki/spaces/OpenSim/pages/53089819/Installation+Guide

6. Run the following script to test the kinematic processing using OpenSim:

   main_OpenSimRunTools. Before running this script change this variable near the start of the file (~line 50) from

   > runThisParticipant = [];%[{'participant17'}];

   to

   > runThisParticipant = [{'participant17'};

   otherwise you will be waiting for a very long time as OpenSim computes IK solutions for every trial in the dataset.



## Practical code notes

   All of the files that you can start running begin with the word 'main' and appear in the 'code/' directory. Configuration variables are placed near the beginning of the file, and efforts have been made to give variables meaningful names. However, the assumption of this code is that you will read it if you have questions. While there are notes in some files, there is not documentation.

### Coding conventions

* Files that can be directly run begin with 'main_'.
* Main files that should be run in a sequence (as part of a pipeline) are named 'main_TITLE_##'. For example, the EMG pipline is 'main_EMG_00_calculateEMGNormalization', 'main_EMG_01_emgBatchProcess', 'main_EMG_02_emgComparison' 
* The code directory contains 'main_' files as does 'spssPreprocessingScripts'.
* Function names begin with a verb and continue with a descrition of what the function does.
* Variable names have been chosen to be descriptive and self-documenting.

### Folder Layout

* algorithms/
* inputOutput/
* pergatory/
* spssPreprocessingScripts/


### Main function layout

* main_AccelerationHead2022.m
* mainCode2022Deprecated
* main_EMG_00_calculateEMGNormalization.m
* main_EMG_01_emgBatchProcess.m
* main_EMG_02_emgComparison.m
* main_extractCarAcceleration.m
* main_OpenSim_00_PreprocessOptitrackData.m
* main_OpenSim_01_RunTools.m
* main_OpenSim_02_IKPostprocess.m
* main_OpenSim_03_CompareKinematics.m


### Participant and experiment meta data

* inputOutput/getBiopacMetaData.m
* inputOutput/getParticipantCarDataFebruary2023.m
* inputOutput/getParticipantCarDataMay2022.m
* inputOutput/getParticipantDataFebruary2023.m
* inputOutput/getParticipantDataMay2022.m
* inputOutput/getParticipantFolders.m
* inputOutput/getParticipantMvcDataFebruary2023.m
* inputOutput/getParticipantMvcDataMay2022.m


### Important algorithms

* algorithms/findOnsetUsingNoiseModel.m
* algorithms/removeEcgFromEmg.m
* algorithms/normalizeEMGData.m
* algorithms/interpolateRigidBodyMotionAndMarkers.m



# Progress Notes


## Anonymization

This repository has had photos of the participants removed. These photos included photos of the Optitrack markers, and photos taken during the maximum voluntary contaction testing. These photos are necessary both to correctly place the markers on the model of the participant and to resolve the load cell measurements into joint torques. Unfortunately these photos cannot be (easily) made anonymous because the eyes and ears are used as landmarks for the digitization process. Instead these photos and the MVC data have been moved to a separate data repository that is kept private.

# Processing Progress

These functions have been tested and are working (and appear in main_Run_Pipelines.m):

* data2022 data set:
   1. main_EMG_00_calculateEMGNormalization
   2. main_EMG_01_emgBatchProcess
   3. main_OpenSim_00_PreprocessOptitrackData
   4. main_OpenSim_01_RunTools
   5. main_OpenSim_02_IKPostprocess  

* data2023 data set:
   1. main_EMG_00_calculateEMGNormalization
   2. main_EMG_01_emgBatchProcess

These functions are not working and/or need to be updated:

* data2022 data set:
   1. main_EMG_02_emgComparison
   2. main_OpenSim_03_CompareKinematics

* data2023 data set:
   1. main_EMG_02_emgComparison
   2. main_OpenSim_00_PreprocessOptitrackData
   3. main_OpenSim_01_RunTools
   4. main_OpenSim_02_IKPostprocess  

Please note that in the data2022 many of the EMG recordings have been moved into the 'other' folder (/data2022/participant02/car/biopac/other) and are currently being ignored. Many of these trials are free from problems but were not a part of earlier analysis done on the data. Very likely this data will be moved out of the 'other' folder so that it is once again included in the main analysis.

## Practical notes data2022 dataset

* Processing that has been completed
   * EMG: normalization and onset identification complete 
   * Kinematics: a first compete run of IK and muscle analysis has been completed
   * Kinematics: in the summer of 2023 a talented Hiwi student manually corrected a number of problematic Motive files. 
* Processing that is yet to do
   * EMG: some trials have some anomalies. Need to manually go through all the figures in participant01/car/biopac - participant21/car/biopac looking for the problem trials.   
   * Kinematics: the model needs to be updated to include either an articulared lumbar spine or a scapulothorasic joint. Why? The acromion markers fail to track the data during the lateral accelerations.
   * Kinematics: Most of the 'main_OpenSim ...' files need to be cleaned up.
   * The functions buildConditionDataTable, calcMeanHeadAccHead, getPercentiles, normalizeEmgEnvelope should be moved into folders
* Problems in the data set
   * Spatial arrangement of torso markers does not permit the tilt of the torso in the chair.

## Practical notes data2023 dataset

* Processing that has been completed
   * EMG: normalization and onset identification complete 
* Processing that is yet to do
   * EMG: manually inspect every trial as with data2022    
* Problems in the data set
   * Head accelerometer was not mounted. 
   * Some participants wore glasses and this essentially destroyed the Optitrack data.
   * The neck contained only 4 markers, which sometimes made it very difficult to correct marker mislabeling errors.
