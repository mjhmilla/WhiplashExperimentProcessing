%%main_emgComparison
clc;
close all;
clear all;

flag_subtractMeanHeadOnsetTimesFrom2023EmgData = 0;
flag_calculateMeanAndExtraColums=1;
% flag_putEachConditionInAnExtraColumn=1;

%Notes to improve participantEmgData
% 1. Get rid of the first 2 elements
% 2. Change flag_ignoreTrial to flag_useTrial

% 0: 2022 data set
% 1: 2023 data set
flag_dataSet    = 1;


dataSet2022 = 0; %Constant: do not change
dataSet2023 = 1; %Constant: do not change

participantFirst= 1;
participantLast = 28;

percentileSet       = [0.05;0.25;0.5;0.75;0.95];

%Removal of invalid data
flag_removeNegativeValues  = 1;
maxAllowedNormEMGAmplitude = 1.5;

maxBumperToEmgOnsetTime_BraultSiegmundWheeler2000 = 0.104; 
maxAllowedHeadToEMGOnsetTime  = 0.150;
maxAllowedCarToEMGOnsetTime_Kemptner2022 = 0.5;

%Input
noDataNumber = -1;
firstMuscleBiopacIndex=1;
lastMuscleBiopacIndex=6;
numberOfMuscles = lastMuscleBiopacIndex-firstMuscleBiopacIndex+1;
                    
numberOfConditions = 2;
conditionsToCompare(numberOfConditions) ...
    = struct('condition','',... 
             'carDirection','',...
             'columnNames',      [],... 
             'times',            [],...
             'magnitudes',       [],...
             'participantIndex',[],...
             'trialIndex',      [],...
             'fileName'  ,      []);

disp('Participant 1 in 2023 breaks left/right analysis');
disp('because they did not have 3 repeats collected. Blocks X and Y need');
disp('to be updated');
conditionsToCompare(1).condition='nominal';
conditionsToCompare(1).carDirection='Backwards';

conditionsToCompare(2).condition='seatBack';
conditionsToCompare(2).carDirection='Backwards';
% 
% conditionsToCompare(3).condition='nominal';
% conditionsToCompare(3).carDirection='Right';
% 
% conditionsToCompare(4).condition='seatBack';
% conditionsToCompare(4).carDirection='Right';

%%
% The ordering of these names define the code that is used in file 
% generated for SPSS. For example
%
% id,   sex,    seatPosition,   direction,  muscle
% 5,      2,               2,           3,       4
%
% Would mean 
%   Participant 5
%   Female
%   seatBack
%   Right
%   TRO:R
%%
sexNames = {'m','f'};
indexMale=1;
indexFemale=2;
sexNamesForLabel = {'male','female'};

seatPositionNames = {'nominal','seatBack'};
indexSeatNominal = 1;
indexSeatBack    = 2;

directionNames = {'Forward','Backwards','Right','Left'};
indexForward   = 1;
indexBackwards = 2;
indexRight     = 3;
indexLeft      = 4;

muscleNames = {'STR:L','STR:R','TRO:L','TRO:R','SPL:L','SPL:R'};

%%
% SPSS Table: If needed, update the column labels
%%
switch flag_calculateMeanAndExtraColums
    case 0
        spssTable.columnLabels = {'id','sex','seatPosition','direction','muscle','onsetTime','amplitude'};
    case 1
        spssTable.columnLabels ={'muscle'};
        positionOnsetLabels=1;
        positionAmplitudeLabels=1+(length(sexNames)*numberOfConditions);
        for indexCondition=1:1:numberOfConditions
            for indexGender=1:1:length(sexNames)
                positionOnsetLabels=positionOnsetLabels+1;
                positionAmplitudeLabels=positionAmplitudeLabels+1;

                nameCondition = char(conditionsToCompare(indexCondition).condition);
                nameCarDirection = char(conditionsToCompare(indexCondition).carDirection);
                nameGender = char(sexNamesForLabel(indexGender));

                nameOnsetLabels = ['Onset', nameCondition , nameCarDirection, nameGender];
                nameAmplitudeLabels = ['Amplitude', nameCondition , nameCarDirection, nameGender];

                spssTable.columnLabels(positionOnsetLabels)={nameOnsetLabels};
                spssTable.columnLabels(positionAmplitudeLabels)={nameAmplitudeLabels};
            end
        end
