function blockIntervals = condenseIndexSeriesToBlocks(indexSeries, ...
                                                minimumIndexGap)

flag_inSignalBlock =  0;
blockIntervals = [];
blockStart  = 0;
blockEnd    = 0;
for i=2:1:length(indexSeries)
    gap = indexSeries(i,1)-indexSeries(i-1,1);
    if(gap <= minimumIndexGap)
        if(flag_inSignalBlock==0)
            blockStart = i-1;        
            flag_inSignalBlock = 1;
        end
    end

    if(gap > minimumIndexGap)
        if(flag_inSignalBlock == 1)
            blockEnd = i-1;
    
            if(indexSeries(blockEnd,1)-indexSeries(blockStart,1) > minimumIndexGap)
                blockIntervals = [blockIntervals;...
                    indexSeries(blockStart,1),indexSeries(blockEnd,1)];
            end                    
        end
        flag_inSignalBlock=0;
    end
end

if(flag_inSignalBlock == 1)
    blockEnd = length(indexSeries);

    if(indexSeries(blockEnd,1)-indexSeries(blockStart,1) > minimumIndexGap)
        blockIntervals = [blockIntervals;...
            indexSeries(blockStart,1),indexSeries(blockEnd,1)];
    end                    
end

