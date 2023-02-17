function [participantMvcData, indicesMvcData]=...
     getParticipantMvcDataFebruary2023(participantId)


participantMvcData = [];

indicesMvcData.indexExtension=1;
indicesMvcData.indexBendRight=2;
indicesMvcData.indexFlexion  =3;
indicesMvcData.indexBendLeft =4;




switch participantId
    case 1
        participantMvcData.id           = participantId;
        participantMvcData.mvcForceN    = [ 198, 189;...
                                            119, 117;...
                                            146, 148;...
                                             83,  83];   
        participantMvcData.mvcFiles = ...
            {'Versuch00000007.mat',     'Versuch00000008.mat';...
             'Versuch00000011.mat',     'Versuch00000012.mat';
             'Versuch00000014.mat',     'Versuch00000015.mat';
             'Versuch00000018.mat',     'Versuch00000019.mat'};

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