%        positionOnsetLabels=1;
%        positionAmplitudeLabels=1+(numberOfMuscles*numberOfConditions); 
end
spssTable.data = [];

%Local folders
addpath('inputOutput');
addpath('algorithms');

%Check that Matlab is currently in the code directory
localPath=pwd();
[parentFolderPath,parentFolder] = fileparts(localPath);

assert(contains(parentFolder,'code'));
assert(contains(parentFolderPath,'WhiplashExperimentProcessing'));

whiplashFolder= parentFolderPath;
codeFolder=localPath;


[meanHeadOnsetTimes2022, stdHeadOnsetTimes2022, headOnsetTimes2022] ...
    = calculateMeanAccHead(dataSet2022);

switch(flag_dataSet)
	case 0
		dataSetFolder = fullfile(whiplashFolder,'data2022');
		outputSetFolder=fullfile(whiplashFolder,'output2022');        
		numberOfParticipants=21;

	case 1
		dataSetFolder = fullfile(whiplashFolder,'data2023');
		outputSetFolder=fullfile(whiplashFolder,'output2023');
		numberOfParticipants=28;    
		disp('Important: the TRU_L and TRU_R are really SCP_L and SCP_R');
        disp('Important: the head accelerometer was never attached to the head. (Matts fault)');
 	otherwise
		assert(0,'Error: flag_dataSet must be 0 or 1');
end


dataParticipantConditions=buildConditionDataTable(participantFirst,participantLast,dataSetFolder,...
    outputSetFolder,conditionsToCompare,firstMuscleBiopacIndex,...
    lastMuscleBiopacIndex,numberOfMuscles,noDataNumber);

here=1;


%% create struct/array for plot
%should include all trials for all participants and muscles for one
%condition

outputOnsetTimes(numberOfConditions) ...
    = struct('allMuscles',[],'id',[]);


outputAmplitude(numberOfConditions)...
     = struct('allMuscles',[],'id',[]);



% This function does 2 things
% 1. Gets the number of times a trial x condition is repeated (repeatsPerCondition)
% 2. Makes a vector of indices so that all of the structs data can be put into
%    a single vector across  participants x repeats
%
    indexParticipant=2;
    repeatsPerCondition = zeros(1,length(conditionsToCompare));
    vectorStartIndexMap = zeros(length(conditionsToCompare), participantLast);
    
    for i=1:1:length(conditionsToCompare)
        repeatsPerCondition(:,i) =...
            height(dataParticipantConditions(indexParticipant).conditions(i).times);
        vectorStartIndexMap(i,:) = ...
            [1:repeatsPerCondition(i):participantLast*repeatsPerCondition(i)];
    
         outputOnsetTimes(i).id=                  ones(repeatsPerCondition...
                                                                    (:,i)*participantLast,1).*noDataNumber;
         outputOnsetTimes(i).allMuscles=    ones(repeatsPerCondition...
                                                                    (:,i)*participantLast,numberOfMuscles).*noDataNumber;
         outputAmplitude(i).id=                     ones(repeatsPerCondition...
                                                                    (:,i)*participantLast,1).*noDataNumber;
         outputAmplitude(i).allMuscles=       ones(repeatsPerCondition...
                                                                    (:,i)*participantLast,numberOfMuscles).*noDataNumber;
    
    end 
    
    %
    % This function fishes out all of the onset times for a specific muscle
    % and groups it across the entire data set but separated by condition.
    %
    % Consider replacing this with an accumulation.
    %
    
    % outputOnsetTimes(idxC).id(indexStart:indexEnd,1) = idxP;
    % 
    % outputOnsetTimes(idxC).allMuscles(indexStart:indexEnd,idxM)...
    %     = dataParticipantConditions(idxP).conditions(idxC).times(:,idxM);
    % 
    % outputAmplitude(idxC).id(indexStart:indexEnd,1) = idxP;            
    % 
    % outputAmplitude(idxC).allMuscles(indexStart:indexEnd,idxM)...
    %     = dataParticipantConditions(idxP).conditions(idxC).magnitudes(:,idxM);
    
    disp('Block Y. Update this code to something easier to understand');
    for idxP = participantFirst:1:participantLast
        for idxC=1:1:length(conditionsToCompare)        
            for idxM = firstMuscleBiopacIndex:1:lastMuscleBiopacIndex
    
                indexStart = vectorStartIndexMap(idxC,idxP);
                indexEnd   = indexStart+repeatsPerCondition(1,idxC)-1;
    
                outputOnsetTimes(idxC).id(indexStart:indexEnd,1) = idxP;
    
                outputOnsetTimes(idxC).allMuscles(indexStart:indexEnd,idxM)...
                    = dataParticipantConditions(idxP).conditions(idxC).times(:,idxM);
    
                outputAmplitude(idxC).id(indexStart:indexEnd,1) = idxP;            
    
                outputAmplitude(idxC).allMuscles(indexStart:indexEnd,idxM)...
                    = dataParticipantConditions(idxP).conditions(idxC).magnitudes(:,idxM);
                
            end
        end 
    end 
