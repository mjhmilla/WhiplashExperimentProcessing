function carDirection = extractCarAccelerationDirection(...
						carBiopacData,...
	                    biopacSignalIntervals,...
	                    biopacIndices)

accMaxXYZ = zeros(3,2);

carDirection = 'Static';


indexDir=1;

for i=biopacIndices.indexAccCarX:1:biopacIndices.indexAccCarZ
    assert(size(biopacSignalIntervals(i).intervalIndices,1)==1,...
           ['Error: biopacSignalIntervals contains more than one',...
            ' acceleration interval. This function requires that',...
            ' only one interval be present.']);


    indexStart = biopacSignalIntervals(i).intervalIndices(1,1);
    indexEnd   = biopacSignalIntervals(i).intervalIndices(1,2);

    indexStaticStart = 1;
    indexStaticEnd   = round( 0.9*(indexStart-indexStaticStart) ); 

    %Subtract off any component of the gravity vector
    bias = mean(carBiopacData.data(indexStaticStart:indexStaticEnd,i));


    [val,idx] = max(abs(carBiopacData.data(indexStart:indexEnd,i)-bias));

    %Get the signed version of the maximum
    accMaxXYZ(indexDir,1) = carBiopacData.data(indexStart+idx-1,i)-bias;
    accMaxXYZ(indexDir,2) = indexStart+idx-1;
    indexDir=indexDir+1;
end

%Find the direction with the largest acceleration
[maxAcc, indexMaxAcc] = max(abs(accMaxXYZ(:,1)));

%Now we know the axis, and we have to determine whether the movement is
%along the positive. Note that the accelerometer is mounted in the car
%so that
%
% +X : right 
% +Y : forwards
% +Z : up

switch indexMaxAcc
    case 1
        if(accMaxXYZ(indexMaxAcc,1) > 0)
            carDirection = 'Right';
        else
            carDirection = 'Left';            
        end

    case 2
        if(accMaxXYZ(indexMaxAcc,1) > 0)
            carDirection = 'Forward';
        else
            carDirection = 'Backwards';            
        end
        

    case 3
        if(accMaxXYZ(indexMaxAcc,1) > 0)
            carDirection = 'Up';
        else
            carDirection = 'Down';            
        end
        
        %This should not happen: the car did not move up/down much
        assert(0, ['Error: Somehow the Z direction has the largest ',...
                   'acceleration, even after the bias has been remove']);


    otherwise
        assert(0, ['Error: Somehow more than 3 acceleration directions',...
                   ' are being analyzed']);
end

