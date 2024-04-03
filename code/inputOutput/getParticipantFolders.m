function [inputFolders,outputFolders] = ...
	getParticipantFolders(participantId, dataSetFolder,outputSetFolder)

idStr = num2str(participantId);
if(length(idStr)<2)
    idStr = ['0',idStr];
end

participantFolder = ['participant',idStr];



inputFolders.car = ...
    fullfile(dataSetFolder,participantFolder,'car');

inputFolders.carBiopac = ...
    fullfile(dataSetFolder,participantFolder,'car','biopac');

inputFolders.carOptiTrack = ...
    fullfile(dataSetFolder,participantFolder,'car','optitrack');

inputFolders.mvc = ...
    fullfile(dataSetFolder,participantFolder,'mvc');

inputFolders.mvcBiopac = ...
    fullfile(dataSetFolder,participantFolder,'mvc','biopac');

inputFolders.mvcPhotos = ...
    fullfile(dataSetFolder,participantFolder,'mvc','photos');


outputFolders.common = fullfile(outputSetFolder,'allParticipants');

outputFolders.car = ...
    fullfile(outputSetFolder,participantFolder,'car');

outputFolders.carBiopac = ...
    fullfile(outputSetFolder,participantFolder,'car','biopac');

outputFolders.carOptiTrack = ...
    fullfile(outputSetFolder,participantFolder,'car','optitrack');

outputFolders.mvc = ...
    fullfile(outputSetFolder,participantFolder,'mvc');

outputFolders.mvcBiopac = ...
    fullfile(outputSetFolder,participantFolder,'mvc','biopac');

outputFolders.mvcPhotos = ...
    fullfile(outputSetFolder,participantFolder,'mvc','photos');