function CrossCorr_Compute

global utilities
global mainCrossFig
global data_selected
global crosscorr
global dataforPlotVideoCrossCorr
%%% queste righe servono per cancellare grafico correlogramma nel caso si
%%% ricliccasse su CC compute
% 1) Cancella dvvplot se è giù stato fatto

delete(findobj('tag','PlotVideoButton'));drawnow
delete(findobj(mainCrossFig,'tag','datiesclusidvv'));drawnow 
delete(findobj(gcf,'type','axes','tag','drawnowdynamicCorrWinAxes'));drawnow
delete(findobj(gcf,'type','axes','tag','dvvPlot'));drawnow
delete(findobj('tag','Smoothing_text'));drawnow
delete(findobj('tag','Smoothing_type'));drawnow
delete(findobj('tag','Smoothing_window'));drawnow
delete(findobj('tag','settings_dvv'));drawnow
delete(findobj('tag','dVV_Xlimits'));drawnow
delete(findobj('tag','dVV_Xlimits_left'));drawnow
delete(findobj('tag','dVV_Xlimits_right'));drawnow
delete(findobj('tag','dVV_Ylimits'));drawnow
delete(findobj('tag','dVV_Ylimits_Value'));drawnow
delete(findobj('tag','water_Ylimits'));drawnow
delete(findobj('tag','water_Ylimits_Value'));drawnow
delete(findobj('tag','watertable_color'));drawnow
delete(findobj('tag','dvv_color'));drawnow
delete(findobj('tag','update_dvvPlot'));drawnow
delete(findobj('tag','reset_dvvPlot'));drawnow
delete(findobj('tag','PlotVideoButton'));drawnow
delete(findobj('tag','DynamicWinCorr_text'));drawnow
delete(findobj('tag','dynamicWinCorrSlider'));drawnow
delete(findobj('tag','dynamiCorrWinTitle'));drawnow
delete(findobj(mainCrossFig,'tag','TitleCC_dvvVSPiezo'));drawnow
delete(findobj(mainCrossFig,'tag','CCcolorBar'));drawnow
delete(findobj(mainCrossFig,'tag','axCC'));drawnow
delete(findobj(mainCrossFig,'tag','Ax_FreqBandAnalisys'));drawnow
delete(findobj(mainCrossFig,'tag','exclude_correlogram_text'));drawnow
delete(findobj(mainCrossFig,'tag','exclude_correlogram'));drawnow

% questi sono gli assi e i tasti dell'errorAnalysis
delete(findobj(gcf,'tag','Add_ErrorAnalysis_dvv'));drawnow
delete(findobj(gcf,'type','axes','tag','CrossCorrREF_Signalaxis'));drawnow
delete(findobj(gcf,'type','axes','tag','CrossCorrREF_Spectrumaxis'));drawnow
delete(findobj(gcf,'tag','timeWindow_ErrorField'));drawnow
delete(findobj(gcf,'tag','timeWindow_ErrorValue'));drawnow
delete(findobj(gcf,'tag','omegac_ErrorField'));drawnow
delete(findobj(gcf,'tag','omegac_ErrorValue'));drawnow
delete(findobj(gcf,'tag','Bandwidth_ErrorField'));drawnow
delete(findobj(gcf,'tag','Bandwidth_ErrorValue'));drawnow
delete(findobj(gcf,'tag','Compute_ErrorButton'));drawnow
delete(findobj(gcf,'tag','colorbarRMSError'));drawnow

% 2) Cancella correlogramma se esiste
if ~isempty(findobj(gcf,'type','axes','tag','dvvPlot')) %questo serve per chiudere il dvv plot se stato fatto
    delete(findobj(gcf,'type','axes','tag','dvvPlot'));drawnow
