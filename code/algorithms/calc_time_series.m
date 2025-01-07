function [data_all] = calc_time_series(data,data_name,directions_name)
    
    for idx= 1: length(data(1).(data_name))
    
            for direc= 1:length(directions_name)

                    mat=[];
                    a=[];
                    
                    if isfield(data(1).(data_name),'name')==1
                        data_mean(idx).name= data(1).(data_name)(idx).name;
                        data_all(idx).name= data(1).(data_name)(idx).name;
                    end
    
                     for sub= 1:length(data)

                         data_cell{sub,1}= data(sub).(data_name)(idx).(directions_name{direc});
                     end
                     
                     id=0;
                     for j= 1:length(data_cell)
                         for n= 1:size(data_cell{j,1},2)
                             for k= 1:size(data_cell{j,1},1)
                                 a{id+k,n}= data_cell{j,1}{k,n}';                
                             end
                         end
                         id= id+size(data_cell{j,1},1);
                     end
                     
                     minLengthCell=min(min(cellfun('size',a,2),[],2));
                     
                     for i=1:size(a,1)
    
                             j2=minLengthCell+1:size(a{i,1},2);
                             for m= 1:size(a,2)
                              a{i,m}(j2)=[]; 
                             end
                             
                     end
                     
                     for l= 1:size(a,2)
                         mat{1,l}= cell2mat(a(:,l));
                     end

                     data_all(idx).(directions_name{direc})=mat;

            end
    end
end