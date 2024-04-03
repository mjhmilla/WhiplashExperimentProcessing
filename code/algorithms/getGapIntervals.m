function gapIntervals = getGapIntervals(data)


dataNan=find(isnan(data));
gapIntervals = [];

if(size(dataNan,1)>0)
    dataNanDiff = diff(dataNan);    
    gapIntervals = [];
    idxStart = dataNan(1,1);
    for(i=1:1:size(dataNanDiff))
        if(dataNanDiff(i,1) > 1)
            idxEnd = dataNan(i,1);
            gapIntervals = [gapIntervals; idxStart, idxEnd];
            idxStart = dataNan(i+1,1);
        end
    end
    idxEnd = dataNan(end,1);
    gapIntervals = [gapIntervals; idxStart, idxEnd];
end