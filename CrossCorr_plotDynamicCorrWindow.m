function CrossCorr_plotDynamicCorrWindow
global dataforPlotVideoCrossCorr
% if ~exist('dataforPlotVideoCrossCorr') == 1
if ~isstruct(dataforPlotVideoCrossCorr)
    % 1) Selezione dato
    [fileName,pathname] = uigetfile({'*.mat'},'Select result of Cross-Corr analysis','MultiSelect', 'off');
    result = load(fullfile(pathname, fileName));
    % close(gcf) %Altrimenti mi apre due figure. Dev'esserci un problemi in plotMovingCrossCorrWindow
    uploadedFile = result.saveSelection.dataforPlotVideoCrossCorr;
    dataforPlotVideoCrossCorr = uploadedFile
end
% make dataforPlotVideoCrossCorr Global


% dataforPlotVideoCrossCorr.uploadedFile = uploadedFile;
plotMovingCrossCorrWindow
end

function plotMovingCrossCorrWindow
%% Global variables
global dataforPlotVideoCrossCorr

%% Figure
FigPlotVideoCrossCorr = figure('WindowState','maximized')
dataforPlotVideoCrossCorr.FigPlotVideoCrossCorr = FigPlotVideoCrossCorr;


%% Gettin parameters
%%%%%% Richiamo variabili dal global dataforPlotVideoCrossCorr per plot correlogram%%%%%
t = dataforPlotVideoCrossCorr.t ;
time_corr = dataforPlotVideoCrossCorr.time_corr;
correlations = dataforPlotVideoCrossCorr.correlations;
timelength = dataforPlotVideoCrossCorr.timelength;
correlogramtitle = dataforPlotVideoCrossCorr.TITOLOCORRELOGRAMMA;
xlimitsCorr = dataforPlotVideoCrossCorr.xlimits;
%dvv
dv = dataforPlotVideoCrossCorr.dv_complete;
dvvtitle = dataforPlotVideoCrossCorr.TITOLOCORRELOGRAMMA;
dv_timeAx = dataforPlotVideoCrossCorr.dv_timeAx;
% Piezo data
timeAxPiezo = dataforPlotVideoCrossCorr.timeAxPiezo;
dataPiezo = dataforPlotVideoCrossCorr.dataPiezo;
TimezoneSurvey = dataforPlotVideoCrossCorr.TimezoneSurvey;
timeAxPiezo.TimeZone = TimezoneSurvey;
%%%%% %%%%% %%%%% %%%%% %%%%% %%%%% %%%%%

%% 1) Plot CORRELOGRAMMA
axesCorrelogramdynami = axes('Position',[0.18 0.38 0.3 0.58],'Tag','TAGaxesCorrelogramdynami');
dataforPlotVideoCrossCorr.axesCorrelogramdynami = axesCorrelogramdynami;
graficoCorrelogramma = imagesc(axesCorrelogramdynami,time_corr,1:size(correlations,2),correlations')
yticksCorrelogram = axesCorrelogramdynami.YTick;
yticklabels({timelength*yticksCorrelogram}) %Ytick in minuti
ylabel('minutes')
xlabel('maxlag [s]','Units','normalized','Position',[0.5 -0.048])
% Xlimits
axesCorrelogramdynami.XLim = xlimitsCorr;
% Title
title(correlogramtitle,'FontSize',9,'FontName','garamond')
% Colorbar
cbarCorrelogram = colorbar(axesCorrelogramdynami,'Position',[0.485 0.38 0.01 0.58]);
dataforPlotVideoCrossCorr.cbarCorrelogram = cbarCorrelogram;
grid on

%% 2) Plot Piezodata, dVV & Moving CorrWindows ==> Plottare sopra il correlogramma il rettangolo che indica la corr.window

ax_dvv = axes('Position',[0.18 0.07 0.3150 0.2],'tag','TAGax_dvv'); %asse per plot dvv curve
dataforPlotVideoCrossCorr.ax_dvv = ax_dvv;
% proprietà asse dvv (sinistro)
yyaxis(ax_dvv, 'left');
% ylabel('dV/V %','Units', 'Normalized', 'Position', [-0.08, 0.5, 0]);
ax_dvv.YAxis(1).Color = [64/255 64/255 64/255]; %Colore asse Y sinistro
% Smothing data
[dv_smooth,smoothdefaultWind] = smoothdata(dv,'movmean');
dataforPlotVideoCrossCorr.dv_smooth = dv_smooth;
% queste due righe servono solo per la sliderbar
dv_smoothSlider = smoothdata(dv,2,'movmean');
dataforPlotVideoCrossCorr.dv_smoothSlider = dv_smoothSlider;

