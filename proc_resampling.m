%%         ISTRUZIONI CODICE        %%%%%%%%%%%%%%%%%%%%%%%%%
%%% Questo codice è la parte universale che dev'essere aggiunta ad ogni
%%% funzione di processamento dei segnali per fare in modo che quando i
%%% segnali non sono stati selezionati prima del merge/filtro/taglio, il
%%% codice mette a display un errore il quale chiede di selezionare i
%%% segnali prima di processarli
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Uifigure resampling signals
function data_processing = proc_resampling(data_processing)
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
ResamplingUIFigure = figure('numbertitle','off','Name','Resampling','toolbar','none','menubar','none','Position', [600 450 280 120]);

% d) Create Resampling FsHzEditFieldLabel
ResamplingFsHzEditFieldLabel = uicontrol(ResamplingUIFigure,'Style','text','Position',[19 70 113 22],'HorizontalAlignment','right',...
    'FontSize',9,'String','Set the new Fs (Hz):');

% e) Create FilterfrequencyHzEditField
ResamplingFsHzEditField = uicontrol(ResamplingUIFigure,'Style','edit','Position',[150 72 92 22]);

% f)Create ComputeButton
ComputeButton = uicontrol(ResamplingUIFigure, 'Style','pushbutton','String','Compute','Position',[100 20 91 22],...
    'Callback', @(btn,event) resampling(btn,data_selected, data_NOTselected,ResamplingFsHzEditField,ResamplingUIFigure));

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


% Resampling function
function resampling(btn,data_selected, data_NOTselected, ResamplingFsHzEditField,ResamplingUIFigure)
global utilities
%%%%%    Waitbar   %%%%%
wait = findobj(utilities.handles.mainFig,'tag','wait');
handleToWaitBar = findobj(utilities.handles.mainFig,'tag','handleToWaitBar');
%%%%%%%%%%%%%%%%%%%%%%%%%

%% 1) Get the new Fs
Fs_new = str2num(ResamplingFsHzEditField.String);

%% 2) Resampling
for i = 1:size(data_selected,1)
%     %%%%%%% resampling signal VECCHIO %%%%%%%%
%     Fs_selected = data_selected(i).fs;
%     Fs_resample = Fs_selected/Fs_new;
%     [N,D] = rat(Fs_resample);
%     data_selected(i).signal   = resample(data_selected(i).signal,D,N);
%     data_selected(i).fs = Fs_new;
    
%     %%% Resampling timeAxis %%%
%     startTime = datestr(data_selected(i).timeAx(1),'dd-mmm-yyyy HH:MM:SS.FFF');
%     endTime = datestr(data_selected(i).timeAx(end),'dd-mmm-yyyy HH:MM:SS.FFF');
%     data_selected(i).timeAx = datenum(datetime(startTime):seconds(1/Fs_new):datetime(endTime))';
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%% Nuova versione resampling
    timeVect = datetime(data_selected(i).timeAx,'ConvertFrom','datenum','Format', 'dd-MMM-yyyy HH:mm:ss.SSS');
    [ResampledSig,ResampledTime] = resample(data_selected(i).signal,timeVect,Fs_new);
    data_selected(i).signal = ResampledSig;
    data_selected(i).timeAx = datenum(ResampledTime);
    data_selected(i).fs = Fs_new;
    %%%
    
    %%%%%    Waitbar   %%%%%
    set(wait,'enable','on')
    p = get(handleToWaitBar,'Child');
    x = get(p,'XData');
    x(3:4) = i/size(data_selected,1);
    set(p,'XData',x);
    drawnow
    %%%%%%%%%%%%%%%%%%%%%%%%%
end

%% 3) Ricostruisci il vettore data_processing facendo l'update con i segnali ricampionati
data_processing = [data_NOTselected; data_selected] %Unisci i segnali che sono stati mergiati e quelli non toccati
% Ordina per ordine alfabetico data_processing 
data_processing = SortStruct(data_processing);
assignin('base','data_processing',data_processing);

%% 3.1) Riempi la tabella con i segnali di cui è stato fatto il resampling
% Ordina per ordine alfabetico data_processing 
data_processing = SortStruct(data_processing);
% Converti data in cell
tabcell = struct2cell(data_processing)';
% Svuota Tabella che conteneva tutta la lista completa dei segnali caricati
set(utilities.handles.table,'ColumnEditable', [false false true],'ColumnFormat', {'char','numeric', {'East', 'North', 'Vertical'}},'data',[],'ColumnName',{'ID','Fs','Comp'});
% Riempi tabella con segnali tagliati
set(utilities.handles.table,'ColumnEditable', [false false true], 'ColumnFormat', {'char','numeric', {'East', 'North', 'Vertical'}}, 'data', tabcell(:,[1 2 3]),'ColumnName',{'ID','Fs','Comp'});

%% 4) Da mettere alla fine: Cancella il vettore che indica quali segnali sono stati selezionati dalla
% lista "Signal for processing"
evalin( 'base', 'clearvars selected' )
clc

%% 5) Display che il resampling è avvenuto
beep on; beep
h=msgbox('Data have been successfully resampled!','Update','warn');
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

%% 6) Chiudi finestra resample
close(ResamplingUIFigure)
end

