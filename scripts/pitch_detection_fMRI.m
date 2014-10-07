function [] = pitch_detection_fMRI()
%
% auditory detection experiment
% USAGE: pitch_detection()
% this scrpit requires psychophysics toolbox (relying on 32 bit MATLAB)
%
% you will be prompted for the following input arguments:
%
% subjID: subject ID: yymmddXXX, where YY=year, mm=month, dd=day, XXX=initials
% runnum: run number, as integer
% Whether this is a test run for familiarization, with visual feedback: 1=yes, 0=no
%
% results will be saved in a logfile in this format:
% resultsmatrix: 
%      rows: one row per stimulus
%      columns: blocktype, stimulus type, stim duration, UPCOMING SoA, RT, key code, time stamp
%
%blocktypes are coded as:
% type 1: low alertness, low attention
% type 2: low alertness, high attention
% type 3: high alertness, low attention
% type 4: high alertness, high attention
%
% Sepideh Sadaghiani, UC Berkeley

subjID = input('Please enter subject ID in this format: yymmddXXX, where YY=year, mm=month, dd=day (today), and XX=initials:  ', 's');
runnum = input('Please enter block number: ');

params.ispractice = input('Is this a practice run (visual feedback)? Enter 1 for "yes" and 0 for "no":  ');
if ~(params.ispractice==0 || params.ispractice==1), error('please enter 0 or 1! Please restart!'); end
% params.vary_stimdur = input('should the duration of stimuli be varied? Enter 1 for "yes" and 0 for "no":  ');    
% if ~(params.vary_stimdur==0 || params.vary_stimdur==1), error('please enter 0 or 1! Please restart!'); end


 rootdir = fullfile('/Users','sepideh','Dropbox','stimulus_development','auditory_detection');
% rootdir = fullfile('/Users','Shared','Experiments','DespoLab','Sepideh'); % 3T scanner stimulus Mac
addpath(rootdir);
close all
warning off

%% sound frequency settings
params.Fs = 48000;          % sound sampling frequency (Hz)
params.stimdur = 0.20;      % sound duration (s)
params.devdur  = params.stimdur+0.06; % for deviats, i.e. only IF params.vary_stimdur==1
params.rampdur = 0.03;      % duration for ramp on, ramp off
params.CF = 261.63;         % C4 (= middle C) center frequency

%% general settings
params.SoA = 0.72;          % inter-stimulus interval
params.IBI = 20;            % inter block interval
params.buttonnum = 30;      % FORPs 1,2,3,4 = 30, 31, 32, 33
params.keydevice = 3%2;       % keyboard ID! fmri stim mac FORPs:3, MacBook: 5
params.TTLbutton = 34;      % corresponds to button "5" (through FORP system)
params.dummies  = 3;        % number of vols to throw away (in addition to 2 scanner dummies)
params.feedbdur = 0.1;      % duration of trial by trial feedback 
params.targetindx = 5; 
params.reps = 8;            % MUST BE EVEN!!!! determines length of a block (*10 stimuli)!
if params.ispractice, params.reps = 6; end
params.ecog = 0;            % whether this is for ECoG recordings!
params.RTlim = 0.8;         % highest allowed RT (s) to be counted as hit for block analysis at run offset
params.vary_stimdur = 1;    % boolean: whether or not to jitter duration of sounds

randblocks = [1 3 2 4]; 
params.endtime = 300;
if ~params.ispractice, randblocks = [randperm(4) randperm(4)]; params.endtime = 694; end

blockinfo = zeros(length(randblocks),3);    % to save on- and offset time and blocktype of each block
familinfo = zeros(length(randblocks),2);    % to save on- and offset time of each familiarization
familsndons = cell(1,length(randblocks));   % to save sound onset times during familiariation

%% PTBX: set the audio device
InitializePsychSound()      % argument (1) ONLY NEEDED FOR WINDOWS! for low latency
params.audiodevice = PsychPortAudio('Open', [], [], 1, params.Fs, 2); % check flags with >>psychportaudio open?