% elseif flag_calculateMeanForEachParticipant==1
%      for idxP = participantFirst:1:participantLast
%         for idxC=1:1:length(conditionsToCompare)        
%             for idxM = firstMuscleBiopacIndex:1:lastMuscleBiopacIndex
%    
%                 outputOnsetTimes(idxC).id(idxP,1)= idxP;
% 
%                 onsetTimesTemporary=dataParticipantConditions(idxP).conditions(idxC).times(:,idxM);
%                 meanOnset=mean(onsetTimesTemporary);
%                 outputOnsetTimes(idxC).allMuscles(idxP,idxM)=meanOnset;
%     
%                 outputAmplitude(idxC).id(idxP,1)= idxP;
% 
%                 amplitudesTemorary=dataParticipantConditions(idxP).conditions(idxC).magnitudes(:,idxM);
%                 meanAmplitudes=mean(amplitudesTemorary);    
%                 outputAmplitude(idxC).allMuscles(idxP,idxM)= meanAmplitudes;
%                 
%             end
%         end 
%     end 
 


%%
%Build a plot that contains a box-whisker illustration for each 
%condition

%% calculate percentiles 

outputPercentiles(numberOfConditions) ...
    = struct('percentilesOnsetTimes',[],...
             'percentilesAmplitudes',[]);

outputValidData(numberOfMuscles)...
    = struct ('validDataOnsetTimes',[],...
              'validDataAmplitudes',[]);


for indexCondition = 1:1:numberOfConditions
        for indexMuscle = firstMuscleBiopacIndex:1:lastMuscleBiopacIndex


            [val,idDirection] = ...
                    max(contains(directionNames,...
                                 conditionsToCompare(indexCondition).carDirection));

%             meanCarHeadOnsetTimeByDirection = meanHeadOnsetTimes2022(1,idDirection);
% 
%             maxAllowedCarToEMGOnsetTime = meanCarHeadOnsetTimeByDirection ...
%                                         + maxAllowedHeadToEMGOnsetTime;

            [validIdOnsetTimes,validIdAmplitudes, validDataOnsetTimes, validDataAmplitudes] = ...
                newExtractValidData(...
                        outputOnsetTimes(indexCondition).id(:,1),...
                        outputAmplitude(indexCondition).id(:,1),...
                        outputOnsetTimes(indexCondition).allMuscles(:,indexMuscle),...
                        outputAmplitude(indexCondition).allMuscles(:,indexMuscle),...
                        maxAllowedNormEMGAmplitude,...
                        maxAllowedCarToEMGOnsetTime_Kemptner2022,...
                        noDataNumber,... 
                        flag_removeNegativeValues);


            for indexPercentile = 1:1:length(percentileSet)        
                    percentilesOnsetTime(indexPercentile,indexMuscle) ...
                         = getPercentiles(validDataOnsetTimes,...
                                percentileSet(indexPercentile));
        
                    percentilesAmplitude(indexPercentile,indexMuscle) ...
                         = getPercentiles(validDataAmplitudes,...
                                percentileSet(indexPercentile));
                     
            end

            

            outputValidData(indexCondition,indexMuscle).idOnsetTimes = validIdOnsetTimes;
            outputValidData(indexCondition,indexMuscle).idAmplitudes = validIdAmplitudes;
            outputValidData(indexCondition,indexMuscle).validDataOnsetTimes = validDataOnsetTimes;
            outputValidData(indexCondition,indexMuscle).validDataAmplitudes = validDataAmplitudes;

            if flag_calculateMeanAndExtraColums == 1
                meanOnsetTimes=ones(participantLast,1).*noDataNumber;
                meanAmplitudes=ones(participantLast,1).*noDataNumber;
                participantIdForMean=ones(participantLast,1).*noDataNumber;
