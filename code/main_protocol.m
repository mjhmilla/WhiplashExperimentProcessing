clc;
close all;
clear all;

%Trial conditions
%nameConditions      = {'Fore','Back','Left','Right'};
nameConditions      = {'Yaw30 + Fore','Yaw30 + Back','Yaw30 + Left','Yaw30 + Right'};
numberOfConditions  = length(nameConditions);
numberOfRepetitions = 2;
numberOfTrials      = numberOfRepetitions*numberOfConditions;
accelerationTime    = 1;%s

%Time between trials
minTimeBetween      = 0.5;
maxTimeBetween      = 5;

%Randomized trial order
trials = [1:1:numberOfConditions]';
trialsSorted = zeros(numberOfTrials,1);

indexCondition=1;
for i=1:1:numberOfConditions
    idx0 = (i-1)*numberOfRepetitions + 1;
    idx1 = idx0+numberOfRepetitions-1;
    trialsSorted(idx0:idx1,1) = indexCondition;
    indexCondition=indexCondition+1;
end

orderRandomized     = randperm(numberOfTrials);
trialsRandomized    = trialsSorted(orderRandomized,1);

timeRandomized = rand(numberOfTrials,1).*(maxTimeBetween-minTimeBetween)...
                        +minTimeBetween;

timeMinutes = floor(timeRandomized);
timeSeconds = timeRandomized.*60-timeMinutes.*60;

%Print the protcol to screen
for i=1:1:numberOfTrials
   fprintf('%d.\twait %1.0fm %1.0fs\t Accelerate:\t%s\t @1g for 1.s\n',...
        i, timeMinutes(i,1),timeSeconds(i,1),...
        nameConditions{trialsRandomized(i,1)});

end
totalTimeSec = sum(timeRandomized.*60 + numberOfTrials*accelerationTime);
totalMinutes = floor(totalTimeSec/60);
totalSeconds = totalTimeSec-totalMinutes*60;
str = sprintf('Total time: %1.1fm %1.1fs\n',totalMinutes,totalSeconds);
disp(str);


