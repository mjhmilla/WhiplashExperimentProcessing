function err = calcProbabilityDistributionError(argParam,argColumn,...
    defaultParams, xdata,ydata,errorScaling,typeDistribution)

err = 0;

params = defaultParams;
params(:,argColumn) = argParam;

values = evaluateProbabilityDistribution(xdata,params,typeDistribution);

err = values - ydata;
err = sum(err.^2).*errorScaling;