%                 meanOnsetTimes=[];
%                 meanAmplitudes=[];
%                 participantIdForMean=[];
                for indexParticipant=participantFirst:1:participantLast
                    if exist('amplitudesParticipant','var') == 1
                    clear amplitudesParticipant
                    end
                     if exist('onsetTimesParticipant','var') == 1
                        clear onsetTimesParticipant
                     end
                 amplitudesParticipant=[];
                 onsetTimesParticipant=[];
                    for indexTrial=1:1:length(outputValidData(indexCondition,indexMuscle).idOnsetTimes)
                        if outputValidData(indexCondition,indexMuscle).idOnsetTimes(indexTrial) == indexParticipant
                            onsetTimesParticipant=[onsetTimesParticipant,outputValidData(indexCondition,indexMuscle).validDataOnsetTimes(indexTrial)];
                        end
                    end
                    for indexTrial=1:1:length(outputValidData(indexCondition,indexMuscle).idAmplitudes)
                        if outputValidData(indexCondition,indexMuscle).idAmplitudes(indexTrial) == indexParticipant
                            amplitudesParticipant=[amplitudesParticipant,outputValidData(indexCondition,indexMuscle).validDataAmplitudes(indexTrial)];
                        end
                    end
                    if isempty(onsetTimesParticipant) == 0
                        meanOnsetTimes(indexParticipant) = mean(onsetTimesParticipant);
                    end
                    if isempty(amplitudesParticipant) == 0
                        meanAmplitudes(indexParticipant) = mean(amplitudesParticipant);
%                     meanOnsetTimes=[meanOnsetTimes,mean(onsetTimesParticipant)];
%                     meanAmplitudes=[meanAmplitudes,mean(amplitudesParticipant)];
%                     participantIdForMean=[participantIdForMean,indexParticipant];
                    end
                end
%             validId=participantIdForMean';
            validId=participantFirst:1:participantLast;
            validId=validId';
            validDataOnsetTimes=meanOnsetTimes;
            validDataAmplitudes=meanAmplitudes;
            outputValidData(indexCondition,indexMuscle).id = validId;
            outputValidData(indexCondition,indexMuscle).validDataOnsetTimes = validDataOnsetTimes;
            outputValidData(indexCondition,indexMuscle).validDataAmplitudes = validDataAmplitudes;

       
            end
            

            %Add the additional fields that will be written to the file given to SPSS
            %
            % participant [1-28]
            % sex 
            %  1:m
            %  2:f     
            %
            % direction
            %  1:forward
            %  2:backwards
            %  3:right
            %  4:left
            %
            % seatPosition
            %  1: nominal
            %  2: back           
            %
            % muscle
            %  1. STR_L
            %  2. STR_R
            %  3. TRP_L
            %  4. TRP_R
            %  5. SPL_L
            %  6. SPL_R
            
            spssSubTable =[];
            spssRow = [];
            if flag_calculateMeanAndExtraColums==0
            for i=1:1:length(validId)
                participantData = getParticipantDataFebruary2023(validId(i,1));
                
                [val,idSex] = max(contains(sexNames,participantData.sex));
                
                [val,idSeatPosition] = ...
                    max(contains(seatPositionNames,...
                                 conditionsToCompare(indexCondition).condition));

                [val,idDirection] = ...
                    max(contains(directionNames,...
                                 conditionsToCompare(indexCondition).carDirection));


                idMuscle = (indexMuscle-firstMuscleBiopacIndex)+1;

                %%
                % SPSS Table: If needed, update the size and data in the 
                %             rows
                %%

                
                spssRow = zeros(1,length(spssTable.columnLabels));
                spssRow(1,1) = validId(i,1);
                spssRow(1,2) = idSex;
                spssRow(1,3) = idSeatPosition;
                spssRow(1,4) = idDirection;
                spssRow(1,5) = idMuscle;
                spssRow(1,6) = validDataOnsetTimes(i,1);
                spssRow(1,7) = validDataAmplitudes(i,1);

                spssTable.data =[spssTable.data; spssRow];

              

            end

            end



        end 

        for indexPercentile = 1:1:length(percentileSet)        
        percentilesOnsetTime(indexPercentile,indexMuscle) ...
             = getPercentiles(validDataOnsetTimes,...
                    percentileSet(indexPercentile));

        percentilesAmplitude(indexPercentile,indexMuscle) ...
             = getPercentiles(validDataAmplitudes,...
                    percentileSet(indexPercentile));
                 
        end
        outputPercentiles(indexCondition).percentilesOnsetTimes = percentilesOnsetTime;
        outputPercentiles(indexCondition).percentilesAmplitudes = percentilesAmplitude;            
       
