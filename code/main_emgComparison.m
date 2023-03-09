%%main_emgComparison
clc;
close all;
clear all;

%Notes to improve participantEmgData
% 1. Get rid of the first 2 elements
% 2. Change flag_ignoreTrial to flag_useTrial

% 0: 2022 data set
% 1: 2023 data set
flag_dataSet    = 1;
participantFirst= 1;
participantLast = 28;

percentileSet       = [0.05;0.25;0.5;0.75;0.95];

%Input
noDataNumber = -1;
firstMuscleBiopacIndex=1;
lastMuscleBiopacIndex=6;
numberOfMuscles = lastMuscleBiopacIndex-firstMuscleBiopacIndex+1;
                    
numberOfConditions = 2;
conditionsToCompare(numberOfConditions) ...
    = struct('condition','',... 
             'carDirection','',...
             'columnNames',      [],... 
             'times',            [],...
             'magnitudes',       [],...
             'participantIndex',[],...
             'trialIndex',      [],...
             'fileName'  ,      []);

conditionsToCompare(1).condition='nominal';
conditionsToCompare(1).carDirection='Forward';

conditionsToCompare(2).condition='seatBack';
conditionsToCompare(2).carDirection='Forward';

% conditionsToCompare(1).condition='nominal';
% conditionsToCompare(1).direction='Forward';

% conditionsToCompare(2).condition='nominal';
% conditionsToCompare(2).direction='Backward';
% 
% conditionsToCompare(3).condition='nominal';
% conditionsToCompare(3).direction='Left';
% 
% conditionsToCompare(4).condition='nominal';
% conditionsToCompare(4).direction='Right';

% conditionsToCompare(5).condition='seatBack';
% conditionsToCompare(5).direction='Forward';
% 
% conditionsToCompare(6).condition='seatBack';
% conditionsToCompare(6).direction='Backward';
% 
% conditionsToCompare(7).condition='seatBack';
% conditionsToCompare(7).direction='Left';
% 
% conditionsToCompare(8).condition='seatBack';
% conditionsToCompare(8).direction='Right';

%Local folders
addpath('inputOutput');

%Check that Matlab is currently in the code directory
localPath=pwd();
[parentFolderPath,parentFolder] = fileparts(localPath);

assert(contains(parentFolder,'code'));
assert(contains(parentFolderPath,'WhiplashExperimentProcessing'));

whiplashFolder= parentFolderPath;
codeFolder=localPath;

switch(flag_dataSet)
	case 0
		dataSetFolder = fullfile(whiplashFolder,'data2022');
		outputSetFolder=fullfile(whiplashFolder,'output2022');        
		numberOfParticipants=21;

	case 1
		dataSetFolder = fullfile(whiplashFolder,'data2023');
		outputSetFolder=fullfile(whiplashFolder,'output2023');
		numberOfParticipants=28;    
		disp('Important: the TRU_L and TRU_R are really SCP_L and SCP_R');
        disp('Important: the head accelerometer was never attached to the head. (Matts fault)');
		
	otherwise
		assert(0,'Error: flag_dataSet must be 0 or 1');
end



%% load the data from emgPipelineOutput_participantXX

dataParticipantConditions=compareConditions(participantFirst,participantLast,dataSetFolder,...
    outputSetFolder,conditionsToCompare,firstMuscleBiopacIndex,...
    lastMuscleBiopacIndex,numberOfMuscles,noDataNumber);

here=1;


%% create struct/array for plot
%should include all trials for all participants and muscles for one
%condition



%%
%Build a plot that contains a box-whisker illustration for each 
%condition

%Perform a Wilcoxon ranksum test to test the probability that the two
%distributions are the same.
