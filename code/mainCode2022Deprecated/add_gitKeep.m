clc;
close all;
clear all;

gitKeepPath = pwd;
gitKeepPath = fullfile(gitKeepPath,'.gitkeep');

cd('output2022');
outputPaths = dir('**/*.*') ;



for i=1:1:length(outputPaths)

    if(outputPaths(i).isdir==1)
        copyfile(gitKeepPath,  outputPaths(i).folder,'f');
    end
end