end 
outputGenders (numberOfConditions) ...
    = struct ('male', [],...
                  'female', []);
for i=1:1:numberOfConditions
outputGenders(i).male...
    =struct ('Onset', [],...
     'Amplitude', []);
outputGenders(i).female...
    =struct ('Onset', [],...
     'Amplitude', []);
end
for indexParticipant= participantFirst:1:participantLast
     participantData = getParticipantDataFebruary2023(indexParticipant);
     [val,idSex] = max(contains(sexNames,participantData.sex));
    for indexCondition= 1:1:numberOfConditions
        for indexMuscle = firstMuscleBiopacIndex:1:lastMuscleBiopacIndex
            if idSex ==1
                outputGenders(indexCondition).male.Onset = [outputGenders(indexCondition).male.Onset, outputValidData(indexCondition,indexMuscle).validDataOnsetTimes(indexParticipant)];
                outputGenders(indexCondition).male.Amplitude = [outputGenders(indexCondition).male.Amplitude, outputValidData(indexCondition,indexMuscle).validDataAmplitudes(indexParticipant)];
            elseif idSex == 2
                outputGenders(indexCondition).female.Onset = [outputGenders(indexCondition).female.Onset, outputValidData(indexCondition,indexMuscle).validDataOnsetTimes(indexParticipant)];
                outputGenders(indexCondition).female.Amplitude = [outputGenders(indexCondition).female.Amplitude, outputValidData(indexCondition,indexMuscle).validDataAmplitudes(indexParticipant)];
            else
                disp('error: idSex should be 1 or 2');
            end
        end
    end
end


if flag_calculateMeanAndExtraColums == 1
       spssRow = zeros(length(outputGenders(1).male.Onset) ,length(spssTable.columnLabels));

       for idxM=1:6:length(outputGenders(1).male.Onset)
           spssRow(idxM:idxM+5,1)=[1,2,3,4,5,6];
       end
    positionOnsetLabels=1;
    positionAmplitudeLabels=1+(length(sexNames)*numberOfConditions);
    for indexCondition=1:1:numberOfConditions
        for indexGender=1:1:length(sexNames)
            positionOnsetLabels=positionOnsetLabels+1;
            positionAmplitudeLabels=positionAmplitudeLabels+1;
            if indexGender == 1
                 spssRow(:,positionOnsetLabels) = outputGenders(indexCondition).male.Onset;
                spssRow(:,positionAmplitudeLabels) =  outputGenders(indexCondition).male.Amplitude;
            elseif indexGender ==2
                spssRow(1:length(outputGenders(indexCondition).female.Onset) ,positionOnsetLabels) = outputGenders(indexCondition).female.Onset;
                spssRow(1:length(outputGenders(indexCondition).female.Onset),positionAmplitudeLabels) =  outputGenders(indexCondition).female.Amplitude;
            end
           
        end
    end
    spssTable.data=spssRow;
end
%%
% Write the SPSS table to file
%%

%outputSetFolder
spssFileName = '';
switch flag_dataSet
    case dataSet2022
        spssFileName = 'spssData2022.csv';
    case dataSet2023
        spssFileName = 'spssData2023.csv';        
    otherwise
        assert(0,'Error: Invalid dataset');
end
spssFileName = fullfile(outputSetFolder,'allParticipants',spssFileName);
fid = fopen(spssFileName,'w');

dlm = ',';

%Write the header

assert(length(spssTable.columnLabels) == size(spssTable.data,2),...
       'Error: The number of column labels and data columns should match');