%% Create sounds
%freqs: frequencies of the different stimuli (Hz)
if params.ecog  % halftone steps
        freqs = [params.CF*(2^(6/12)); params.CF*(2^(7/12)); params.CF*(2^(8/12)); params.CF*(2^(9/12)); params.CF*(2^(10/12))];
    else            % quarter tones
        % freqs = [params.CF*(2^(16/24)); params.CF*(2^(17/24)); params.CF*(2^(18/24)); params.CF*(2^(19/24)); params.CF*(2^(20/24))];
        freqs = [params.CF*(2^(34/48)); params.CF*(2^(37/48)); params.CF*(2^(36/48)); params.CF*(2^(38/48)); params.CF*(2^(40/48))]; % 1,2,5: 3/8 steps. 3,4,5: 2/8 steps
end
    
for s=1:length(freqs)
    allsounds{s,1} = create_sound(freqs(s), params, params.stimdur);
    allsounds{s,2} = create_sound(freqs(s), params, params.devdur);
end


try
    scr = Initialize_myscreen(params);
    
    %% record eyes open resting state
    % call_rest(scr, params);
    
    %% dialog with subject
    subj_dialog(scr, params);
    
    Priority(2);             % PTBX switches MATLAB into real time mode

    %% Wait for MRI trigger or corresponding keyboard button
    wait_trigger(scr, params);

    %% start stimulus presentation
    
    tic
    t0 = GetSecs;
    WaitSecs(2);

    for thisblock = 1:length(randblocks) % for each block
        
        blocktype = randblocks(thisblock);

        % specify order of all stimuli to be played in this block
        stimsorder = create_stimsorder(blocktype, params);

        % specify SoA
        [allSoA] = create_SoA(blocktype, stimsorder, params);
        
        % create stimdur and eventually vary        
        if params.vary_stimdur && (blocktype==3 || blocktype==4)
            stimsdur = [ones(1,length(stimsorder)*3/4) ones(1,length(stimsorder)*1/4)*2];
            stimsdur = shuffle(stimsdur);
        else
            stimsdur = ones(1,length(stimsorder));
        end
        
        % familiarize subject with target sound before each block
        familinfo(thisblock,1) = GetSecs-t0;    % save onset time
        familsndons{thisblock} = familiarize(scr, allsounds{params.targetindx,1}, params, t0);
        familinfo(thisblock,2) = GetSecs-t0;    % save offset time
        
        blockinfo(thisblock,1) = GetSecs-t0;
        blockinfo(thisblock,3) = blocktype;

        for thisstim=1:size(stimsorder,2);      % for each stimulus
            if thisstim==1, 
                t_prevoff = GetSecs; 
                PsychPortAudio('FillBuffer', params.audiodevice, allsounds{stimsorder(thisstim),1});
            end
            RT = 0;
            responded = 0; % boolean, to avoid that MR TTL is counted as press

            thisSoA = allSoA(thisstim);
            t_stimstart = PsychPortAudio('Start', params.audiodevice, 1, 0, 1); % repetitions=1, start time=0s, 1=waitforsound & return onset time
            % now fill up buffer for next sound
            if thisstim<size(stimsorder,2), PsychPortAudio('FillBuffer', params.audiodevice, allsounds{stimsorder(thisstim+1),stimsdur(thisstim+1)}); end
            WaitSecs('UntilTime',t_stimstart+params.stimdur+0.05);  
            
            keyCode=zeros(1,256); % instead of Flsuhevents()
            while ~responded && (GetSecs-t_prevoff) < thisSoA
                [keyIsDown,secs,keyCode] = KbCheck(params.keydevice);
                responded = ~isempty(find(keyCode(params.buttonnum)));
            end
            if responded, RT=secs-t0; end

            % immediate feedback after each trial
            if params.ispractice && (responded || stimsorder(thisstim)==params.targetindx)     %to reduce load, restirct call of trial_feedback
                t_feedback = trial_feedback(stimsorder(thisstim), keyCode(params.buttonnum), params, scr, t0);
            else
                t_feedback = 0;
            end
            WaitSecs('UntilTime', t_prevoff+thisSoA);
            
            t_prevoff=GetSecs;  % get stamp as soon as possible after previous use!
            
            % blocktype, stimulus type, UPCOMING SoA, stimulus onset, respose onset, visual feedback onset 
            resultsmat((thisblock-1)*size(stimsorder,2)+thisstim,:) = [blocktype, stimsorder(thisstim), thisSoA, t_stimstart-t0, RT, t_feedback];
        end
        
        blockinfo(thisblock,2) = GetSecs-t0;    % save block offset time
        
        WaitSecs(params.IBI);                   % inter-block interval
    end
    
    toc
    WaitSecs('UntilTime', t0+params.endtime); 	% to synch to end of scan
    toc % prints elapsed time to standard output
    
    resultsmat                                  % to standard output
    [hits, averageRT, false_alarms] = analyze_perform(resultsmat, params)   % for all blocks (separately)
    
    run_feedback(mean(hits), sum(false_alarms), scr);
    
    
    %% save data
    if params.ecog,
        subjdir=fullfile(rootdir, 'ECoG_results', subjID);
    else
        subjdir=fullfile(rootdir, 'results', subjID);
    end
    if ~(exist(subjdir)==7)
        mkdir(subjdir);
        disp 'making new subject diectory'
    end
    
    if params.ispractice
        savepath = fullfile(subjdir, [subjID '_Audio_log_practice_run' int2str(runnum)]);
    else
        savepath = fullfile(subjdir, [subjID '_Audio_log_run' int2str(runnum)]);
    end
    
    if exist([savepath '.mat'])==2
        savepath = fullfile(subjdir, ['conflict_' subjID '_Audio_log_run' int2str(runnum)]);
        disp 'WARNING: file already exists. Saving with alternative filename "conflict_<origfilename>"'
        beep; WaitSecs(0.5); beep; WaitSecs(0.5); beep;
    end
    worksp_savepath=[savepath '_workspace'];
    
    save(savepath, 'hits', 'averageRT', 'false_alarms', 'resultsmat', 'stimsorder', 'allSoA', 'params', 'blockinfo', 'familinfo', 'familsndons');
    save(worksp_savepath);  % save all workspace variables, just in case
    
    close all;
    Screen('CloseAll');
    PsychPortAudio('Close', params.audiodevice);
    ShowCursor

