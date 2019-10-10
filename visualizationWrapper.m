function visualizationWrapper(psth,useTrials,params,isNotRunning,ledOn,stimCond)

% countTo=11827;
% countTo=11407;
countTo=11000;
stepSize=1000;
doFrames=10001:stepSize:countTo;

allframes=struct('cdata',cell(1,countTo-doFrames(1)+1),'colormap',cell(1,countTo-doFrames(1)+1));
for i=doFrames
%     [allframes(i-min(doFrames)+1:i+(stepSize-1)-min(doFrames)+1)]=makeVisualization(psth,useTrials,[],[],i:i+(stepSize-1),isNotRunning,ledOn);
    [allframes(i-min(doFrames)+1:i+(stepSize-1)-min(doFrames)+1)]=makeVisualizationDG(psth,useTrials,[],[],i:i+(stepSize-1),isNotRunning,ledOn,stimCond);
    v = VideoWriter(['m330_run_frames' num2str(i) 'to' num2str(i+(stepSize-1)) '.avi'],'Uncompressed AVI');
    v.FrameRate = 30;
    open(v);
    % drop last frame if end
    writeVideo(v,allframes);
    close(v);
end

 