function [participantMvcData, indicesMvcData, namesMvcData]=...
     getParticipantMvcDataFebruary2023(participantId)


participantMvcData = [];
participantMvcData.ignore = [];

indicesMvcData.indexExtension=1;
indicesMvcData.indexBendRight=2;
indicesMvcData.indexFlexion  =3;
indicesMvcData.indexBendLeft =4;

namesMvcData = {'Extension','Right','Flexion','Left'};


switch participantId
    case 1
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 198, 189;...
                                            119, 117;...
                                            146, 148;...
                                             83,  83];   
        participantMvcData.mvcFiles = ...
            {'Versuch00000007.mat',     'Versuch00000008.mat';...
             'Versuch00000011.mat',     'Versuch00000012.mat';...
             'Versuch00000014.mat',     'Versuch00000015.mat';...
             'Versuch00000018.mat',     'Versuch00000019.mat'};

    case 2
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 200, 209;...
                                            103, 121;... 
                                            107, 104;...
                                            135,143];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000022.mat',     'Versuch00000023.mat';...
            'Versuch00000025.mat',      'Versuch00000027.mat';...
            'Versuch00000029.mat',      'Versuch00000030.mat';...
            'Versuch00000034.mat',      'Versuch00000035.mat'};

    case 3
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 247, 245;...
                                            162, 169;...
                                            179, 184;...
                                            177, 179];   
        participantMvcData.mvcFiles     = ...
            {'Versuch00000040.mat',     'Versuch00000041.mat';...
            'Versuch00000043.mat',      'Versuch00000045.mat';...
            'Versuch00000047.mat',      'Versuch00000048.mat';...
            'Versuch00000050.mat',      'Versuch00000052.mat'};
           
    case 4
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [235, 227;...
                                            133, 139;...
                                            114, 117;...
                                            146, 140];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000056.mat',     'Versuch00000057.mat';...
            'Versuch00000061.mat',      'Versuch00000062.mat';...
            'Versuch00000064.mat',      'Versuch00000065.mat';...
            'Versuch00000070.mat',      'Versuch00000071.mat'};
        
    case 5
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [273, 270;...
                                            170, 169;...
                                            120, 117;...
                                            151, 153];
            
        participantMvcData.mvcFiles     = ...
            {'Versuch00000075.mat',     'Versuch00000077.mat';...
            'Versuch00000079.mat',      'Versuch00000081.mat';...
            'Versuch00000085.mat',      'Versuch00000086.mat';...
            'Versuch00000088.mat',      'Versuch00000090.mat'};
       
    case 6
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [266, 256;...
                                                168, 164;...
                                                135, 142;...
                                                187, 193];
        participantMvcData.mvcFiles     = ...
            { 'Versuch00000093.mat',         'Versuch00000094.mat';...
             'Versuch00000096.mat',          'Versuch00000097.mat';...
              'Versuch00000099.mat',         'Versuch00000101.mat';...
               'Versuch00000103.mat',        'Versuch00000104.mat'};
              
    case 7 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [157, 154;...
                                                   97, 99;...
                                                   66, 71;...
                                                   100, 105];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000003.mat',     'Versuch00000005.mat';...
            'Versuch00000008.mat',      'Versuch00000009.mat';...
            'Versuch00000011.mat',      'Versuch00000012.mat';...
            'Versuch00000014.mat',      'Versuch00000015.mat'};
                  
    case 8 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [125, 121;...
                                                125, 125;...
                                                220, 212;...
                                                137, 140];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000020.mat',     'Versuch00000021.mat';...
            'Versuch00000023.mat',      'Versuch00000026.mat';...
            'Versuch00000030.mat',      'Versuch00000031.mat';...
            'Versuch00000033.mat',      'Versuch00000034.mat'};
            
    case 9
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [244, 223;...
                                          168, 163;...
                                                   248, 259;...
                                                   167, 169];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000041.mat',     'Versuch00000042.mat';...
            'Versuch00000045.mat',      'Versuch00000046.mat';...
            'Versuch00000048.mat',      'Versuch00000049.mat';...
            'Versuch00000051.mat',      'Versuch00000052.mat'};

