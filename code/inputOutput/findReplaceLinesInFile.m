function success = findReplaceLinesInFile(inputFileName,outputFileName, ...
            findLinesWithThisKeyword, replaceWithThisLine )

success     = 0;
fidInput    = fopen(inputFileName,'r');
fidOutput   = fopen(outputFileName,'w');

inputLine = fgetl(fidInput);

fprintf(fidOutput,'%s\n',inputLine);

fclose(fid);
success     = 1;