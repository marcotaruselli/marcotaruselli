function PolSaveFig

global mainPolFig

copiedAxes = findobj(mainPolFig,'type','axes');

copiedCBar = findobj(mainPolFig,'type','colorbar');
% copiedFigChil = fui.Children;

f2 = figure('toolbar','none');

for I = 1:size(copiedAxes,1)
    ax2 = copyobj([copiedAxes(I) copiedCBar(I)],f2);
    colormap(get(mainPolFig,'colormap'));
    % copyobj(copiedFigChil, f2)
    %     copyobj(copiedCBar, f2)
end


% % Get handles for all children from ax1
% ax1Chil = ax1.Children; 
% % Copy all ax1 objects to axis 2
% copyobj(ax1Chil, ax2)