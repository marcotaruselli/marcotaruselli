function CrossCorr_Analysis_MAIN(data_processing)
global utilities
global mainCrossFig
global data_selected
global crosscorr
global dataforPlotVideoCrossCorr

%% Controlli iniziali
% 1) Prima di applicare la funzione controlla che qualche segnale sia stato selezionato!
if logical(evalin('base','~exist(''selected'')')) % Se non sono stati selezionati termina la funzione con questo messaggio di errore
    beep
    h=msgbox('No data have been selected! Please select data from "Signal for processing" list!','Update','error');
    return
else selected = evalin('base','selected'); % Se esiste carica la variabile selected dal base-workspace
end

% 2) Seleziono i dati selezionati dalla tabella in MainPassive 
data_selected = data_processing(selected,1); %Dati selezionati da tabella "Signal for processing"

% 2.1 Check if only two signals have been selected
if size(data_selected,1) ~= 2
    beep
    waitfor(msgbox('You must select two signals!','Update','error'))
    return
end

% 2.2 Check if the vertical component have been selected
comp = ["East", "North", "Vertical"]';
for i = 1:size(data_selected,1)
    eval(['data_selected_comp(' num2str(i) ',:) = "' data_selected(i).Comp '";']);
end
check = strcmp(comp(3,1),data_selected_comp);
if ~all(check)
    waitfor(msgbox('You SHOULD select only vertical components to improve the final result!','Update','warn'))
end 

% % 2.3 Check if the two selected signals have the same component
% if ~isequal(data_selected(1).Comp, data_selected(2).Comp)
%     beep
%     waitfor(msgbox({'Same components MUST be selected!'},'Update','error'))
%     return
% end

% % 2.4 Check if two different stations have been selected
% if isequal(data_selected(1).stn, data_selected(2).stn)
%     beep
%     waitfor(msgbox({'You MUST select signals which belong to different stations!'},'Update','error'))
%     return
% end


% 2.5 Check if the two components have the same time length
if ~isequal(length(data_selected(1).signal),length(data_selected(2).signal))
    beep
    waitfor(msgbox({'The two components must have the same length!'; 'Cut them before proceeding!'},'Update','error'))
    return
end



% 2.6 Check if the two selected signals have the same Fs
if ~isequal(data_selected(1).fs, data_selected(2).fs)
    beep
    waitfor(msgbox({'The signals MUST have the same sampling frequency!'},'Update','error'))
    return
end

%% SIGNALS INFO ------------------------------------------------
mainCrossFig = figure('units','normalized','outerposition',[0 0 1 1],'WindowState','maximized','toolbar','none','MenuBar','none',...
    'numbertitle','off','name','CROSS CORRELATION ANALYSIS');

