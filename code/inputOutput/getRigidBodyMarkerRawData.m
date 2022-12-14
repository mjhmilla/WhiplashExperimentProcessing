function rawLabelledMarkerData = ...
    getRigidBodyMarkerRawData(rigidBodyMarkerData,motiveColData)


nMarkers=length(rigidBodyMarkerData);
n = length(rigidBodyMarkerData(1).r0M0);

rawLabelledMarkerData(nMarkers)=...
               struct('r0M0',zeros(n,3),'markerName','');


for indexMarker=1:1:nMarkers

    parentName=rigidBodyMarkerData(indexMarker).parentName;
    markerName=rigidBodyMarkerData(indexMarker).markerName;

    flag_found=0;
    indexColumn=1;
    while indexColumn < length(motiveColData) && flag_found == 0

        if( strcmp(motiveColData(indexColumn).Type,'Marker') ...
         && contains(motiveColData(indexColumn).Name, parentName) ...
         && contains(motiveColData(indexColumn).Name, markerName) ...
         && strcmp(motiveColData(indexColumn).Measure,'Position')...
         && strcmp(motiveColData(indexColumn).Coordinate,'X'))

            flag_found=1;
        else
            indexColumn=indexColumn+1;
        end
    end
    assert(flag_found==1);

    rawLabelledMarkerData(indexMarker).markerName = ...
        motiveColData(indexColumn).Name;


    assert(indexColumn+2 <= length(motiveColData));

    if(indexColumn+2 > length(motiveColData))
        here=1;
    end

    rawLabelledMarkerData(indexMarker).r0M0 = ...
        [motiveColData(indexColumn).data,...
        motiveColData(indexColumn+1).data,...
        motiveColData(indexColumn+2).data];

    if(isempty(motiveColData(indexColumn+2).Coordinate)==1)
        here=1;
    end

    if(~contains(motiveColData(indexColumn+2).Coordinate,'Z'))
        here=1;
    end

    assert(contains(motiveColData(indexColumn+2).Coordinate,'Z'));

end