end
delete(findobj(gcf,'type','axes','tag','Correlogram'));drawnow
delete(findobj('tag','settings_correlogram'));drawnow
delete(findobj('tag','xlimits_correlogram_text'));drawnow
delete(findobj('tag','caxis_correlogram_text'));drawnow
delete(findobj('tag','xlimits_correlogram'));drawnow
delete(findobj('tag','caxis_correlogram'));drawnow
delete(findobj('tag','update_correlogram'));drawnow
delete(findobj('tag','reset_correlogram'));drawnow


%%%


%%%%%    Waitbar   %%%%%
wait = findobj(mainCrossFig,'tag','wait');
handleToWaitBar = findobj(mainCrossFig,'tag','handleToWaitBar');
%%%%%%%%%%%%%%%%%%%%%%%%%

%% 1) Get input from mainCrossFig
% Pre-processing input
removeMean = get(findobj(mainCrossFig,'tag','removeMean'),'value');
detrendValue = get(findobj(mainCrossFig,'tag','detrend'),'value');
filtering = get(findobj(mainCrossFig,'tag','filtercheck'),'value');
filterselected = get(findobj(mainCrossFig,'tag','filtertype_checkbox'),'value');
filtertype = get(findobj(mainCrossFig,'tag','filtertype_checkbox'),'string');
filtertype = filtertype(filterselected);
crosscorr.filtertype = filtertype;
filterfreq = get(findobj(mainCrossFig,'tag','filterfreq'),'string');
crosscorr.filterfreq = filterfreq;
% Cross-Corr input
timelength = str2num(get(findobj(mainCrossFig,'tag','timelength'),'string'));
WeightingType = get(findobj(mainCrossFig,'tag','Weighting'),'value');
WeightingString = get(findobj(mainCrossFig,'tag','Weighting'),'string');
esiste = findobj(mainCrossFig,'tag','WeightValue');
if not(isempty(esiste))
WeightValue = str2num(get(findobj(mainCrossFig,'tag','WeightValue'),'string'));
end
maxlag = str2num(get(findobj(mainCrossFig,'tag','maxlag'),'string'));


if isempty(timelength)
    beep
    waitfor(msgbox('You must specify the time length!','Update','error'));
    return
end

% Get parameters for Dynamic filter. Gli altri tipi di filtro vengono
% applicati dopo 
if filtering == 1
    % Design Dynamic filter
    if strcmp(filtertype,'Dynamic')
       settingDynamicFilterParameters 
    end
end
%%%%

%% 2) Signals for cross-correlation
signal_1 = data_selected(1).signal;
signal_2 = data_selected(2).signal;
Fs = data_selected(1).fs;

%% 3)  Time-domain weightining
if strcmp(WeightingString(WeightingType),'Time') | strcmp(WeightingString(WeightingType),'Both') %Se si applica il Time-domain Weighting
    % E' necessario fare un highpass filter ai segnali prima di fare questo step
    signal_1 = highpass(signal_1,0.05,Fs,'ImpulseResponse','iir','Steepness',0.95);
    signal_2 = highpass(signal_2,0.05,Fs,'ImpulseResponse','iir','Steepness',0.95);
    % Dati necessari
    N = 1/WeightValue; %secondi ==> è il periodo massimo
    N = N*Fs; %numero di campioni
    % Traccia 1
    w = runmean(signal_1,N/2,[],'mean'); %Calclo pesi come da formula libro e paper Bensen et all 2007
    signal_1 = signal_1./w;
    % Traccia 2
    w = runmean(signal_2,N/2,[],'mean'); %Calclo pesi come da formula libro e paper Bensen et all 2007
    signal_2 = signal_2./w;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 4) COMPUTING CROSS_CORRELATION
% 4.1) Subdivide into subsignals which will be used to compute cross-correlation
samplesTimeLength = timelength*60*Fs; %samples per second

if rem(length(signal_1),samplesTimeLength) == 0
    signal_1 = reshape(signal_1,samplesTimeLength,[]);
    signal_2 = reshape(signal_2,samplesTimeLength,[]);
else
    signal_1 = reshape(signal_1(rem(length(signal_1),samplesTimeLength)+1:end),samplesTimeLength,[]);
    signal_2 = reshape(signal_2(rem(length(signal_2),samplesTimeLength)+1:end),samplesTimeLength,[]);
