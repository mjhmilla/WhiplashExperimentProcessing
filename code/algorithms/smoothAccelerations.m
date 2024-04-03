function biopacData = smoothAccelerations(biopacData,accelerationKeyword,...
    lowpassFilterFrequency,sampleRate)

[b,a] = butter(2,lowpassFilterFrequency/(0.5*sampleRate),'low');

for i=1:1:size(biopacData.labels,1)
    if(contains(biopacData.labels(i,:),accelerationKeyword))
        biopacData.data(:,i)=filtfilt(b,a,biopacData.data(:,i));
    end
end