function [participantMvcData, indicesMvcData,namesMvcData]=...
     getParticipantMvcDataMay2022(participantId)


participantMvcData = [];


indicesMvcData.indexBendRight=1;
indicesMvcData.indexFlexion  =2;
indicesMvcData.indexBendLeft =3;
indicesMvcData.indexExtension=4;

namesMvcData = {'Right','Flexion','Left','Extension'};


switch participantId
    case 1
        %This is from the hand written notes
        participantMvcData.id           = participantId;

        participantMvcData.mvcForceN    = [ 180.9, 172.7;...
                                            114.1, 126.6;...
                                            123.9, 116;...
                                            256.3, 255.1];   
        participantMvcData.mvcFiles = ...
            {'Versuch00000008.mat',     'Versuch00000009.mat';...
             'Versuch00000011.mat',     'Versuch00000012.mat';
             'Versuch00000015.mat',     'Versuch00000016.mat';
             'Versuch00000004.mat',     'Versuch00000005.mat'};

    case 2
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 85.4,   85.7;...
                                            164.8,   171.8;...
                                            123,     117;...
                                            213.9,    223]; 

        participantMvcData.mvcFiles     = ...
            {'Versuch00000019.mat',     'Versuch00000022.mat';...
             'Versuch00000024.mat',     'Versuch00000025.mat';
             'Versuch00000030.mat',     'Versuch00000031.mat';
             'Versuch00000035.mat',     'Versuch00000036.mat'};         

    case 3
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 126.647, 130.92; ...
                                            144.348, 138.854;...
                                            145.568, 145.263;...
                                            133.361, 132.751];    
        participantMvcData.mvcFiles     = ...
            {'Versuch00000042.mat',     'Versuch00000044.mat';...
             'Versuch00000047.mat',     'Versuch00000048.mat';
             'Versuch00000050.mat',     'Versuch00000051.mat';
             'Versuch00000054.mat',     'Versuch00000055.mat'};      
           
    case 4
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 90.026, 93.688;...
                                            98.571, 101.62;...
                                            75.073, 73.242;...
                                            101.623, 101.318];    
        participantMvcData.mvcFiles     = ...
            {'Versuch00000069.mat',     'Versuch00000070.mat';...
             'Versuch00000072.mat',     'Versuch00000075.mat';
             'Versuch00000077.mat',     'Versuch00000078.mat';
             'Versuch00000081.mat',     'Versuch00000084.mat'};       
        
    case 5
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 157.4, 162.6;...
                                            109.5, 116.2;...
                                            165.4, 163.8;...
                                            179.1, 180];   
        participantMvcData.mvcFiles     = ...
            {'Versuch00000003.mat',     'Versuch00000004.mat';...
             'Versuch00000006.mat',     'Versuch00000007.mat';
             'Versuch00000009.mat',     'Versuch00000010.mat';
             'Versuch00000012.mat',     'Versuch00000013.mat'};       
       
    case 6
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 141, 141.3;...
                                            144.7, 151.5;...
                                            140.6, 145;...
                                            225, 222];    
        participantMvcData.mvcFiles     = ...
            {'Versuch00000018.mat',     'Versuch00000019.mat';...
             'Versuch00000022.mat',     'Versuch00000023.mat';
             'Versuch00000026.mat',     'Versuch00000028.mat';
             'Versuch00000032.mat',     'Versuch00000033.mat'};       
              
    case 7 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 94.9, 92.5;...
                                            72.6, 74.4;...
                                            72.326, 72.326;...
                                            74.1, 75.6];    
        participantMvcData.mvcFiles     = ...
            {'Versuch00000039.mat',     'Versuch00000040.mat';...
             'Versuch00000043.mat',     'Versuch00000045.mat';
             'Versuch00000050.mat',     'Versuch00000051.mat';
             'Versuch00000053.mat',     'Versuch00000056.mat'};         
                  
    case 8 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 157.7, 160.5;...
                                            103.4, 107.4;...
                                            151.6, 155;...
                                            181.8, 186.4];    
        participantMvcData.mvcFiles     = ...
            {'Versuch0001.mat',     'Versuch0002.mat';...
             'Versuch0004.mat',     'Versuch0005.mat';
             'Versuch0010.mat',     'Versuch0012.mat';
             'Versuch0015.mat',     'Versuch0016.mat'};         
        
    case 9
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 147.7, 145.2;...
                                            137, 138.5;...
                                            123.5, 122.4;...
                                            184.346, 179.133];   
        participantMvcData.mvcFiles     = ...
            {'Versuch00000002.mat',     'Versuch00000003.mat';...
             'Versuch00000006.mat',     'Versuch00000008.mat';
             'Versuch00000010.mat',     'Versuch00000012.mat';
             'Versuch00000015.mat',     'Versuch00000016.mat'};      
        
    case 10   
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 84, 89;...
                                            64, 64;...
                                            81, 81;...
                                            130, 128];   
        participantMvcData.mvcFiles     = ...
            {'Versuch000000000003.mat',     'Versuch000000000004.mat';...
             'Versuch000000000007.mat',     'Versuch000000000009.mat';
             'Versuch000000000012.mat',     'Versuch000000000013.mat';
             'Versuch000000000017.mat',     'Versuch000000000018.mat'};        

    case 11
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 177, 186;...
                                            119, 121;...
                                            199, 204;...
                                            350, 343];    
        participantMvcData.mvcFiles     = ...
            {'Versuch00000001.mat',     'Versuch00000003.mat';...
             'Versuch00000006.mat',     'Versuch00000009.mat';
             'Versuch00000012.mat',     'Versuch00000013.mat';
             'Versuch00000017.mat',     'Versuch00000018.mat'};        
       
    case 12
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 139, 134;...
                                            102, 105;...
                                            150, 155;...
                                            154, 153];    
        participantMvcData.mvcFiles     = ...
            {'Versuch00000001.mat',     'Versuch00000002.mat';...
             'Versuch00000004.mat',     'Versuch00000005.mat';
             'Versuch00000009.mat',     'Versuch00000011.mat';
             'Versuch00000013.mat',     'Versuch00000014.mat'};       
        
    case 13 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 85, 86;...
                                            104, 105;...
                                            87, 91;...
                                            132, 132];   
        participantMvcData.mvcFiles     = ...
            {'Versuch00000001.mat',     'Versuch00000002.mat';...
             'Versuch00000005.mat',     'Versuch00000006.mat';
             'Versuch00000010.mat',     'Versuch00000011.mat';
             'Versuch00000016.mat',     'Versuch00000017.mat'};       
        
    case 14 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 101, 104;...
                                            79, 76;...
                                            123, 120;...
                                            128, 124];    
        participantMvcData.mvcFiles     = ...
            {'Versuch00000002.mat',     'Versuch00000003.mat';...
             'Versuch00000005.mat',     'Versuch00000006.mat';
             'Versuch00000010.mat',     'Versuch00000011.mat';
             'Versuch00000013.mat',     'Versuch00000014.mat'};        

    case 15 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 116, 118;...
                                            84, 80;...
                                            119, 113;...
                                            139, 141];   
        participantMvcData.mvcFiles     = ...
            {'Versuch00000001.mat',     'Versuch00000002.mat';...
             'Versuch00000004.mat',     'Versuch00000005.mat';
             'Versuch00000008.mat',     'Versuch00000009.mat';
             'Versuch00000011.mat',     'Versuch00000013.mat'};        

    case 16 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 151.9, 157.7;...
                                            158.4, 153.8;...
                                            178.2, 180;...
                                            220, 211];    
        participantMvcData.mvcFiles     = ...
            {'Versuch00000002.mat',     'Versuch00000003.mat';...
             'Versuch00000006.mat',     'Versuch00000007.mat';
             'Versuch00000011.mat',     'Versuch00000015.mat';
             'Versuch00000017.mat',     'Versuch00000018.mat'};        

    case 17 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 100, 101.9;...
                                            71.4, 73.8;...
                                            89.7, 93;...
                                            140, 136];   
        participantMvcData.mvcFiles     = ...
            {'Versuch00000003.mat',     'Versuch00000004.mat';...
             'Versuch00000006.mat',     'Versuch00000007.mat';
             'Versuch00000009.mat',     'Versuch00000011.mat';
             'Versuch00000015.mat',     'Versuch00000017.mat'};        
 
    case 18 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 113.8, 110.4;...
                                            83.6, 87.8;...
                                            122, 115;...
                                            160, 165];    
        participantMvcData.mvcFiles     = ...
            {'Versuch00000026.mat',     'Versuch00000027.mat';...
             'Versuch00000029.mat',     'Versuch00000030.mat';
             'Versuch00000036.mat',     'Versuch00000037.mat';
             'Versuch00000040.mat',     'Versuch00000041.mat'};        

    case 19 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 227, 232;...
                                            205, 213;...
                                            209, 222.7;...
                                            210, 219];   
        participantMvcData.mvcFiles     = ...
            {'Versuch00000049.mat',     'Versuch00000050.mat';...
             'Versuch00000054.mat',     'Versuch00000055.mat';
             'Versuch00000057.mat',     'Versuch00000058.mat';
             'Versuch00000062.mat',     'Versuch00000064.mat'};       

    case 20 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 205.9, 207.2;...
                                            223.1, 222.1;...
                                            138, 143;...
                                            201, 203.2];   
        participantMvcData.mvcFiles     = ...
            {'Versuch00000012.mat',     'Versuch00000013.mat';...
             'Versuch00000018.mat',     'Versuch00000020.mat';
             'Versuch00000022.mat',     'Versuch00000023.mat';
             'Versuch00000025.mat',     'Versuch00000026.mat'};        

    case 21
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 153.8, 160;...
                                            80, 84;...
                                            120, 121.4;...
                                            185, 193.7];    
        participantMvcData.mvcFiles     = ...
            {'Versuch00000034.mat',     'Versuch00000035.mat';...
             'Versuch00000037.mat',     'Versuch00000038.mat';
             'Versuch00000042.mat',     'Versuch00000043.mat';
             'Versuch00000045.mat',     'Versuch00000046.mat'};       

       

   otherwise
        assert(0, ['Error: particpantId is not within the range of 1-21,',...
            ' or the information for the requested participant has ',...
            'not yet been entered']);
end