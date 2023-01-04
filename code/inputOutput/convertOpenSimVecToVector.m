function [vecMat] = convertOpenSimVecToVector(vec)

vecMat = zeros(vec.size(),1);

for i=1:1:vec.size()
    vecMat(i,1)=vec.get(i-1);
end