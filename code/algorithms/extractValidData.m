function [validId, validDataOnsetTimes, validDataAmplitudes] = ...
    extractValidData( idData, onsetData, amplitudeData, ...
                      maxAllowedNormEMGAmplitude,maxAllowedOnsetTime,...
                      noDataNumber, flag_removeNegativeValues)

assert(size(idData,1) == size(onsetData,1),...
    'Error: idData and onsetData must have the same size');

assert(size(amplitudeData,1) == size(onsetData,1),...
    'Error: amplitudeData and onsetData must have the same size');

assert(size(idData,2)==1,       ...
    'Error idData should have only 1 column');
assert(size(amplitudeData,2)==1,...
    'Error amplitudeData should have only 1 column');
assert(size(onsetData,2)==1,    ...
    'Error onsetData should have only 1 column');

assert(isnan(noDataNumber)==0,...
    'Error: noDataNumber must be a number (other than nan).');

validId = []; 
validDataOnsetTimes = [];
validDataAmplitudes = [];

for i=1:1:length(idData)

    isValid = 1;
    
    %The guantlet of if conditions begins ...
    if(onsetData(i,1) >= maxAllowedOnsetTime)
        isValid = 0;
    end
    if(amplitudeData(i,1)>= maxAllowedNormEMGAmplitude)
        isValid = 0;
    end
    if(onsetData(i,1)==noDataNumber || amplitudeData(i,1) == noDataNumber)
        isValid= 0;
    end
    if(flag_removeNegativeValues == 1)
        if(onsetData(i,1) < 0)
            isValid=0;
        end
        if(amplitudeData(i,1) < 0)
            isValid=0;
        end

    end

    %if the data is valid, append it

    if(isValid == 1)
        validId = [validId;idData(i,1)];
        validDataOnsetTimes = [validDataOnsetTimes; onsetData(i,1)];
        validDataAmplitudes = [validDataAmplitudes; amplitudeData(i,1)];
    end
end


% indexValidData = find(data ~= noDataNumber);
% 
% validData = data(indexValidData);
% 
% if(flag_removeNegativeValues==1)
%     signsOfArray = sign(data);
%     indexValidData = find(signsOfArray == 1);
%     validData = data(indexValidData);
% end

