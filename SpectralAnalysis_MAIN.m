function SpectralAnalysis_MAIN(data_processing)
global utilities
global data_selected
global spectralAnalysis

% Seleziono il segnale dalla tabella in MainPassive
selected = evalin('base','selected');
data_selected = data_processing(selected,1); %Segnale selezionato da tabella "Signal for processing"
spectralAnalysis.data_selected = data_selected;
% assignin('base','data_selected',data_selected) %questo serve solo per cut e filtro segnale

%% Controlli iniziali

% 1) Prima di applicare la funzione controlla che sia stato selezionato un solo segnale
if logical(evalin('base','~exist(''selected'')')) % Se non sono stati selezionati termina la funzione con questo messaggio di errore
    beep
    h=msgbox('No data have been selected! Please select one signal from "Signal for processing" list!','Update','error');
    return
else selected = evalin('base','selected'); % Se esiste carica la variabile selected dal base-workspace
end

% 2) Check if only one signal have been selected
if size(data_selected,1) ~= 1
    beep
    waitfor(msgbox('You must select only one signals!','Update','error'))
    return
end

%% SIGNAL INFO ------------------------------------------------

% Creazione figure e rettangolo attorno ai plot
mainSpectralAnalysisFig = figure('Tag','SP_Main','Name','Spectral Analysis','numbertitle','off','Units','normalized','WindowState','maximized','MenuBar','none') %SP = SpectralAnalysis
spectralAnalysis.mainSpectralAnalysisFig = mainSpectralAnalysisFig;
% Cornice ai plot e titolo
annotation('line',[0.14 0.99],[0.988 0.988],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga sopra orizzontale
annotation('line',[0.14 0.14],[0.014 0.988],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga sx verticale
annotation('line',[0.99 0.99],[0.014 0.988],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga dx verticale
annotation('line',[0.14 0.99],[0.014 0.014],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga sotto orizzontale

annotation('textbox',[0.02,0.975,0.078,0.02],'String','Spectral analysis Plot','Units','normalized','Position',[0.16 0.973 0.076 0.03],'FontSize',8,'LineStyle','none','BackgroundColor',[0.95 0.95 0.95]);


% SIGNAL INFO ------------------------------------------------
uicontrol('style','text','units','normalized','position',[.005 .96 .12 .03],...
    'string',' Signal info','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',[189/255 236/255 182/255]);
  
% Signal station
uicontrol('style','text','units','normalized','position',[.005 .925 .06 .03],...
    'string','Station','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','text','units','normalized','position',[.065 .925 .06 .03],'tag','Signals_info',...
    'string',[data_selected.stn],'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5);

% Selected Component
uicontrol('style','text','units','normalized','position',[.005 .893 .06 .03],...
    'string','Component','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','text','tag','Signal_comp','units','normalized','position',[.065 .893 .06 .03],...
    'string',data_selected.Comp,'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5);

% Fs - sampling frequency
uicontrol('style','text','units','normalized','position',[.005 .861 .06 .03],...
    'string','Fs','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','text','tag','Signal_FS','units','normalized','position',[.065 .861 .06 .03],...
    'string',data_selected.fs,'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5);

% Start Time
uicontrol('style','text','units','normalized','position',[.005 .829 .06 .03],...
    'string','Start Time','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','text','tag','Signals_startTime','units','normalized','position',[.065 .829 .06 .03],...
    'string',datestr(data_selected.timeAx(1)),'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.4);

% End Time
uicontrol('style','text','units','normalized','position',[.005 .797 .06 .03],...
    'string','End Time','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','text','tag','Signals_endTime','units','normalized','position',[.065 .797 .06 .03],...
    'string',datestr(data_selected.timeAx(end)),'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.4);

%% SIGNAL PRE_PROCESSING --------------------------------------------------------
uicontrol('style','text','units','normalized','position',[.005 .750 .12 .03],...
    'string',' Signal Pre-processing','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',[189/255 236/255 182/255]);

% Cut signals
uicontrol('style','text','units','normalized','position',[.005 .715 .06 .03],...
    'string','Cut signal','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','pushbutton','tag','cutButton','units','normalized','position',[.065 .715 .06 .03],...
    'string','Enter','Value', 0,'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'Callback','SpectralAnalysis_cut');

% Filtering
uicontrol('style','text','units','normalized','position',[.005 .6830 .06 .03],...
    'string','Filtering','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','pushbutton','tag','filterButton','units','normalized','position',[.065 .6830 .06 .03],...
    'string','Enter','Value', 0,'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'Callback','SpectralAnalysis_filter');


%% Spectral analysis --------------------------------------------------------
uicontrol('style','text','units','normalized','position',[.005 .6360 .12 .03],...
    'string',' Spectral Analysis','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',[189/255 236/255 182/255]);

% Method
SpiegazioneMetodo = ['Amp. Spectrum ==> displays the amplitude of the signal Fourier transform (FFT).   abs(FFT(signal))' 10 ...
    'Phase Spectrum ==> displays the unwrapped phase of the signal Fourier transform (FFT).   unwrap(angle(FFT(signal)))' 10 ...
    'Periodogram ==> non media suddiivdendo il segnale in finestre ma moltiplica soltando il segnale per una finestra'];
SP_method_text = uicontrol('style','text','Tag','SP_method_text','units','normalized','position',[.005 .6010 .06 .03],...
    'Enable','on','string','Method','horizontalalignment','center','fontunits','normalized','fontsize',.5,'backgroundcolor',[.8 .8 .8]);
SP_method_listbox = uicontrol('style','popupmenu','Tag','SP_method_listbox','units','normalized','position',[.065 .600 .06 .03],'Enable','on',...
    'string',{'Amp. Spectrum','Phase Spectrum','Periodogram','Welch','Multitaper','Spectrogram','Stacked spectrogram'},'horizontalalignment','center',...
    'fontunits','normalized','fontsize',.5,'Tooltip',SpiegazioneMetodo,'Callback',@(numfld,event) activationRequiredParameters); %'Callback',@(hObject, eventdata) SP_buttonActivation(hObject, eventdata));

% Nfft
SP_nfft_text = uicontrol('style','text','tag','SP_nfft_text','units','normalized','position',[.005 .5690 .06 .03],...
    'string','Nfft','horizontalalignment','center','fontunits','normalized','fontsize',.5,'backgroundcolor',[.8 .8 .8],'Enable','on');
SP_nfft_value = uicontrol('style','edit','tag','SP_nfft_value','units','normalized','position',[.065 .5690 .06 .03],...
    'String','auto','backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','on',...
    'tooltipstring',['Select the number of DFT points' 10 ...
    'If ''Auto'' is chosen, then nfft = 2^nextpow(length(timeWindow))']);

% Time window
SP_timeWin_text = uicontrol('style','text','Tag','SP_timeWin_text','units','normalized','position',[.005 .5370 .06 .03],...
    'string','TimeWindow [s]','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off',...
    'backgroundcolor',[.8 .8 .8]);
SP_timeWin_value = uicontrol('style','edit','Tag','SP_timeWin_value','units','normalized','position',[.065 .5370 .06 .03],...
    'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off',...
    'tooltipstring','Express time window in seconds. The code will convert it in samples.');

% Window tapering
SP_taperWin_text = uicontrol('style','text','Tag','SP_taperWin_text','units','normalized','position',[.005 .5050 .06 .03],...
    'string','Tapering','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off');
SP_taperWin_listbox = uicontrol('style','popupmenu','Tag','SP_taperWin_listbox','units','normalized','position',[.065 .5040 .06 .03],...
    'string',{'hamming','hann','kaiser','rectwin','tukeywin'},'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off');


% winOverlap
SP_Overlap_text = uicontrol('style','text','Tag','SP_Overlap_text','units','normalized','position',[.005 .4730 .06 .03],...
    'string','Overlap [%]','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off',...
    'backgroundcolor',[.8 .8 .8]);
SP_Overlap_value = uicontrol('style','edit','tag','SP_Overlap_value','units','normalized','position',[.065 .4730 .06 .03],...
    'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off');

% Switch plot to dB
SP_dBPlot_text = uicontrol('style','text','Tag','SP_dBPlot_text','units','normalized','position',[.005 .4410 .06 .03],...
    'string','Plot in dB','horizontalalignment','center','fontunits','normalized','fontsize',.5,'backgroundcolor',[.8 .8 .8]);
SP_dBPlot_value = uicontrol('style','popupmenu','tag','SP_dBPlot_value','units','normalized','position',[.065 .439 .06 .031],...
    'String',{'no';'yes'},'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'Tooltip','If yes is selected the result of the analysis will be plot in dB.','Callback',@(numfld,event) updateChanges);

% movMean spectrum
SP_movMean_text = uicontrol('style','text','Tag','SP_movMean_text','units','normalized','position',[.005 .4090 .06 .03],...
    'string','Mean spectrum','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','on',...
    'backgroundcolor',[.8 .8 .8]);
SP_movMean_value = uicontrol('style','edit','tag','SP_movMean_value','units','normalized','position',[.065 .4090 .06 .03],...
    'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','on','String','no','Tooltip',...
    ['Write no if you do not want to compute the average spectrum' 10 'Set the parameter (number) to compute the moving average using movmean function']);


%% Plot settings ----------------------------------------------------------
uicontrol('style','text','units','normalized','position',[.005 .3620 .12 .03],...
    'string',' Plot settings','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',[189/255 236/255 182/255]);

% X-axis linear/Log
SP_TypeAxesPlot_text = uicontrol('style','text','Tag','SP_TypeAxesPlot_text','units','normalized','position',[.005 .3270 .06 .03],...
    'string','Freq-Axis','horizontalalignment','center','fontunits','normalized','fontsize',.5,'backgroundcolor',[.8 .8 .8],'Enable','on');
SP_TypeAxesPlot_value = uicontrol('style','popupmenu','tag','SP_TypeAxesPlot_value','units','normalized','position',[.065 .325 .06 .031],...
    'String',{'Linear';'logarithmic'},'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','on','Callback',@(numfld,event) updateChanges);

% axes selection for plot
SP_AxesSelection_text = uicontrol('style','text','Tag','SP_AxesSelection_text','units','normalized','position',[.005 .2950 .06 .03],...
    'string','Select axis','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','on',...
    'backgroundcolor',[.8 .8 .8],'Tooltip','Select the axis where you want to plot the result of the analysis');
SP_AxesTop = uicontrol('style','checkbox','Tag','SP_AxesTop','units','normalized','position',[.075 .2950 .05 .03],...
    'string','Top','horizontalalignment','center','fontunits','normalized','fontsize',.5,'BackgroundColor','none',...
    'backgroundcolor',[0.9400 0.9400 0.9400],'Callback',@(numfld,event) removeDoubleCheckboxSelectionTop);
SP_AxesMiddle = uicontrol('style','checkbox','Tag','SP_AxesMiddle','units','normalized','position',[.075 .2630 .05 .03],...
    'string','Middle','horizontalalignment','center','fontunits','normalized','fontsize',.5,'BackgroundColor','none',...
    'backgroundcolor',[0.9400 0.9400 0.9400],'Callback',@(numfld,event) removeDoubleCheckboxSelectionMiddle);
SP_AxesBottom = uicontrol('style','checkbox','Tag','SP_AxesBottom','units','normalized','position',[.075 .2310 .05 .03],...
    'string','Bottom','horizontalalignment','center','fontunits','normalized','fontsize',.5,'BackgroundColor','none',...
    'backgroundcolor',[0.9400 0.9400 0.9400],'Callback',@(numfld,event) removeDoubleCheckboxSelectionBottom);

% Freqlim 
SP_SpectYLim_text = uicontrol('style','text','Tag','SP_SpectYLim_text','units','normalized','position',[.005 .199 .06 .03],...
    'string','FreqLim','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','on',...
    'backgroundcolor',[.8 .8 .8]);
SP_SpectYLim_value = uicontrol('style','edit','tag','SP_SpectYLim_value','units','normalized','position',[.065 .199 .06 .03],...
    'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','on','Tooltip','Set the YLim for the spectrogram plot',...
    'String',[num2str(0) ',' num2str(data_selected.fs/2)],'Callback',@(numfld,event) updateChanges);

% Colorbar limits for Spectrogram
SP_SpectColorbarLim_text = uicontrol('style','text','Tag','SP_SpectColorbarLim_text','units','normalized','position',[.005 .1670 .06 .03],...
    'string','Caxis','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off',...
    'backgroundcolor',[.8 .8 .8]);
SP_SpectColorbarLim_value = uicontrol('style','edit','tag','SP_SpectColorbarLim_value','units','normalized','position',[.065 .1670 .06 .03],...
    'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off','Tooltip','Set the colorbar limits for the spectrogram plot',...
    'Callback',@(numfld,event) updateChanges);

%% PUSHBUTTONS ------------------------------------------------------------
% Close spectral analysis procedure
uicontrol('style','pushbutton','units','normalized','position',[.005 0.1200 .12 .03],...
    'string','Close','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'callback','close(gcf)','tag','button_closeSpectAnal')

% Save Plot
% uicontrol('style','pushbutton','units','normalized','position',[.065 0.1200 .06 .03],...
%     'string','Save Plot','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
%     'backgroundcolor',[.7 .7 .7],'Enable','off','Tag','SpecAnal_saveplot')
% % Save Correlogram figure

% Compute Spectral Analysis
uicontrol('style','pushbutton','units','normalized','position',[0.005 0.0850 .12 .03],...
    'string','Compute','horizontalalignment','left','FontWeight','bold','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'Tag','SpecAnal_compute','Callback', @(numfld,event) ComputeSpectAnal)

%% Plot segnale caricato
ax1_spectralAnalysis = axes('Units','normalized','Position',[.185 .71 0.75 0.24]);
spectralAnalysis.ax1_spectralAnalysis = ax1_spectralAnalysis;
plot(ax1_spectralAnalysis,data_selected(1).timeAx,data_selected(1).signal,'Color','k');
% zoom(ax1_spectralAnalysis,'on');
ax1_spectralAnalysis.Toolbar.Visible = 'on';
xlabel('Time');
if strcmp(data_selected.name(1:3),'Dec')
    ylabel('m/s')
else
ylabel('Signal not deconvolved','Color','r');
end

grid on;
grid minor;
datetickzoom;
xlim([data_selected.timeAx(1) data_selected.timeAx(end)]);

%% Creazione assi da richiamare
ax2_spectralAnalysis = axes('Units','normalized','Position',[.185 .39 0.75 0.24]);
spectralAnalysis.ax2_spectralAnalysis = ax2_spectralAnalysis;
set(ax2_spectralAnalysis,'visible','off')

ax3_spectralAnalysis = axes('Units','normalized','Position',[.185 .07 0.75 0.24]);
spectralAnalysis.ax3_spectralAnalysis = ax3_spectralAnalysis;
set(ax3_spectralAnalysis,'visible','off')

%% Aggiornamento checkbox per selezione asse su cui fare il plot
UpdateAxesCheckboxSelection
end


% Attiva in automatico il checkbox giusto
function UpdateAxesCheckboxSelection
global spectralAnalysis

mainSpectralAnalysisFig = spectralAnalysis.mainSpectralAnalysisFig;

ax1_spectralAnalysis = spectralAnalysis.ax1_spectralAnalysis;
ax2_spectralAnalysis = spectralAnalysis.ax2_spectralAnalysis;
ax3_spectralAnalysis = spectralAnalysis.ax3_spectralAnalysis;

%
listAxis = ['ax1_spectralAnalysis';'ax2_spectralAnalysis';'ax3_spectralAnalysis'];
for i = 1:size(listAxis,1)
    if isempty(get(ax1_spectralAnalysis,'Children'))
        set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesTop'),'value',1)
        set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesMiddle'),'value',0)
        set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesBottom'),'value',0)
        return
    end
    if isempty(get(ax2_spectralAnalysis,'Children'))
        set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesTop'),'value',0)
        set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesMiddle'),'value',1)
        set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesBottom'),'value',0)
        return
    end
    if isempty(get(ax3_spectralAnalysis,'Children'))
        set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesTop'),'value',0)
        set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesMiddle'),'value',0)
        set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesBottom'),'value',1)
        return
    end
end
end

% Rendi impossibile selezionare due assi contemporaneamente
function removeDoubleCheckboxSelectionTop
global spectralAnalysis

mainSpectralAnalysisFig = spectralAnalysis.mainSpectralAnalysisFig;
set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesTop'),'value',1)
set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesMiddle'),'value',0)
set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesBottom'),'value',0)

%% attiva possibilità modifica colorbar spettrogramma
% Asse selezionato
if get(findobj(mainSpectralAnalysisFig,'tag','SP_AxesTop'),'value') == 1
    currentAxes = spectralAnalysis.ax1_spectralAnalysis;
    axes(currentAxes);
elseif get(findobj(mainSpectralAnalysisFig,'tag','SP_AxesMiddle'),'value') == 1
    currentAxes = spectralAnalysis.ax2_spectralAnalysis;
    axes(currentAxes);
elseif get(findobj(mainSpectralAnalysisFig,'tag','SP_AxesBottom'),'value') == 1
    currentAxes = spectralAnalysis.ax3_spectralAnalysis;
    axes(currentAxes);
end


if strcmp(currentAxes.Tag,'spectrogramAxes_plot')
    set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_text'),'enable','on');
    set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_value'),'enable','on');
else
    set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_text'),'enable','off');
    set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_value'),'enable','off');
end
end
function removeDoubleCheckboxSelectionMiddle
global spectralAnalysis

mainSpectralAnalysisFig = spectralAnalysis.mainSpectralAnalysisFig;
set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesTop'),'value',0)
set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesMiddle'),'value',1)
set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesBottom'),'value',0)

%% attiva possibilità modifica colorbar spettrogramma
% Asse selezionato
if get(findobj(mainSpectralAnalysisFig,'tag','SP_AxesTop'),'value') == 1
    currentAxes = spectralAnalysis.ax1_spectralAnalysis;
    axes(currentAxes);
elseif get(findobj(mainSpectralAnalysisFig,'tag','SP_AxesMiddle'),'value') == 1
    currentAxes = spectralAnalysis.ax2_spectralAnalysis;
    axes(currentAxes);
elseif get(findobj(mainSpectralAnalysisFig,'tag','SP_AxesBottom'),'value') == 1
    currentAxes = spectralAnalysis.ax3_spectralAnalysis;
    axes(currentAxes);
end


if strcmp(currentAxes.Tag,'spectrogramAxes_plot')
    set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_text'),'enable','on');
    set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_value'),'enable','on');
else
    set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_text'),'enable','off');
    set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_value'),'enable','off');
end
end
function removeDoubleCheckboxSelectionBottom
global spectralAnalysis

mainSpectralAnalysisFig = spectralAnalysis.mainSpectralAnalysisFig;
set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesTop'),'value',0)
set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesMiddle'),'value',0)
set(findobj(mainSpectralAnalysisFig,'tag','SP_AxesBottom'),'value',1)

%% attiva possibilità modifica colorbar spettrogramma
% Asse selezionato
if get(findobj(mainSpectralAnalysisFig,'tag','SP_AxesTop'),'value') == 1
    currentAxes = spectralAnalysis.ax1_spectralAnalysis;
    axes(currentAxes);
elseif get(findobj(mainSpectralAnalysisFig,'tag','SP_AxesMiddle'),'value') == 1
    currentAxes = spectralAnalysis.ax2_spectralAnalysis;
    axes(currentAxes);
elseif get(findobj(mainSpectralAnalysisFig,'tag','SP_AxesBottom'),'value') == 1
    currentAxes = spectralAnalysis.ax3_spectralAnalysis;
    axes(currentAxes);
end


if strcmp(currentAxes.Tag,'spectrogramAxes_plot')
    set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_text'),'enable','on');
    set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_value'),'enable','on');
else
    set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_text'),'enable','off');
    set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_value'),'enable','off');
end
end


function ComputeSpectAnal
global spectralAnalysis
mainSpectralAnalysisFig = spectralAnalysis.mainSpectralAnalysisFig;

data_selected = spectralAnalysis.data_selected;
segnale = data_selected.signal;

%% Get parameters from MainFigure
SP_nfft_value = get(findobj(mainSpectralAnalysisFig,'tag','SP_nfft_value'),'string');
if isempty(SP_nfft_value)
    beep
    h=msgbox('You must set the Nfft before proceding!','Update','error');
    return
end
SP_timeWin_value = get(findobj(mainSpectralAnalysisFig,'tag','SP_timeWin_value'),'string');
SP_taperWin_listbox = get(findobj(mainSpectralAnalysisFig,'tag','SP_taperWin_listbox'),'string');
SP_taperWin_value = get(findobj(mainSpectralAnalysisFig,'tag','SP_taperWin_listbox'),'value');
SP_Overlap_value = get(findobj(mainSpectralAnalysisFig,'tag','SP_Overlap_value'),'string');
SP_movMean_value =  get(findobj(mainSpectralAnalysisFig,'tag','SP_movMean_value'),'string');
SP_dBPlot_listbox = get(findobj(mainSpectralAnalysisFig,'tag','SP_dBPlot_value'),'string');
SP_dBPlot_value = get(findobj(mainSpectralAnalysisFig,'tag','SP_dBPlot_value'),'value');
dbPlot = SP_dBPlot_listbox{SP_dBPlot_value};

%% Scelta del metodo
listOfMethods = get(findobj(mainSpectralAnalysisFig,'tag','SP_method_listbox'),'string');
chosenMethod = get(findobj(mainSpectralAnalysisFig,'tag','SP_method_listbox'),'value');
chosenMethod = listOfMethods(chosenMethod); %Metodo scelto per effettuare analisi spettrale

%% Get Nfft (Number of samples) for spectral analysis computation
switch char(chosenMethod)
    
    case 'Amp. Spectrum'
        if strcmpi(SP_nfft_value,'auto')
            nfft = 2^nextpow2(length(segnale))
            if nextpow2(length(segnale)) > 14
                %%% Attenzione Nfft molto grande, vuoi continuare?
                promptMessage = sprintf(['You are chosing Nfft =2^' num2str(nextpow2(length(segnale))) '. If the signal is very long I would suggest to decrease Nfft to save time in the computation. Do you want to quit and change Nfft?']);
                button = questdlg(promptMessage, 'No, Continue', 'No, Continue', 'Quit', 'Quit');
                if strcmpi(button, 'Quit')
                    return; % Or break or continue
                end
                %%%
            end
        else
            nfft = str2num(SP_nfft_value);
        end
        
    case 'Phase Spectrum'
        if strcmpi(SP_nfft_value,'auto')
            nfft = 2^nextpow2(length(segnale))
            if nextpow2(length(segnale)) > 14
                %%% Attenzione Nfft molto grande, vuoi continuare?
                promptMessage = sprintf(['You are chosing Nfft =2^' num2str(nextpow2(length(segnale))) '. If the signal is very long I would suggest to decrease Nfft to save time in the computation. Do you want to quit and change Nfft?']);
                button = questdlg(promptMessage, 'No, Continue', 'No, Continue', 'Quit', 'Quit');
                if strcmpi(button, 'Quit')
                    return; % Or break or continue
                end
                %%%
            end
        else
            nfft = str2num(SP_nfft_value);
        end
        
    case 'Periodogram'
        if strcmpi(SP_nfft_value,'auto')
            nfft = 2^nextpow2(length(segnale))
            if nextpow2(length(segnale)) > 14
                %%% Attenzione Nfft molto grande, vuoi continuare?
                promptMessage = sprintf(['You are chosing Nfft =2^' num2str(nextpow2(length(segnale))) '. If the signal is very long I would suggest to decrease Nfft to save time in the computation. Do you want to quit and change Nfft?']);
                button = questdlg(promptMessage, 'No, Continue', 'No, Continue', 'Quit', 'Quit');
                if strcmpi(button, 'Quit')
                    return; % Or break or continue
                end
                %%%
            end
        else
            nfft = str2num(SP_nfft_value);
        end
        
    case 'Welch'
        Fs = data_selected.fs;
        tWindow = str2num(SP_timeWin_value);
        ts = 1/Fs;
        timeWindowS = round(tWindow/ts);
        
        if strcmpi(SP_nfft_value,'auto')
            nfft = 2^nextpow2(timeWindowS)
            if nextpow2(timeWindowS) > 14
                %%% Attenzione Nfft molto grande, vuoi continuare?
                promptMessage = sprintf(['You are chosing Nfft =2^' num2str(nextpow2(timeWindowS)) '. If the signal is very long I would suggest to decrease Nfft to save time in the computation. Do you want to quit and change Nfft?']);
                button = questdlg(promptMessage, 'No, Continue', 'No, Continue', 'Quit', 'Quit');
                if strcmpi(button, 'Quit')
                    return; % Or break or continue
                end
                %%%
            end
        else
            nfft = str2num(SP_nfft_value);
        end
         
         
    case 'Multitaper'
        errordlg('Function not yet implemented')
        return
        
    case 'Spectrogram'
        Fs = data_selected.fs;
        tWindow = str2num(SP_timeWin_value);
        ts = 1/Fs;
        timeWindowS = round(tWindow/ts);
        
        if strcmpi(SP_nfft_value,'auto')
            nfft = 2^nextpow2(timeWindowS)
            if nextpow2(timeWindowS) > 14
                %%% Attenzione Nfft molto grande, vuoi continuare?
                promptMessage = sprintf(['You are chosing Nfft =2^' num2str(nextpow2(timeWindowS)) '. If the signal is very long I would suggest to decrease Nfft to save time in the computation. Do you want to quit and change Nfft?']);
                button = questdlg(promptMessage, 'No, Continue', 'No, Continue', 'Quit', 'Quit');
                if strcmpi(button, 'Quit')
                    return; % Or break or continue
                end
                %%%
            end
        else
            nfft = str2num(SP_nfft_value);
        end
        
    case 'Stacked spectrogram'
        errordlg('Function not yet implemented')
        return
end


%% scegli asse su cui fare il plot
if get(findobj(mainSpectralAnalysisFig,'tag','SP_AxesTop'),'value') == 1
    currentAxes = spectralAnalysis.ax1_spectralAnalysis;
    axes(currentAxes);
elseif get(findobj(mainSpectralAnalysisFig,'tag','SP_AxesMiddle'),'value') == 1
    currentAxes = spectralAnalysis.ax2_spectralAnalysis;
    axes(currentAxes);
elseif get(findobj(mainSpectralAnalysisFig,'tag','SP_AxesBottom'),'value') == 1
    currentAxes = spectralAnalysis.ax3_spectralAnalysis;
    axes(currentAxes);
end
% Attivo toolbar per fare zoom
currentAxes.Toolbar.Visible = 'on';
    
% se esiste già un plot su questo asse eliminalo
if ~isempty(get(currentAxes, 'children'))
    delete(get(currentAxes, 'children'))
end

% se esiste la colorbar cancellala
delete(currentAxes.Colorbar)

% Rendi visibile l'asse perchè magari è stato reso invisibile dal cut o dal filtro
set(currentAxes,'visible','on')

%% Spectral analysis computation

switch char(chosenMethod)
    
    case 'Amp. Spectrum'
        %%%%%%%%%%% Setting parameters for spectral analysis  %%%%%%%%%%%%%
        % Frequency axis
        Fs = data_selected.fs;
        df = Fs/nfft;
        freqAx = 0:df:(nfft/2-1)*df;
        
        %%%%%%%%%%%%%%%%%%%%%%  Computation %%%%%%%%%%%%%%%%%%%%%%%%%%%
        result = abs(fft(segnale,nfft));
        result(nfft/2 + 1:end,:) = [];
        
        %%%%%%%%%%%%%%%%%%%%%%      Plot      %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if strcmpi(dbPlot,'yes')
            plot(currentAxes,freqAx,20*log10(result),'Color',[160/255 160/255 160/255]); %Plot in dB
            ylabel('dB','Color','k');
        else
            plot(currentAxes,freqAx,result,'Color',[160/255 160/255 160/255]);
            if strcmp(data_selected.name(1:3),'Dec')
                ylabel('m/s')
            else
                ylabel('Signal not deconvolved','Color','r');
            end
        end


        %%%%%%%%%%%%%%%%%%       Plot average      %%%%%%%%%%%%%%%%%%%%%%%
        if ~strcmpi(SP_movMean_value,'no')
            hold on
            movMeanParameter = str2num(SP_movMean_value);
            if strcmpi(dbPlot,'yes')
                plot(currentAxes,freqAx,movmean(20*log10(result),movMeanParameter),'Color','k')
            else
                plot(currentAxes,freqAx,movmean(result,movMeanParameter),'Color','k')
                if strcmp(data_selected.name(1:3),'Dec')
                    ylabel('m/s')
                else
                    ylabel('Signal not deconvolved','Color','r');
                end
            end
        end
        
        %%% Plot settings
        xlabel('Frequency [Hz]');
        set(currentAxes,'xminorgrid','on','yminorgrid','on')
        set(currentAxes,'xgrid','on','ygrid','on')
        
        %%% Aggiorna asse su cui fare il nuovo plot
        UpdateAxesCheckboxSelection
          
    case 'Phase Spectrum'
        %%%%%%%%%%% Setting parameters for spectral analysis  %%%%%%%%%%%%%
        Fs = data_selected.fs;
        df = Fs/nfft;
        freqAx = 0:df:(nfft/2-1)*df;
        
        %%%%%%%%%%%%%%%%%%%%%%  Computation %%%%%%%%%%%%%%%%%%%%%%%%%%%
        result = angle(fft(segnale,nfft));
        result(nfft/2 + 1:end,:) = [];
        
        %%%%%%%%%%%%%%%%%%%%%%      Plot        %%%%%%%%%%%%%%%%%%%%%%%%%%
        plot(currentAxes,freqAx,unwrap(result),'k');
        
        %%% Plot settings
        xlabel('Frequency [Hz]');
        ylabel('Unwrapped Phase','Color','k');
        set(currentAxes,'xminorgrid','on','yminorgrid','on')
        set(currentAxes,'xgrid','on','ygrid','on')
        
        %%% Aggiorna asse su cui fare il nuovo plot
        UpdateAxesCheckboxSelection
          
    case 'Periodogram'
        %%%%%%%%%%% Setting parameters for spectral analysis  %%%%%%%%%%%%%
        %Tapering window
        tapeWin = SP_taperWin_listbox{SP_taperWin_value};
        %Fs
        Fs = data_selected.fs;
        
        %%%%%%%%%%%%%%%%%%%%%%  Computation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        eval(['[pxx,f] = periodogram(segnale,' tapeWin '(length(segnale)),nfft,Fs);'])
        
        %%%%%%%%%%%%%%%%%%%%%%      Plot      %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if strcmpi(dbPlot,'yes')
            plot(currentAxes,f,10*log10(pxx),'Color',[160/255 160/255 160/255]);
            ylabel('dB','Color','k');
        else
            plot(currentAxes,f,pxx,'Color',[160/255 160/255 160/255]);
            if strcmp(data_selected.name(1:3),'Dec')
                ylabel('(m/s)^2')
            else
                ylabel('Signal not deconvolved','Color','r');
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%    Plot average     %%%%%%%%%%%%%%%%%%%%%%%%%
        if ~strcmpi(SP_movMean_value,'no')
            hold on
            movMeanParameter = str2num(SP_movMean_value);
            if strcmpi(dbPlot,'yes')
                plot(currentAxes,f,10*log10(movmean(pxx,movMeanParameter)),'Color','k')
                ylabel('dB','Color','k');
            else
                plot(currentAxes,f,movmean(pxx,movMeanParameter),'Color','k')
                if strcmp(data_selected.name(1:3),'Dec')
                    ylabel('(m/s)^2')
                else
                    ylabel('Signal not deconvolved','Color','r');
                end
            end
        end
        
        %%% Plot settings
        xlabel('Frequency [Hz]');
        set(currentAxes,'xminorgrid','on','yminorgrid','on')
        set(currentAxes,'xgrid','on','ygrid','on')
        
        %%% Aggiorna asse su cui fare il nuovo plot
        UpdateAxesCheckboxSelection
        
    case 'Welch'
        %%%%%% Controlla che tutti i parametri siano stati settati %%%%%%%%
        if  isempty(SP_timeWin_value) | isempty(SP_Overlap_value)
            beep
            h=msgbox('You must set TimeWindow and Overlap parameters before proceding!','Update','error');
            set(currentAxes,'visible','off')
            return
        end
        %%%%%%%%%%% Setting parameters for spectral analysis  %%%%%%%%%%%%%        
        %Fs
        Fs = data_selected.fs;
        
        % Data for Welch method
        tapeWin = SP_taperWin_listbox{SP_taperWin_value}
        tWindow = str2num(SP_timeWin_value);
        winOverlap = str2num(SP_Overlap_value);
        ts = 1/Fs;
        timeWindowS = round(tWindow/ts);
        overlapS = round((winOverlap/100)*timeWindowS);
        
        %%%%%%%%%%%%%%%%%%%%%%  Computation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        eval(['[pxx,f] = pwelch(segnale,' tapeWin '(timeWindowS),overlapS,nfft,Fs);'])

        %%%%%%%%%%%%%%%%%%%%%%      Plot      %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if strcmpi(dbPlot,'yes')
            plot(currentAxes,f,10*log10(pxx),'Color',[160/255 160/255 160/255]);
            ylabel('dB','Color','k');
        else
            plot(currentAxes,f,pxx,'Color',[160/255 160/255 160/255]);
            if strcmp(data_selected.name(1:3),'Dec')
                ylabel('(m/s)^2')
            else
                ylabel('Signal not deconvolved','Color','r');
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%    Plot average     %%%%%%%%%%%%%%%%%%%%%%%%%
        %%% ATTIVARE LE RIGHE SOTTO SE SI VUOLE ANCHE IL WELCH MEDIO MA NON 
        %%% PENSO ABBIA MOLTO SENSO
        
%         if ~strcmpi(SP_movMean_value,'no')
%             hold on
%             movMeanParameter = str2num(SP_movMean_value);
%             if strcmpi(dbPlot,'yes')
%                 plot(currentAxes,f,10*log10(movmean(pxx,movMeanParameter)),'Color','k')
%                 ylabel('dB','Color','k');
%             else
%                 plot(currentAxes,f,movmean(pxx,movMeanParameter),'Color','k')
%                 ylabel('Correggere','Color','r');
%             end
%         end
        
        %%% Plot settings
        xlabel('Frequency [Hz]');
        set(currentAxes,'xminorgrid','on','yminorgrid','on')
        set(currentAxes,'xgrid','on','ygrid','on')
        
        %%% Aggiorna asse su cui fare il nuovo plot
        UpdateAxesCheckboxSelection
   
    case 'Multitaper'
        errordlg('Function not yet implemented')
        return
        
    case 'Spectrogram'
        %%%%%% Controlla che tutti i parametri siano stati settati %%%%%%%%
        if  isempty(SP_timeWin_value) | isempty(SP_Overlap_value)
            beep
            h=msgbox('You must set TimeWindow and Overlap parameters before proceding!','Update','error');
            set(currentAxes,'visible','off')
            return
        end
        %%%%%%%%%%% Setting parameters for spectral analysis  %%%%%%%%%%%%%
        %Fs
        Fs = data_selected.fs;
        
        % Data for spectrogam method
        tapeWin = SP_taperWin_listbox{SP_taperWin_value}
        tWindow = str2num(SP_timeWin_value);
        winOverlap = str2num(SP_Overlap_value);
        ts = 1/Fs;
        timeWindowS = round(tWindow/ts);
        overlapS = round((winOverlap/100)*timeWindowS);
        
        %%%%%%%%%%%%%%%%%%%%%%  Computation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        eval(['[s,f,t] = spectrogram(segnale,' tapeWin '(timeWindowS),overlapS,nfft,Fs);']);
        
        %%%%%%%%%%%%%%%%%%%%%%      Plot      %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Creazione datetime vector
        timeAx = data_selected.timeAx;
        timeAx = datetime(timeAx,'ConvertFrom','datenum');
        timeAx = linspace(timeAx(1),timeAx(end),length(t));
        
        if strcmpi(dbPlot,'yes')
            surf(currentAxes,timeAx,f,20*log10(abs(s)),'EdgeColor','none');
            view([0 90])
            xlim([timeAx(1) timeAx(end)])
            % Colorbar
            posizioneAsse = currentAxes.Position;
            cbarCorrelogram = colorbar(currentAxes,'Position',[0.94 posizioneAsse(1,2) 0.01 0.24]);
            cbarCorrelogram.Label.String = '[dB]'
        else
            surf(currentAxes,timeAx,f,abs(s),'EdgeColor','none');
            view([0 90])
            xlim([timeAx(1) timeAx(end)])
            % Colorbar
            posizioneAsse = currentAxes.Position;
            cbarCorrelogram = colorbar(currentAxes,'Position',[0.94 posizioneAsse(1,2) 0.01 0.24]);
            %
            if strcmp(data_selected.name(1:3),'Dec')
                cbarCorrelogram.Label.String = 'm/s';
            else
                cbarCorrelogram.Label.String = '[Signal not deconvolved]';
                cbarCorrelogram.Label.Color = 'r';
            end
        end
        set(gca,'tag','spectrogramAxes_plot')
        spectralAnalysis.cbarCorrelogram = cbarCorrelogram;
        
        %%% Plot settings
        % Aggiornamento valori per modifica Ylim e correlogramLim
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectYLim_value'),'string',[num2str(currentAxes.YLim(1)) ',' num2str(currentAxes.YLim(2))]);
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_value'),'string',[num2str(cbarCorrelogram.Limits(1)) ',' num2str(cbarCorrelogram.Limits(2))]);
                
        % Per fare vedere i bordi della figura:
        box on
        currentAxes.Layer = 'Top';
        
        ylabel('Frequency [Hz]','Color','k');
        xlabel('Time');
        
        
        %%% Aggiorna asse su cui fare il nuovo plot
        UpdateAxesCheckboxSelection
        
    case 'Stacked spectrogram'
        errordlg('Function not yet implemented')
        return
end

end

function activationRequiredParameters
global spectralAnalysis
mainSpectralAnalysisFig = spectralAnalysis.mainSpectralAnalysisFig;

%% Scelta del metodo
listOfMethods = get(findobj(mainSpectralAnalysisFig,'tag','SP_method_listbox'),'string');
chosenMethod = get(findobj(mainSpectralAnalysisFig,'tag','SP_method_listbox'),'value');
chosenMethod = listOfMethods(chosenMethod); %Metodo scelto per effettuare analisi spettrale

%% Disattivo parametri non necessari per Spectral analysis
switch char(chosenMethod)
    case 'Amp. Spectrum'
        set(findobj(mainSpectralAnalysisFig,'tag','SP_timeWin_text'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_timeWin_value'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_taperWin_text'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_taperWin_listbox'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_Overlap_text'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_Overlap_value'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_movMean_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_movMean_value'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_dBPlot_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_dBPlot_value'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectYLim_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectYLim_value'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_text'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_value'),'enable','off');
                
        
    case 'Phase Spectrum'
        set(findobj(mainSpectralAnalysisFig,'tag','SP_timeWin_text'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_timeWin_value'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_taperWin_text'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_taperWin_listbox'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_Overlap_text'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_Overlap_value'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_movMean_text'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_movMean_value'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_dBPlot_text'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_dBPlot_value'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectYLim_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectYLim_value'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_text'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_value'),'enable','off');
        
    case 'Periodogram'
        set(findobj(mainSpectralAnalysisFig,'tag','SP_timeWin_text'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_timeWin_value'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_taperWin_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_taperWin_listbox'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_Overlap_text'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_Overlap_value'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_movMean_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_movMean_value'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_dBPlot_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_dBPlot_value'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectYLim_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectYLim_value'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_text'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_value'),'enable','off');
        
    case 'Welch'
        set(findobj(mainSpectralAnalysisFig,'tag','SP_timeWin_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_timeWin_value'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_taperWin_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_taperWin_listbox'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_Overlap_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_Overlap_value'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_dBPlot_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_dBPlot_value'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectYLim_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectYLim_value'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_text'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_value'),'enable','off');
        
    case 'Multitaper'
        
    case 'Spectrogram'
        set(findobj(mainSpectralAnalysisFig,'tag','SP_timeWin_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_timeWin_value'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_taperWin_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_taperWin_listbox'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_Overlap_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_Overlap_value'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_dBPlot_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_dBPlot_value'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_movMean_text'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_movMean_value'),'enable','off');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectYLim_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectYLim_value'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_text'),'enable','on');
        set(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_value'),'enable','on');
        
    case 'Stacked spectrogram'
end

end


function updateChanges
global spectralAnalysis
mainSpectralAnalysisFig = spectralAnalysis.mainSpectralAnalysisFig;
% Asse selezionato
if get(findobj(mainSpectralAnalysisFig,'tag','SP_AxesTop'),'value') == 1
    currentAxes = spectralAnalysis.ax1_spectralAnalysis;
    axes(currentAxes);
elseif get(findobj(mainSpectralAnalysisFig,'tag','SP_AxesMiddle'),'value') == 1
    currentAxes = spectralAnalysis.ax2_spectralAnalysis;
    axes(currentAxes);
elseif get(findobj(mainSpectralAnalysisFig,'tag','SP_AxesBottom'),'value') == 1
    currentAxes = spectralAnalysis.ax3_spectralAnalysis;
    axes(currentAxes);
end

%% Aggiorno caxis-colorbar spectrogram
% for i = 1:length(allAxesInFigure)
%     currentAxes = allAxesInFigure(i);
    if strcmp(currentAxes.Tag,'spectrogramAxes_plot')
        CAxisSpectrogram = get(findobj(mainSpectralAnalysisFig,'tag','SP_SpectColorbarLim_value'),'string');
        cbarCorrelogram = spectralAnalysis.cbarCorrelogram;
        
        currentAxes.CLim = str2num(CAxisSpectrogram);
        cbarCorrelogram.Limits = str2num(CAxisSpectrogram); %Aggiorna colorbar
    end
% end

% ricarico tutti gli assi della figure
% allAxesInFigure = findall(mainSpectralAnalysisFig,'type','axes');

%% Aggiorno asse frequenze Lineare o Logaritmico
% controlla qual'è l'asse delle frequenze
optAsseFreq = get(findobj(mainSpectralAnalysisFig,'tag','SP_TypeAxesPlot_value'),'string');
scletaAsseFreq = get(findobj(mainSpectralAnalysisFig,'tag','SP_TypeAxesPlot_value'),'value');
tipoAsseFreq = optAsseFreq(scletaAsseFreq);

% Se logaritmico
% for i = 1:length(allAxesInFigure)
% currentAxes = allAxesInFigure(i);    
if strcmp(currentAxes.YLabel.String,'Frequency [Hz]') && strcmp(tipoAsseFreq,'logarithmic')
    currentAxes.YScale = 'log';
elseif strcmp(currentAxes.XLabel.String,'Frequency [Hz]') && strcmp(tipoAsseFreq,'logarithmic')
    currentAxes.XScale = 'log';
% Se lineare    
elseif strcmp(currentAxes.YLabel.String,'Frequency [Hz]') && strcmp(tipoAsseFreq,'Linear')
    currentAxes.YScale = 'linear';
elseif strcmp(currentAxes.XLabel.String,'Frequency [Hz]') && strcmp(tipoAsseFreq,'Linear')
    currentAxes.XScale = 'linear';    
end
% end

%% Aggiorno Ylim 
YlimValue = get(findobj(mainSpectralAnalysisFig,'tag','SP_SpectYLim_value'),'string');
% for i = 1:length(allAxesInFigure)
% currentAxes = allAxesInFigure(i);    
if strcmp(currentAxes.YLabel.String,'Frequency [Hz]') 
    currentAxes.YLim = str2num(YlimValue);
elseif strcmp(currentAxes.XLabel.String,'Frequency [Hz]') 
    currentAxes.XLim = str2num(YlimValue);
end
% end

end