% Plot Piezometer data
yyaxis(ax_dvv, 'right');
dvv_watertableplot = plot(ax_dvv,timeAxPiezo,dataPiezo,'b');
dataforPlotVideoCrossCorr.dvv_watertableplot = dvv_watertableplot;
yticksPiezo = linspace(ceil(min(dataPiezo)),ceil(max(dataPiezo)),10);
xlim([max(min(dv_timeAx),min(timeAxPiezo)) min(max(dv_timeAx),max(timeAxPiezo))]);
datetick('x','HH:MM')
% Prorpietà asse destro
ax_dvv.YAxis(2).Visible = 'on';
ax_dvv.YAxis(2).Color = 'b';
ax_dvv.YAxis(2).Label.String = 'Water table [m]';

% Plot dVV
for h = 1:size(t,1)
    t1 = t(h,1);
    t2 = t(h,2);
    
    %% 1) Plot dVV & dVV_Smoothed
    yyaxis(ax_dvv, 'left');
    if h > 1
        delete(dvvplot)
        delete(dvvSmoothato)
    end
    % dvv curve
    dvvplot = plot(ax_dvv,dv_timeAx,dv(h,:),'Color',[160/255 160/255 160/255],'LineStyle','-.','marker','none');
    ax_dvv.YAxis(1).Label.String = 'dV/V %';
    %     ylabel('dV/V %','Units', 'Normalized', 'Position', [-0.08, 0.5, 0]);
    ax_dvv.YAxis(1).Color = [64/255 64/255 64/255]; %Colore asse Y sinistro
    
    % dvv smoothed curve
    hold on
    dvvSmoothato = plot(ax_dvv,dv_timeAx,dv_smooth(h,:),'Color',[96/255 96/255 96/255],'LineStyle','-','marker','none')
    %     ylabel('dV/V [%]')
    % Proprietà assi
    % Asse x
    xlabel('Time')
    
    % Asse y SINISTRO
    ax_dvv.YAxis(1).Limits = [min(min(dv))-5 max(max(dv))+5] %ho fatto +5 per avere un pò di margine
    
    % Asse y DESTRO
    % Se non esistono piezometri cancella Yticklabel ==> NON DOVREBBE SUCCEDERE
    % PERCHé SE FACCIO IL VIDEO é PROPRIO PER FAR CONFRONTO CON PIEZOMETRO
    if ~isfield(dataforPlotVideoCrossCorr,'dataPiezo') % Se non ci sono piezometri (non dovrebbe succedere)
        ax_dvv.YAxis(2).Color = [64/255 64/255 64/255];
        ax_dvv.YAxis(2).TickValues = [];  %disattiva secondo asse y
        ax_dvv.YAxis(2).Visible = 'off';
    end
    
    % Titolo
    %     Attiva queste righe se vuoi il titolo come il correlogramma
    %     dvvtitle = dataforPlotVideoCrossCorr.TITOLOCORRELOGRAMMA;
    %     dvvtitle_dvvPlot = [dvvtitle '| correlogramWindow [' num2str(t1) ';' num2str(t2) ']'];
    dvvtitle_dvvPlot = [' CorrelogramWindow: [' num2str(t1) ';' num2str(t2) ']']
    set(ax_dvv.Title,'String',dvvtitle_dvvPlot,'fontsize',9,'fontname','garamond');
    grid on; grid minor
    datetickzoom
    
    % Legend
    legend( [dvvplot;dvvSmoothato;dvv_watertableplot;] , {'dV/V','dV/V Smoothed','Piezometer data'} ,'Location','southeast' );
    
    % Set xlim
    dv_timeAx.Format = 'dd-MM-yyyy HH:mm:ss';
    startime = dv_timeAx(1);
    endtime = dv_timeAx(end);
    ax_dvv.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);
    
    %% 2) Plot moving CorrWindow %%%%%%%
    XaxisLimCorrel = axesCorrelogramdynami.XLim; % Leggo i limiti in X del correlogramma
    YaxisLimCorrel = axesCorrelogramdynami.YLim; % Leggo i limiti in Y del correlogramma
    % Creo nuovo asse per rettangolo CorrWindow
    asseCorrWindow = axes('Position',[0.18 0.38 0.3 0.58],'XLim',XaxisLimCorrel,'Tag','TAGasseCorrWindow')
    % Plotto il rettangolo
    rectangle(asseCorrWindow,'Position',[t1 YaxisLimCorrel(1) abs(-t2-(-t1)) 1],'EdgeColor','r','LineWidth',2,'Tag','dynamicRectangle')
    set(asseCorrWindow,'Visible','off')
    pause(0.5)
    if h < size(t,1)
        cla(asseCorrWindow)
    end
