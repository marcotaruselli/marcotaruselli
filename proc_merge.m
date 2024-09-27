%%%%%%%%%%%%%%%          ISTRUZIONI CODICE        %%%%%%%%%%%%%%%%%%%%%%%%%

%%% Questa funzione fa il merge di TUTTI segnali che sono stati caricati nella
%%% finestra "signals for processing". Il merge viene fatto per segnali appartenenti
%%% alla stessa stazione ed alla stessa componente.Li unisce rinominando il file con
%%% data-ora di inizio e fine registrazione. INOLTRE SE CI DOVESSERO ESSERE
%%% BUCHI TRA UN SEGNALE E L'ALTRO VENGONO RIEMPITI DI ZERI!!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function data_processing = proc_merge(data_processing)
global utilities

%%%%%    Waitbar   %%%%%
wait = findobj(utilities.handles.mainFig,'tag','wait');
handleToWaitBar = findobj(utilities.handles.mainFig,'tag','handleToWaitBar');
%%%%%%%%%%%%%%%%%%%%%%%%%

%% 0.0) Prima di applicare la funzione controlla che qualche segnale sia stato selezionato!
% Se non sono stati selezionati termina la funzione
if logical(evalin('base','~exist(''selected'')'))
    h=msgbox('No data have been selected! Please select data from "Signal for processing" list!','Update','error');
    return
else selected = evalin('base','selected'); % Se esiste carica la variabile selected dal base-workspace
end

%% 0) Seleziono i dati selezionati dalla tabella
% Dati per merge
data_selected = data_processing(selected,1); %Dati selezionati da tabella "Signal for processing"
% Dati su cui non fare merge
data_NOTselected = data_processing;
data_NOTselected(selected) = [];

%% 1) Faccio lista delle componenti e delle stazioni presenti nella tabella
for idx = 1:size(data_selected,1)
    stnName{1,idx} = data_selected(idx).stn;
    comp{1,idx} = data_selected(idx).Comp;
end
stnName = unique(stnName);
comp = unique(comp);

