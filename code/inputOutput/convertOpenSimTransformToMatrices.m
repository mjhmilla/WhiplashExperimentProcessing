function [rG1G, R1G] = convertOpenSimTransformToMatrices(X_G_1)

rG1G = zeros(3,1);
R1G  = zeros(3,3);
for i=1:1:3
    rG1G(i,1)=X_G_1.p.get(i-1);
    for j=1:1:3
        R1G(i,j)=X_G_1.R.get(i-1,j-1);
    end
end