%        participantMvcData.ignore = ...
%            struct('mvcFiles','Versuch00000041.mat',...
%                   'biopacChannel', {'STR_R','TRO_L'});
        
    case 10   
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [179, 172;...
                                                   109, 111;...
                                                   83, 85;...
                                                   94, 93];
        participantMvcData.mvcFiles     = ...
            { 'Versuch00000058.mat',         'Versuch00000059.mat';...
             'Versuch00000061.mat',           'Versuch00000063.mat';...
              'Versuch00000066.mat',         'Versuch00000067.mat';...
               'Versuch00000069.mat',        'Versuch00000070.mat'};

    case 11
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [188, 189;...
                                                   115, 104;...
                                                   94, 96;...
                                                   105, 109];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000073.mat',     'Versuch00000074.mat';...
            'Versuch00000076.mat',     'Versuch00000078.mat';...
            'Versuch00000081.mat',      'Versuch00000082.mat';...
            'Versuch00000085.mat',      'Versuch00000086.mat'};
       
    case 12
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [137, 136;...
                                                    81, 81;...
                                                    65, 69;...
                                                    93, 98];
        participantMvcData.mvcFiles     = ...
            { 'Versuch00000088.mat',         'Versuch00000089.mat';...
             'Versuch00000091.mat',          'Versuch00000092.mat';...
              'Versuch00000094.mat',         'Versuch00000095.mat';...
               'Versuch00000097.mat',        'Versuch00000098.mat'};
        
    case 13 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    =    [185, 169;...
                                                   121, 116;...
                                                   105, 96;...
                                                   131, 137];                                                  
        participantMvcData.mvcFiles     = ...
            {'Versuch00000005.mat',     'Versuch00000007.mat';...
            'Versuch00000011.mat',      'Versuch00000012.mat';...
            'Versuch00000015.mat',      'Versuch00000016.mat';...
            'Versuch00000021.mat',      'Versuch00000022.mat'};
        
    case 14 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [126, 142;...
                                                    95, 91;...
                                                    63, 66;...
                                                    69, 67];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000026.mat',     'Versuch00000027.mat';...
            'Versuch00000030.mat',      'Versuch00000031.mat';...
            'Versuch00000033.mat',      'Versuch00000034.mat';...
            'Versuch00000036.mat',      'Versuch00000038.mat'};

    case 15 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [136, 137;...
                                                    86, 85;...
                                                    54, 52;...
                                                    88, 91];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000001.mat',     'Versuch00000003.mat';...
            'Versuch00000009.mat',      'Versuch00000010.mat'...
            'Versuch00000012.mat',      'Versuch00000014.mat'...
            'Versuch00000017.mat',      'Versuch00000019.mat'};

    case 16 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [156, 155;...
                                            87, 92;...
                                            79, 77;...
                                            80, 79];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000021.mat',     'Versuch00000023.mat';...
            'Versuch00000025.mat',      'Versuch00000026.mat';...
            'Versuch00000028.mat',      'Versuch00000029.mat';...
            'Versuch00000033.mat',      'Versuch00000034.mat'};

    case 17 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [151, 155;...
                                                    109, 107;...
                                                    107, 108;...
                                                    79, 77];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000009.mat',     'Versuch00000010.mat';...
            'Versuch00000015.mat',      'Versuch00000016.mat';...
            'Versuch00000019.mat',      'Versuch00000020.mat';...
            'Versuch00000022.mat',      'Versuch00000025.mat'};
 
    case 18 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [215, 214;...
                                                    122, 130;...
                                                    125, 131;...
                                                    107, 111];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000030.mat',     'Versuch00000031.mat';...
            'Versuch00000034.mat',      'Versuch00000035.mat';...
            'Versuch00000038.mat',      'Versuch00000039.mat';...
            'Versuch00000042.mat',      'Versuch00000043.mat'};

    case 19 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [140, 142;...
                                                   89, 85;...
                                                   89, 91;...
                                                   74, 76];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000002.mat',     'Versuch00000004.mat';...
            'Versuch00000006.mat',      'Versuch00000007.mat';...
            'Versuch00000010.mat',      'Versuch00000011.mat';...
            'Versuch00000013.mat',      'Versuch00000015.mat'};

    case 20 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [191, 187;...
                                                    75, 79;...
                                                    91, 88;...
                                                    76, 77];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000018.mat',     'Versuch00000020.mat';...
            'Versuch00000022.mat',      'Versuch00000023.mat';...
            'Versuch00000026.mat',      'Versuch00000027.mat',...
            'Versuch00000029.mat',      'Versuch00000030.mat'};

    case 21
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [99, 97;...
                                                35, 32;...
                                                48, 48;...
                                                28, 29];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000033.mat',     'Versuch00000034.mat';...
            'Versuch00000037.mat',      'Versuch00000038.mat';...
            'Versuch00000040.mat',      'Versuch00000042.mat';...
            'Versuch00000044.mat',      'Versuch00000045.mat'};

    case 22
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [123, 130;...
                                                84, 87;...
                                                113, 114;...
                                                75, 79];                                            
        participantMvcData.mvcFiles     = ...
            {'Versuch00000048.mat',     'Versuch00000050.mat';...
            'Versuch00000052.mat',      'Versuch00000053.mat';...
            'Versuch00000055.mat',      'Versuch00000056.mat';...
            'Versuch00000058.mat',      'Versuch00000059.mat'};

    case 23 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [124, 123;...
                                                45, 44;...
                                                70, 67;...
                                                60, 61];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000065.mat',     'Versuch00000066.mat';...
            'Versuch00000068.mat',      'Versuch00000069.mat';...
            'Versuch00000071.mat',      'Versuch00000072.mat';...
            'Versuch00000074.mat',      'Versuch00000073.mat'};

    case 24 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [292, 278;...
                                                143, 144;...
                                                194, 186;...
                                                152, 157];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000078.mat',     'Versuch00000080.mat';...
            'Versuch00000083.mat',      'Versuch00000085.mat';...
            'Versuch00000087.mat',      'Versuch00000089.mat';...
            'Versuch00000091.mat',      'Versuch00000092.mat'};

    case 25 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [299, 293;...
                                                184, 184;...
                                                164, 165;...
                                                165, 157];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000003.mat',     'Versuch00000004.mat';...
            'Versuch00000009.mat',      'Versuch00000011.mat';...
            'Versuch00000013.mat',      'Versuch00000015.mat';...
            'Versuch00000017.mat',      'Versuch00000018.mat'};

    case 26 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [167, 163;...
                                                106, 108;...
                                                70, 70;...
                                                95, 95];
        participantMvcData.mvcFiles     = ....
            {'Versuch00000022.mat',     'Versuch00000023.mat';...
            'Versuch00000026.mat',      'Versuch00000027.mat';...
            'Versuch00000029.mat',      'Versuch00000030.mat';...
            'Versuch00000032.mat',      'Versuch00000036.mat'};

    case 27 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [82, 86;...
                                                55, 56;...
                                                43, 41;...
                                                51, 51];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000003.mat',     'Versuch00000004.mat';...
            'Versuch00000007.mat',      'Versuch00000008.mat';...
            'Versuch00000010.mat',      'Versuch00000011.mat';...
            'Versuch00000013.mat',      'Versuch00000014.mat'};

    case 28 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [182, 177;...
                                               115, 119;...
                                               101, 104;...
                                               111, 112];
        participantMvcData.mvcFiles     = ...
            {'Versuch00000018.mat',     'Versuch00000021.mat';...
            'Versuch00000025.mat',      'Versuch00000026.mat';...
            'Versuch00000028.mat',      'Versuch00000029.mat';...
            'Versuch00000032.mat',      'Versuch00000033.mat'};

   otherwise
        assert(0, ['Error: particpantId is not within the range of 1-28,',...
            ' or the information for the requested participant has ',...
            'not yet been entered']);
        
%         for i=1:height(participantMvcData.mvcFiles)
%             for j=1:width(participantMvcData.mvcFiles)
%                 if participantMvcData.mvcFiles(i,j) <= A 
%                     %trial should be ignored
%                 end
%             end
%         end
end
%% CC
%Next, there's something else that should be added to getParticipantMvcData2023: 
%a field to ignore a file. If you run the script and look at 
%output2023/participant01/mvc/biopac/fig_MVC_TRU_R.png the left trials should 
%be ignored: it looks like the electrode fell off, or something weird happened.

%With a trial like this I would like to be able to set an 'ignore' flag somewhere in 
%getParticipantMvcData2023 so that the values used in this trial is not used. 
%Think about how you might do that.

%ideas
        % if all emg data are under a certain threshold for one trial it should
        % be ignored
                %maybe calculate the mean or look at the max amplitude







