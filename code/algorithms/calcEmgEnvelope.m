function biopacData = calcEmgEnvelope(biopacData,signalKeyword, ...
                                lowpassFilterFrequency, sampleRate)

[b,a] = butter(2,lowpassFilterFrequency/(0.5*sampleRate),'low');

idxSubplot=1;


flag_debug=0;
timeV = [];

if(flag_debug==1)
    figureEmgEnvelope=figure;
    timeV = [(1/sampleRate):(1/sampleRate):(size(biopacData.data,1)/sampleRate)]';
end


for i=1:1:size(biopacData.labels,1)
    if(contains(biopacData.labels(i,:),signalKeyword))

        %Plot the EMG signal before processing
        if(flag_debug==1 && idxSubplot <= 9)
            
            figure(figureEmgEnvelope);
            subplot(3,3,idxSubplot);
            plot(timeV, biopacData.data(:,i),'Color',[1,1,1].*0.5);
            hold on;
            xlabel('Time')
            ylabel(biopacData.labels(i,:));
            here=1;    
        end 

        %filtfilt will fail if there are less than 6 points        
        if(length(biopacData.data(:,i))>6)
            biopacData.data(:,i) = filtfilt(b,a,abs(biopacData.data(:,i)));
        end

        %Plot the EMG signal after processing
        if(flag_debug==1 && idxSubplot <= 9)
            figure(figureEmgEnvelope);
            subplot(3,3,idxSubplot);
            plot(timeV, biopacData.data(:,i),'Color',[1,0,0]);
            hold on;
            here=1;    
        end 

        idxSubplot=idxSubplot+1;
    end
end