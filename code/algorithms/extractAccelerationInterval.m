function [biopacSignalIntervals,flag_carMoved,indexSubplot,figOnset] ...
                = extractAccelerationInterval(...
                        timeV,...
                        carBiopacData,...  
                        biopacSignalIntervals,...                                
                        minimumAcceleration,...
                        onsetDetectionSettings,...
                        biopacIndices,...  
                        biopacKeywords,...
                        biopacParameters,...
                        flag_plotOnset,...
                        indexSubplot,...
                        subPlotPanel,...
                        colorOnset,...                        
                        figOnset)


flag_carMoved=0;

for i=[biopacIndices.indexAccCarX,biopacIndices.indexAccHeadX]

    %Identify signal onset times from the norm of the acceleration
    accDelta        = carBiopacData.data(:,[i:1:(i+2)]);
    accDelta        = accDelta-median(accDelta);
    accDeltaNorm    = (sum(accDelta.^2,2)).^0.5;

    if(max(accDeltaNorm) > minimumAcceleration)

        if(i== biopacIndices.indexAccCarX || flag_carMoved == 1)
            noiseWindowIndicies= [];
            signalWindowIndices= [];

            noiseWindowNorm = onsetDetectionSettings.noiseWindowInNormalizedTime;
            signalWindowNorm= onsetDetectionSettings.signalWindowInNormalizedTime;

            if(i== biopacIndices.indexAccCarX)
                %Car
                noiseWindowIndices  = ...
                    round(noiseWindowNorm.*length(accDeltaNorm));
                signalWindowIndices = ...
                    round(signalWindowNorm.*length(accDeltaNorm));                

            else
                %Head
                minNoiseIdx = 1;
                maxNoiseIdx = biopacSignalIntervals(biopacIndices.indexAccCarX).intervals(1,1);
                noiseWindowIndices = [minNoiseIdx, maxNoiseIdx];

                maxSignalIdx = round(0.99.*length(accDeltaNorm));
                signalWindowIndices = [maxNoiseIdx,maxSignalIdx];
            end
    
            flag_plotOnsetAlgorithmDetails=0;

            [peakIntervalRaw,...
             peakIntervalFiltered,...
             noiseBlocks,...
             dataZeroMedian,...
             dataZeroMedianFiltered] = ...
                findOnsetUsingNoiseModel(...
                    accDeltaNorm, ...
                    signalWindowIndices,...
                    noiseWindowIndices,...
                    onsetDetectionSettings.numberOfNoiseSubWindows,...
                    onsetDetectionSettings.maxAcceptableNoiseProbability,...
                    onsetDetectionSettings.minimumTimingGap,...
                    onsetDetectionSettings.lowFrequencyFilterCutoff,...
                    biopacParameters.sampleFrequencyHz,...
                    onsetDetectionSettings.typeOfNoiseModel,...
                    flag_plotOnsetAlgorithmDetails);

            peakIntervalFilteredUpd=[];

            %If the dataZeroMedianFiltered meets the minimum acceleration
            %then get interval that defines the acceleration
            if(max(dataZeroMedianFiltered) > minimumAcceleration)

                flag_carMoved=1;                                                
                if(i== biopacIndices.indexAccCarX && ...
                        size(peakIntervalFiltered,1) > 1)

                   %If there's more than one acceleration interval 
                   %select the interval with the largest acceleration
                   maxAccVal = zeros(size(peakIntervalFiltered,1),1);
                   for k=1:1:size(peakIntervalFiltered,1)
                       i0=peakIntervalFiltered(k,1);
                       i1=peakIntervalFiltered(k,2);                       
                       maxAccVal(k,1)=max(dataZeroMedianFiltered(i0:1:i1,1));
                   end
                   [val,idx]=max(maxAccVal);
                    peakIntervalFilteredUpd=peakIntervalFiltered(idx,:);

                elseif(isempty(peakIntervalFiltered)==0)
                   %If there's one interval, then take it
                    peakIntervalFilteredUpd = peakIntervalFiltered(1,:);
                end

            else 
                %The car didn't move: update flag_carMoved appropriately
                if(i== biopacIndices.indexAccCarX)
                    flag_carMoved=0;
                end
            end

            %Update the 3 indicies of this accelerometer with the
            %intervals that contain the peak acceleration
            for k=1:1:3
                biopacSignalIntervals(i+k-1).intervals   = ...
                    peakIntervalFilteredUpd;
            end


            dataLabel='';
            if(contains(carBiopacData.labels(i,:),biopacKeywords.accHead))
                dataLabel = 'Accelerometer: Head';
            end
            if(contains(carBiopacData.labels(i,:),biopacKeywords.accCar))
                dataLabel = 'Accelerometer: Car';
            end
        
            if(flag_plotOnset)
                [figOnset,indexSubplot] = ...
                    addOnsetPlot(   timeV, ...
                                    dataZeroMedian,...
                                    dataZeroMedianFiltered,...
                                    signalWindowIndices,...
                                    noiseBlocks,...
                                    peakIntervalFiltered,...
                                    colorOnset,...
                                    dataLabel,...
                                    figOnset, ...
                                    subPlotPanel, ...
                                    indexSubplot); 
                here=1;
            end
        end
    end
end	