function [peakInterval, noiseProbability,data] = ...
            findOnsetWithinWindow(  data, ...
                                    indicesWindowInterval,...
                                    noiseThresholdPercentile,...
                                    maximumAcceptableNoiseProbability,...
                                    sampleFrequency,...
                                    flag_plotDetails)

peakInterval = []; 
noiseProbability = [];

assert(length(indicesWindowInterval)==2,...
    ['Error: indicesOfWindow must contain 2 ',...
     'entries: the beginning and end of the window']);

assert(indicesWindowInterval(1,1) > 2);
assert(indicesWindowInterval(1,2) < (length(data)-1));

windowStart = indicesWindowInterval(1,1);
windowEnd   = indicesWindowInterval(1,2);

indicesWindow = [indicesWindowInterval(1,1):1:indicesWindowInterval(1,2)]';
indicesNotWindow = [2:1:(indicesWindowInterval(1,1)-1)];
indicesNotWindow = [indicesNotWindow,...
                  (indicesWindowInterval(1,1)+1):1:(length(data)-1)]';


dataMedian=median(data);
data = data-dataMedian;
data = abs(data);


if(flag_plotDetails==1)
    figDebug=figure;
    subplot(3,1,1);
    plot(data,'Color',[1,1,1].*0.5,'DisplayName','Raw Input');    
    hold on; 
    
    minVal = min(data(indicesWindow,1));
    maxVal = max(data(indicesWindow,1));
    indexLeft = indicesWindowInterval(1,1);
    indexRight= indicesWindowInterval(1,2);

    plot([indexLeft;indexRight;indexRight;indexLeft;indexLeft],...
         [minVal;minVal;maxVal;maxVal;minVal],'b');

    hold on;
    xlabel('Index');
    ylabel('Value')
end




%%
%Evaluate the distribution of the data
%%
%intervals = 100;
[nData,dataEdges] = histcounts(data(indicesNotWindow(:),1),'Normalization','cdf');
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

    if(nData(1,index) >= noiseThresholdPercentile && ...
       nData(1,index-1) <  noiseThresholdPercentile )  

        dy = 0;       
        if(nData(1,index)-nData(1,index-1) > 0)
            dydx = (noiseThresholdPercentile-nData(1,index-1)) ...
                /(nData(1,index)-nData(1,index-1));
            dx = midInterval(1,index)-midInterval(1,index-1);
            dy = dydx*dx;
        end
        noiseThreshold = midInterval(1,index-1)+dy;
        flag_found=1;
    else
        index=index+1;
    end
end


indicesNoise = find(data <= noiseThreshold);
noiseNotInWindow = indicesNoise(indicesNoise < windowStart ...
                              | indicesNoise > windowEnd);

[noiseProbability,noiseEdges] = histcounts(data(noiseNotInWindow),...
    'Normalization','probability','BinMethod','sturges');
noiseInterval = 0.5*noiseEdges(1,1:(end-1)) ...
            + 0.5*noiseEdges(1,2:(end));


if(flag_plotDetails==1)
    subplot(3,1,1);
    plot(noiseNotInWindow, data(noiseNotInWindow,1),'.r');
    hold on;

    subplot(3,1,2);
    plot(midInterval,nData,'k');
    hold on;
    plot([1;1].*noiseThreshold,...
         [0;1].*noiseThresholdPercentile,...
         'r');
    hold on;
    xlabel('Value');
    ylabel('Count');
    title('Cumulative Distribution Outside Window');

    subplot(3,1,3);
    plot(noiseInterval,noiseProbability,'k');
    hold on;
    xlabel('Value');
    ylabel('Count');
    title('Probability Distribution Outside Window');
end

%Go through all of the points in the window and evaluate the probability
%that the value came from the noise distribution

peakIndices = [];
peakProbability = [];

[b,a] = butter(2,10/(sampleFrequency*0.5),'low');
dataFilt = filtfilt(b,a,data);

for i=1:1:length(indicesWindow)
    idx=indicesWindow(i,1);
    vF = dataFilt(idx,1);
    pF = interp1(noiseInterval,noiseProbability,vF,'linear','extrap');
    v = data(idx,1);
    p = interp1(noiseInterval,noiseProbability,v,'linear','extrap');

    if(pF <= maximumAcceptableNoiseProbability ...
            && p <= maximumAcceptableNoiseProbability)
        peakInterval = [peakInterval; idx];
        peakProbability = [peakProbability;p];
    end
    
end


if(flag_plotDetails==1)
    subplot(3,1,1);
        plot(dataFilt,'k');
        hold on;
        plot(peakInterval(:), data(peakInterval(:),1),'.m');
        hold on;
end


