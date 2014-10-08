function [] = rcnAudio_fMRI_sandbox_v2(subject,day,block)
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
for v = 1:length(task_map.trial_map)
    if task_map.trial_map(v).block == block;
        cTrial_map(counter) = task_map.trial_map(v);
        counter = counter + 1;
    end
end


%%% get TR
TR = task_map.params.TR;
%TR = 2.2; % temp        
TTL = '5%'; %%% keyboard code for TTL pulse is a 5


% set up devices
checkdevices = PsychHID('devices');
for devicecounter = 1:length(checkdevices)
    if checkdevices(devicecounter).vendorID == 1452; %FORP (or ID 1240)
        device_forp = devicecounter;
    elseif checkdevices(devicecounter).vendorID == 1452 && isequal(checkdevices(devicecounter).usageName,'Keyboard') ...
            && ~isequal(checkdevices(devicecounter).transport,'Bluetooth');
        
        device_kb = devicecounter; % probably don't need this, but leave for now
        
    end
end

% get screen size and center
[width, height] = Screen('WindowSize', 0);
wcenter = width/2;
hcenter = height/2;
screen_dims = [0 0 width/2 height/2]; % so psycho screen takes up only half our screen space

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
[scr.window, scr.res]=Screen('OpenWindow', 0, 0, screen_dims);
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

fprintf('Ready \nWaiting for scanner trigger\n')
DrawFormattedText(scr.textwin, readytext, 'center', scr.res(4)-150, scr.white);
Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
Screen('FillRect', scr.textwin, scr.black, scr.rect);
WaitSecs(3);
% This Flip makes it gray for longer than black
% Can't help it from being initially black
% Screen('FillRect',scr.textwin,scr.grey,[0 0 width height]);
% Screen('Flip',scr.window);

%% NEW CODE

% Prepare stimuli
[scr.textwin]=Screen('OpenOffscreenWindow', scr.window, 0, scr.rect);
Screen('TextSize', scr.textwin , 25)

% Give the user instructions
msg = 'You will hear some tones and see a sequence of letters appear on the screen';
DrawFormattedText(scr.textwin, msg, 'center', 'center', scr.white);
Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
Screen('FillRect', scr.textwin, scr.black, scr.rect);
WaitSecs(3);

msg = 'Press 1 if the letter you see is the same as the letter that preceded it';
DrawFormattedText(scr.textwin, msg, 'center', 'center', scr.white);
Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
Screen('FillRect', scr.textwin, scr.black, scr.rect);
WaitSecs(3);

msg = 'Press 2 if the letter you see is printed in red font';
DrawFormattedText(scr.textwin, msg, 'center', 'center', scr.white);
Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
Screen('FillRect', scr.textwin, scr.black, scr.rect);
WaitSecs(3);

[scr.textwin]=Screen('OpenOffscreenWindow', scr.window, 0, scr.rect);
Screen('TextSize', scr.textwin , 100)

msg = '+';
DrawFormattedText(scr.textwin, msg, 'center', 'center', scr.white);
Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
Screen('FillRect', scr.textwin, scr.black, scr.rect);
WaitSecs(2);

msg = '+';
DrawFormattedText(scr.textwin, msg, 'center', 'center', scr.green);
Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
Screen('FillRect', scr.textwin, scr.black, scr.rect);
WaitSecs(1);

% Set the visual stimuli
visual_stim = ['J' 'R' 'Q' 'Q' 'N' 'L' 'L';
               'T','M','R','A','B','B','A';
               'R','Y','J','C','U','V','V']; % each row corresponds to a trial

% Set task time variables
TR = 2.2;
num_trials = size(visual_stim,1);%length(cTrial_map);
trial_time = 7 * TR; % total time of each trial

num_visual_stims = size(visual_stim,2); % number of visual stims played per audio stim
audio_stim_time = 2 * TR; % time that the audio stim is played
visual_isi_time = 0.2; % time between each successive visual stim
visual_stim_time = (audio_stim_time - (visual_isi_time * num_visual_stims)) / num_visual_stims; % time that each visual stim is displayed

% Set up user response variables
userkey_vischange = '1!'; % user presses 1 if the letter displayed is the same as prev
userkey_visred = '2@'; % user presses 2 if the letter is displayed in red font
user_ans = zeros(num_trials, num_visual_stims); % empty vector for the user's answers (1 or 2)
response_time = zeros(num_trials, num_visual_stims); % empty vector for user's response time
corr_ans = [0 2 0 1 0 0 1;
            0 0 2 0 0 1 0;
            2 0 0 0 0 0 1]; % what the user's answers should be, if all correct

