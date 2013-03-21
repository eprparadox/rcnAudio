function [] = rcnAudio_fMRI(subject,day,block)
%
% auditory reconstruction experiment


% auditory detection experiment
% USAGE: rcnAudio(sub,day,block)
% this scrpit requires psychophysics toolbox (relying on 32 bit MATLAB)
%
%
% the only things to save are timing info, so I'll try to save those
% somewhere

subject = num2str(subject); day = num2str(day);

d = dir([subject '-' day '_rcnAudio_task_map_original.mat']);
if length(d) == 0
    cp_cmd = ['!cp ' subject '-' day '_rcnAudio_task_map.mat ' ...
        subject '-' day '_rcnAudio_task_map_original.mat'];
    eval(cp_cmd)
end
%%% load task map
load([subject '-' day '_rcnAudio_task_map.mat'])

%%% this is insane
counter = 1;
for i = 1:length(task_map.trial_map)
    if task_map.trial_map(i).block == block;
        cTrial_map(counter) = task_map.trial_map(i);
        counter = counter + 1;
    end
end


%%% get TR
%TR = task_map.params.TR;
TR = 2.2; % temp        
TTL = '5%'; %%% keyboard code for TTL pulse is a 5


% set up devices
checkdevices = PsychHID('devices');
for devicecounter = 1:length(checkdevices)
    if checkdevices(devicecounter).vendorID == 6171; %FORP (or ID 1240)
        device_forp = devicecounter;
    elseif checkdevices(devicecounter).vendorID == 1452 && isequal(checkdevices(devicecounter).usageName,'Keyboard');
        device_kb = devicecounter; % probably don't need this, but leave for now
    end
end

% get screen size and center
[width, height] = Screen('WindowSize', 0);
wcenter = width/2;
hcenter = height/2;

% fixation dot
fixdot = [wcenter-5 hcenter-5 wcenter+5 hcenter+5];


% hard code dummies as 5 
task_map.params.dummies = 5;

%%%%% screen stuff (pack this into params later?)
scr.red = [200 0 0];       % FA
scr.green = [0 150 0];     % hit
scr.orange = [255 110 0];  % miss
scr.grey = [50 50 50];     % fixation corss
scr.white = [200 200 200]; % text
scr.black = [0 0 0];       % background

%HideCursor;
[scr.window, scr.res]=Screen('OpenWindow', 0, 0);
scr.rect=[0 0 scr.res(3) scr.res(4)];

[scr.textwin]=Screen('OpenOffscreenWindow', scr.window, 0, scr.rect);
Screen('TextSize', scr.textwin , 40)

scr.fixwin=Screen('OpenOffscreenWindow', scr.window, 0, scr.rect);
Screen('TextSize', scr.fixwin , 100)

readytext = 'Waiting for Scanner ...';

%%% PTBX: set the audio device
InitializePsychSound()      % argument (1) ONLY NEEDED FOR WINDOWS! for low latency
task_map.params.audiodevice = PsychPortAudio('Open', [], [], 1, task_map.params.sampling_rate, 2); % check flags with >>psychportaudio open?

%%% open the audio device
pahandle = PsychPortAudio('Open');
Priority(2);             % PTBX switches MATLAB into real time mode

      
%%% at the end of the experiment, events will be a vector indicating the
%%% clock time of all the events in one long row. 
events.stim_onsets = [];
events.silent_onsets = [];
events.acquisition_onsets = [];

    

'Ready \nWaiting for scanner trigger'
DrawFormattedText(scr.textwin, readytext, 'center', scr.res(4)-150, scr.white);
Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
Screen('FillRect', scr.textwin, scr.black, scr.rect);       % clear window for later use
    
WaitSecs(3);
% This Flip makes it gray for longer than black
% Can't help it from being initially black
% Screen('FillRect',scr.textwin,scr.grey,[0 0 width height]);
% Screen('Flip',scr.window);

sca

%%%% %%% put wait for the go TTL pulse here
while 1
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck(device_forp);%device_k);
    if keyIsDown
        keypress = KbName(find(keyCode));
        if isequal(keypress,'TTL')%TTL)
            disp('TTL')
            break
        end
    end
end


%%% wait for the dummy scans to go by 
%WaitSecs(TR*task_map.params.dummies);
%%% update : i think there's no need 
%%% wait fot the dummies to go by.  however,
%%% dan's sequence starts with the acquision
%%% therefore, we'll wait here for the acquision TRs
%%% and then we'll be starting ontime with the 
%%% silent TR
WaitSecs(TR*task_map.params.acqTRs);

%%%% start stimulus presentation
% the task has started now, write down the time
t0 = GetSecs;
disp('start')
for tr = 1:length(cTrial_map)
    disp('begin silence')
    %%% bulid stim (put current wave in the buffer)
    events.silent_onsets(end+1) = GetSecs;
    PsychPortAudio('FillBuffer',task_map.params.audiodevice,[cTrial_map(tr).wave; cTrial_map(tr).wave])
    
    wakeup = WaitSecs('UntilTime',events.silent_onsets(end) + task_map.params.silentTRs * TR);
        
    %%% play stim
    disp('playing stim')
    events.stim_onsets(end+1) = GetSecs;
    PsychPortAudio('Start', task_map.params.audiodevice, 1, 0, 1); % repetitions=1, start time=0s, 1=waitforsound & return onset time GetSecs;
    wakeup = WaitSecs('UntilTime',events.stim_onsets(end) + task_map.params.stimTRs * TR);
    
    disp('aquiring')
    events.acquisition_onsets(end+1) = wakeup;
    WaitSecs('UntilTime',events.acquisition_onsets(end) + task_map.params.acqTRs * TR);
      
end
   


task_map.real_timing_data(block).start = t0;
task_map.real_timing_data(block).events = events;
save([subject '-' day '_rcnAudio_task_map.mat'], 'task_map')



close all;
Screen('CloseAll');
PsychPortAudio('Close', task_map.params.audiodevice);
