function participantCarData=...
     getParticipantCarDataMay2022(participantId)


participantCarData = [];
participantCarData.biopacProblems = [];
participantCarData.ignoreTheseFileNumbers = [];

%If the notes mention EMG problems, please enter these problems into the 
%biopacProblemsStruct like this:
%
% Trial 11 has EMG problems on channels 2 and 3
% Trial 12 has EMG problems on channels 1
%
% We have 2 problematic trials, so we need an array of 2 biopacProblemsStruct:
%
%       biopacProblemsStruct(2) = struct('trialNumber',0,'channels',[]);
%
% And we fill out the struct like this
%
%       biopacProblemsStruct(1).trialNumber = 11;
%       biopacProblemsStruct(1).channels    = [2,3];
%       biopacProblemsStruct(2).trialNumber = 12;
%       biopacProblemsStruct(2).channels    = [1];
%
% Then we put this information into the participant struct like this:
%
%       participantCarData.biopacProblems = biopacProblemsStruct;
%

switch participantId
    case 1
        participantCarData.id           = participantId;

        participantCarData.condition       = {'nominal'; ...
                                              'nominal';...
                                              'headTurned'};

        %From the back of the hand-written paper sheet
        participantCarData.block           = {'headRom';...
                                              'A';...
                                              'B'};

        %These are the start and end file numbers for each of the
        %the conditions listed above
        participantCarData.blockFileNumbers = [5, 5;...
                                               10, 22;...
                                               23, 30];

        %If the notes mention to ignore a trial that is within
        %the range in conditionFileNumbers, list them here.                                          
        participantCarData.ignoreTheseFileNumbers = [];                                           
        participantCarData.ignoreTheseOptitrackFileNumbers =[];

        %Marker data
        participantCarData.scalingMarkerFile =...
            'Take 2022-05-02 10.10.44 AM.trc';
        participantCarData.scalingTimeRange = [29.96, 29.965];

    case 2
        participantCarData.id               = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'A';...
                                                'D'};
        participantCarData.blockFileNumbers = [ 1, 1;...
                                                2, 13;...
                                                14, 21];
        participantCarData.ignoreTheseFileNumbers = [];
        participantCarData.ignoreTheseOptitrackFileNumbers =[];

        %Marker data
        participantCarData.scalingMarkerFile = ...
            'Take 2022-05-02 11.29.43 AM.trc';
        participantCarData.scalingTimeRange = [0.005,0.010];        
        
    case 3
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'B';...
                                                'D'};
        participantCarData.blockFileNumbers = [ 7, 7;...
                                                8, 19;...
                                                20, 38];
        disp('Check: if ignoreTheseFileNumbers works in updateParticipantEmgDataFileNames');
        participantCarData.ignoreTheseFileNumbers = [21, 22, 29, 31, 32, 33];
        biopacProblemStruct(8) = struct('trialNumber' ,0,'channels' ,[]);
        biopacProblemStruct(1).trialNumber = 24;
        biopacProblemStruct(1).channels = 2;
        biopacProblemStruct(2).trialNumber = 26;
        biopacProblemStruct(2).channels = 2;
        biopacProblemStruct(3).trialNumber = 27;
        biopacProblemStruct(3).channels = 2;
        biopacProblemStruct(4).trialNumber = 28;
        biopacProblemStruct(4).channels = 2;
        biopacProblemStruct(5).trialNumber = 30;
        biopacProblemStruct(5).channels = 3;
        biopacProblemStruct(6).trialNumber = 36;
        biopacProblemStruct(6).channels = 2;
        biopacProblemStruct(7).trialNumber = 37;
        biopacProblemStruct(7).channels = 2;
        biopacProblemStruct(8).trialNumber = 38;
        biopacProblemStruct(8).channels = 2;
        participantCarData.biopacProblems = biopacProblemStruct;
        participantCarData.ignoreTheseOptitrackFileNumbers =[];

        %Marker data
        participantCarData.scalingMarkerFile = ...
            'Take 2022-05-02 01.47.51 PM.trc';
        participantCarData.scalingTimeRange = [0.005,0.010];        

    case 4
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'B';...
                                                'C'};
        participantCarData.blockFileNumbers = [ 5, 5;...
                                                6, 17;...
                                                20, 25];
        participantCarData.ignoreTheseFileNumbers = [9];
        biopacProblemStruct(7) = struct('trialNumber' ,0,'channels' ,[]);
        biopacProblemStruct(1).trialNumber = 8;
        biopacProblemStruct(1).channels = 3;
        biopacProblemStruct(2).trialNumber = 10;
        biopacProblemStruct(2).channels = 3;
        biopacProblemStruct(3).trialNumber = 12;
        biopacProblemStruct(3).channels = 3;
        biopacProblemStruct(4).trialNumber = 14;
        biopacProblemStruct(4).channels = 3;
        biopacProblemStruct(5).trialNumber = 15;
        biopacProblemStruct(5).channels = 3;
        biopacProblemStruct(6).trialNumber = 16;
        biopacProblemStruct(6).channels = 3;
        biopacProblemStruct(7).trialNumber = 17;
        biopacProblemStruct(7).channels = 3;
        participantCarData.biopacProblems = biopacProblemStruct;
        participantCarData.ignoreTheseOptitrackFileNumbers =[];

        %Marker data
        participantCarData.scalingMarkerFile = ...
            'Take 2022-05-02 12.10.39 PM_003.trc';
        participantCarData.scalingTimeRange = [0.005,0.010];        
 

    case 5
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'A';...
                                                'C'};
        participantCarData.blockFileNumbers = [ 8, 8;...
                                                9, 29;...
                                                30, 37];
        participantCarData.ignoreTheseFileNumbers = [15, 19, 20 , 21, 22, 23, 24, 25, 26];
        participantCarData.ignoreTheseOptitrackFileNumbers =[0.005,0.010];

        %Marker data
        participantCarData.scalingMarkerFile = ...
            'Take 2022-05-03 09.39.07 AM.trc';
        participantCarData.scalingTimeRange = [0.005,0.010];        
        

    case 6
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'A';...
                                                'D'};
        participantCarData.blockFileNumbers = [ NaN, NaN;...
                                                4, 15;...
                                                16, 23];
        participantCarData.ignoreTheseFileNumbers = [];
        participantCarData.ignoreTheseOptitrackFileNumbers =[];

        %Marker data
        participantCarData.scalingMarkerFile = ...
            'Take 2022-05-03 11.19.34 AM.trc';
        participantCarData.scalingTimeRange = [0.005,0.010];        
        

    case 7 
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'A';...
                                                'C'};
        participantCarData.blockFileNumbers = [ NaN, NaN;...
                                                5, 16;...
                                                17, 24];
        participantCarData.ignoreTheseFileNumbers = [];
        participantCarData.ignoreTheseOptitrackFileNumbers =1:12;

        %Marker data
        participantCarData.scalingMarkerFile = '';
        participantCarData.scalingTimeRange = [nan,nan];        
        

    case 8 
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'B';...
                                                'D'};
        participantCarData.blockFileNumbers = [ NaN, NaN;...
                                                7, 18;...
                                                19, 26];
        participantCarData.ignoreTheseFileNumbers = [];
        participantCarData.ignoreTheseOptitrackFileNumbers =[];

        %Marker data
        participantCarData.scalingMarkerFile = ...
            'Take 2022-05-03 02.54.05 PM.trc';
        participantCarData.scalingTimeRange = [0.005,0.010];        
        

    case 9
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'B';...
                                                'C'};
        participantCarData.blockFileNumbers = [ NaN, NaN;...
                                                6, 17;...
                                                18, 25];
        participantCarData.ignoreTheseFileNumbers = [];
        participantCarData.ignoreTheseOptitrackFileNumbers =1:12;

        %Marker data
        participantCarData.scalingMarkerFile = '';
        participantCarData.scalingTimeRange = [nan,nan];        


    case 10   
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'A';...
                                                'C'};
        participantCarData.blockFileNumbers = [ NaN, NaN;...
                                                7, 18;...
                                                19, 26];
        participantCarData.ignoreTheseFileNumbers = [];
        participantCarData.ignoreTheseOptitrackFileNumbers =[];

        %Marker data
        participantCarData.scalingMarkerFile = ...
            'Take 2022-05-05 10.15.19 AM.trc';
        participantCarData.scalingTimeRange = [0.005,0.010];        
        

    case 11
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'A';...
                                                'D'};
        participantCarData.blockFileNumbers = [ NaN, NaN;...
                                                4, 15;...
                                                16, 23];
        participantCarData.ignoreTheseFileNumbers = [];
        participantCarData.ignoreTheseOptitrackFileNumbers =[];

        %Marker data
        participantCarData.scalingMarkerFile = ...
            'Take 2022-05-05 11.21.44 AM.trc';
        participantCarData.scalingTimeRange = [0.005,0.010];        
        

    case 12
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'A';...
                                                'C'};
        participantCarData.blockFileNumbers = [ NaN, NaN;...
                                                9, 23;...
                                                24, 31];
        participantCarData.ignoreTheseFileNumbers = [21, 22];
        biopacProblemStruct(1) = struct('trialNumber' ,0,'channels' ,[]);
        biopacProblemStruct(1).trialNumber = 17;
        biopacProblemStruct(1).channels = [2];
        participantCarData.biopacProblems = biopacProblemStruct;
        participantCarData.ignoreTheseOptitrackFileNumbers =[8];

        %Marker data
        participantCarData.scalingMarkerFile = ...
            'Take 2022-05-05 12.27.41 PM.trc';
        participantCarData.scalingTimeRange = [0.005,0.010];        
        
      
    case 13 
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'B';...
                                                'D'};
        participantCarData.blockFileNumbers = [ 6, 6;...
                                                7, 18;...
                                                26, 33];
        participantCarData.ignoreTheseFileNumbers = [];
        biopacProblemStruct(4) = struct('trialNumber' ,0,'channels' ,[]);
        biopacProblemStruct(1).trialNumber = 16;
        biopacProblemStruct(1).channels = 2;
        biopacProblemStruct(2).trialNumber = 17;
        biopacProblemStruct(2).channels = 2;
        biopacProblemStruct(3).trialNumber = 18;
        biopacProblemStruct(3).channels = 2;
        biopacProblemStruct(4).trialNumber = 32;
        biopacProblemStruct(4).channels = 2;
        participantCarData.biopacProblems = biopacProblemStruct;
        participantCarData.ignoreTheseOptitrackFileNumbers =[9];

        %Marker data
        participantCarData.scalingMarkerFile =...
            'Take 2022-05-05 02.09.45 PM.trc';
        participantCarData.scalingTimeRange = [0.005,0.010];        
      

    case 14 
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'B';...
                                                'C'};
        participantCarData.blockFileNumbers = [ 7, 7;...
                                                8, 19;...
                                                20, 27];
        participantCarData.ignoreTheseFileNumbers = [];
        participantCarData.ignoreTheseOptitrackFileNumbers =[3];


        %Marker data
        participantCarData.scalingMarkerFile = ...
            'Take 2022-05-05 03.51.55 PM.trc';
        participantCarData.scalingTimeRange = [0.005,0.010];        
        
    case 15 
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'B';...
                                                'D'};
        participantCarData.blockFileNumbers = [ NaN, NaN;...
                                                2, 13;...
                                                14, 21];
        participantCarData.ignoreTheseFileNumbers = [];
        participantCarData.ignoreTheseOptitrackFileNumbers =1:12;

        %Marker data
        participantCarData.scalingMarkerFile = '';
        participantCarData.scalingTimeRange = [nan,nan];        


    case 16 
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'A';...
                                                'C'};
        participantCarData.blockFileNumbers = [ NaN, NaN;...
                                                5, 16;...
                                                24, 31];
        participantCarData.ignoreTheseFileNumbers = [];
        participantCarData.ignoreTheseOptitrackFileNumbers =[];

        %Marker data
        participantCarData.scalingMarkerFile = ...
            'Take 2022-05-06 09.37.03 AM.trc';
        participantCarData.scalingTimeRange = [30.005,30.010];        
        

    case 17 
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'A';...
                                                'D'};
        participantCarData.blockFileNumbers = [ NaN, NaN;...
                                                5, 16;...
                                                17, 24];
        participantCarData.ignoreTheseFileNumbers = [];
        participantCarData.ignoreTheseOptitrackFileNumbers =[];


        %Marker data
        participantCarData.scalingMarkerFile = ...
            'Take 2022-05-06 11.19.59 AM.trc';
        participantCarData.scalingTimeRange = [0.005,0.010];        


    case 18 
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'A';...
                                                'C'};
        participantCarData.blockFileNumbers = [ NaN, NaN;...
                                                4, 15;...
                                                16, 23];
        participantCarData.ignoreTheseFileNumbers = [];
        participantCarData.ignoreTheseOptitrackFileNumbers =[];

        %Marker data
        participantCarData.scalingMarkerFile = ...
            'Take 2022-05-06 12.19.26 PM.trc';
        participantCarData.scalingTimeRange = [0.005,0.010];        


    case 19 
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'B';...
                                                'D'};
        participantCarData.blockFileNumbers = [ 5, 5;...
                                                6, 17;...
                                                18, 25];
        participantCarData.ignoreTheseFileNumbers = [];
        biopacProblemStruct(1) = struct('trialNumber' ,0,'channels' ,[]);
        biopacProblemStruct(1).trialNumber = 19;
        biopacProblemStruct(1).channels = 1;
        participantCarData.biopacProblems = biopacProblemStruct;
        participantCarData.ignoreTheseOptitrackFileNumbers =[8];

        %Marker data
        participantCarData.scalingMarkerFile = ...
            'Take 2022-05-06 01.56.26 PM.trc';
        participantCarData.scalingTimeRange = [0.005, 0.010];        
    
    case 20 
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'B';...
                                                'C'};
        participantCarData.blockFileNumbers = [ 3, 3;...
                                                4, 15;...
                                                16, 23];


        participantCarData.ignoreTheseFileNumbers = [];
        participantCarData.ignoreTheseOptitrackFileNumbers =[];

        %Marker data
        participantCarData.scalingMarkerFile = ...
            'Take 2022-05-06 03.22.47 PM.trc';
        participantCarData.scalingTimeRange = [0.005, 0.010];        


    case 21
        participantCarData.id           = participantId;
        participantCarData.condition        = { 'nominal'; ...
                                                'nominal';...
                                                'headTurned'};        
        participantCarData.block            = { 'headRom';...
                                                'B';...
                                                'D'};
        participantCarData.blockFileNumbers = [ 3, 3;...
                                                4, 15;...
                                                16, 23];
        participantCarData.ignoreTheseFileNumbers = [];
        participantCarData.ignoreTheseOptitrackFileNumbers =[];
    
        %Marker data
        participantCarData.scalingMarkerFile = ...
            'Take 2022-05-06 04.38.22 PM.trc';
        participantCarData.scalingTimeRange = [0.005,0.010];        


   otherwise
        assert(0, ['Error: particpantId is not within the range of 1-21,',...
            ' or the information for the requested participant has ',...
            'not yet been entered']);
end