%%%%%%%%%%             Proc_cut: Taglio segnali                %%%%%%%%%%%%
% Questa funzione serve per tagliare i segnali selezionati.
% Due opzioni sono disponibili: Si può tagliare il segnale definendo come
% inizio e fine del cut l'ora precisa. Questa opzione si abilita attivando
% l'opzione "this time". Nel caso in cui si scegliesse l'opzione T0 il
% segnale non viene tagliato all'inizio. Però, nel caso in cui più segnali
% fossero stati selezionati, l'opzione T0 prevede che venga scelto come T0 il
% primo orario comune a tutti i segnali selezionati. Lo stesso per End in
% cui verrà scelto l'orario finale comune a tutti segnali selezionati.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data_processing = proc_cut(data_processing)
global utilities
waittext = uicontrol(utilities.handles.mainFig,'style','text','units','normalized','position',[.93 .01 .06 .04],'string','Wait...',...
    'ForegroundColor','r','FontSize',12,'FontWeight','bold','Tag','waittext');

%% 0) Prima di applicare la funzione controlla che qualche segnale sia stato selezionato!
if logical(evalin('base','~exist(''selected'')'))
    h=msgbox('No data have been selected! Please select data from "Signal for processing" list!','Update','error');
    return
else
    selected = evalin('base','selected'); % Se esiste carica la variabile selected dal base-workspace
end

%% 1) Creo vettore dei dati selezionati dalla tabella
% Dati per merge
data_selected = data_processing(selected,1); %Dati selezionati da tabella "Signal for processing"
% Dati su cui non fare merge
data_NOTselected = data_processing;
data_NOTselected(selected) = [];

%% 2a) Definisco T0
if size(data_selected,1) == 1 %Se solo un segnale è stato selezionato
    T0 = data_processing(selected(1)).timeAx(1);
else % se più segnali sono stati selezionati
    T0 = data_processing(selected(1)).timeAx;
    initialT0 = []; %Vettore che contiene tutti i primi valori degli assi temporali
    for k = 1:length(selected)
        eval(['initialT0 = [initialT0; data_selected(' num2str(k) ').timeAx(1)];']);
    end
    T0 = max(initialT0);
end

%% 2b) Definisco End
if size(data_selected,1) == 1 %Se solo un segnale è stato selezionato
    End = data_processing(selected(1)).timeAx(end);
else % se più segnali sono stati selezionati
    End = data_processing(selected(1)).timeAx;
    finalEnd = []; %Vettore che contiene tutti i primi valori degli assi temporali
    for k = 1:length(selected)
        eval(['finalEnd = [finalEnd; data_selected(' num2str(k) ').timeAx(end)];']);
    end
    End = min(finalEnd)
end

%% 3) Crea finestra proc_cut
% a) Create figure
Cutfigure = figure('NumberTitle','off','Name','Cut signals','ToolBar','none','MenuBar','none','Position',[600 450 357 150]);

% b) Create label
from = uicontrol(Cutfigure,'Style','text','Position',[28 106 33 22],'HorizontalAlignment','right','String','From','FontSize',9);
to = uicontrol(Cutfigure,'Style','text','Position',[36 65 25 22],'HorizontalAlignment','right','String','To','FontSize',9);

% c) Create popupmenu
utilities.handles.from_popup = uicontrol(Cutfigure,'Style','popupmenu','FontWeight','bold','Position',[76 106 100 22],...
    'TooltipString','If more than one signal is selected, T0 is considered as the common initial time among all the signals',...
    'String',{'T0', 'This time'}','Callback',@ From_Activate);
utilities.handles.to_popup = uicontrol(Cutfigure,'Style','popupmenu','FontWeight','bold','Position',[76 65 100 22],...
    'TooltipString','If more than one signal is selected, End is considered as the common final time among all the signals',...
    'String',{'End', 'This time'}','Callback',@ To_Activate);

% d.1) Create edit field
utilities.handles.from_edit = uicontrol(Cutfigure,'Style','edit','Position',[211 106 123 22],'Enable','off','TooltipString','dd-mmm-yyyy HH:MM:SS.FFF','String',datestr(T0,'dd-mmm-yyyy HH:MM:SS.FFF'));
utilities.handles.to_edit = uicontrol(Cutfigure,'Style','edit','Position',[211 65 123 22],'Enable','off','TooltipString','dd-mmm-yyyy HH:MM:SS.FFF','String',datestr(End,'dd-mmm-yyyy HH:MM:SS.FFF'));

% e) Create Compute button
compute = uicontrol(Cutfigure,'Style','pushbutton','Position', [211 21 58 22],...
    'String','Compute','Callback', @(btn,event) ButtonPushed_Compute(btn,Cutfigure,utilities.handles.from_edit,utilities.handles.to_edit,data_processing,selected,data_selected,data_NOTselected));
