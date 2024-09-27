function CrossCorr_CorrelogramSaveFig

GUI_fig_children=get(gcf,'children');
Fig_Axes=findobj(GUI_fig_children,'type','Axes');
Fig_Axes = findobj(Fig_Axes,'Tag','Correlogram')
fig=figure;
ax=axes;clf;
new_handle=copyobj(Fig_Axes,fig);
set(gca,'ActivePositionProperty','outerposition')
set(gca,'Units','normalized')
set(gca,'OuterPosition',[0 0 1 1])
set(gca,'position',[0.1300 0.1100 0.7750 0.8150])
