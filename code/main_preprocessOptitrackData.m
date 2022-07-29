clc;
close all;
clear all;

flag_plotMarkerData=1;

rootDir  = '/home/mmillard/work/code/stuttgart/FKFS/WhiplashExperimentProcessing/code/';
cd(rootDir);
addpath(rootDir);

bodyNames = {'head','torso'};

dataDir = '../data/01_preprocessing/car/optitrack/';
dayFoldersToProcess = {'02May2022_Monday'};


cd(dataDir);
dayFolders = dir();

for indexDay = 3:1:length(dayFolders)
    cd(rootDir);
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