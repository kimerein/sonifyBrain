function [output_data,out_Fs]=sonifyLFP(LFP,useTrials,mappingType,LFP_Fs)

addNbetween=0; % add this many pulses between each LFP dip
heightOfBetween=2; % higher will make in between pulses higher wrt base pulses

downSamp=true;
aimFor=1902;

doConvolution=false; % will add an envelope if true
x=0:0.001:10;
y=exp(-150*x);
figure();
plot(x,y);

bandpass=true;
if bandpass==true
    LFP=bandPassLFP(LFP,LFP_Fs,1,300,1);
end

chronuxpath='/Users/kim/Documents/GitHub/chronux_2_12/chronux_2_12/spectral_analysis/continuous/';
rmpath(chronuxpath);

data=LFP;
if islogical(useTrials)
    data=data(useTrials==true,:);
elseif isnumeric(useTrials)
    data=data(ismember(1:size(data,1),useTrials),:);
end
data=data';
data=data(1:end); % concatenate all trials

switch mappingType
    case 1
        % get downward deflections of LFP as synchronized network activity
        % and make pulses at these points
        [vals,downs]=findpeaks(-data,'MinPeakProminence',1.5);
        vals=-vals;
        figure();
        plot(data,'Color','k');
        hold on;
        inBetweens=zeros(1,length(data));
        for i=1:length(downs)
            line([downs(i) downs(i)],[nanmin(data) nanmax(data)],'Color','r');
            if i>1
                if addNbetween>0
                    dist=downs(i)-downs(i-1);
                    spacing=round(dist/addNbetween);
                    inBetweens(downs(i-1):spacing:downs(i))=heightOfBetween;
                    scatter(downs(i-1):spacing:downs(i),ones(size(downs(i-1):spacing:downs(i))).*nanmean(data),[],'b');
                end
            end
        end
        output_data=zeros(1,length(data));
        output_data(downs)=1;
        out_Fs=LFP_Fs;
        if addNbetween>0
            output_data=output_data+inBetweens;
            output_data(downs)=1;
        end
    otherwise
end

if downSamp==true
    output_data=downSampAv(output_data,floor(length(output_data)/aimFor));
    disp(length(output_data));
end

if doConvolution==true
    output_data=conv(output_data,y,'same');
    figure();
    plot(output_data);
end

addpath(chronuxpath);