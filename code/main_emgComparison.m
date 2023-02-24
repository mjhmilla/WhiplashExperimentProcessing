clc;
close all;
clear all;

%Input
numberOfConditions = 2;
conditionsToCompare(numberOfConditions) ...
    = struct('condition','',... 
             'direction','',...
             'time',[],...
             'magnitude',[]);


conditionsToCompare(1).condition='nominal';
conditionsToCompare(1).direction='forward';

conditionsToCompare(2).condition='seatBack';
conditionsToCompare(2).direction='forward';

%load the data from emgPipelineOutput_participantXX

%for loop over all of the trial files for a participantXX (indexTrial)
    %for loop over all of your conditions (indexCondition)
        %if the conditions of the trial match the conditions you're
        %interested in, then store the data
        %   conditionsToCompare(indexCondition).onsetTime = ...
        %       [conditionsToCompare(indexCondition).onsetTime;...
        %        newOnsetDataHere];
        %   conditionsToCompare(indexCondition).magnitude = ...
        %       [conditionsToCompare(indexCondition).magnitude;...
        %        magnitudeDataHere];
%
%
%

%Build a plot that contains a box-whisker illustration for each 
%condition

%Perform a Wilcoxon ranksum test to test the probability that the two
%distributions are the same.