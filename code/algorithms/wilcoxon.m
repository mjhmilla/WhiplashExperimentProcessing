%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate the rank sum test and looking for significance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [p_sig,p_all] = wilcoxon(data1,data2,p_value,directions_name)
   
  assert(length(data1)==length(data2))

   for i= 1:length(data1)
        
        if isfield(data1,'name')==1
            p_all(i).name=data1(i).name;
            p_sig(i).name=data1(i).name;
        end

        for j= 1: length(directions_name)      
            p_all(i).(directions_name{j}) = ranksum(data1(i).(directions_name{j}),data2(i).(directions_name{j}));
            p_sig(i).(directions_name{j})= p_all(i).(directions_name{j});
           
            if p_all(i).(directions_name{j})>p_value
                p_sig(i).(directions_name{j})=[];
            end

        end
    end
end


