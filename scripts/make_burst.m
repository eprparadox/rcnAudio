% small part of the make_wave script isolated to just return a burst
function [wave] = make_burst(this_freq,freq_list)

fs = 44100;                    % sampling rate - might as well be CD quality
dt = 1/fs;                     % seconds per sample
burstRate = 10;                % this is in Hz; more advice from Humphries
burstDur = 80;                  % ms
t = [0:dt:(burstDur*10^-3)];

%%% 20ms envelope
%%% 40ms stim

%%% create envelope rise and fall
etime = [0:dt:(envelope*10^-3)];    %%% envelope is in ms
envrise = etime .* etime; envrise = envrise/max(envrise);
envfall = fliplr(envrise);

wave = sin(2*pi*this_freq*t);

%%% add rise and fall
wave(1:length(envrise)) = envrise .* wave(1:length(envrise));
wave(end-length(envfall)+1:end) = envfall .* wave(end-length(envfall)+1:end);

%%% normalize
wave = wave / max(wave);

%%% halve
wave = wave * .5;

%%% adjust for isoloudness contour using the iso226 curves (1 phon)
[spl, spl_freq] = iso226(60);  % it's loud in there?

%%% find the closest frequency to the current frequency and find the
%%% corresponding spl adjustment
[val idx] = min(abs(freq_list - this_freq));

% the_spl = spl(idx);

%%% just for kicks let's say the most we can boost it to is 1 (double)
%%% so we'll set that to the highest point in the isoloudness contour.
%%% everything else will be relative to that

amp_map = spl' / spl(1); amp_map = amp_map * 2;

%%% amplify
wave = wave * amp_map(idx);