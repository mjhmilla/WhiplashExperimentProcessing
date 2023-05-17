# Description

This repository contains a series of scripts to process kinematic and electromyographic (EMG) data collected of the response of the head and neck to accelerations in the drivers seat of a (mechanically simulated) car. 

Matthew Millard, May 2023

## Quick start
1. Download and unzip the participant data from the 2022 experiment into the folder 'data2022' in the git repository. The data is found here: https://bwsyncandshare.kit.edu/s/q7mxkXBtKaaFq3p

2. Download and unzip the participant data from the 2023 experiment into the folder 'data2023' in the git repository. The data is found here: https://bwsyncandshare.kit.edu/s/ypEEEXkLnNe7SfS

3. Run the following scripts to test the EMG processing functionality
   1. main_calculateEMGNormalization.m (approximately 5 minutes)
   2. main_emgBatchProcess.m (3 minutes per participant). To run one participant set

      > flag_runOneParticipant          = 1;
      > runThisParticipant              = 1;
      
   If these scripts run without any errors then the installation is functioning.

4. Run the following scripts to test the kinematic processing using OpenSim:


## Practical code notes

### Coding conventions

* Files that can be directly begin with 'main_'.
* Function names begin with a verb and continue with a descrition of what the function does.
* Variable names have been chosen to be descriptive and self documenting.

### Code directory layout

* algorithms
* inputOutput
* mainCode2022Deprecated
* pergatory
* spssPreprocessingScripts

* buildConditionDataTable.m
* calculateMeanAccHead.m
* getPercentiles.m
* main_AccelerationHead2022.m
* main_calculateEMGNormalization.m
* main_emgBatchProcess.m
* main_emgComparison.m
* main_extractCarAcceleration.m
* normalizeEmgEnvelope.m


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

## Practical notes data2022 dataset

* Processing that has been completed
* Processing that is yet to do
* Problems in the data set
   * Spatial arrangement of torso markers does not permit the tilt of the torso in the chair.

## Practical notes data2023 dataset

* Processing that has been completed
* Processing that is yet to do
* Problems in the data set
   * Head accelerometer was not mounted
   * Some participants wore glasses
   * The neck contained only 4 markers, which sometimes made it very difficult to correct marker mislabeling errors.

