function task_map = create_Arun(fbounds,nfreq,ntrials,TR,silentTRs,stimTRs,acqTRs,checkerFlag,complexFlag,sub,day)


%%% this m file will create trial maps.  the user will specify the number of blocks,
%%% the number of frequencies to span the space (assumed to be 20Hz to 20kHz), the
%%% number of trials of each frequency, the ratio of aquisitons to silence,
%%% and whether the stimuli are pure tones or checkerboards.
clc

if nargin >= 10;
    subject = sub;
    disp(['please note, you will be saving a UNIQUE taskmap due to ' ...
        'randomization.  check that this is the map you want before future use.'])
    task_map.params.day = day;
end

%%% get the parameters of the task map
%nblocks = input('please enter the number of blocks: ');

% fbounds = input(['please enter the two element vector indicating the ' ...
%     'lowest and highest frequency to be used in the stimulus set: ']);
% 
% nfreq = input(['please enter the number of frequencies ' ...
%     'you would like to span the space from ' num2str(fbounds(1))...
%     'Hz to ' num2str(fbounds(2)) 'Hz: ']);
% 
% ntrials = input(['please enter the number of trials you can tolerate ' ...
%     '(~15s per trial default => 220 trials = 55mins): ']);
% 
% TR = input('plese enter the TR: ');
% 
% silentTRs = input(['please enter the number of silent TRs: ']);
% 
% stimTRs = input(['please enter the number of stim TRs (these will be ' ...
%     'when the stimuli are presented): ']);
% 
% acqTRs = input('please enter the number of acquisition TRs : ');
% 
% checkerFlag = input(['would you like the stimuli to be checkerboards ' ...
%     ' or pure tones (enter c or p): '],'s');
% 
% complexFlag = input(['what level of complex stimuli would you like to include? enter : \n' ...
%  '0 for only simple channels \n2 for major and minor 3rds \n4 for 3rds and 5ths \n' ...
%  '5 for 3rds 5ths and octaves \n:  ']);


disp('  ');disp('  ');disp('   ')
disp('creating trials ...'); pause(2)
disp('  ');disp('  ');disp('   ')

%%% initialze task map with some stuff
task_map.params.fbounds.high = fbounds(2);
task_map.params.fbounds.low = fbounds(1);

task_map.params.silentTRs = silentTRs;
task_map.params.stimTRs = stimTRs;
task_map.params.acqTRs = acqTRs;
task_map.params.TR = TR;
task_map.params.TTLbutton = 34;      % corresponds to button "5" (through FORP system)

%%% dummy TRs
task_map.params.dummies = 5;

% hard code for now
fs = 44100;
envelope = 20; % ms
envelope_shape = 'exponential';

task_map.params.sampling_rate = fs;
task_map.params.envelope.dur = envelope;
task_map.params.envelope.shape = envelope_shape;
task_map.params.subject = subject;


%%% describe possible complex trial states 
cStates = {{'mj3rd','mn3rd'},{'mj3rd','mn3rd','mj5th','mn5th'},...
    {'mj3rd','mn3rd','mj5th','mn5th','oct'}};
cIdx = [0 1 0 2 3];

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
            
            
            %wave = trial_map(trial).wave;
            
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




