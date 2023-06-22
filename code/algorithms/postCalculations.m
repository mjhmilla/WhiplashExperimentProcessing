%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Comment: As I told you I used a modified version of your code
% (extractOnsetTimesFromBiopacData) to calculate the car acc. onset
% 
% Next, I used a constant delay factor (line 12-118), for analyzing some
% time depending parameters (e.g. time to max strain/displacement...), the
% exact delay in each trial should be calculated
%
% After the last participant is fully processed, the script still runs a
% long time, I dont know why
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [results]=postCalculations (codeDir,dataDir,...
                openSimDir,outputSetFolder, osimPath,...
                indexMovementStartOffset,indexMovementEndOffset,...
                idStr,slashChar)

[inputFolders,~] = getParticipantFolders(idStr, dataDir,outputSetFolder);
[opensimFolders] = getParticipantOpensimFolders(idStr, openSimDir);

participantNum = ['participant',idStr];

import org.opensim.modeling.*;

trialsFiber = dir(fullfile(opensimFolders.analyze,'*FiberLength.sto'));
trcDir      = fullfile(inputFolders.carOptiTrack,'trc');
allTrc      = dir(fullfile(trcDir, '*.trc'));
trialsTrc   = allTrc(find(cellfun(@isempty,regexp({allTrc.name},'raw'))));

postProcessFiles = dir(fullfile(opensimFolders.postprocessing, '*.csv'));

nTrial= length(trialsTrc);
                       
% Load the model and initialize
model=Model(fullfile(osimPath));

% Alle Muskeln des Modells auslesen
Muscles(:,1) = osimList2MatlabCell(model,'Muscle'); 

% calculate onset times
subdir= [slashChar, 'car', slashChar, 'biopac'];
messageLevel=0;
[carAccOnsetTime,  carAccOffsetTime] =extractOnsetTimesFromBiopacData_modified(participantNum,subdir,slashChar,messageLevel);

% Onset Car with Delay
carAccOnsetTime_idx= floor(carAccOnsetTime.*200);
carAccOnsetTime_idx_new= carAccOnsetTime_idx-205;

% Offset Car with Delay
carAccOffsetTime_idx= floor(carAccOffsetTime.*200);
carAccOffsetTime_idx_new= carAccOffsetTime_idx-205;

% calculate reference window
reference_idx_start= calc_ref_idx(trialsTrc,trcDir,carAccOnsetTime_idx_new,indexMovementStartOffset);

results=[]; 
% Loop through the trials
for j= 1:nTrial
   
    fprintf(['Performing on cycle # ' num2str(j) '\n']);

    % Get the name of the file for this trial
    fiberFile = trialsFiber(j).name;
    cd(opensimFolders.postprocessing)
    csv_data=csvread(postProcessFiles(j).name,1,0); 

    cd(opensimFolders.analyze);
    % Analyze Ergebnisse auslesen
    fiberLength= struct2cell(osimTableToStruct(TimeSeriesTable(fiberFile)));

    referenceIdx= floor(reference_idx_start(j):reference_idx_start(j)+(indexMovementStartOffset-1));
   
 
     x_ref=[];
     y_ref=[];
     z_ref=[];
     norm_vec=[];

  % Displacement calculation
  for idx= 1:length(csv_data)

      x_ref(idx)= (csv_data(idx,2)-mean(csv_data(referenceIdx,2))).*100; 
      y_ref(idx)= (csv_data(idx,3)-mean(csv_data(referenceIdx,3))).*100;
      z_ref(idx)= (csv_data(idx,4)-mean(csv_data(referenceIdx,4))).*100;

      norm_vec(idx)= sqrt(x_ref(idx).^2+y_ref(idx).^2+z_ref(idx).^2);
  end
  
  displ{1,1}=norm_vec;
  [displ{1,2}, displ{1,3}]=max(norm_vec(carAccOnsetTime_idx_new(j):carAccOnsetTime_idx_new(j)+(indexMovementEndOffset-1)));

  % Strain calculation
  for k= 1: length(fiberLength)-1

      reference_length_fiber= mean(fiberLength{k}(referenceIdx));
      strain_fiber{k,1}= matlab.unittest.diagnostics.ConstraintDiagnostic.getDisplayableString(Muscles{k,1});
      strain_fiber{k,2}= ((fiberLength{k,1}-reference_length_fiber)./reference_length_fiber).*100;
      [strain_fiber{k,3} , strain_fiber{k,4}]= max(strain_fiber{k,2}(carAccOnsetTime_idx_new(j):carAccOnsetTime_idx_new(j)+(indexMovementEndOffset-1)));
      strain_fiber{k,5}=  reference_length_fiber;
      
  end

  results(j).name= fiberFile; 
  results(j).onset= carAccOnsetTime_idx_new(j);
  results(j).offset= carAccOffsetTime_idx_new(j);
  results(j).displacement=displ;
  results(j).strain_fiber= strain_fiber; 
  results(j).fiber_length= fiberLength; 
  results(j).reference_idx= referenceIdx;


end  

cd(opensimFolders.postprocessing)
save([participantNum,'_results'],'results')

fprintf([participantNum, ' COMPLETED' '\n']);
cd(codeDir)
    

end