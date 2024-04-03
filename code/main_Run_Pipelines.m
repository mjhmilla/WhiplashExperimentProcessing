% 0: 2022 data set
% 1: 2023 data set



flag_outerLoopMode= 1;

%%
%2022 dataset
%%
flag_dataSet = 0;
main_EMG_00_calculateEMGNormalization;
main_EMG_01_emgBatchProcess;

%Not working yet
%main_EMG_02_emgComparison;

main_OpenSim_00_PreprocessOptitrackData;
main_OpenSim_01_RunTools;
main_OpenSim_02_IKPostprocess;            

%Not working yet
%main_OpenSim_03_CompareKinematics;

%%
%2023 dataset
%%
flag_dataSet = 1;
main_EMG_00_calculateEMGNormalization;
main_EMG_01_emgBatchProcess;
%main_EMG_02_emgComparison;

%The OpenSim pipeline has not been set up for the 2023 data set yet. 
%To do this a scalable model needs to be made for each participant (this needs
%to be done manually) and then the pipeline can be run. After this the 
%solution for each IK solution needs to be visually inspected and problematic
%trials need to be fixed or removed.