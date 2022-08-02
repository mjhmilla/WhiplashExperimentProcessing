function [indexOnset, dataLabels] = findOnsetUsingKmeans(data, ...
                                    numberOfClusters,...
                                    onsetStandardDeviationThreshold)
%%
% This will group the data into numberOfClusters of data. 
% Due to the properties of our specific data:
%
% - One cluster will contain the steady state data
% - Another cluster will contain the dynamic data
% - The final cluster will contain the data in between
%
% The onset time is defined as the first time between the steady state data
% and the data in between. This function assumes that the data begins with
% steady state data
%
% @params data: the 1 x n data vector
% @params numberOfClusters: the number of clusters you expect in the data
% @params onsetStandardDeviationThreshold: The 2nd cluster must be at least
%        this many standard deviations away from the mean to be included.
% @returns [indexOnset, dataLabels]
%  indexOnset:  an n x 2 vector where each row contains the index of the 
%               beginning and the end of data that exceeds the desired
%               threshold and is not in the lowest cluster
%  dataLabels: the label of each point
%       1: steady state
%       2: dynamic state
%%


k = numberOfClusters;


%%
% Scale the data to be measured in standard deviations. Since 'quiet'
% data should domimate, by far, the standard deviation will most closely
% match the quiet signals.
%%      
data = data-mean(data);
data = abs(data)./std(data);

%%
% Get the labels
%%
dataLabels = kmeans(data,k);

%%
% The data is not labelled in any particular way. Here we evaluate the 
% mean of each cluster so we can order the data from smallest mean 
% value to the largest mean value
%%
meanK = zeros(k,1);
maxK  = zeros(k,1);
for i=1:1:k
    meanK(i,1)=mean(data(dataLabels==i));
    maxK(i,1) = max(data(dataLabels==i));
end
%Sort the vector and get the index map 
[sortedMeans, sortedIdx] = sort(meanK);

meanKSorted = meanK(sortedIdx,:);
maxKSorted  = maxK(sortedIdx,:);

%Relabel the data so that the first label is for the cluster with the 
%lowest mean value, etc. 
dataLabelsUpd = dataLabels;
for i=1:1:length(sortedIdx)
    dataLabelsUpd(dataLabels == i) = sortedIdx(i,1);
end
dataLabels=dataLabelsUpd;

%
%Identify all of the signal onsets:
%  1. A transition from a low cluster 1 to a higher cluster 2
%  2. Cluster 2 must have a maximum value that is at least 
%     onsetStandardDeviationThreshold
indexOnset=[];
i = 2;
if(maxKSorted(2,1) >= onsetStandardDeviationThreshold)
    idxStart=0;
    idxEnd = 0;
    while i < length(data)
        
        if( dataLabels(i-1,1)==1 && dataLabels(i,1)==2)
            idxStart=i;
        end

        if( dataLabels(i-1,1)==2 && dataLabels(i,1)==1 && ...
                idxStart ~= 0)
            idxEnd=i;
            if(max(data(idxStart:idxEnd,1)) >= ...
                    onsetStandardDeviationThreshold )
                indexOnset=[indexOnset;idxStart,idxEnd];
            end
            idxStart=0;
        end
        i=i+1;
    end
end


