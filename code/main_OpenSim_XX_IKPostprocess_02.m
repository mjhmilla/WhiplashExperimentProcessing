%%
% @author: Jakob Vilsmeier, Matthew Millard
% @date: 1/3/2023 
%        22/6/2023
%
% Description
% This function will solve for the transform between the T1-C7 joint to
% the skull center of mass frame. This information is saved to file
% that contains the translation (x,y,z) and the quaternion 
% coordinates (ux,uy,uz,theta).
%%
flag_useDefaultInitialization=0;
if(exist('flag_outerLoopMode','var') == 0)
    flag_useDefaultInitialization=1;
else    
    if(flag_outerLoopMode==0)
        flag_useDefaultInitialization=1;
    end
end
if(flag_useDefaultInitialization==1)
    clc
    clear all
    close all;    
    % 0: 2022 data set
    % 1: 2023 data set
    flag_dataSet = 0; 
end

assert(flag_dataSet==0,'Error: Code has not yet been updated to work',...
    ' with the 2023 dataset, which includes a different marker layout.');

skipTheseFolders = {'participant21_presentation'};
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


% Check that we are starting in the correct directory
localPath=pwd();
[parentFolderPath,parentFolder] = fileparts(localPath);

assert(contains(parentFolder,'code'));
assert(contains(parentFolderPath,'WhiplashExperimentProcessing'));

addpath('algorithms/');
addpath('inputOutput/');