end

% 4.2) Cross-correlation computation
% Lista dei subsegnali
crosscorr.subsignals = [1:size(signal_1,2)];
subsignals = crosscorr.subsignals;
numero=0;
valid=0;
param_time=1;

for kk=1:length(subsignals)
    % Carica ogni singola traccia
    toto1_new_D1 = signal_1(:,kk);
    toto1_new_D2 = signal_2(:,kk);
    valid=valid+1;
    numero=numero+1; % conteggio del subsignal rispetto al primo
    index=(numero-1)*param_time; % conteggio del subsignal rispetto al primo
    
    
    
    %%%%%%%%%%%%%% FASE: WHITENING  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Da
    %%%%%%%%%%%%%% libro ambient seismic noise pag. 153-159
    if  strcmp(WeightingString(WeightingType),'Frequency') | strcmp(WeightingString(WeightingType),'Both') % Se si applica il whitening (frequency-domain)o entrambi TIme and Frequency weighting
        % Traccia 1
        toto1=fft(toto1_new_D1); % Trasformata di fourier
        toto_final1=toto1./abs(toto1); % diviso per l'inverso del modulo equalizzando le frequenze.........'.*hanning(length(J)).^0.25)';
        toto_final1=real(ifft(toto_final1)); % Ritorno al segnale sbiancato..................................*hanning(length(toto_final1))';
        % Traccia 2
        toto2=fft(toto1_new_D2); % Trasformata di fourier
        toto_final2=toto2./abs(toto2);% diviso per l'inverso del modulo equalizzando le frequenze.........'.*hanning(length(J)).^0.25)';
        toto_final2=real(ifft(toto_final2));% Ritorno al segnale sbiancato..................................*hanning(length(toto_final1))';

    else % Se non si fa il whitening
        toto_final1=toto1_new_D1; % Non sbianco la traccia 1
        toto_final2=toto1_new_D2; % Non sbianco la traccia 2
    end
    %%%%%%%%%%%% FINE WHITENING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    % Opzioni cross-correlazione
    if valid==1
        maxlag=maxlag*Fs; % tempo di correlazione in punti
        % ###################### pourquoi /Fsnew
        time_corr=[-maxlag:maxlag]/Fs; % intervallo di correlazione
        correlations=zeros(length(time_corr),length(subsignals)*param_time); % inizializzazione dell'elenco delle correlazioni della coppia
        % ###################### qu'est-ce que Nan
%         energie1=NaN(param_time*length(subsignals),1); % ?nergie 1
%         energie2=NaN(param_time*length(subsignals),1); % ?nergie 2
    end
    
    %% pour chaque heure
    
    %Creo asse temporale
    Nombre_new=round(Fs*timelength*60);
    time_new=[0:Nombre_new-1]/Fs;
%     for ii=1:param_time
        % intervallo di scorrimento per cross corr (th?oriquement 1h ?)
%         interval=round(length(time_new)/param_time)*(ii-1)+[1:round(length(time_new)/param_time)]; %Codice Christophe se vuoi usare questo codice usa versione PassiveBarinda precedende alla 20200417         
        interval=[1:round(length(time_new)/param_time)]; %Marco
        
        % Traccia 1
        minitrace1 = toto_final1;
        if removeMean == 1
            minitrace1=toto_final1(interval)-nanmean(toto_final1(interval)); %sottraggo media
        end
        if detrendValue == 1
            minitrace1=detrend(minitrace1); %Detrend           %minitrace1=max(0,minitrace1./max(abs(minitrace1)));%.*hanning(length(minitrace1))';;
        end
        
        % Traccia 2
        minitrace2 = toto_final2;
        if removeMean == 1
            minitrace2=toto_final2(interval)-nanmean(toto_final2(interval)); %sottraggo media
        end
        if detrendValue == 1
            minitrace2=detrend(minitrace2); %Detrend           %minitrace2=max(0,minitrace2./max(abs(minitrace2)));%.*hanning(length(minitrace2))';
        end
        
