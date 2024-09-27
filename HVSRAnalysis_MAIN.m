function HVSRAnalysis_MAIN(data_processing)
global utilities
global data_selected
global HVSRAnalysis

% Seleziono il segnale dalla tabella in MainPassive
selected = evalin('base','selected');
data_selected = data_processing(selected,1); %Segnale selezionato da tabella "Signal for processing"
HVSRAnalysis.data_selected = data_selected;
% assignin('base','data_selected',data_selected) %questo serve solo per cut e filtro segnale

%% Controlli iniziali
% 1)  Controlla che almeno tre segnali siano stati selezionati %%%%%%%%%
if size(data_selected,1) ~= 3
    beep
    h=msgbox('You SHOULD select the three components of the same sensor!','Update','error');
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 2) Check if the three components have been selected
if ~isequal(length(data_selected(1).signal),length(data_selected(2).signal),length(data_selected(3).signal))
    beep
    waitfor(msgbox({'The three components must have the same length!'; 'Cut them before proceeding!'},'Update','error'))
    return
end

% 3) Check if the three components have the same time length
if ~isequal(length(data_selected(1).signal),length(data_selected(2).signal),length(data_selected(3).signal))
    beep
    waitfor(msgbox({'The three components must have the same length!'; 'Cut them before proceeding!'},'Update','error'))
    return
end

% 4) Check if the selected signals have the same Fs
if ~isequal(data_selected(1).fs, data_selected(2).fs, data_selected(3).fs)
    beep
    waitfor(msgbox({'The signals MUST have the same sampling frequency!'},'Update','error'))
    return
end

% 5) Check if all the 3 components of the sensor have been selected
comp = ["East", "North", "Vertical"]';
for i = 1:size(data_selected,1)
    check = strcmp(data_selected(i).Comp,comp); 
    if all(check)
        beep
        h=msgbox('You SHOULD select all the three components!','Update','error');
        return
    end    
end

% 6) Check if the 3 components belong to the same sensor
stnmain = data_selected(1).stn;
for i = 1:size(data_selected,1)
    
    if ~strcmp(data_selected(i).stn,stnmain)
        beep
        h=msgbox('You SHOULD select the same sensor!','Update','error');
        return
    end    
end

%% SIGNAL INFO ------------------------------------------------

