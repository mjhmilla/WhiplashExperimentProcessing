clc;
close all;
clear all;

flag_plotMarkerData=1;
flag_plotRawMarkerData=0;

flag_plotInterpolatedMarkers        = 0;
flag_plotInterpolatedRigidBodies    = 0;
flag_exportRigidBodyMarkers         = 1;

flag_useDeprecatedOffset            = 1;
% if flag_useDeprecatedOffset is 0 then,
%---------------------------------
% Evaluates the offset between the Mortensen data set and the 
% marker data as
%
%   r0N0-r0M0
%
% where r0N0 is 3x1 and r0M0 is 1x3. This produces (surprisingly!) a 3x3
% matrix of 
%
%   [r0N0(1,1),r0N0(1,1),r0N0(1,1)] - [r0M0(1,1),r0M0(1,2),r0M0(1,3)]
%   [r0N0(2,1),r0N0(2,1),r0N0(2,1)] - [r0M0(1,1),r0M0(1,2),r0M0(1,3)]
%   [r0N0(3,1),r0N0(3,1),r0N0(3,1)] - [r0M0(1,1),r0M0(1,2),r0M0(1,3)]
%
% In which we took the first row as the offset.
%---------------------------------
% Otherwise 
%  
%  r0N0'-r0M0 
%
% is used, which in this case produces the 1x3 vector we are after.
%
figInput=figure;
%%
%The Motive files contain marker positions that are calculated using a 
%transformation of a fixed rigid body, and measured marker positions that
%are close to those positions. Setting flag_exportRigidBodyMarkers
%
% 0: By default the measured marker positions are taken. Gaps are
% interpolated using calculated position of the equivalent rigid body
% marker
% 1: By default the rigid-body-marker positions are taken. Gaps are
% interpolated using calculated position of the equivalent rigid body
% marker
%%

flag_filterMarkerPositions  = 1;
lowPassFilterFrequency      = 10; %As in 10 Hz.

flag_writeTRCFile=1;
unitsLengthTRCFile = 'mm'; %The data is not displayed in the GUI correctly 
                    % unless its in mm

flag_centerDataToMortensenModel = 1;     
angle = -90*(pi/180);
c   = cos(angle);
s   = sin(angle);
rm  = [ c 0 -s; ...
        0 1 0; ...
        s 0 c];
r0N0 = [0.02;0.351569;0];

MortensenModelFrame = struct('rm',rm,'r0N0',r0N0,'markerName','SJN');

bodyNames           = {'head','neck','torso'};

parentName = ...
  [{'head'  },...
   {'head'  },...
   {'head'  },...
   {'head'  },...
   {'head'  },...
   {'neck'  },...
   {'neck'  },...
   {'neck'  },...
   {'torso' },...
   {'torso' },...
   {'torso' },...
   {'torso' },...
   {'torso' },...
   {'torso' },...
   {'torso' }];

markerName = ...
 [{'Marker1'},... 
  {'Marker2'},... 
  {'Marker3'},... 
  {'Marker4'},... 
  {'Marker5'},...
  {'Marker1'},... 
  {'Marker2'},... 
  {'Marker3'},...
  {'Marker1'},... 
  {'Marker3'},... 
  {'Marker5'},...
  {'Marker2'},... 
  {'Marker4'},...
  {'Marker6'},... 
  {'Marker7'}];

newMarkerName = ...
  [{'RZP' },...
   {'RZF' },...
   {'GLA' },...
   {'LZF' },...
   {'LZP' },...
   {'RUN' },... %RUN: right upper neck
   {'LUN' },... %LUN: left upper neck
   {'HY'  },...  %HY: Hyoid
   {'RCAJ'},...
   {'SJN' },...
   {'LCAJ'},...
   {'RC'  },...
   {'LC'  },...
   {'LN'  },...
   {'RN'  }];


assert( ~(flag_plotInterpolatedMarkers ...
            && flag_plotInterpolatedRigidBodies));

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
addpath(['algorithms',slashChar]);
addpath(['inputOutput',slashChar]);
addpath(codeFolder);

dataDir             = sprintf('..%sdata%s',slashChar,slashChar);
dataDir(strfind(dataDir,'/'))=slashChar;


cd(dataDir);
dayFolders = dir();

cd(codeFolder);
cd(dataDir);
dataDir = pwd();

