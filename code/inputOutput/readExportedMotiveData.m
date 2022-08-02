function [columnData,header] = readExportedMotiveData(csvFileName)

fid = fopen(csvFileName);

numberOfHeaderLines = 0;
line = fgetl(fid);
numberOfHeaderLines=numberOfHeaderLines+1;
%%
% Read in the trial header
%%
commaLocation=strfind(line,',');
indexComma=1;
while indexComma<length(commaLocation)
    i0=1;
    if(indexComma>1)
        i0 = commaLocation(1,indexComma-1)+1;    
    end
    i1 = commaLocation(1,indexComma)-1;
    indexComma=indexComma+1;

    fieldName = strtrim(line(i0:1:i1));
    whiteSpace = strfind(fieldName,' ');
    fieldName(whiteSpace)='_';

    i0 = commaLocation(1,indexComma-1)+1;
    i1 = commaLocation(1,indexComma)-1;
    indexComma=indexComma+1;

    fieldValue = strtrim(line(i0:1:i1));
    whiteSpace = strfind(fieldValue,' ');
    fieldValue(whiteSpace)='_';

    if(isnan(str2double(fieldValue))==0)
        header.(fieldName) =str2double(fieldValue);
    else
        header.(fieldName) = fieldValue;
    end
    
end


line=fgetl(fid);
numberOfHeaderLines=numberOfHeaderLines+1;

assert(isempty(line)==1);

%%
% Read in each column header
%%

line = fgetl(fid);
numberOfHeaderLines=numberOfHeaderLines+1;

rowData = getRowData(line,',');
columnData(length(rowData)) = ...
    struct('Type','','Name','','ID','',...
    'Measure','','Coordinate','','data',[]);

%Get the column headers
colHeaderFields = {'Type','Name','ID'};
for indexFields=1:1:length(colHeaderFields)
    if(indexFields > 1)
        line = fgetl(fid);
        numberOfHeaderLines=numberOfHeaderLines+1;

        rowData = getRowData(line,',');
    end
    assert(contains(rowData{1,2},colHeaderFields{indexFields}));
    for indexColumn=3:1:length(rowData)
        columnData(indexColumn).(colHeaderFields{indexFields}) ...
            = rowData{1,indexColumn};
    end
end

%Measure
line = fgetl(fid);
numberOfHeaderLines=numberOfHeaderLines+1;

rowData = getRowData(line,',');
assert(length(rowData)==length(columnData));
for indexColumn=1:1:length(rowData)
    columnData(indexColumn).Measure = rowData{1,indexColumn};
end

%Coordinate
line = fgetl(fid);
numberOfHeaderLines=numberOfHeaderLines+1;

rowData = getRowData(line,',');
assert(length(rowData)==length(columnData));
for indexColumn=1:1:length(rowData)
    columnData(indexColumn).Coordinate = rowData{1,indexColumn};
end

%Data

fclose(fid);

data = readmatrix(csvFileName,"FileType","text","Delimiter",",",...
        "NumHeaderLines",numberOfHeaderLines);

assert(length(columnData)==size(data,2));



for indexColumn=1:1:length(columnData)
    columnData(indexColumn).data = data(:,indexColumn);
end

% nDataRow=0;
% while(ischar(line))
%     line = fgetl(fid);
%     nDataRow=nDataRow+1;
%     if(ischar(line))        
%         rowData = getRowData(line,',');
%         assert(length(rowData)==length(columnData));
%         for indexColumn=1:1:length(rowData)
%             entry = rowData{1,indexColumn};
%             if(isempty(entry))
%                 entry=nan;
%             end
%             columnData(indexColumn).data = ...
%                 [columnData(indexColumn).data; entry];
%         end
%     end
% end







