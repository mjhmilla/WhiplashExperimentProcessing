clc;
close all;
clear all;

flag_plotMarkerData=1;

rootDir  = '/home/mmillard/work/code/stuttgart/FKFS/WhiplashExperimentProcessing/code/';
cd(rootDir);
addpath(rootDir);

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
               [colData,header] = readExportedMotiveData(dataFiles(indexFile).name);
               
               if(flag_plotMarkerData==1)
                    fig=figure;
                    nFrames = length(colData(1).data);
                    frameNumber=1;
                    
                    for frameNumber=1:100:nFrames
                        clf(fig);
                        fig = plotMotiveData(frameNumber,colData,...
                            {'head','torso'},[1,0,0; 0,0,1],fig);
                        here=1;
                    end
               end

            end
        end
    end

end