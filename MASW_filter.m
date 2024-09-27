% Uifigure filtering signals
function MASW_filter
global utilities
global mainMASWFig

%Wait
avviso = annotation(mainMASWFig,'textbox','String','WAIT!!!','Color','b','FontWeight','bold','FontSize',15,...
    'Units','normalized','Position',[0.03 0.05 0.06 0.05],'EdgeColor','none','Tag','avviso');

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
global MASW

%segnale
data_selected = MASW.data_selected;

%% 1) Seleziono i dati relativi al tipo di filtro
filterselected = FiltertypeDropDown.Value;
filtertype = FiltertypeDropDown.String;
filtertype = filtertype(filterselected);
filterfrequency = str2num(FilterfrequencyHzEditField.String);

%% 2) Filtra
for i = 1:size(data_selected,1)
    
    % %Design lowpass filt
    if strcmp(filtertype,'Low pass')
        data_selected(i).signal   = lowpass(data_selected(i).signal  ,filterfrequency, data_selected(i).fs,'ImpulseResponse','iir','Steepness',0.95);
    end
    
    %Design highpass filter
    if strcmp(filtertype,'High pass')
        data_selected(i).signal = highpass(data_selected(i).signal,filterfrequency,data_selected(i).fs,'ImpulseResponse','iir','Steepness',0.95);
    end
    
    %Design bandpass filter
    if strcmp(filtertype,'Band pass')
        data_selected(i).signal = bandpass(data_selected(i).signal,filterfrequency,data_selected(i).fs,'ImpulseResponse','iir','Steepness',0.95);
    end
end

    


%% 3) Update con il segnale filtrato
MASW.data_selected = data_selected;

%% 4) Chiudi finestra filtro
close(FilteringUIFigure)

%% 5) Aggiornamento plot
PlotMASWtraces
set(gca,'Tag','Traces_Axis');

%% 6) Display che il filtro è avvenuto
h=msgbox('Data have been successfully filtered!','Update','warn');
pause(1)
close(h)

% Togli avviso
delete( findall(gcf,'Tag','avviso'));
end

function PlotMASWtraces
global MASW
global mainMASWFig
% Se già esiste il plot cancellalo
delete(findobj(mainMASWFig,'tag','Traces_Axis'));

% Dati input
data_selected = MASW.data_selected;
nCh = MASW.nCh;                                                                   %%% ==> CANCELLA!!!!!!!!!
% TimeAx
fs = data_selected(1).fs;
dt = 1/fs;
N = length(data_selected(1).signal);                                        %%% ==> DA CAMBIAREEE!!! IN BASE ALLA FINESTRA TEMPORALE SCELTA
timeAx = 0:dt:(N-1)*dt;
MASW.timeAx = timeAx;

% Rimuovi la DC
data_withoutDC = ones(length(data_selected(1).signal),nCh);
for i = 1:size(data_selected,1)
    data_withoutDC(:,i) = data_selected(i).signal-mean(data_selected(i).signal);
end
MASW.data_withoutDC = data_withoutDC;

% Plot
Traces_Axis = axes(mainMASWFig,'Units','normalized','Position',[0.17 0.2 0.32 0.72]);
nTraces = 1:nCh;
for i = 1:size(data_withoutDC,2)
    plot(Traces_Axis,nTraces(i)+data_withoutDC(:,i)./abs(max(data_withoutDC(:,i))),timeAx,'color',[0,0,0]+0.5) %normalizzo per evidenziare le phases
    hold on
end
set(gca,'YDir','Reverse','Tag','Traces_Axis','XAxisLocation','top','YTickLabelRotation',90)
xlabel('Traces')
ylabel('Time [s]')
grid on; grid minor;

end