catch
    close all
    Screen('CloseAll');
    PsychPortAudio('Close');
    ShowCursor
    errorfile=fullfile(rootdir, 'results', [subjID '_errorfile']);
    save(errorfile)
    error(['program stopped unfinished. Saving workspace to ' errorfile]);
    psychrethrow(psychlasterror);
end

%================ end of script; subfunctions follow ====================

%% set the screen, with psychtoolbox
function [scr] = Initialize_myscreen(params)

scr.red = [200 0 0];       % FA
scr.green = [0 150 0];     % hit
scr.orange = [255 110 0];  % miss
scr.grey = [50 50 50];     % fixation corss
scr.white = [200 200 200]; % text
scr.black = [0 0 0];       % background

HideCursor;
[scr.window, scr.res]=Screen('OpenWindow', 0, 0);
scr.rect=[0 0 scr.res(3) scr.res(4)];

[scr.window, scr.res]=Screen('OpenWindow', 0, 0);
scr.rect=[0 0 scr.res(3) scr.res(4)];

scr.hitwin=Screen('OpenOffscreenWindow', scr.window, 0, scr.rect);
Screen('FillRect', scr.hitwin, scr.green, [scr.res(3)/2-30 scr.res(4)/2-30 scr.res(3)/2+30 scr.res(4)/2+30]);
if params.ecog, Screen('FillRect', scr.hitwin, scr.white, [scr.res(3)-60 scr.res(4)-60 scr.res(3) scr.res(4)]); end     % for ECoG

