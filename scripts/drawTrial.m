function [] = drawTrial(silent,stim,acquire)
%%% this function will draw what an example trial will look like in the
%%% rcnAudio paradigm

%%% set up trial vec
vec = [ones(1,silent) ones(1,stim)*9 ones(1,acquire)*9];


%%% draw
figure
imagesc(vec)

%%% assign colormap (below from stack overflow
cmap = jet(3);
hold on 
L = line(ones(3),ones(3), 'LineWidth',2);               % generate line
set(L,{'color'},mat2cell(cmap,ones(1,3),3));            % set the colors according to cmap
legend('silent','stim','acquire','Location','NorthEastOutside')
legend boxoff

xlabel('TR','FontSize',20)
ylabel('')

