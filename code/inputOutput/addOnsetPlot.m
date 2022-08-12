function [figH,indexSubplot] = addOnsetPlot(timeV, dataV, windowInterval,...
    thresholdStruct,  dataLabel, figH, subPlotPanel, indexSubplot)

figure(figH);
maxPlotCols = size(subPlotPanel,2);
maxPlotRows = size(subPlotPanel,1);

row = ceil(indexSubplot/maxPlotCols);
col = max(1,indexSubplot-(row-1)*maxPlotCols);

subplot('Position',reshape(subPlotPanel(row,col,:),1,4));


timeMin = min(timeV);
timeMax = max(timeV);

middleThresholds = ...
    thresholdStruct.middleThresholds;
maximumThresholds = ...
    thresholdStruct.maximumThresholds;
intervals = ...
    thresholdStruct.intervals;

if(isnan(middleThresholds)==0)
    fill([timeMin;timeMax;timeMax;timeMin;timeMin],...
         [middleThresholds(1,1);middleThresholds(1,1);...
          middleThresholds(1,2);middleThresholds(1,2);...
          middleThresholds(1,1)],[1,1,1].*0.75,...
         'EdgeColor','none');
    hold on;
end

if(isnan(middleThresholds)==0)
    plot([timeMin;timeMax],[1;1].*maximumThresholds(1,1),'--','Color',[0,0,0]);
    hold on;            
    plot([timeMin;timeMax],[1;1].*maximumThresholds(1,2),'--','Color',[0,0,0]);
    hold on;            
end


plot(timeV, dataV,'Color',[1,1,1].*0.5);
hold on;            

idxWindow = [windowInterval(1,1):1:windowInterval(1,2)];
plot(timeV(idxWindow,1), dataV(idxWindow,1),'Color',[1,1,1].*0);
hold on;            

yLimMin = min(dataV);
yLimMax = max(dataV);
for k=1:1:size(intervals,1)   
    i1 = intervals(k,1);
    i2 = intervals(k,2);
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

    plot([t0;t1;t1;t0;t0],[v1;v2;vVal;vVal;v1],'Color',[1,0,0]);
    hold on;
    tt = t0-(t1-t0)*0.05;
    vt = v1;
    plot(tt,vt,'o','Color',[1,0,0]);                
    hold on;
    text(tt,vtt,sprintf('%1.3f',t0),...
        'VerticalAlignment','middle',...
        'HorizontalAlignment','left');
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
i1 = windowInterval(1,1);
i2 = windowInterval(1,2);

t0 = timeV(i1,1);
t1 = timeV(i2,1);     
vMax = max(dataV);
vMin = min(dataV);

plot([t0;t1;t1;t0;t0],[vMin;vMin;vMax;vMax;vMin],'Color',[0,0,1]);
hold on;



ylim([yLimMin,yLimMax]);
xlabel('Time (s)');
ylabel('Value');
titleString = ...
    replaceCharacter(dataLabel,'_',' ');
title(titleString(1,1:min(length(titleString),30) ));
box off;

indexSubplot=indexSubplot+1;