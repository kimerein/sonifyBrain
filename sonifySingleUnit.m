function [output_data,out_Fs]=sonifySingleUnit(psth,unitInd,useTrials,params,outputFileName,mappingType,bursts,LFP)

if isempty(params) 
    % defaults for spectrogram
    params.tapers=[5 6];
    params.Fs=1/(psth.t(2)-psth.t(1));
    params.fpass=[1 50];
    params.trialave=1;
    params.movingwin=[1 0.025];
end

smoothIt=true;

data=psth.psths{unitInd};
if islogical(useTrials)
    data=data(useTrials==true,:);
elseif isnumeric(useTrials)
    data=data(ismember(1:size(data,1),useTrials),:);
end
data=data';
data=data(1:end); % concatenate all trials

[S,t,f]=mtspecgrampb(data,params.movingwin,params); % get spectrogram
out_Fs=1/(t(2)-t(1));
% K = 0.0112*ones(10);
% S = conv2(S,K,'same');

% display for this unit
figure();
colormap(othercolor('Cat_12'));
imagesc(t,f(f<=max(params.fpass)),S(:,f<=max(params.fpass))');
xlabel('Time (seconds)');
ylabel('Frequency (Hz)');

% sonify

switch mappingType
    case 1
        if smoothIt==true
            figure();
            title('Smoothed');
        end
        % divide into frequency bands:
        %   <4 Hz
        %   >=4 and <8 Hz
        %   >=8 and <12 Hz
        %   >=12 and <22 Hz
        %   >=22 and <35 Hz
        %   >=35 Hz
        %   add bursts
        % max frequency in each band will become pitch
        % use amplitude as a volume filter, i.e., no sound below a certain amplitude
        
        % get max frequency in each frequency band
        % freqbands=[min(params.fpass) 4; 4 8; 8 12; 12 22; 22 35; 35 max(params.fpass)];
        % freqbands=[min(params.fpass) max(params.fpass)];
        freqbands=[min(params.fpass) 6; 6 22; 22 max(params.fpass)];
        all_volume=nan(size(freqbands,1),size(S,1)); % n freqbands X m trials
        all_pitch=nan(size(freqbands,1),size(S,1)); % n freqbands X m trials
        for i=1:size(freqbands,1)
            if size(freqbands,1)==1
                currband=freqbands;
            else
                currband=freqbands(i,:);
            end
            specgram_in_band=S(:,f>=currband(1) & f<currband(2));
            currfreqs=f(f>=currband(1) & f<currband(2));
            % [vol,maxfreqinds]=nanmax(specgram_in_band,[],2); % find highest amplitude frequency at each time point
            % pitch=currfreqs(maxfreqinds); % map to pitch
            normby=repmat(nansum(specgram_in_band,2),1,size(specgram_in_band,2));
            normby(normby==0)=min(normby(normby>0));
            normed_specgram=specgram_in_band./normby;
            pitch=nansum(repmat(currfreqs,size(specgram_in_band,1),1).*normed_specgram,2);    
%             pitchmin=nanmin(pitch);
%             useprctile=100;
%             for j=1:100
%                 if prctile(pitch,j)>pitchmin
%                     useprctile=j;
%                     break
%                 end
%             end
%             pitch(pitch==pitchmin)=prctile(pitch,useprctile); 
            pitch=filloutliers(pitch,'previous','movmedian',50);
            pitch=filloutliers(pitch,'previous');
            temp=pitch(1:end);
            temp(isnan(temp))=nanmean(temp);
            pitch=reshape(temp,size(pitch,1),size(pitch,2));
            vol=nanmean(specgram_in_band,2); 
            all_volume(i,:)=vol;
            all_pitch(i,:)=pitch;
            if smoothIt==true
                all_pitch(i,:)=smooth(all_pitch(i,:),1); 
                plot(t,all_pitch(i,:)./nansum(all_pitch(i,:)));
                hold all;
            end  
        end
        
        % pad to have amplitude ranges match across frequency bands
        %all_volume=[nanmin(all_volume,[],2) all_volume nanmax(all_volume,[],2)]; % whiten
        %if size(freqbands,1)==1
        %   all_pitch=[freqbands(1) all_pitch freqbands(2)]; % define frequency band range as ends of scale
        %else
        %   all_pitch=[freqbands(:,1) all_pitch freqbands(:,2)]; % define frequency band range as ends of scale
        %end
        
        % interleave pitch and volume for each frequency band
        output_data=nan(size(all_volume,1)*2,size(all_volume,2));
        j=1;
        for i=1:size(output_data,1)
            % pitch then volume
            if mod(i,2)==1
                output_data(i,:)=all_pitch(j,:);
                disp('pitch');
            elseif mod(i,2)==0
                output_data(i,:)=all_volume(j,:);
                disp('volume');
                j=j+1;
            end
        end
    otherwise
        disp('Unrecognized mappingType');
        return
end

% add raw firing rate data
output_data=[resample(data,size(output_data,2),size(data,2)); output_data];

% add bursts if have them
if ~isempty(bursts)
    data=bursts.psths{unitInd};
    if islogical(useTrials)
        data=data(useTrials==true,:);
    elseif isnumeric(useTrials)
        data=data(ismember(1:size(data,1),useTrials),:);
    end
    data=data';
    data=data(1:end); % concatenate all trials
    % add burst data
    if all(data==0)
        data(1)=1;
    end
    output_data=[resample(data,size(output_data,2),size(data,2)); output_data];
end
if ~isempty(LFP)
    LFP(1:5)=[0 nanmean(LFP)/4 nanmean(LFP)/2 3*nanmean(LFP)/4 nanmean(LFP)];
    output_data=[output_data; -LFP(1:size(output_data,2))];
end

% write output to csv file
% csvwrite([outputFileName '_unit' num2str(unitInd) '.csv'],output_data.');
csvwrite([outputFileName '.csv'],output_data.');

