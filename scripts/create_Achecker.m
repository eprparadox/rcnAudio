function [checkerwave] = create_Achecker(centerFREQ, rate, duration, envelope)

%%% this matlab function will take a center frequency (in HZ),a number of
%%% tones and a rate (checkboard 'flash' rate, HZ) and output a wave which
%%% is an audio checkboard that lasts for durations seconds with an envelope 
%%% of envelope ms. 
%%% this is kind of a preliminary step to creating stimuli like
%%% those described in Tonotopic organization of human auditory cortex -
%%% Humphies et all, 2009 for use in an auditory reconstruction paradigm

%%% for right now, the ratios of the tones to the center frequency will be 
%%% hard coded as in the above paper

highFREQ3 = 1.23 * centerFREQ;  highFREQ2 = 1.11* centerFREQ;
lowFREQ3 = .83 * centerFREQ;    lowFREQ2 = .93 * centerFREQ;

%%% for right now, also hard code the burst duration
burstDur = 80;

%%% create tri tone complex
%fs = 44100;                    % sampling rate - might as well be CD quality
fs = 8000;
T = 1/fs;                      % sampling period
t = [0:T:(burstDur*10^-3)];    % time vector (burstDur is in ms)

%%% create envelope rise and fall
etime = [0:T:(envelope*10^-3)];    %%% envelope is in ms
envrise = etime .* etime; envrise = envrise/max(envrise);
envfall = fliplr(envrise);

%%% create 3 sine waves and apply rise and fall envelopes
center3 = sin(2*pi*centerFREQ*t); 
center3(1:length(envrise)) = envrise .* sin(2*pi*centerFREQ*t(1:length(envrise)));
center3(end-length(envfall)+1:end) = envfall .* sin(2*pi*centerFREQ*t(end-length(envfall)+1:end));

high3 = sin(2*pi*highFREQ3*t); 
high3(1:length(envrise)) = envrise .* sin(2*pi*highFREQ3*t(1:length(envrise)));
high3(end-length(envfall)+1:end) = envfall .* sin(2*pi*highFREQ3*t(end-length(envfall)+1:end));

low3 = sin(2*pi*lowFREQ3*t); 
low3(1:length(envrise)) = envrise .* sin(2*pi*lowFREQ3*t(1:length(envrise)));
low3(end-length(envfall)+1:end) = envfall .* sin(2*pi*lowFREQ3*t(end-length(envfall)+1:end));

%%% all together, then normalize
tritone = low3 + center3+ high3;
tritone = tritone/max(tritone);
tritone = tritone * .9;  %% attenuate to prevent clipping

%%% create 2 sine waves and apply rise and fall envelopes 
low2 = sin(2*pi*lowFREQ2*t); 
low2(1:length(envrise)) = envrise .* sin(2*pi*lowFREQ2*t(1:length(envrise)));
low2(end-length(envfall)+1:end) = envfall .* sin(2*pi*lowFREQ2*t(end-length(envfall)+1:end));

high2 = sin(2*pi*highFREQ2*t); 
high2(1:length(envrise)) = envrise .* sin(2*pi*highFREQ2*t(1:length(envrise)));
high2(end-length(envfall)+1:end) = envfall .* sin(2*pi*highFREQ2*t(end-length(envfall)+1:end));

%%% add and normalize
twotone = low2 + high2;
twotone = twotone/max(twotone);
twotone = .9 * twotone;

%%% calculate interburst silence duration
silenceDur = rate - burstDur/rate;
silenceDur = silenceDur * 10^-2; %%% fix these conversions
silence = zeros(1,round(silenceDur*44100));

%%% calculate total number of bursts
totalBursts = duration / (silenceDur + burstDur*10^-3);

%%% now the checkboard is randomized, so we just add up the tritone and
%%% twotone chords in random order with silence interspersed until we have
%%% the whole wave
checkerwave = silence;

for i = 1:round(totalBursts)
    if rand(1) > .5
        checkerwave = [checkerwave tritone silence];
    else
        checkerwave = [checkerwave twotone silence];
    end
end

%%%% this is ridiculous but i'll clean it up later
for i = 1:length(checkerwave)
    if checkerwave(i) < -1;
        checkerwave(i) = -1;
    end
end
disp('')
    