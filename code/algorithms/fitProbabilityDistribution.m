function noiseModel = fitProbabilityDistribution(...
                        edges,n, maximaOfNote, typeDistribution)


noiseModel = struct('coeff',[],'localMaxima',[]);


midPoints =   0.5*edges(1,1:(end-1)) + 0.5*edges(1,2:(end));
%%
% The noise probability distribution cannot be used directly because it
% will contain some intervals with zeros. To be conservative I'm going
% to fit a power law as a function to model the probability of a particular
% value showing up.
%%



switch typeDistribution
    case 0
        %Exponential noise model
        %y = c1*e^(-c2*x)
        isNotZero = find(n>0);
        b = log(n(1,isNotZero)');
        x = -midPoints(1,isNotZero)';
        
        %Weighting the data to best approximate values near the origin
        w = diag(n(1,isNotZero)');
        w = w./w(1,1);
        w = 1./(w + 0.1);
        %w = sqrt(w);
        %w = diag(ones(size(n(1,isNotZero)')));
        A = [x, ones(size(x))];
        coeff = (A'*w*A)\(A'*w*b);
        
        noiseModel.coeff=coeff;
        noiseModel.localMaxima = [];
    case 1
        %Power noise model
        %y = c1*x^(c2)        
        isNotZero = find(n>0);
        b = log(n(1,isNotZero)');
        x = log(midPoints(1,isNotZero)');
        
        %Weighting the data to best approximate values near the origin
        w = diag(n(1,isNotZero)');
        w = w./w(1,1);
        w = 1./(w + 0.1);
        %w = sqrt(w);
        %w = diag(ones(size(n(1,isNotZero)')));
        A = [x, ones(size(x))];
        coeff = (A'*w*A)\(A'*w*b);

        noiseModel.coeff=coeff;
        noiseModel.localMaxima = [];
        
    case 2
        isNotZero = find(n>0);
        
        %Mixture of Gaussian model
        %Sum of ai*exp( ((x-xi)/sigma_i)^2)
        xi = midPoints(1,isNotZero);
        ai = n(1,isNotZero);
        sigma = diff(midPoints);
        sigma = [sigma,sigma(1,1)];
        sigmai = sigma(1,isNotZero);
        sigmai = sigmai.*2;


        coeff = [xi',sigmai',ai'];

        errStart = calcProbabilityDistributionError(coeff(:,3),3,coeff,...
            xi',ai',1,typeDistribution);
        calcErr = @(arg1)calcProbabilityDistributionError(arg1,3,coeff,...
            xi',ai',1/errStart,typeDistribution);
        
        A = [];
        b = [];
        Aeq = [];
        beq = [];
        lb =zeros(size(coeff(:,3)));
        ub = [];

        options = optimoptions('fmincon','Display','off');
        [x,fval,exitflag,output]=fmincon(calcErr,coeff(:,3),...
            A,b,Aeq,beq,lb,ub,[],options);

        %If the optimized solution for the coefficients is superior, 
        %accept it
        if(fval < 1)
            coeff(:,3) = x;
        end

        %Evaluate any local maxima
        values =evaluateProbabilityDistribution(xi',coeff,typeDistribution);
        here=1;

        dvalues = calcCentralDifferenceDataSeries(xi',values);

        for j=2:1:(length(dvalues))
            if(dvalues(j-1,1)*dvalues(j,1) < 0 && values(j,1)>maximaOfNote)
                noiseModel.localMaxima = [noiseModel.localMaxima;xi(1,j)];
            end
        end

        noiseModel.coeff=coeff;
        
    otherwise assert(0,'typeDistribution not recognized');
end