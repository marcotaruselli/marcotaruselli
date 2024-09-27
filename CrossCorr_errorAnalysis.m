function CrossCorr_errorAnalysis

% Questa funzione serve per stimare l'errore nel calcolo del coefficente di
% dilatazione epsilon. La funzione è in CrossCorr_dVVCompute, in fondo alla
% sottofunzione dvvComputation

global crosscorr
global mainCrossFig


% Add error analysis
Compute_ErrorButton = uicontrol(mainCrossFig,'style','pushbutton','units','normalized','position',[0.548 0.45 .07 .03],...
    'string','Add Error Analysis','horizontalalignment','center','fontunits','normalized','fontsize',.5,'FontWeight','bold',...
    'backgroundcolor',[.7 .7 .7],'Tag','Add_ErrorAnalysis_dvv','Tooltip',...
    'This analysis is based on the Weaver formula (2011). Read the paper for more details',...
    'Callback',@(numfld,event) Add_ErrorAnalysis);%,'callback',@(btn,event) resetcorrelogram(btn),'Tag','reset_correlogram')

end

function Add_ErrorAnalysis
global crosscorr
global mainCrossFig
set(findobj(mainCrossFig,'tag','Add_ErrorAnalysis_dvv'),'enable','off')

h = zoom %in fondo alla funzione disattivo zoom su assi non zoommabili

% Creo assi per poi fare i plot
CrossCorrREF_Signalaxis = axes(mainCrossFig,'Units','normalized','Position',[0.55 0.3 0.42 0.12],'Tag','CrossCorrREF_Signalaxis');
zoom(CrossCorrREF_Signalaxis,'on')
crosscorr.CrossCorrREF_Signalaxis = CrossCorrREF_Signalaxis;
% CrossCorrREF_Signalaxis = mainCrossFig.CrossCorrREF_Signalaxis;
CrossCorrREF_Spectrumaxis = axes(mainCrossFig,'Units','normalized','Position',[0.55 0.11 0.42 0.12],'Tag','CrossCorrREF_Spectrumaxis');
zoom(CrossCorrREF_Spectrumaxis,'on')
crosscorr.CrossCorrREF_Spectrumaxis = CrossCorrREF_Spectrumaxis;

%% Getting parameters
global crosscorr
time_corr = crosscorr.time_corr;
dvv_corrwindowValue =  get(findobj(mainCrossFig,'tag','dvv_corrwindowValue'),'String');

if strcmp(dvv_corrwindowValue,'auto') == 1
    t1 = time_corr(1);
    t2 = time_corr(end);
    t = [time_corr(1) time_corr(end)];
    
    % case 2: ==> Dynamic
