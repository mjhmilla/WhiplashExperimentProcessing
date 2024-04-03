function figH = addBox(figH, x0,x1,y0,y1,rgbColor,typeOfBox)

switch typeOfBox
    case 0
        plot([x0;x1;x1;x0;x0],[y0;y0;y1;y1;y0],'Color',rgbColor);
        hold on;
    case 1
        fill([x0;x1;x1;x0;x0],[y0;y0;y1;y1;y0],rgbColor,...
            'FaceAlpha',0.5,'EdgeColor','none');
        hold on;
end