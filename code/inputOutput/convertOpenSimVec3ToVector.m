function [rG1G, RG1] = convertOpenSimTransformToMatrices(X_G_1)

rG1G = zeros(3,1);
RG1  = zeros(3,3);
for i=1:1:3
    rG1G(i,1)=X_G_1.p.get(i-1);
    for j=1:1:3
        RG1(i,j)=X_G_1.R.get(i-1,j-1);
    end
end