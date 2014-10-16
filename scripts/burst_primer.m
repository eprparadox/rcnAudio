% helper function, takes a wave a returns burst centers and edges in
% indicies
function [burst_centers burst_edges nbursts] = burst_primer(wave)
    
    burst_edges = [];
    for i = 11:length(wave) - 11
        if wave(i) ~= 0 && sum(wave(i-10:i-1)) == 0
            burst_edges(end+1) = i;
        elseif wave(i) ~= 0 && sum(wave(i+1:i+10)) == 0
            burst_edges(end+1) = i;
        end
    end
    
    % get leading and lagging edges
    ldedges = burst_edges(1:2:end);
    lgedges = burst_edges(2:2:end);
    
    % get length 
    burst_dur = lgedges(1) - ldedges(1);
    burst_centers = ldedges + burst_dur / 2;
    nbursts = length(burst_centers);
end
