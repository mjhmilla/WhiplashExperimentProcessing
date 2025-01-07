function [  peakBlocksRaw,...
            peakBlocksFiltered,...
            noiseSubWindowIntervals,...
            dataZeroMedian,...
            dataZeroMedianFiltered] = ...
            findOnsetUsingNoiseModel(dataInput, ...
                                    signalWindow,...
                                    noiseWindow,...
                                    numberOfNoiseSubWindows,...
                                    maxAcceptableNoiseProbability,...
                                    minimumTimingGap,...
                                    lowFrequencyFilterCutoff,...
                                    sampleFrequency,...                                    
                                    typeOfNoiseModel,...
                                    flag_plotDetails)

peakIntervalRaw = []; 
peakIntervalFiltered = []; 

noisePdf = [];

assert(length(signalWindow)==2,...
    ['Error: signalWindow must contain 2 ',...
     'entries: the beginning and end of the window']);

if(signalWindow(1,2) >= (length(dataInput)-1))
    here=1;
end
assert(signalWindow(1,1) > 2);
assert(signalWindow(1,2) < (length(dataInput)-1));

windowStart = signalWindow(1,1);
windowEnd   = signalWindow(1,2);

signalIndices   = [signalWindow(1,1):1:signalWindow(1,2)]';



%%
% Transform the data for single-sided analysis
%%

dataMedian=median(dataInput);
dataZeroMedian = dataInput-dataMedian;
dataZeroMedian = abs(dataZeroMedian);

dataZeroMedianFiltered = [];
if(isnan(lowFrequencyFilterCutoff)==0)
    [b,a] = butter(2,lowFrequencyFilterCutoff/(sampleFrequency*0.5),'low');
    dataZeroMedianFiltered = filtfilt(b,a,dataZeroMedian);
end

%%
% Divide up the noise window into segments. Find the segment with the 
% lowest average value. Find all additional segments which are similar.
% This subset of the noise window will be used to build the noise model
%%

%numberOfNoiseSubWindows = 5;

%Find the sub interval in the noise window that has the lowest mean value.
%This will be our prototype.
noiseSubWindowLowMean = inf;
noiseSubWindowPrototype = [];

index0=noiseWindow(1,1);
index1=noiseWindow(1,2);
indexDelta =round((index1-index0)/numberOfNoiseSubWindows);

indexLowNoiseStart=0;
indexLowNoiseEnd  =0;

for i=1:1:numberOfNoiseSubWindows
    indexA = (i-1)*indexDelta + 1;
    indexB = min(indexA + indexDelta,length(dataZeroMedian));
    meanAB = mean(dataZeroMedian(indexA:1:indexB,1));

    if(meanAB < noiseSubWindowLowMean)
        noiseSubWindowLowMean=meanAB;
        indexLowNoiseStart=indexA;
        indexLowNoiseEnd  =indexB;        
    end
end

%Go through all of the sub intervals. If the candidate sub interval is
%not different (using the Wilcoxon ranksum test) from the prototype, it is
%accepted and added to build the noise model.

noiseIndices=[];
noiseSubWindowIntervals = [];

for i=1:1:numberOfNoiseSubWindows
    indexA = (i-1)*indexDelta + 1;
    indexB = min(indexA + indexDelta, length(dataZeroMedian));

    [p,h] = ranksum(dataZeroMedian(indexA:1:indexB,1),...
                dataZeroMedian(indexLowNoiseStart:1:indexLowNoiseEnd,1),...
                'alpha', 0.1);

    %If the hypothesis that the medians are equal cannot be rejected
    %include this sub interval in the noise model
    if(h==0)
        noiseIndices=[noiseIndices, indexA:1:indexB];
        noiseSubWindowIntervals=[noiseSubWindowIntervals;...
                         indexA,indexB];
    end
end



%noiseIndices    = [noiseWindow(1,1):1:noiseWindow(1,2)]';