indexParticipant=3;
for indexParticipant=3:1:3 %1:1:3

    participantFolderStr = num2str(indexParticipant);
    if(length(participantFolderStr)<2)
        participantFolderStr=['0',participantFolderStr];
    end
    participantFolderStr = ['participant',participantFolderStr];
    cd(dataDir);
    cd(participantFolderStr);
    participantDir = pwd;
    cd(sprintf('car%soptitrack%scsv%s',slashChar,slashChar,slashChar));

    dataFiles = dir();

    %Count the number of files
    fileCount=0;
    for indexFile=3:1:length(dataFiles)
        if(contains(dataFiles(indexFile).name,'.csv')==1 ...
                && contains(dataFiles(indexFile).name,'lock')==0)
            fileCount=fileCount+1;
        end
    end

    fileNumber=0;
    indexFile=9;
    for indexFile=3:1:length(dataFiles)
        if(contains(dataFiles(indexFile).name,'.csv')==1 ...
                && contains(dataFiles(indexFile).name,'lock')==0)
            
           fileNumber=fileNumber+1;
           fprintf('%i of %i\n', fileNumber, fileCount);
           t0=tic;
           [motiveColData,motiveHeader] = ...
               readExportedMotiveData(dataFiles(indexFile).name);
           t1=toc(t0);
           fprintf('\t%fs\tLoading: %s\n', t1,dataFiles(indexFile).name);
           
           t0=tic;
           [frameTimeData, rigidBodyData, rigidBodyMarkerData] ...
            = interpolateRigidBodyMotionAndMarkers(...
                    motiveColData,motiveHeader,bodyNames,...
                    flag_exportRigidBodyMarkers);
           t1=toc(t0);
           fprintf('\t%fs\tInterpolating\n', t1);   

           t0=tic;
           rawLabelledMarkerData = ...
                getRigidBodyMarkerRawData(rigidBodyMarkerData,motiveColData);
           t1=toc(t0);
           fprintf('\t%fs\tGetting labelled raw marker data\n', t1);  

           [rigidBodyData]=...
               renameRigidBodyData(rigidBodyData,...
                    parentName,...
                    markerName,...
                    newMarkerName);

           [rigidBodyMarkerData]=...
               renameRigidBodyMarkers(rigidBodyMarkerData,...
                    parentName,...
                    markerName,...
                    newMarkerName);

           [rawLabelledMarkerData]=...
               renameLabelledMarkerData(rawLabelledMarkerData,...
                    parentName,...
                    markerName,...
                    newMarkerName);

           if(flag_filterMarkerPositions==1)
               t0=tic;
               [rigidBodyMarkerData] = filterMarkerData(...
                                   rigidBodyMarkerData,...
                                   lowPassFilterFrequency, ...
                                   motiveHeader.Capture_Frame_Rate);
               t1=toc(t0);
               fprintf('\t%fs\tFiltering\n', t1);
           end

           if(flag_centerDataToMortensenModel==1)

                [rigidBodyMarkerData,dataOffset]=...
                    moveMarkerDataToFrame(rigidBodyMarkerData,...
                                          MortensenModelFrame,...
                                          [],...
                                          flag_useDeprecatedOffset);                                

                rigidBodyData=...
                    moveRigidBodyDataToFrame(rigidBodyData,...
                                          MortensenModelFrame,...
                                          dataOffset);

                [rawLabelledMarkerData,dataOffsetB]=...
                    moveMarkerDataToFrame(rawLabelledMarkerData,...
                                          MortensenModelFrame,...
                                          dataOffset,...
                                          flag_useDeprecatedOffset);
                
                                
                assert(norm(dataOffset-dataOffsetB)<1e-6);

                %Obsolete
%                 [rigidBodyData,rigidBodyMarkerData] = ...
%                    moveDataToFrame(rigidBodyData,...
%                                    rigidBodyMarkerData,...   
%                                    MortensenModelFrame);
           end

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
                        if(flag_plotRawMarkerData==1)
                            figInput = plotMotiveData(frame,motiveColData,...
                                bodyNames,[1,0,0; 0,0,1],figInput);
                        end
                        if(flag_plotInterpolatedRigidBodies==1 ...
                            || flag_plotInterpolatedMarkers    )
                            figInput=plotRigidBodiesMarkers(frame,...
                                rigidBodyData,rigidBodyMarkerData,...
                                figInput);
                        end

                        pause(0.01);
                    end
                end
           end

           if(flag_writeTRCFile==1)
                fileName = dataFiles(indexFile).name;
                assert(strcmp(fileName(1,(end-3):end),'.csv'));
                fileName(1,(end-3):end)='.trc';
                t0=tic;
                trcFilePath = [sprintf('..%strc%s',slashChar,slashChar),fileName];
                success = writeTRCFile(trcFilePath, ...
                            frameTimeData, rigidBodyMarkerData,...
                            motiveHeader, newMarkerName,...
                            unitsLengthTRCFile);
                t1=toc(t0);
                fprintf('\t%fs\tWriting TRC file\n', t1);

                fileNameRaw = fileName(1,1:(end-4));
                fileNameRaw = [fileNameRaw,'_raw.trc'];
                t0=tic;
                trcFilePath = [sprintf('..%strc%s',slashChar,slashChar),fileNameRaw];
                success = writeTRCFile(trcFilePath, ...
                            frameTimeData, rawLabelledMarkerData,...
                            motiveHeader, newMarkerName,...
                            unitsLengthTRCFile);
                t1=toc(t0);
                fprintf('\t%fs\tWriting TRC file of raw Mocap data\n', t1);
                t0=tic;
                [trcMetaData, trcFrameTime, trcMarkerData] =...
                    readTRCFile(trcFilePath);
                t1=toc(t0);
                fprintf('\t%fs\tReading TRC file of raw Mocap data\n', t1);
                
           end
           here=1;

        end
    end
end