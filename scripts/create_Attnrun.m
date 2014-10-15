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


%%% ok number of blocks is an even division of the number of trials into
%%% tenths
nblocks = 10;

%= floor(ntrials/10);


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


%%% put everything in the task_map
task_map.trial_map = trial_map;

if nargin >= 10
   disp(['saving task_map as ' num2str(subject) '-' num2str(day) '_rcnAudio_task_map'])
   save([num2str(subject) '-' num2str(day) '_rcnAudio_task_map.mat'],'task_map')
end




