function visualizationWrapper(psth,useTrials,params,isNotRunning,ledOn)

countTo=11827;

for i=1:50:countTo
    makeVisualization(psth,useTrials,[],['tf_frames' num2str(i) 'to' num2str(i+49) '.avi'],i:(i-1)*50+50,isNotRunning,ledOn);
    close all
end
