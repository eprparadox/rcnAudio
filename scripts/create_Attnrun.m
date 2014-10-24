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

% get number of blocks
nblocks = task_map.trial_map(end).block;

% odd blocks are visual task
for b:length(task_map.trial_map)
    bl = task_map.trial_map(b).block;
    if mod(b1,2)
        task_map.trial_map(bl).task_type = 'visual';
    else
        task_map.trial_map(bl).task_type = 'audio';
    end
end


% go block by block and alter existing waves to create auditory task
for i = 1:length(task_map.trial_map);
    if strcmp(task_map.trial_map(i),'audio')
        
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
            aidx = burst_leads(bto_move) + 1; bidx = burst_lags(bto_move) - 1;
            
            % additional alterations to the burst can easily be made here
            burst = the_wave(aidx:bidx);
                        
            if rand(1) > 0.75 && strcmp(type,'pure')
                
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
        
    elseif strcmp(task_map.trial_map,'visual')
        % 75% include targets
        if rand(1) > 0.80
            % create target trial
            
        else 
            
            if rand(1) > 0.5
                %create lure trial
            elseif rand(1) < 0.5
                % create control trial
            end
        end
            
        
        
        
    end    
end

[burst_centers burst_edges nbursts] = burst_primer(the_wave);

if complexFlag ~= 0
    %%% 70% of these will be pure and 30% will be complex so that we can
    %%% still have some usable data if the complex trials don't work out
    nPureTrials = floor(ntrials * .7);
    nComplexTrials = floor(ntrials * .3);
end

%%% create list of center frequencies
freqlist = round(2.^linspace(log2(fbounds(1)), log2(fbounds(2)),nfreq));

if day == 2
    freqlist = freqlist(1:2:end);
end
%%% add the silent trials 
freqlist = [0 freqlist];

%%% record
task_map.params.frequencies = freqlist;
energy = [];
    


%%% k here we go
if complexFlag ~= 0
    
    %%%% vector trial_frequencies will be the freqs per trial
    pure_trial_freqs = repmat(freqlist,[1 floor(nPureTrials/length(freqlist))]);
    pure_trial_labels = repmat({'pure'},1, length(pure_trial_freqs));
    complex_trial_freqs = repmat(freqlist(2:end),[1 floor(nComplexTrials/length(freqlist(2:end)))]);
    complex_relation = repmat(cStates{cIdx(complexFlag)},1,floor(nComplexTrials/length(cStates{cIdx(complexFlag)})));
    
    %%% adjust for the possible odd number of complex trial types 
    while length(complex_trial_freqs) ~= length(complex_relation)
        complex_relation = complex_relation(1:end-1);
    end
    
    %%% the real deal frequency list
    trial_frequencies = [pure_trial_freqs complex_trial_freqs];
    trial_labels = [pure_trial_labels complex_relation];
    
    %%% correct numbers of trials for how many we can actually make of each type
    %%% (depending on the users' input, we might not be able to deliever
    %%% the exact number of trials asked for)
    nPureTrials = length(pure_trial_freqs);
    nComplexTrials = length(complex_trial_freqs);
    nTrials = nPureTrials + nComplexTrials;
    
    rand_idxs = randperm(nTrials);
    
    %%% solve for blocks
    blockRelTrial = 1; block = 1;
    TPB = ceil(nTrials/8);  % 8 blocks hard coded here
    
    %%% build trial map
    for trial = 1:nTrials
            
            %%% fill out trial map
            this_freq = trial_frequencies(rand_idxs(trial));
            type = trial_labels{rand_idxs(trial)};
            
            trial_map(trial).frequency = this_freq;
            trial_map(trial).type = type;
            trial_map(trial).block = block;
            
            trial_map(trial).blockRelTrialNum = blockRelTrial;
            if floor(blockRelTrial/TPB) == 1
                blockRelTrial = 1; block = block + 1;
            else
                blockRelTrial = blockRelTrial + 1;
            end
            
            trial_map(trial).abs_trial = trial; %redundant
            [trial_map(trial).wave thise] = make_wave(this_freq, type, silentTRs, stimTRs, acqTRs, TR, fs, envelope,freqlist);
            trial_map(trial).energy = thise;
            
            
            wave = trial_map(trial).wave;
            if length(find(isnan(wave))) > 0
                disp([' trial number ' num2str(trial) ' is a ' type ' trial of freq: ' num2str(this_freq) ' and has NaNs in the wave'])
                pause(3)
            end
            
            %energy = [energy thise];
%             
%             disp([num2str(this_freq) ' : ' type])
%             plot(wave(1:4000));
%             %set(gcf,'un','n','pos',[0,0,1,1])
%             pause(.1)
%             sound(trial_map(trial).wave,44100);
%             pause(10)
%             close all;
    end
        
end


disp(['saving task_map as ' num2str(subject) '-attn_rcnAudio_task_map'])
save([num2str(subject) '-attn_rcnAudio_task_map.mat'],'task_map')




