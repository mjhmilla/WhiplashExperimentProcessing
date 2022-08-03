clc;
close all;
clear all;

flag_plotMarkerData=0;
flag_plotInterpolatedMarkers=0;
flag_plotInterpolatedRigidBodies=0;
flag_writeTRCFile=1;

assert( ~(flag_plotInterpolatedMarkers ...
            && flag_plotInterpolatedRigidBodies));

% / : linux
% \ : windows
slashChar = '/';

%%
%Check that we're in the correct directory
%%
cd('/home/mmillard/work/code/stuttgart/FKFS/WhiplashExperimentProcessing/code');
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
               
               [frameTimeData, rigidBodyData, rigidBodyMarkerData] ...
                = interpolateRigidBodyMotionAndMarkers(...
                        motiveColData,motiveHeader,bodyNames);

               if(flag_plotMarkerData==1)
                    %Find some interpolated frames
                    interpolatedIntervals = [];

                    if(flag_plotInterpolatedRigidBodies)
                        interpolatedIntervals = ...
                            getAllInterpolatedIntervals(rigidBodyData);                        
                    end

                    if(flag_plotInterpolatedMarkers)
                        interpolatedIntervals = ...
                            getAllInterpolatedIntervals(rigidBodyMarkerData);                        
                    end

                    if(isempty(interpolatedIntervals))
                        interpolatedIntervals=[1,1];
                    end
                    
                    figInput=figure;
                    %figInterpolation=figure;
                    frameMax = size(rigidBodyMarkerData(1).r0M0,1);
                    for indexInterval=1:1:size(interpolatedIntervals,1)

                        frameStart = ...
                            max(1,interpolatedIntervals(indexInterval,1)-1);
                        frameEnd = ...
                            min(frameMax, interpolatedIntervals(indexInterval,2)+1);

                        for frame=frameStart:1:frameEnd
                            clf(figInput);
                            %clf(figInterpolation);

                            figInput = plotMotiveData(frame,motiveColData,...
                                bodyNames,[1,0,0; 0,0,1],figInput);

                            figInput=plotRigidBodiesMarkers(frame,...
                                rigidBodyData,rigidBodyMarkerData,...
                                figInput);

                            pause(0.01);
                        end
                    end
               end

               if(flag_writeTRCFile==1)
                    pathAndFileName = dataFiles(indexFile).name;
                    assert(strcmp(pathAndFileName(1,(end-3):end),'.csv'));
                    pathAndFileName(1,(end-3):end)='.trc';
                    
                    success = writeTRCFile(pathAndFileName, ...
                                frameTimeData, rigidBodyMarkerData,...
                                motiveHeader);
                    here=1;
               end
               here=1;

            end
        end
    end

end