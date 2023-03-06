function [figH,indexSubplot] = addOnsetPlot(timeV, dataRaw, dataFiltered, ...
    signalWindowInterval, noiseModelWindows, onsetWindows,  ...
    onsetColor, dataLabel, figH, subPlotPanel, indexSubplot)

figure(figH);
maxPlotCols = size(subPlotPanel,2);
maxPlotRows = size(subPlotPanel,1);

row = ceil(indexSubplot/maxPlotCols);
col = max(1,indexSubplot-(row-1)*maxPlotCols);

subplot('Position',reshape(subPlotPanel(row,col,:),1,4));


idxMin = 1;
idxMax = length(timeV);
%idxMax = signalWindowInterval(1,2);

timeMin = min(timeV);
timeMax = max(timeV);


plot(timeV(idxMin:idxMax,1), dataRaw(idxMin:idxMax,1),...
    'Color',[1,1,1].*0.75,'LineWidth',0.5);
hold on; 

plot(timeV(idxMin:idxMax,1), dataFiltered(idxMin:idxMax,1),...
    'Color',[0,0,0],'LineWidth',1);
hold on;            

           

yLimMin = min(0,min(dataFiltered));
yLimMax = max([max(dataRaw),max(dataFiltered)]);

if(isempty(noiseModelWindows)==0)
    for k=1:1:size(noiseModelWindows,1)   
        i1 = noiseModelWindows(k,1);
        i2 = noiseModelWindows(k,2);
        t0 = timeV(i1,1);
        t1 = timeV(i2,1);     
        v0 = yLimMin;
        v1 = yLimMax*0.5;
    
        plot([t0;t1;t1;t0;t0],[v0;v0;v1;v1;v0],'Color',[1,0,0]);
        hold on;
    end
end

if(isempty(onsetWindows)==0)
    
    indexMaximumOnset = 0;
    valueMaximumOnset = -inf;
    for k=1:1:size(onsetWindows,1)  
        i1 = onsetWindows(k,1);
        i2 = onsetWindows(k,2);
        maxDataFilteredInterval=max(abs(dataFiltered(i1:i2,1)));
        if(maxDataFilteredInterval>valueMaximumOnset)
            valueMaximumOnset=maxDataFilteredInterval;
            indexMaximumOnset=k;
        end
    
    end
    
    for k=1:1:size(onsetWindows,1)   
        i1 = onsetWindows(k,1);
        i2 = onsetWindows(k,2);
        t0 = timeV(i1,1);
        t1 = timeV(i2,1);     
        v1 = dataFiltered(i1,1);
        v2 = dataFiltered(i2,1);
        vMedian = median(dataFiltered);
        vPos = max(dataFiltered(i1:i2,1)-vMedian);
        vNeg = min(dataFiltered(i1:i2,1)-vMedian);
        iVal = 0;
        vVal = 0;
        vtt = 0;
        if(abs(vPos) >= abs(vNeg))
            vVal = max(dataFiltered(i1:i2,1));
            vtt = vVal + (yLimMax-yLimMin)*0.1;
        else
            vVal = min(dataFiltered(i1:i2,1));
            vtt = vVal - (yLimMax-yLimMin)*0.1;
        end
    
        plot(timeV(i1:i2,1),dataFiltered(i1:i2,1),'Color',onsetColor,'LineWidth',2);
        hold on;
    
        plot([t0;t1;t1;t0;t0],[v1;v2;vVal;vVal;v1],'Color',onsetColor);
        hold on;
        tt = t0-(t1-t0)*0.05;
        vt = v1;
        plot(t0,vVal,'o','Color',onsetColor,'MarkerFaceColor',[1,1,1],'MarkerSize',4);                
        hold on;
    
        if(k==1)
            tt  = t0-(max(timeV)-min(timeV)).*0.05;
            vtt = yLimMax - (yLimMax-yLimMin)*0.15;
            plot([t0;tt],[vVal;vtt],'--','Color',onsetColor);
            hold on;        
            text(tt,vtt,sprintf('(%1.3f, %1.3f)',t0,vVal),...
                'VerticalAlignment','bottom',...
                'HorizontalAlignment','right',...
                'Color',onsetColor,...
                'FontSize',10);
            hold on;
        end
        %axis tight;
        if((vtt+vPos*0.1) > yLimMax)
            yLimMax=(vtt+vPos*0.1);
        end
        if((vtt+vNeg*0.2)< yLimMin)
            yLimMin=vtt+vNeg*0.2;
        end
    end
end

%Plot the window that is being analyzed for peaks
if(isempty(signalWindowInterval)==0)
    i1 = signalWindowInterval(1,1);
    i2 = signalWindowInterval(1,2);
    
    t0 = timeV(i1,1);
    t1 = timeV(i2,1);     
    
    plot(   [t0;t1;t1;t0;t0],...
            [yLimMin;yLimMin;yLimMax;yLimMax;yLimMin],...
            'Color',[0,0,1]);
    hold on;
end

ylim([yLimMin,yLimMax]);
xlabel('Time (s)');
ylabel('Value');
titleString = ...
    replaceCharacter(dataLabel,'_',' ');
title(titleString(1,1:min(length(titleString),30) ));
box off;

indexSubplot=indexSubplot+1;