fprintf(fid,'%s',spssTable.columnLabels{1});
for i=2:1:length(spssTable.columnLabels)
    fprintf(fid,',%s',spssTable.columnLabels{i});
end
fprintf(fid,'\n');

for i=1:1:size(spssTable.data,1)
    fprintf(fid,'%1.6f',spssTable.data(i,1));
    for j=2:1:size(spssTable.data,2)
        fprintf(fid,',%1.6f',spssTable.data(i,j));        
    end
    fprintf(fid,'\n');    
end

fclose(fid);


%% OnsetTimes 
% Plot the distribution of the data

maxPlotRows          = 3;
maxPlotCols          = 2;
plotWidthCm          = 26.0; 
plotHeightCm         = 5.0;
plotHorizMarginCm    = 1.5;
plotVertMarginCm     = 1.5;

[subPlotPanel, ...
 pageWidthCm, ...
 pageHeightCm]= ...
      plotConfigGeneric(  maxPlotCols,...
                          maxPlotRows,...
                          plotWidthCm,...
                          plotHeightCm,...
                          plotHorizMarginCm,...
                          plotVertMarginCm);

for indexCondition = 1:1:numberOfConditions
    figDistribution = figure(indexCondition);
    for indexMuscle = firstMuscleBiopacIndex:1:lastMuscleBiopacIndex
        row = ceil(indexMuscle/maxPlotCols);
        col = indexMuscle-(row-1)*maxPlotCols;
       
        subplot('Position',reshape(subPlotPanel(row,col,:),1,4));
        [n,edges] = histcounts(outputValidData(indexCondition,indexMuscle).validDataOnsetTimes,'Normalization','probability');
        

       for indexBin=1:1:length(n)
            nA = n(1,indexBin);
            edgeA = edges(1,indexBin);
            edgeB = edges(1,indexBin+1);            
            fill([0;nA;nA;0;0], [edgeA;edgeA;edgeB;edgeB;edgeA],...
                [1,1,1].*0.75);
            hold on;
       end

    
    %%
    % Make a box and whisker plot beside the probability distribution
    %%
    xOffset = max(n)*1.2;
    xDelta  = max(n)*0.1;
    
    p05 = outputPercentiles(indexCondition).percentilesOnsetTimes(1,indexMuscle);
    p25 = outputPercentiles(indexCondition).percentilesOnsetTimes(2,indexMuscle);
    p50 = outputPercentiles(indexCondition).percentilesOnsetTimes(3,indexMuscle);
    p75 = outputPercentiles(indexCondition).percentilesOnsetTimes(4,indexMuscle);
    p95 = outputPercentiles(indexCondition).percentilesOnsetTimes(5,indexMuscle);
    
    %Plot the whisker: from 5-95%
    plot([1;1].*xOffset,[p05;p95],'-','Color',[0,0,0]);
    hold on;
    plot([1].*xOffset,[p05],'o','Color',[0,0,0],'MarkerFaceColor',[0,0,0]);
    hold on;
    plot([1].*xOffset,[p95],'o','Color',[0,0,0],'MarkerFaceColor',[0,0,0]);
    hold on;
    
    
    %Plot the box: from 25-75%
    xL = xOffset-xDelta;
    xR = xOffset+xDelta;
    fill([xL;xR;xR;xL;xL],[p25;p25;p75;p75;p75],[1,1,1]);
    hold on;
    
    %Plot the median whisker
    plot([xL;xR],[p50;p50],'Color',[0,0,0],'LineWidth',2);
    hold on;
    
    xRR = xOffset+2*xDelta;
        for i=1:1:size(percentileSet,1)
            text(xRR, outputPercentiles(indexCondition).percentilesOnsetTimes(i,indexMuscle), ... 
                 sprintf('%i%s',percentileSet(i,1)*100,'$$^{th}$$'),...
                 'HorizontalAlignment','center');
            hold on;
        end
    
    xlabel('Probability');
    ylabel('OnsetTime [s]');
    titleMuscle = char(muscleNames(indexMuscle));
    titleCondition = char(conditionsToCompare(indexCondition).condition);
    titleCarDirection = char(conditionsToCompare(indexCondition).carDirection);
    textTitle = [titleMuscle,', ', titleCondition ,', ', titleCarDirection];
    title(textTitle);
    box off;
    end 
