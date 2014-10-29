function task_map = create_Arun(sub)

%%% this m file will create trial maps.  for the attentional run of the rcnAudio task
%%% the user will specify nothing as the script will load up the 1st days'
%%% task_map to ensure that the same stimuli are used
clc
task_file = [sub '-1_rcnAudio_task_map.mat'];

try
    load(task_file)
catch
    disp(['expecting to find file: ' task_file ' in the current dir.  please be sure youre in the right place'])
end


disp('  ');disp('  ');disp('   ')
disp('creating trials ...'); pause(2)
disp('  ');disp('  ');disp('   ')

% freq alteration list
alt = [0.0035 0.0045 0.0055 0.0065 0.0075 ...
    -0.0035 -0.0045 -0.0055 -0.0065 -0.0075];

% alphabet
alphabet=char('a'+(1:26)-1);

% get number of blocks
nblocks = task_map.trial_map(end).block;

% odd blocks are visual task
for b = 1:length(task_map.trial_map)
    bl = task_map.trial_map(b).block;
    if mod(bl,2)
        task_map.trial_map(b).task_type = 'visual';
    else
        task_map.trial_map(b).task_type = 'audio';
    end
end


% go block by block and alter existing waves to create auditory task
for i = 1:length(task_map.trial_map);
    if strcmp(task_map.trial_map(i).task_type,'audio') && (task_map.trial_map(i).frequency ~= 0)
        
        % get wave and freq
        the_wave = task_map.trial_map(i).wave;
        the_freq = task_map.trial_map(i).frequency;
        the_type = task_map.trial_map(i).type;
        
        % get burst primers
        [burst_centers burst_edges nbursts] = burst_primer(the_wave);
        
        % get the leading and lagging edges.  back up and move forward 1
        % to get the zero point of the wave
        burst_leads = burst_edges(1:2:end) - 1;
        burst_lags = burst_edges(2:2:end) + 1;
        ibi = burst_leads(2) - burst_lags(1);
        
        % move the burst or alter the burst frequency on 80 percent of the trials, so if rand > .2
        if rand(1) > 0.2
            
            % now choose a random burst in the last three quarters (ie if
            % there are 100 bursts move one in the range 25:99)
            bto_move = round((0.75*nbursts) * rand(1)) + (0.25 * nbursts);
            
            % grab that burst and move it
            the_wave = task_map.trial_map(i).wave;
            aidx = burst_leads(bto_move); bidx = burst_lags(bto_move);
            
            % additional alterations to the burst can easily be made here
            burst = the_wave(aidx:bidx);
            
            if rand(1) > 0.75 && strcmp(the_type,'pure')
                
                % alter frequency
                from_ref = datasample(alt,1);
                the_freq = the_freq + the_freq * from_ref;
                burst = make_burst(the_freq,task_map.params.frequencies);
                the_wave(aidx:bidx) = burst;
                
            else
                % alter rhythm
                % zero and move
                the_wave(aidx:bidx) = 0;
                the_wave(aidx - floor(ibi/2):bidx - floor(ibi/2)) = burst;
                
                % alter
                task_map.trial_map(i).wave = the_wave;
            end
        end
        
    elseif strcmp(task_map.trial_map(i).task_type,'visual')
        % 75% include targets
        if rand(1) > 0.80
            
            if rand(1) > 0.50
                % create letter target trial
                % chose ten letters at random
                letters = datasample(alphabet,10);
                
                % since it's a target, choose a random element
                targ = randi([2 10],1);
                letters(targ) = letters(targ-1);
                task_map.trial_map(i).task_params.letters = letters;
                task_map.trial_map(i).task_params.targ = targ;
                task_map.trial_map(i).task_params.targ_type = 'letter_targ';
                task_map.trial_map(i).task_params.targ_letter = letters(targ);
                
            else
                % create red letter target trial
                % chose ten letters at random
                letters = datasample(alphabet,10);
                
                % since it's a target, choose a random element
                targ = randi([2 10],1);
                letters(targ) = letters(targ-1);
                task_map.trial_map(i).task_params.letters = letters;
                task_map.trial_map(i).task_params.targ = targ;
                task_map.trial_map(i).task_params.targ_type = 'red_targ';
                task_map.trial_map(i).task_params.targ_letter = letters(targ);
            end
            
        else
            
            if rand(1) > 0.5
                % create lure trial
                % create letter target trial
                % chose ten letters at random
                letters = datasample(alphabet,10);
                
                % since it's a target, choose a random element
                targ = randi([3 10],1);
                letters(targ) = letters(targ-2);
                task_map.trial_map(i).task_params.letters = letters;
                task_map.trial_map(i).task_params.targ = 0;
                task_map.trial_map(i).task_params.targ_type = 'letter_lure';
                task_map.trial_map(i).task_params.targ_letter = [];
                
            else
                % create control trial
                letters = datasample(alphabet,10);
                                
                task_map.trial_map(i).task_params.letters = letters;
                task_map.trial_map(i).task_params.targ = 0;
                task_map.trial_map(i).task_params.targ_type = 'letter_control';
                task_map.trial_map(i).task_params.targ_letter = [];
            end
        end
    end
end


disp(['saving task_map as ' num2str(sub) '-attn_rcnAudio_task_map'])
save([num2str(sub) '-attn_rcnAudio_task_map.mat'],'task_map')




