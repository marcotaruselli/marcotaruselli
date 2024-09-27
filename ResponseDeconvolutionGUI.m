function ResponseDeconvolutionGUI(data_processing)
global signalDeconv

%% Controlli iniziali
% 1) Prima di applicare la funzione controlla che qualche segnale sia stato selezionato!
if logical(evalin('base','~exist(''selected'')')) % Se non sono stati selezionati termina la funzione con questo messaggio di errore
    beep
    h=msgbox('No data have been selected! Please select data from "Signal for processing" list!','Update','error');
    return
else selected = evalin('base','selected'); % Se esiste carica la variabile selected dal base-workspace
end

% 2) Seleziono i dati selezionati dalla tabella in MainPassive
% Dati da processare
data_selected = data_processing(selected,1); %Dati selezionati da tabella "Signal for processing"
% Dati da NON processare
data_NOTselected = data_processing;
data_NOTselected(selected) = [];

% % 2.1) Check if the two components have the same time length
% if ~isequal(length(data_selected(1).signal),length(data_selected(2).signal))
%     beep
%     waitfor(msgbox({'The two components must have the same length!'; 'Cut them before proceeding!'},'Update','error'))
%     return
% end


%% da qui codice di Diego

fui = figure('units','normalized','position',[.3 .3 .4 .3],'menubar','none','name','Response Deconvolution','numbertitle','off');

currDir = cd;

uicontrol('style','text','units','normalized','position',[.01 .9 .85 .1],'string','Select Folder with JEvalResp')
uicontrol('style','edit','units','normalized','position',[.01 .8 .85 .1],'enable','off','string',currDir,'tag','jEvalFolder');
uicontrol('style','pushbutton','units','normalized','position',[.865 .8 .13 .1],'string','Browse','callback',@FolderButtonpushed)

uicontrol('style','text','units','normalized','position',[.01 .65 .85 .1],'string','Select Sensor response')
uicontrol('style','edit','units','normalized','position',[.01 .55 .85 .1],'enable','off','tag','sensorRespName');
uicontrol('style','pushbutton','units','normalized','position',[.865 .55 .13 .1],'string','Browse','callback',@SensorButtonpushed)

uicontrol('style','text','units','normalized','position',[.01 .4 .85 .1],'string','Select Digitizer response')
uicontrol('style','edit','units','normalized','position',[.01 .3 .85 .1],'enable','off','tag','digitizerRespName');
uicontrol('style','pushbutton','units','normalized','position',[.865 .3 .13 .1],'string','Browse','callback',@DigitizerButtonpushed)

uicontrol('style','text','units','normalized','position',[.05 .15 .1 .07],'string','Filter','horizontalalignment','right')
uicontrol('style','popupmenu','units','normalized','position',[.16 .21 .12 .03],'string',{'None','HighPass'},'value',2,'tag','filterType');
uicontrol('style','edit','units','normalized','position',[.29 .16 .1 .07],'string','0.05','tag','filterFreq',...
    'Tooltip','Advide: select a frequency close to the cutoff frequency of the sensor (i.e. 0.05 for Trillium; 0.5 for Raspberry)');

uicontrol('style','checkbox','units','normalized','position',[.45 .17 .15 .05],'value',0,'string','Plot results','tag','plotResults',...
'Tooltip','Advice: do not plot results if you are deconvolving more than one signal');

% uicontrol('style','pushbutton','units','normalized','position',[.73 .01 .13 .1],'string','Deconvolve','fontweight','bold','callback',...
%     'signalDeconv = PolResponseDeconvolution(fui,data,fs);')

uicontrol('style','pushbutton','units','normalized','position',[.73 .01 .13 .1],'string','Deconvolve','fontweight','bold','callback',@DeconvolveButtonpushed)

uicontrol('style','pushbutton','units','normalized','position',[.865 .01 .13 .1],'string','OK','fontweight','bold','enable','off');%,'callback',...
%     'assignin(''base'',''data'',signalDeconv);clear signalDeconv; Undo;')

