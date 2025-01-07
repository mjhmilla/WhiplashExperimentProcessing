function rowData = getRowData(line,delimiter)


dlmLocation=[strfind(line,delimiter),length(line)];
indexComma=1;
rowData = cell(1,length(dlmLocation));

indexCell=1;
while indexComma<=length(dlmLocation)
    i0=1;
    if(indexComma>1)
        i0 = dlmLocation(1,indexComma-1)+1;    
    end
    if(indexComma < length(dlmLocation))
      i1 = dlmLocation(1,indexComma)-1;
    else
      i1 = dlmLocation(1,indexComma);
    end
    indexComma=indexComma+1;

    fieldValue = strtrim(line(i0:1:i1));
    whiteSpace = strfind(fieldValue,' ');
    fieldValue(whiteSpace)='_';

    if(isnan(str2double(fieldValue)) == 0)
        rowData(1,indexCell) =num2cell(str2double(fieldValue));
    else
        if(isempty(fieldValue)==0)
            rowData(1,indexCell) = cellstr(fieldValue);
        end
    end
    
    indexCell=indexCell+1;
    
end