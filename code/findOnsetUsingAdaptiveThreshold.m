function [indexOnset] = findOnsetUsingAdaptiveThreshold(data, ...
                                    onsetPercentileThreshold)
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
% @params time: the 1 x n time vector
% @params data: the 1 x n data vector
% @params numberOfClusters: the number of clusters you expect in the data
% @params onsetStandardDeviationThreshold: The 2nd cluster must be at least
%        this many standard deviations away from the mean to be included.
% @returns [indexOnset, dataLabels]
%  indexOnset: an n x 2 vector where each row contains the index of the 
%               beginning and the end of data that exceeds the desired
%               threshold and is not in the lowest cluster
%  dataLabels: the label of each point
%       1: steady state
%       2: transition state
%       3: dynamic state
%%

