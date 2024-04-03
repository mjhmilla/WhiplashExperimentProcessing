% generate box-whisker illustration for onset times and amplitudes
% for each condition
function percentiles=getPercentiles(data,percentileSet)

assert(min(percentileSet)>= 0 && max(percentileSet) <= 1);

%
%signsOfArray = sign(data);
%indexValidData = find(signsOfArray ~= noDataNumber);
%vectorOfValidData = data(indexValidData);
%Find the number in data that is closest to the desired percentile
%N=length(vectorOfValidData);

n=percentileSet*length(data);
n=round(n);
dataOrder=sortrows(data);

if(n==0)
    n=1;
end

%Update value so that it returns this number in data
percentiles = dataOrder(n);

%this_is_snake_case
%thisIsLowerCamelCase
%ThisIsUpperCamelCase
