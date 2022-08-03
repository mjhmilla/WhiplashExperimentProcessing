function success = writeTRCFile(pathAndFileName, frameTimeData, ...
    rigidBodyMarkerData, motiveDataHeader)
%%
%
%
%%

success=0;

if(contains(pathAndFileName,'.')==0)
  pathAndFileName = [pathAndFileName,'.trc'];
end

idx = strfind(pathAndFileName,'/');
fileName = '';
if(isempty(idx))
  idx = strfind(pathAndFileName,'\');
end
if(isempty(idx)==0)
  fileName = pathAndFileName(1,(max(idx)+1):1:end);
else 
  fileName = pathAndFileName;
end


fid = fopen(pathAndFileName,'w');


nFrames     = size(rigidBodyMarkerData(1).r0M0,1);
nMarkers    = length(rigidBodyMarkerData);
sampleRate  = motiveDataHeader.Export_Frame_Rate;
unitsLength = motiveDataHeader.Length_Units;
assert(strcmp(unitsLength,'Meters'));
unitsLength = 'm';


%%
% Write the file header
%%
fprintf(fid, 'PathFileType\t4\t(X/Y/Z)\t%s\n', fileName);
fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n',...
  'DataRate','CameraRate','NumFrames','NumMarkers',...
  'Units','OrigDataRate','OrigDataStartFrame','OrigNumFrames');
fprintf(fid,'%i\t%i\t%i\t%i\t%s\t%i\t%i\t%i\n',...
  sampleRate,sampleRate,nFrames,nMarkers,...
  unitsLength,sampleRate,1,nFrames);

  
%%
% Write the marker header
%%

fprintf(fid,'Frame#\tTime\t');
for i=1:1:nMarkers
  uniqueMarkerName = [ rigidBodyMarkerData(i).parentName,'_',...
                       rigidBodyMarkerData(i).markerName];

  if(i < nMarkers)
    fprintf(fid,'%s\t\t\t',uniqueMarkerName);
  else
    fprintf(fid,'%s\t\t\n',uniqueMarkerName);    
  end
end


%%
%Write the column header
%%
fprintf(fid,'\t');
for i=1:1:nMarkers
  fprintf(fid,'\tX%i\tY%i\tZ%i',i,i,i);
end
fprintf(fid,'\n');


%%
%Write all of the marker data
%%
for i=1:1:nFrames

  fprintf(fid,'%i\t%1.9f',frameTimeData(i,1),frameTimeData(i,2));
  for j=1:1:nMarkers
    fprintf(fid,'\t%1.9f\t%1.9f\t%1.9f',...
      rigidBodyMarkerData(j).r0M0(i,1),...
      rigidBodyMarkerData(j).r0M0(i,2),...
      rigidBodyMarkerData(j).r0M0(i,3));
  end
  fprintf(fid,'\n');

end
fclose(fid);

success=1;
