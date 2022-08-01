function [peakIntervals, thresholdLower, thresholdUpper] ...
    = findOnsetUsingAdaptiveThreshold(data, ...
                    lowerPercentileThreshold,...
                    upperThresholdScaling)
%%
% This function will identify peaks of data spanning from a local minimum
% to another local minimum that meet two criteria:
%
%  1. The peak must be in the top lowerPercentileThreshold of all of the
%     data (e.g. the top 0.975 or 97.5% of all data)
%
%  2. The peak must rise above lowerPercentileThreshold by some distance
%     upperThresholdScaling. Here this distance is measured in terms of 
%     the median distance between the data and the lowerPercentileThreshold
%     (ignoring the peaks)
%  
% The first criteria is in place so that the statistics of the data is used
% to pick a threshold for a 'big' value. The second criteria is in place
% to give the user some ability to remove peaks that exceed the threshold
% but are not much bigger than the rest of the data set.
%
% After these peaks are selected the intervals that define each peak are
% expaned from the lowerPercentileThreshold until a local minimum is found.
% Next overlapping or contiguous intervals are merged.
%
% @params data: the 1 x n data vector
%
% @params lowerPercentileThreshold: the percentile which the peak values
%   of the data set must exceed to be considered peaks.
%
% @params upperThresholdScaling: intervals of data are returned that have
%   values that exceed lowerPercentileThreshold and have at least 1 data
%   point that exceeds an upperThreshold. If upperThresholdScaling is set
%   to 0, the upper threshold is the same as the lowerPercentileThreshold.
%   If upperThresholdScaling is set to 1, then the upper threshold is 
%   set to lowerPercentileThreshold + the median distance between the 
%   data and the lowerThreshold.
%
% @returns peakIntervals
%  peakIntervals: an n x 2 vector where each row contains the index of the 
%               beginning and the end of data that exceeds the desired
%               thresholdLower and is not in the lowest cluster
%
% @returns thresholdLower: numerical value of the lower threshold
% @returns thresholdUpper: numerical value of the upper threshold
%
%%

%assert(length(data) >= 100);

%%
%Evaluate the distribution of the data
%%
%intervals = 100;
[nData,dataEdges] = histcounts(data,'Normalization','cdf');
midInterval = 0.5*dataEdges(1,1:(end-1)) ...
            + 0.5*dataEdges(1,2:(end));

%%
% Interpolate the vectors nData and midInterval to get the 
% threshold value that is at the desired percentile. I would use the
% function interp1, except its possible for nData to have repeating values
% which breaks interp1: interp1 requires all values to be unique.
%%
flag_found=0;
index=2;
while(index < length(nData) && flag_found==0)

    if(nData(1,index) >= lowerPercentileThreshold && ...
       nData(1,index-1) <  lowerPercentileThreshold )  

        dy = 0;       
        if(nData(1,index)-nData(1,index-1) > 0)
            dydx = (lowerPercentileThreshold-nData(1,index-1)) ...
                /(nData(1,index)-nData(1,index-1));
            dx = midInterval(1,index)-midInterval(1,index-1);
            dy = dydx*dx;
        end
        thresholdLower = midInterval(1,index-1)+dy;
        flag_found=1;
    else
        index=index+1;
    end
end
assert(flag_found==1);


%To count as a peak, some value within the interval should rise above the
%threshold larger than the median distance between the data set and
%threshold.
medianDistanceToThreshold = median(  thresholdLower-data(data < thresholdLower) );
thresholdUpper = medianDistanceToThreshold*upperThresholdScaling+ thresholdLower;

%%
% Go and get all of the starting and ending points of intervals that
% cross the data thresholdLower
%%
peakIntervals = [];
indexStart=0;
indexEnd = 0;
for index=2:1:size(data,1)    
    if(data(index,1)>= thresholdLower ...
            && data(index,1) > data(index-1,1) ...
            && indexStart == 0)
        indexStart=index;
    end
    if(indexStart ~= 0 && ...
            data(index,1) < thresholdLower && ...
            data(index-1,1) >= thresholdLower)

        if(max(data(indexStart:index,1)) ...
                > (thresholdUpper)  )
            indexEnd = index-1;
            peakIntervals = [peakIntervals; indexStart,indexEnd];
        end
        indexStart=0;
    end    
end

%%
%Widen each interval by decreasing the starting index and increasing the
%ending index until the first local minima is hit
%%

for index=1:1:size(peakIntervals,1)
    
    indexStart = peakIntervals(index,1);
    indexEnd = peakIntervals(index,2);

    while(indexStart > 2 && data(indexStart-1,1) < data(indexStart,1))
        indexStart =indexStart - 1;
    end
    while(indexEnd < (length(data)-1) && data(indexEnd,1) > data(indexEnd+1,1))
        indexEnd =indexEnd + 1;
    end
    peakIntervals(index,:) = [indexStart,indexEnd];

end

%%
% Merge intervals that are within 1 data point of eachother in time
%%
peakIntervalsOrig=peakIntervals;
if(size(peakIntervals,1)>=2)
    peakIntervalsUpd = [];

    index=1;
    indexStart= peakIntervals(index,1);
    index=2;
    
    while index <= size(peakIntervals,1)
        didx = peakIntervals(index,1)-peakIntervals(index-1,2);
        if(didx <= 1 && index < size(peakIntervals,1))
            index=index+1;
        elseif (didx <= 1 && index == size(peakIntervals,1))
            indexEnd = peakIntervals(index,2);
            peakIntervalsUpd = [peakIntervalsUpd; indexStart, indexEnd]; 
            index=index+1;
        elseif (didx > 1 && index == size(peakIntervals,1))
            indexEnd = peakIntervals(index-1,2);
            peakIntervalsUpd = [peakIntervalsUpd; indexStart, indexEnd]; 
            peakIntervalsUpd = [peakIntervalsUpd; peakIntervals(index,:)];
            index=index+1;
        else
            indexEnd = peakIntervals(index-1,2);
            peakIntervalsUpd = [peakIntervalsUpd; indexStart, indexEnd];        
            indexStart = peakIntervals(index,1);
            index=index+1;            
        end
    
    end
    
    peakIntervals=peakIntervalsUpd;
end

flag_debug=0;
if(flag_debug==1)
    figDebug=figure;
    n0=1;
    n1=length(data);

    fill([n0;n1;n1;n0;n0],[0;0;1;1;0].*thresholdLower,[1,1,1].*0.75,...
         'EdgeColor','none');
    hold on;

    plot([n0;n1],[1;1].*(thresholdUpper),...
         '--','Color',[0,0,0]);

    plot(data,'Color',[0,0,0]);
    hold on;

    maxVal=max(data);
    for index=1:1:size(peakIntervals,1)
        i0 = peakIntervals(index,1);
        i1 = peakIntervals(index,2);
        plot([i0;i1;i1;i0;i0],[0;0;1;1;0].*maxVal,'Color',[1,0,0]);
        hold on;
    end
    box off;
    xlabel('Index');
    ylabel('Value');
    title('Data, Threshold, and Peak Intervals')

end