codeDir = pwd;
cd ..;
cd 'opensim2022';
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
    flag_ignoreFolder=0;
    for indexIgnore = 1:1:length(skipTheseFolders)
        if(contains(dataDirContents(indexDataDir).name,skipTheseFolders{indexIgnore}))
            flag_ignoreFolder=1;
        end
    end

    if(contains(dataDirContents(indexDataDir).name,'participant') && flag_ignoreFolder==0)
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
                      'ik')...
               && participantDirContents(indexFile).isdir==1)
                flag_IKResultsFolder=flag_IKResultsFolder+1;
            end
            if(strcmp(participantDirContents(indexFile).name,...
                      'postprocessing')...
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
            ': does not contain exactly one folder named "ik"']);
        assert(flag_IKResultsProcessedFolder==1,...
            [dataDirContents(indexDataDir).folder,...
            ': does not contain exactly one folder named',...
             ' "postprocessing"']);
        
        motFolder         = fullfile(participantDir,'ik');
        motProcessedFolder = fullfile(participantDir,'postprocessing');

        model = Model(fullfile(participantDir, osimFile));
        modelState=model.initSystem();

        modelCoordSet = model.getCoordinateSet();
        nCoords = modelCoordSet.getSize();
        

        cd(motFolder);
        motFilesToProcess = dir;
        for indexMotFile = 1:1:length(motFilesToProcess)
            flag_firstFrame = contains(motFilesToProcess(indexMotFile).name,...
                                       'FirstFrame');
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
                    %Now what we want is
                    %
                    % X_SkullCOM_T1 where the notation is 
                    %   X       : transform position and orientation 
                    %   SkullCOM: to the center of mass of the skull frame
                    %   T1      : from the T1 frame
                    %  
                    %%

                    t0=tic;

                    %Get the transform from the spine to the T1 frame
                    jointSet = model.getJointSet();
                    jointAuxT1Jnt=jointSet.get('auxt1jnt');
                    jointAuxT1JntParentFrame = jointAuxT1Jnt.getParentFrame();
                    X_Spine_T1 = jointAuxT1JntParentFrame.findTransformInBaseFrame();
                    [rS1S, RS1]  = convertOpenSimTransformToMatrices(...
                                        X_Spine_T1); 
                    if(indexTime==1)
                        RS1err = RS1-eye(3,3);
                        for i=1:1:3
                            for j=1:1:3
                                assert(abs(RS1err(i,j))<1e-6,...
                                    ['Error: the T1 frame is rotated',...
                                     ' w.r.t. the spine frame']);
                            end
                        end
                    end

                    %Make sure that the skull's C1 joint frame is at the 
                    %origin of the skull - later calculations assume this.
                    jointAux1Jnt = jointSet.get('aux1jnt');
                    jointAux1JntChildFrame = jointAux1Jnt.getChildFrame();
                    X_SkullOffset_Skull = jointAux1JntChildFrame.findTransformInBaseFrame();
                    [rOKO, ROK]  = convertOpenSimTransformToMatrices(...
                                        X_SkullOffset_Skull);

                    if(indexTime==1)
                        ROKerr= ROK-eye(3,3);
                        for i=1:1:3
                            assert(abs(rOKO(i,1))<1e-6,...
                                 ['Error: C1 joint of the skull is not',...
                                  ' at the origin of the skull body.']);
                            for j=1:1:3
                                assert(abs(ROKerr(i,j))<1e-6,...
                                 ['Error: C1 joint of the skull is not',...
                                  ' aligned with the skull body.']);
                            end
                        end
                    end

                    %Get the transform from ground to the spine, skull.
                    %Use body C7 to check if the X_Skull_T1 transform is
                    %close to the X_Skull_T1
                    bodySet     = model.getBodySet();
                    bodySpine   = bodySet.get('spine');
                    bodySkull   = bodySet.get('skull');                    
                    bodyC7      = bodySet.get('cerv7');

                    X_G_Skull = ...
                        bodySkull.getTransformInGround(modelState);

                    X_G_Spine = ...
                        bodySpine.getTransformInGround(modelState);

                    [rGKG, RGK]  = convertOpenSimTransformToMatrices(...
                                        X_G_Skull);
                    rKCK         = convertOpenSimVecToVector(...
                                        bodySkull.get_mass_center());

                    [rGSG, RGS]  = convertOpenSimTransformToMatrices(...
                                        X_G_Spine);
                    
                    %%
                    %Evaluate the transform from T1 to the skull's 
                    %COM resolved in the coordinates of T1, which is
                    %the spine in this case
                    %%
                    rGCG = rGKG + (RGK*rKCK);
                    rG1G = rGSG + (RGS*rS1S);

                    r1CG = rGCG-rG1G;
                    r1CS = RGS'*r1CG;
                    RSC  = (RGS')*RGK;


                    
                    %Sanity checks
                    X_T1_Skull = ...
                        bodySkull.findTransformBetween(modelState,...
                                                       jointAuxT1JntParentFrame);
                    [r1K1, R1K]=convertOpenSimTransformToMatrices(X_T1_Skull);   

                    if(indexTime==1)
                        r1KG_test = rGKG-rG1G;
                        r1K1_test = RGS'*(r1KG_test); 
                        assert(norm(r1K1_test-r1K1)<1e-6,...
                               'Error: expressions used to build r1CS are wrong');
                        assert(norm(RSC-R1K)<1e-6,...
                            'Error: expressions used to build RSC are in wrong');
                    end

                    timeTransform = toc(t0);
                    
                    
                    %%
                    %Manually create the X_Skull_C7 to reverse engineer
                    %the convention used for the rotation matrices
                    %
                    %  Notation convention
                    %   rG7G: (r) vector
                    %         (G) from point G
                    %         (7) to point 7 (the origin of frame 7)
                    %         (G) in coordinates of frame G
                    %
                    %   RGS:  (R) rotation matrix
                    %         (G) to frame G
                    %         (S) from frame S
                    %
                    %   This convention means that you can check if 
                    %   a matrix vector multiplication is valid
                    %
                    %   R_toF_fromF * r_fromPt_toPt_inF
                    %
                    %   The last two characters of the rotation matrix
                    %   and the vector must match. Note that if you do
                    %   a transpose operation to R, this is equivalent to
                    %   switching the from and to frames.
                    %
                    %%

                    if(indexTime==1)

                        X_C7_Skull =...
                            bodySkull.findTransformBetween(modelState,...
                                                           bodyC7);                    
                        [r7K7, R7K]=convertOpenSimTransformToMatrices(X_C7_Skull);
                        
                        X_G_C7 = bodyC7.getTransformInGround(modelState);
                        [rG7G,RG7]=convertOpenSimTransformToMatrices(X_G_C7);

                        r7K7check = RG7'*(rGKG-rG7G);
                        R7Kcheck  = RG7'*RGK;
    
                        r7K7err = norm(r7K7check-r7K7);
                        R7Kerr = norm(R7Kcheck-R7K);
                        assert(r7K7err < 1e-6);
                        assert(R7Kerr < 1e-6);
                    end

                    %%
                    % Form the expressions for the transform between
                    % the joint between the spine-c7 to the skull.
                    %%

                    t0=tic;
                    [u,theta] = extractAxisAngleFromRotationMatrix(RSC);
                    timeTransformProcess=toc(t0);

                    t0=tic;                    
                    fprintf(fid,'%e,%e,%e,%e,%e,%e,%e,%e\n',...
                        timeVal, r1CS(1,1), r1CS(2,1), r1CS(3,1), ...
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
cd(codeDir);

