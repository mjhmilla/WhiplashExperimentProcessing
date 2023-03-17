% generate box-whisker illustration for onset times and amplitudes
% for each condition
function [percentiles vectorOfValidData]=getPercentiles(data,percentileSet,noDataNumber)
assert(percentileSet>= 0 && percentileSet <= 1);
%
indexValidData = find(data ~= noDataNumber);
vectorOfValidData = data(indexValidData);

%Find the number in data that is closest to the desired percentile
N=length(vectorOfValidData);
n=percentileSet*N;
n=round(n);
data_order=sortrows(vectorOfValidData);


%Update value so that it returns this number in data
percentiles = data_order(n);

