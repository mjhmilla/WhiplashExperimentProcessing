function [participantMvcData, indicesMvcData]=...
     getParticipantMvcDataMay2022(participantId)


participantMvcData = [];


indicesMvcData.indexFlexion  =1;
indicesMvcData.indexExtension=2;
indicesMvcData.indexBendLeft =3;
indicesMvcData.indexBendRight=4;




switch participantId
    case 1
        %This is from the hand written notes
        participantMvcData.id           = participantId;

        participantMvcData.mvcForceN    = [ 114,   126.6;...
                                            256.3, 255;...
                                            123.9, 116;...
                                            180.9, 172.7];   
        participantMvcData.mvcFiles = ...
            {'Versuch00000011.mat',     'Versuch00000012.mat';...
             'Versuch00000004.mat',     'Versuch00000005.mat';
             'Versuch00000015.mat',     'Versuch00000016.mat';
             'Versuch00000008.mat',     'Versuch00000009.mat'};

    case 2
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        

    case 3
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        
           
    case 4
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        
        
    case 5
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        
       
    case 6
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        
              
    case 7 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        
                  
    case 8 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        
        
    case 9
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        
        
    case 10   
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        

    case 11
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        
       
    case 12
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        
        
    case 13 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        
        
    case 14 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        

    case 15 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        

    case 16 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        

    case 17 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        
 
    case 18 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        

    case 19 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        

    case 20 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        

    case 21
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        

    case 22
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        

    case 23 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        

    case 24 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        

    case 25 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        

    case 26 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        

    case 27 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        

    case 28 
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = zeros(4,2).*nan;   
        participantMvcData.mvcFiles     = cell(4,2) ;        

   otherwise
        assert(0, ['Error: particpantId is not within the range of 1-28,',...
            ' or the information for the requested participant has ',...
            'not yet been entered']);
end