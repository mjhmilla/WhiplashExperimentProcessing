%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate the euclidean distance between model marker 
% position of IK-results and the raw marker positions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [error] = calc_error(model_marker,raw_marker,markerNames)
       
      assert(length(model_marker)==length(raw_marker) )
      for idx= 1:length(model_marker)
              
          for n= 1:length(markerNames)
                           r_x= raw_marker(idx).(markerNames{n})(:,1)./10;
                           r_y= raw_marker(idx).(markerNames{n})(:,2)./10;
                           r_z= raw_marker(idx).(markerNames{n})(:,3)./10;
                           m_x= model_marker(idx).([markerNames{n},'_tx']).*100;
                           m_y= model_marker(idx).([markerNames{n},'_ty']).*100;
                           m_z= model_marker(idx).([markerNames{n},'_tz']).*100;
                           error(idx).(markerNames{n})=sqrt(((r_x)-(m_x)).^2+((r_y)-(m_y)).^2+((r_z)-(m_z)).^2);
          end

      end

end