%%
%Evaluate the distribution of the dataZeroMedian
%%

[noisePdfNum,noisePdfEdges] = histcounts(dataZeroMedian(noiseIndices),...
    'Normalization','probability','BinMethod','sturges');

noiseModelCoeff = fitProbabilityDistribution(...
                    noisePdfEdges,noisePdfNum,...
                    maxAcceptableNoiseProbability,typeOfNoiseModel);

noiseFiltModelCoeff = [];
noiseFiltPdfNum     = [];
noiseFiltPdfEdges   = [];

if(isnan(lowFrequencyFilterCutoff)==0)
    [noiseFiltPdfNum,noiseFiltPdfEdges] = histcounts(dataZeroMedianFiltered(noiseIndices),...
        'Normalization','probability','BinMethod','sturges');
    
    noiseFiltModelCoeff = fitProbabilityDistribution(...
                    noiseFiltPdfEdges,noiseFiltPdfNum,...
                    maxAcceptableNoiseProbability,typeOfNoiseModel);    
end


if(flag_plotDetails==1)
    figDebug=figure;

    subplot(3,1,1);
    plot(dataZeroMedian,'Color',[1,1,1].*0.5,'DisplayName','Signal');    
    hold on; 
    
    %Analysis window
    minVal = min(dataZeroMedian(signalIndices,1));
    maxVal = max(dataZeroMedian(signalIndices,1));
    indexLeft = signalWindow(1,1);
    indexRight= signalWindow(1,2);

    plot([indexLeft;indexRight;indexRight;indexLeft;indexLeft],...
         [minVal;minVal;maxVal;maxVal;minVal],'b');

    hold on;

    %noise sub windows

    for i=1:1:size(noiseSubWindowIntervals,1)
        indexLeft = noiseSubWindowIntervals(i,1);
        indexRight= noiseSubWindowIntervals(i,2);
    
        plot([indexLeft;indexRight;indexRight;indexLeft;indexLeft],...
             [minVal;minVal;maxVal;maxVal;minVal],'r');
    
        hold on;
    end
    

    if(isnan(lowFrequencyFilterCutoff)==0)
        plot(dataZeroMedianFiltered,'k','DisplayName','Lpf Signal');
        hold on;
    end

    box off;
    xlabel('Time');
    ylabel('Value');
    title('Signal');

    %%
    % Probability distribution of the signal
    %%
    subplot(3,1,2);    
    noisePdfMidpoints =   0.5*noisePdfEdges(1,1:(end-1)) ...
                        + 0.5*noisePdfEdges(1,2:(end));

    noiseModelProb = evaluateProbabilityDistribution(...
                        noisePdfEdges,...
                        noiseModelCoeff.coeff,...
                        typeOfNoiseModel);


    plot(noisePdfMidpoints,noisePdfNum,'k','DisplayName','Num.');
    hold on;

    plot(noisePdfEdges,noiseModelProb,'b','DisplayName','Exp');
    hold on;

    maxVal = max(noiseModelProb);
    for i=1:1:length(noiseModelCoeff.localMaxima)
        plot([1;1].*noiseModelCoeff.localMaxima(i),...
             [0;1].*maxVal,'r');
        hold on;
    end

    legend;
    box off;
    xlabel('Value');
    ylabel('Probability');
    title('Noise Probability Function');

    %If the dataZeroMedian has been filtered, also
    if(isnan(lowFrequencyFilterCutoff)==0)

        %%
        % Probability distribution of the filtered signal
        %%        
        subplot(3,1,3);

        noiseFiltPdfMidpoints =   0.5*noiseFiltPdfEdges(1,1:(end-1)) ...
                                + 0.5*noiseFiltPdfEdges(1,2:(end));

        noiseFiltModelProb = evaluateProbabilityDistribution(...
                noiseFiltPdfEdges,noiseFiltModelCoeff.coeff,typeOfNoiseModel); 

        plot(noiseFiltPdfMidpoints,noiseFiltPdfNum,...
            'k','DisplayName','Num.');
        hold on;
    
        plot(noiseFiltPdfEdges,noiseFiltModelProb,...
            'b','DisplayName','Model');
        hold on;

        maxVal = max(noiseFiltModelProb);
        for i=1:1:length(noiseFiltModelCoeff.localMaxima)
            plot([1;1].*noiseFiltModelCoeff.localMaxima(i),...
                 [0;1].*maxVal,'r');
            hold on;
        end

        %legend;
        box off;
        xlabel('Value');
        ylabel('Probability');
        title('Filtered Noise Probability Function');
        here=1;
    end
    here=1;

