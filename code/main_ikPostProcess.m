clc;
close all;
clear all;

%%
% This function will go through each participant and each MOT file and
% will:
%
%   I. Load the model
%  II. Load the data from IKResults
% III. For each time sample script will extract the vector and rotation
%    matrix to go from the C7 vertebrae to the skull.
%  IV. The data is written to file:
%    a. In the folder participant01/IKResultsProcessed
%    b. The file written is <mot_file_name>_processed.csv
%    c. The columns written to file are:
%      1. time,
%      2. x,
%      3. y,
%      4. z,
%      5. ux,
%      6. uy,
%      7. uz,
%      8. theta
%
%      ( x, y, z): linear vector from c7 to the skull in the coordinates of c7
%      (ux,uy,uz): normal vector of the axis that the skull is rotated
%                  about w.r.t. c7
%           theta: the angle of rotation of the skull w.r.t. the c7
%                  vertebrae in units of radians
%    V. The csv file has a header, so to read it use
%        data=csvread('Take 2022-05-02 10.14.09 AM_ik_processed.csv',1,0);

% Pull in the modeling classes straight from the OpenSim distribution
import org.opensim.modeling.*

slashChar = '\';

% Check that we are starting in the correct directory
currentDirContents = dir;
assert( contains( currentDirContents(1).folder,...
                  ['WhiplashExperimentProcessing',slashChar,'code'])==1,...
        ['Error: script must be started in the code directory in'...
        ' WhiplashExperimentProcessing']);

addpath('algorithms/');
addpath('inputOutput/');

codeDir = currentDirContents(1).folder;
cd ..;
cd 'data';
dataDir = pwd;
dataDirContents = dir;

%%
% Jakob -   I got tired of manually selecting folders and so I've writtn
%           a bunch of code to get this data automatically.
%           Everything from here until about line 108 is code that will 
%           automatically 
%   
%          1.Open the data folder
%          2.Look in every folder in data with the name 'participant' in it
%          3.Within every participant folder it will check if there exists
%               a.  A file with the ending "scaled.osim" in it. There should
%                   only be one model file like this in each folder
%               b.  A folder with the name IKResults
%               c.  A folder with the name IKResultsProcessed: this is
%                   where the output of this method is stored
%          4.Then it will process every *.mot file in IKResults that does
%            not have the words 'first_step' in it.
%%
for indexDataDir = 1:1:length(dataDirContents)
    if(contains(dataDirContents(indexDataDir).name,'participant'))
        participantDir = fullfile(dataDirContents(indexDataDir).folder,...
                                  dataDirContents(indexDataDir).name);

        disp(['Processing: ', dataDirContents(indexDataDir).name]);

        cd(participantDir);
        participantDirContents = dir;

        %Check to make sure that the directory contains the correct folders
        %and files
        flag_osimFile=0;
        osimFile = '';
        
        flag_IKResultsFolder=0;
        flag_IKResultsProcessedFolder=0;

        for indexFile=1:1:length(participantDirContents)
            if(contains(participantDirContents(indexFile).name,...
                        '_scaled.osim')...
               && participantDirContents(indexFile).isdir==0)
                flag_osimFile=flag_osimFile+1;
                osimFile = participantDirContents(indexFile).name;
            end
            if(strcmp(participantDirContents(indexFile).name,...
                      'IKResults')...
               && participantDirContents(indexFile).isdir==1)
                flag_IKResultsFolder=flag_IKResultsFolder+1;
            end
            if(strcmp(participantDirContents(indexFile).name,...
                      'IKResultsProcessed')...
               && participantDirContents(indexFile).isdir==1)
                flag_IKResultsProcessedFolder=...
                    flag_IKResultsProcessedFolder+1;
            end
        end

        assert(flag_osimFile==1,...
            [dataDirContents(indexDataDir).folder,...
            ': does not contain exactly one file with _scaled.osim ',...
            'in the name'])
        assert(flag_IKResultsFolder==1,...
            [dataDirContents(indexDataDir).folder,...
            ': does not contain exactly one folder named IKResults']);
        assert(flag_IKResultsProcessedFolder==1,...
            [dataDirContents(indexDataDir).folder,...
            ': does not contain exactly one folder named',...
             ' IKResultsPostProcessed']);
        
        motFolder         = fullfile(participantDir,'IKResults');
        motProcessedFolder = fullfile(participantDir,'IKResultsProcessed');

        model = Model(fullfile(participantDir, osimFile));
        modelState=model.initSystem();

        modelCoordSet = model.getCoordinateSet();
        nCoords = modelCoordSet.getSize();
        

        cd(motFolder);
        motFilesToProcess = dir;

        for indexMotFile = 1:1:length(motFilesToProcess)
            flag_firstFrame = contains(motFilesToProcess(indexMotFile).name,...
                                       'first_frame');
            flag_motFile = contains(motFilesToProcess(indexMotFile).name,...
                                       '.mot');
            if(flag_firstFrame==0 && flag_motFile == 1)
                disp(['  ', motFilesToProcess(indexMotFile).name]);
                
                filepath = fullfile(motFilesToProcess(indexMotFile).folder,...
                                    motFilesToProcess(indexMotFile).name);
        
