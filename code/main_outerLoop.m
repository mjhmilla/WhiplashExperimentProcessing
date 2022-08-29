clc;
close all;
clear all;

% / : linux
% \ : windows
slashChar = '/';

%Extract EMG onset times from car biopac data
for i=1:1:20
    strNum =num2str(i);
    if(length(strNum)<2)
        strNum = ['0',strNum];
    end
    participantLabel = ['participant',strNum];
    subdir = '/car/biopac';


    success = ...
        extractOnsetTimesFromBiopacData(participantLabel,subdir,slashChar);
    

end