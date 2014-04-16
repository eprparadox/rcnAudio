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

% screen stuff (pack this into params later?)
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
DrawFormattedText(scr.textwin, readytext, 'center', scr.res(4)-150, scr.white);
Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
Screen('Flip', scr.window);
Screen('FillRect', scr.textwin, scr.black, scr.rect);
WaitSecs(3);

% Prepare stimuli
[scr.textwin]=Screen('OpenOffscreenWindow', scr.window, 0, scr.rect);
Screen('TextSize', scr.textwin , 100)

sample_text = ['J';'F';'Q';'Q';'N']; % each entry is a trial
num_trials = length(sample_text);
stim_time = [1 1 1 1 1]; % stim time for each trial
isi_time = [2 2 2 2 2]; % ISI time for each trial
user_key = '1!';
user_ans = zeros(1,num_trials); % empty vector for the user's answers
corr_ans = [0;0;0;1;0]; % what the user's answers should be, if all correct

% Display stimuli
for i = 1:num_trials
    start_time = GetSecs();
    
    % Show the stimulus
    DrawFormattedText(scr.textwin, sample_text(i), 'center', 'center', scr.white);
    Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
    Screen('Flip', scr.window);
    Screen('FillRect', scr.textwin, scr.black, scr.rect);
    
    % Loop until it is time to move on to the ISI, and look for a button 
    % press if the user has not already pressed during this stimulus
    key_not_pressed = true;
    next_event = start_time + stim_time(i);
    while GetSecs() < next_event
        if key_not_pressed
            [keyIsDown, secs, keyCode] = PsychHID('KbCheck');%device_forp);%device_kb);
            if keyIsDown
                keypress = KbName(find(keyCode));
                if isequal(keypress,user_key)
                    user_ans(i) = 1;
                    key_not_pressed = false;
                end
            end
        end
    end
        
    % Stop displaying the stimulus (i.e., begin ISI)
    DrawFormattedText(scr.textwin, '', 'center', 'center', scr.black);
    Screen('CopyWindow', scr.textwin, scr.window, scr.rect, scr.rect);
    Screen('Flip', scr.window);
    Screen('FillRect', scr.textwin, scr.black, scr.rect);
    
    % Loop until it is time to move on to the next stimulus, and look for a
    % button press if the user has not already pressed during this stimulus
    next_event = start_time + stim_time(i) + isi_time(i);
    while GetSecs() < next_event
        if key_not_pressed
            [keyIsDown, secs, keyCode] = PsychHID('KbCheck');%device_forp);%device_kb);
            if keyIsDown
                keypress = KbName(find(keyCode));
                if isequal(keypress,user_key)
                    user_ans(i) = 1;
                    key_not_pressed = false;
                end
            end
        end
    end        
end

% Return the user answers vector
disp('User answers by trial:')
disp(user_ans)

% Close the screen
sca;