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

% wait a little in the beginning, so it doesn't feel rushed
WaitSecs(1);

%%% general settings
%params.buttonnum = 30;      % FORPs 1,2,3,4 = 30, 31, 32, 33
%params.keydevice = 3%2;       % keyboard ID! fmri stim mac FORPs:3, MacBook: 5
%params.TTLbutton = 34;      % corresponds to button "5" (through FORP system)
%params.dummies  = 3;        % number of vols to throw away (in addition to 2 scanner dummies)

%blockinfo = zeros(length(randblocks),3);    % to save on- and offset time and blocktype of each block
%familsndons = cell(1,length(randblocks));   % to save sound onset times 

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

    

%'Ready \nWaiting for scanner trigger'
DrawFormattedText(scr.textwin, readytext, 'center', scr.res(4)-150, scr.white);
Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
Screen('FillRect', scr.textwin, scr.black, scr.rect);       % clear window for later use
    
%%%% %%% put wait for the go TTL pulse here
%%% wait trigger should be changed to wait for the number of dummy pulses and maybe display a get ready message
%%% note: actually it should take a given number of TTL pulses to wait.
%%% that way we can use it for the beginning and each trial;  also change
%%% it to return the current clock time

wait_trigger(task_map.params.dummies);
beep
%%%% start stimulus presentation
% the task has started now, write down the time
%tic
t0 = GetSecs;

% set to gray
% display a blank screen

% This Flip makes it gray for longer than black
% Can't help it from being initially black
Screen('FillRect',scr.textwin,scr.grey,[0 0 width height]);
Screen('Flip',scr.window);

for tr = 1:length(cTrial_map)
    
    %%% bulid stim (put current wave in the buffer)
    PsychPortAudio('FillBuffer',task_map.params.audiodevice,[cTrial_map(tr).wave; cTrial_map(tr).wave])
    events.silent_onsets(end+1) = GetSecs;
    wait_trigger(task_map.params.silentTRs);
    
    %%% play stim
    events.stim_onsets(end+1) = PsychPortAudio('Start', task_map.params.audiodevice, 1, 0, 1); % repetitions=1, start time=0s, 1=waitforsound & return onset time GetSecs;
    
    events.acquisition_onsets(end+1) = GetSecs;
    wait_trigger(task_map.params.acqTRs);
    
    
end
   
% 
% 
% if thisstim<size(stimsorder,2), PsychPortAudio('FillBuffer', params.audiodevice, allsounds{stimsorder(thisstim+1),stimsdur(thisstim+1)}); end
% WaitSecs('UntilTime',t_stimstart+params.stimdur+0.05);
% 
% keyCode=zeros(1,256); % instead of Flsuhevents()
% while ~responded && (GetSecs-t_prevoff) < thisSoA
%     [keyIsDown,secs,keyCode] = KbCheck(params.keydevice);
%     responded = ~isempty(find(keyCode(params.buttonnum)));
% end
% if responded, RT=secs-t0; end

close all;
Screen('CloseAll');
PsychPortAudio('Close', params.audiodevice);
ShowCursor

errorfile=fullfile(rootdir, 'results', [subjID '_errorfile']);
save(errorfile)
error(['program stopped unfinished. Saving workspace to ' errorfile]);
psychrethrow(psychlasterror);
end

%================ end of script; subfunctions follow ====================
%
%%% %% set the screen, with psychtoolbox
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

