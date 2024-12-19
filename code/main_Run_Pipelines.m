% 0: 2022 data set
% 1: 2023 data set



flag_outerLoopMode= 1;

%%
%2022 dataset
%%
flag_dataSet = 0;
%main_EMG_00_calculateEMGNormalization;
%main_EMG_01_emgBatchProcess;
%main_EMG_02_emgComparison;
%main_OpenSim_00_PreprocessOptitrackData;
main_OpenSim_01_RunTools;
%main_OpenSim_02_IKPostprocess;            
%main_OpenSim_03_CompareKinematics;

%%
%2023 dataset
%%
flag_dataSet = 1;
%main_EMG_00_calculateEMGNormalization;
%main_EMG_01_emgBatchProcess;
%main_EMG_02_emgComparison;
%main_OpenSim_00_PreprocessOptitrackData;
