% Uifigure filtering signals
function SpectralAnalysis_filter
global utilities

%% 1) Crea finestra richiesta Cut-Allign
% a) Crea figure
FilteringUIFigure = figure('numbertitle','off','Name','Filtering','toolbar','none','menubar','none','Position', [600 450 301 187]);

% b) Create FiltertypeDropDownLabel
FiltertypeDropDownLabel = uicontrol( FilteringUIFigure,'Style','text','Position',[19 146 62 22],'HorizontalAlignment','right',...
    'FontSize',9,'String','Filter type');

% c) Create FiltertypeDropDown
FiltertypeDropDown = uicontrol(FilteringUIFigure,'Style','popupmenu','FontWeight','bold','Position',[158 146 92 22],'String',{'Low pass', 'High pass', 'Band pass'}');

% d) Create FilterfrequencyHzEditFieldLabel
FilterfrequencyHzEditFieldLabel = uicontrol(FilteringUIFigure,'Style','text','Position',[19 110 113 22],'HorizontalAlignment','right',...
    'FontSize',9,'String','Filter frequency [Hz]');

% e) Create FilterfrequencyHzEditField
FilterfrequencyHzEditField = uicontrol(FilteringUIFigure,'Style','edit','Position',[159 110 92 22]);

% f)Create ComputeButton
ComputeButton = uicontrol(FilteringUIFigure, 'Style','pushbutton','String','Compute','Position',[110 60 91 22],...
    'Callback', @(btn,event) filtering(btn,FiltertypeDropDown,FilterfrequencyHzEditField,FilteringUIFigure));

% g) Create TextArea
TextArea = uicontrol(FilteringUIFigure,'Style','text','FontSize',6.8,'HorizontalAlignment','center','FontAngle','italic','Position',[1 1 301 28],...
    'String',{'Help: Indicate Fcut for Highpass/Lowpass or Fcut1,Fcut2 for Bandpass.'});


end


% Filtreing function
function filtering(btn,FiltertypeDropDown, FilterfrequencyHzEditField,FilteringUIFigure)
global spectralAnalysis

%segnale
data_selected = spectralAnalysis.data_selected;

%% 1) Seleziono i dati relativi al tipo di filtro
filterselected = FiltertypeDropDown.Value;
filtertype = FiltertypeDropDown.String;
filtertype = filtertype(filterselected);
filterfrequency = str2num(FilterfrequencyHzEditField.String);

%% 2) Filtra
    
    % %Design lowpass filt
    if strcmp(filtertype,'Low pass')
        data_selected.signal   = lowpass(data_selected.signal  ,filterfrequency, data_selected.fs,'ImpulseResponse','iir','Steepness',0.95);
    end
    
    %Design highpass filter
    if strcmp(filtertype,'High pass')
        data_selected.signal = highpass(data_selected.signal,filterfrequency,data_selected.fs,'ImpulseResponse','iir','Steepness',0.95);
    end
    
    %Design bandpass filter
    if strcmp(filtertype,'Band pass')
        data_selected.signal = bandpass(data_selected.signal,filterfrequency,data_selected.fs,'ImpulseResponse','iir','Steepness',0.95);
    end
    


%% Aggiornamento plot
ax1_spectralAnalysis = spectralAnalysis.ax1_spectralAnalysis; %richiamo asse
delete(get(ax1_spectralAnalysis,'Children')); %Cancella il plot esistente e aggiornalo col segnale filtrato
plot(ax1_spectralAnalysis,data_selected.timeAx,data_selected.signal,'Color','k');
grid(ax1_spectralAnalysis,'on');
grid(ax1_spectralAnalysis,'minor');
datetick(ax1_spectralAnalysis);
set(ax1_spectralAnalysis,'XLim',[data_selected.timeAx(1), data_selected.timeAx(end)])
set(get(ax1_spectralAnalysis,'XLabel'),'String','Time');

if strcmp(data_selected.name(1:3),'Dec')
    set(get(ax1_spectralAnalysis,'YLabel'),'String','m/s');
else
set(get(ax1_spectralAnalysis,'YLabel'),'String','Signal not deconvolved','Color','r');    
end
beep on; beep

%% rendi invisibili gli assi e cancella plot già esistenti
ax2_spectralAnalysis = spectralAnalysis.ax2_spectralAnalysis;
set(ax2_spectralAnalysis,'visible','off')
delete(get(ax2_spectralAnalysis, 'children'))
ax3_spectralAnalysis = spectralAnalysis.ax3_spectralAnalysis;
set(ax3_spectralAnalysis,'visible','off')
delete(get(ax3_spectralAnalysis, 'children'))


%% 3) Update con il segnale filtrato
spectralAnalysis.data_selected = data_selected;

%% 4) Chiudi finestra filtro
close(FilteringUIFigure)

%% 5) Cancella colorbar se esistono
colorbar('off')

%% 6) Display che il filtro è avvenuto
h=msgbox('Data have been successfully filtered!','Update','warn');
pause(1)
close(h)

end

