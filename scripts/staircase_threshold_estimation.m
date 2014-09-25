function [Mthreshold] = staircase_threshold_estimation
%
% uses interleaved staircase procedure by
% (c)2009 Arthur Lugtigheid (lugtigheid@gmail.com)
% with his last edit: 16 December 2009 - Version 2.0.3-beta
%
% Sepideh Sadaghiani, UC Berkeley
%
%

%% read in parameters
subjID = input('Please enter subject ID:  ', 's');
runnum = input('Please enter block number: ');

%% ============= please adjust: ============
%rootdir = fullfile('/Users','sepirat','Dropbox','stimulus_development','Stanford_threshold_audio');
rootdir = fullfile('~','Dropbox','stimulus_development','Stanford_threshold_audio');
params.buttonnum = 17;      % response button code: 17 on Mac="N"
params.keydevice = 5;       % keyboard ID

% Set up parameters for staircase. For explanation see demo.m of sc toolbox
sc.maxtrials = 35;                  % the maximum number of trials
sc.maxreversals = 10;               % the maximum number of reversals
sc.ignorereversals = 5;             % number of first reversals to ignore

sc.minstimval = 0.03;              	% minimum stimulus value
sc.maxstimval = 0.3;                % maximum stimulus value
sc.maxboundaries = 5;               % number of times sc can hit boundary

sc.steptype = 'fixed';              % other option is 'random'
sc.fixedstepsizes = [0.05 0.02 0.01 0.005];   % specifies the stepsize vector

sc.up = 1;                          % # of incorrect answers to go one step up
sc.down = 1;                        % # of correct answers to go one step down

                                    % set up 2 staircases (more are possible!)
sc.stairs(1).initial = 0.07;     	% first staircase
sc.stairs(2).initial = 0.15;     	% second staircase

% === general stimulus settings ====
params.ISIs  =  Shuffle(linspace(1.5,4,sc.maxtrials));
params.RTlim = 1;           % highest allowed RT (s) to be counted as hit for block analysis at run offset

% sound frequency settings
params.Fs = 48000;                  % sound sampling frequency (Hz)
% the following parameters are used only if you have singla processing
% toolbox installed. Otherwise, sound will be loaded into workspace.
params.stimdur  = 0.3;                  % target sound duration (s)
params.rampdur  = params.stimdur/5;     % for ramping sound at on- and offset
params.stimband = [500 5000];           % for bandpass filtering 
params.stimmod  = [0 400 1000 400 0];   % target sound is modulated in 5 steps



%% ========== no editing beyond this =========
%close all
warning off
addpath(rootdir);
addpath(fullfile(rootdir, 'sc'));

%% == PTBX: set the audio device
InitializePsychSound()      % argument (1) ONLY NEEDED FOR WINDOWS! for low latency
params.audiodevice1 = PsychPortAudio('Open', [], [], 1, params.Fs, 2); % for background stram. check flags with >>psychportaudio open?
params.audiodevice2 = PsychPortAudio('Open', [], [], 1, params.Fs, 2); % for target stream.

%% == PTBX: set the screen
scr.black = [0 0 0];        % RGB values for background
scr.grey  = [50 50 50];     % RGB values for fixation corss
scr.white = [200 200 200];  % RGB values for text
HideCursor;

[scr.window, scr.res] = Screen('OpenWindow', 0, 0);
scr.rect = [0 0 scr.res(3) scr.res(4)];

scr.fixwin = Screen('OpenOffscreenWindow', scr.window, 0, scr.rect);
Screen('TextSize', scr.fixwin , 100)
Screen('DrawText', scr.fixwin,'+', scr.res(3)/2-30, scr.res(4)/2-70, scr.grey);

scr.diodewin = Screen('OpenOffscreenWindow', scr.window, 0, scr.rect);
Screen('TextSize', scr.diodewin , 100)
Screen('DrawText', scr.diodewin,'+', scr.res(3)/2-30, scr.res(4)/2-70, scr.grey);
Screen('FillRect', scr.diodewin, scr.white, [scr.res(3)-60 scr.res(4)-60 scr.res(3) scr.res(4)]); % for photodiode, lower right corner

scr.textwin = Screen('OpenOffscreenWindow', scr.window, 0, scr.rect);
Screen('TextSize', scr.textwin , 40)

%% == Create sounds
try
    target_sound = create_target_sound(rootdir, params); % function requires signal processing toolbox
catch       % if no signal processing toolbox installed
    load(fullfile(rootdir, 'target_sound_file.mat'))
end

backgrdur = (sum(params.ISIs)+length(params.ISIs)*params.stimdur)+200; % +200s just in case; will be stopped when trials are over
backgr_sound = rand(1, backgrdur*params.Fs)*0.1;
backgr_sound = [backgr_sound; backgr_sound];

%% instruction dialog with subject
ListenChar(2);              % mute the output to MATLAB command line

subj_dialog(scr, params, target_sound);

% initialise the staircases
sc = init(sc);

% start background oinse stream
PsychPortAudio('FillBuffer', params.audiodevice1, backgr_sound);
t_backgrstart = PsychPortAudio('Start', params.audiodevice1, 1, 0, 1); % repetitions=1, start time=0s, 1=waitforsound & return onset time
  