% Creazione figure e rettangolo attorno ai plot
mainHVSRFig = figure('Tag','HVSR_Main','Name','HVSR Analysis','numbertitle','off','Units','normalized','WindowState','maximized','MenuBar','none'); 
HVSRAnalysis.mainHVSRFig = mainHVSRFig;
% Cornice ai plot e titolo
annotation('line',[0.14 0.99],[0.988 0.988],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga sopra orizzontale
annotation('line',[0.14 0.14],[0.014 0.988],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga sx verticale
annotation('line',[0.99 0.99],[0.014 0.988],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga dx verticale
annotation('line',[0.14 0.99],[0.014 0.014],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga sotto orizzontale

annotation('textbox',[0.02,0.975,0.078,0.02],'String','HVSR analysis Plot','Units','normalized','Position',[0.16 0.973 0.076 0.03],'FontSize',8,'LineStyle','none','BackgroundColor',[0.95 0.95 0.95]);


% SIGNAL INFO ------------------------------------------------
maincolour = [198/255 158/255 255/255];
PosTitleUicontrol = [.005 .96 .12 .03];
PosSubUicontrol_left = [.005 .96 .06 .03];
PosSubUicontrol_right = [.065 .96 .06 .03];
spazioPiccolo = [0 0.032 0 0];
% spazioMedio = [0 0.035 0 0];
spazioGrande = [0 0.038 0 0];

uicontrol('style','text','units','normalized','position',PosTitleUicontrol,...
    'string',' Signal info','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',maincolour);
  
% Signal station
uicontrol('style','text','units','normalized','position',PosSubUicontrol_left-spazioPiccolo,...
    'string','Station','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','text','units','normalized','position',PosSubUicontrol_right-spazioPiccolo,'tag','Signals_info',...
    'string',[data_selected(1).stn],'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5);

% Selected Component
uicontrol('style','text','units','normalized','position',PosSubUicontrol_left-2*spazioPiccolo,...
    'string','Component','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','text','tag','Signal_comp','units','normalized','position',PosSubUicontrol_right-2*spazioPiccolo,...
    'string','E-N-V','backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5);

% Fs - sampling frequency
uicontrol('style','text','units','normalized','position',PosSubUicontrol_left-3*spazioPiccolo,...
    'string','Fs','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','text','tag','Signal_FS','units','normalized','position',PosSubUicontrol_right-3*spazioPiccolo,...
    'string',data_selected(1).fs,'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5);

% Start Time
uicontrol('style','text','units','normalized','position',PosSubUicontrol_left-4*spazioPiccolo,...
    'string','Start Time','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','text','tag','Signals_startTime','units','normalized','position',PosSubUicontrol_right-4*spazioPiccolo,...
    'string',datestr(data_selected(1).timeAx(1)),'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.4);

% End Time
uicontrol('style','text','units','normalized','position',PosSubUicontrol_left-5*spazioPiccolo,...
    'string','End Time','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','text','tag','Signals_endTime','units','normalized','position',PosSubUicontrol_right-5*spazioPiccolo,...
    'string',datestr(data_selected(1).timeAx(end)),'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.4);

%% SIGNAL PRE_PROCESSING --------------------------------------------------------
% uicontrol('style','text','units','normalized','position',PosTitleUicontrol-5*spazioPiccolo-spazioGrande,...
%     'string',' Signal Pre-processing','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
%     'backgroundcolor',maincolour);
% 
% % Cut signals
% uicontrol('style','text','units','normalized','position',PosSubUicontrol_left-spazioGrande-6*spazioPiccolo,...
%     'string','Cut signal','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
%     'backgroundcolor',[.8 .8 .8]);
% uicontrol('style','pushbutton','tag','cutButton','units','normalized','position',PosSubUicontrol_right-spazioGrande-6*spazioPiccolo,...
%     'string','Enter','Value', 0,'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
%     'Callback','HVSRAnalysis_cut'); 
% 
% % Filtering
% uicontrol('style','text','units','normalized','position',PosSubUicontrol_left-spazioGrande-7*spazioPiccolo,...
%     'string','Filtering','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
%     'backgroundcolor',[.8 .8 .8]);
% uicontrol('style','pushbutton','tag','filterButton','units','normalized','position',PosSubUicontrol_right-spazioGrande-7*spazioPiccolo,...
%     'string','Enter','Value', 0,'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
%     'Callback','HVSRAnalysis_filter'); 
% 

%% HVSR parameters --------------------------------------------------------
uicontrol('style','text','units','normalized','position',PosTitleUicontrol-5*spazioPiccolo-spazioGrande,...
    'string',' HVSR parameters','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',maincolour);

% Nfft
HV_nfft_text = uicontrol('style','text','tag','HV_nfft_text','units','normalized','position',PosSubUicontrol_left-spazioGrande-6*spazioPiccolo,...
    'string','Nfft','horizontalalignment','center','fontunits','normalized','fontsize',.5,'backgroundcolor',[.8 .8 .8],'Enable','on');
HV_nfft_value = uicontrol('style','edit','tag','HV_nfft_value','units','normalized','position',PosSubUicontrol_right-spazioGrande-6*spazioPiccolo,...
    'String','auto','backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','on',...
    'tooltipstring',['FFT Samples should be equal or greater than (time window*sampling frequency).' 10,...
    'Powers of 2 give better performance of the FFT algorithm.' 10,...
    '''auto'' option: 2^(nextpow2(length(signal)))']);

% Time window
HV_timeWin_text = uicontrol('style','text','Tag','HV_timeWin_text','units','normalized','position',PosSubUicontrol_left-spazioGrande-7*spazioPiccolo,...
    'string','TimeWindow [s]','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
HV_timeWin_value = uicontrol('style','edit','Tag','HV_timeWin_value','units','normalized','position',PosSubUicontrol_right-spazioGrande-7*spazioPiccolo,...
    'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring',['Express time window in seconds. The code will convert it in samples.' 10,...
    'The longer the time window, the better the spectral resolution' 10,...
    'The shorter the time window, the better the statistical significance' 10,...
    'The lower relevant frequency is approximately related to 1/(time window/10)']);

% Window tapering
HV_taperWin_text = uicontrol('style','text','Tag','HV_taperWin_text','units','normalized','position',PosSubUicontrol_left-spazioGrande-8*spazioPiccolo,...
    'string','Tapering','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
HV_taperWin_listbox = uicontrol('style','popupmenu','Tag','HV_taperWin_listbox','units','normalized','position',PosSubUicontrol_right-spazioGrande-8*spazioPiccolo,...
    'string',{'hamming','hann','kaiser','rectwin','tukeywin'},'horizontalalignment','center','fontunits','normalized','fontsize',.5);


% % winOverlap
% HV_Overlap_text = uicontrol('style','text','Tag','HV_Overlap_text','units','normalized','position',PosSubUicontrol_left-spazioGrande-9*spazioPiccolo,...
%     'string','Overlap [%]','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
%     'backgroundcolor',[.8 .8 .8]);
% HV_Overlap_value = uicontrol('style','edit','tag','HV_Overlap_value','units','normalized','position',PosSubUicontrol_right-spazioGrande-9*spazioPiccolo,...
%     'horizontalalignment','center','fontunits','normalized','fontsize',.5);

% Smoothing type
HV_Smoothing_text = uicontrol('style','text','Tag','HV_Smoothing_text','units','normalized','position',PosSubUicontrol_left-spazioGrande-9*spazioPiccolo,...
    'string','Smoothing','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]); 
HV_Smoothing_value = uicontrol('style','popupmenu','Tag','HV_Smoothing_value','units','normalized','position',PosSubUicontrol_right-spazioGrande-9*spazioPiccolo,...
    'string',{'None','KonnoOhmachi','Triangular','Rectangular'},'Value',2,'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'Callback',@(numfld,event) activationRequiredParameters,'Tooltip','NB: Triangular & Rectangular smoothing not yet implemented');

% KonnoOhmachi b value
HV_konnoOhmachiPar_text = uicontrol('style','text','Tag','HV_konnoOhmachiPar_text','units','normalized','position',PosSubUicontrol_left-spazioGrande-10*spazioPiccolo,...
    'string','KO b value [-]','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
HV_konnoOhmachiPar_value = uicontrol('style','edit','Tag','HV_konnoOhmachiPar_value','units','normalized','position',PosSubUicontrol_right-spazioGrande-10*spazioPiccolo,...
    'horizontalalignment','center','String','40','fontunits','normalized','fontsize',.5,...
    'tooltipstring',['This parameter applies to KonnoOhmachi smoothing only.' 10,...
    'The value must be 0 < b < 100.' 10,'A value of 40 generally yields satisfactory results.']);

% Smoothing band
HV_smoothBand_text = uicontrol('style','text','tag','HV_smoothBand_text','units','normalized','position',PosSubUicontrol_left-spazioGrande-11*spazioPiccolo,...
    'string','Smooth Band [Hz]','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off')
HV_smoothBand_value = uicontrol('style','edit','tag','HV_smoothBand_value','units','normalized','position',PosSubUicontrol_right-spazioGrande-11*spazioPiccolo,...
    'string','5','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off',...
    'tooltipstring',['This parameter applies to Rectangular and Triangular smoothing.' 10,...
    'The value must be > sampling interval of the frequency axis and smaller than the Nyquist frequency.'])

%% STATISTICAL ANALYSIS
uicontrol('style','text','Tag','StatAnalTITLE','units','normalized','position',PosTitleUicontrol-11*spazioPiccolo-2*spazioGrande,...
    'string','Statistical analysis','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',maincolour,'Enable','off');

% make statistic on the HV peak or on the frequency at which the HV peak occurs
HV_peakORfreq_text = uicontrol('style','text','Tag','HV_peakORfreq_text','units','normalized','position',PosSubUicontrol_left-2*spazioGrande-12*spazioPiccolo,...
    'string','Analyse','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off',...
    'backgroundcolor',[.8 .8 .8]); 
HV_peakORfreq_value = uicontrol('style','popupmenu','Tag','HV_peakORfreq_value','units','normalized','position',PosSubUicontrol_right-2*spazioGrande-12*spazioPiccolo,...
    'string',{'HV peak','HV frequency'},'Value',1,'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off',...
    'Tooltip','You can compute the statistical analysis either on the HVSR peak or on the frequency at which the HV peak occurs');

% Bandwidth frequency
HV_PeakBandwidth_text = uicontrol('style','text','tag','HV_PeakBandwidth_text','units','normalized','position',PosSubUicontrol_left-2*spazioGrande-13*spazioPiccolo,...
    'string','Bandwidth [Hz]','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off');
HV_PeakBandwidth_value = uicontrol('style','edit','tag','HV_PeakBandwidth_value','units','normalized','position',PosSubUicontrol_right-2*spazioGrande-13*spazioPiccolo,...
    'string','auto','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off','Tooltip',...
    ['Select the frequency range in which you are going to peak the max of the HVSR' 10,...
    'if auto the frequency bandwidth range between the minimum and the fNy'])

% HVSR smoothing parameter
HV_smoothHVSR_text = uicontrol('style','text','tag','HV_smoothHVSR_text','units','normalized','position',PosSubUicontrol_left-2*spazioGrande-14*spazioPiccolo,...
    'string','Fit param','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off');
HV_smoothHVSR_value = uicontrol('style','edit','tag','HV_smoothHVSR_value','units','normalized','position',PosSubUicontrol_right-2*spazioGrande-14*spazioPiccolo,...
    'string','0.0001','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off','Tooltip',...
    'The HVSR peak curve will be fit with smoothingspline method that require a smoothing parameter ');

% Identify outliers
HV_outliers_text = uicontrol('style','text','tag','HV_outliers_text','units','normalized','position',PosSubUicontrol_left-2*spazioGrande-15*spazioPiccolo,...
    'string','Outliers','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off');
HV_outliers_value = uicontrol('style','edit','tag','HV_outliers_value','units','normalized','position',PosSubUicontrol_right-2*spazioGrande-15*spazioPiccolo,...
    'string','1.3','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off','Tooltip',...
    ['This value will moltiply the std of the HVSR peak curve to determine the outliers ' 10,...
        'Identify "outliers" as points at a distance greater than x*standard deviations from the baseline model, and refit the data with the outliers excluded'])

%% IMPORT AND PLOT PIEZO DATA --------------------------------------------------------
uicontrol('style','text','tag','imporPiezoTITLE','units','normalized','position',PosTitleUicontrol-15*spazioPiccolo-3*spazioGrande,...
    'string','Import Piezo Data','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',maincolour,'Enable','off');

% Plot Piezometer data over dV/V
HV_piezochoice_text = uicontrol('style','text','tag','HV_piezochoice_text','units','normalized','position',PosSubUicontrol_left-3*spazioGrande-16*spazioPiccolo,...
    'string','Plot Piezometers','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off');
HV_piezochoice_value = uicontrol('style','checkbox','tag','HV_piezochoice_value','units','normalized','position',PosSubUicontrol_right-3*spazioGrande-16*spazioPiccolo,...
    'string','Yes','Value', 0,'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'TooltipString','Do you want to plot piezometers data over dV/V?',...
    'Callback',@(hObject, eventdata) PiezoPlot_activation(hObject, eventdata),'Enable','off');

% Select file with piezometer data
HV_piezoSelect_text = uicontrol('style','text','Tag','HV_piezoSelect_text','units','normalized','position',PosSubUicontrol_left-3*spazioGrande-17*spazioPiccolo,...
    'string','Piezometer data','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off');
HV_piezoSelect_value = uicontrol('style','pushbutton','tag','HV_piezoSelect_value','units','normalized','position',PosSubUicontrol_right-3*spazioGrande-17*spazioPiccolo,...
    'String','Select','backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring',['Select .csv file with the following format...' 10 ...
    'Date Piezodata' 10 '20/05/2018 00:00:30  4.70' 10 '20/05/2018 00:01:00  4.70' 10 ...
    'NB Time vector must be in survey local time'],'Enable','off','Callback',@(hObject, eventdata) loadPiezometerData);

% Getting Timezone
HV_timezone_text = uicontrol('style','text','tag','HV_timezone_text','units','normalized','position',PosSubUicontrol_left-3*spazioGrande-18*spazioPiccolo,'Enable','off',...
    'string','Timezone','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
HV_timezone_value = uicontrol('style','edit','tag','HV_timezone_value','units','normalized','position',PosSubUicontrol_right-3*spazioGrande-18*spazioPiccolo,'String','Europe/Rome',...
    'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'Enable','off','tooltipstring',['Select the time zone where you did collect the data.' 10 ...
    'This is used to convert timeAx from UTC to Local time' 10 'Check Timezone areas in Matlab website']);

%% PLOT SETTINGS ----------------------------------------------------------
uicontrol('style','text','tag','PlotSetTITLE','units','normalized','position',PosTitleUicontrol-18*spazioPiccolo-4*spazioGrande,...
    'string',' Plot settings','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',maincolour,'Enable','off');

% Ylim for HVSR
HV_YLim_text = uicontrol('style','text','Tag','HV_YLim_text','units','normalized','position',PosSubUicontrol_left-4*spazioGrande-19*spazioPiccolo,...
    'string','HV Lim','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off',...
    'backgroundcolor',[.8 .8 .8]);
HV_YLim_value = uicontrol('style','edit','tag','HV_YLim_value','units','normalized','position',PosSubUicontrol_right-4*spazioGrande-19*spazioPiccolo,...
    'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off','Tooltip','Set the YLim for the HV plot',...
    'Callback',@(numfld,event) updateChanges);

% Frequency limits for HV
HV_FreqLim_text = uicontrol('style','text','Tag','HV_FreqLim_text','units','normalized','position',PosSubUicontrol_left-4*spazioGrande-20*spazioPiccolo,...
    'string','Freq lim [Hz]','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off',...
    'backgroundcolor',[.8 .8 .8]);
HV_FreqLim_value = uicontrol('style','edit','tag','HV_FreqLim_value','units','normalized','position',PosSubUicontrol_right-4*spazioGrande-20*spazioPiccolo,...
    'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off','Tooltip','Set the frequency limits. es: 1,50',...
    'Callback',@(numfld,event) updateChanges);

% FreqAx linear or log
HV_freqAxtype_text = uicontrol('style','text','Tag','HV_freqAxtype_text','units','normalized','position',PosSubUicontrol_left-4*spazioGrande-21*spazioPiccolo,...
    'string','FreqAx type','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off',...
    'backgroundcolor',[.8 .8 .8]); 
HV_freqAxtype_value = uicontrol('style','popupmenu','Tag','HV_freqAxtype_value','units','normalized','position',PosSubUicontrol_right-4*spazioGrande-21*spazioPiccolo,...
    'string',{'Log','Linear'},'Value',1,'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off',...
    'Callback',@(numfld,event) updateChanges,'Tooltip','NB: change frequency axes appearance');

% startTime for HV vs time
HV_StartTimePlot_text = uicontrol('style','text','Tag','HV_StartTimePlot_text','units','normalized','position',PosSubUicontrol_left-4*spazioGrande-22*spazioPiccolo,...
    'string','Start time','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off',...
    'backgroundcolor',[.8 .8 .8]);
HV_StartTimePlot_Value = uicontrol('style','edit','tag','HV_StartTimePlot_Value','units','normalized','position',PosSubUicontrol_right-4*spazioGrande-22*spazioPiccolo,...
    'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off','Tooltip','Set the start time',...
    'Callback',@(numfld,event) updateChanges);

% endTime for HV vs time
HV_EndTimePlot_text = uicontrol('style','text','Tag','HV_EndTimePlot_text','units','normalized','position',PosSubUicontrol_left-4*spazioGrande-23*spazioPiccolo,...
    'string','End time','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off',...
    'backgroundcolor',[.8 .8 .8]);
HV_EndTimePlot_Value = uicontrol('style','edit','tag','HV_EndTimePlot_Value','units','normalized','position',PosSubUicontrol_right-4*spazioGrande-23*spazioPiccolo,...
    'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off','Tooltip','Set the end time',...
    'Callback',@(numfld,event) updateChanges);

% Water table limits 
HV_WatTabLim_text = uicontrol('style','text','Tag','HV_WatTabLim_text','units','normalized','position',PosSubUicontrol_left-4*spazioGrande-24*spazioPiccolo,...
    'string','Water Lim','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off',...
    'backgroundcolor',[.8 .8 .8]);
HV_WatTabLim_value = uicontrol('style','edit','tag','HV_WatTabLim_value','units','normalized','position',PosSubUicontrol_right-4*spazioGrande-24*spazioPiccolo,...
    'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Enable','off','Tooltip','Set the colorbar limits for the HV vs time plot',...
    'Callback',@(numfld,event) updateChanges);

%% PUSHBUTTONS ------------------------------------------------------------
% % Close HV analysis procedure
% uicontrol('style','pushbutton','units','normalized','position',PosSubUicontrol_left-5*spazioGrande-23*spazioPiccolo,...
%     'string','Close','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
%     'backgroundcolor',[.7 .7 .7],'callback','close(gcf);','tag','button_closeHVAnal')
% 
% % Save Plot
% uicontrol('style','pushbutton','units','normalized','position',PosSubUicontrol_right-5*spazioGrande-23*spazioPiccolo,...
%     'string','Save Plot','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
%     'backgroundcolor',[.7 .7 .7],'Enable','off','Tag','HVecAnal_saveplot');

% Compute HV analysis
uicontrol('style','pushbutton','units','normalized','position',PosSubUicontrol_left-5*spazioGrande-24*spazioPiccolo,...
    'string','Compute HV','horizontalalignment','left','FontWeight','bold','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'Tag','HVecAnal_compute','Callback', @(numfld,event) ComputeHV);

% Compute Stat analysis
uicontrol('style','pushbutton','units','normalized','position',PosSubUicontrol_right-5*spazioGrande-24*spazioPiccolo,...
    'string','Compute Stat','horizontalalignment','left','FontWeight','bold','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'Tag','HVStatAnal_button','Callback', @(numfld,event) ComputeHVStat,'Enable','off');

%% CREAZIONE ASSI DA RICHIAMARE
ax1_HVSRAnalysis = axes('Units','normalized','Position',[.185 .71 0.75 0.24]);
HVSRAnalysis.ax1_HVSRAnalysis = ax1_HVSRAnalysis;
set(ax1_HVSRAnalysis,'visible','off')

ax2_HVSRAnalysis = axes('Units','normalized','Position',[.185 .39 0.75 0.24]);
HVSRAnalysis.ax2_HVSRAnalysis = ax2_HVSRAnalysis;
set(ax2_HVSRAnalysis,'visible','off')

% ax3_HVSRAnalysis = axes('Units','normalized','Position',[.185 .07 0.75 0.24]);
% HVSRAnalysis.ax3_HVSRAnalysis = ax3_HVSRAnalysis;
% set(ax3_HVSRAnalysis,'visible','off')

end

function ComputeHV
global HVSRAnalysis
mainHVSRFig = HVSRAnalysis.mainHVSRFig;

% Elimino annotation statistica se esiste
delete(findall(gcf,'type','annotation'))

% Elimino e ricreo assi => questo serve nel caso volessi rifare l'analisi
% con nuovi parametri
ax1_HVSRAnalysis = HVSRAnalysis.ax1_HVSRAnalysis;
ax2_HVSRAnalysis = HVSRAnalysis.ax2_HVSRAnalysis;
ax3_HVSRAnalysis = findobj(mainHVSRFig,'type','axes','tag','ax3_HVSRAnalysis');
delete(ax1_HVSRAnalysis)
delete(ax2_HVSRAnalysis)
delete(ax3_HVSRAnalysis)

ax1_HVSRAnalysis = axes('Units','normalized','Position',[.185 .71 0.75 0.24],'tag','ax1_HVSRAnalysis');
HVSRAnalysis.ax1_HVSRAnalysis = ax1_HVSRAnalysis;
ax1_HVSRAnalysis.Toolbar.Visible = 'on';
set(ax1_HVSRAnalysis,'visible','off')
ax2_HVSRAnalysis = axes('Units','normalized','Position',[.185 .39 0.75 0.24],'tag','ax2_HVSRAnalysis');
HVSRAnalysis.ax2_HVSRAnalysis = ax2_HVSRAnalysis;
ax2_HVSRAnalysis.Toolbar.Visible = 'on';
set(ax2_HVSRAnalysis,'visible','off')
% ax3_HVSRAnalysis = axes('Units','normalized','Position',[.185 .07 0.75 0.24],'tag','ax3_HVSRAnalysis');
% HVSRAnalysis.ax3_HVSRAnalysis = ax3_HVSRAnalysis;
% set(ax3_HVSRAnalysis,'visible','off')


data_selected = HVSRAnalysis.data_selected;
% segnale = data_selected.signal;

%% Barra caricamento
%Loading bar
barracaricamento = waitbar(0,'Computing HVSR analysis','Units','normalized','Position',[0.73,0.06,0.25,0.08]);

%% FASE 1: CREAZIONE SEGNALE UNICO A CUI APPLICARE HVSR
segnale = [data_selected(1).signal data_selected(2).signal data_selected(3).signal]; %1°=E; 2°=Y; 3°=Z

%% FASE 2 INSERIMENTO DATI PER CALCOLO HVSR
% Get parameters from MainFigure
HV_nfft_value = get(findobj(mainHVSRFig,'tag','HV_nfft_value'),'string');
if isempty(HV_nfft_value)
    beep
    h=msgbox('You must set the Nfft before proceding!','Update','error');
    return
end
HV_timeWin_value = get(findobj(mainHVSRFig,'tag','HV_timeWin_value'),'string');
HV_taperWin_listbox = get(findobj(mainHVSRFig,'tag','HV_taperWin_listbox'),'string');
HV_taperWin_value = get(findobj(mainHVSRFig,'tag','HV_taperWin_listbox'),'value');
HV_Smoothing_listbox = get(findobj(mainHVSRFig,'tag','HV_Smoothing_value'),'string');
HV_Smoothing_value = get(findobj(mainHVSRFig,'tag','HV_Smoothing_value'),'value');
HV_KOparam_value = get(findobj(mainHVSRFig,'tag','HV_konnoOhmachiPar_value'),'string');
HV_smoothParam_value = get(findobj(mainHVSRFig,'tag','HV_smoothBand_value'),'string');

% Creazione parametri
fs = data_selected(1).fs;
timeWindow = str2num(HV_timeWin_value);

% 2b) Dati che generalmente non cambiano
winTapering = HV_taperWin_listbox{HV_taperWin_value};
spectralSmoothing = HV_Smoothing_listbox{HV_Smoothing_value};

%% FASE 3: DEFINIZIONE VETTORE TEMPO E TEMPO REALE
time_real = data_selected(1).timeAx;
time_real = datetime(time_real,'ConvertFrom','datenum','Format','dd/MM/yyyy HH:mm:ss');
time_real.TimeZone = 'UTC';
HVSRAnalysis.time_real = time_real;

% 3c) Asse temporale funzione della frequenza di campionamento
dt = 1/fs;
ns = size(segnale,1);
timeAx = 0:dt:(ns-1)*dt;

%% Se vuoi plottare i segnali attiva queste righe
% %% Plot grafico segnale Raw
% figure
% subplot(3,1,1)
% plot(time_real,segnale(:,1),'-r'); legend('X-comp'); ylabel('Velocity [\mum/s]'); datetickzoom; 
% subplot(3,1,2)
% plot(time_real,segnale(:,2),'-g'); legend('Y-comp'); ylabel('Velocity [\mum/s]');datetickzoom;
% subplot(3,1,3)
% plot(time_real,segnale(:,3),'-b'); legend('Z-comp'); ylabel('Velocity [\mum/s]');datetickzoom;
% xlabel('Time'); 
% supertitle('Raw signal')

%% FASE 4: DEFINIZIONE FINESTRE TEMPORALI PER TAPERING E HVSR

timeWindowS = round(timeWindow/dt);
switch(lower(winTapering))
    case('hann')
        timeWindowSTape = hann(timeWindowS);
    case('hamming')
        timeWindowSTape = hamming(timeWindowS);
    case('tukey')
        timeWindowSTape = tukeywin(timeWindowS);
    case('none')
        timeWindowSTape = rectwin(timeWindowS);
    case('blackmanharris')
        timeWindowSTape = blackmanharris(timeWindowS);
end
timeWindowSTape3C = repmat(timeWindowSTape,1,3);
winNumber = floor(ns/timeWindowS);
HVSRAnalysis.winNumber = winNumber;

%% FASE 5: CALCOLO SPETTRO
% Definizione nfft
if strcmp(HV_nfft_value,'auto')
    fftSample = 2^(nextpow2(timeWindowS));
    else
    fftSample = str2num(HV_nfft_value);
end

df = fs/fftSample;
freqAx = 0:df:(fftSample/2-1)*df;
HVSRAnalysis.freqAx = freqAx;
% Initialization
eventFreqX = zeros(fftSample/2,winNumber);
eventFreqY = zeros(fftSample/2,winNumber);
eventFreqZ = zeros(fftSample/2,winNumber);
for K = 1:winNumber
    dataTemp = segnale(((K-1)*timeWindowS)+1:(((K-1)+1)*timeWindowS),:).*timeWindowSTape3C;
    eventFreqTemp = abs(fft(dataTemp,fftSample,1));
    eventFreqTemp(fftSample/2+1:fftSample,:) = [];
    eventFreqX(:,K) = eventFreqTemp(:,1);
    eventFreqY(:,K) = eventFreqTemp(:,2);
    eventFreqZ(:,K) = eventFreqTemp(:,3);
end
eventFreqXMean = mean(eventFreqX,2);
eventFreqYMean = mean(eventFreqY,2);
eventFreqZMean = mean(eventFreqZ,2);

% figure
% subplot(121)
% hold on
% plot(timeAx,segnale(:,1),'-r')
% plot(timeAx,segnale(:,2),'-g')
% plot(timeAx,segnale(:,3),'-b')
% hold off
% xlabel('Time [s]')
% ylabel('Velocity [\mum/s]')
% axis tight
% set(gca,'box','on','ylim',[-0.05 0.05])

% subplot(122)
% semilogx(freqAx,eventFreqXMean,'color','r')
% hold on
% semilogx(freqAx,eventFreqYMean,'color','g')
% semilogx(freqAx,eventFreqZMean,'color','b')
% hold off
% set(gca,'xlim',[0.05 500],'xgrid','on')

%% FASE 6: CALCOLO HVSR
% Initialization
eventFreqX = zeros(fftSample/2,winNumber);
eventFreqY = zeros(fftSample/2,winNumber);
eventFreqZ = zeros(fftSample/2,winNumber);
mergeH = zeros(fftSample/2,winNumber);
HoverV = zeros(fftSample/2,winNumber);
if strcmp(spectralSmoothing,'KonnoOhmachi')
    % Smoothing matrix
    b = 40;
    konnoOhmachi = zeros(length(freqAx));
    for f = 1:length(freqAx)
        konnoOhmachi(:,f) = ((sin(b*log10(freqAx/freqAx(f))))./(b*log10(freqAx/freqAx(f)))).^4;
    end
    for K = 1:winNumber
        dataTemp = segnale(((K-1)*timeWindowS)+1:(((K-1)+1)*timeWindowS),:).*timeWindowSTape3C;
        eventFreqTemp = abs(fft(dataTemp,fftSample,1));
        eventFreqTemp(fftSample/2+1:fftSample,:) = [];
        % è (quasi) indifferente fare prima smoothing e poi merge o viceversa però costa computazionalmente meno il viceversa
        eventFreqX(:,K) = eventFreqTemp(:,1);
        eventFreqY(:,K) = eventFreqTemp(:,2);
        %         eventFreqX(:,K) = sum(repmat(eventFreqTemp(:,1),1,fftSample/2).*konnoOhmachi,1,'omitnan');
        %         eventFreqY(:,K) = sum(repmat(eventFreqTemp(:,2),1,fftSample/2).*konnoOhmachi,1,'omitnan');
        eventFreqZ(:,K) = sum(repmat(eventFreqTemp(:,3),1,fftSample/2).*konnoOhmachi,1,'omitnan');
        %         % Merge horizontal components
        %         mergeH(:,K) = sqrt(eventFreqX(:,K).*eventFreqY(:,K));               % geometric mean
        %         mergeH(:,K) = sqrt(((eventFreqX(:,K).^2)+(eventFreqY(:,K).^2))/2);  % quadratic mean
        mergeTemp = sqrt(((eventFreqX(:,K).^2)+(eventFreqY(:,K).^2))/2);    % quadratic mean
        mergeH(:,K) = sum(repmat(mergeTemp,1,fftSample/2).*konnoOhmachi,1,'omitnan');
        % Spectral ratio H/V
        HoverV(:,K) = mergeH(:,K)./eventFreqZ(:,K);
        %% Avanzamento barra di caricamento
        waitbar(winNumber*K,barracaricamento,'Computing HVSR Analysis');

    end
elseif strcmp(spectralSmoothing,'None')
    for K = 1:winNumber
        dataTemp = segnale(((K-1)*timeWindowS)+1:(((K-1)+1)*timeWindowS),:).*timeWindowSTape3C;
        eventFreqTemp = abs(fft(dataTemp,fftSample,1));
        eventFreqTemp(fftSample/2+1:fftSample,:) = [];
        eventFreqX(:,K) = eventFreqTemp(:,1);
        eventFreqY(:,K) = eventFreqTemp(:,2);
        eventFreqZ(:,K) = eventFreqTemp(:,3);
        % Merge horizontal components (geometric mean)
        %             mergeH(:,K) = sqrt(eventFreqX(:,K).*eventFreqY(:,K));
        mergeH(:,K) = sqrt(((eventFreqX(:,K).^2)+(eventFreqY(:,K).^2))/2);
        
        % Spectral ratio H/V
        HoverV(:,K) = mergeH(:,K)./eventFreqZ(:,K);
        
        %% Avanzamento barra di caricamento
        waitbar(winNumber*K,barracaricamento,'Computing HVSR Analysis');
    end
end

% Mean and Std of H/V
%     HoverVMean = mean(HoverV,2);  % Aritmetic mean (influenzata da valori lontani dalla media)
HoverVMean = geomean(HoverV,2); % Geometric mean (molto influenzata da valori bassi, meno influenzata da valori alti)
HoverVMean(isnan(HoverVMean)) = 0;
% HoverVStd = std(HoverV,0,2);
 
%
% eventFreqXMean = nanmean(eventFreqX,2);
% eventFreqYMean = nanmean(eventFreqY,2);
% eventFreqZMean = nanmean(eventFreqZ,2);

ratioFreqLim = [(1/timeWindow)*10 fs/2];
ratioAmpLim = [0 max(max(HoverV))];
[v,i] = max(HoverVMean);

% Rendo globali le variabili
HVSRAnalysis.HoverV = HoverV;
HVSRAnalysis.HoverVMean = HoverVMean;
% HVSRAnalysis.HoverVStd = HoverVStd;
HVSRAnalysis.ratioFreqLim = ratioFreqLim;
HVSRAnalysis.ratioAmpLim = ratioAmpLim;

%% FASE 7: PLOT
PlotHV
    
%% FASE 8: ATTIVO BOTTONI ANALISI STATISTICA e PLOT SETTINGS
% Analisi statistica
        set(findobj(mainHVSRFig,'tag','StatAnalTITLE'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_peakORfreq_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_peakORfreq_value'),'enable','on');        
        set(findobj(mainHVSRFig,'tag','HV_PeakBandwidth_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_PeakBandwidth_value'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_smoothHVSR_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_smoothHVSR_value'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_outliers_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_outliers_value'),'enable','on');
% Plot settings
        set(findobj(mainHVSRFig,'tag','PlotSetTITLE'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_YLim_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_YLim_value'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_ColorbarLim_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_ColorbarLim_value'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_FreqLim_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_FreqLim_value'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_StartTimePlot_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_StartTimePlot_Value'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_EndTimePlot_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_EndTimePlot_Value'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_freqAxtype_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_freqAxtype_value'),'enable','on');        
        
% Import piezo data
        set(findobj(mainHVSRFig,'tag','imporPiezoTITLE'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_piezochoice_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_piezochoice_value'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_timezone_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_timezone_value'),'enable','on');
        
        set(findobj(mainHVSRFig,'tag','HV_piezochoice_value'),'Value',0);

% Compute statystical analysis button
        set(findobj(mainHVSRFig,'tag','HVStatAnal_button'),'enable','on');

        
%% FASE 9: chiudi barra di caricamento      
        close(barracaricamento)

end

function PlotHV
global HVSRAnalysis   
mainHVSRFig = HVSRAnalysis.mainHVSRFig;
fontDim = 12;

%% Richiamo variabli
freqAx = HVSRAnalysis.freqAx;
HoverV = HVSRAnalysis.HoverV;
HoverVMean = HVSRAnalysis.HoverVMean;
% HoverVStd = HVSRAnalysis.HoverVStd;
ratioFreqLim = HVSRAnalysis.ratioFreqLim;
ratioAmpLim = HVSRAnalysis.ratioAmpLim;
time_real = HVSRAnalysis.time_real;
winNumber = HVSRAnalysis.winNumber;

%% HV plot
% Richiamo asse
currentAxes = HVSRAnalysis.ax1_HVSRAnalysis;
axes(currentAxes);   
% Attivo toolbar per fare zoom
currentAxes.Toolbar.Visible = 'on';

% Rendi visibile l'asse perchè magari è stato reso invisibile dal cut o dal filtro
set(currentAxes,'visible','on')
% se esiste già un plot su questo asse eliminalo
if ~isempty(get(currentAxes, 'children'))
    delete(get(currentAxes, 'children'))
end

% plot
semilogx(freqAx,HoverV,'color',[.8 .8 .8])
hold on
hlegline = semilogx(freqAx,HoverVMean,'k','linewidth',2);

%%%% Ho disattivato il plot con calcolo std e l'ho sostituito 
% Plottando l'intervallo di confidenza 95  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% 1) Riattivare queste righe se si vuole plot con std %%%%%%%%%%%%%%%
% HoverVMean = mean(HoverV,2);  % Aritmetic mean (influenzata da valori lontani dalla media)
% HoverVStd = std(HoverV,0,2);
% semilogx(freqAx,HoverVMean+HoverVStd,':k','linewidth',2)
% semilogx(freqAx,HoverVMean-HoverVStd,':k','linewidth',2)

%%%%%%% 2) Plot intervallo di confidenza %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HoverVMean                                    % Mean Of All Experiments At Each Value Of ‘x’
N = size(HoverV,1);                                      % Number of ‘Experiments’ In Data Set
%HoverVMean = mean(HoverV);                                    % Mean Of All Experiments At Each Value Of ‘x’
HVSEM = std(HoverV')/sqrt(N);                              % Compute ‘Standard Error Of The Mean’ Of All Experiments At Each Value Of ‘x’
HVSEM(isnan(HVSEM)) = 0;
CI95 = tinv([0.025 0.975], N-1);  %il 5% non è 0.05 ma va diviso per due perchè ce l'hai sia a sx che a dx della gaussiana                   % Calculate 95% Probability Intervals Of t-Distribution
HoverV_CI95 = bsxfun(@times, HVSEM, CI95(:));              % Calculate 95% Confidence Intervals Of All Experiments At Each Value Of ‘x’
HoverV_CI95 = HoverV_CI95';
semilogx(freqAx,HoverV_CI95+HoverVMean,':k','linewidth',2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set(gca,'xlim',ratioFreqLim,'ylim',ratioAmpLim,'xgrid','on','gridcolor','k','minorgridcolor','k','gridalpha',1,'minorgridalpha',1)
set(gca,'xlim',[0 ratioFreqLim(2)],'xgrid','on','gridcolor','k','minorgridcolor','k','gridalpha',1,'minorgridalpha',1)
hold off
set(gca,'box','on','fontsize',10)
xlabel('Frequency [Hz]','FontName','garamond','FontSize',fontDim);
ylabel('HVSR [-]','FontName','garamond','FontSize',fontDim)
currentAxes.FontSize = fontDim;
currentAxes.FontName = 'garamond';
% xticklab = get(gca,'XTickLabel');
% set(gca,'XTickLabel',xticklab,'FontName','garamond','FontSize',fontDim);
% yticklab = get(gca,'YTickLabel');
% set(gca,'YTickLabel',yticklab,'FontName','garamond','FontSize',fontDim);

[v,i] = max(HoverVMean);
legend(hlegline,['f_0: ' num2str(freqAx(i),'%2.2f') 'Hz'],'FontName','garamond','FontSize',fontDim)
set(gca,'tag','ax1_HVSRAnalysis');

%% HV NEL TEMPO plot
% Richiamo asse
currentAxes = HVSRAnalysis.ax2_HVSRAnalysis;
axes(currentAxes);   
% Rendi visibile l'asse perchè magari è stato reso invisibile dal cut o dal filtro
set(currentAxes,'visible','on')
% se esiste già un plot su questo asse eliminalo
if ~isempty(get(currentAxes, 'children'))
    delete(get(currentAxes, 'children'))
end

% Conversione timeAx to UTC time
TimezoneSurvey = get(findobj(mainHVSRFig,'tag','HV_timezone_value'),'String');
time_real =  HVSRAnalysis.time_real;
% time_real = datetime(time_real,'TimeZone','UTC');
time_real.TimeZone = TimezoneSurvey;
% time_real = datetime(time_real,'TimeZone','UTC');
% time_real.TimeZone = TimezoneSurvey;
time_real.Format = 'dd/MM/yyyy HH:mm:ss';
HVSRAnalysis.time_real = time_real;

% 8a) asse temporale
startDate=time_real(1);
endDate=time_real(end);
steptimeaxis=linspace(startDate,endDate,winNumber);
HV_time_timeaxis=repmat(steptimeaxis,size(freqAx,2),1);

%  8b) asse frequenze
HV_time_frequencyaxis=repmat(freqAx,size(HV_time_timeaxis,2),1)';


s = surf(HV_time_timeaxis,HV_time_frequencyaxis,HoverV,'EdgeColor','none'); %si può usare anche la funzione mesh
set(gca,'XTick',[startDate:datenum('13-03-2018 11:00:00')-datenum('13-03-2018 10:45:00'):endDate],'FontName','garamond','FontSize',fontDim); %questa riga serve per incrementare gli indici sull'asseX
xlim([time_real(1) time_real(end)])
datetickzoom; %è la funzione che serve per far si che zoommando rimanga asse temporale giusto
shading interp              % This smooths out the colormap.
set(gca,'Ydir','reverse') % Qui non bisogna invertire asse frequenze
set(gca,'YScale','log')
% set(gca,'ylim',[0.5 ratioFreqLim(2)]); %imposta limiti di frequenza
set(gca,'ylim',[0 ratioFreqLim(2)]);
set(gca,'xlim',[time_real(1) time_real(end)]); %imposta limiti di tempo asse X
xlabel('Time','FontName','garamond','FontSize',fontDim);
ylabel('Frequency [Hz]','FontName','garamond','FontSize',fontDim);
% xticklab = get(gca,'XTickLabel');
% set(gca,'XTickLabel',xticklab,'FontName','garamond','FontSize',fontDim);
% yticklab = get(gca,'YTickLabel');
% set(gca,'YTickLabel',yticklab,'FontName','garamond','FontSize',fontDim);
view(2)
% Colorbar
posizioneAsse = currentAxes.Position;
cbarCorrelogram = colorbar(currentAxes,'Position',[0.94 posizioneAsse(1,2) 0.01 0.24]);
cbarCorrelogram.Label.String = '[H/V]'
HVSRAnalysis.cbarCorrelogram = cbarCorrelogram;

% set(gca,'clim',[0 ceil(max(HoverVMean+HoverVStd))]) %imposta la colorbar in modo tale da colorare solo i valori sopra la media+st.dev

set(gca,'Ydir','normal') %serve per invertire l'asse delle frequenze
set(gca,'tag','ax2_HVSRAnalysis');

%% Riempio plot settings 
mainHVSRFig = HVSRAnalysis.mainHVSRFig;
% Limiti HVSR
currentAxes = HVSRAnalysis.ax1_HVSRAnalysis;
HVSRLim = currentAxes.YLim;
set(findobj(mainHVSRFig,'tag','HV_YLim_value'),'string',[num2str(HVSRLim(1)) ',' num2str(HVSRLim(2))]);
% Limiti Frequency axes
HVSRFreqLim = currentAxes.XLim;
set(findobj(mainHVSRFig,'tag','HV_FreqLim_value'),'string',[num2str(HVSRFreqLim(1)) ',' num2str(HVSRFreqLim(2))]);

% Limiti asse tempo
set(findobj(mainHVSRFig,'tag','HV_StartTimePlot_Value'),'string',datestr(time_real(1)));
set(findobj(mainHVSRFig,'tag','HV_EndTimePlot_Value'),'string',datestr(time_real(end)));

% Colorbar
set(findobj(mainHVSRFig,'tag','HV_ColorbarLim_value'),'string',[num2str(cbarCorrelogram.Limits(1)) ',' num2str(cbarCorrelogram.Limits(2))]);
          
end

function ComputeHVStat
global HVSRAnalysis
mainHVSRFig = HVSRAnalysis.mainHVSRFig;

% Elimino annotation bonta statistica
delete(findall(gcf,'type','annotation'))

% Elimino asse analisi statistica
asse = findobj(mainHVSRFig,'type','axes','tag','ax3_HVSRAnalysis');
delete(asse)

%% Richiamo variabili
HoverV = HVSRAnalysis.HoverV;
winNumber = HVSRAnalysis.winNumber;
freqAx = HVSRAnalysis.freqAx;
time_real = HVSRAnalysis.time_real;

%% Getting parameters
HV_PeakBandwidth_value = get(findobj(mainHVSRFig,'tag','HV_PeakBandwidth_value'),'string');
HV_smoothHVSR_value = get(findobj(mainHVSRFig,'tag','HV_smoothHVSR_value'),'string');
HV_outliers_value = get(findobj(mainHVSRFig,'tag','HV_outliers_value'),'string');
HV_outliers_listbox = get(findobj(mainHVSRFig,'tag','HV_peakORfreq_value'),'string');
HV_peakORfreq_value = get(findobj(mainHVSRFig,'tag','HV_peakORfreq_value'),'value');
statChoice = HV_outliers_listbox{HV_peakORfreq_value};

%% Range di frequenze scelto
if ~strcmp(HV_PeakBandwidth_value,'auto')
   HV_PeakBandwidth_value = str2num(HV_PeakBandwidth_value);
   idxMin = find(freqAx>=min(HV_PeakBandwidth_value));
   idxMax = find(freqAx<=max(HV_PeakBandwidth_value));
   freqAx_limited = freqAx(idxMin(1):idxMax(end));
   HoverV = HoverV([idxMin(1):idxMax(end)],:);
end

%% Maxpeak within selected HoverV
HoverV(isnan(HoverV))=0;
[peakHV, idx] = max(HoverV,[],1);  %peakHV

%% scegli su che dato fare l'analisi statistica
if strcmp(statChoice,'HV peak')
    peakHV = peakHV';
elseif strcmp(statChoice,'HV frequency')
    peakHV = freqAx_limited(idx);
    peakHV = peakHV';    
end

%% Asse temporale
startDate=time_real(1);
endDate=time_real(end);
HVfit_timeaxis=linspace(startDate,endDate,winNumber)';

%% Fitting curve
% Fitting
smoothPar = str2num(HV_smoothHVSR_value);                                          
time = linspace(1,length(peakHV),length(peakHV))';
[f, fgof] = fit(time,peakHV,'smoothingspline','SmoothingParam',smoothPar);  
fittedcurvedata = feval(f,time); % serve per valutare il fit sullo stesso numero di campioni in ingresso

%% identify outliers, remove them and refit
hold on 
deviaz = str2num(HV_outliers_value);
I = abs(fittedcurvedata - peakHV) > deviaz*std(peakHV);                                 %%%%%%%% MODIFICA %%%%%%%%%%%
outliers = excludedata(HVfit_timeaxis,peakHV,'indices',I);

%re-fit without
idxOutliers = find(outliers == 1);
[f_withoutOutliers, fnoOutgof] = fit(time,peakHV,'smoothingspline','SmoothingParam',smoothPar,'exclude',idxOutliers); 
fittedcurvedata_noOutliers = feval(f_withoutOutliers,time); % serve per valutare il fit sullo stesso numero di campioni in ingresso

%% Plot 
% currentAxes = HVSRAnalysis.ax3_HVSRAnalysis;
ax3_HVSRAnalysis = axes('Units','normalized','Position',[.185 .07 0.75 0.24],'tag','ax3_HVSRAnalysis');
ax3_HVSRAnalysis.Toolbar.Visible = 'on';
currentAxes = ax3_HVSRAnalysis;
axes(currentAxes); 

yyaxis(currentAxes,'left');
hold on

% se esiste già un plot su questo asse eliminalo
if ~isempty(get(currentAxes, 'children'))
    delete(get(currentAxes, 'children'))
end

% Plot peak in HV
plot(HVfit_timeaxis,peakHV,'o','Color',[0.5 0.5 0.5]); %Plot picchi massimi
hold on;
% Plot fit HVpeak
plot(HVfit_timeaxis,fittedcurvedata,'-g');
datetick 
% Plot outliers
plot(HVfit_timeaxis(outliers),peakHV(outliers),'*r')
% Plot fit without outliers
plot(HVfit_timeaxis,fittedcurvedata_noOutliers,'-k','LineWidth',2);datetick

% Tag asse
set(gca,'tag','ax3_HVSRAnalysis');
% Settings
fontDim = 12;
if strcmp(statChoice,'HV peak')
    ylabel('HVSR [-]','FontName','garamond','FontSize',fontDim);
else
    ylabel('Frequency [Hz]','FontName','garamond','FontSize',fontDim);
end
xlabel('Time','FontName','garamond','FontSize',fontDim);
set(gca,'xlim',[time_real(1) time_real(end)]); %imposta limiti di tempo asse X
l = legend({'maxHV', 'fit maxHV', 'outliers', 'fit without outliers'},'FontName','garamond','FontSize',9);
grid on; grid minor; drawnow
currentAxes.YAxis(1).Color = 'k';
set(currentAxes,'xminorgrid','on','yminorgrid','on');
set(gca,'tag','ax3_HVSRAnalysis');
currentAxes.FontSize = fontDim;
currentAxes.FontName = 'garamond';
currentAxes.Box = 'on';

% Proprietà asse destro
% currentAxes.YAxis(2).TickValues = [];  %disattiva secondo asse y
currentAxes.YAxis(2).Color = 'k';
set(currentAxes.YAxis(2),'visible','off')
%% Annotation tabella goodness of fit
h = annotation('textbox','Units','normalized','Position',[0.195 0.22 0.1 0.075],...
    'String',['Goodness of fit:', 10, 'Fit: R^{2} = ' num2str(fgof.rsquare,'%.2f'),10,'Fit no-outliers: R^{2} = ' num2str(fnoOutgof.rsquare,'%.2f')],...
    'FontName','garamond','FontSize',10,'BackgroundColor','w','Tag','gofAnnotation');

%% Plot Piezo data if selected ==> choicePiezo
plotPiezo

%% Applica i plot settings
updateChanges
end

function activationRequiredParameters
global HVSRAnalysis
mainHVSRFig = HVSRAnalysis.mainHVSRFig;

%% Scelta del metodo
listOfMethods = get(findobj(mainHVSRFig,'tag','HV_Smoothing_value'),'string');
chosenMethod = get(findobj(mainHVSRFig,'tag','HV_Smoothing_value'),'value');
chosenMethod = listOfMethods(chosenMethod); %Metodo scelto per effettuare analisi HVettrale

%% Disattivo parametri non necessari per HV analysis
switch char(chosenMethod)
    case 'None'
        set(findobj(mainHVSRFig,'tag','HV_konnoOhmachiPar_text'),'enable','off');
        set(findobj(mainHVSRFig,'tag','HV_konnoOhmachiPar_value'),'enable','off');
        set(findobj(mainHVSRFig,'tag','HV_smoothBand_text'),'enable','off');
        set(findobj(mainHVSRFig,'tag','HV_smoothBand_value'),'enable','off');                
        
    case 'KonnoOhmachi'
        set(findobj(mainHVSRFig,'tag','HV_konnoOhmachiPar_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_konnoOhmachiPar_value'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_smoothBand_text'),'enable','off');
        set(findobj(mainHVSRFig,'tag','HV_smoothBand_value'),'enable','off');     
        
    case 'Triangular'
        set(findobj(mainHVSRFig,'tag','HV_konnoOhmachiPar_text'),'enable','off');
        set(findobj(mainHVSRFig,'tag','HV_konnoOhmachiPar_value'),'enable','off');
        set(findobj(mainHVSRFig,'tag','HV_smoothBand_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_smoothBand_value'),'enable','on');     
        
    case 'Rectangular'
        set(findobj(mainHVSRFig,'tag','HV_konnoOhmachiPar_text'),'enable','off');
        set(findobj(mainHVSRFig,'tag','HV_konnoOhmachiPar_value'),'enable','off');
        set(findobj(mainHVSRFig,'tag','HV_smoothBand_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_smoothBand_value'),'enable','on');     
        
end

end

function updateChanges
global HVSRAnalysis
mainHVSRFig = HVSRAnalysis.mainHVSRFig;

%% Get parameters
HV_YLim_value = get(findobj(mainHVSRFig,'tag','HV_YLim_value'),'string');
HV_ColorbarLim_value = get(findobj(mainHVSRFig,'tag','HV_ColorbarLim_value'),'string');
HV_FreqLim_value = get(findobj(mainHVSRFig,'tag','HV_FreqLim_value'),'string');
HV_StartTimePlot_Value = get(findobj(mainHVSRFig,'tag','HV_StartTimePlot_Value'),'string');
HV_EndTimePlot_Value = get(findobj(mainHVSRFig,'tag','HV_EndTimePlot_Value'),'string');
HV_PeakBandwidth_value = get(findobj(mainHVSRFig,'tag','HV_PeakBandwidth_value'),'string');
HV_freqAxtype_value = get(findobj(mainHVSRFig,'tag','HV_freqAxtype_value'),'value');
HV_outliers_listbox = get(findobj(mainHVSRFig,'tag','HV_peakORfreq_value'),'string');
HV_peakORfreq_value = get(findobj(mainHVSRFig,'tag','HV_peakORfreq_value'),'value');
statChoice = HV_outliers_listbox{HV_peakORfreq_value};

%% Aggiorno HV limits
%asse1
currentAx = findobj(mainHVSRFig,'type','axes','tag','ax1_HVSRAnalysis');
currentAx.YLim = str2num(HV_YLim_value);
% asse3
currentAx = findobj(mainHVSRFig,'type','axes','tag','ax3_HVSRAnalysis');
if ~isempty(currentAx)
    if strcmp(statChoice,'HV peak')
        currentAx.YAxis(1).Limits = str2num(HV_YLim_value);
    end
end
% asse 2
currentAx = findobj(mainHVSRFig,'type','axes','tag','ax2_HVSRAnalysis');
% set(gca,'clim',[0 ceil(max(HoverVMean+HoverVStd))]) %imposta la colorbar in modo tale da colorare solo i valori sopra la media+st.dev
cbarCorrelogram = HVSRAnalysis.cbarCorrelogram;
currentAx.CLim = str2num(HV_YLim_value);
cbarCorrelogram.Limits = str2num(HV_YLim_value); %Aggiorna colorbar

%% Aggiorno Frequency limits
%asse1
currentAx = findobj(mainHVSRFig,'type','axes','tag','ax1_HVSRAnalysis');
currentAx.XLim = str2num(HV_FreqLim_value);
% asse2
currentAx = findobj(mainHVSRFig,'type','axes','tag','ax2_HVSRAnalysis');
currentAx.YLim = str2num(HV_FreqLim_value);

currentAx = findobj(mainHVSRFig,'type','axes','tag','ax3_HVSRAnalysis');
if ~isempty(currentAx)
    if strcmp(statChoice,'HV frequency')
        currentAx.YAxis(1).Limits = str2num(HV_FreqLim_value);
    end
end
    
%% Aggiorno Frequency axis type
% asse1
currentAx = findobj(mainHVSRFig,'type','axes','tag','ax1_HVSRAnalysis');
if HV_freqAxtype_value == 1
    set(currentAx, 'XScale', 'log');
elseif HV_freqAxtype_value == 2
    set(currentAx, 'XScale', 'linear');
end

% asse2
currentAx = findobj(mainHVSRFig,'type','axes','tag','ax2_HVSRAnalysis');
if HV_freqAxtype_value == 1
    set(currentAx, 'YScale', 'log');
elseif HV_freqAxtype_value == 2
    set(currentAx, 'YScale', 'linear');
end
%% Aggiorno time limits
% Richiamo asse plot 
currentAx2 = findobj(mainHVSRFig,'type','axes','tag','ax2_HVSRAnalysis');
currentAx3 = findobj(mainHVSRFig,'type','axes','tag','ax3_HVSRAnalysis');

% Update X lim
TimezoneSurvey = get(findobj(mainHVSRFig,'tag','HV_timezone_value'),'String');
startime = datetime(get(findobj(mainHVSRFig,'tag','HV_StartTimePlot_Value'),'String'),'TimeZone',TimezoneSurvey);
endtime = datetime(get(findobj(mainHVSRFig,'tag','HV_EndTimePlot_Value'),'String'),'TimeZone',TimezoneSurvey);
currentAx2.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);
if ~isempty(currentAx3)
currentAx3.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);
end

%% Aggiorno water table limits
choicePiezo = get(findobj(mainHVSRFig,'tag','HV_piezochoice_value'),'Value');
currentAx3 = findobj(mainHVSRFig,'type','axes','tag','ax3_HVSRAnalysis');
watLim = get(findobj(mainHVSRFig,'tag','HV_WatTabLim_value'),'String')
if  choicePiezo == 1
    if ~isempty(currentAx3)
        currentAx3.YAxis(2).Limits = str2num(watLim);
    end
end
end

function PiezoPlot_activation(hObject,eventdata)
global HVSRAnalysis
mainHVSRFig = HVSRAnalysis.mainHVSRFig;

choice = get(findobj(mainHVSRFig,'tag','HV_piezochoice_value'),'Value');
% Se check è selezionato, attiva la parte di caricamento file
if  choice == 1
        set(findobj(mainHVSRFig,'tag','HV_piezoSelect_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_piezoSelect_value'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_WatTabLim_text'),'enable','on');
        set(findobj(mainHVSRFig,'tag','HV_WatTabLim_value'),'enable','on');                
end
% Se check NON è selezionato, attiva la parte di caricamento file
if choice == 0
        set(findobj(mainHVSRFig,'tag','HV_piezoSelect_text'),'enable','off');
        set(findobj(mainHVSRFig,'tag','HV_piezoSelect_value'),'enable','off');
        set(findobj(mainHVSRFig,'tag','HV_WatTabLim_text'),'enable','off');
        set(findobj(mainHVSRFig,'tag','HV_WatTabLim_value'),'enable','off');
end
end

function loadPiezometerData
global HVSRAnalysis
mainHVSRFig = HVSRAnalysis.mainHVSRFig;

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

    %% Aggiorna dati per modifica plot settings
    limWaterLeft = num2str(ceil(min(dataPiezo)));
    limWaterRight = num2str(ceil(max(dataPiezo)));
    set(findobj(mainHVSRFig,'tag','HV_WatTabLim_value'),'string',[limWaterLeft ',' limWaterRight]);
end


function plotPiezo
global HVSRAnalysis
mainHVSRFig = HVSRAnalysis.mainHVSRFig;

choicePiezo = get(findobj(mainHVSRFig,'tag','HV_piezochoice_value'),'Value');
time_real = HVSRAnalysis.time_real;
TimezoneSurvey = get(findobj(mainHVSRFig,'tag','HV_timezone_value'),'String');
% % time_real = datetime(time_real,'ConvertFrom','datenum','Format','dd/MM/yyyy HH:mm:ss');
% % time_real = datetime(time_real,'TimeZone','UTC');
% TimezoneSurvey = get(findobj(mainHVSRFig,'tag','HV_timezone_value'),'String');
% time_real.TimeZone = 'Europe/Rome';


% Richiamo asse
currentAxes = findobj(mainHVSRFig,'type','axes','tag','ax3_HVSRAnalysis');

if choicePiezo == 1
    set(currentAxes.YAxis(2),'visible','on')
    timeAxPiezo = evalin('base', 'timeAxPiezo');
    dataPiezo = evalin('base', 'dataPiezo');
    timeAxPiezo.TimeZone = TimezoneSurvey;
    yyaxis(currentAxes, 'right');
    dv_watertableplot = plot(timeAxPiezo,dataPiezo,'b');
    % Yaxis right ticksValues
%     yticksPiezo = [ceil(min(dataPiezo)):0.2:ceil(max(dataPiezo))];
    yticksPiezo = linspace(ceil(min(dataPiezo)),ceil(max(dataPiezo)),10);
% %     currentAxes.YAxis(2).TickValues = yticksPiezo;
%     currentAxes.YAxis(2).TickLabelFormat = '%.2f'
    currentAxes.YAxis(2).Color = 'b';
    xlim([max(min(time_real),min(timeAxPiezo)) min(max(time_real),max(timeAxPiezo))]);
    ylim([ceil(min(dataPiezo)),ceil(max(dataPiezo))])
%     datetick('x','HH:MM')
    % Prorpietà asse destro
    ax_dvv.YAxis(2).Color = 'b';
    ylabel('Water table [m]','Units', 'Normalized', 'Position', [1.04 0.5, 0]);
    l = legend({'maxHV', 'fit maxHV', 'outliers', 'fit without outliers','Water table'},'FontName','garamond','FontSize',9);

end

% % Set xlim
% timeAx.Format = 'dd-MM-yyyy HH:mm:ss';
% startime = timeAx(1);
% endtime = timeAx(end);
% dvvfigure = findobj(gcf,'tag','dvvPlot');
% TimezoneSurvey = get(findobj(mainCrossFig,'tag','Timezone'),'String');
% dvvfigure.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);

end