%         energie1(index+ii)=sum(minitrace1.^2); % Energia della traccia 1 sull'intervallo considerato
%         energie2(index+ii)=sum(minitrace2.^2); % Energia della traccia 1 sull'intervallo considerato
        
        % Correlazione
%         if energie1(index+ii)~=0 && energie2(index+ii)~=0
            %%test=xcorr(toto_final1(interval),toto_final2(interval),maxlag)./sqrt(energie1(index+ii).*energie2(index+ii)); % corr?lation crois?e normalis?e par rapport ? la racine carr?e du pdt des ?nergies au carr?
%             test=xcorr(minitrace1,minitrace2,maxlag)./sqrt(energie1(index+ii).*energie2(index+ii)); % Codice Christophe se vuoi usare questo codice usa versione PassiveBarinda precedende alla 20200417            
            test=xcorr(minitrace1,minitrace2,maxlag,'normalized'); %Codice Marco
            correlations(:,index+1)=test; % ajout de la corr?lation consid?r?e (sur 1h) ? l'ensemble des corr?lations du jour consid?r?
            
            clear test % eliminazione delle variabili di correlazione
%         end
%     end
    
    %%%%%    Waitbar   %%%%%
    set(wait,'visible','on')
    set(handleToWaitBar,'visible','on')
    p = get(handleToWaitBar,'Child');
    x = get(p,'XData');
    x(3:4) = kk/length(subsignals);
    set(p,'XData',x);
    drawnow
    %%%%%%%%%%%%%%%%%%%%%%%%%
end

%%% if there are Nan in the correlations matrix set it equal to 0
correlations(isnan(correlations))=0;
%%% Correlogram Filtering
correlations_NOTFILTERED = correlations; %This will be used if in the dvv computation you select the option to compute the dvv with not-filtered correlogram
correlations_NOTFILTERED(isnan(correlations_NOTFILTERED))=0;

if filtering == 1
    % Design lowpass filt
    if strcmp(filtertype,'Lowpass')
        correlations   = lowpass(correlations,str2num(filterfreq), Fs,'ImpulseResponse','iir','Steepness',0.95);
    end
    
    % Design highpass filter
    if strcmp(filtertype,'Highpass')
        correlations   = highpass(correlations,str2num(filterfreq), Fs,'ImpulseResponse','iir','Steepness',0.95);
    end
    
    % Design bandpass filter
    if strcmp(filtertype,'Bandpass')
        correlations   = bandpass(correlations,str2num(filterfreq), Fs,'ImpulseResponse','iir','Steepness',0.95);
    end   
    
    % Design Dynamic filter ==> Qui viene fatto il broadband correlogramma
    if strcmp(filtertype,'Dynamic')
        filterfreq = crosscorr.dynamicBroadband;
        correlations   = bandpass(correlations,str2num(filterfreq), Fs,'ImpulseResponse','iir','Steepness',0.95);
    end
    
end
%%%%

%%% PLOT: Rendo globali queste variabili per plot e per calcolo dv/v
crosscorr.time_corr =time_corr;
crosscorr.correlations_NOTFILTERED = correlations_NOTFILTERED;
crosscorr.correlations = correlations;
crosscorr.subsignals = subsignals;
plotcorrelogram
%%%%%%%%%%%%%%%%%%%%%%%%%

%%% PLOT: Rendo globali queste variabili per plot video cross_corr
dataforPlotVideoCrossCorr.time_corr =time_corr;
dataforPlotVideoCrossCorr.correlations = correlations;
timelength = str2num(get(findobj(mainCrossFig,'tag','timelength'),'string'));
dataforPlotVideoCrossCorr.timelength = timelength;
xlimits = str2num(get(findobj(mainCrossFig,'tag','xlimits_correlogram'),'String'));
%%%%%%%%%%%%%%%%%%%%%%%%%