end

    % %%
    % function[] = call_rest(scr, params)
    %
    % instructions = ['For the next minute, please just relax.'...
    %                 '\n\n\n\n Please fixate at center of screen\n\n without moving!'...
    %                 '\n\n\n\n Press any button to start fixation!'];
    % DrawFormattedText(scr.textwin, instructions, 'center', 'center', scr.white);
    % if params.ecog, Screen('FillRect', scr.textwin, scr.white, [scr.res(3)-60 scr.res(4)-60 scr.res(3) scr.res(4)]); end    % for ECoG
    % Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
    % Screen('Flip', scr.window);
    % kbWait;
    % Screen('FillRect', scr.textwin, scr.black, scr.rect);       % clear window for later use
    % Screen('CopyWindow', scr.fixwin, scr.window, scr.rect, scr.rect);
    % Screen('Flip', scr.window);
    % waitSecs(50);
    %
    % %%
    % function [] = subj_dialog(scr, params)
    %
    % % instructions = ['The target sound has higher pitch \n than all other sounds. \n\n\n The target sound (pitch) \n remains always the same.'...
    % %     '\n\n\n Durations may vary but are not relevant.'...
    % %     '\n\n\n Press button as fast as possible \n when hearing the target!'...
    % %     '\n\n\n Please fixate at center of screen! \n\n\n Press button to continue!'];
    % % DrawFormattedText(scr.textwin, instructions, 'center', 'center', scr.white);
    % % if params.ecog, Screen('FillRect', scr.textwin, scr.white, [scr.res(3)-60 scr.res(4)-60 scr.res(3) scr.res(4)]); end    % for ECoG
    % % Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
    % % Screen('Flip', scr.window);
    % % WaitSecs(1);
    % % keyIsDown = 0;
    % % pressedCode = 0;
    % % FlushEvents();
    % % while pressedCode~=params.buttonnum
    % %     [keyIsDown,secs,keyCode] = KbCheck();
    % %     if keyIsDown, pressedCode = find(keyCode,1); end;
    % % end
    % % Screen('FillRect', scr.textwin, scr.black, scr.rect);       % clear window for later use
    % %
    % % Screen('CopyWindow', scr.fixwin, scr.window, scr.rect, scr.rect);
    % % Screen('Flip', scr.window);
    % %
    % % WaitSecs(1);
    %
    % if params.ispractice
    %     DrawFormattedText(scr.textwin, 'Training session: you receive feedback:', 'center', scr.res(4)/2-150, scr.white);
    %     Screen('FillRect', scr.textwin, scr.green, [scr.res(3)/3-30 scr.res(4)/2-30 scr.res(3)/3+30 scr.res(4)/2+30]);
    %     Screen('DrawText', scr.textwin,'detected', scr.res(3)/3-120, scr.res(4)/2+70, scr.white);
    %     Screen('FillRect', scr.textwin, scr.orange, [scr.res(3)/2-30 scr.res(4)/2-30 scr.res(3)/2+30 scr.res(4)/2+30]);
    %     Screen('DrawText', scr.textwin,'missed', scr.res(3)/2-70, scr.res(4)/2+70, scr.white);
    %     Screen('FillRect', scr.textwin, scr.red, [scr.res(3)*2/3-30 scr.res(4)/2-30 scr.res(3)*2/3+30 scr.res(4)/2+30]);
    %     Screen('DrawText', scr.textwin,'false alarm', scr.res(3)*2/3-70, scr.res(4)/2+70, scr.white);
    %     DrawFormattedText(scr.textwin, 'Press button to continue!', 'center', scr.res(4)/2+150, scr.white);
    %     Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
    %     Screen('Flip', scr.window);
    %     WaitSecs(1);
    %     nextinstr = 'Do not move! \n\n Please FIXATE central cross!';
    % else
    %     DrawFormattedText(scr.textwin, 'No feedback will be given! \n\nPress button to continue!', 'center', 'center', scr.white);
    %     Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
    %     Screen('Flip', scr.window);
    %     WaitSecs(1);
    %     nextinstr = 'Do not move! \n\n Please CLOSE EYES!';
    % end
    %
    % pressedCode_2 = 0;
    % FlushEvents();
    % while pressedCode_2~=params.buttonnum
    %     [keyIsDown,secs,keyCode] = KbCheck();
    %     if keyIsDown, pressedCode_2 = find(keyCode,1); end;
    % end
    % Screen('FillRect', scr.textwin, scr.black, scr.rect);       % clear window for later use
    %
    % %
    % DrawFormattedText(scr.textwin, nextinstr, 'center', 'center', scr.white);
    % Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
    % Screen('Flip', scr.window);
    % WaitSecs(2.5);
    % Screen('FillRect', scr.textwin, scr.black, scr.rect);       % clear window for later use
    % %
    %
    % Screen('CopyWindow', scr.fixwin, scr.window, scr.rect, scr.rect);
    % Screen('Flip', scr.window);
    %
    % WaitSecs(1);
    %
    % %%
    function [] = wait_trigger(TRs)
    
    TRs_passed = 0;
    while TRs_passed < TRs
        %[keyIsDown, secs, keyCode, deltaSecs] = KbCheck(device_forp);
        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck(5);
        if keyIsDown
            keypress = KbName(find(keyCode));
            %if isequal(keypress,task_map.params.TTLbutton)
            if isequal(keypress,'k')  % 14 is 'k' - for testing
                TRs_passed = TRs_passed + 1;
                clear keyIsDown keyCode keypress
                WaitSecs(1);
            end
        end
    end
    
    end
    
    %Screen('CopyWindow', scr.fixwin, scr.window, scr.rect, scr.rect);
    %Screen('Flip', scr.window);
 
    
    %%
