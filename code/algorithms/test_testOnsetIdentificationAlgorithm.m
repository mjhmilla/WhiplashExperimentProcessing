clc;
close all;
clear all;

%%
% Input variables
%%

%Variables related to the signal creation
signalMagnitude  = 1;    %Leave at 1
noiseMagnitude   = 0.75; %Increase this if you like

%Variables related to onset identification
numberOfClusters = 2;    %Use 2 clusters. More can be used, but the result
                         %is not good if the data is noisy
flag_lowPassFilter = 1;  %If the signal to noise ratio is bad, 
                         % low pass filter the data                        
lowPassFreq        = 10; %Low pass frequency fitler in Hz 
%%
%Generate an ideal signal: a step function
% :step begins at index 35
% :step ends at index 65
%%

indexSignal = [35:1:65]';
dt = 0.01;
time = [0:dt:1]';
maxFreq = 1/(dt*0.5);
signal = zeros(length(time),1);
signal(indexSignal,:)=signalMagnitude;

[b,a] = butter(2, 0.4*maxFreq/maxFreq,'low');
signal = filtfilt(b,a,signal);

%%
%Generate some noise that we will add to the step function
%%
noise = (rand(size(signal))-0.5).*(2*noiseMagnitude);
signalWithNoise = signal + noise;

%%
% Identify the onset time
%%
signalToProcess = signalWithNoise;

%If the data is very noisy then the clustering algorithm won't work very 
%well: it will identify postive noise and negative noise. Much better
%performance can be had by first low-pass filtering the data. This only 
%works if the noise is at a higher frequency than the movement: which is
%the case in our data.
if(flag_lowPassFilter==1)
    [b,a] = butter(2, lowPassFreq/maxFreq,'low');
    signalToProcess = filtfilt(b,a,signalToProcess);
end

[indexOnset, dataLabels] = findOnset(signalToProcess,numberOfClusters);

%%
% Plot the output
%%

fig=figure;

%
subplot(2,2,1);
plot(time,signalWithNoise,'Color',[1,1,1].*0.5,'DisplayName','signal+noise');
hold on
plot(time,signal,'Color',[0,0,1],'DisplayName','signal');
hold on


plot([1;1].*time(indexSignal(1,1),1),[0,2],...
    'Color',[0,0,0],'DisplayName','onset');
hold on;
text(time(indexSignal(1,1),1),2,...
    sprintf('index %i',indexSignal(1,1)),...
    'HorizontalAlignment','right');
hold on;


xticks([time(indexSignal(1,1),1),time(indexSignal(end,1),1)]);
xlabel('Time (s)');
ylabel('Amplitude');
title('Signal with noise');

ylim([-1,3]);
legend('Location','NorthEast');
legend boxoff;
box off;

subplot(2,2,2);


i=2;
indexChunk = [1];
chunkCount=1;
while (i <= length(dataLabels))

    if(dataLabels(i,1)==dataLabels(i-1,1))
        indexChunk = [indexChunk;i];
    end
    if(dataLabels(i,1)~=dataLabels(i-1,1) || i == length(dataLabels))
        lineColor = [0,0,0];
        chunkName = '';
        switch dataLabels(i-1,1)
            case 1
                lineColor = [0,0,1];
                chunkName = 'low';
            case 2
                lineColor = [1,0,0];
                chunkName = 'med';
            case 3
                lineColor = [0,1,0];
                chunkName = 'high';
            otherwise
                assert(0,'If you added a 3rd cluster, add a new color');
        end

        plot(time(indexChunk,1), ...
             signalWithNoise(indexChunk,1),...
            'Color',lineColor,...
            'DisplayName',[num2str(chunkCount),'. ',chunkName]);
        hold on;        

        indexChunk = [i-1];
        chunkCount=chunkCount+1;
    end
    i=i+1;
end

%Plot the last chunk

plot([1;1].*time(indexOnset),[0,2],...
    '-k','DisplayName','Onset');
hold on;
text(time(indexOnset),2,...
    sprintf('index %i',indexOnset),...
    'HorizontalAlignment','right');
hold on;

if(flag_lowPassFilter==1)
    plot(time,signalToProcess,'Color',[0,0,0]);
    hold on;
end

xticks(time(indexOnset));
xlabel('Time (s)');
ylabel('Amplitude');
ylim([-1,3]);
box off;

%legend;
%legend boxoff;

title('Clustered signal');

fprintf('%1.3f Error in onset time\n', time(indexSignal(1,1),1)-time(indexOnset,1));