% Disegno riquadri
aaa = annotation(mainCrossFig,'line',[0.13 0.995],[0.988 0.988],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga sopra orizzontale
bbb = annotation(mainCrossFig,'line',[0.13 0.13],[0.007 0.988],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga sx verticale
ccc = annotation(mainCrossFig,'line',[0.995 0.995],[0.007 0.988],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga dx verticale
ddd = annotation(mainCrossFig,'line',[0.13 0.995],[0.007 0.007],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga sotto orizzontale
eee = annotation(mainCrossFig,'line',[0.527 0.527],[0.007 0.988],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga dx verticale
fff = annotation(mainCrossFig,'line',[0.527 0.995],[0.485 0.485],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga dx verticale


% Cross Correlation: SIGNALS INFO ------------------------------------------------
uicontrol('style','text','units','normalized','position',[.005 .96 .12 .03],...
    'string','Signals info','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',[0.6000    0.8000    1.0000]);

% STN couple 
uicontrol('style','text','units','normalized','position',[.005 .925 .06 .03],...
    'string','STN couple','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','text','units','normalized','position',[.065 .925 .06 .03],'tag','Signals_info',...
    'string',[data_selected(1).stn '_'  data_selected(2).stn],'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5);

% Selected Component 
uicontrol('style','text','units','normalized','position',[.005 .893 .06 .03],...
    'string','Component','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','text','units','normalized','position',[.065 .893 .06 .03],'tag','Signals_info',...
    'string',data_selected(1).Comp,'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5);

% Fs - sampling frequency
uicontrol('style','text','units','normalized','position',[.005 .861 .06 .03],...
    'string','Fs','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','text','units','normalized','position',[.065 .861 .06 .03],'tag','Signals_info',...
    'string',data_selected(1).fs,'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5);

% Start Time 
uicontrol('style','text','units','normalized','position',[.005 .829 .06 .03],...
    'string','Start Time','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','text','units','normalized','position',[.065 .829 .06 .03],'tag','Signals_info',...
    'string',datestr(data_selected(1).timeAx(1)),'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.4);

% End Time 
uicontrol('style','text','units','normalized','position',[.005 .797 .06 .03],...
    'string','End Time','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','text','units','normalized','position',[.065 .797 .06 .03],'tag','Signals_info',...
    'string',datestr(data_selected(1).timeAx(end)),'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.4);

% Title that will be used for correlogram and dV/V plots
crosscorr.correlogramtitle = [data_selected(1).stn '-'  data_selected(2).stn '| Comp.' data_selected(1).Comp];
dvvtitle = ['dV/V ' data_selected(1).stn ' '  data_selected(2).stn ' comp' data_selected(1).Comp];
crosscorr.dvvtitle = dvvtitle;
dataforPlotVideoCrossCorr.dvvtitle = dvvtitle;
%% SIGNALS PRE_PROCESSING --------------------------------------------------------
uicontrol('style','text','units','normalized','position',[.005 .750 .12 .03],...
    'string','Signals Pre-processing','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',[0.6000    0.8000    1.0000]);

% Remove Mean 
uicontrol('style','text','units','normalized','position',[.005 .715 .06 .03],...
    'string','Remove mean','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','checkbox','units','normalized','position',[.080 .715 .04 .03],'tag','removeMean',...
    'string','Yes','Value', 0,'horizontalalignment','center','fontunits','normalized','fontsize',.5);

% Detrend
uicontrol('style','text','units','normalized','position',[.005 .6830 .06 .03],...
    'string','Detrend','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','checkbox','units','normalized','position',[.080 .6830 .04 .03],'tag','detrend',...
    'string','Yes','Value', 0,'horizontalalignment','center','fontunits','normalized','fontsize',.5);

%% Cross-correlation parameters --------------------------------------------------------
uicontrol('style','text','units','normalized','position',[.005 .6360 .12 .03],...
    'string','Cross-Correlation setting','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',[0.6000    0.8000    1.0000]);

% Time-length signals
uicontrol('style','text','units','normalized','position',[.005 .6010 .06 .03],...
    'string','Time length [m]','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','edit','units','normalized','position',[.065 .6010 .06 .03],'tag','timelength',...
    'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring',['Select the signals time-length to compute the cross-correlation. Time in minutes' 10 ...
    'If the chosen length does not return null reminder, a first part of the signal will be discarded.']);

% Weighting
uicontrol('style','text','units','normalized','position',[.005 .5690 .06 .03],...
    'string','Weighting','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);  
uicontrol('style','popupmenu','units','normalized','position',[.065 .5690 .04 .03],...
    'String',{'Time', 'Frequency', 'Both','None'},'value',2,...
    'horizontalalignment','left','fontunits','normalized','fontsize',.5,'Tag','Weighting',...
    'tooltipstring',['You can decide to compute the time-domain Weighting or' 10 ...
    'the Frequency-domain Weighting (whitening) or both together' 10 ...
    'When Time-domain Weighting or Both is selected, the signals are firstly high-pass filtered at 0.05Hz to improve the quality of this procedure'],...
    'Callback',@(hObject, eventdata) CrossCorr_WeightingActivation(hObject, eventdata));

% Maxlag
uicontrol('style','text','units','normalized','position',[.005 .5370 .06 .03],...
    'string','Maxlag [s]','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','edit','units','normalized','position',[.065 .5370 .06 .03],'tag','maxlag',...
    'backgroundcolor',[1 1 1],'String',10,'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring','Express maxlag in second. The code will convert it in samples.');

% Correlogram Filtering
uicontrol('style','text','units','normalized','position',[.005 .5050 .06 .03],...
    'string','Correl. Filter','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
filtercheck = uicontrol('style','checkbox','units','normalized','position',[.080 .5050 .04 .03],...
    'string','Yes','Value', 0,'horizontalalignment','left','fontunits','normalized','fontsize',.5,'Tag','filtercheck',...
    'TooltipString','NB You can either pre-filter the input signals or the correlogram. Filtering the correlogram is faster!',...
    'Callback',@(hObject, eventdata) CrossCorr_filteractivation(hObject, eventdata));
% Filter type
filtertype_text = uicontrol('style','text','units','normalized','position',[.005 .4730 .06 .03],'Enable','off',...
    'string','Filter type','horizontalalignment','left','fontunits','normalized','fontsize',.5,'Tag','filtertype_text',...
    'backgroundcolor',[.8 .8 .8]);
filtertype_checkbox = uicontrol('style','popupmenu','units','normalized','position',[.065 .4730 .06 .03],'Enable','off','tag','filter_type',...
    'string',{'Lowpass','Highpass','Bandpass','Dynamic'},'horizontalalignment','right','fontunits','normalized','fontsize',.5,'Tag','filtertype_checkbox',...
    'Tooltip',['Dynamic option allows you to compute the dV/V for different filtered correlograms and to compare all the dV/V in order to chose the correct frequency band (fig.4 paper Voison etall 2016).' 10 ...
    'Tips:' 10 ...
    '1) Compute firstly the dV/V in the BroadBand frequency in order to determined in which corr.wind you are able to "feel" the water variations;' 10 ...
    '2) Then use this Dynamic filter tool to inspect different frequency bands;' 10 ...    
    '3) Remember to set the Corr.win found out at step 1 of this list.' 10 ...
    'NB. If you select this option you cannot use the dynamic option in Corr. window'],...
    'Callback',@(hObject, eventdata) CrossCorr_filterUpdate(hObject, eventdata));
% Filter frequency
filterfreq_text = uicontrol('style','text','units','normalized','position',[.005 .4410 .06 .03],'Enable','off',...
    'string','Filter freq [Hz]','horizontalalignment','left','fontunits','normalized','fontsize',.5,'Tag','filterfreq_text',...
    'backgroundcolor',[.8 .8 .8]);
filterfreq = uicontrol('style','edit','units','normalized','position',[.065 .4410 .06 .03],'Enable','off','tag','filter_frequency',...
    'string','1','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Tag','filterfreq',...
    'tooltipstring','Indicate Fcut for Highpass/Lowpass or Fcut1,Fcut2 for Bandpass');

%% dV/V parameters --------------------------------------------------------
uicontrol('style','text','units','normalized','position',[.005 .3940 .12 .03],...
    'string','dV/V setting','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',[0.6000    0.8000    1.0000],'Enable','off','tag','dvv_Settings');

% Time-window
uicontrol('style','text','units','normalized','position',[.005 .3590 .06 .03],...
    'string','Corr. window','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off','Tag','dvv_corrwindow');
uicontrol('style','edit','units','normalized','position',[.065 .3590 .06 .03],'tag','dvv_corrwindowValue',...
    'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring',['Select the correlogram time window which will be used to compute the dV/V' 10 ...
    'you can set:' 10 ...
    'auto ==> the Corr. window is [-maxlag, maxlag]' 10 ...
    'es. -2,2 ==>  the Corr. window is [-2, 2]' 10 ...
    ' dynamic ==> is used to compute dV/V with moving corr. wind. When you click on dV/V Compute a new tab will open and you have to set the parameters'], ...
    'Enable','off',...
    'String','auto');

% Epsilon range
uicontrol('style','text','units','normalized','position',[.005 .3270 .06 .03],...
    'string','Epsilon','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off','Tag','dvv_Epsilon');
uicontrol('style','edit','units','normalized','position',[.065 .3270 .06 .03],'tag','dvv_EpsilonValue',...
    'backgroundcolor',[1 1 1],'String','-1e-1:1e-3:1e-1','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring','Range of epsilon values used in the stretching technique','Enable','off');

% Correlogram filter
uicontrol('style','text','units','normalized','position',[.005 .2950 .06 .03],...
    'string','Use filtered corr.','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off','Tag','dvv_corrfilter');
uicontrol('style','checkbox','units','normalized','position',[.08 .2950 .04 .03],'String','yes',...
    'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Tag','dvv_corrfilterCheck',...
    'Value',1,'tooltipstring','dV/V will be evaluated on the filtered correlogram','Enable','off');

% dV/V smoothing
uicontrol('style','text','units','normalized','position',[.005 .2630 .06 .03],...
    'string','dV/V smoothing','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off','Tag','dvv_smoothing');
uicontrol('style','checkbox','units','normalized','position',[.08 .2630 .04 .03],'String','yes',...
    'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Tag','dvv_smoothingValue',...
    'Value',1,'tooltipstring','Smoothdata Matlab function is used to smooth the computed dV/V. The movmean method with default moving window is used.','Enable','off');

% Getting Timezone
uicontrol('style','text','units','normalized','position',[.005 .231 .06 .03],'Enable','off',...
    'string','Timezone','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','Timezone_text');
uicontrol('style','edit','units','normalized','position',[.065 .231 .06 .03],'String','Europe/Rome',...
    'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'Enable','off','tooltipstring',['Select the time zone where you did collect the data.' 10 ...
    'This is used to convert timeAx from UTC to Local time' 10 'Check Timezone areas in Matlab website'],'tag','Timezone');
%% Import and plot Piezo data --------------------------------------------------------
uicontrol('style','text','units','normalized','position',[.005 .1840 .12 .03],...
    'string','Import Piezo Data','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',[0.6000    0.8000    1.0000],'Enable','off','Tag','piezo_data');

% Plot Piezometer data over dV/V
uicontrol('style','text','units','normalized','position',[.005 .1520 .06 .03],...
    'string','Plot Piezometers','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off','tag','piezo_plot');
uicontrol('style','checkbox','units','normalized','position',[.080 .1520 .04 .03],'tag','piezo_plotcheck',...
    'string','Yes','Value', 0,'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'TooltipString','Do you want to plot piezometers data over dV/V?',...
    'Callback',@(hObject, eventdata) PiezoPlot_activation(hObject, eventdata),'Enable','off');

% Select file with piezometer data
uicontrol('style','text','units','normalized','position',[.005 .12 .06 .03],...
    'string','Piezometer data','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off','Tag','piezo_select');
uicontrol('style','pushbutton','units','normalized','position',[.065 .12 .06 .03],'tag','piezo_selectButton',...
    'String','Select','backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring',['Select .csv file with the following format...' 10 ...
    'Date Piezodata' 10 '20/05/2018 00:00:30  4.70' 10 '20/05/2018 00:01:00  4.70' 10 ...
    'NB Time vector must be in survey local time'],'Enable','off','Callback',@(hObject, eventdata) loadPiezometerData(hObject, eventdata));

%% PUSHBUTTONS ------------------------------------------------------------
% Compute CrossCorr
uicontrol('style','pushbutton','units','normalized','position',[.005 .075 .06 .03],...
    'string','CC Compute','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'callback','CrossCorr_Compute','Tag','crosscorr_compute')
% Compute dV/V
uicontrol('style','pushbutton','units','normalized','position',[.065 .075 .06 .03],...
    'string','dV/V Compute','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'callback','CrossCorr_dVVCompute','Enable','off','Tag','dvv_compute')
% Save Correlogram figure
uicontrol('style','pushbutton','units','normalized','position',[.005 .04 .06 .03],...
    'string','Save Correlogram','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'callback','CrossCorr_CorrelogramSaveFig','Enable','off','Tag','Save correlogram')
% Save dV/V Plot figure
uicontrol('style','pushbutton','units','normalized','position',[.065 .04 .06 .03],...
    'string','Save dVVPlot','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'callback','CrossCorr_dVVSaveFig','Enable','off','Tag','Save dvv Plot')
% Save Variables
uicontrol('style','pushbutton','units','normalized','position',[.005 .005 .06 .03],...
    'string','Save Variables','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'callback','Save_data')
% Close
uicontrol('style','pushbutton','units','normalized','position',[.065 .005 .06 .03],...
    'string','Close','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'callback','close(gcf)')

%% WAIT BAR
uicontrol('Style','text','Units','normalized','Position',[.87 .03 .12 .025],...
    'String','Wait...','horizontalalignment','left','fontunits','normalized',...
    'fontsize',0.8,'Enable','off','Tag','wait');
handleToWaitBar = axes('Units','normalized','Position',[.87 .005 .12 .025],'XLim',[0 1],'YLim',[0 1],'XTick',[],'YTick',[],...
'Color', 'w','XColor','w','YColor', 'w','tag','handleToWaitBar');
patch([0 0 0 0], [0 1 1 0], 'g','Parent', handleToWaitBar,'EdgeColor','none');
drawnow

end

%% Funzione per attivare il Weighting
function CrossCorr_WeightingActivation(hObject,eventdata)
global mainCrossFig
weightType = findobj('Tag','Weighting');

if weightType.Value==1 | weightType.Value==3
     delete(findobj(mainCrossFig,'tag','WeightValue'));
weightEdit = uicontrol('style','edit','units','normalized','position',[.105 .5715 .02 .0275],...
'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
'String',0.5,'tag','WeightValue',...
'tooltipstring',['This value represents the lowest corner frequency [Hz]. It allows to compute the maximum period needed in the weighting procedure.' 10 ...
'i.e. 0.05 for Trillium or if you high-pass the signal at 0.5Hz you set 0.5' 10 ...
'for more details read book Seismic Ambient noise pag.153']);

else
    delete(findobj(mainCrossFig,'tag','WeightValue'));
end
end

%% Funzione per attivare filtro
function CrossCorr_filteractivation(hObject,eventdata)
filtercheck = findobj('Tag','filtercheck');
filtertype_text = findobj('Tag','filtertype_text');
filtertype_checkbox = findobj('Tag','filtertype_checkbox');
filterfreq_text = findobj('Tag','filterfreq_text');
filterfreq = findobj('Tag','filterfreq');

% Se opzione filtro è selezionata, attiva la parte di inserimento dati filtro
choice = filtercheck.Value;
if  choice == 1
    set(filtertype_text,'Enable','on') 
    set(filtertype_checkbox,'Enable','on')
    set(filterfreq_text,'Enable','on') 
    set(filterfreq,'Enable','on')        
end

% Se opzione filtro NON è selezionata, disattiva la parte di inserimento dati filtro
if choice == 0
    set(filtertype_text,'Enable','off') 
    set(filtertype_checkbox,'Enable','off')
    set(filterfreq_text,'Enable','off') 
    set(filterfreq,'Enable','off')        
end

end

%% Funzione per disattivare inserimento filtro quando Dynamic option is selected
function CrossCorr_filterUpdate(hObject,eventdata)
filtercheck = findobj('Tag','filtercheck');
filtertype_text = findobj('Tag','filtertype_text');
filtertype_checkbox = findobj('Tag','filtertype_checkbox');
filterfreq_text = findobj('Tag','filterfreq_text');
filterfreq = findobj('Tag','filterfreq');

% Se opzione filtro è selezionata, attiva la parte di inserimento dati filtro
choice = filtercheck.Value;
if  choice == 1
    set(filtertype_text,'Enable','on') 
    set(filtertype_checkbox,'Enable','on')
    set(filterfreq_text,'Enable','on') 
    set(filterfreq,'Enable','on')        
end

% Se opzione filtro NON è selezionata, disattiva la parte di inserimento dati filtro
if choice == 0
    set(filtertype_text,'Enable','off') 
    set(filtertype_checkbox,'Enable','off')
    set(filterfreq_text,'Enable','off') 
    set(filterfreq,'Enable','off')        
end


% Se Dynamic is selected do not activated the Filter freq tab
list = filtertype_checkbox.String;
FilterTypeSelected = list(filtertype_checkbox.Value);
if strcmp(FilterTypeSelected,'Dynamic')
    set(filterfreq_text,'Enable','off')
    set(filterfreq,'Enable','off')
end

end

%% Funzione per attivare tasti importazione dati piezometri
function PiezoPlot_activation(hObject,eventdata)
global mainCrossFig
choice = get(findobj(mainCrossFig,'tag','piezo_plotcheck'),'Value');
% Se check è selezionato, attiva la parte di caricamento file
if  choice == 1
    set(findobj(mainCrossFig,'Tag','piezo_select'),'enable','on');
    set(findobj(mainCrossFig,'Tag','piezo_selectButton'),'enable','on');
end

% Se check NON è selezionato, attiva la parte di caricamento file
if choice == 0
    set(findobj(mainCrossFig,'Tag','piezo_select'),'enable','off');
    set(findobj(mainCrossFig,'Tag','piezo_selectButton'),'enable','off');  
end
end

%% Funzione per caricare dati piezometri
function loadPiezometerData(hObject,eventdata)
global mainCrossFig
waittext = uicontrol(mainCrossFig,'style','text','units','normalized','position',[.93 .01 .06 .04],'string','Wait...',...
    'ForegroundColor','r','FontSize',12,'FontWeight','bold','Tag','waittext');
% selezione piezodata
[fileNamePiezo,folderPiezo] = uigetfile({'*.*'},'Select file to be loaded','MultiSelect', 'on');
currentfolder = pwd;
cd(folderPiezo)
piezofile = readtable(fileNamePiezo);
timeAxPiezo = table2array(piezofile(:,1));
dataPiezo = table2array(piezofile(:,2));
assignin('base','timeAxPiezo',timeAxPiezo);
assignin('base','dataPiezo',dataPiezo);
delete(findobj('tag','waittext'));drawnow
cd(currentfolder);
end


