function [peakIntervals, peakMiddleThresholds, peakMaximumThresholds] ...
    = findOnsetUsingAdaptiveThreshold(data, ...
                    peakMiddlePercentileThreshold,...
                    peakMaximumThresholdScaling,...
                    peakBaseThresholdScaling,...
                    minimumSamplesBetweenIntervals,...
                    flag_plotDetails)
%%
% This function will identify peaks 
%
% After these peaks are selected the intervals that define each peak are
% expaned from the peakMiddlePercentileThreshold until a local minimum is found.
% Next overlapping or contiguous intervals are merged.
%
% @params data: the 1 x n data vector
%
% @params peakMiddlePercentileThreshold: the percentile which the peak 
%   values of the data set must exceed to be considered peaks. The 
%   numerical value that corresponds to this threshold is the
%   peakMiddleThreshold.
%
% @params peakMaximumThresholdScaling: this value is used to calculate a
%   maximum value that candidate peaks must exceed to be considered peaks.
%   If peakMaximumThresholdScaling is set to 0, then the maximum value is 
%   identical to peakMiddlePercentileThreshold. If 
%   peakMiddlePercentileThreshold is 1, then the maximum value is the sum
%   of peakMiddlePercentileThreshold and the median gap between the data
%   and the value that corresponds to peakMiddlePercentileThreshold.
%
% @params peakBaseThresholdScaling: once a peak is identified, the times
%    the peak begins and ends are defined as being the times at which the
%    value of the peak are some fraction of peakMiddleThreshold. 
%
% @params minimumSamplesBetweenIntervals: if two intervals have fewer than
%    minimumSamplesBetweenIntervals between them then the two intervals are
%    merged into one.
%
% @returns peakIntervals
%  peakIntervals: an n x 2 vector where each row contains the index of the 
%               beginning and the end of data that exceeds the desired
%               peakMiddleThreshold and is not in the lowest cluster
%
% @returns peakMiddleThresholdPercentile: numerical value of the lower threshold
% @returns peakMaximumThreshold: numerical value of the upper threshold
%
%%

%assert(length(data) >= 100);

if(flag_plotDetails==1)
    figDebug=figure;
    subplot(2,1,1);
    plot(data,'b','DisplayName','Raw Input');
    hold on;
    xlabel('Index');
    ylabel('Value')
end

dataMedian=median(data);
data = data-dataMedian;
data = abs(data);

if(flag_plotDetails==1)
    subplot(2,1,1);
    plot(data,'k','DisplayName','Input');
    xlabel('Index');
    ylabel('Value')
end


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

    if(nData(1,index) >= peakMiddlePercentileThreshold && ...
       nData(1,index-1) <  peakMiddlePercentileThreshold )  

        dy = 0;       
        if(nData(1,index)-nData(1,index-1) > 0)
            dydx = (peakMiddlePercentileThreshold-nData(1,index-1)) ...
                /(nData(1,index)-nData(1,index-1));
            dx = midInterval(1,index)-midInterval(1,index-1);
            dy = dydx*dx;
        end
        peakMiddleThreshold = midInterval(1,index-1)+dy;
        flag_found=1;
    else
        index=index+1;
    end
end
assert(flag_found==1);


%To count as a peak, some value within the interval should rise above the
%threshold larger than the median distance between the data set and
%threshold.
medianDistanceToThreshold = ...
    median(  peakMiddleThreshold ...
    -data(data < peakMiddleThreshold) );

peakMaximumThreshold = ...
    medianDistanceToThreshold*peakMaximumThresholdScaling...
               + peakMiddleThreshold;
baseThreshold = peakBaseThresholdScaling*peakMiddleThreshold;


%%
% Go and get all of the starting and ending points of intervals that
% cross the data peakMiddleThreshold
%%
peakIntervals = [];
indexStart=0;
indexEnd = 0;
for index=2:1:size(data,1)    
    if(data(index,1)>= peakMiddleThreshold ...
            && data(index,1) > data(index-1,1) ...
            && indexStart == 0)
        indexStart=index;
    end
    if(indexStart ~= 0 && ...
            data(index,1) < peakMiddleThreshold && ...
            data(index-1,1) >= peakMiddleThreshold)

        if(max(data(indexStart:index,1)) ...
                > (peakMaximumThreshold)  )
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

%     while(indexStart > 2 && data(indexStart-1,1) < data(indexStart,1))
%         indexStart =indexStart - 1;
%     end
%     while(indexEnd < (length(data)-1) && data(indexEnd,1) > data(indexEnd+1,1))
%         indexEnd =indexEnd + 1;
%     end

    while(indexStart > 2 && data(indexStart,1) > baseThreshold)
         indexStart =indexStart - 1;
    end    
    while(indexEnd < (length(data)-1) && data(indexEnd,1) > baseThreshold)
         indexEnd =indexEnd + 1;
    end 

    peakIntervals(index,:) = [indexStart,indexEnd];

end

%%
% Merge intervals that are within minimumSamplesBetweenIntervals samples
% of eachother in time
%%
peakIntervalsOrig=peakIntervals;
if(size(peakIntervals,1)>=2)
    peakIntervalsUpd = [];

    index=1;
    indexStart= peakIntervals(index,1);
    index=2;
    
    while index <= size(peakIntervals,1)
        didx = peakIntervals(index,1)-peakIntervals(index-1,2);
        if(didx <= minimumSamplesBetweenIntervals ...
                && index < size(peakIntervals,1))
            index=index+1;
        elseif (didx <= minimumSamplesBetweenIntervals ...
                && index == size(peakIntervals,1))
            indexEnd = peakIntervals(index,2);
            peakIntervalsUpd = [peakIntervalsUpd; indexStart, indexEnd]; 
            index=index+1;
        elseif (didx > minimumSamplesBetweenIntervals ...
                && index == size(peakIntervals,1))
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

if(flag_plotDetails==1)
    figure(figDebug);
    subplot(2,1,2);
    n0=1;
    n1=length(data);

    fill([n0;n1;n1;n0;n0],[0;0;1;1;0].*peakMiddleThreshold,[1,1,1].*0.75,...
         'EdgeColor','none');
    hold on;

    plot([n0;n1],[1;1].*(peakMaximumThreshold),...
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

peakMiddleThresholds = dataMedian+[-peakMiddleThreshold,peakMiddleThreshold];
peakMaximumThresholds = dataMedian+[-peakMaximumThreshold,peakMaximumThreshold];


