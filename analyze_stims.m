%function dummy = analyze_stims(sub)

%%%% this function will analyze the stimuli in a created task map.  this
%%%% includes creating a total power spectrogram for pure and complex tones
%%%% and creating histograms over the types of all stim
%sub = 'sequence_test-1';
sub = 'bm_02-2';
load([sub '_rcnAudio_task_map.mat'])
trial_map = task_map.trial_map;

freqlist = task_map.params.frequencies;

pure_hist = [];
complex_hist = [0 0 0 0 0]; 
mj3_hist = []; mn3_hist = []; mj3 = 1; mn3 = 1;
mj5_hist = []; mn5_hist = []; mj5 = 1; mn5 = 1;
oct_hist = []; oct = 1;
big_wave = []; big_mj3_wave = []; big_mn3_wave = [];
big_mj5_wave = []; big_mn5_wave = []; big_oct_wave = [];

for tr = 1:length(trial_map)
    if strcmp(trial_map(tr).type,'pure')
        pure_hist(end+1) = trial_map(tr).frequency;
        big_wave = [big_wave trial_map(tr).wave];
        
    elseif strcmp(trial_map(tr).type,'mj3rd')
        complex_hist(1) = mj3;
        mj3 = mj3 + 1;
        mj3_hist(end+1) = trial_map(tr).frequency;
        big_mj3_wave = [big_mj3_wave trial_map(tr).wave];
        
    elseif strcmp(trial_map(tr).type,'mn3rd')
        complex_hist(2) = mn3;
        mn3 = mn3 + 1;
        mn3_hist(end+1) = trial_map(tr).frequency;
        big_mn3_wave = [big_mn3_wave trial_map(tr).wave];
        
    elseif strcmp(trial_map(tr).type,'mj5th')
        complex_hist(3) = mj5;
        mj5 = mj5 + 1;
        mj5_hist(end+1) = trial_map(tr).frequency;
        big_mj5_wave = [big_mj5_wave trial_map(tr).wave];
        
    elseif strcmp(trial_map(tr).type,'mn5th')
        complex_hist(4) = mn5;
        mn5 = mn5 + 1;
        mn5_hist(end+1) = trial_map(tr).frequency;
        big_mn5_wave = [big_mn5_wave trial_map(tr).wave];
        
    elseif strcmp(trial_map(tr).type,'oct')
        complex_hist(5) = oct;
        oct = oct + 1;
        oct_hist(end+1) = trial_map(tr).frequency;
        big_oct_wave = [big_oct_wave trial_map(tr).wave];
        
    end
end


figure
%%% draw spectrogram of the big wave
nfft=256;
nt=20;
fs=2000;
dt=1/fs;
fmax = max(freqlist);

n=length(big_wave);

pwelch(big_wave,[],[],[],fs)
%xlim([.05 .8])
set(gca,'XScale','log')

% %initialize outputs
% nf=nfft/2+1;
% tt=dt*(nfft-1)/2:nt*dt:(n-1)*dt-(nfft/2)*dt;
% ntt=length(tt);
% f=linspace(0,fs/2,nf)'*ones(1,ntt);
% t=ones(nf,1)*tt;
% y=zeros(nf,ntt);
% 
% %create window vector
% xw=[0:nfft-1]';
% wind=.5*(1-cos((xw*2*pi)/(nfft-1)));
% 
% %create ffts
% for i=1:ntt
%     
%     %fft
%     zi=(i-1)*nt+1:nfft*i-(i-1)*(nfft-nt);
%     xss=fft(big_wave(zi).*wind,nfft)/nfft;
%     yy=2*abs(xss(1:(nfft/2)+1));
%     
%     %update y
%     y(:,i)=yy;
%     
% end
% 
% %reduce t,f,y to fmax
% zi=f(:,1)<=fmax;
% f=f(zi,:);
% t=t(zi,:);
% y=y(zi,:);
% 
% %eliminate least powerful points
% if per<1
%     sy=sort(y(:));
%     si=floor((1-per)*length(sy));
%     sval=sy(si);
%     y(y<=sval)=0;
% end
% 
% %create plot
% if pflag
%     hold off;
%     pcolor(t,f,y);
%     shading flat;
%     xlabel('Time (sec)');
%     ylabel('Frequency (Hz)');
%     title('Spectrogram');
% end
% 
% 
% 
% 