%% Attiva possibilità di calcolare dV/V
dvv_activation
end

function plotcorrelogram
global crosscorr
global mainCrossFig
global dataforPlotVideoCrossCorr
%%%%%% Richiamo variabili dal global %%%%%
wait = findobj(mainCrossFig,'tag','wait');
handleToWaitBar = findobj(mainCrossFig,'tag','handleToWaitBar');
time_corr = crosscorr.time_corr;
correlations = crosscorr.correlations;
subsignals = crosscorr.subsignals;
timelength = str2num(get(findobj(mainCrossFig,'tag','timelength'),'string'));
% Creo titolo correlogramma
maxlag = str2num(get(findobj(mainCrossFig,'tag','maxlag'),'string'));
filtertype = crosscorr.filtertype;
filterfreq = crosscorr.filterfreq;
if ~isempty(filtertype)
if strcmp(filtertype,'Lowpass')
    filterTitolo = ['<' filterfreq]
elseif strcmp(filtertype,'Highpass')
    filterTitolo = ['>' filterfreq]
else 
    filterTitolo = [filterfreq]
end
end
correlogramtitle = crosscorr.correlogramtitle;
correlogramtitle = [correlogramtitle '| Signals length ' num2str(timelength) '[minutes]| Maxlag:' num2str(maxlag) '| Filter:' filterTitolo '[Hz]']; %aggiungo minuti al titolo
crosscorr.TITOLOCORRELOGRAMMA = correlogramtitle;
dataforPlotVideoCrossCorr.TITOLOCORRELOGRAMMA = correlogramtitle;
%%%%% %%%%% %%%%% %%%%% %%%%% %%%%% %%%%%

