function [participantEmgData, listOfFilesToProcess] ...
        = updateParticipantEmgDataFileNames(participantEmgData, ...
                                            filesInCarBiopacFolder, ...
                                            indexOfMatFilesInBiopacFolder, ...
                                            participantCarMetaData)


indexMatFile = indexOfMatFilesInBiopacFolder;
indexFileToProcess = 1;
listOfFilesToProcess =[];
for indexCondition = 1:1:length(participantCarMetaData.condition)
    fileNumberBlockStart = participantCarMetaData.blockFileNumbers(indexCondition,1);
    fileNumberBlockEnd   = participantCarMetaData.blockFileNumbers(indexCondition,2);

    if(~isnan(fileNumberBlockEnd) && ~isnan(fileNumberBlockStart))
        for indexFileInBlock = fileNumberBlockStart:1:fileNumberBlockEnd
            flag_fileFound = 0;
            fileNameSubStr = ['0',num2str(indexFileInBlock),'.mat'];
    
            for indexFile = 1:1:length(indexMatFile)
    
                if(contains(filesInCarBiopacFolder(indexMatFile(indexFile,1)).name ,fileNameSubStr))
                    flag_fileFound=1;
                    listOfFilesToProcess = [listOfFilesToProcess,indexFileToProcess];
                    participantEmgData(indexFileToProcess).filePath = ...
                        filesInCarBiopacFolder(indexMatFile(indexFile,1)).folder;
                    participantEmgData(indexFileToProcess).fileName = ...
                        filesInCarBiopacFolder(indexMatFile(indexFile,1)).name;
                    participantEmgData(indexFileToProcess).fileNumber = indexFileInBlock;
                    participantEmgData(indexFileToProcess).flag_ignoreTrial = 0;
    
                    if(isempty(participantCarMetaData.ignoreTheseFileNumbers)==0)
                        for indexIgnoreFile=1:1:length(participantCarMetaData.ignoreTheseFileNumbers)  
                            fileNumberToIgnore = participantCarMetaData.ignoreTheseFileNumbers(1,indexIgnoreFile);
                            if(indexFileInBlock==fileNumberToIgnore)
                                participantEmgData(indexFileToProcess).flag_ignoreTrial=1;
                            end
                        end
                    end
    
                end
    
            end
            if(flag_fileFound==0)
                flag_printWarning=1;
                if(isempty(participantCarMetaData.ignoreTheseFileNumbers)==0)
                    for i=1:1:length(participantCarMetaData.ignoreTheseFileNumbers)
                        ignoreTrialNumber = participantCarMetaData.ignoreTheseFileNumbers(1,i);
                        if(ignoreTrialNumber==participantEmgData(indexFileToProcess).fileNumber)
                            flag_printWarning=0;
                        end
                    end
                end
                if(flag_printWarning==1)
                    fprintf('  Missing: file number %i of (%s, %s)\n',...
                        indexFileInBlock,...
                        participantCarMetaData.condition{indexCondition,1},...
                        participantCarMetaData.block{indexCondition,1});
                end
            end
            indexFileToProcess=indexFileToProcess+1;        
        end
    end
end
here=1;