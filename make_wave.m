function [wave, energy] = make_wave(this_freq, type, silentTRs, stimTRs, acqTRs, TR, fs, envelope)
%%% this function will make all the waves for each trial for the above task
%%% map.  waves will include silence before the stim, the stim, and the
%%% acquisition slience after the stim


fs = 44100;                    % sampling rate - might as well be CD quality
dt = 1/fs;                     % seconds per sample
burstRate = 10;                % this is in Hz; more advice from Humphries 
burstDur = 80;                  % ms 
t = [0:dt:(burstDur*10^-3)];


%%% now stim.  create burst
%%% 10ms inter burst interval
%%% 20ms envelope
%%% 40ms stim

%%% create envelope rise and fall
etime = [0:dt:(envelope*10^-3)];    %%% envelope is in ms
envrise = etime .* etime; envrise = envrise/max(envrise);
envfall = fliplr(envrise);

if strcmp(type,'pure')
    wave = sin(2*pi*this_freq*t); 
    %%% add rise and fall
    wave(1:length(envrise)) = envrise .* wave(1:length(envrise));
    wave(end-length(envfall)+1:end) = envfall .* wave(end-length(envfall)+1:end);
    
elseif strcmp(type,'mj3rd')
    wave = sin(2*pi*this_freq*t); 
    wave2 = sin(2*pi*(this_freq*2^(1/3))*t); %even temperment
    wave = wave + wave2;  wave = wave ./ max(wave); 
    %%% add rise and fall
    wave(1:length(envrise)) = envrise .* wave(1:length(envrise));
    wave(end-length(envfall)+1:end) = envfall .* wave(end-length(envfall)+1:end);
elseif strcmp(type,'mn3rd')
    wave = sin(2*pi*this_freq*t);
    wave2 = sin(2*pi*(this_freq*2^(1/4))*t); %even temperment
    wave = wave + wave2;  wave = wave ./ max(wave);
    %%% add rise and fall
    wave(1:length(envrise)) = envrise .* wave(1:length(envrise));
    wave(end-length(envfall)+1:end) = envfall .* wave(end-length(envfall)+1:end);
elseif strcmp(type,'mj5th')
    wave = sin(2*pi*this_freq*t);
    wave2 = sin(2*pi*(this_freq*(3/2))*t); %perfect ratio
    wave = wave + wave2;  wave = wave ./ max(wave);
    %%% add rise and fall
    wave(1:length(envrise)) = envrise .* wave(1:length(envrise));
    wave(end-length(envfall)+1:end) = envfall .* wave(end-length(envfall)+1:end);
elseif strcmp(type,'mn5th')
    wave = sin(2*pi*this_freq*t);
    wave2 = sin(2*pi*(this_freq*(7/5))*t); %just intonation
    wave = wave + wave2;  wave = wave ./ max(wave);
    %%% add rise and fall
    wave(1:length(envrise)) = envrise .* wave(1:length(envrise));
    wave(end-length(envfall)+1:end) = envfall .* wave(end-length(envfall)+1:end);
elseif strcmp(type,'oct')
    wave = sin(2*pi*this_freq*t);
    wave2 = sin(2*pi*(this_freq*2)*t); %even temperment
    wave = wave + wave2;  wave = wave ./ max(wave);
    %%% add rise and fall
    wave(1:length(envrise)) = envrise .* wave(1:length(envrise));
    wave(end-length(envfall)+1:end) = envfall .* wave(end-length(envfall)+1:end);
end


%%% attenuate to prevent clipping
wave = wave * .8;

%%% adjust for isoloudness contour using the iso226 curves (1 phon)
[spl, spl_freq] = iso226(1);

%%% find the closest frequency to the current frequency and find the
%%% corresponding spl adjustment
[val idx] = min(abs(freq_list - this_freq));

the_spl = spl(idx);

%%% 20

%%% add the 10ms inter burst duration
wave = [zeros(1,fs * burstRate*10^-3) wave zeros(1,fs * burstRate*10^-3)];
wave = repmat(wave,1,10 * stimTRs * TR);
energy = sum( wave.^2);
disp(['this frequency: ' num2str(this_freq) ' max: ' num2str(max(wave)) '   min: ' num2str(min(wave)) ...
    '   type: ' type '    energy: ' num2str(energy)])

end
   
