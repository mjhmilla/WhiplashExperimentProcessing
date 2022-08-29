function [figH,indexSubplot] = addOnsetPlot(timeV, dataV, ...
    signalWindowInterval, noiseModelWindows, onsetWindows,  ...
    onsetColor, dataLabel, figH, subPlotPanel, indexSubplot)

figure(figH);
maxPlotCols = size(subPlotPanel,2);
maxPlotRows = size(subPlotPanel,1);

row = ceil(indexSubplot/maxPlotCols);
col = max(1,indexSubplot-(row-1)*maxPlotCols);

subplot('Position',reshape(subPlotPanel(row,col,:),1,4));


idxMin = 1;
idxMax = signalWindowInterval(1,2);

timeMin = min(timeV);
timeMax = max(timeV);




plot(timeV(idxMin:idxMax,1), dataV(idxMin:idxMax,1),...
    'Color',[1,1,1].*0.75,'LineWidth',2);
hold on;            

           

yLimMin = min(dataV);
yLimMax = max(dataV);

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

for k=1:1:size(onsetWindows,1)   
    i1 = onsetWindows(k,1);
    i2 = onsetWindows(k,2);
    t0 = timeV(i1,1);
    t1 = timeV(i2,1);     
    v1 = dataV(i1,1);
    v2 = dataV(i2,1);
    vMedian = median(dataV);
    vPos = max(dataV(i1:i2,1)-vMedian);
    vNeg = min(dataV(i1:i2,1)-vMedian);
    vVal = 0;
    vtt = 0;
    if(abs(vPos) >= abs(vNeg))
        vVal = max(dataV(i1:i2,1));
        vtt = vVal + vPos*0.1;
    else
        vVal = min(dataV(i1:i2,1));
        vtt = vVal + vNeg*0.1;
    end

    plot(timeV(i1:i2,1),dataV(i1:i2,1),'Color',onsetColor,'LineWidth',1);
    hold on;

    plot([t0;t1;t1;t0;t0],[v1;v2;vVal;vVal;v1],'Color',onsetColor);
    hold on;
    tt = t0-(t1-t0)*0.05;
    vt = v1;
    plot(t0,vVal,'.','Color',onsetColor,'MarkerFaceColor',onsetColor);                
    hold on;
    text(tt,vtt,sprintf('%1.3f',t0),...
        'VerticalAlignment','middle',...
        'HorizontalAlignment','left',...
        'Color',onsetColor);
    hold on;
    %axis tight;
    if((vtt+vPos*0.1) > yLimMax)
        yLimMax=(vtt+vPos*0.1);
    end
    if((vtt+vNeg*0.2)< yLimMin)
        yLimMin=vtt+vNeg*0.2;
    end
end

%Plot the window that is being analyzed for peaks
i1 = signalWindowInterval(1,1);
i2 = signalWindowInterval(1,2);

t0 = timeV(i1,1);
t1 = timeV(i2,1);     

plot(   [t0;t1;t1;t0;t0],...
        [yLimMin;yLimMin;yLimMax;yLimMax;yLimMin],...
        'Color',[0,0,1]);
hold on;


ylim([yLimMin,yLimMax]);
xlabel('Time (s)');
ylabel('Value');
titleString = ...
    replaceCharacter(dataLabel,'_',' ');
title(titleString(1,1:min(length(titleString),30) ));
box off;

indexSubplot=indexSubplot+1;