scr.misswin=Screen('OpenOffscreenWindow', scr.window, 0, scr.rect);
Screen('FillRect', scr.misswin, scr.orange, [scr.res(3)/2-30 scr.res(4)/2-30 scr.res(3)/2+30 scr.res(4)/2+30]);
if params.ecog, Screen('FillRect', scr.misswin, scr.white, [scr.res(3)-60 scr.res(4)-60 scr.res(3) scr.res(4)]); end    % for ECoG

scr.FAwin=Screen('OpenOffscreenWindow', scr.window, 0, scr.rect);
Screen('FillRect', scr.FAwin, scr.red, [scr.res(3)/2-30 scr.res(4)/2-30 scr.res(3)/2+30 scr.res(4)/2+30]);
if params.ecog, Screen('FillRect', scr.FAwin, scr.white, [scr.res(3)-60 scr.res(4)-60 scr.res(3) scr.res(4)]); end      % for ECoG

scr.textwin=Screen('OpenOffscreenWindow', scr.window, 0, scr.rect);
Screen('TextSize', scr.textwin , 40)

scr.fixwin=Screen('OpenOffscreenWindow', scr.window, 0, scr.rect);
Screen('TextSize', scr.fixwin , 100)
if params.ispractice
    Screen('DrawText', scr.fixwin,'+', scr.res(3)/2-30, scr.res(4)/2-70, scr.grey);
end

%%
function[] = call_rest(scr, params)

instructions = ['For the next minute, please just relax.'...
                '\n\n\n\n Please fixate at center of screen\n\n without moving!'...
                '\n\n\n\n Press any button to start fixation!'];
