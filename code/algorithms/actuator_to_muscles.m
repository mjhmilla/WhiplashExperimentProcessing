%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Summarize actuator data in muscles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [strains,strain_max,times] = actuator_to_muscles(actuator_strains,actuator_strains_mean,actuator_times, actuator_index,muscle_names,directions_name)

    for s= 1:length(directions_name)
        for l= 1:length(muscle_names)
    
                index= actuator_index(l,:);
                index= (index(~isnan(index)));

                vec_strain=[];
                vec_time=[];


                for p= 1:length(index)
                       vec_strain(1,p)= actuator_strains_mean(index(p)).([directions_name{s},'_mean']);
                       vec_time(1,p)= actuator_times(index(p)).([directions_name{s},'_mean']);
                       vec_strain(2,p)= actuator_strains_mean(index(p)).([directions_name{s},'_std']);
                       vec_time(2,p)= actuator_times(index(p)).([directions_name{s},'_std']);
                end
                [max_actuator,max_idx]= max(vec_strain(1,:));
                actuator_for_muscle=actuator_strains(index(max_idx)).(directions_name{s});
                
                % muscle names
                strains(l).name=muscle_names{l};
                strain_max(l).name= muscle_names{l};
                times(l).name= muscle_names{l};

                
                % max actuator strain of each muscle with the std and the mean time + std
                strains(l).(directions_name{s})= actuator_for_muscle;
                strain_max(l).([directions_name{s},'_mean'])= max_actuator;
                strain_max(l).([directions_name{s},'_std'])=vec_strain(2,max_idx);
                times(l).([directions_name{s},'_mean'])= vec_time(1,max_idx);
                times(l).([directions_name{s},'_std'])= vec_time(2,max_idx);
 

        end 
    end
 
end