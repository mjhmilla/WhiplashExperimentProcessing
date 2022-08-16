function [peakIntervalRaw,peakIntervalFiltered,data,dataFilt] = ...
            findOnsetUsingNoiseModel(data, ...
                                    signalWindow,...
                                    noiseWindow,...                                                                        
                                    maxAcceptableNoiseProbability,...
                                    lowFrequencyFilterCutoff,...
                                    sampleFrequency,...
                                    typeOfNoiseModel,...
                                    flag_plotDetails)

peakIntervalRaw = []; 
peakIntervalFiltered = []; 

noisePdf = [];

assert(length(signalWindow)==2,...
    ['Error: indicesOfWindow must contain 2 ',...
     'entries: the beginning and end of the window']);

assert(signalWindow(1,1) > 2);
assert(signalWindow(1,2) < (length(data)-1));

windowStart = signalWindow(1,1);
windowEnd   = signalWindow(1,2);

signalIndices   = [signalWindow(1,1):1:signalWindow(1,2)]';
noiseIndices    = [noiseWindow(1,1):1:noiseWindow(1,2)]';


dataMedian=median(data);
data = data-dataMedian;
data = abs(data);


dataFilt = [];
if(isnan(lowFrequencyFilterCutoff)==0)
    [b,a] = butter(2,lowFrequencyFilterCutoff/(sampleFrequency*0.5),'low');
    dataFilt = filtfilt(b,a,data);
end







%%
%Evaluate the distribution of the data
%%

[noisePdfNum,noisePdfEdges] = histcounts(data(noiseIndices),...
    'Normalization','probability','BinMethod','sturges');

noiseModelCoeff = fitProbabilityDistribution(...
                    noisePdfEdges,noisePdfNum,...
                    maxAcceptableNoiseProbability,typeOfNoiseModel);

noiseFiltModelCoeff = [];
noiseFiltPdfNum     = [];
noiseFiltPdfEdges   = [];

if(isnan(lowFrequencyFilterCutoff)==0)
    [noiseFiltPdfNum,noiseFiltPdfEdges] = histcounts(dataFilt(noiseIndices),...
        'Normalization','probability','BinMethod','sturges');
    
    noiseFiltModelCoeff = fitProbabilityDistribution(...
                    noiseFiltPdfEdges,noiseFiltPdfNum,...
                    maxAcceptableNoiseProbability,typeOfNoiseModel);    
end


if(flag_plotDetails==1)
    figDebug=figure;

    subplot(3,1,1);
    plot(data,'Color',[1,1,1].*0.5,'DisplayName','Signal');    
    hold on; 
    
    %Analysis window
    minVal = min(data(signalIndices,1));
    maxVal = max(data(signalIndices,1));
    indexLeft = signalWindow(1,1);
    indexRight= signalWindow(1,2);

    plot([indexLeft;indexRight;indexRight;indexLeft;indexLeft],...
         [minVal;minVal;maxVal;maxVal;minVal],'b');

    hold on;

    %noise window
    minVal = min(data(noiseIndices,1));
    maxVal = max(data(noiseIndices,1));
    indexLeft = noiseIndices(1,1);
    indexRight= noiseIndices(end,1);

    plot([indexLeft;indexRight;indexRight;indexLeft;indexLeft],...
         [minVal;minVal;maxVal;maxVal;minVal],'r');

    hold on;
    

    if(isnan(lowFrequencyFilterCutoff)==0)
        plot(dataFilt,'k','DisplayName','Lpf Signal');
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

    %If the data has been filtered, also
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

    vF = data(idx,1);
    pF = 0;
    mF = 0;
    if(isnan(lowFrequencyFilterCutoff)==0)
        if(isempty(noiseFiltModelCoeff.localMaxima)==0)
            mF = max(noiseFiltModelCoeff.localMaxima);
        end
        if(isempty(dataFilt)==0)
            vF = dataFilt(idx,1);    
            pF = evaluateProbabilityDistribution(...
                    vF,noiseFiltModelCoeff.coeff,...
                    typeOfNoiseModel);
        end
    end

    v = data(idx,1);
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


if(flag_plotDetails==1)
    subplot(3,1,1);
        plot(dataFilt,'k');
        hold on;
        plot(peakIntervalRaw(:), data(peakIntervalRaw(:),1),'.m');
        hold on;
        plot(peakIntervalFiltered(:), data(peakIntervalFiltered(:),1),'.c');
        hold on;
        
end


