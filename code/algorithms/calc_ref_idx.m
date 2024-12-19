function [ reference_idx_start]= calc_ref_idx(trc_files,trc_data_folder,carAccOnsetTime_idx,wind)

    import org.opensim.modeling.*

    nTrials = size(trc_files);
    reference_idx_start= zeros(1,nTrials(1));

    for trial= 1:nTrials
 
    
        
        % Get the name of the file for this trial
        markerFile = trc_files(trial).name;

        fullpath = fullfile(trc_data_folder, markerFile);
    
        trc_data = osimTableToStruct(TimeSeriesTableVec3(fullpath));
    
        t= ((1:length(trc_data.SJN)).*0.005)';

        vx= calcCentralDifferenceDataSeries(t,trc_data.GLA(:,1)); 
        vy= calcCentralDifferenceDataSeries(t,trc_data.GLA(:,2)); 
        vz= calcCentralDifferenceDataSeries(t,trc_data.GLA(:,3)); 
        vNorm = ( vx.^2+vy.^2+vz.^2).^0.5;

        ax= calcCentralDifferenceDataSeries(t,vx); 
        ay= calcCentralDifferenceDataSeries(t,vy); 
        az= calcCentralDifferenceDataSeries(t,vz); 
        aNorm = ( ax.^2+ay.^2+az.^2).^0.5;
                   
        b= zeros(carAccOnsetTime_idx(trial)-199,2);
        c=zeros(carAccOnsetTime_idx(trial)-199,2);
        list_sum=zeros(1,carAccOnsetTime_idx(trial)-199);
       
          
        for k= 1:length(b)

              b(k,1)= sum(abs(vNorm(k:k+(wind-1)))); 
              b(k,2)= k;
                  
              c(k,1)= sum(abs(aNorm(k:k+(wind-1))));
              c(k,2)= k;

        end
                    
        list_v= sortrows(b); 
        list_a= sortrows(c);

        for l= 1:length(list_a)

              list_sum(l)= find(list_v(:,2)==l)+ find(list_a(:,2)==l);

        end

        [~,reference_idx_start(trial)]= min(list_sum);

    end

end
