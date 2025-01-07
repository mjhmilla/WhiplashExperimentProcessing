function success = findReplaceLinesInFile(inputFileName,outputFileName, ...
            findLinesWithThisKeyword, replaceWithThisLine )

success     = 0;

fidInput    = fopen(inputFileName,'r');


fidOutput   = fopen(outputFileName,'w');


inputLine = fgetl(fidInput);

while ischar(inputLine)

    idxFound = nan;
    i=1;
    while( i <= length(findLinesWithThisKeyword) )
        if(contains(inputLine,findLinesWithThisKeyword{i}))
            idxFound = i;
            break;
        end
        i=i+1;
    end

    outputLine=inputLine;
    if(~isnan(idxFound))
       outputLine = replaceWithThisLine{idxFound};
       idxStart = strfind(inputLine,findLinesWithThisKeyword{idxFound});
       idxStart = idxStart-1;
       outputLine = [inputLine(1:idxStart),outputLine];
    end 

    fprintf(fidOutput,'%s\r\n',outputLine);
    inputLine = fgetl(fidInput);    
end

fclose(fidInput);
fclose(fidOutput);
fclose('all');

success     = 1;