uicontrol('style','text','units','normalized','position',[.02 .01 .7 .05],'string','Please wait...','visible','off','tag','pleaseWait',...
    'horizontalalignment','left')


    function FolderButtonpushed(~,~)
        selpath = uigetdir(currDir,'Select Folder with JEvalResp');
        set(findobj(fui,'tag','jEvalFolder'),'string',selpath);
        currDir = selpath;
    end


    function SensorButtonpushed(~,~)
        [filename, path] = uigetfile([currDir '\*.*'],'Select Sensor Response file','MultiSelect','off');
        set(findobj(fui,'tag','sensorRespName'),'string',[path filename]);
        currDir = path;
    end


    function DigitizerButtonpushed(~,~)
        [filename, path] = uigetfile([currDir '\*.*'],'Select Digitizer Response file','MultiSelect','off');
        set(findobj(fui,'tag','digitizerRespName'),'string',[path filename]);
        currDir = path;
    end


    function DeconvolveButtonpushed(~,~)
        
        %% Barra caricamento
        %Loading bar
        barracaricamento = waitbar(0,'Computing Response Deconvolution','Units','normalized','Position',[0.73,0.06,0.25,0.08]);
        
        set(findobj(fui,'type','uicontrol'),'enable','off')
        set(findobj(fui,'tag','pleaseWait'),'visible','on','enable','on');
        drawnow;
        jEvalFolderstring = get(findobj(fui,'tag','jEvalFolder'),'string');
        %
        %         cd(tmpstring);
        %         addpath(jEvalFolderstring)
        %
        tmpString1 = get(findobj(fui,'tag','sensorRespName'),'string');
        tmpIndex = strfind(tmpString1,'\');
        if ~isempty(tmpIndex)
            sensorRespName = tmpString1(tmpIndex(end)+1:end);
            [status,msg] = copyfile(tmpString1,jEvalFolderstring,'f');
        else
            sensorRespName = [];
        end
        %
        tmpString2 = get(findobj(fui,'tag','digitizerRespName'),'string');
        tmpIndex = strfind(tmpString2,'\');
        if ~isempty(tmpIndex)
            digitizerRespName = tmpString2(tmpIndex(end)+1:end);
            [status,msg] = copyfile(tmpString2,jEvalFolderstring,'f');
        else
            digitizerRespName = [];
        end
        %
        filterTypeValue = get(findobj(fui,'tag','filterType'),'value');
        filterTypeString = get(findobj(fui,'tag','filterType'),'string');
        filterType = filterTypeString{filterTypeValue};
        filterFreq = str2double(get(findobj(fui,'tag','filterFreq'),'string'));
        
        % Filtro il segnale
        for i = 1:size(data_selected,1)
            %% Avanzamento barra di caricamento
            waitbar(i/size(data_selected,1),barracaricamento,['Computing Response Deconvolution for signal' num2str(i)]);
            
            signal = data_selected(i).signal;
            timeAx = data_selected(i).timeAx;
            fs = data_selected(i).fs;
%             signalRaw = signal;
            signalRaw = DataFiltering(signal,fs,timeAx,filterType,filterFreq,0);
            %         if strcmpi(filterType,'highpass')
            %             [signalRaw,~] = highpass(data,filterFreq,fs,'ImpulseResponse','iir','Steepness',0.95);
            %         end
            signalRaw = signalRaw - mean(signalRaw);
            
            % Deconvolution
            plotResults = get(findobj(fui,'tag','plotResults'),'value');
            [signalDeconv] = ResponseDeconvolution(fui,jEvalFolderstring,signalRaw,fs,sensorRespName,digitizerRespName,filterType,filterFreq,plotResults,timeAx);
            assignin('caller','signalDeconv',signalDeconv)
            %
            %         set(findobj(fui,'type','uicontrol'),'enable','on')
            %         set(findobj(fui,'tag','pleaseWait'),'visible','off','string','Please wait...');
            %         drawnow;
            
            % Sostituisco il segnale in ingresso con quello deconvoluto
            data_selected(i).signal = signalDeconv;
            data_selected(i).name = ['Dec_' data_selected(i).name];
        end
        
        %% chiudi barra di caricamento
        close(barracaricamento)
        
        %% Ricostruisci il vettore data_processing facendo l'update con i segnali filtrati
        data_processing = [data_NOTselected; data_selected] ;%Unisci i segnali che sono stati mergiati e quelli non toccati
        % Ordina per ordine alfabetico data_processing
        data_processing = SortStruct(data_processing);
        assignin('base','data_processing',data_processing);
        
        %% Riempi la tabella con i segnali di cui è stato fatto il Cut
        global utilities
        % Converti data in cell
        tabcell = struct2cell(data_processing)';
        % Svuota Tabella che conteneva tutta la lista completa dei segnali caricati
        set(utilities.handles.table,'ColumnEditable', [false false true],'ColumnFormat', {'char','numeric', {'East', 'North', 'Vertical'}},'data',[],'ColumnName',{'ID','Fs','Comp'});
        % Riempi tabella con segnali tagliati
        set(utilities.handles.table,'ColumnEditable', [false false true], 'ColumnFormat', {'char','numeric', {'East', 'North', 'Vertical'}}, 'data', tabcell(:,[1 2 3]),'ColumnName',{'ID','Fs','Comp'});
        

        %%  Da mettere alla fine: Cancella il vettore che indica quali segnali sono stati selezionati dalla
        % lista "Signal for processing"
        evalin( 'base', 'clearvars selected' )
        clc
        
        %% Chiudi la finestra della rimozione della risposta
        close(fui)
        beep on; beep
        h=msgbox('Data have been successfully deconvolved!','Update','warn');
        pause(1)
        close(h)
    end

end