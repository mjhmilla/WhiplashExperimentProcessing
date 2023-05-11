function [validIdOnset, validIdAmplitude, validDataOnsetTimes, validDataAmplitudes] = ...
    christaExtractValidData( idDataOnset,idDataAmplitude, onsetData, amplitudeData, ...
                      maxAllowedNormEMGAmplitude,maxAllowedOnsetTime,...
                      noDataNumber, flag_removeNegativeValues)

assert(size(idDataOnset,1) == size(onsetData,1),...
    'Error: idData and onsetData must have the same size');

assert(size(amplitudeData,1) == size(onsetData,1),...
    'Error: amplitudeData and onsetData must have the same size');

assert(size(idDataOnset,2)==1,       ...
    'Error idData should have only 1 column');
assert(size(idDataAmplitude,2)==1,       ...
    'Error idData should have only 1 column');
assert(size(amplitudeData,2)==1,...
    'Error amplitudeData should have only 1 column');
assert(size(onsetData,2)==1,    ...
    'Error onsetData should have only 1 column');

assert(isnan(noDataNumber)==0,...
    'Error: noDataNumber must be a number (other than nan).');

validIdOnset = []; 
validIdAmplitude = [];
validDataOnsetTimes = [];
validDataAmplitudes = [];

for i=1:1:length(idDataOnset)

    isValidOnset = 1;
    isValidAmplitude = 1;

    
    %The guantlet of if conditions begins ...
    if(onsetData(i,1) >= maxAllowedOnsetTime)
        isValidOnset = 0;
    end
    if(amplitudeData(i,1)>= maxAllowedNormEMGAmplitude)
        isValidAmplitude = 0;
    end
    if onsetData(i,1)==noDataNumber
        isValidOnset= 0;
    end
    if amplitudeData(i,1) == noDataNumber
        isValidAmplitude =0;
    end
    if(flag_removeNegativeValues == 1)
        if(onsetData(i,1) < 0)
            isValidOnset=0;
        end
        if(amplitudeData(i,1) < 0)
            isValidAmplitude=0;
        end

    end

    %if the data is valid, append it

    if(isValidOnset == 1)
        validIdOnset = [validIdOnset;idDataOnset(i,1)];
        validDataOnsetTimes = [validDataOnsetTimes; onsetData(i,1)];
    end
    if (isValidAmplitude == 1)
        validIdAmplitude = [validIdAmplitude;idDataAmplitude(i,1)];
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

