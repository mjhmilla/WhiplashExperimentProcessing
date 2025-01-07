clc;
close all;
clear all;

% / : linux & mac
% \ : windows
slashChar = '/';
messageLevel = 1;

flag_use2022Data=0;
flag_use2023Data=1;

assert((flag_use2022Data && flag_use2023Data) == 0,...
       'Error: only one data set can be processed at a time');

if(flag_use2022Data==1)
    dataFolder      = 'data2022';
    outputFolder    = 'output2022';
end 

if(flag_use2023Data==1)
    dataFolder      = 'data2023';
    outputFolder    = 'output2023';
    disp('Important: the TRU_L and TRU_R are really SCP_L and SCP_R');
end 

flag_removeECGPeaksFromEMGData=1;

% When set to 1 png images will be written to the output folder of the
% accelerations and EMG data with the onsets identified
flag_plotOnset = 1; 

% When set to 1 csv files will be written to the output folder 
% containing the time delays between: 
%
% 1. The acceleration onset of the car and the EMG onset of the 6 neck 
%    muscles.
%
% 2. The acceleration onset of the head and the EMG onset of the 6 neck 
%    muscles.
%
flag_writeOnsetDataToFile = 1;


addpath(['algorithms',slashChar]);
addpath(['inputOutput',slashChar]);


%Check that we're in the correct directory
localPath           = pwd();
idxSlash            = strfind(localPath,slashChar);
parentFolder        = localPath(1,idxSlash(end):end);
grandParentFolder   = localPath(1,idxSlash(end-1):idxSlash(end));

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
                    slashChar,messageLevel,...
                    flag_removeECGPeaksFromEMGData,...
                    flag_plotOnset, flag_writeOnsetDataToFile);
    here=1;

end