%% Plot correlogram
ax1 = axes('Position',[0.18 0.18 0.335 0.78]);
axtoolbar(ax1)
graficoCorrelogramma = imagesc(ax1,time_corr,1:size(correlations,2),correlations')
crosscorr.graficoCorrelogramma = graficoCorrelogramma;
set(gca,'Tag','Correlogram');
yticksCorrelogram = ax1.YTick;
yticklabels({timelength*yticksCorrelogram}) %Ytick in minuti
ylabel('minutes')
% caxis([-0.2 0.2])
xlimits = xlim;
dataforPlotVideoCrossCorr.xlimits=xlimits;
title(correlogramtitle,'FontSize',10,'FontName','garamond')
crosscorr.correlogramcolorbar = colorbar('Tag','correlogramcolorbar');
set(crosscorr.correlogramcolorbar,'Location','southoutside');
grid on
% dragzoom();

%% Aggiunta pulsanti per modificare il plot
uicontrol('style','text','units','normalized','position',[.176 .14 .06 .03],...
    'string','Plot settings','horizontalalignment','center','fontunits','normalized','fontsize',.6,...
    'Tag','settings_correlogram');

% Xlimits
uicontrol('style','text','units','normalized','position',[.18 .110 .03 .03],...
    'string','Xlimits','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','xlimits_correlogram_text');
uicontrol('style','edit','units','normalized','position',[.21 .110 .04 .03],'tag','xlimits_correlogram',...
    'backgroundcolor',[1 1 1],'String',[num2str(round(xlimits(1))) ',' num2str(round(xlimits(2)))],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring','Limits of xaxis. es. -2,2','Callback',@(numfld,event) updateCorrPlot);

% Colorbar limits
uicontrol('style','text','units','normalized','position',[.255 .110 .03 .03],...
    'string','Caxis','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','caxis_correlogram_text');
uicontrol('style','edit','units','normalized','position',[.285 .110 .04 .03],'tag','caxis_correlogram',...
    'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'String','auto','tooltipstring',['Colorbar limits. es. -2,2' 10 'If "auto" the colorbar will be automatically set'],...
    'Callback',@(numfld,event) updateCorrPlot);


% Reset button
uicontrol('style','pushbutton','units','normalized','position',[.33 .110 .035 .03],...
    'string','Reset','horizontalalignment','left','fontunits','normalized','fontsize',.5,'FontWeight','bold',...
    'backgroundcolor',[.7 .7 .7],'callback',@(btn,event) resetcorrelogram(btn),'Tag','reset_correlogram')

% Exclude data from correlogram
uicontrol('style','text','units','normalized','position',[.435 .110 .04 .03],...
    'string','Exclude','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','exclude_correlogram_text');
uicontrol('style','edit','units','normalized','position',[.475 .110 .04 .03],'tag','exclude_correlogram',...
    'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'String','','tooltipstring',['Select a time window in the correlogram that you want to exclude from dV/V computation' 10 ...
    'es. 100,110. In this way the correlations between 100 and 110 will not be use to extimate the dV/V' 10 ...
    'Questa opzione non è implementata con le finestre dinamiche ma solo con il caso semplice in cui si calcola un solo dV/V']);

%% Cross-corr completed
% Display che il load è avvenuto
beep on; beep
h=msgbox('Cross-correlation has been computed!','Update','warn');
pause(1)
close(h)
%%%%%    Waitbar   %%%%%
set(wait,'visible','off')
set(handleToWaitBar,'visible','off')
p = get(handleToWaitBar,'Child');
x = get(p,'XData');
x(3:4) = 0;
set(p,'XData',x);
drawnow

%%% Se è stato selezionato il filtro Dynamic mostra che ora bisogna fare il
%%% dV/V compute
Listafiltri = get(findobj(mainCrossFig,'tag','filtertype_checkbox'),'String');
tipoFiltro = get(findobj(mainCrossFig,'tag','filtertype_checkbox'),'Value');
filtroselezionato = Listafiltri(tipoFiltro)
if strcmp(filtroselezionato,'Dynamic')
beep on; beep
h=msgbox('Now you have to select the Corr. window and then click on dV/V Compute button!','Update','warn');
pause(1.5)
close(h)
end

end

function updateCorrPlot
global mainCrossFig
global crosscorr
global data_selected
global dataforPlotVideoCrossCorr

delete(findobj(gcf,'type','axes','tag','drawnowdynamicCorrWinAxes'));drawnow

Fs = data_selected(1).fs; %serve nel caso si faccia filtro correlogramma
correlations = crosscorr.correlations;
subsignals = crosscorr.subsignals;
time_corr = crosscorr.time_corr;
timelength = str2num(get(findobj(mainCrossFig,'tag','timelength'),'string'));
correlogramtitle = crosscorr.TITOLOCORRELOGRAMMA;

% Richiama figura
correlogramplot = findobj(gcf,'tag','Correlogram');
% Richiama i parametri inseriti e modifica il plot


% Xlimits
xlimits = str2num(get(findobj(mainCrossFig,'tag','xlimits_correlogram'),'String'));
correlogramplot.XLim = xlimits;
dataforPlotVideoCrossCorr.xlimits=xlimits;

% Caxis
colorbarlimits = str2num(get(findobj(mainCrossFig,'tag','caxis_correlogram'),'String'));
if isempty(colorbarlimits)
    set(crosscorr.correlogramcolorbar);
else
    correlogramplot = findobj(gcf,'type','axes','tag','Correlogram');
    set(correlogramplot,'clim',colorbarlimits);
end

% Se è stata scelta l'opzione Dynamic in Corr.window aggiorna anche l'asse
dvv_corrwindowValue =  get(findobj(mainCrossFig,'tag','dvv_corrwindowValue'),'String');
dvvaxes = findobj(mainCrossFig,'type','axes','tag','dvvPlot');
if strcmp(dvv_corrwindowValue,'dynamic') == 1 && not(isempty(dvvaxes))
asseCorr = findobj(mainCrossFig,'tag','Correlogram')
asseCC = findobj(mainCrossFig,'tag','axCC')
asseCC.XLim = asseCorr.XLim;
end

end

function resetcorrelogram(btn)
global mainCrossFig
global crosscorr
global data_selected
timelength = str2num(get(findobj(mainCrossFig,'tag','timelength'),'string'));
Fs = data_selected(1).fs; %serve nel caso si faccia filtro correlogramma
correlations = crosscorr.correlations;
subsignals = crosscorr.subsignals;
time_corr = crosscorr.time_corr;
correlogramtitle = crosscorr.TITOLOCORRELOGRAMMA;


% Richiama figura
findobj(gcf,'tag','Correlogram');
% Richiama i parametri inseriti e modifica il plot

% Plot correlogram
delete(findobj(gcf,'type','axes','tag','Correlogram'));drawnow
delete(findobj(gcf,'type','axes','tag','drawnowdynamicCorrWinAxes'));drawnow
ax1 = axes('Position',[0.18 0.18 0.335 0.78]);
graficoCorrelogramma = imagesc(ax1,time_corr,1:size(correlations,2),correlations')
crosscorr.graficoCorrelogramma = graficoCorrelogramma;
set(gca,'Tag','Correlogram')
yticksCorrelogram = ax1.YTick;
yticklabels({timelength*yticksCorrelogram}) %Ytick in minuti
ylabel('minutes')
% caxis([-0.2 0.2])
xlimits = xlim;
title(correlogramtitle,'FontSize',10,'FontName','garamond')
colorbar('Location','southoutside');
grid on
end

%%%%%%%%% Getting parameters for Dynamic Filter computation of dV/V 
function settingDynamicFilterParameters
global crosscorr
global DynamicFrequencyUIFigure
%% Crea finestra richiesta dati per calcolare il dV/V per diversi finestre del correlogramma

% a) Crea figure
DynamicFrequencyUIFigure = figure('numbertitle','off','Name','Dynamic frequency parameters','toolbar','none','menubar','none','Position', [600 450 355 187]);

% b) Create BroadBandFieldLabel
dynamicBroadBandEditFieldLabel = uicontrol(DynamicFrequencyUIFigure,'Style','text','Position',[50 146 150 22],'HorizontalAlignment','left',...
    'FontSize',9,'String','Broadband [Hz] ');

