%%%%%%%%%%%%%%      file_LoadSignals          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Questa funzione serve per caricare segnali raw e quindi in formato
% .miniseed. Oppure caricare segnali che sono già stati processati e
% salvati nel formato .taru

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [data,LboxNames] = file_LoadSignals
global utilities
global mainCrossFig
% global data % Inizializzo il vettore data da riempire

%%%%%    Waitbar   %%%%%
wait = findobj(utilities.handles.mainFig,'tag','wait');
handleToWaitBar = findobj(utilities.handles.mainFig,'tag','handleToWaitBar');
%%%%%%%%%%%%%%%%%%%%%%%%%

waitfor(msgbox({'You can do single or multiple selection of both .miniseed and .taru file extension'; ...
    ' NB You can either load .mseed exported from Geopsy but it takes more time'}))

% 0) Selezione segnali
[fileName,folder] = uigetfile({'*.*'},'Select file to be loaded','MultiSelect', 'on');

% 1) Numero segnali caricati
if ischar(fileName)
    Nsignals = 1;
else
    Nsignals = length(fileName);
end

% 2) Carico segnali
for i = 1:Nsignals
    % 1) Scegli un segnale per volta da importare
    if Nsignals == 1 %Se è stato caricato solo un segnale
        signal = fileName;
    else
        signal = fileName{1,i}; %Se sono stati caricati più segnali
    end
    
    
    % 3) Valuta estensione file
    [filepath,name,ext] = fileparts(signal); % ext = estensione file
    
    %% 4) Se il file caricato è .taru
    if strcmp(ext,'.taru')
        if ~exist('data_processing') %se non esiste data_processing crealo
            data_processing = [];
        end
        cd(folder)
        load(signal, '-mat' )
        data_processing_Importing = data_processing;
        LboxNames = [];
        
        
        
        % Controlla se in Signals for processing sono già presenti altri segnali e
        % se non è ancora stato caricato nulla:
        if isempty(utilities.handles.table.Data)
            data_processing = data_processing_Importing;
            % Ordina per ordine alfabetico data
            data_processing = SortStruct(data_processing);
            
            % Se sono già stati caricati ci sono due opzioni dettate dalla domanda sotto
        else ~isempty(utilities.handles.table.Data)
            data_processing = evalin('base', 'data_processing');
            data_processing_Existing = data_processing;
            
            quest = 'Do you want to preserve the signals that are within the Signals for Processing table?';
            defaultAnsw = 'Yes';
            answer = questdlg(quest,'Answer to continue','Yes','No',defaultAnsw);
            
            
            if strcmp(answer,'Yes')
                data_processing_Existing_Check = data_processing_Existing;
                %%% Se sono già presenti alcuni segnali scegli se aggionarli o mantenere gli stessi
                for j = 1:size(data_processing_Importing,1)
                    checksignals = [];
                    %%% Controlla se esiste già un segnale con stesso nome
                    for kk = 1:size(data_processing_Existing_Check,1)
                        checksignals =  [checksignals strcmp(data_processing_Importing(j).name,data_processing_Existing_Check(kk).name)];
                    end
                    %%%
                    if  any(checksignals)%Se sono già stati caricati puoi scegliere se aggiornali o no
                        quest = [data_processing_Importing(j).name ' already exists. Do you want to substitute it with the new one?'];
                        defaultAnsw = 'Yes';
                        answer = questdlg(quest,'Answer to continue','Yes','No',defaultAnsw);
                        if strcmp(answer,'Yes')
                            index = find(checksignals);
                            data_processing_Existing(index) = data_processing_Importing(j,:);
                        end
                        if strcmp(answer,'No')
                            break
                        end
                    else %Altrimenti aggiungili tutti
                        data_processing_Existing =[data_processing_Existing;  data_processing_Importing(j,:)];
                    end
                end
                % Ordina per ordine alfabetico data
                data_processing = SortStruct(data_processing_Existing);
            end
            
            if strcmp(answer,'No')
                data_processing = data_processing_Importing;
                % Ordina per ordine alfabetico data
                data_processing = SortStruct(data_processing);
            end
        end
        
        
        %4.1 Converti data in cell
        tabcell = struct2cell(data_processing)';
        %4.2 Riempi tabella
        set(utilities.handles.table,'ColumnEditable', [false false true], 'ColumnFormat', {'char','numeric', {'East', 'North', 'Vertical'}}, 'data', tabcell(:,[1 2 3]),'ColumnName',{'ID','Fs','Comp'});
        %4.3 Se tabcell non è vuota attiva il uimenu
        if not(isempty(tabcell))
            set(findobj(utilities.handles.mainFig,'type','uimenu'),'enable','on');
        end
        assignin('base','data_processing',data_processing)
        cd(utilities.softwareFolder)
        
        % se esiste data
        ise = evalin( 'base', 'exist(''data'',''var'') == 1' );
        if ise
        data = evalin('base', 'data');
        else
            data = [];
        end
    else
        
        %% 5) Se il file/i file caricato/i è/sono .miniseed o RaspberryShake
        [X,I,datocreato] = file_loadminiseed_function(signal,Nsignals,folder);
        %%%%%% Questo secondo if serve per fare in modo che se datosegnale esiste già, i segnali che vengono caricati nuovamente vengono aggiunti al vettore datosegnale
        if exist('data')== 1
            data = data;
        else
            data = [];
        end
        data = [data; datocreato];
    end
    
    %%%%%    Waitbar   %%%%%
    set(wait,'visible','on')
    set(handleToWaitBar,'visible','on')
    p = get(handleToWaitBar,'Child');
    x = get(p,'XData');
    x(3:4) = i/Nsignals;
    set(p,'XData',x);
    drawnow
    %%%%%%%%%%%%%%%%%%%%%%%%%
end

%% 6) Crea lista nomi per riempire listbox
if ~strcmp(ext,'.taru') %solo quando si carica un .miniseed
    for ind=1:length(data)
        LboxNames{ind} = data(ind).name; %compile cell array of names.
    end
    
    % Riempi listbox
    set(utilities.handles.listRaw,'string',LboxNames,'FontSize',utilities.ListboxfontSize,'Value',1); % Ho dovuto mettere Value,1 perchè altrimenti quando caricavo un solo segnale la listRaw non si riempiva
    set(utilities.handles.listRaw,'max',length(LboxNames)); %make it so you can select more than 1.
    cd(utilities.softwareFolder)
end

% Display che il load è avvenuto
beep on; beep
h=msgbox('Data have been successfully loaded!','Update','warn');
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

end



