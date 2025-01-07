function [opensimFolders] = ...
	getParticipantOpensimFolders(participantId, opensimFolder)

idStr = num2str(participantId);
if(length(idStr)<2)
    idStr = ['0',idStr];
end

participantFolder = ['participant',idStr];

opensimFolders.ik = ...
    fullfile(opensimFolder,participantFolder,'ik');

opensimFolders.analyze = ...
    fullfile(opensimFolder,participantFolder,'analyze');

opensimFolders.postprocessing = ...
    fullfile(opensimFolder,participantFolder,'postprocessing');

