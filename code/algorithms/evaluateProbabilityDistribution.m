function p = evaluateProbabilityDistribution(value,coeff,typeDistribution)

p =zeros(size(value));

switch typeDistribution
    case 0
        for i=1:1:length(value)
            p(i) = exp([-value(i),1]*coeff);
        end
    case 1
        for i=1:1:length(value)
            p(i) = exp([log(value(i)),1]*coeff);
        end
    case 2
        for i=1:1:length(value)
            p(i)=0;
            for j=1:1:size(coeff,1)
                xi      = coeff(j,1);
                sigmai  = coeff(j,2);
                ai      = coeff(j,3);
                argx = ((value(i)-xi)/sigmai);
                p(i) = p(i) + ai*exp(-argx*argx);
            end
        end
    otherwise assert(0,'typeDistribution not recognized');
end