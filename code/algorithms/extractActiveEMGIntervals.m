function [biopacSignalIntervals,indexSubplot, figOnset] ...
                = extractActiveEMGIntervals(...                       
                        timeV,...
                        carBiopacData,... 
                        carBiopacDataNorm,...
                        biopacSignalIntervals,...
                        onsetDetectionSettings,...
                        biopacIndices,...  
                        biopacKeywords,...
                        biopacParameters,...
                        flag_useFilteredSignal,...
                        flag_carMoved,...
                        flag_plotOnset,...
                        indexSubplot,...
                        subPlotPanel,...
                        colorOnset,...                        
                        figOnset)

for i=1:1:size(carBiopacData.labels,1)
    if(contains(carBiopacData.labels(i,:),biopacKeywords.emg))        
        %assert(isempty(biopacSignalIntervals(biopacIndices.indexAccCarX).intervalIndices)==0,...
        %           ['Error: The car did not accelerate. The code should not be able to',...
        %             ' evaluate the EMG onsets']);

        %Get the acceleration window associated with both the car
        %and the head.

        indexAccMin = round(length(timeV)*0.1);
        indexAccMax = round(length(timeV)*0.9);
        flag_usingDefaultWindow = 1;
        if(max(timeV) > 10)
            indexAccMin = find(timeV > 10, 1 );
            indexAccMax = find(timeV > max(timeV)-onsetDetectionSettings.maximumAcceptableOnsetTime-1, 1 );
            flag_usingDefaultWindow = 0;
        end
        if(isempty(biopacSignalIntervals(biopacIndices.indexAccCarX).intervalIndices)==0)
            indexAccMin = min(biopacSignalIntervals(biopacIndices.indexAccCarX).intervalIndices(1,:));
            indexAccMax = max(biopacSignalIntervals(biopacIndices.indexAccCarX).intervalIndices(1,:));                
            flag_usingDefaultWindow = 0;            
        end

        %If the head also moves, include its movement in definining
        %the minimum and maximum times.
        if(isempty(biopacSignalIntervals(biopacIndices.indexAccHeadX).intervalIndices)==0 ...
                && isempty(biopacSignalIntervals(biopacIndices.indexAccCarX).intervalIndices)==0)
            indexAccMin = ...
                min( biopacSignalIntervals(biopacIndices.indexAccCarX).intervalIndices(1,:),...
                     biopacSignalIntervals(biopacIndices.indexAccHeadX).intervalIndices(1,:));
    
            indexAccMax = ...
                max( biopacSignalIntervals(biopacIndices.indexAccCarX).intervalIndices(1,:),...
                     biopacSignalIntervals(biopacIndices.indexAccHeadX).intervalIndices(1,:));
            flag_usingDefaultWindow = 0;            
        end

        timeAccMin      = timeV(indexAccMin,1);
        timeAccMax      = timeV(indexAccMax,1);  
        timeWindowStart = timeAccMin;
        timeWindowEnd   = timeAccMax;         
        if(flag_usingDefaultWindow==0)
            timeWindowStart = timeAccMin+onsetDetectionSettings.minimumAcceptableOnsetTime;
            timeWindowEnd   = timeAccMax+onsetDetectionSettings.maximumAcceptableOnsetTime; 
            timeWindowEnd   = min(max(timeV),timeWindowEnd);
        end

        signalWindowIndices = ...
            [timeWindowStart,timeWindowEnd].*biopacParameters.sampleFrequencyHz;

        signalWindowIndices = round(signalWindowIndices);
        signalWindowIndices(1,1) = max(3,signalWindowIndices(1,1));
        signalWindowIndices(1,2) = min([signalWindowIndices(1,2),...
                                        length(carBiopacData.data(:,i))-3]);




        noiseWindowIndices = [1,round(indexAccMin*0.95)];
        flag_plotOnsetAlgorithmDetails=0;

        [peakIntervalRaw,...
         peakIntervalFiltered, ...
         noiseBlocks,...
         dataZeroMedian,...
         dataZeroMedianFiltered] = ...
            findOnsetUsingNoiseModel(...
                carBiopacData.data(:,i), ...
                signalWindowIndices,...
                noiseWindowIndices,...
                onsetDetectionSettings.numberOfNoiseSubWindows,...
                onsetDetectionSettings.maxAcceptableNoiseProbability,...
                onsetDetectionSettings.minimumTimingGap,...
                onsetDetectionSettings.lowFrequencyFilterCutoff,...
                biopacParameters.sampleFrequencyHz,...
                onsetDetectionSettings.typeOfNoiseModel,...
                flag_plotOnsetAlgorithmDetails);

        flag_onsetDetected=0;
        if(flag_useFilteredSignal==1)
            if(isempty(peakIntervalFiltered)==0)
                flag_onsetDetected=1;
            end
        else
            if(isempty(peakIntervalRaw)==0)
                flag_onsetDetected=1;
            end
        end


        %Determine if the muscle was activated before the signal window
        flag_isPreactivationChecked = 0;

        deltaIndices = signalWindowIndices(1,2)-signalWindowIndices(1,1);
        signalWindowIndicesPreactivation = signalWindowIndices-deltaIndices;

        noiseWindowIndicesPreactivation     = [];
        peakIntervalRawPreactivation        = [];
        peakIntervalFilteredPreactivation   = [];
        noiseBlocksPreactivation            = [];
        dataZeroMedianPreactivation         = [];
        dataZeroMedianFilteredPreactivation = [];

        if(flag_onsetDetected == 1 && ...
                min(signalWindowIndicesPreactivation(1,:)) ...
                > biopacParameters.sampleFrequencyHz )

            noiseWindowIndicesPreactivation = [1,round(min(signalWindowIndicesPreactivation(1,:))*0.95)];
            flag_plotOnsetAlgorithmDetails=0;

            [peakIntervalRawPreactivation,...
             peakIntervalFilteredPreactivation, ...
             noiseBlocksPreactivation,...
             dataZeroMedianPreactivation,...
             dataZeroMedianFilteredPreactivation] = ...
                findOnsetUsingNoiseModel(...
                    carBiopacData.data(:,i), ...
                    signalWindowIndicesPreactivation,...
                    noiseWindowIndicesPreactivation,...
                    onsetDetectionSettings.numberOfNoiseSubWindows,...
                    onsetDetectionSettings.maxAcceptableNoiseProbability,...
                    onsetDetectionSettings.minimumTimingGap,...
                    onsetDetectionSettings.lowFrequencyFilterCutoff,...
                    biopacParameters.sampleFrequencyHz,...
                    onsetDetectionSettings.typeOfNoiseModel,...
                    flag_plotOnsetAlgorithmDetails);
            flag_isPreactivationChecked = 1;
        end





        biopacSignalIntervals(i).flag_maximumValueExceedsThreshold = 0;
        biopacSignalIntervals(i).flag_isPreactivationChecked = ...
            flag_isPreactivationChecked;
        biopacSignalIntervals(i).flag_isMusclePreactivated = 0;

        flag_emgEnvelopeGoesNegative=0;
        if(isempty(peakIntervalRaw)==0 ...
                && isempty(peakIntervalFiltered)==0 ...
                    && flag_carMoved == 1)

            if(flag_useFilteredSignal==1)
                biopacSignalIntervals(i).intervalIndices   = ...
                    [peakIntervalFiltered(1,:)];
                biopacSignalIntervals(i).intervalTimes   = ...
                    timeV(peakIntervalFiltered(1,:)')';
            else
                biopacSignalIntervals(i).intervalIndices   = ...
                    [peakIntervalRaw(1,:)];
                biopacSignalIntervals(i).intervalTimes   = ...
                    timeV(peakIntervalRaw(1,:)')';
            end
            
            if(isempty(peakIntervalRaw)==0)
                i0=0;
                i1=0;
                
                if(flag_useFilteredSignal==1)
                    i0 = peakIntervalFiltered(1,1);
                    i1 = peakIntervalFiltered(1,2);
                else
                    i0 = peakIntervalRaw(1,1);
                    i1 = peakIntervalRaw(1,2);
                end

                biopacSignalIntervals(i).intervalMaximumValue = ...
                    max(carBiopacDataNorm.data(i0:1:i1,i));
                
                if(min(carBiopacDataNorm.data(i0:1:i1,i)) < 0)
                    %MM 2023/03/06: This is usually nothing to be worred
                    %about
                    disp('  **Note: Emg Envelope has negative values');
                    flag_emgEnvelopeGoesNegative=1;
                end


                if(flag_isPreactivationChecked==1)                    
                    if(flag_useFilteredSignal==1)
                        if(isempty(peakIntervalFilteredPreactivation)==0)
                            biopacSignalIntervals(i).flag_isMusclePreactivated = 1;
                        end
                    else
                        if(isempty(peakIntervalRawPreactivation)==0)
                            biopacSignalIntervals(i).flag_isMusclePreactivated = 1;
                        end
                    end
                end

                %biopacSignalIntervals(i).intervalMaximumValue = ...
                %    max(abs(dataZeroMedianFiltered(i0:1:i1,1)));
                biopacSignalIntervals(i).flag_maximumValueExceedsThreshold =1;
            end
        end
   

        if(flag_plotOnset)
            dataLabel = carBiopacData.labels(i,:);
            dataLabel = dataLabel(1,1:max(30,length(dataLabel)));

            figure(figOnset);
            maxPlotCols = size(subPlotPanel,2);
            maxPlotRows = size(subPlotPanel,1);
            
            row = ceil(indexSubplot/maxPlotCols);
            col = max(1,indexSubplot-(row-1)*maxPlotCols);
            
            colorLine=colorOnset;

            peakInterval=[];
            if(flag_useFilteredSignal==1)
                peakInterval = peakIntervalFiltered;
            else
                peakInterval = peakIntervalRaw;
            end

            if(biopacSignalIntervals(i).flag_maximumValueExceedsThreshold==0)
                colorLine = [0,0,0];
                %signalWindowIndices = [];
                %noiseBlocks = [];
                peakInterval = [];
            end

            if(flag_emgEnvelopeGoesNegative==1)
                colorLine = [0,0.5,0];
            end

            subplot('Position',reshape(subPlotPanel(row,col,:),1,4));  
            labelVerticalOffset = 0;
            [figOnset,indexSubplot] = ...                        
                addOnsetPlot(   timeV, ...
                                carBiopacData.data(:,i),...
                                carBiopacDataNorm.data(:,i),...
                                signalWindowIndices,...
                                noiseBlocks,...
                                peakInterval,...
                                min(timeAccMin),...
                                colorLine,...
                                dataLabel,...
                                figOnset, ...
                                subPlotPanel, ...
                                indexSubplot,...
                                labelVerticalOffset);   
            here=1;


            if(biopacSignalIntervals(i).flag_isPreactivationChecked == 1 ...
                && biopacSignalIntervals(i).flag_isMusclePreactivated == 1)

                peakIntervalPreactivation=[];
                if(flag_useFilteredSignal==1)
                    peakIntervalPreactivation = peakIntervalFilteredPreactivation;
                else
                    peakIntervalPreactivation = peakIntervalRawPreactivation;
                end
                colorLine = colorOnset.*0.5 + [0,1,0].*0.5; 
                indexSubplot=indexSubplot-1;
                labelVerticalOffset = 1;
                [figOnset,indexSubplot] = ...       
                    addOnsetPlot(   timeV, ...
                                    carBiopacData.data(:,i),...
                                    carBiopacDataNorm.data(:,i),...
                                    signalWindowIndicesPreactivation,...
                                    noiseBlocksPreactivation,...
                                    peakIntervalPreactivation,...
                                    min(timeAccMin),...
                                    colorLine,...
                                    dataLabel,...
                                    figOnset, ...
                                    subPlotPanel, ...
                                    indexSubplot,...
                                    labelVerticalOffset);   
            end

            if(flag_useFilteredSignal==1)
                text('Units', 'Normalized', 'Position', [0.05, 0.9], 'string',...
                            'Onset of filtered signal', 'FontSize',10,...
                            'HorizontalAlignment','left',...
                            'VerticalAlignment','top');
            else
                text('Units', 'Normalized', 'Position', [0.05, 0.9], 'string',...
                            'Onset of raw signal', 'FontSize',10,...
                            'HorizontalAlignment','left',...
                            'VerticalAlignment','top');
            end

            if(flag_emgEnvelopeGoesNegative==1)
                xL=xlim;
                yL=ylim;
                text(0.99*xL(2),0.99*yL(2),...
                    'Green: Filtered EMG envelope value below 0',...
                    'HorizontalAlignment','right',...
                    'VerticalAlignment','top');
                hold on;
            end

        end        
    end

end