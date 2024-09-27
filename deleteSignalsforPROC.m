function [data_processing] = deleteSignalsforPROC(data_processing)
global utilities

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

% elimina i segnali che non servono
data_processing(selected) = [];

% Crea tabella
tabcell = struct2cell(data_processing)';
if isempty(tabcell)
    signalsToProcess = [];
else
signalsToProcess = tabcell(:,[1:3]);
end

%Riempi tabella
set(utilities.handles.table,'ColumnEditable', [false false true], 'ColumnFormat', {'char','numeric', {'East', 'North', 'Vertical'}}, 'data', signalsToProcess,'ColumnName',{'ID','Fs','Comp'});
% set(utilities.handles.table,'max',length(LboxNames)); %make it so you can select more than 1.


% Se tabcell non è vuota attiva il uimenu
if not(isempty(tabcell))
    set(findobj(utilities.handles.mainFig,'type','uimenu'),'enable','on');
end

cd(utilities.softwareFolder)
end