elseif strcmp(dvv_corrwindowValue,'dynamic') == 1
    beep
    sms=msgbox(['The error analysis for ''' 'dynamic' ''' choice of time-corr window is not available yet!'],'Update','error');
    pause(1)
    close(sms)
    delete(CrossCorrREF_Signalaxis)
    delete(ErrorAnalysis_dvv_title)
    return
    
    % case 3: ==> an interval has been selected
else
    timewin_correlogram = str2num(dvv_corrwindowValue);
    %     t1 = timewin_correlogram(1);
    %     t2 = timewin_correlogram(2);
    t = [timewin_correlogram(1) timewin_correlogram(2)];
end

%% Plot cross-corr REF Signal & Spectrum
    % Import parameters
    correlations = crosscorr.correlations;
    time_corr = crosscorr.time_corr;

    % Scelta della finestra
    t1 = t(1);
    t2 = t(2);
    
    % Cerco posizione t1 e t2 nel correlogramma
    [c index]=min(abs(time_corr-t1));
    closestValue=time_corr(index);
    leftvalueoftimewindow=find(time_corr==closestValue);
    %QUI GUARDO A CHE POSIZIONE CORRISPONDE t2 NEL CORRELOGRAMMA(-1000:1000)
    [c index]=min(abs(time_corr-t2));
    closestValue=time_corr(index);
    rightvalueoftimewindow=find(time_corr==closestValue);
    %COSTRUISCO LA TIME WINDOW
    time_window=[leftvalueoftimewindow:rightvalueoftimewindow];

    % Definisco la finestra scelta
    [i j] = find(time_corr==t1);
    [ii k] = find(time_corr==t2);
    time_corr = time_corr(j:k);
   
    % scelgo la finestra della cross-corr REF da analizzare
    ref=nanmean(correlations(:,1:end),2);
    ref = ref(time_window);
    correlazionedaAnalizzare = ref;

    % Plot signal cross-corr REF
    axes(CrossCorrREF_Signalaxis)
    plot(CrossCorrREF_Signalaxis,time_corr,correlazionedaAnalizzare,'k')
    title('CrossCorr-REF','FontSize',9,'FontName','garamond')
    xlabel('Lag [s]')
    set(gca,'Tag','CrossCorrREF_Signalaxis')
%     zoom(CrossCorrREF_Signalaxis,'on')
    grid(CrossCorrREF_Signalaxis,'minor')
    
    % ==> Spectrum
    % Dati per spettro
    global data_selected
    Fs = data_selected(1).fs;
    nfft = 2^nextpow2(length(correlazionedaAnalizzare));
    df = Fs/nfft;
    freqAx = 0:df:(nfft/2-1)*df;
 
    result = abs(fft(correlazionedaAnalizzare,nfft));
    result(nfft/2 + 1:end,:) = [];
    
    axes(CrossCorrREF_Spectrumaxis)
    plot(CrossCorrREF_Spectrumaxis,freqAx,10*log10(result),'k');
    title(CrossCorrREF_Spectrumaxis,['Spectrum of CrossCorr-REF [' num2str(t1) '|' num2str(t2) ']'],'FontSize',9,'FontName','garamond')
    xlabel('Frequency [Hz]')
    ylabel('dB')
    set(gca,'Tag','CrossCorrREF_Spectrumaxis')
%     zoom on
    grid(CrossCorrREF_Spectrumaxis,'minor')
% powerbw(correlazionedaAnalizzare,Fs)

%% disattivo zoom dove non serve
assi = findobj(mainCrossFig,'type','axes');
setAllowAxesZoom(h,assi(3),false);
setAllowAxesZoom(h,assi(4),false);
setAllowAxesZoom(h,assi(5),false);
%%%%%%%%%%%%%%%%%%%%


%% Aggiunta pulsanti per calcolo errore

% t2-t1
timeWindow_ErrorField = uicontrol('style','text','units','normalized','position',[.55 .02 .03 .03],...
    'string','t2-t1','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','timeWindow_ErrorField');
timeWindow_ErrorValue = uicontrol('style','edit','units','normalized','position',[.5805 .02 .04 .03],'tag','timeWindow_ErrorValue',...
    'backgroundcolor',[1 1 1],'String',[num2str(t1) ',' num2str(t2)],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'Callback',@(numfld,event) updateSpectrumforErrorEstimation,...
    'tooltipstring','This is the interval selected within the correlogram. es.-2,2'); %,'Callback',@(numfld,event) updateCorrPlot);

% Wc
omegac_ErrorField = uicontrol('style','text','units','normalized','position',[.626 .02 .03 .03],...
    'string','Wc','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','omegac_ErrorField');
omegac_ErrorValue =uicontrol('style','edit','units','normalized','position',[.656 .02 .03 .03],'tag','omegac_ErrorValue',...
    'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'String','','tooltipstring','Central frequency: it is the main peak in the CrossCorr-REF spectrum');

% Bandwidth
Bandwidth_ErrorField = uicontrol('style','text','units','normalized','position',[.691 .02 .05 .03],...
    'string','Bandwidth','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','Bandwidth_ErrorField');
Bandwidth_ErrorValue =uicontrol('style','edit','units','normalized','position',[.7412 .02 .03 .03],'tag','Bandwidth_ErrorValue',...
    'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'String','','tooltipstring','The bandwidth (in Hz) will be used to compute T in the Weaver equation. es. 10');


% Compute button
Compute_ErrorButton = uicontrol('style','pushbutton','units','normalized','position',[.77612 .02 .04 .03],...
    'string','Compute','horizontalalignment','left','fontunits','normalized','fontsize',.5,'FontWeight','bold',...
    'backgroundcolor',[.7 .7 .7],'Tag','Compute_ErrorButton','Callback',@(numfld,event) Compute_ErrorAnalysis);%,'callback',@(btn,event) resetcorrelogram(btn),'Tag','reset_correlogram')

end

function updateSpectrumforErrorEstimation
% Questa funzione aggiorna il plot della cross-corr REF e del suo spettro
% al variare della finestra scelta
global mainCrossFig
global crosscorr

% Cancello plot già esistenti
CrossCorrREF_Signalaxis = findobj(mainCrossFig,'tag','CrossCorrREF_Signalaxis');
delete(get(CrossCorrREF_Signalaxis,'Children'))
CrossCorrREF_Spectrumaxis = findobj(mainCrossFig,'tag','CrossCorrREF_Spectrumaxis');
delete(get(CrossCorrREF_Spectrumaxis,'Children'))

% Prendo i parametri necessari per il riplot e il ricalcolo dello spettro
timeWindow_ErrorValue = get(findobj(mainCrossFig,'Tag','timeWindow_ErrorValue'),'String');
t = str2num(timeWindow_ErrorValue);


%% Plot cross-corr REF Signal & Spectrum
    % Import parameters
    correlations = crosscorr.correlations;
    time_corr = crosscorr.time_corr;

    % Scelta della finestra
    t1 = t(1);
    t2 = t(2);
    
    % Cerco posizione t1 e t2 nel correlogramma
    [c index]=min(abs(time_corr-t1));
    closestValue=time_corr(index);
    leftvalueoftimewindow=find(time_corr==closestValue);
    %QUI GUARDO A CHE POSIZIONE CORRISPONDE t2 NEL CORRELOGRAMMA(-1000:1000)
    [c index]=min(abs(time_corr-t2));
    closestValue=time_corr(index);
    rightvalueoftimewindow=find(time_corr==closestValue);
    %COSTRUISCO LA TIME WINDOW
    time_window=[leftvalueoftimewindow:rightvalueoftimewindow];

    % Definisco la finestra scelta
    [i j] = find(time_corr==t1);
    [ii k] = find(time_corr==t2);
    time_corr = time_corr(j:k);
   
    % scelgo la finestra della cross-corr REF da analizzare
    ref=nanmean(correlations(:,1:end),2);
    ref = ref(time_window);
    correlazionedaAnalizzare = ref;

    % Plot signal cross-corr REF
    axes(CrossCorrREF_Signalaxis)
    plot(CrossCorrREF_Signalaxis,time_corr,correlazionedaAnalizzare,'k')
    title('CrossCorr-REF','FontSize',9,'FontName','garamond')
    xlabel('Lag [s]')
    set(gca,'Tag','CrossCorrREF_Signalaxis')
%     zoom(CrossCorrREF_Signalaxis,'on')
    grid(CrossCorrREF_Signalaxis,'minor')
    
    % ==> Spectrum
    % Dati per spettro
    global data_selected
    Fs = data_selected(1).fs;
    nfft = 2^nextpow2(length(correlazionedaAnalizzare));
    df = Fs/nfft;
    freqAx = 0:df:(nfft/2-1)*df;
 
    result = abs(fft(correlazionedaAnalizzare,nfft));
    result(nfft/2 + 1:end,:) = [];
    
    axes(CrossCorrREF_Spectrumaxis)
    plot(CrossCorrREF_Spectrumaxis,freqAx,10*log10(result),'k');
    title(CrossCorrREF_Spectrumaxis,['Spectrum of CrossCorr-REF [' num2str(t1) '|' num2str(t2) ']'],'FontSize',9,'FontName','garamond')
    xlabel('Frequency [Hz]')
    ylabel('dB')
    set(gca,'Tag','CrossCorrREF_Spectrumaxis')
%     zoom on
    grid(CrossCorrREF_Spectrumaxis,'minor')
% powerbw(correlazionedaAnalizzare,Fs)

end

function Compute_ErrorAnalysis
global crosscorr
global mainCrossFig

% Prendo i parametri necessari per il riplot e il ricalcolo dello spettro
timeWindow_ErrorValue = get(findobj(mainCrossFig,'Tag','timeWindow_ErrorValue'),'String');
t = str2num(timeWindow_ErrorValue);
Wc = str2num(get(findobj(mainCrossFig,'Tag','omegac_ErrorValue'),'String')); 
Bandwidth = str2num(get(findobj(mainCrossFig,'Tag','Bandwidth_ErrorValue'),'String'));
correlationCoefficient = crosscorr.correlationCoefficient;
X = correlationCoefficient;

% Applico formula
t1 = t(1);
t2 = t(2);
T = 1/Bandwidth;
rmsteorico = (sqrt(1-X.^2)./(2*X)).* sqrt((6*sqrt(pi/2)*T)/(Wc^2*(t2^3-t1^3)));

sz = 25;


% Plot
ax_dvv = crosscorr.ax_dvv;
dv = crosscorr.dv;
timeAx = crosscorr.timeAx;

yyaxis(ax_dvv, 'left');
hold on
dvErrorPlot = scatter(ax_dvv,timeAx,dv,sz,rmsteorico,'filled','HandleVisibility','off','MarkerFaceAlpha',.7,'MarkerEdgeAlpha',.7);

    choicePiezo = get(findobj(mainCrossFig,'tag','piezo_plotcheck'),'Value');
    if choicePiezo == 0
        legend(ax_dvv,'dV/V','dV/V Smoothed','Location','southeast');
    end
    if choicePiezo == 1
        legend(ax_dvv,'dV/V','dV/V Smoothed','Piezometer data','Location','southeast');
    end
    
% Plot colorbar
colorbarRMSError = colorbar('Units','normalized','Position',[0.83 .02 .14 .03],'Location','south','AxisLocation','in','Tag','colorbarRMSError');
colorbarRMSError.Label.String = ['rms ' char(949)];
colorbarRMSError.Label.FontSize = 12;
colorbarRMSError.Label.FontName = 'garamond'
colorbarRMSError.Label.Position = [0.5, 0.2]
colormap(colorbarRMSError,jet)


end