% f) Create Cancel button
cancel = uicontrol(Cutfigure,'Style','pushbutton','Position',  [277 21 57 22],...
    'String','Cancel','Callback', @(btn, event) ButtonPushed_Cancel(btn,Cutfigure));


%% Activation "From" editing
    function From_Activate(from_popup,from_edit)
        % From
        switch get(from_popup, 'Value')
            case 1 % If "T0" is selected
                set(utilities.handles.from_edit, 'Enable', 'off');
            case 2 % If "This time" is selected
                set(utilities.handles.from_edit, 'Enable', 'on');
        end
    end

%% Activation "To" editing
    function To_Activate(to_popup,to_edit)
        % To
        switch get(to_popup, 'Value')
            case 1
                set(utilities.handles.to_edit, 'Enable', 'off');
            case 2
                set(utilities.handles.to_edit, 'Enable', 'on');
        end
    end

end

%%%%%%%%%%%%%%       ButtonPushed_Compute          %%%%%%%%%%%%%%%%%%%%%%%%
% Questa funzione taglia i segnali al tempo definito in cutfigure
function data_processing = ButtonPushed_Compute(btn,Cutfigure,from_edit,to_edit,data_processing,selected,data_selected,data_NOTselected)
global utilities
startcut = datenum(get(utilities.handles.from_edit,'String'));
endcut = datenum(get(utilities.handles.to_edit,'String'));

for k = 1:size(data_selected,1)
    % Taglia all'inzio
    eval(['data_selected(' num2str(k) ').signal(data_selected(' num2str(k) ').timeAx<startcut) = [];'])
    eval(['data_selected(' num2str(k) ').timeAx(data_selected(' num2str(k) ').timeAx<startcut) = [];'])
    % Taglia alla fine
    eval(['data_selected(' num2str(k) ').signal(data_selected(' num2str(k) ').timeAx>endcut) = [];'])
    eval(['data_selected(' num2str(k) ').timeAx(data_selected(' num2str(k) ').timeAx>endcut) = [];'])
end

% Finale
data_processing = [data_NOTselected; data_selected]; %Assembla i segnali che sono stati mergiati e quelli non toccati
% Ordina per ordine alfabetico data_processing 
data_processing = SortStruct(data_processing);
assignin('base','data_processing',data_processing)

%% Riempi la tabella con i segnali di cui è stato fatto il Cut
% Converti data in cell
tabcell = struct2cell(data_processing)';
% Svuota Tabella che conteneva tutta la lista completa dei segnali caricati
set(utilities.handles.table,'ColumnEditable', [false false true],'ColumnFormat', {'char','numeric', {'East', 'North', 'Vertical'}},'data',[],'ColumnName',{'ID','Fs','Comp'});
% Riempi tabella con segnali tagliati
set(utilities.handles.table,'ColumnEditable', [false false true], 'ColumnFormat', {'char','numeric', {'East', 'North', 'Vertical'}}, 'data', tabcell(:,[1 2 3]),'ColumnName',{'ID','Fs','Comp'});


h=msgbox('Data has been cut!','Update','warn');
pause(1)
close(h);close(Cutfigure)
delete(findobj('tag','waittext'));drawnow
clc
end

%%%%%%%%%%%%%%       ButtonPushed_Cancel        %%%%%%%%%%%%%%%%%%%%%%%%%%%
function ButtonPushed_Cancel(btn,Cutfigure)
beep
h=msgbox('No data has been cut!','Update','warn');
pause(1)
close(h);close(Cutfigure)
clc
end