end

%% 3) Aggiungi pulsanti modifca plot
dvvplotsettings(dv,xlimitsCorr,dv_timeAx,dataPiezo,smoothdefaultWind)
end


%% FUNZIONE Aggiunta pulsanti per modificare il plot
function dvvplotsettings(dv,xlimitsCorr,dv_timeAx,dataPiezo,smoothdefaultWind)
global dataforPlotVideoCrossCorr

spostagiu = 0.395;
uicontrol('style','text','units','normalized','position',[0.546 0.67-spostagiu .06 .03],...
    'string','Plot settings','horizontalalignment','center','fontunits','normalized','fontsize',.6,...
    'Tag','settings_dvv');

%% correlogramPlotVideo  plot settings
% correlogramPlotVideo Xlimits
uicontrol('style','text','units','normalized','position',[.55 .63-spostagiu .05 .03],...
    'string','Corr Xlim','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','xlimits_correlogram_text');
uicontrol('style','edit','units','normalized','position',[.60 .63-spostagiu .08 .03],'tag','xlimits_correlogram',...
    'backgroundcolor',[1 1 1],'String',[num2str(xlimitsCorr(1)) ',' num2str(xlimitsCorr(2))],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring','Limits of correlogram xaxis. es. -2,2','Callback',@(numfld,event) updateChanges);

% Colorbar limits
uicontrol('style','text','units','normalized','position',[.685 .63-spostagiu .04 .03],...
    'string','Corr Cbar','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','caxis_correlogram_text');
uicontrol('style','edit','units','normalized','position',[.725 .63-spostagiu .04 .03],'tag','caxis_correlogram',...
    'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'String','auto','tooltipstring',['correlogramPlotVideo colorbar limits. es. -2,2' 10 'If "auto" the colorbar will be automatically set'],...
    'Callback',@(numfld,event) updateChanges);

%% dVV Plot settings
% Xlimits
uicontrol('style','text','units','normalized','position',[.55 .59-spostagiu .05 .03],...
    'string','Xlimits','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','dVV_Xlimits');
uicontrol('style','edit','units','normalized','position',[.60 .59-spostagiu .08 .03],'backgroundcolor',[1 1 1],...
    'String',[datestr(dv_timeAx(1))],'horizontalalignment','center','fontunits','normalized',...
    'fontsize',.5,'tooltipstring','Start time limit','Tag','dVV_Xlimits_left','Callback',@(numfld,event) updateChanges);
uicontrol('style','edit','units','normalized','position',[.685 .59-spostagiu .08 .03],'backgroundcolor',[1 1 1],...
    'String',[datestr(dv_timeAx(end))],'horizontalalignment','center','fontunits','normalized',...
    'fontsize',.5,'tooltipstring','End time limit','Tag','dVV_Xlimits_right','Callback',@(numfld,event) updateChanges);

% dVV Ylimits
uicontrol('style','text','units','normalized','position',[.55 .55-spostagiu .05 .03],...
    'string','dV/V Ylimits','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','dVV_Ylimits');
uicontrol('style','edit','units','normalized','position',[.60 .55-spostagiu .08 .03],'backgroundcolor',[1 1 1],...
    'horizontalalignment','center','String',[num2str(min(min(dv))-5) ',' num2str(max(max(dv))+5)],'fontunits','normalized','fontsize',.5,'tooltipstring',...
    'Limits of dV/V yaxis. es. -2,2','Tag','dVV_Ylimits_Value','Callback',@(numfld,event) updateChanges);


% Groundwater Ylimits
uicontrol('style','text','units','normalized','position',[.55 .51-spostagiu .05 .03],...
    'string','Water Ylimits','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','water_Ylimits');
ax_dvv = dataforPlotVideoCrossCorr.ax_dvv; %Richiamo asse dvv Plot
YlimitsPiezoData = ax_dvv.YAxis(2).Limits;
uicontrol('style','edit','units','normalized','position',[.60 .51-spostagiu .08 .03],'backgroundcolor',[1 1 1],...
    'horizontalalignment','center','fontunits','normalized','fontsize',.5,'String',[num2str(YlimitsPiezoData(1)) ',' num2str(YlimitsPiezoData(2))],...
    'tooltipstring','Limits of water table Yaxis. es. -2,2','Tag','water_Ylimits_Value','Callback',@(numfld,event) updateChanges);


% dVV Color
uicontrol('style','pushbutton','units','normalized','position',[.685 .55-spostagiu .08 .03],...
    'string','dV/V Color','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'callback',@(btn,event) dvv_color(btn),'Tag','dvv_color','Enable','off')

% Water table Color
uicontrol('style','pushbutton','units','normalized','position',[.685 .51-spostagiu .08 .03],...
    'string','Water Color','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'callback',@(btn,event) watertable_color(btn),'Tag','watertable_color','Enable','off')


% % Save video button
% uicontrol('style','pushbutton','units','normalized','position',[.685 .43-spostagiu .04 .03],...
%     'string','Save video','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
%     'backgroundcolor',[.7 .7 .7],'callback',@(btn,event) saveVideo(btn),'Tag','saveVideo')

% Plot video button
uicontrol('style','pushbutton','units','normalized','position',[.7256 .43-spostagiu .04 .03],...
    'string','Plot video','horizontalalignment','left','fontunits','normalized','fontsize',.5,'FontWeight','bold',...
    'backgroundcolor',[.7 .7 .7],'callback',@(btn,event) plotvideo(btn),'Tag','plotvideo')

%% Slider bar
uicontrol('style','text','units','normalized','position',[.55 .43-spostagiu .05 .03],...
    'string','Win. Corr','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Tag','DynamicWinCorr_text',...
    'backgroundcolor',[.8 .8 .8]);

% Slidebar
NdynamicWinCorr = size(dataforPlotVideoCrossCorr.t,1); %numero finestre che si muovono nel correlogramma
stepSz = [1,NdynamicWinCorr];
uicontrol('style','slider','units','normalized','position',[.60 .43-spostagiu .08 .03],...
    'Min',1,'Max',NdynamicWinCorr,'SliderStep',stepSz/(NdynamicWinCorr-1),'Value',NdynamicWinCorr,'Tag','dynamicWinCorrSlider',...
    'callback',@(btn,event) sliderPlot(btn));

% Selected WinCorr in the slidebar
% t = dataforPlotVideoCrossCorr.t;
% LastdynamicWinCorr = t(end,:);
% uicontrol('Style','edit','Enable','off','units','normalized','Position',[0.685 .43-spostagiu 0.0356 .03],...
%     'horizontalalignment','center','fontunits','normalized','fontsize',.5,'tag','dynamicWinCorrSliderEDIT');

%% dVV Smoothing settings
spostagiu = spostagiu+0.04;
% Creo tasti
% uicontrol('style','text','units','normalized','position',[0.762 0.62 .12 .03],...
%     'string','Smoothing dVV','horizontalalignment','center','fontunits','normalized','fontsize',.6,...
%     'Tag','settings_dvv');
Smoothing_text = uicontrol('style','text','units','normalized','position',[.55 .47-spostagiu+0.04 .05 .03],...
    'string','Smooth type','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Tag','Smoothing_text',...
    'backgroundcolor',[.8 .8 .8]);
Smoothing_listbox = uicontrol('style','popupmenu','units','normalized','position',[.60 .467-spostagiu+0.04 .08 .033],'tag','Smoothing_type',...
    'horizontalalignment','right','fontunits','normalized','fontsize',.5,...
    'string',{'Movmean','Movmedian','Gaussian','Lowess','Loess','Rlowess','Rloess','Sgolay'},'Callback',@(numfld,event) updateChanges);
Smoothing_edit = uicontrol('style','edit','units','normalized','position',[.685 .47-spostagiu+0.04 .08 .03],...
    'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Tag','Smoothing_window',...
    'backgroundcolor','w','String',num2str(smoothdefaultWind),'TooltipString','It specifies the length of the window used by the smoothing method',...
    'Callback',@(numfld,event) updateChanges);

end

%% Slider update plot
function sliderPlot(btn)
global dataforPlotVideoCrossCorr
FigPlotVideoCrossCorr = dataforPlotVideoCrossCorr.FigPlotVideoCrossCorr; %Richiamo la figura
SliderselectedWinCorr = get(findobj(FigPlotVideoCrossCorr,'tag','dynamicWinCorrSlider'),'value');

ax_dvv = dataforPlotVideoCrossCorr.ax_dvv; %Richiamo asse dvv Plot
lineePlottate = get(ax_dvv, 'Children');
delete(lineePlottate);

% dvv plot
dv_timeAx = dataforPlotVideoCrossCorr.dv_timeAx;
dv_timeAx = dataforPlotVideoCrossCorr.dv_timeAx;
dv = dataforPlotVideoCrossCorr.dv_complete;
dvvplot = plot(ax_dvv,dv_timeAx,dv(SliderselectedWinCorr,:),'Color',[160/255 160/255 160/255],'LineStyle','-.','marker','none');
% dvv smoothed plot
hold on
dv_smoothSlider = dataforPlotVideoCrossCorr.dv_smoothSlider;
dvvSmoothato = plot(ax_dvv,dv_timeAx,dv_smoothSlider(SliderselectedWinCorr,:),'Color',[96/255 96/255 96/255],'LineStyle','-','marker','none')

% Tile
t = dataforPlotVideoCrossCorr.t;
t1 = t(SliderselectedWinCorr,1);
t2 = t(SliderselectedWinCorr,2);
dvvtitle_dvvPlot = [' CorrelogramWindow: [' num2str(t1) ';' num2str(t2) ']']
set(ax_dvv.Title,'String',dvvtitle_dvvPlot,'fontsize',9,'fontname','garamond');

legend(ax_dvv,'dV/V','dV/V Smoothed','Piezometer data','Location','southeast');
%     legend( [dvvplot;dvvSmoothato;dvv_watertableplot;] , {'dV/V','dV/V Smoothed','Piezometer data'} ,'Location','southeast' );

% Update Correlogram X-limits
% axesCorrelogramdynami = dataforPlotVideoCrossCorr.axesCorrelogramdynami; %Richiamo asse
% axesCorrelogramdynami.XLim = t(SliderselectedWinCorr,:);

% Rettangolo rosso
% Elimina il rettangolo rosso
dynamicRectangle = findobj(FigPlotVideoCrossCorr,'tag','dynamicRectangle');
delete(dynamicRectangle);
SliderselectedWinCorr = get(findobj(FigPlotVideoCrossCorr,'tag','dynamicWinCorrSlider'),'value');
t = dataforPlotVideoCrossCorr.t;
t1 = t(SliderselectedWinCorr,1);
t2 = t(SliderselectedWinCorr,2);
axesCorrelogramdynami = dataforPlotVideoCrossCorr.axesCorrelogramdynami;
XaxisLimCorrel = axesCorrelogramdynami.XLim; % Leggo i limiti in X del correlogramma
YaxisLimCorrel = axesCorrelogramdynami.YLim; % Leggo i limiti in Y del correlogramma
% Creo nuovo asse per rettangolo CorrWindow
asseCorrWindow = axes('Position',[0.18 0.38 0.3 0.58],'XLim',XaxisLimCorrel,'Tag','TAGasseCorrWindow')
% Plotto il rettangolo
rectangle(asseCorrWindow,'Position',[t1 YaxisLimCorrel(1) abs(-t2-(-t1)) 1],'EdgeColor','r','LineWidth',2,'Tag','dynamicRectangle')
set(asseCorrWindow,'Visible','off')
end

%% Update graph
function updateChanges
global dataforPlotVideoCrossCorr
FigPlotVideoCrossCorr = dataforPlotVideoCrossCorr.FigPlotVideoCrossCorr; %Richiamo la figura
SliderselectedWinCorr = get(findobj(FigPlotVideoCrossCorr,'tag','dynamicWinCorrSlider'),'value');

%% Update correlogram
% Correlogram X-limits
axesCorrelogramdynami = dataforPlotVideoCrossCorr.axesCorrelogramdynami; %Richiamo asse
newCorrXlim = get(findobj(FigPlotVideoCrossCorr,'tag','xlimits_correlogram'),'string');
axesCorrelogramdynami.XLim = str2num(newCorrXlim);

% Correlogram colorbar Limits
cbarCorrelogram = dataforPlotVideoCrossCorr.cbarCorrelogram;
newCorrColorBar = get(findobj(FigPlotVideoCrossCorr,'tag','caxis_correlogram'),'string');
if ~strcmp(newCorrColorBar,'auto')
    axesCorrelogramdynami.CLim = str2num(newCorrColorBar);
    cbarCorrelogram.Limits = str2num(newCorrColorBar);
end

%% Update dvv Plot
ax_dvv = dataforPlotVideoCrossCorr.ax_dvv; %Richiamo asse dvv Plot

% Update X lim dVV_Xlimits_right
startime = datetime(get(findobj(FigPlotVideoCrossCorr,'tag','dVV_Xlimits_left'),'String'));
endtime = datetime(get(findobj(FigPlotVideoCrossCorr,'tag','dVV_Xlimits_right'),'String'));
if size(startime,1) ~= 1
    startime = startime(1,1);
    endtime = endtime(1,1);
end
TimezoneSurvey = dataforPlotVideoCrossCorr.TimezoneSurvey;
ax_dvv.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);

% Update Y lim dVV
new_dVVYlimits = get(findobj(FigPlotVideoCrossCorr,'tag','dVV_Ylimits_Value'),'String');
ax_dvv.YLim = str2num(new_dVVYlimits);

% Update Y lim Piezo
new_PiezoYlimits = get(findobj(FigPlotVideoCrossCorr,'tag','water_Ylimits_Value'),'String');
ax_dvv.YAxis(2).Limits = str2num(new_PiezoYlimits);

% Smoothing dV/V curve
dvv_smoothingType = findobj(FigPlotVideoCrossCorr,'tag','Smoothing_type');
dvv_smoothingType = dvv_smoothingType.String(dvv_smoothingType.Value);
dvv_smoothingWindow = findobj(FigPlotVideoCrossCorr,'tag','Smoothing_window');
dvv_smoothingWindow = str2num(dvv_smoothingWindow.String);
lineePlottate = get(ax_dvv, 'Children');
dvvSmoothato = lineePlottate(1);
dvvplot = lineePlottate(2);
delete(dvvSmoothato)
dv = dataforPlotVideoCrossCorr.dv_complete;
dv_timeAx = dataforPlotVideoCrossCorr.dv_timeAx;
dv_smooth = smoothdata(dv,2,dvv_smoothingType{1,1},dvv_smoothingWindow); %% ATTENZIONE AGGIORNO SOLO L'ultimo dvv
% queste due righe servono solo per la sliderbar
dv_smoothSlider = smoothdata(dv,2,dvv_smoothingType{1,1},dvv_smoothingWindow); %% ATTENZIONE AGGIORNO SOLO L'ultimo dvv
dataforPlotVideoCrossCorr.dv_smoothSlider = dv_smoothSlider;
yyaxis(ax_dvv,'left')
hold on
% % % SliderselectedWinCorr = get(findobj(FigPlotVideoCrossCorr,'tag','dynamicWinCorrSlider'),'value');
dvvSmoothato = plot(ax_dvv,dv_timeAx,dv_smooth(SliderselectedWinCorr,:),'Color',[96/255 96/255 96/255],'LineStyle','-','marker','none');
ax_dvv.YLim = str2num(new_dVVYlimits);
ax_dvv.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);
dvv_watertableplot = dataforPlotVideoCrossCorr.dvv_watertableplot;
legend([dvvplot;dvvSmoothato;dvv_watertableplot;] , {'dV/V','dV/V Smoothed','Piezometer data'} ,'Location','southeast' );

% Rettangolo rosso
% Elimina il rettangolo rosso
dynamicRectangle = findobj(FigPlotVideoCrossCorr,'tag','dynamicRectangle');
delete(dynamicRectangle);
SliderselectedWinCorr = get(findobj(FigPlotVideoCrossCorr,'tag','dynamicWinCorrSlider'),'value');
t = dataforPlotVideoCrossCorr.t;
t1 = t(SliderselectedWinCorr,1);
t2 = t(SliderselectedWinCorr,2);
axesCorrelogramdynami = dataforPlotVideoCrossCorr.axesCorrelogramdynami;
XaxisLimCorrel = axesCorrelogramdynami.XLim; % Leggo i limiti in X del correlogramma
YaxisLimCorrel = axesCorrelogramdynami.YLim; % Leggo i limiti in Y del correlogramma
% Creo nuovo asse per rettangolo CorrWindow
asseCorrWindow = axes('Position',[0.18 0.38 0.3 0.58],'XLim',XaxisLimCorrel,'Tag','TAGasseCorrWindow')
% Plotto il rettangolo
rectangle(asseCorrWindow,'Position',[t1 YaxisLimCorrel(1) abs(-t2-(-t1)) 1],'EdgeColor','r','LineWidth',2,'Tag','dynamicRectangle')
set(asseCorrWindow,'Visible','off')
end

%% Plot video
function plotvideo(btn)
global dataforPlotVideoCrossCorr
FigPlotVideoCrossCorr = dataforPlotVideoCrossCorr.FigPlotVideoCrossCorr; %Richiamo la figura
delete(findobj(FigPlotVideoCrossCorr,'type','axes'))



%% Gettin parameters
%%%%%% Richiamo variabili dal global dataforPlotVideoCrossCorr per plot correlogram%%%%%
t = dataforPlotVideoCrossCorr.t ;
time_corr = dataforPlotVideoCrossCorr.time_corr;
correlations = dataforPlotVideoCrossCorr.correlations;
timelength = dataforPlotVideoCrossCorr.timelength;
correlogramtitle = dataforPlotVideoCrossCorr.TITOLOCORRELOGRAMMA;
xlimitsCorr = dataforPlotVideoCrossCorr.xlimits;
%dvv
dv = dataforPlotVideoCrossCorr.dv_complete;
dvvtitle = dataforPlotVideoCrossCorr.dvvtitle;
dv_timeAx = dataforPlotVideoCrossCorr.dv_timeAx;
% Piezo data
timeAxPiezo = dataforPlotVideoCrossCorr.timeAxPiezo;
dataPiezo = dataforPlotVideoCrossCorr.dataPiezo;
TimezoneSurvey = dataforPlotVideoCrossCorr.TimezoneSurvey;
timeAxPiezo.TimeZone = TimezoneSurvey;
%%%%% %%%%% %%%%% %%%%% %%%%% %%%%% %%%%%

%% 1) Plot CORRELOGRAMMA
axesCorrelogramdynami = axes('Position',[0.18 0.38 0.3 0.58],'Tag','TAGaxesCorrelogramdynami');
dataforPlotVideoCrossCorr.axesCorrelogramdynami = axesCorrelogramdynami;
imagesc(axesCorrelogramdynami,time_corr,1:size(correlations,2),correlations');
set(gca,'Tag','TAGaxesCorrelogramdynami');
yticksCorrelogram = axesCorrelogramdynami.YTick;
yticklabels({timelength*yticksCorrelogram}); %Ytick in minuti
ylabel('minutes');
xlabel('maxlag [s]','Units','normalized','Position',[0.5 -0.048]);
% Xlimits
newCorrXlim = get(findobj(FigPlotVideoCrossCorr,'tag','xlimits_correlogram'),'string');
axesCorrelogramdynami.XLim = str2num(newCorrXlim);

% Title
title(correlogramtitle,'FontSize',9,'fontname','garamond')
% Colorbar
cbarCorrelogram = colorbar(axesCorrelogramdynami,'Position',[0.485 0.38 0.01 0.58]);
newCorrColorBar = get(findobj(FigPlotVideoCrossCorr,'tag','caxis_correlogram'),'string');
if ~strcmp(newCorrColorBar,'auto')
    axesCorrelogramdynami.CLim = str2num(newCorrColorBar);
    cbarCorrelogram.Limits = str2num(newCorrColorBar);
end
dataforPlotVideoCrossCorr.cbarCorrelogram = cbarCorrelogram;
grid on

%% 2) Plot Piezodata, dVV & Moving CorrWindows ==> Plottare sopra il correlogramma il rettangolo che indica la corr.window
ax_dvv = axes('Position',[0.18 0.07 0.3150 0.2],'tag','TAGax_dvv'); %asse per plot dvv curve
dataforPlotVideoCrossCorr.ax_dvv = ax_dvv;
% proprietà asse dvv (sinistro)
yyaxis(ax_dvv, 'left');
ylabel('dV/V %','Units', 'Normalized', 'Position', [-0.08, 0.5, 0]);
ax_dvv.YAxis(1).Color = [64/255 64/255 64/255]; %Colore asse Y sinistro
% Smoothing dV/V curve
% clear('dvv_smoothingType','dvv_smoothingWindow','dv_smooth');
% dvv_smoothingType = findobj(FigPlotVideoCrossCorr,'tag','Smoothing_type');
% dvv_smoothingType = dvv_smoothingType.String(dvv_smoothingType.Value);
% dvv_smoothingWindow = findobj(FigPlotVideoCrossCorr,'tag','Smoothing_window');
% dvv_smoothingWindow = str2num(dvv_smoothingWindow.String);
% dv_smooth = smoothdata(dv,dvv_smoothingType{1,1},dvv_smoothingWindow); %% ATTENZIONE AGGIORNO SOLO L'ultimo dvv
dvv_smoothingType = findobj(FigPlotVideoCrossCorr,'tag','Smoothing_type');
dvv_smoothingType = dvv_smoothingType.String(dvv_smoothingType.Value);
dvv_smoothingWindow = findobj(FigPlotVideoCrossCorr,'tag','Smoothing_window');
dvv_smoothingWindow = str2num(dvv_smoothingWindow.String);
ax_dvv = findobj(FigPlotVideoCrossCorr,'type','axes','tag','TAGax_dvv')
lineePlottate = get(ax_dvv, 'Children');
delete(lineePlottate)
dv = dataforPlotVideoCrossCorr.dv_complete;
dv_timeAx = dataforPlotVideoCrossCorr.dv_timeAx;