% Display stimuli
task_start_time = GetSecs();
for t = 1:num_trials
    trial_start_time = GetSecs();
    % Build and play the audio stimulus
    PsychPortAudio('FillBuffer',task_map.params.audiodevice,[cTrial_map(t).wave; cTrial_map(t).wave])
    PsychPortAudio('Start', task_map.params.audiodevice, 1, 0, 1);
    
    % Show the visual stimuli
    for v = 1:num_visual_stims
        visual_start_time = GetSecs();
        if visual_stim(t,v) == 'R'   
            DrawFormattedText(scr.textwin, visual_stim(t,v), 'center', 'center', scr.red);
        else
            DrawFormattedText(scr.textwin, visual_stim(t,v), 'center', 'center', scr.white);
        end
        Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
        Screen('Flip', scr.window);
        Screen('FillRect', scr.textwin, scr.black, scr.rect);

        % Loop until it is time to move on to the ISI, and look for a button 
        % press if the user has not already pressed during this visual stimulus
        key_not_pressed = true;
        next_event = visual_start_time + visual_stim_time;
        while GetSecs() < next_event
            if key_not_pressed
                [keyIsDown, secs, keyCode] = PsychHID('KbCheck');%device_forp);%device_kb);
                if keyIsDown
                    keypress = KbName(find(keyCode));
                    if isequal(keypress,userkey_vischange)
                        user_ans(t,v) = 1;
                        response_time(t,v) = GetSecs() - visual_start_time;
                        key_not_pressed = false;
                    elseif isequal(keypress,userkey_visred)
                        user_ans(t,v) = 2;
                        response_time(t,v) = GetSecs() - visual_start_time;
                        key_not_pressed = false;
                    end
                end
            end
        end

        % Stop displaying the visual stimulus (i.e., begin ISI)
        DrawFormattedText(scr.textwin, '', 'center', 'center', scr.black);
        Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
        Screen('Flip', scr.window);
        Screen('FillRect', scr.textwin, scr.black, scr.rect);

        % Loop until it is time to move on to the next stimulus, and look for a
        % button press if the user has not already pressed during this visual stimulus
        next_event = visual_start_time + visual_stim_time + visual_isi_time;
        while GetSecs() < next_event
            if key_not_pressed
                [keyIsDown, secs, keyCode] = PsychHID('KbCheck');%device_forp);%device_kb);
                if keyIsDown
                    keypress = KbName(find(keyCode));
                    if isequal(keypress,userkey_vischange)
                        user_ans(t,v) = 1;
                        response_time(t,v) = GetSecs() - visual_start_time;
                        key_not_pressed = false;
                    elseif isequal(keypress,userkey_visred)
                        user_ans(t,v) = 2;
                        response_time(t,v) = GetSecs() - visual_start_time;
                        key_not_pressed = false;
                    end
                end
            end
        end        
    end
    % Wait until it is time to continue to the next auditory stimulus
    if t == num_trials
        next_event = trial_start_time + trial_time;
        while GetSecs() < next_event
            continue
        end
    else
        next_event = trial_start_time + trial_time - 1.5;
        % Show a white crosshair
        DrawFormattedText(scr.textwin, '+', 'center', 'center', scr.white);
        Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
        Screen('Flip', scr.window);
        Screen('FillRect', scr.textwin, scr.black, scr.rect);
        while GetSecs() < next_event
            continue
        end
        next_event = trial_start_time + trial_time - 0.5;
        % Show a green crosshair
        DrawFormattedText(scr.textwin, '+', 'center', 'center', scr.green);
        Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
        Screen('Flip', scr.window);
        Screen('FillRect', scr.textwin, scr.black, scr.rect);
        while GetSecs() < next_event
            continue
        end
        next_event = trial_start_time + trial_time;
        % Show a black screen
        DrawFormattedText(scr.textwin, '', 'center', 'center', scr.black);
        Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
        Screen('Flip', scr.window);
        Screen('FillRect', scr.textwin, scr.black, scr.rect);
        while GetSecs() < next_event
            continue
        end
    end
end
task_end_time = GetSecs();

% Report task time, then display the user's answers, response time, and the correct answers
strjoin({'Task presentation began at',num2str(task_start_time),'and ended at',num2str(task_end_time)},' ')
disp('User answers by trial:')
disp(user_ans)
disp('User response time by trial:')
disp(response_time)
disp('Correct answers by trial:')
disp(corr_ans)
disp('User answers to correct answers:')
disp(user_ans == corr_ans)

close all;
Screen('CloseAll');
sca;
PsychPortAudio('Close', task_map.params.audiodevice);

return;

%%% END NEW CODE
%% OLD CODE





%%%% %%% put wait for the go TTL pulse here
while 1
    %[keyIsDown, secs, keyCode, deltaSecs] = KbCheck(device_forp);%device_forp);%device_kb);
    %[keyIsDown, secs, keyCode, deltaSecs] = PsychHID(KbCheck,device_forp);%device_forp);%device_kb);
    [keyIsDown, secs, keyCode] = PsychHID('KbCheck');%device_forp);%device_kb);
    
    if keyIsDown
        keypress = KbName(find(keyCode));
        if isequal(keypress,TTL)%TTL)
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
    %%% build stim (put current wave in the buffer)
    events.silent_onsets(end+1) = GetSecs;
    PsychPortAudio('FillBuffer',task_map.params.audiodevice,[cTrial_map(tr).wave; cTrial_map(tr).wave])
    
    offset = .2;
    %offset = 0;
    
    wakeup = WaitSecs('UntilTime',events.silent_onsets(end) + (task_map.params.silentTRs * TR)-offset);
        
    %%% play stim
    disp('playing stim')
    events.stim_onsets(end+1) = GetSecs;
    PsychPortAudio('Start', task_map.params.audiodevice, 1, 0, 1); % repetitions=1, start time=0s, 1=waitforsound & return onset time GetSecs;
    wakeup = WaitSecs('UntilTime',events.stim_onsets(end) + task_map.params.stimTRs * TR);
    
    disp('aquiring')
    events.acquisition_onsets(end+1) = wakeup;
    WaitSecs('UntilTime',events.acquisition_onsets(end) + task_map.params.acqTRs * TR);
    
    while 1
        [keyIsDown, secs, keyCode] = PsychHID('KbCheck');
        
        if keyIsDown
            keypress = KbName(find(keyCode));
            if isequal(keypress,TTL)%TTL)
                disp('TTL')
                break
            end
        end
    end
end
   


task_map.real_timing_data(block).start = t0;
task_map.real_timing_data(block).events = events;
save([subject '-' day '_rcnAudio_task_map.mat'], 'task_map')



close all;
Screen('CloseAll');
sca;
PsychPortAudio('Close', task_map.params.audiodevice);