% c) Create BroadBandEditField
dynamicBroadBandEditField = uicontrol(DynamicFrequencyUIFigure,'Style','edit','Position',[200 148 92 22],'TooltipString',...
    'Set the broadband frequency in Hz. i.e. 1,20','Tag','dynamicBroadBand');


% d) Create dynamicFreqStepEditFieldLabel
dynamicFreqStepFieldLabel = uicontrol(DynamicFrequencyUIFigure,'Style','text','Position',[50 110 150 22],'HorizontalAlignment','left',...
    'FontSize',9,'String','Frequency step');

% e) Create dynamicFreqStepEditField
dynamicFreqStepEditField = uicontrol(DynamicFrequencyUIFigure,'Style','edit','Position',[200 112 92 22],'TooltipString',...
    'Set the width of the band-pass filter. es. 2 means that for istance the band-pass will be 1-3,3-5,...','Tag','dynamicCorrelogramFilterFreqStep');

% h)Create ProceedButton
ProceedButton = uicontrol(DynamicFrequencyUIFigure, 'Style','pushbutton','String','Proceed','Position',[200 65 91 22],...
    'Callback', @(hObject, eventdata) selectedButton(hObject, eventdata),'Tag','proceedComputation');

% i)Create ExitButton
ExitButton = uicontrol(DynamicFrequencyUIFigure, 'Style','pushbutton','String','Exit','ForegroundColor','r','Position',[100 65 91 22],...
    'TooltipString','If you exit you run out the computation of the dV/V',...
    'Callback', @(hObject, eventdata) selectedButton(hObject, eventdata),'Tag','exitComputation');

% l) Create TextArea
TextArea = uicontrol(DynamicFrequencyUIFigure,'Style','text','FontSize',6.8,'HorizontalAlignment','left','FontAngle','italic','Position',[10 8 331 48],...
    'String',['Help: Using the "dynamic" filter the software will compute the dV/V for different band-pass filters of the correlogram. Then it plot the autocorrelation of the dV/V obtained for the broadband filter vs the the crosscorr between the broadband dV/V and the filtered one. es. Figure 4 paper Voison et all 2016']);

