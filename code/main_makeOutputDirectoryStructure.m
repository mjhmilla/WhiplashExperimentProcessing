clc;
close all;
clear all;

cd('../output');

for i=1:1:20
    strNum = num2str(i);
    if(length(strNum)<2)
        strNum = ['0',strNum];
    end
    participantDir = ['participant',strNum];
    mkdir(['participant',strNum]);
    cd(participantDir);
    mkdir('car');
    mkdir('mvc');
    cd('car');
    mkdir('biopac');
    mkdir('optitrack');
    cd ..
    cd('mvc');
    mkdir('biopac');
    mkdir('optitrack');
    cd ../..;
    
end