%%
%   1. Load the IK data
%   2. For each time point in the data set:
%       a. Update the (position) state of the model to match the IK data 
%       b. Polish the state to satisfy the constraints of the model
%       c. Compute the positition dependent quantites in the model
%   3. Extract the position and orientation of the torso and the head
%   4. Transform this information into these outputs       
%       a. The position of the head in the coordinate system of the torso
%       b. The orientation of the head w.r.t. the torso described in the
%          axis angle coordinate system.
%   5. Write this data to file
%%

                osimTable   =TimeSeriesTable(filepath);
                osimStruct  =osimTableToStruct(osimTable);
                osimFields  =fields(osimStruct);

                nTime = length(osimStruct.time);

                stateVarNames=model.getStateVariableNames;
                
                outputFileName = motFilesToProcess(indexMotFile).name;
                outputFileName=[outputFileName(1,1:end-4),'_processed.csv'];
                outputFileName=fullfile(motProcessedFolder,outputFileName);

                %%
                % Build the mapping between the column indices of each 
                % entry in the mot file and the index of the corresponding 
                % state name. A timing analysis showed that this is the 
                % most time consuming part of the entire loop, so this 
                % should only be done once per file
                %%

                osimStateNames = string(stateVarNames.getitem(0));
                for i=1:1:(stateVarNames.size-1)
                    osimStateNames=[osimStateNames(),...
                                    string(stateVarNames.getitem(i))];
                end

                motColumnToStateMapping = ...
                    struct('motIndex', zeros(length(osimFields)-1,1),...
                           'stateIndex', zeros(length(osimFields)-1,1),...
                           'motName',[],...
                           'stateName',[]);

                for i=1:1:(length(osimFields)-1)

                    j=1;
                    found=0;
                    while(j < length(osimStateNames) && found==0)

                        if(contains(osimStateNames{j},...
                                    [osimFields{i},'/value']))
                            motColumnToStateMapping.motIndex(i,1)=i;
                            motColumnToStateMapping.motName= ...
                                [motColumnToStateMapping.motName,...
                                 osimFields(i)];
                            motColumnToStateMapping.stateIndex(i,1)=j;
                            motColumnToStateMapping.stateName = ...
                                [motColumnToStateMapping.stateName,...
                                 osimStateNames(j)];
                            found=1;
                        else
                            j=j+1;
                        end
                    end
                    assert(found==1,...
                       ['Error: could not find ', osimFields{i},'/value']);
                end



                %%
                % Open a handle to the output file and write header
                %%
                fid=fopen(outputFileName,'w');
                fprintf(fid,'%s,%s,%s,%s,%s,%s,%s,%s\n',...
                    'time','x','y','z','ux','uy','uz','angle');

                progress=double(0/nTime);
                msg=fprintf('    Progress %1.2f/100',progress*100 );                
                for indexTime=1:1:nTime
                    timeVal = osimStruct.time(indexTime);
                    nStatesSet=0;
                    

                    fprintf(repmat('\b',1,(msg)));
                    progress=double(indexTime/nTime);
                    msg=fprintf('    Progress %1.2f/100', progress*100 );


                    %%
                    % Copy the state over from the loaded mot file into the
                    % correct spot in the state vector of the model.
                    %%
                    t0=tic;
                    for i=1:1:length(motColumnToStateMapping.motIndex)
                       %This variable copy over costs no extra time, but
                       %makes the code more readable
                       stateName = osimStateNames{motColumnToStateMapping.stateIndex(i)}; 
                       fieldName = osimFields{ motColumnToStateMapping.motIndex(i) };
                       model.setStateVariableValue(...
                                modelState,...
                                stateName,...
                                osimStruct.(fieldName)(indexTime,1)); 
                    end
                    timeGetState=toc(t0);

                    %%
                    %The values in the sto file are only valid to 6 decimal
                    %points. This level of accuracy might not be sufficient
                    %to satisfy the constraints in the model. Here we
                    %polish the state up to a higher precision.
                    %%
                    modelStateBefore=modelState;

                    t0=tic;
                    model.assemble(modelState);
                    timeAssemble=toc(t0);

                    %%
                    % Check that the assembly step did not make any big
                    % changes: done only during debugging.
                    %%
                    flag_checkAssembly = 0;
                    if(flag_checkAssembly==1)
                        for i=1:1:length(motColumnToStateMapping.motIndex)
                            stateName = osimStateNames{motColumnToStateMapping.stateIndex(i)}; 
                            fieldName = osimFields{ motColumnToStateMapping.motIndex(i) };                        

                            stateValueBefore = ...
                                double(...
                                    model.getStateVariableValue(...
                                    modelStateBefore,...
                                    stateName));

                            stateValueAfter = ...
                                double(...
                                    model.getStateVariableValue(...
                                    modelState,...
                                    stateName));
                                    
                            fprintf('%e\t%e\t%e\t%s\n',...
                                abs(stateValueBefore-stateValueAfter),...
                                stateValueBefore,...
                                stateValueAfter,...
                                fieldName);
                        end
                    end

                    %%
                    %Before we can evaluate positions and orientations we
                    %need to evaluate all of the kinematic transforms in
                    %the model by calling realizePosition.
                    %%
                    t0=tic;
                    model.realizePosition(modelState);
                    timeRealizePosition=toc(t0);

                    %%
                    %Now what we want is:
                    %  
                    % 'skull': position and orientation
                    %      T1: superior position and orientation.   
                    %   
                    %  There is no T1 body, but we can get this using:
                    %
                    %  1. Approximate: Get the C7 position and orientation.
                    %     This will ignore, of course, the movement that
                    %     takes place at the C7 joint (perhaps 1/7th of the
                    %     movement) and about 1.5 cm of offset in Y.
                    %
                    % 2. Exact: 
                    % 'spine': This has the orientation we want, but not
                    %          the position
                    % 'cerv7': The location of the joint to the c7 body in
                    %          the parent's frame is the position we
                    %          want.
                    %
                    % Note: Roughly the orientation of the bodies is as
                    %       follows: X fwd, Y up, Z right
                    % 
                    %%
                    t0=tic;
                    bodySet     = model.getBodySet();
                    bodySpine   = bodySet.get('spine');
                    bodyC7      = bodySet.get('cerv7');
                    bodySkull   = bodySet.get('skull');

                    X_Skull_C7 =...
                        bodySkull.findTransformBetween(modelState,...
                                                       bodyC7);
                    timeTransform = toc(t0);

                    t0=tic;
                    %r_(from)(to)(frame)
                    osim_r7S7 = X_Skull_C7.p;
                    r7S7 = zeros(1,3);
                    for i=1:1:3
                        r7S7(1,i)=osim_r7S7.get(i-1);
                    end

                    %R_(to)(from)
                    osim_R_7S = X_Skull_C7.R;
                    R_7S = zeros(3,3);
                    for i=1:1:3
                        for j=1:1:3
                            R_7S(i,j)=osim_R_7S.get(i-1,j-1);
                        end
                    end
                    timeTransformConvert=toc(t0);

                    t0=tic;
                    [u,theta] = extractAxisAngleFromRotationMatrix(R_7S);
                    timeTransformProcess=toc(t0);

                    t0=tic;                    
                    fprintf(fid,'%e,%e,%e,%e,%e,%e,%e,%e\n',...
                        timeVal, r7S7(1,1), r7S7(1,2), r7S7(1,3), ...
                                 u(1,1), u(2,1), u(3,1), theta);
                    timeWrite=toc(t0);
                    here=1;
                end
                fclose(fid);

                
            end
        end

    end
end    


fprintf('\n\nCOMPLETED \n');


