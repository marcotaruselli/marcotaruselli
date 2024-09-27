%%         ISTRUZIONI CODICE        %%%%%%%%%%%%%%%%%%%%%%%%%
%%% Questo codice è la parte universale che dev'essere aggiunta ad ogni
%%% funzione di processamento dei segnali per fare in modo che quando i
%%% segnali non sono stati selezionati prima del merge/filtro/taglio, il
%%% codice mette a display un errore il quale chiede di selezionare i
%%% segnali prima di processarli
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Uifigure filtering signals
function data_processing = proc_filtering(data_processing)
global utilities
%%%%%    Waitbar   %%%%%
wait = findobj(utilities.handles.mainFig,'tag','wait');
handleToWaitBar = findobj(utilities.handles.mainFig,'tag','handleToWaitBar');
%%%%%%%%%%%%%%%%%%%%%%%%%

%% 0) Prima di applicare la funzione controlla che qualche segnale sia stato selezionato!

if logical(evalin('base','~exist(''selected'')')) % Se non sono stati selezionati termina la funzione con questo messaggio di errore
    h=msgbox('No data have been selected! Please select data from "Signal for processing" list!','Update','error');
    return
else selected = evalin('base','selected'); % Se esiste carica la variabile selected dal base-workspace
end

%% 0.1) Seleziono i dati selezionati dalla tabella in MainPassive
% Dati da filtrare
data_selected = data_processing(selected,1); %Dati selezionati da tabella "Signal for processing"

% Dati da NON filtrare
data_NOTselected = data_processing;
data_NOTselected(selected) = [];

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
    'Callback', @(btn,event) filtering(btn,data_selected, data_NOTselected, FiltertypeDropDown,FilterfrequencyHzEditField,FilteringUIFigure));

% g) Create TextArea
TextArea = uicontrol(FilteringUIFigure,'Style','text','FontSize',6.8,'HorizontalAlignment','center','FontAngle','italic','Position',[1 1 301 28],...
    'String',{'Help: Indicate Fcut for Highpass/Lowpass or Fcut1,Fcut2 for Bandpass.'});

%%%%%    Waitbar   %%%%%
set(wait,'visible','on')
set(handleToWaitBar,'visible','on')
p = get(handleToWaitBar,'Child');
x = get(p,'XData');
x(3:4) = 0;
set(p,'XData',x);
drawnow
%%%%%%%%%%%%%%%%%%%%%%%%%
end


% Filtreing function
function filtering(btn,data_selected, data_NOTselected, FiltertypeDropDown, FilterfrequencyHzEditField,FilteringUIFigure)
global utilities
%%%%%    Waitbar   %%%%%
wait = findobj(utilities.handles.mainFig,'tag','wait');
handleToWaitBar = findobj(utilities.handles.mainFig,'tag','handleToWaitBar');
%%%%%%%%%%%%%%%%%%%%%%%%%

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
    
    %%%%%    Waitbar   %%%%%
    set(wait,'enable','on')
    p = get(handleToWaitBar,'Child');
    x = get(p,'XData');
    x(3:4) = i/size(data_selected,1);
    set(p,'XData',x);
    drawnow
    %%%%%%%%%%%%%%%%%%%%%%%%%
end

%% 3) Ricostruisci il vettore data_processing facendo l'update con i segnali filtrati
data_processing = [data_NOTselected; data_selected] ;%Unisci i segnali che sono stati mergiati e quelli non toccati
% Ordina per ordine alfabetico data_processing 
data_processing = SortStruct(data_processing);
assignin('base','data_processing',data_processing);

%% 4) Da mettere alla fine: Cancella il vettore che indica quali segnali sono stati selezionati dalla
% lista "Signal for processing"
evalin( 'base', 'clearvars selected' )
clc

%% 5) Display che il filtro è avvenuto
beep on; beep
h=msgbox('Data have been successfully filtered!','Update','warn');
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
%%%%%%%%%%%%%%%%%%%%%%%%%

%% 6) Chiudi finestra filtro
close(FilteringUIFigure)
end

