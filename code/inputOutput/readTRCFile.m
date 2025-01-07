function [trcMetaData, trcFrameTime, trcMarkerData] = readTRCFile(pathAndFileName)
%%
%
%
%%
success=0;

fid = fopen(pathAndFileName,'r');
assert(fid ~= -1, ['Error: fopen failed to open ',pathAndFileName]);


trcMetaData = struct('fileType','','fileName','','DataRate','','CameraRate','',...
    'NumFrames','','NumMarkers','','Units','','OrigDataRate','',...
    'OrigDataStartFrame','','OrigNumFrames','');

fieldList = {'DataRate','CameraRate','NumFrames','NumMarkers','Units',...
    'OrigDataRate',	'OrigDataStartFrame','OrigNumFrames'};

line=fgetl(fid);
    tag = 'PathFileType';
    i0  = strfind(line,tag);
    i0  = i0+length(tag);

    tag = ')';
    i1  = strfind(line,tag);
    i1  = i1+length(tag);

    assert(contains(strtrim(line(1,i0:i1)),'(X/Y/Z)'),...
           'Error: this script can only read (X/Y/Z) data');

    trcMetaData.fileType = strtrim(line(1,i0:i1));    
    trcMetaData.fileName = strtrim(line(i1:end));

line=fgetl(fid);  

%Check that the header contains the correct fields in the correct order
tabStr = sprintf('\t');
for i=1:1:length(fieldList)    
    i1 = strfind(line,[tabStr,fieldList{i},tabStr]);
    if(isempty(i1)==1)
      i1 = strfind(line,[tabStr,fieldList{i}]);
      i1 = max(i1);
    end
    if(isempty(i1)==1)
      i1 = strfind(line,[fieldList{i},tabStr]);
      i1 = min(i1);
    end
    
    assert(isempty(i0)==0 && length(i1)==1);
    if(i>1)
        assert(i1 > i0);
    end
    i0=i1;
end

line=fgetl(fid);
data = sscanf(line,'%f %f %d %d %s %f %d %d');

trcMetaData.DataRate    = data(1,1);
trcMetaData.CameraRate  = data(2,1);
trcMetaData.NumFrames   = uint64(data(3,1));
trcMetaData.NumMarkers  = uint64(data(4,1));

idx=5;
for i=1:1:(length(data)-length(fieldList)+1)
    trcMetaData.Units = [trcMetaData.Units,char(data(idx,1))];
    idx=idx+1;
end

trcMetaData.OrigDataRate= data(idx,1);
idx=idx+1;
trcMetaData.OrigDataStartFrame = uint64(data(idx,1));
idx=idx+1;
trcMetaData.OrigNumFrames      = uint64(data(idx,1));


nMarkers = trcMetaData.NumMarkers;
nFrames  = trcMetaData.NumFrames;

trcFrameTime(2)=struct('value',zeros(nFrames,1),'name','');

trcMarkerData(nMarkers)=...
               struct('r0M0',zeros(nFrames,3),'markerName','','columnNames',{''});


header1Format = '%s\t%s\t%s';
for idxMarker=2:1:nMarkers
    header1Format = [header1Format,'\t\t\t%s'];
end

line=fgetl(fid);
%data1Header = sscanf(line,header1Format);
data1Header=textscan(line,'%s');

header2Format = '\t';
lineFormat    = '%f\t%f';
for idxMarker=1:1:nMarkers
    header2Format   = [header2Format,'\t%s\t%s\t%s'];
    lineFormat      = [lineFormat,'\t%f\t%f\t%f'];
end

line=fgetl(fid);
%data2Header = sscanf(line,header2Format);
data2Header=textscan(line,'%s');

trcFrameTime(1).name = data1Header{1}{1};
trcFrameTime(2).name = data1Header{1}{2};

for indexMarker=1:1:nMarkers
    trcMarkerData(indexMarker).markerName = data1Header{1}{2+indexMarker};
    i0 = (indexMarker-1)*3+1;
    i1 = i0+2;
    indexColumn=1;
    for i=i0:1:i1
        trcMarkerData(indexMarker).columnNames{indexColumn}= data2Header{1}{i};
        indexColumn=indexColumn+1;
    end
    trcMarkerData(indexMarker).r0M0 = zeros(nFrames,3);
end
line=fgetl(fid);



indexFrame=1;
for indexLine=1:1:nFrames
    line=fgetl(fid);
    %dataLine = sscanf(line,lineFormat);
    dataLine = textscan(line,'%f');

    trcFrameTime(1).value(indexLine,1)=uint64(dataLine{1}(1,1));
    trcFrameTime(2).value(indexLine,1)=       dataLine{1}(2,1);

    for indexMarker=1:1:nMarkers 
        i0 = (indexMarker-1)*3+3;
        i1 = i0+2;

        trcMarkerData(indexMarker).r0M0(indexLine,1:3)=dataLine{1}(i0:i1,1)';
    end
    indexFrame=indexFrame+1;
end


fclose(fid);

success=1;