DrawFormattedText(scr.textwin, instructions, 'center', 'center', scr.white);
if params.ecog, Screen('FillRect', scr.textwin, scr.white, [scr.res(3)-60 scr.res(4)-60 scr.res(3) scr.res(4)]); end    % for ECoG
Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
kbWait;
Screen('FillRect', scr.textwin, scr.black, scr.rect);       % clear window for later use
Screen('CopyWindow', scr.fixwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
waitSecs(50);

%%
function [] = subj_dialog(scr, params)

% instructions = ['The target sound has higher pitch \n than all other sounds. \n\n\n The target sound (pitch) \n remains always the same.'...
%     '\n\n\n Durations may vary but are not relevant.'...
%     '\n\n\n Press button as fast as possible \n when hearing the target!'...
%     '\n\n\n Please fixate at center of screen! \n\n\n Press button to continue!'];
% DrawFormattedText(scr.textwin, instructions, 'center', 'center', scr.white);
% if params.ecog, Screen('FillRect', scr.textwin, scr.white, [scr.res(3)-60 scr.res(4)-60 scr.res(3) scr.res(4)]); end    % for ECoG
% Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
% Screen('Flip', scr.window);
% WaitSecs(1);
% keyIsDown = 0;
% pressedCode = 0;
% FlushEvents();
% while pressedCode~=params.buttonnum
%     [keyIsDown,secs,keyCode] = KbCheck();
%     if keyIsDown, pressedCode = find(keyCode,1); end;
% end
% Screen('FillRect', scr.textwin, scr.black, scr.rect);       % clear window for later use
% 
% Screen('CopyWindow', scr.fixwin, scr.window, scr.rect, scr.rect);
% Screen('Flip', scr.window);
% 
% WaitSecs(1);

if params.ispractice
    DrawFormattedText(scr.textwin, 'Training session: you receive feedback:', 'center', scr.res(4)/2-150, scr.white);
    Screen('FillRect', scr.textwin, scr.green, [scr.res(3)/3-30 scr.res(4)/2-30 scr.res(3)/3+30 scr.res(4)/2+30]);
    Screen('DrawText', scr.textwin,'detected', scr.res(3)/3-120, scr.res(4)/2+70, scr.white);
    Screen('FillRect', scr.textwin, scr.orange, [scr.res(3)/2-30 scr.res(4)/2-30 scr.res(3)/2+30 scr.res(4)/2+30]);
    Screen('DrawText', scr.textwin,'missed', scr.res(3)/2-70, scr.res(4)/2+70, scr.white);
    Screen('FillRect', scr.textwin, scr.red, [scr.res(3)*2/3-30 scr.res(4)/2-30 scr.res(3)*2/3+30 scr.res(4)/2+30]);
    Screen('DrawText', scr.textwin,'false alarm', scr.res(3)*2/3-70, scr.res(4)/2+70, scr.white);
    DrawFormattedText(scr.textwin, 'Press button to continue!', 'center', scr.res(4)/2+150, scr.white);
    Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
    Screen('Flip', scr.window);
    WaitSecs(1);
    nextinstr = 'Do not move! \n\n Please FIXATE central cross!';
else
    DrawFormattedText(scr.textwin, 'No feedback will be given! \n\nPress button to continue!', 'center', 'center', scr.white);
    Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
    Screen('Flip', scr.window);
    WaitSecs(1);
    nextinstr = 'Do not move! \n\n Please CLOSE EYES!';
end

pressedCode_2 = 0;
FlushEvents();
while pressedCode_2~=params.buttonnum
    [keyIsDown,secs,keyCode] = KbCheck();
    if keyIsDown, pressedCode_2 = find(keyCode,1); end;
end
Screen('FillRect', scr.textwin, scr.black, scr.rect);       % clear window for later use

%
DrawFormattedText(scr.textwin, nextinstr, 'center', 'center', scr.white);
Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
WaitSecs(2.5);
Screen('FillRect', scr.textwin, scr.black, scr.rect);       % clear window for later use
%

Screen('CopyWindow', scr.fixwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);

WaitSecs(1);

%%
function [] = wait_trigger(scr, params)

DrawFormattedText(scr.textwin, 'Ready \nWaiting for scanner trigger', 'center', scr.res(4)-150, scr.white);
if params.ecog, Screen('FillRect', scr.textwin, scr.white, [scr.res(3)-60 scr.res(4)-60 scr.res(3) scr.res(4)]); end % for ECoG
if params.ispractice,
    Screen('TextSize', scr.textwin , 100);
    Screen('DrawText', scr.textwin,'+', scr.res(3)/2-30, scr.res(4)/2-70, scr.grey);
    Screen('TextSize', scr.textwin , 40); % set it back to default
end % add fixation cross
Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
Screen('FillRect', scr.textwin, scr.black, scr.rect);       % clear window for later use

for i=1:params.dummies+1  % number of TTLs to wait for (=vols to throw away, NOT+1 because of previous waiting)
    WaitSecs(0.5);
    keyIsDown = 0;
    pressedCode = 0;
    FlushEvents();
    while pressedCode~=params.TTLbutton
        [keyIsDown,secs,keyCode] = KbCheck();
        if keyIsDown, pressedCode = find(keyCode,1); end;
    end
end

Screen('CopyWindow', scr.fixwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);

%%
function [ons] = familiarize(scr, targsound, params, tnull)

ons = []; 

if params.ispractice
    DrawFormattedText(scr.textwin, 'Memorize this target sound', 'center', 'center', scr.white);
    if params.ecog, Screen('FillRect', scr.textwin, scr.white, [scr.res(3)-60 scr.res(4)-60 scr.res(3) scr.res(4)]); end % for ECoG
    Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
    Screen('Flip', scr.window);
    Screen('FillRect', scr.textwin, scr.black, scr.rect);       % clear window for later use
end
WaitSecs(0.5);


% to familiarize subject with target sound before each block
PsychPortAudio('FillBuffer', params.audiodevice, targsound);
for r=1:3, %sound(targsound, params.Fs);
    thisons = PsychPortAudio('Start', params.audiodevice, 1, 0, 1);   % repetitions=1, start time=0s, 1= return onset
    % s = PsychPortAudio('GetStatus', params.audiodevice)   % to get info on audio device performance
    ons = [ons thisons-tnull];
    WaitSecs(2);
end

% if params.ecog, Screen('FillRect', scr.textwin, scr.white, [scr.res(3)-60
% scr.res(4)-60 scr.res(3) scr.res(4)]); end % for ECoG
if params.ispractice, 
    DrawFormattedText(scr.textwin, 'Experiment starts now', 'center', 'center', scr.white); 
    Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
    Screen('Flip', scr.window);
    Screen('FillRect', scr.textwin, scr.black, scr.rect);       % clear window for later use
    % fixation cross
    Screen('CopyWindow', scr.fixwin, scr.window, scr.rect, scr.rect);
    Screen('Flip', scr.window);
end
WaitSecs(2);


%%
function [stimsorder] = create_stimsorder(blocktype, params)
        
stimsorder=[];

if blocktype==1 | blocktype==3  % easy discrimination
    tmp=[ones(1,4)*1 ones(1,5)*2 5];
    for r=1:params.reps/2, stimsorder=[stimsorder tmp(randperm(length(tmp)))]; end
    tmp=[ones(1,5)*1 ones(1,4)*2 5];
    for r=1:params.reps/2, stimsorder=[stimsorder tmp(randperm(length(tmp)))]; end
else                            % hard discrimination
    tmp=[ones(1,4)*3 ones(1,5)*4 5];
    for r=1:params.reps/2, stimsorder=[stimsorder tmp(randperm(length(tmp)))]; end
    tmp=[ones(1,5)*3 ones(1,4)*4 5];
    for r=1:params.reps/2, stimsorder=[stimsorder tmp(randperm(length(tmp)))]; end
end

%%
function [allSoA] = create_SoA(blocktype, stimsorder, params)

% SoA duration (preceeding the respective stimulus! SoA depends on wether the NEXT stim is target)
SoA = params.SoA;
targs = length(find(stimsorder==params.targetindx));
if blocktype ==1 || blocktype==2
    targsSoA = repmat(SoA, 1, targs);
    nontargsSoA = repmat(SoA,1,length(stimsorder)-targs);
else
    if params.reps==12
        targsSoA = [SoA-0.2 SoA-0.15 SoA-0.1 SoA-0.05 SoA SoA SoA SoA SoA+0.05 SoA+0.1 SoA+0.15 SoA+0.2]; % mean==SoA
    elseif params.reps==10
        targsSoA= [SoA-0.2 SoA-0.18 SoA-0.17 SoA-0.15 SoA SoA SoA+0.05 SoA+0.1 SoA+0.15 SoA+0.4];   % mean==SoA, with one annoyingly long one
    elseif params.reps==8
        targsSoA = [SoA-0.2 SoA-0.1 SoA-0.05 SoA SoA SoA+0.05 SoA+0.1 SoA+0.2];                     % mean==SoA
    elseif params.reps==6
        targsSoA = [SoA-0.2 SoA-0.1 SoA SoA SoA+0.1 SoA+0.2];                                       % mean==SoA
    elseif params.reps==4
        targsSoA = [SoA-0.1 SoA-0.5 SoA+0.1 SoA+0.2];                                     
    end
    targsSoA    = targsSoA(randperm(length(targsSoA)));
    nontargsSoA = repmat(targsSoA,1,9);  % there are 9 nontarget sounds per rep
    nontargsSoA = nontargsSoA(randperm(length(nontargsSoA)));
end

targSoAcount=1;
nontargSoAcount=1;
for thisstim=1:length(stimsorder)
    if thisstim==length(stimsorder)
        thisSoA=params.SoA;
    else
        if stimsorder(thisstim+1)==params.targetindx;
            thisSoA=targsSoA(targSoAcount);
            targSoAcount=targSoAcount+1;
        else
            thisSoA = nontargsSoA(nontargSoAcount);
            nontargSoAcount=nontargSoAcount+1;
        end
    end
    allSoA(thisstim) = thisSoA; 
end

%%
function thissound = create_sound(thisfreq, params, thisdur)

samplepoints = linspace(0, thisdur, thisdur*params.Fs);

ramp = ones(size(samplepoints));
ramp(1:params.Fs*params.rampdur) = linspace(0,1,params.Fs*params.rampdur);
ramp(end-(floor(params.Fs*params.rampdur)-1):end) = linspace(1,0,params.Fs*params.rampdur);

% "sin" calculates radiants into sine value
% recall that angular frequency is: randiants/s = 2*pi*f since 2pi is 1 circular cycle
thissound = sin(2 * pi * thisfreq * samplepoints);
thissound = thissound .* ramp;

thissound = [thissound; thissound];     % stereo 2 chn


%%
function [t_feed] = trial_feedback(stimnum, keyPressed, params, scr, t0)

t_feed=GetSecs;

feedbackwin=[];
if stimnum==params.targetindx
    if keyPressed
        feedbackwin=scr.hitwin;
    else
        feedbackwin=scr.misswin;
    end
elseif keyPressed %FA
    feedbackwin=scr.FAwin;
end

if ~isempty(feedbackwin)
    Screen('CopyWindow', feedbackwin, scr.window, scr.rect, scr.rect);
    Screen('Flip', scr.window);
    WaitSecs('UntilTime', t_feed+params.feedbdur);

    Screen('CopyWindow', scr.fixwin, scr.window, scr.rect, scr.rect);
    Screen('Flip', scr.window);  
    t_feed=GetSecs-t0;
else
    t_feed=0;
end

%%
function [hits, averageRT, false_alarms] = analyze_perform(blockresults, params)

for bl_type=1:4
    targets_indx = find(blockresults(:,1)==bl_type & blockresults(:,2)==params.targetindx);
    pressed_indx = find(blockresults(:,1)==bl_type & blockresults(:,5)-blockresults(:,4)>0.005);

    
    correct_count = 0;
    correct_RT = [];
    
    for i=1:size(targets_indx,1)
        
        if (0.005 < blockresults(targets_indx(i),5) - blockresults(targets_indx(i),4) && blockresults(targets_indx(i),5) - blockresults(targets_indx(i),4) < params.RTlim)
            correct_count = correct_count+1;
            correct_RT = [correct_RT (blockresults(targets_indx(i),5) - blockresults(targets_indx(i),4))];
            
        % include responses that happen after next stimulus presentation
        elseif targets_indx(i)~=size(blockresults,1) && ( 0 < blockresults(targets_indx(i)+1,5) - blockresults(targets_indx(i),4) && blockresults(targets_indx(i)+1,5) - blockresults(targets_indx(i),4) < params.RTlim)
            disp('late response')
            correct_count = correct_count+1;
            correct_RT = [correct_RT (blockresults(targets_indx(i)+1,5) - blockresults(targets_indx(i),4))];
        end

    end
    
    averageRT(bl_type) = mean(correct_RT);

    hits(bl_type) = correct_count / length(targets_indx);        %hit rate

    false_alarms(bl_type) = length(pressed_indx) - correct_count;
    fa_rate(bl_type) = false_alarms(bl_type) / (length(find(blockresults(:,1)==bl_type))-length(targets_indx));         % false alarm rate

    % dprime(bl_type) = norminv(hits(bl_type)) - norminv(fa_rate(bl_type));
end
                

%%
function [] = run_feedback(thishits, thisFAs, scr)

mssg = [num2str(round(thishits*100)) ' % of targets detected \n\n' num2str(thisFAs) ' wrong button presses. \n\n\n\n Press button to exit!'];
DrawFormattedText(scr.textwin, mssg, 'center', 'center', scr.white);

Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
FlushEvents();
KbWait;
Screen('FillRect', scr.textwin, scr.black, scr.rect); % clear window for later use

Screen('CopyWindow', scr.fixwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