end

%% Amplitude 
% Plot the distribution of the data

for indexCondition = 1:1:numberOfConditions
    figDistribution = figure(indexCondition+numberOfConditions);
    for indexMuscle = firstMuscleBiopacIndex:1:lastMuscleBiopacIndex
        row = ceil(indexMuscle/maxPlotCols);
        col = indexMuscle-(row-1)*maxPlotCols;
       
        subplot('Position',reshape(subPlotPanel(row,col,:),1,4));
        [n,edges] = histcounts(outputValidData(indexCondition,indexMuscle).validDataAmplitudes,'Normalization','probability');
        
        for indexBin=1:1:length(n)
            nA = n(1,indexBin);
            edgeA = edges(1,indexBin);
            edgeB = edges(1,indexBin+1);            
            fill([0;nA;nA;0;0], [edgeA;edgeA;edgeB;edgeB;edgeA],...
                [1,1,1].*0.75);
            hold on;
        end

%         intervalMiddle = zeros(size(n));
%         for i=2:1:size(edges,2)
%             intervalMiddle(1,i-1) = 0.5.*(edges(1,i)+edges(1,i-1));
%         end
%     
%     fill([n';min(n);min(n)],...
%         [intervalMiddle';max(intervalMiddle);min(intervalMiddle)],...
%          [1,1,1].*0.75);
%     hold on;
%     
    
    %%
    % Make a box and whisker plot beside the probability distribution
    %%
    xOffset = max(n)*1.2;
    xDelta  = max(n)*0.1;
    
    p05 = outputPercentiles(indexCondition).percentilesAmplitudes(1,indexMuscle);
    p25 = outputPercentiles(indexCondition).percentilesAmplitudes(2,indexMuscle);
    p50 = outputPercentiles(indexCondition).percentilesAmplitudes(3,indexMuscle);
    p75 = outputPercentiles(indexCondition).percentilesAmplitudes(4,indexMuscle);
    p95 = outputPercentiles(indexCondition).percentilesAmplitudes(5,indexMuscle);
    
    %Plot the whisker: from 5-95%
    plot([1;1].*xOffset,[p05;p95],'-','Color',[0,0,0]);
    hold on;
    plot([1].*xOffset,[p05],'o','Color',[0,0,0],'MarkerFaceColor',[0,0,0]);
    hold on;
    plot([1].*xOffset,[p95],'o','Color',[0,0,0],'MarkerFaceColor',[0,0,0]);
    hold on;
    
    
    %Plot the box: from 25-75%
    xL = xOffset-xDelta;
    xR = xOffset+xDelta;
    fill([xL;xR;xR;xL;xL],[p25;p25;p75;p75;p75],[1,1,1]);
    hold on;
    
    %Plot the median whisker
    plot([xL;xR],[p50;p50],'Color',[0,0,0],'LineWidth',2);
    hold on;
    
    xRR = xOffset+2*xDelta;
        for i=1:1:size(percentileSet,1)
            text(xRR, outputPercentiles(indexCondition).percentilesAmplitudes(i,indexMuscle), ... 
                 sprintf('%i%s',percentileSet(i,1)*100,'$$^{th}$$'),...
                 'VerticalAlignment','middle',...
                 'HorizontalAlignment','center');
            hold on;
        end
    
    xlabel('Probability');
    ylabel('Amplitude [mV]');
    titleMuscle = char(muscleNames(indexMuscle));
    titleCondition = char(conditionsToCompare(indexCondition).condition);
    titleCarDirection = char(conditionsToCompare(indexCondition).carDirection);
    textTitle = [titleMuscle,', ', titleCondition ,', ', titleCarDirection];
    title(textTitle);
    box off;
    end 
end


%Perform a Wilcoxon ranksum test to test the probability that the two
%distributions are the same.

for indexMuscle = firstMuscleBiopacIndex:1:lastMuscleBiopacIndex
    probabilityOnsetTimes(indexMuscle) = ranksum(outputValidData(1,indexMuscle).validDataOnsetTimes,outputValidData(2,indexMuscle).validDataOnsetTimes);
    probabilityAmplitudes(indexMuscle) = ranksum(outputValidData(1,indexMuscle).validDataAmplitudes,outputValidData(2,indexMuscle).validDataAmplitudes);
end 

