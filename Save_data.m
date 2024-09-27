function Save_data
global dataToSave
global SaveDataUIFigure
if ~isempty(dataToSave)  % Se esistono variabili da salvare
    
    % 1) Preparing data to save
    % List Data in Global dataToSave variable and put it in the listbox
    ListVariables = fieldnames(dataToSave);
    
    
    % 2) Graphycal interface
    % Crea figure
    SaveDataUIFigure = figure('numbertitle','off','Name','Save .m data','toolbar','none','menubar','none','units','normalized','Position', [0.4 0.3 0.3 0.5]);
    % Save in:
    uicontrol('style','text','units','normalized','position',[.05 .85 .15 .1],'string','Save in:','FontSize',10); %Title
    uicontrol('style','edit','units','normalized','position',[.07 .85 .77 .05],'enable','off','tag','folderSaveEdit'); %Bar
    uicontrol('style','pushbutton','units','normalized','position',[.85 .85 .13 .05],'string','Browse','callback',@(btn,event) folderSaveButtonpushed(btn)); % Button
    % Saving name
    uicontrol('style','text','units','normalized','position',[.05 .75 .37 .05],'string','Name of the exported file:','FontSize',10); %Title
    uicontrol('style','edit','units','normalized','position',[.07 .70 .77 .05],'enable','on','HorizontalAlignment','left',...
        'TooltipString','Do no specify any extension! The code will save data in .mat format',...
        'Callback',@(hObject, eventdata) SaveButtonActivation(hObject, eventdata),'tag','saveDataNameTag'); %Bar
    %     Display list of variable to save [.07 .2 .77 .6]
    uicontrol('style','text','units','normalized','position',[.05 .6 .27 .05],'string','Select file to save:','FontSize',10); %Title
    uicontrol('Style','listbox','units','normalized','position',[.07 .05 .77 .55],...
        'string',ListVariables,'value',1,'backgroundcolor',[1 1 1],'min',0,'max',10,'FontSize',10,...
        'Callback',@(hObject, eventdata) SaveButtonActivation(hObject, eventdata),'Tag','listDataToSaveTag');
    % Button save
    uicontrol('style','pushbutton','units','normalized','position',[.85 .05 .13 0.05],'string','Save','fontweight','bold','Enable','off','Tag','SaveButtonTag',...
        'TooltipString','The selected data will be saved within a .mat file','callback',@(btn,event) SaveButton(btn));
    
end


% Funzione Seleziona cartella dove salvare i file
    function folderSaveButtonpushed(btn)
        selpath = uigetdir;
        set(findobj(SaveDataUIFigure,'tag','folderSaveEdit'),'string',selpath);
    end

% Funzione Save
    function SaveButton(btn)
        % Folder dove salvarle
        saveInFolder = get(findobj(SaveDataUIFigure,'tag','folderSaveEdit'),'String')
        % Nome del file per salvataggio
        saveDataName = get(findobj(SaveDataUIFigure,'tag','saveDataNameTag'),'String')
        % Variabili da salvare:
        ListVariables = fieldnames(dataToSave); % Lista variabili in dataToSave
        selectedDataValue = get(findobj(SaveDataUIFigure,'tag','listDataToSaveTag'),'Value');
        selectedDatatoSave = ListVariables(selectedDataValue) % Variabili selezionate
        removeFromDataToSave = setdiff(ListVariables,selectedDatatoSave); %Variabili non selezionate
        saveSelection = rmfield(dataToSave,removeFromDataToSave) % Variabili da salvare

        eval(['save(''' saveInFolder '\' saveDataName '.mat''' ',' '''saveSelection''' ');'])
        close(gcf)
    end


end

% Attivazione tasto Save quando seleziono i dati
function SaveButtonActivation(hObject,eventdata)
global SaveDataUIFigure
saveInFolder = get(findobj(SaveDataUIFigure,'tag','folderSaveEdit'),'String')
saveDataName = get(findobj(SaveDataUIFigure,'tag','saveDataNameTag'),'String')
selectedDataValue = get(findobj(SaveDataUIFigure,'tag','listDataToSaveTag'),'Value');

if ~isempty(saveInFolder) && ~isempty(saveDataName) && ~isempty(selectedDataValue)
    set(findobj('Tag','SaveButtonTag'),'enable','on')
end
end



















