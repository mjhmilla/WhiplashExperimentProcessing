function [indexOnset, dataLabels] = findOnset(data, numberOfClusters)
%%
% This will group the data into 3 clusters. Due to the properties of our
% specific data:
%
% - One cluster will contain the steady state data
% - Another cluster will contain the dynamic data
% - The final cluster will contain the data in between
%
% The onset time is defined as the first time between the steady state data
% and the data in between. This function assumes that the data begins with
% steady state data
%
% @params time: the 1 x n time vector
% @params data: the 1 x n data vector
% @params numberOfClusters: the number of clusters you expect in the data
% @returns [indexOnset, dataLabels]
%  indexOnset: the first data point that transitions from the steady-state
%              data to the transition data.
%  dataLabels: the label of each point
%       1: steady state
%       2: transition state
%       3: dynamic state
%%
k = numberOfClusters;

dataLabels = kmeans(data,k);

meanK = zeros(k,1);

for i=1:1:k
    meanK(i,1)=mean(data(dataLabels==i));
end


%Sort the vector and get the index map 
[sortedMeans, sortedIdx] = sort(meanK);

%Use the index map to update the labels in idx1 so that 1 is the steady
%state (the minimum), 3 is the highest value, and 2 is the transition.
dataLabelsUpd = dataLabels;
for i=1:1:length(sortedIdx)
    dataLabelsUpd(dataLabels == i) = sortedIdx(i,1);
end
dataLabels=dataLabelsUpd;
%Now go and identify the onset: the first point where a label transitions
%from a 1 to a 2:
indexOnset=0;
i = 2;
while indexOnset == 0 && i < length(data)
    if( dataLabels(i-1,1)==1 && dataLabels(i,1)==2)
        indexOnset=i;
    end
    i=i+1;
end


