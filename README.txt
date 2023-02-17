--------------------------------------------------
Extracting the EMG normalization coefficients from the MVC trials
--------------------------------------------------
 
     Please read this entire document twice (use deepl.com to translate if you like)
     before you do anything.

     How would this function work?

     It will go into the MVC data and identify the 2 trials that are
     within 5% of eachother (or are closest, some were 6%)
     for each muscle. Next it will go through this entire list and find the maximum
     processed electrical activity for each muscle. To do process the EMG of each
     MVC trial:
    
      1. Remove the ECG data from the EMG data from the 2 trials using 
         removeEcgFromEmg (see example in main_emgBatchProcess.m)
    
      2. Evaluate the envelope of each using calcEmgEnvelope 
         (see example in main_emgBatchProcess.m)
       
      3. Extract the maximum value of the envelope from each trial.
    
      4. At the end, save the maximum electrical activity from each muscle
         across all of the 8 trials in a structure that looks like this:
    
      numberOfSignals = size(mvcBiopacDataRaw.data,2);
      biopacSignalNormalization(numberOfSignals) = struct('normalization',[]);
    
    
     To get started
        1.Write a function to return all of the information you need to process the
          MVC data of each subject. This is easy, but will take 1-2 hours. 
          Here are the details:
 
          As noted in data2023/README.txt, the notes made by Norman have MVC left and
          MVC right incorrectly labeled. The ones from Tobias are correctly
          labelled. To avoid having to write some ugly code to get around this
          you can write a function like code/inputOutput/getParticipantDataFebruary2023.m
          called code/inputOutput/getParticipantMVCDataFebruary2023.m. This function
          appears in code/inputOutput/ but only the first participant's data has
          been filled in.

          In this function you will fill in the information in a struct that will 
          return all of the information you need to process the MVC data for each 
          participant:
     
        participantMvcData = struct(...
            'id',               participantId,...              
            mvcNames  = {'Ext','Ext';...
                          'BendRight','BendRight';...
                          'Flex','Flex';...
                          'BendLeft','BendLeft'},
            mvcForceN = [198, 189;...
                         119, 117;...
                         146, 148;...
                         83, 83],    
            mvcFiles  = {'Versuch00000007.mat','Versuch00000008.mat';...
                         'Versuch00000011.mat','Versuch00000012.mat';
                         'Versuch00000014.mat','Versuch00000015.mat';
                         'Versuch00000018.mat','Versuch00000019.mat';});  
    
          It will take time to do this for all 28 participants, but once done, 
          you can be 100% sure that you are getting the correct file for the 
          direction you want. As a bonus you will not have to write the code
          that searches through the notes of Norman and Tobias to correctly
          identify the file that you want.
     
        2. Start writing your prototype code to extract the MVC coefficients
           for a single participant in a file that you will add:
           WhiplashExperimentProcessing/main_calculateEMGNormalization.m 

           Since you will have to remove the ECG data and extract the
           EMG envelopes you can use some of the code that appears in
           main_emgBatchProcess as an example.
           
           When this is working, and it makes sense, work with Matt to 
           encorporate this code into main_emgBatchProcess.m
           
           Do NOT write your prototype code in main_emgBatchProcess.m. 
     

    

          
                
