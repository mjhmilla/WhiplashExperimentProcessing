clc;
close all;
clear all;

% / : linux
% \ : windows
slashChar = '/';
messageLevel = 1;


dataFolder = 'data2023';
outputFolder = 'output2023';

if(contains(dataFolder,'2023'))
    disp('Important: the TRU_L and TRU_R are really SCP_L and SCP_R');
end

addpath(['algorithms',slashChar]);
addpath(['inputOutput',slashChar]);


%Check that we're in the correct directory
localPath = pwd();
idxSlash = strfind(localPath,slashChar);
parentFolder      = localPath(1,idxSlash(end):end);
grandParentFolder = localPath(1,idxSlash(end-1):idxSlash(end));
assert(contains(parentFolder,'code'));
assert(contains(grandParentFolder,'WhiplashExperimentProcessing'));

codeFolder=localPath;


%Extract EMG onset times from car biopac data
for i=1:1:1
    strNum =num2str(i);
    if(length(strNum)<2)
        strNum = ['0',strNum];
    end

    participantLabel = ['participant',strNum];
    subdir = [slashChar,'car',slashChar,'biopac'];

    carBiopacFolder = ['..',slashChar,dataFolder,slashChar,participantLabel,subdir];
    outputBiopacFolder = ['..',slashChar,outputFolder,slashChar,participantLabel,subdir];

    disp('----------------------------------------');
    disp(participantLabel);
    disp('----------------------------------------');
    success = extractOnsetTimesFromBiopacData(...
                    carBiopacFolder,outputBiopacFolder,codeFolder,...
                    slashChar,messageLevel);
    here=1;

end