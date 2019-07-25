function makePercussion(data,Fs,filename,nSamplesOtherData)

upTo=44100; % in Hz

percussHigh=false; % if want to use percussPitch to set pitch
percussPitch=100000; % making this higher will make the percussion pitch sound higher

percussLow=true; % if want to use percussSmooth to set pitch
percussSmooth=10; % making this higher will make the percussion pitch sound lower

% up sample to 44100 Hz
data_up=resample(data,upTo,round(Fs));
% data_up(end-3000:end)=nanmean(data_up);

% up again to get to length of other tracks
% if playing other data at 300 bpm
masterTempo=300; % bpm
% and sample rate of other data is matchToFs
% then other audio samples will last nSamplesOtherData/300 min
% set sampling rate of this percussion track such that lasts same duration
% as other data
targetTime=nSamplesOtherData/masterTempo; % in minutes
targetTimeSeconds=targetTime*60; % in seconds
currDuration=length(data_up)*(1/upTo); % in seconds 
data_up=resample(data_up,round(targetTimeSeconds/currDuration),1);
disp([num2str(length(data_up)) ' samples at ' num2str(upTo) ' Hz']);
disp(['makes ' num2str((length(data_up)*(1/upTo))/60) ' minutes of sound']);

if percussHigh==true
    figure();
    plot(data_up);
    thresh=input('Cut-off thresh? ');
    data_up(data_up<thresh)=0;
    data_up=data_up*percussPitch;
elseif percussLow==true
    data_up=smooth(data_up,percussSmooth);
end

figure();
plot(data_up);

% sound(data_up,upTo);

data_up=data_up-nanmin(data_up);
data_up=data_up./nanmax(data_up);
data_up=data_up*2-1;

audiowrite(filename,data_up,upTo);

[y,Fs]=audioread(filename);
sound(y,Fs);