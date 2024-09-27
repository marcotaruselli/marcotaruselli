%%%%%%%%%%%%%           proc_processRawData(data)       %%%%%%%%%%%%%%%%%%%
% Questa funzione serve per mettere nella tabella "signals for processing" i
%segnli che devono essere processati


function data_processing = proc_processRawData(data)

global utilities

% Funzione che riempie la tabella con i segnali selezionati dalla lista Raw Signals

ListBoxValue = get(utilities.handles.listRaw,'Value'); %segnali selezionati in listRAW

% if ~ismember('data_processing',evalin('base','who'))
%     data_processing = data(ListBoxValue,:);
% else % se esistono già segnali allora aggiungili data_processing
% data_processing = evalin('base', 'data_processing');
%     data_processing =[data_processing; data(ListBoxValue,:)];
% end

% Converti data in cell
tabcell = struct2cell(data)';
% tabcell = [tabcell(:,1) tabcell(:,3) tabcell(:,5)];

% Controlla se in Signals for processing sono già presenti altri segnali e
% se non è ancora stato caricato nulla:
if isempty(utilities.handles.table.Data)
    signalsToProcess = tabcell(ListBoxValue,[1 2 3]);
    data_processing = data(ListBoxValue,:);
    % Ordina per ordine alfabetico data
    data_processing = SortStruct(data_processing);
    
    % Se sono già stati caricati ci sono due opzioni dettate dalla domanda sotto
else ~isempty(utilities.handles.table.Data)
    data_processing = evalin('base', 'data_processing');
    quest = 'Do you want to preserve the signals that are within the Signals for Processing table?';
    defaultAnsw = 'Yes';
    answer = questdlg(quest,'Answer to continue','Yes','No',defaultAnsw)
    if strcmp(answer,'Yes')
        selectedData = data(ListBoxValue,:);
        existingSignals = utilities.handles.table.Data;
        
        %%% Controlla se i segnali selezionati non siano già stati caricati nella signals for processing list
        for k = 1:size(selectedData,1)
            for j = 1:size(existingSignals,1)
                if ismember(selectedData(k).name,existingSignals(j,1))
                    h=msgbox('The selected data have been already uploaded into "Signal for processing" list!','Update','error');
                    return
                end
            end
        end
        %%%
        signalsToProcess = [existingSignals; tabcell(ListBoxValue,[1 2 3])];
        %%%%%% QUI DI SEGUITO LE RIGHE PER RICREARE IL VETTORE data_processing
        data_processing = [data_processing; selectedData];
        % Ordina per ordine alfabetico data
        data_processing = SortStruct(data_processing);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
    if strcmp(answer,'No')
        signalsToProcess = tabcell(ListBoxValue,[1 2 3]);
        data_processing = data(ListBoxValue,:);
        % Ordina per ordine alfabetico data
        data_processing = SortStruct(data_processing);
    end
end

% signalsToProcess = data_processing;


% Metti in ordine alfabetico
signalsToProcess = sortrows(signalsToProcess,[1,1]);
%Riempi tabella
set(utilities.handles.table,'ColumnEditable', [false false true], 'ColumnFormat', {'char','numeric', {'East', 'North', 'Vertical'}}, 'data', signalsToProcess,'ColumnName',{'ID','Fs','Comp'});
% set(utilities.handles.table,'max',length(LboxNames)); %make it so you can select more than 1.


% Se tabcell non è vuota attiva il uimenu
if not(isempty(tabcell))
    set(findobj(utilities.handles.mainFig,'type','uimenu'),'enable','on');
end

cd(utilities.softwareFolder)