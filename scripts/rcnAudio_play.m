freq_list =  [200,415,862,1789,3713,7708,16000]
fs = 44100

for fq = 1:length(freq_list)
    presented = load([num2str(freq_list(fq)) '_Hz_presented.mat']);
    reconned = load([num2str(freq_list(fq)) '_Hz_Sreconned_normed_manaul_masked.mat']);
    smoothed = sgolayfilt(reconned.rcnWave',4,41);
    %smoothed = fastsmooth(reconned.rcnWave,10);
    pwave = presented.wave; pwave = pwave ./ max(pwave); pwave = pwave .* .8;
    rwave = reconned.rcnWave; rwave = rwave ./ max(rwave); rwave = rwave .* .8;
    s1 = 44100; s2 = 44700;
    subplot(2,1,1);plot(presented.wave(s1:s2));
    subplot(2,1,2);plot(reconned.rcnWave(s1:s2),'r-');
    %subplot(3,1,3);plot(smoothed(3000:4000),'g-');
    disp(['presented stimuli ' num2str(freq_list(fq)) ' Hz']);
    sound(pwave,fs)
    pause(1.5)
    disp(['reconstrcuted stimuli ' num2str(freq_list(fq)) ' Hz']);
    sound(rwave,fs)
    %pause(1.5)
    %disp(['SG smoothed_reconstrcuted stimuli ' num2str(freq_list(fq)) ' Hz']);
    %soundsc(smoothed,fs)
    %pause(1.5)
    
    
    disp('   ');disp('   ');disp('   ')
end