end

%Go through all of the points in the window and evaluate the probability
%that the value came from the noise distribution

peakIndices = [];
peakProbability = [];



for i=1:1:length(signalIndices)
    idx=signalIndices(i,1);

    vF = dataZeroMedian(idx,1);
    pF = 0;
    mF = 0;
    if(isnan(lowFrequencyFilterCutoff)==0)
        if(isempty(noiseFiltModelCoeff.localMaxima)==0)
            mF = max(noiseFiltModelCoeff.localMaxima);
        end
        if(isempty(dataZeroMedianFiltered)==0)
            vF = dataZeroMedianFiltered(idx,1);    
            pF = evaluateProbabilityDistribution(...
                    vF,noiseFiltModelCoeff.coeff,...
                    typeOfNoiseModel);
        end
    end

    v = dataZeroMedian(idx,1);
    p = evaluateProbabilityDistribution(...
                v,noiseModelCoeff.coeff,...
                typeOfNoiseModel);
    m = 0;
    if(isempty(noiseModelCoeff.localMaxima)==0)
        m = max(noiseModelCoeff.localMaxima);
    end


    if(pF <= maxAcceptableNoiseProbability ...
            && p <= maxAcceptableNoiseProbability)
        peakIntervalRaw = [peakIntervalRaw; idx];
    end

    if(pF <= maxAcceptableNoiseProbability ...
            && p <= maxAcceptableNoiseProbability ...
            && vF >= mF ...
            && v >= m)
        peakIntervalFiltered = [peakIntervalFiltered; idx];
    end

end

%Go through the identified signals and group intervals together that only
%have breaks that are minimumTimingGap or smaller, and ignore isolated 
%signal segments that are minimumTimingGap or less.

minimumIndexGap = minimumTimingGap*sampleFrequency;

peakBlocksRaw = condenseIndexSeriesToBlocks(peakIntervalRaw, ...
                                             minimumIndexGap);

peakBlocksFiltered = condenseIndexSeriesToBlocks(peakIntervalFiltered, ...
                                             minimumIndexGap);

if(flag_plotDetails==1)
    subplot(3,1,1);
        plot(dataZeroMedianFiltered,'k');
        hold on;
        v0 = 0;
        v1 = max(dataZeroMedianFiltered);

        plot(peakIntervalRaw(:), dataZeroMedian(peakIntervalRaw(:),1),'.m');
        hold on;
        
        for i=1:1:size(peakBlocksRaw,1)
            idx0 = peakBlocksRaw(i,1);
            idx1 = peakBlocksRaw(i,2);
            plot([idx0;idx1;idx1;idx0;idx0],[v0;v0;v1;v1;v0],'-m');
            hold on;
        end

        plot(peakIntervalFiltered(:), dataZeroMedian(peakIntervalFiltered(:),1),'.c');
        hold on;

        for i=1:1:size(peakBlocksFiltered,1)
            idx0 = peakBlocksFiltered(i,1);
            idx1 = peakBlocksFiltered(i,2);
            plot([idx0;idx1;idx1;idx0;idx0],[v0;v0;v1;v1;v0],'-c');
            hold on;
        end
        here=1;
        
end