%% 2) fai passare i segnali e scegli quelli con stessa componente e stazione ed uniscili
dataEast = [];
dataNorth = [];
dataVertical = [];
timeEast = [];
timeNorth = [];
timeVertical = [];
fs = [];
i = 1;
for j = 1:length(stnName) %questo per scegliere una stazione
    %%% 2a) Qui avviene il merge per ciascuna componente di un singolo sensore
    
    for jj = 1:length(data_selected)
        
        % Componente X
        if strcmp(data_selected(jj).Comp,'East') && strcmp(stnName{1,j},data_selected(jj).stn) %controlla sia componente che stn selezionato
            if isempty(dataEast) % se è stato selezionato il primo segnale crea i vettori dataEast e timeEast
                dataEast = [dataEast; data_selected(jj).signal];
                timeEast = [timeEast; data_selected(jj).timeAx];
                fs = [fs; data_selected(jj).fs];
                
            elseif ~isempty(dataEast) % se dataEast esiste già, quindi se stiamo processando dal secondo segnale in avanti
                % Calcola quanti secondi ci sono tra la fine e l'inizio dei due segnali che si vogliono mergiare per vedere se ci sono buchi
                if jj < length(data_selected)
                    t1 = timeEast(end);
                    t2 = data_selected(jj).timeAx(1);
                    t11=datevec(datenum(t1));
                    t22=datevec(datenum(t2));
                    time_interval_in_seconds = etime(t22,t11);
                    % se ci sono buchi
                    if round(time_interval_in_seconds,5) ~=  1/data_selected(jj+1).fs % se il time interval è diverso dal ts c'è buco
                        Fs = data_selected(jj).fs;
                        timevect_parteMancante = t1+seconds(1/Fs):seconds(1/Fs):t2-seconds(1/Fs); %conto quanti secondi è lungo il buco
                        dato_parte_mancante = zeros(length(timevect_parteMancante),1); %Creo vettore di zeri parte mancante
                        dataEast = [dataEast; dato_parte_mancante; data_selected(jj).signal];
                        timeEast = [timeEast; datenum(timevect_parteMancante)'; data_selected(jj).timeAx];
                        fs = [fs; data_selected(jj).fs];
                    else
                        dataEast = [dataEast; data_selected(jj).signal];
                        timeEast = [timeEast; data_selected(jj).timeAx];
                        fs = [fs; data_selected(jj).fs];
                    end
                end
                if jj == length(data_selected)
                    dataEast = [dataEast; data_selected(jj).signal];
                    timeEast = [timeEast; data_selected(jj).timeAx];
                    fs = [fs; data_selected(jj).fs];
                end
            end
        end
        
        %             end
        
        
        % Componente Y
        if strcmp(data_selected(jj).Comp,'North') && strcmp(stnName{1,j},data_selected(jj).stn) %controlla sia componente che stn selezionato
            if isempty(dataNorth) % se è stato selezionato il primo segnale crea i vettori dataEast e timeEast
                dataNorth = [dataNorth; data_selected(jj).signal];
                timeNorth = [timeNorth; data_selected(jj).timeAx];
                fs = [fs; data_selected(jj).fs];
                
            elseif ~isempty(dataNorth) % se dataEast esiste già, quindi se stiamo processando dal secondo segnale in avanti
                % Calcola quanti secondi ci sono tra la fine e l'inizio dei due segnali che si vogliono mergiare per vedere se ci sono buchi
                if jj < length(data_selected)
                    t1 = timeNorth(end);
                    t2 = data_selected(jj).timeAx(1);
                    t11=datevec(datenum(t1));
                    t22=datevec(datenum(t2));
                    time_interval_in_seconds = etime(t22,t11);
                    % se ci sono buchi
                    if round(time_interval_in_seconds,5) ~=  1/data_selected(jj+1).fs % se il time interval è diverso dal ts c'è buco
                        Fs = data_selected(jj).fs;
                        timevect_parteMancante = t1+seconds(1/Fs):seconds(1/Fs):t2-seconds(1/Fs); %conto quanti secondi è lungo il buco
                        dato_parte_mancante = zeros(length(timevect_parteMancante),1); %Creo vettore di zeri parte mancante
                        dataNorth = [dataNorth; dato_parte_mancante; data_selected(jj).signal];
                        timeNorth = [timeNorth; datenum(timevect_parteMancante)'; data_selected(jj).timeAx];
                        fs = [fs; data_selected(jj).fs];
                    else
                        dataNorth = [dataNorth; data_selected(jj).signal];
                        timeNorth = [timeNorth; data_selected(jj).timeAx];
                        fs = [fs; data_selected(jj).fs];
                    end
                end
                if jj == length(data_selected)
                    dataNorth = [dataNorth; data_selected(jj).signal];
                    timeNorth = [timeNorth; data_selected(jj).timeAx];
                    fs = [fs; data_selected(jj).fs];
                end
            end
        end
        
        
        
        
        % Componente Z
        if strcmp(data_selected(jj).Comp,'Vertical') && strcmp(stnName{1,j},data_selected(jj).stn) %controlla sia componente che stn selezionato
            if isempty(dataVertical) % se è stato selezionato il primo segnale crea i vettori dataEast e timeEast
                dataVertical = [dataVertical; data_selected(jj).signal];
                timeVertical = [timeVertical; data_selected(jj).timeAx];
                fs = [fs; data_selected(jj).fs];
                
            elseif ~isempty(dataVertical) % se dataEast esiste già, quindi se stiamo processando dal secondo segnale in avanti
                % Calcola quanti secondi ci sono tra la fine e l'inizio dei due segnali che si vogliono mergiare per vedere se ci sono buchi
                if jj < length(data_selected)
                    t1 = timeVertical(end);
                    t2 = data_selected(jj).timeAx(1);
                    t11=datevec(datenum(t1));
                    t22=datevec(datenum(t2));
                    time_interval_in_seconds = etime(t22,t11);
                    % se ci sono buchi
                    if round(time_interval_in_seconds,5) ~=  1/data_selected(jj+1).fs % se il time interval è diverso dal ts c'è buco
                        Fs = data_selected(jj).fs;
                        timevect_parteMancante = t1+seconds(1/Fs):seconds(1/Fs):t2-seconds(1/Fs); %conto quanti secondi è lungo il buco
                        dato_parte_mancante = zeros(length(timevect_parteMancante),1); %Creo vettore di zeri parte mancante
                        dataVertical = [dataVertical; dato_parte_mancante; data_selected(jj).signal];
                        timeVertical = [timeVertical; datenum(timevect_parteMancante)'; data_selected(jj).timeAx];
                        fs = [fs; data_selected(jj).fs];
                    else
                        dataVertical = [dataVertical; data_selected(jj).signal];
                        timeVertical = [timeVertical; data_selected(jj).timeAx];
                        fs = [fs; data_selected(jj).fs];
                    end
                end
                if jj == length(data_selected)
                    dataVertical = [dataVertical; data_selected(jj).signal];
                    timeVertical = [timeVertical; data_selected(jj).timeAx];
                    fs = [fs; data_selected(jj).fs];
                end
            end
            
        end
        
    end

%%% 2b) Qui viene ricreata la struct data_processed
fs = unique(fs);
for kk = 1:length(comp)
    if ~isempty(timeEast)
        name = [stnName{1,j} '_' comp{kk} '_' datestr(timeEast(1,1),'ddmmm_HHMM') '_' datestr(timeEast(end,1),'ddmmm_HHMM')];
    elseif ~isempty(timeNorth)
        name = [stnName{1,j} '_' comp{kk} '_' datestr(timeNorth(1,1),'ddmmm_HHMM') '_' datestr(timeNorth(end,1),'ddmmm_HHMM')];
    else
        name = [stnName{1,j} '_' comp{kk} '_' datestr(timeVertical(1,1),'ddmmm_HHMM') '_' datestr(timeVertical(end,1),'ddmmm_HHMM')];
    end
    eval('data_merged(i,1).name = name;')
    eval('data_merged(i,1).fs = fs;')
    eval('data_merged(i,1).Comp = comp{kk} ;')
    eval('data_merged(i,1).stn =  stnName{1,j} ;')
    eval(['data_merged(i,1).signal = data' comp{kk} ';'])
    eval(['data_merged(i,1).timeAx = time' comp{kk} ';'])
    i = i+1;
end

dataEast = [];
dataNorth = [];
dataVertical = [];
timeEast = [];
timeNorth = [];
timeVertical = [];

%%%%%    Waitbar   %%%%%
set(wait,'visible','on')
set(handleToWaitBar,'visible','on')
p = get(handleToWaitBar,'Child');
x = get(p,'XData');
x(3:4) = i/length(stnName);
set(p,'XData',x);
drawnow
%%%%%%%%%%%%%%%%%%%%%%%%%
fs = [];
end

data_selected = data_merged;
data_processing = [data_NOTselected; data_selected]; %Assembla i segnali che sono stati mergiati e quelli non toccati

%%%%%% Parte inserita sopra ==> 3) controllo che i segnali importati non abbiamo spazi vuoti. Se ci sono riempili di zeri.
% for i = 1:size(data_processing,1)
%
%     % Prepara il segnale che sarà processato
%     segnale = data_processing(i).signal;
%     segnale = segnale';
%     segnale(2,:) = data_processing(i).timeAx;
%     % Metti zero al posto dei buchi
%     Fs = data_processing(i).fs;
%     [segnale_corretto] = setzerotoemptydata(segnale,Fs);
%     % Ririempi la struttura data_processing
%     data_processing(i).signal = segnale_corretto(1,:)';
%     data_processing(i).timeAx = segnale_corretto(2,:)';
% end
%%%%
%% 4) Riempi la tabella con i segnali di cui è stato fatto il Merge
% Ordina per ordine alfabetico data_processing
data_processing = SortStruct(data_processing)