uiwait(gcf)
% end


end
function selectedButton(hObject, eventdata)
global crosscorr
global DynamicFrequencyUIFigure
%% 1) Get input parameters
% a) BroadBand filter
dynamicBroadband = get(findobj(DynamicFrequencyUIFigure,'tag','dynamicBroadBand'),'String');
crosscorr.dynamicBroadband = dynamicBroadband;
dynamicBroadband = str2num(dynamicBroadband);
% b) Frequency step
dynamicFreqStepFilter = get(findobj(DynamicFrequencyUIFigure,'tag','dynamicCorrelogramFilterFreqStep'),'String');
crosscorr.dynamicFreqStepFilter = dynamicFreqStepFilter;
dynamicFreqStepFilter = str2num(dynamicFreqStepFilter);

frequenze = dynamicBroadband(1):dynamicFreqStepFilter:dynamicBroadband(2);
filterfreqDynamicCorrelogram = zeros(length(frequenze),2);
    for i = 1:length(frequenze)
filterfreqDynamicCorrelogram(i,:) = [dynamicBroadband(1)+(i-1)*dynamicFreqStepFilter dynamicBroadband(1)+i*dynamicFreqStepFilter]
    end
crosscorr.filterfreqDynamicCorrelogram = filterfreqDynamicCorrelogram;

%% 2) Get pushed button
exitButton = get(findobj(DynamicFrequencyUIFigure,'tag','exitComputation'),'Value');
proceedButton = get(findobj(DynamicFrequencyUIFigure,'tag','proceedComputation'),'Value');

if exitButton == 1
    choicedvvDynamic = 'exitComputation';
elseif proceedButton ==1
    choicedvvDynamic = 'proceedComputation';
end
crosscorr.choicedvvDynamic = choicedvvDynamic;

% chiudi la finestra del settagio dei parametri
close(DynamicFrequencyUIFigure)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Funzione per attivare calcolo dV/V e import Piezo data
function dvv_activation
% Save correlogram activation
set(findobj('Tag','Save correlogram'),'enable','on');
set(findobj('Tag','Save dvv Plot'),'enable','off');
% dvv activation
dvv_Setting = set(findobj('Tag','dvv_Settings'),'enable','on');
dvv_corrwindow = set(findobj('Tag','dvv_corrwindow'),'enable','on');
dvv_corrwindowValue = set(findobj('Tag','dvv_corrwindowValue'),'enable','on');
dvv_corrfilter = set(findobj('Tag','dvv_corrfilter'),'enable','on');
dvv_corrfilterCheck = set(findobj('Tag','dvv_corrfilterCheck'),'enable','on');
dvv_Epsilon = set(findobj('Tag','dvv_Epsilon'),'enable','on');
dvv_EpsilonValue = set(findobj('Tag','dvv_EpsilonValue'),'enable','on');
dvv_smoothing = set(findobj('Tag','dvv_smoothing'),'enable','on');
dvv_smoothingValue = set(findobj('Tag','dvv_smoothingValue'),'enable','on');
dvv_compute = set(findobj('Tag','dvv_compute'),'enable','on');
dvv_Timezone_text = set(findobj('Tag','Timezone_text'),'enable','on');
dvv_Timezone = set(findobj('Tag','Timezone'),'enable','on');
% piezodata activation
piezo_data = set(findobj('Tag','piezo_data'),'enable','on');
piezo_plot = set(findobj('Tag','piezo_plot'),'enable','on');
piezo_plotcheck = set(findobj('Tag','piezo_plotcheck'),'enable','on');
% piezo_select = set(findobj('Tag','piezo_select'),'enable','on');
% piezo_selectButton = set(findobj('Tag','piezo_selectButton'),'enable','on');

end
