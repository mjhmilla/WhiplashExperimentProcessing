function [trialCondition, trialBlock, flag_ignoreTrial] = ...
        getTrialConditionAndBlock(fileName,participantCarData)

trialCondition = '-';
trialBlock     = '-';
flag_ignoreTrial    =0;


indexPoint   = strfind(fileName,'.');	
assert(length(indexPoint)==1,'Error: fileName breaks expected convention');

indexZero    = min(strfind(fileName,'0'));
assert(length(indexZero)==1,'Error: fileName breaks expected convention');

fileNumber = str2double( fileName(indexZero:1:(indexPoint-1)) );

found=0;

if(isempty(participantCarData.blockFileNumbers)==0 ...
        && sum(sum(isnan(participantCarData.blockFileNumbers)))==0)


    if(max(max(participantCarData.blockFileNumbers)) > 0)
        %There is data in participantCarData.blockFileNumbers and
        %its non zero. Lets see if this file number shows up in any of
        %the blocks

        for i=1:1:size(participantCarData.blockFileNumbers,1)
            indexStart = participantCarData.blockFileNumbers(i,1);
            indexEnd   = participantCarData.blockFileNumbers(i,2);
            
            if(fileNumber >= indexStart && fileNumber <= indexEnd)

                assert(found==0,'Error: trial belongs to more than one block');

                trialCondition = participantCarData.condition{i,1};
                trialBlock = participantCarData.block{i,1};
                flag_ignoreTrial=0;
                found=1;


                if(isempty(participantCarData.ignoreTheseFileNumbers)==0)
                    for k=1:1:length(participantCarData.ignoreTheseFileNumbers)
                        indexError=participantCarData.ignoreTheseFileNumbers(k)-fileNumber;
                        if(abs(indexError)<1e-6)
                            flag_ignoreTrial=1;
                        end
                    end
                end

            end
        end
    end
end




