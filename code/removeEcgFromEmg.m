function biopacData = removeEcgFromEmg(biopacData,emgKeyword,ecgKeyword,...
                        ecgWindowDuration, highpassFilterFrequency, sampleRate)


ecgWindowSamples  = round(ecgWindowDuration*sampleRate/2);


%Find the ECG channel
indexECG = 0;
for i=1:1:size(biopacData.labels,1)
    if(contains(biopacData.labels(i,:),ecgKeyword))
        indexECG = i;
    end
end

%%
%Find the ECG peaks:
%  Look for changes in the sign of the derivative that
%  occur higher than half of the maximum value
%%

%Evaluate the threshold
minEcgVal = min(biopacData.data(:,indexECG));
maxEcgVal = max(biopacData.data(:,indexECG));
thresholdEcgVal = (maxEcgVal-minEcgVal)*0.5 + minEcgVal;

%Evaluate the produce of the numerical derivative to the left and to the
%right of a point
ecgDiffL  = diff(biopacData.data(2:end,indexECG));
ecgDiffR  = diff(biopacData.data(1:(end-1),indexECG));

%Now take the product: this produce will be negative or zero only at a 
%local maxima
ecgDiffLR = ecgDiffL.*ecgDiffR;

%Identify all of the peaks
ecgPeaks = find(biopacData.data(2:(end-1),indexECG) > thresholdEcgVal ...
               & ecgDiffLR <= 0);

%Add 1 to account for the first index we lost taking a derivative
ecgPeaks = ecgPeaks+1;


flag_debug=1;
idxSubplot=1;
timeV = [];
if(flag_debug==1)
    figEcgRemoval = figure;
    timeV = [(1/sampleRate):(1/sampleRate):(size(biopacData.data,1)/sampleRate)]';
    subplot(3,3,idxSubplot);
    plot(timeV, biopacData.data(:,indexECG),'b');
    hold on;
    plot(timeV(ecgPeaks,1), biopacData.data(ecgPeaks,indexECG),'or');

    m0=min(biopacData.data(:,indexECG));
    m1=max(biopacData.data(:,indexECG));

    for j=1:1:length(ecgPeaks)
        k0 = max(1,ecgPeaks(j,1)-ecgWindowSamples);
        k1 = min(ecgPeaks(j,1)+ecgWindowSamples,size(biopacData.data,1));
        plot([timeV(k0,1);timeV(k1,1)],[m0;m0],'r');
        hold on;
        plot([timeV(k1,1);timeV(k1,1)],[m0;m1],'r');
        hold on;        
        plot([timeV(k0,1);timeV(k1,1)],[m1;m1],'r');
        hold on;        
        plot([timeV(k0,1);timeV(k0,1)],[m0;m1],'r');
        hold on;        
        
    end

    hold on;
    xlabel('Time')
    ylabel('ECG');
    here=1;    
    idxSubplot=idxSubplot+1;
end

%%
% Now go through the EMG signals and apply a high pass filter to a window
% centered on each peak
%%

[b,a] = butter(2,highpassFilterFrequency/(0.5*sampleRate),'high');

%Go find each EMG channel and process it
flag_firstChannelFound=0;
for i=1:1:size(biopacData.labels,1)
    if(contains(biopacData.labels(i,:),emgKeyword))

        %Plot the EMG signal before its processed
        if(flag_debug==1 && idxSubplot <= 9)
            figure(figEcgRemoval);
            subplot(3,3,idxSubplot);
            plot(timeV, biopacData.data(:,i),'Color',[1,1,1].*0.5);
            hold on;
            xlabel('Time')
            ylabel(biopacData.labels(i,:));
            here=1; 
            title(biopacData.labels(i,:));
        end        

        %For each ECG peak
        for j=1:1:length(ecgPeaks)
            k0 = max(1,ecgPeaks(j,1)-ecgWindowSamples);
            k1 = min(ecgPeaks(j,1)+ecgWindowSamples,size(biopacData.data,1));
            
            windowData = biopacData.data(k0:k1,i);
            windowDataFiltered = filtfilt(b,a,windowData);

            biopacData.data(k0:k1,i)= windowDataFiltered;

            %Plot the EMG window after its processed
            if(flag_debug==1 &&  idxSubplot <= 9)
                figure(figEcgRemoval);
                subplot(3,3,idxSubplot);
                plot(timeV(k0:k1,1), biopacData.data(k0:k1,i),'Color',[1,0,0]);
                hold on; 
                box off;
            end  
        end
        idxSubplot=idxSubplot+1;

    end
end