% Converti data in cell
tabcell = struct2cell(data_processing)';
% tabcell = [tabcell(:,1) tabcell(:,3) tabcell(:,5)];

% Svuota Tabella che conteneva tutta la lista completa dei segnali caricati
set(utilities.handles.table,'ColumnEditable', [false false true],'ColumnFormat', {'char','numeric', {'East', 'North', 'Vertical'}},'data',[],'ColumnName',{'ID','Fs','Comp'});

% Riempi tabella con segnali mergiati
set(utilities.handles.table,'ColumnEditable', [false false true], 'ColumnFormat', {'char','numeric', {'East', 'North', 'Vertical'}}, 'data', tabcell(:,[1 2 3]),'ColumnName',{'ID','Fs','Comp'});
% set(utilities.handles.table,'max',length(LboxNames)); %make it so you can select more than 1.


% Se tabcell non è vuota attiva il uimenu
if not(isempty(tabcell))
    set(findobj(utilities.handles.mainFig,'type','uimenu'),'enable','on');
end

% Cancella il vettore che indica quali segnali sono stati selezionati dalla
% lista "Signal for processing"
evalin( 'base', 'clearvars selected' )

% Display che il merge è avvenuto
beep on; beep
h=msgbox('Data have been successfully merged!','Update','warn');
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

