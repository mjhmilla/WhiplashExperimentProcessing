function [figH,indexSubplot] = addAccelerationXYZPlot(timeV, accXYZ, ...
    peakIntervals, dataLabel, figH, subPlotPanel, indexSubplot)

figure(figH);
maxPlotCols = size(subPlotPanel,2);
maxPlotRows = size(subPlotPanel,1);

row = ceil(indexSubplot/maxPlotCols);
col = max(1,indexSubplot-(row-1)*maxPlotCols);

subplot('Position',reshape(subPlotPanel(row,col,:),1,4));


idxMin = 1;
idxMax = length(timeV);

yLimMin = inf;
yLimMax = -inf;


for i=1:1:size(accXYZ,2)

    lineColor = zeros(1,3);
    lineColor(1,i)=1;
    lineColor = lineColor.*0.25 + [0.5,0.5,0.5].*0.75;


    plot(timeV(idxMin:idxMax,1), ...
        accXYZ(idxMin:idxMax,i),...
        'Color',lineColor,'LineWidth',1);
    hold on;            

    if(max(accXYZ(idxMin:idxMax,i)) > yLimMax)
        yLimMax=max(accXYZ(idxMin:idxMax,i));
    end
    if(min(accXYZ(idxMin:idxMax,i)) < yLimMin)
        yLimMin=min(accXYZ(idxMin:idxMax,i));
    end
    
end
           
timeMin = min(timeV);
timeMax = max(timeV);

for k=1:1:size(peakIntervals,1)   
    i1 = peakIntervals(k,1);
    i2 = peakIntervals(k,2);
    t0 = timeV(i1,1);
    t1 = timeV(i2,1); 


    for i=1:1:3
        v1 = accXYZ(i1,i);
        v2 = accXYZ(i2,i);
        vMedian = median(accXYZ);
        vPos = max(accXYZ(i1:i2,1)-vMedian);
        vNeg = min(accXYZ(i1:i2,1)-vMedian);
        vVal = 0;
        vtt = 0;
        if(abs(vPos) >= abs(vNeg))
            vVal = max(accXYZ(i1:i2,i));
            vtt = vVal - (yLimMax-yLimMin)*0.25;
        else
            vVal = min(accXYZ(i1:i2,i));
            vtt = vVal + (yLimMax-yLimMin)*0.25;
        end
    
        onsetColor = zeros(1,3);
        onsetColor(1,i)=1;
        plot(timeV(i1:i2,1),accXYZ(i1:i2,i),'Color',onsetColor,'LineWidth',2);
        hold on;
    
        plot([t0;t1;t1;t0;t0],[v1;v2;vVal;vVal;v1],'Color',onsetColor);
        hold on;
        tt = t1+(t1-t0)*0.25;
        vt = v1;
        plot(t0,vVal,'.','Color',onsetColor,'MarkerFaceColor',onsetColor);                
        hold on;
        text(tt,vtt,sprintf('(%1.1f,%1.1f)',t0,vVal),...
            'VerticalAlignment','middle',...
            'HorizontalAlignment','left',...
            'Color',onsetColor);
        hold on;
        %axis tight;
    end
%     if((vtt+vPos*0.1) > yLimMax)
%         yLimMax=(vtt+vPos*0.1);
%     end
%     if((vtt+vNeg*0.2)< yLimMin)
%         yLimMin=vtt+vNeg*0.2;
%     end
end


ylim([yLimMin,yLimMax]);
xlabel('Time (s)');
ylabel('Value');
titleString = ...
    replaceCharacter(dataLabel,'_',' ');
title(titleString(1,1:min(length(titleString),30) ));
box off;

indexSubplot=indexSubplot+1;