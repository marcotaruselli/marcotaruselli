function CrossCorr_dVVSaveFig
figure
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
global crosscorr
global mainCrossFig
global data_selected


%% Plot title
dv = crosscorr.dv;
dvvtitle = crosscorr.dvvtitle;
dvv_corrwindowValue =  get(findobj(mainCrossFig,'tag','dvv_corrwindowValue'),'String');
dvvtitle = [dvvtitle ' correlogramWindow ' dvv_corrwindowValue];

%% Resampling asse temporale per plot
timevector = data_selected(1).timeAx;
startTime = timevector(1);
endTime = timevector(end);
timeAx = linspace(startTime,endTime,length(dv));

% Conversione timeAx to UTC time
TimezoneSurvey = get(findobj(mainCrossFig,'tag','Timezone'),'String');
timeAx = datetime(timeAx,'ConvertFrom','datenum');
timeAx = datetime(timeAx,'TimeZone','UTC');
timeAx.TimeZone = TimezoneSurvey;
timeAx.Format = 'dd/MM/yyyy HH:mm:ss';
crosscorr.timeAx = timeAx;

%% Plot dV/V senza Smoothing
ax_dvv = axes;
yyaxis(ax_dvv, 'left');
dvplot = plot(ax_dvv,timeAx,dv,'Color',[160/255 160/255 160/255],'LineStyle','-.','Tag','line_dV_Plot');
set(gca,'Tag','dvvPlot')
% Proprietà asse Y sinistro
ylabel('dV/V %','Units', 'Normalized', 'Position', [-0.025, 0.5, 0]);
ax_dvv.YAxis(1).Color = [64/255 64/255 64/255]; %Colore asse Y sinistro



% Proprietà asse Y destro
% Se non esistono piezometri cancella Yticklabel
choicePiezo = get(findobj(mainCrossFig,'tag','piezo_plotcheck'),'Value');
if choicePiezo == 0
    ax_dvv.YAxis(2).Color = [64/255 64/255 64/255];
    ax_dvv.YAxis(2).TickValues = [];  %disattiva secondo asse y
end
crosscorr.ylim_groundwater = ax_dvv.YAxis(2).Limits;
% ax_dvv.YAxis(2).Visible = 'off';

% Proprietà asse X
xlabel('Time')
title(dvvtitle)
grid on; grid minor
legend('dV/V','Location','southeast')
datetickzoom
% dragzoom();

%% Plot dV/V con Smoothing
% dvv_smoothingValue = get(findobj(mainCrossFig,'tag','dvv_smoothingValue'),'Value');
% if dvv_smoothingValue == 1
%     [dv_smooth,smoothdefaultWind] = smoothdata(dv,'movmean');
%     hold on
%     dvsmoothplot = plot(ax_dvv,timeAx,dv_smooth,'Color',[96/255 96/255 96/255],'LineStyle','-','Tag','line_dVSmoothed_Plot')
%     legend('dV/V','dV/V Smoothed','Location','southeast')
% end

%% Plot Piezo data if selected
if choicePiezo == 1
    timeAxPiezo = evalin('base', 'timeAxPiezo');
    dataPiezo = evalin('base', 'dataPiezo');
    timeAxPiezo.TimeZone = TimezoneSurvey;
    yyaxis(ax_dvv, 'right');
    dv_watertableplot = plot(timeAxPiezo,dataPiezo,'b');
    crosscorr.dv_watertableplot = dv_watertableplot;
    yticksPiezo = linspace(ceil(min(dataPiezo)),ceil(max(dataPiezo)),10);
    crosscorr.ylimPiezo = yticks;
    xlim([max(min(timeAx),min(timeAxPiezo)) min(max(timeAx),max(timeAxPiezo))]);
    datetick('x','HH:MM')
    % Prorpietà asse destro
    ax_dvv.YAxis(2).Color = 'b';
    ylabel('Water table [m]','Units', 'Normalized', 'Position', [1.04 0.5, 0]);
    legend('dV/V','dV/V Smoothed','Piezometer data','Location','southeast')
end

% Set xlim
timeAx.Format = 'dd-MM-yyyy HH:mm:ss';
startime = timeAx(1);
endtime = timeAx(end);
dvvfigure = findobj(gcf,'tag','dvvPlot');
TimezoneSurvey = get(findobj(mainCrossFig,'tag','Timezone'),'String');
dvvfigure.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);


%% Update da Plot settings
% Update X lim
startime = datetime(get(findobj(mainCrossFig,'tag','dVV_Xlimits_left'),'String'));
endtime = datetime(get(findobj(mainCrossFig,'tag','dVV_Xlimits_right'),'String'));
if size(startime,1) ~= 1
    startime = startime(1,1);
    endtime = endtime(1,1);
end
TimezoneSurvey = get(findobj(mainCrossFig,'tag','Timezone'),'String');
dvvfigure.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);

% Update asse Y dV/V
dvvYlimits = get(findobj(mainCrossFig,'tag','dVV_Ylimits_Value'),'String');
if size(dvvYlimits,1) ~= 1 %ho dovuto inserire questo ciclo if perchè altrimenti quando faccio "reset" non funzionerebbe il tasto "update"
    dvvYlimits = str2num(dvvYlimits{1,:});
else
    dvvYlimits = str2num(dvvYlimits);
end
if ~isempty(dvvYlimits)
    dvvfigure.YAxis(1).Limits = dvvYlimits;
end

% Update asse Y water table
choicePiezo = get(findobj(mainCrossFig,'tag','piezo_plotcheck'),'Value');
if choicePiezo == 1
    watertableYlimits = get(findobj(mainCrossFig,'tag','water_Ylimits_Value'),'String');
    if size(watertableYlimits,1) ~= 1
        watertableYlimits = str2num(watertableYlimits{1,:});
    else
        watertableYlimits = str2num(watertableYlimits);
    end
end
if exist('watertableYlimits') ==1
    if ~isempty(watertableYlimits)
        dvvfigure.YAxis(2).Limits = watertableYlimits;
    end
end

% Smoothing dV/V curve
dvv_smoothingValue = get(findobj(mainCrossFig,'tag','dvv_smoothingValue'),'Value');
dvv_smoothingType = findobj(mainCrossFig,'tag','Smoothing_type');
dvv_smoothingType = dvv_smoothingType.String(dvv_smoothingType.Value);
dvv_smoothingWindow = str2num(get(findobj(mainCrossFig,'tag','Smoothing_window'),'string'));
dvvplotHandle = crosscorr.ax_dvv;
dvvLines = findobj(dvvplotHandle, 'Type', 'line');

    dv = crosscorr.dv;
    timeAx = crosscorr.timeAx;
    dv_smooth = smoothdata(dv,dvv_smoothingType{1,1},dvv_smoothingWindow);
    hold on
    yyaxis left
    dvsmoothplot = plot(timeAx,dv_smooth,'Color',[96/255 96/255 96/255],'LineStyle','-','marker','none','tag','line_dVSmoothed_Plot');
    
    choicePiezo = get(findobj(mainCrossFig,'tag','piezo_plotcheck'),'Value');
    if choicePiezo == 0
        legend('dV/V','dV/V Smoothed','Location','southeast');
    end
    if choicePiezo == 1
        legend('dV/V','dV/V Smoothed','Piezometer data','Location','southeast');
    end
