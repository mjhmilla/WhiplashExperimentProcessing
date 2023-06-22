%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate means
%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [mean_data,data] = mean_of_subjects(subjects,data_name,directions_name)

    for e= 1: length(subjects(1).(data_name))
        
        for direc= 1:length(directions_name)

                 data_vec=[];
                 
                 if isfield(subjects(1).(data_name),'name')==1
                 mean_data(e).name=subjects(1).(data_name)(e).name;
                 data(e).name=subjects(1).(data_name)(e).name;
                 end

             
                 for sub= 1:length(subjects)                                   
                     data_cell{sub}= subjects(sub).(data_name)(e).(directions_name{direc});
                 end

                 % convert strain and time cells to array for mean and std calculation (cell2mat doesnt work because of different vector lengths in cell (error trials))           
                 data_vec=cell_to_array(data_cell);   
                 
                 % save mean and std vector:[mean,std] for each muscle and direction          
                 mean_data(e).([directions_name{direc},'_mean'])=mean(data_vec);
                 mean_data(e).([directions_name{direc},'_std'])=std(data_vec);
                 data(e).(directions_name{direc})= data_vec; 
        end
    
    end


    function array=cell_to_array(cell)
           idx=1;
           for l= 1:length(cell)
                for o= 1:length(cell{l})
                    array(idx)= cell{l}(o);
                    idx=idx+1;
                end 
           end   
    end

end