% Plot Piezometer data
yyaxis(ax_dvv, 'right');
dvv_watertableplot = plot(ax_dvv,timeAxPiezo,dataPiezo,'b');
dataforPlotVideoCrossCorr.dvv_watertableplot = dvv_watertableplot;
yticksPiezo = linspace(ceil(min(dataPiezo)),ceil(max(dataPiezo)),10);
xlim([max(min(dv_timeAx),min(timeAxPiezo)) min(max(dv_timeAx),max(timeAxPiezo))]);
datetick('x','HH:MM')

% Prorpietà asse destro
yyaxis(ax_dvv, 'right');
ax_dvv.YAxis(2).Visible = 'on';
ax_dvv.YAxis(2).Color = 'b';
ax_dvv.YAxis(2).Label.String = 'Water table [m]';

% Plot dVV
for h = 1:size(t,1)
    t1 = t(h,1);
    t2 = t(h,2);
    %% 1) Plot dVV & dVV_Smoothed
    yyaxis(ax_dvv, 'left');
    set(ax_dvv,'xminorgrid','on','yminorgrid','on')
    set(ax_dvv,'xgrid','on','ygrid','on')
    
    if h > 1
        delete(dvvplot);
        delete(dvvSmoothato);
        clear dvvplot;
        clear dvvSmoothato;
    end
    % dvv curve
    dvvplot = plot(ax_dvv,dv_timeAx,dv(h,:),'Color',[160/255 160/255 160/255],'LineStyle','-.','marker','none');
    ax_dvv.YAxis(1).Label.String = 'dV/V %';
    %     ylabel('dV/V %','Units', 'Normalized', 'Position', [-0.08, 0.5, 0]);
    % dvv smoothed curve
    %     yyaxis(ax_dvv, 'left');
    hold on
    dv_smooth = smoothdata(dv(h,:),dvv_smoothingType{1,1},dvv_smoothingWindow); %% ATTENZIONE AGGIORNO SOLO L'ultimo dvv
    dvvSmoothato = plot(dv_timeAx,dv_smooth,'Color',[96/255 96/255 96/255],'LineStyle','-','marker','none');
    %     grid(ax_dvv,'on')
    %     grid(ax_dvv,'minor')
    % Proprietà assi
    % Asse x
    xlabel('Time');
    
    % Asse y SINISTRO
    new_dVVYlimits = get(findobj(FigPlotVideoCrossCorr,'tag','dVV_Ylimits_Value'),'String');
    ax_dvv.YLim = str2num(new_dVVYlimits);
    yyaxis(ax_dvv, 'left');
    
    % Asse y DESTRO
    %     ax_dvv.YAxis(2).Color = [64/255 64/255 64/255];
    %     ax_dvv.YAxis(2).TickValues = [];  %disattiva secondo asse y
    %     ax_dvv.YAxis(2).Visible = 'off';
    new_PiezoYlimits = get(findobj(FigPlotVideoCrossCorr,'tag','water_Ylimits_Value'),'String');
    ax_dvv.YAxis(2).Limits = str2num(new_PiezoYlimits);
    
    % Titolo
    %     Attiva queste righe se vuoi il titolo come il correlogramma
    %     dvvtitle = dataforPlotVideoCrossCorr.TITOLOCORRELOGRAMMA;
    %     dvvtitle_dvvPlot = [dvvtitle '| correlogramWindow [' num2str(t1) ';' num2str(t2) ']'];
    dvvtitle_dvvPlot = [' CorrelogramWindow: [' num2str(t1) ';' num2str(t2) ']']
    set(ax_dvv.Title,'String',dvvtitle_dvvPlot,'fontsize',9,'fontname','garamond');
    datetickzoom;
    
    % Legend
    legend([dvvplot;dvvSmoothato;dvv_watertableplot;] , {'dV/V','dV/V Smoothed','Piezometer data'} ,'Location','southeast' );
    
    % Set xlim
    startime = datetime(get(findobj(FigPlotVideoCrossCorr,'tag','dVV_Xlimits_left'),'String'));
    endtime = datetime(get(findobj(FigPlotVideoCrossCorr,'tag','dVV_Xlimits_right'),'String'));
    if size(startime,1) ~= 1
        startime = startime(1,1);
        endtime = endtime(1,1);
    end
    TimezoneSurvey = dataforPlotVideoCrossCorr.TimezoneSurvey;
    ax_dvv.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);
    
    %% 2) Plot moving CorrWindow %%%%%%%
    XaxisLimCorrel = axesCorrelogramdynami.XLim; % Leggo i limiti in X del correlogramma
    YaxisLimCorrel = axesCorrelogramdynami.YLim; % Leggo i limiti in Y del correlogramma
    % Creo nuovo asse per rettangolo CorrWindow
    asseCorrWindow = axes('Position',[0.18 0.38 0.3 0.58],'XLim',XaxisLimCorrel,'Tag','TAGasseCorrWindow');
    % Plotto il rettangolo
    rectangle(asseCorrWindow,'Position',[t1 YaxisLimCorrel(1) abs(-t2-(-t1)) 1],'EdgeColor','r','LineWidth',2,'Tag','dynamicRectangle')
    set(asseCorrWindow,'Visible','off');
    pause(0.5);
    if h < size(t,1)
        delete(asseCorrWindow);
    end
end
end