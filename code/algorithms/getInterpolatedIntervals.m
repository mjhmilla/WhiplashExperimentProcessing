function interpolatedIntervals = getInterpolatedIntervals(interpolationFlag)

interpolatedIndices=find(interpolationFlag==1);
interpolatedIntervals = [];

if(size(interpolatedIndices,1)>0)
    interpolatedIndicesDiff = diff(interpolatedIndices);    
    interpolatedIntervals = [];
    idxStart = interpolatedIndices(1,1);
    for(i=1:1:size(interpolatedIndicesDiff))
        if(interpolatedIndicesDiff(i,1) > 1)
            idxEnd = interpolatedIndices(i,1);
            interpolatedIntervals = [interpolatedIntervals; idxStart, idxEnd];
            idxStart = interpolatedIndices(i+1,1);
        end
    end
    idxEnd = interpolatedIndices(end,1);
    interpolatedIntervals = [interpolatedIntervals; idxStart, idxEnd];
end