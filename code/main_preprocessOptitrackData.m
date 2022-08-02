clc;
close all;
clear all;

flag_plotMarkerData=1;

% / : linux
% \ : windows
slashChar = '/';

%%
%Check that we're in the correct directory
%%
cd('/home/mjhmilla/dev/projectsBig/stuttgart/FKFS/WhiplashExperimentProcessing/code');
localPath = pwd();
idxSlash = strfind(localPath,slashChar);
parentFolder      = localPath(1,idxSlash(end):end);
grandParentFolder = localPath(1,idxSlash(end-1):idxSlash(end));
assert(contains(parentFolder,'code'));
assert(contains(grandParentFolder,'WhiplashExperimentProcessing'));

codeFolder=localPath;


%%
% Folders
%%
addpath('algorithms/');
addpath('inputOutput/');
addpath(codeFolder);


bodyNames           = {'head','torso'};
dataDir             = '../data/01_preprocessing/car/optitrack/';

cd(dataDir);
dayFolders = dir();

for indexDay = 3:1:length(dayFolders)
    cd(codeFolder);
    cd(dataDir);
    cd(dayFolders(indexDay).name);
    subjectFolders = dir();

    dayDir = pwd;
    for indexFolders=3:1:length(subjectFolders)
        cd(subjectFolders(indexFolders).name);
        dataFiles = dir();

        for indexFile=3:1:length(dataFiles)
            if(contains(dataFiles(indexFile).name,'.csv')==1 ...
                    && contains(dataFiles(indexFile).name,'lock')==0)

               [motiveColData,motiveHeader] = ...
                   readExportedMotiveData(dataFiles(indexFile).name);
               
               [timeFrameData, rigidBodyData, rigidBodyMarkerData] ...
                = interpolateRigidBodyMotionAndMarkers(...
                        motiveColData,motiveHeader,bodyNames);

               if(flag_plotMarkerData==1)
                    fig=figure;
                    nFrames = length(motiveColData(1).data);
                    frameNumber=1;
                    
                    for frameNumber=1:10:nFrames
                        clf(fig);
                        fig = plotMotiveData(frameNumber,motiveColData,...
                            bodyNames,[1,0,0; 0,0,1],fig);
                        pause(0.01);
                    end
               end
               here=1;

            end
        end
    end

end