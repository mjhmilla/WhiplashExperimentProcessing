function interpolatedIntervals = getAllInterpolatedIntervals(...
    structWithInterpolatedField)

interpolatedIntervals = [];

for index=1:1:length(structWithInterpolatedField)
    interpolatedIntervalsIndex = ...
    getInterpolatedIntervals(...
        structWithInterpolatedField(index).interpolated);

    if(isempty(interpolatedIntervalsIndex)==0)

        if(isempty(interpolatedIntervals)==1)
            col1 = ones(size(interpolatedIntervalsIndex,1),1);
            interpolatedIntervals = [interpolatedIntervalsIndex, index.*col1];
        else

            for j=1:1:size(interpolatedIntervalsIndex,1)
                indexMergeInterval=[];
                for k=1:1:size(interpolatedIntervals,1)
        
                    %existing interval contains candidate
                    if(    interpolatedIntervals(k,1) <= interpolatedIntervalsIndex(j,1) ...
                        && interpolatedIntervals(k,2) >= interpolatedIntervalsIndex(j,2) )
                        
                        if(sum(indexMergeInterval == k)==0)
                            indexMergeInterval=[indexMergeInterval;k];
                        end
                    end
                    %candidate interval contains existing
                    if(    interpolatedIntervals(k,1) >= interpolatedIntervalsIndex(j,1) ...
                        && interpolatedIntervals(k,2) <= interpolatedIntervalsIndex(j,2))
        
                        if(sum(indexMergeInterval == k)==0)
                            indexMergeInterval=[indexMergeInterval;k];
                        end
                    end
                    %existing interval overlaps left of existing
                    if(    interpolatedIntervals(k,1) <= interpolatedIntervalsIndex(j,1) ...
                        && interpolatedIntervals(k,2) >= interpolatedIntervalsIndex(j,1))
        
                        if(sum(indexMergeInterval == k)==0)
                            indexMergeInterval=[indexMergeInterval;k];
                        end
                    end
                    %existing interval overlaps right of existing
                    if(    interpolatedIntervals(k,1) <= interpolatedIntervalsIndex(j,2) ...
                        && interpolatedIntervals(k,2) >= interpolatedIntervalsIndex(j,2))
                        if(sum(indexMergeInterval == k)==0)
                            indexMergeInterval=[indexMergeInterval;k];
                        end
                    end
        
                end
        
                if(isempty(indexMergeInterval) == 0)
                    indexSubInterval = interpolatedIntervalsIndex(j,1:2);
                    for z=1:1:size(indexMergeInterval)
                        k=indexMergeInterval(z,1);
                        idxStart = min( interpolatedIntervals(k,1),...
                                        indexSubInterval(1,1));
                        idxEnd   = max( interpolatedIntervals(k,2),...
                                        indexSubInterval(1,2));
                        indexSubInterval=[idxStart, idxEnd, nan];
                    end
                    interpolatedIntervals(indexMergeInterval,:)= ...
                        ones(size(indexMergeInterval,1),3).*nan;
                    interpolatedIntervals(indexMergeInterval(1,1),:)=indexSubInterval;
                    interpolatedIntervals= ...
                        interpolatedIntervals(~isnan(interpolatedIntervals(:,1)),:);
                else 
                    interpolatedIntervals = [interpolatedIntervals;...
                        interpolatedIntervalsIndex(j,:), index];
                end
            end
            [val idxSorted] = sort(interpolatedIntervals(:,1));
            interpolatedIntervals=interpolatedIntervals(idxSorted,:);
        end
        

    end


end

%Merge intervals that are side by side
if(isempty(interpolatedIntervals)==0)
    indexStart=interpolatedIntervals(1,1);
    interpolatedIntervalsMerged = [];
    for i=1:1:(size(interpolatedIntervals,1)-1)
        if(interpolatedIntervals(i,2)+1 < interpolatedIntervals(i+1,1))
            indexEnd = interpolatedIntervals(i,2);
            interpolatedIntervalsMerged = [interpolatedIntervalsMerged;...
                indexStart, indexEnd];
            indexStart = interpolatedIntervals(i+1,1);
        end
    end
    indexEnd = interpolatedIntervals(end,2);
    interpolatedIntervalsMerged = [interpolatedIntervalsMerged;...
                indexStart, indexEnd];
    interpolatedIntervals=interpolatedIntervalsMerged;
end
