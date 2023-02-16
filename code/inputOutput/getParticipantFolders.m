function [inputFolders,outputFolders] = ...
	getParticipantFolders(participantId, dataFolder,outputFolder)

idStr = num2str(participantId);
if(length(idStr)<2)
    idStr = ['0',idStr];
end

participantFolder = ['participant',idStr];


inputFolders.carBiopac = ...
    fullfile(dataFolder,participantFolder,'car','biopac');

inputFolders.carOptiTrack = ...
    fullfile(dataFolder,participantFolder,'car','optitrack');

outputFolders.carBiopac = ...
    fullfile(outputFolder,participantFolder,'car','biopac');

outputFolders.carOptiTrack = ...
    fullfile(outputFolder,participantFolder,'car','optitrack');