%% run the staircase algorithm until we're done
t0 = GetSecs; 
tic
false_alarms = [];
trialcount = 1;
% start trial by trialstimulation
prestim_ISI = params.ISIs(1);
while ~sc.done,
    
    % wait for the specified prestimulus time and check for false alarms
    t_ISIstart = GetSecs;
    
    while (GetSecs-t_ISIstart) < prestim_ISI
        KbWait(params.keydevice, 1);            % wait untill all buttons are released. Crucial!
        pressed = 0;
        while pressed==0 && (GetSecs-t_ISIstart) < prestim_ISI
            [pressed,secs,keys] = KbCheck(params.keydevice);
        end
        if pressed && find(keys)==params.buttonnum, 
            false_alarms = [false_alarms secs-t0]; 
        end
    end
    
    % gets the next trial; some of the trial parameters are stored in a
    % 'trial' struct, like the stimulus value (trial.stimval) and the 
    % trial number (trial.number)
    [trial,sc] = newtrial(sc);
    
    % present stimulus and check for response
    RT = 0;
    trial.resp = 0;
    keyIsDown  = false;

    PsychPortAudio('FillBuffer', params.audiodevice2, target_sound*trial.stimval);
    t_stimstart = PsychPortAudio('Start', params.audiodevice2, 1, 0, 1); % repetitions=1, start time=0s, 1=waitforsound & return onset time
    
    Screen('CopyWindow', scr.diodewin, scr.window, scr.rect, scr.rect);
    Screen('Flip', scr.window);
    WaitSecs(0.1);
    Screen('CopyWindow', scr.fixwin, scr.window, scr.rect, scr.rect);
    Screen('Flip', scr.window);
    
    while keyIsDown==0 && (GetSecs-t_stimstart) < params.RTlim
        [keyIsDown,secs,keyCode] = KbCheck(params.keydevice);
    end
    if keyIsDown && find(keyCode)==params.buttonnum, 
        RT=secs-t0; 
        trial.resp = 1;
    end
    
    % add trial time stamps to output results matrix 
    resultsmat(trialcount,:) = [prestim_ISI, t_stimstart-t0, RT];
    
    if trialcount<length(params.ISIs), prestim_ISI = params.ISIs(trialcount+1); trialcount = trialcount+1; end    % set it for next trial
    
    % evaluates the response and updates the staircase struct.
    sc = evaluate(trial, sc);
    
end
toc

%% save data
subjdir = fullfile(rootdir, 'results', subjID);

if ~(exist(subjdir)==7)
    mkdir(subjdir);
    disp 'making new subject diectory'
end

savepath = fullfile(subjdir, [subjID '_STAIRCASE_log_run' int2str(runnum)]);

if exist([savepath '.mat'])==2
    savepath = fullfile(subjdir, ['conflict_' subjID '_STAIRCASE_log_run' int2str(runnum)]);
    disp(['WARNING: file already exists. Saving with alternative filename: ' savepath])
    beep; WaitSecs(0.5); beep; WaitSecs(0.5); beep;
end
worksp_savepath = [savepath '_workspace'];

save(savepath, 'sc', 'resultsmat', 'false_alarms', 'params');
save(worksp_savepath);  % save all workspace variables, just in case

%% close up
ListenChar(0); 
Screen('CloseAll');
PsychPortAudio('Close', params.audiodevice1);
PsychPortAudio('Close', params.audiodevice2);
ShowCursor

% put the main variable in the workspace (for debugging)
assignin('base', 'sc', sc);

% return resulting detection threshold (mean over all staircases)
Mthreshold = sc.threshold;

% visualise the results. THIS WILL CRASH OLD WHITE MACBOOK!
try visualise(sc); catch end

%% ============= end of main script, subfunctions follow ================
function [] = subj_dialog(scr, params, target_sound)

instructions = ['Please listen for the faint target sound.'...
    '\n\n\n Press button as fast as possible \n when hearing the target!'...
    '\n\n\n Please fixate at center of screen! \n\n\n Press response button to hear the sound!'];
DrawFormattedText(scr.textwin, instructions, 'center', 'center', scr.white);
Screen('FillRect', scr.textwin, scr.white, [scr.res(3)-60 scr.res(4)-60 scr.res(3) scr.res(4)]); % for photodiode, lower right corner
Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
WaitSecs(1);
keyIsDown = 0;
pressedCode = 0;
FlushEvents();
while pressedCode~=params.buttonnum
    [keyIsDown,secs,keyCode] = KbCheck();
    if keyIsDown, pressedCode = find(keyCode,1); end;
end
Screen('FillRect', scr.textwin, scr.black, scr.rect);       % clear window for later use


instructions = ['This is your target sound.'];
DrawFormattedText(scr.textwin, instructions, 'center', 'center', scr.white);
Screen('FillRect', scr.textwin, scr.white, [scr.res(3)-60 scr.res(4)-60 scr.res(3) scr.res(4)]); % for photodiode, lower right corner
Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
PsychPortAudio('FillBuffer', params.audiodevice2, target_sound*0.25);
for i=1:3
    WaitSecs(1.5);
    PsychPortAudio('Start', params.audiodevice2, 1, 0, 1); % repetitions=1, start time=0s, 1=waitforsound & return onset time
end
WaitSecs(1.5);
Screen('FillRect', scr.textwin, scr.black, scr.rect);       % clear window for later use

instructions = ['Please press response button to start!'];
DrawFormattedText(scr.textwin, instructions, 'center', 'center', scr.white);
Screen('FillRect', scr.textwin, scr.white, [scr.res(3)-60 scr.res(4)-60 scr.res(3) scr.res(4)]); % for photodiode, lower right corner
Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
WaitSecs(1);
keyIsDown = 0;
pressedCode = 0;
FlushEvents();
while pressedCode~=params.buttonnum
    [keyIsDown,secs,keyCode] = KbCheck();
    if keyIsDown, pressedCode = find(keyCode,1); end;
end
Screen('FillRect', scr.textwin, scr.black, scr.rect);       % clear window for later use

Screen('CopyWindow', scr.fixwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);

WaitSecs(1);
