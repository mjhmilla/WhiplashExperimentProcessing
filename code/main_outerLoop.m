clc;
close all;
clear all;

% / : linux
% \ : windows
slashChar = '/';
messageLevel = 1;


%Extract EMG onset times from car biopac data
for i=1:1:21
    strNum =num2str(i);
    if(length(strNum)<2)
        strNum = ['0',strNum];
    end
    participantLabel = ['participant',strNum];
    subdir = '/car/biopac';

    disp('----------------------------------------');
    disp(participantLabel);
    disp('----------------------------------------');
    success = ...
        extractOnsetTimesFromBiopacData(participantLabel,subdir,slashChar,...
                                        messageLevel);
    

end