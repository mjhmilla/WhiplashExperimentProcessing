function validData = ...
    extractValidData(data, noDataNumber, flag_removeNegativeValues)

indexValidData = find(data ~= noDataNumber);

validData = data(indexValidData);

if(flag_removeNegativeValues==1)
    signsOfArray = sign(data);
    indexValidData = find(signsOfArray == 1);
    validData = data(indexValidData);
end