% function thissound = create_sound(thisfreq, params, thisdur)
% 
% samplepoints = linspace(0, thisdur, thisdur*params.Fs);
% 
% ramp = ones(size(samplepoints));
% ramp(1:params.Fs*params.rampdur) = linspace(0,1,params.Fs*params.rampdur);
% ramp(end-(floor(params.Fs*params.rampdur)-1):end) = linspace(1,0,params.Fs*params.rampdur);
% 
% % "sin" calculates radiants into sine value
% % recall that angular frequency is: randiants/s = 2*pi*f since 2pi is 1 circular cycle
% thissound = sin(2 * pi * thisfreq * samplepoints);
% thissound = thissound .* ramp;
% 
% thissound = [thissound; thissound];     % stereo 2 chn
% 
% 
% %%
% function [t_feed] = trial_feedback(stimnum, keyPressed, params, scr, t0)
% 
% t_feed=GetSecs;
% 
% feedbackwin=[];
% if stimnum==params.targetindx
%     if keyPressed
%         feedbackwin=scr.hitwin;
%     else
%         feedbackwin=scr.misswin;
%     end
% elseif keyPressed %FA
%     feedbackwin=scr.FAwin;
% end
% 
% if ~isempty(feedbackwin)
%     Screen('CopyWindow', feedbackwin, scr.window, scr.rect, scr.rect);
%     Screen('Flip', scr.window);
%     WaitSecs('UntilTime', t_feed+params.feedbdur);
% 
%     Screen('CopyWindow', scr.fixwin, scr.window, scr.rect, scr.rect);
%     Screen('Flip', scr.window);  
%     t_feed=GetSecs-t0;
% else
%     t_feed=0;
% end
% 
% %%
% function [hits, averageRT, false_alarms] = analyze_perform(blockresults, params)
% 
% for bl_type=1:4
%     targets_indx = find(blockresults(:,1)==bl_type & blockresults(:,2)==params.targetindx);
%     pressed_indx = find(blockresults(:,1)==bl_type & blockresults(:,5)-blockresults(:,4)>0.005);
% 
%     
%     correct_count = 0;
%     correct_RT = [];
%     
%     for i=1:size(targets_indx,1)
%         
%         if (0.005 < blockresults(targets_indx(i),5) - blockresults(targets_indx(i),4) && blockresults(targets_indx(i),5) - blockresults(targets_indx(i),4) < params.RTlim)
%             correct_count = correct_count+1;
%             correct_RT = [correct_RT (blockresults(targets_indx(i),5) - blockresults(targets_indx(i),4))];
%             
%         % include responses that happen after next stimulus presentation
%         elseif targets_indx(i)~=size(blockresults,1) && ( 0 < blockresults(targets_indx(i)+1,5) - blockresults(targets_indx(i),4) && blockresults(targets_indx(i)+1,5) - blockresults(targets_indx(i),4) < params.RTlim)
%             disp('late response')
%             correct_count = correct_count+1;
%             correct_RT = [correct_RT (blockresults(targets_indx(i)+1,5) - blockresults(targets_indx(i),4))];
%         end
% 
%     end
%     
%     averageRT(bl_type) = mean(correct_RT);
% 
%     hits(bl_type) = correct_count / length(targets_indx);        %hit rate
% 
%     false_alarms(bl_type) = length(pressed_indx) - correct_count;
%     fa_rate(bl_type) = false_alarms(bl_type) / (length(find(blockresults(:,1)==bl_type))-length(targets_indx));         % false alarm rate
% 
%     % dprime(bl_type) = norminv(hits(bl_type)) - norminv(fa_rate(bl_type));
% end
%                 
% 
% %%
% function [] = run_feedback(thishits, thisFAs, scr)
% 
% mssg = [num2str(round(thishits*100)) ' % of targets detected \n\n' num2str(thisFAs) ' wrong button presses. \n\n\n\n Press button to exit!'];
% DrawFormattedText(scr.textwin, mssg, 'center', 'center', scr.white);
% 
% Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
% Screen('Flip', scr.window);
% FlushEvents();
% KbWait;
% Screen('FillRect', scr.textwin, scr.black, scr.rect); % clear window for later use
% 
% Screen('CopyWindow', scr.fixwin, scr.window, scr.rect, scr.rect);
% Screen('Flip', scr.window);
