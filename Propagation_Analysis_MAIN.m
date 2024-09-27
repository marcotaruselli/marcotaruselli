function Propagation_Analysis_MAIN(data_processing)
% global utilities
global mainPropFig
global data_selected
global Propagation
% global dataforPlotVideoCrossCorr

%% Controlli iniziali
% 1) Prima di applicare la funzione controlla che qualche segnale sia stato selezionato!
if logical(evalin('base','~exist(''selected'')')) % Se non sono stati selezionati termina la funzione con questo messaggio di errore
    beep
    msgbox('No data have been selected! Please select data from "Signal for processing" list!','Update','error');
    return
else
    selected = evalin('base','selected'); % Se esiste carica la variabile selected dal base-workspace
end

% 2) Seleziono i dati selezionati dalla tabella in MainPassive
data_selected = data_processing(selected,1); %Dati selezionati da tabella "Signal for processing"


% 2.1) Check if the selected signals have the same component
if ~isequal(data_selected(1).Comp, data_selected(2:end).Comp)
    beep
    waitfor(msgbox({'Same components MUST be selected!'},'Update','error'))
    return
end

% 2.2) Check if the signals have the same time length
for i = 2:size(data_selected,1)
    if ~isequal(length(data_selected(1).signal),length(data_selected(i).signal))
        beep
        waitfor(msgbox({'The selected signals must have the same length!'; 'Cut them before proceeding!'},'Update','error'))
        return
    end
end

% 2.3) Check if two different stations have been selected
if isequal(data_selected(1).stn, data_selected(2:end).stn)
    beep
    waitfor(msgbox({'You MUST select signals which belong to different stations!'},'Update','error'))
    return
end

% 2.4) Check if the two selected signals have the same Fs
if ~isequal(data_selected(1).fs, data_selected(2:end).fs)
    beep
    waitfor(msgbox({'The signals MUST have the same sampling frequency!'},'Update','error'))
    return
end

%% SIGNALS INFO ------------------------------------------------
mainPropFig = figure('units','normalized','outerposition',[0 0 1 1],'WindowState','maximized','toolbar','none','MenuBar','none',...
    'numbertitle','off','name','PropERSION CURVE ANALYSIS');

% Disegno riquadri
annotation(mainPropFig,'line',[0.13 0.995],[0.99 0.99],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga sopra orizzontale
annotation(mainPropFig,'line',[0.13 0.13],[0.007 0.99],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga sx verticale
annotation(mainPropFig,'line',[0.995 0.995],[0.007 0.99],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga dx verticale
annotation(mainPropFig,'line',[0.13 0.995],[0.007 0.007],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga sotto orizzontale
annotation(mainPropFig,'line',[0.527 0.527],[0.007 0.99],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga dx verticale
annotation(mainPropFig,'line',[0.527 0.995],[0.485 0.485],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga dx verticale


% Propersion curve: Stations ------------------------------------------------
uicontrol(mainPropFig,'style','text','units','normalized','position',[.006 .96 .118 .0285],...
    'string','Stations coordinates','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',[230/255 237/255 130/255]);
annotation(mainPropFig,'rectangle','Units','normalized','Position',[.005 .96 .119 .03],'FaceColor','none','Color',[0.6 0.6 0.6])

% Coordinate system
uicontrol('style','text','units','normalized','position',[.005 .9265 .06 .03],'Enable','on',...
    'string','Coordinate sys.','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8]);
uicontrol('style','popupmenu','units','normalized','position',[.065 .9225 .06 .034],'Enable','on',...
    'string',{'Cartesian','Geographical'},'horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'Tag','coordSystem','Tooltip',['If Geographical is selected you may set LAT and LONG either in degree or in decimal format' 10 ...
    'es. decimal ==> 10.633379  | degree ==>  46°58''34.60"'] );


% Crea tabella stazioni + coordinate
TableSelectedStations(data_processing)  %Posizione tabella ==> [.005 .785 .12 .1706]

% Button load
uicontrol(mainPropFig,'style','pushbutton','units','normalized','position',[.005 .7515-0.0335 .06 .03],...
    'string','Load coord.','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'Tag','LoadCoord','Callback',@(numfld,event) LoadCoordinates);

% Button save
uicontrol(mainPropFig,'style','pushbutton','units','normalized','position',[.065 .7515-0.0335 .06 .03],...
    'string','Save coord.','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'Tag','SaveCoord','Enable','off','Callback',@(numfld,event) SaveCoordinates);

% Button Compute distance of stations pair
uicontrol(mainPropFig,'style','pushbutton','units','normalized','position',[.005 .718-0.0335 .12 .03],...
    'string','Compute distance of stations-pair','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'Tag','statPairDist','Enable','off','Callback',@(numfld,event) TableStationsPairDistance);

%% Tabella distanze
columnname = {'','Stations pair','Distance'};
columnformat = {'logical','bank','bank'};
% Create the uitable
distTable = uitable(mainPropFig,'Units','normalized','Position',[0.005 .4754-0.0335 .12 .2376],...
    'ColumnWidth', {30 80 75},...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'ColumnEditable', [true false false],...
    'RowName',[],'Enable','on',...
    'Tag','distTable');%,...
Propagation.distTable = distTable;


% Table Distances position ==> [0.005 .4754 .12 .2376]

%% Cross-correlation parameters --------------------------------------------------------
uicontrol(mainPropFig,'style','text','units','normalized','position',[.006 0.4378-0.0335 .118 .0285],...
    'string','Cross-Correlation setting','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',[230/255 237/255 130/255]);
annotation(mainPropFig,'rectangle','Units','normalized','Position',[.005 0.4380-0.0335 .119 .03],'FaceColor','none','Color',[0.6 0.6 0.6])

% Time-length signals
uicontrol(mainPropFig,'style','text','units','normalized','position',[.005 .3688 .07 .03],...
    'string','Time length [m]','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off','tag','String_timelength_PP');
uicontrol(mainPropFig,'style','edit','units','normalized','position',[.075 .3688 .05 .03],...
    'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tag','timelength_PP','Enable','off',...
    'tooltipstring',['Select the signals time-length to compute the cross-correlation. Time in minutes' 10 ...
    'If the chosen length does not return null reminder, a first part of the signal will be discarded.']);

% Maxlag
uicontrol('style','text','units','normalized','position',[.005 .3368 .07 .03],...
    'string','Maxlag [s]','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off','tag','String_maxlag_PP');
uicontrol('style','edit','units','normalized','position',[.075 .3368 .05 .03],...
    'backgroundcolor',[1 1 1],'String',10,'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tag','maxlag_PP','Enable','off',...
    'tooltipstring','Express maxlag in second. The code will convert it in samples.');

% Whitening
uicontrol('style','text','units','normalized','position',[.005 .3048 .07 .03],...
    'string','Whitening','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off','Tag','String_whitening_PP');
uicontrol('style','checkbox','units','normalized','position',[.090 .3048 .03 .03],'String','yes',...
    'horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'Tag','whitening_PP','Enable','off',...
    'Value',1,'tooltipstring','If selected the signals will be whitened');

% Avarage cross-corr belonging to station pairs with same distance
uicontrol('style','text','units','normalized','position',[.005 .2728 .07 .03],...
    'string','Average Cross-corr','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off','Tag','String_avarageCrossCorr_PP');
uicontrol('style','checkbox','units','normalized','position',[.090 .2728 .03 .03],'String','yes',...
    'horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'Tag','avarageCrossCorr_PP','Enable','off',...
    'Value',1,'tooltipstring','FUNZIONE NON ANCORA ATTIVA!!!!If yes is selected, for the pairs of stations with same distance the corresponding cross-correlations will be averaged together');

% Button Compute cross-correlations of stations pairs
uicontrol(mainPropFig,'style','pushbutton','units','normalized','position',[.005 .2408 .12 .03],...
    'string','Compute cross-correlations','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'Tag','computeCrossCorrelations_PP','Enable','off','Callback',@(numfld,event) ComputeCrossCorr);

%% Propersion curve filtering
uicontrol(mainPropFig,'style','text','units','normalized','position',[.006 0.2058 .118 .0285],...
    'string','Cross-correlation filtering','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',[230/255 237/255 130/255]);
annotation(mainPropFig,'rectangle','Units','normalized','Position',[.005 0.2058 .119 .03],'FaceColor','none','Color',[0.6 0.6 0.6])

% Filter type
uicontrol(mainPropFig,'style','text','units','normalized','position',[.005 .1708 .06 .03],'Enable','off',...
    'string','Filter type','horizontalalignment','left','fontunits','normalized','fontsize',.5,'Tag','filtertype_text_PP',...
    'backgroundcolor',[.8 .8 .8]);
uicontrol(mainPropFig,'style','popupmenu','units','normalized','position',[.065 .1708 .06 .03],'Enable','off','tag','filter_type',...
    'string',{'Lowpass','Highpass','Bandpass','Dynamic'},'horizontalalignment','right','fontunits','normalized','fontsize',.5,'Tag','filtertype_checkbox_PP');
% Filter frequency
uicontrol(mainPropFig,'style','text','units','normalized','position',[.005 .1388 .06 .03],'Enable','off',...
    'string','Filter freq [Hz]','horizontalalignment','left','fontunits','normalized','fontsize',.5,'Tag','filterfreq_text_PP',...
    'backgroundcolor',[.8 .8 .8]);
uicontrol(mainPropFig,'style','edit','units','normalized','position',[.065 .1388 .06 .03],'Enable','off','tag','filter_frequency_PP',...
    'string','1','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Tag','filterfreq_PP',...
    'tooltipstring',['Indicate Fcut for Highpass/Lowpass i.e. 4' newline ...
    'Fcut1,Fcut2 for Bandpass i.e. 1,20' newline 'Fmin,Fmax,Fstep for dynamic i.e. 1,100,2' newline...
    'In "dynamic" case the Propagation will be filtered at frequency-step es.1-3Hz, 3-5Hz,...']);

% Button Compute cross-correlations Filterin
uicontrol(mainPropFig,'style','pushbutton','units','normalized','position',[.005 .1068 .12 .03],...
    'string','Compute filtering','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'Tag','computeFiltering_PP','Enable','off','Callback',@(numfld,event) ComputeFiltering_PP);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Creazione tabelle
function TableSelectedStations(data_processing)
global mainPropFig
global Propagation

% Segnali da processare
selected = evalin('base','selected');
data_selected = data_processing(selected,1); %Dati selezionati da tabella "Signal for processing"

% Dati per creazione tabella
columnname = {'Station','X (LAT)','Y (LONG)'};
columnformat = {'char','char','char'};

stationsList = cell(size(data_selected,1),3);
for i = 1:size(data_selected,1)
    stationsList{i,1} = data_selected(i).stn;
    stationsList{i,2} = [];
    stationsList{i,3} = [];
end

% Creo tabella
coordTable = uitable(mainPropFig,'Units','normalized','Position',[.005 .785-0.0335 .12 .1706],...
    'Data',stationsList,...
    'ColumnWidth', {50 67 67},...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'ColumnEditable', [false true true],... %serve per attivare la modifica delle coordinate
    'RowName',[],...
    'CellSelectionCallback', @(numfld,event) activateButton,...
    'Tag','coordTable');
Propagation.coordTable = coordTable;
end

function TableStationsPairDistance
%% Calcolo distanze
global mainPropFig
global Propagation
% Get coordinate system
coordSysOptions = get(findobj(mainPropFig,'tag','coordSystem'),'value');
coordSys_selected = get(findobj(mainPropFig,'tag','coordSystem'),'string');
coordSys_selected = coordSys_selected{coordSysOptions};

% Trovo coppie di stazioni possibili
coordTable = Propagation.coordTable;
stationsPairs = nchoosek(coordTable.Data(:,1)',2);
Propagation.stationsPairs = stationsPairs;

% Calcolo distanza e riempio Data per tabella
stationsPairData = cell(size(stationsPairs,1),3);
for i = 1:size(stationsPairs,1)
    k = find(strcmp(stationsPairs{i,1},coordTable.Data));
    j = find(strcmp(stationsPairs{i,2},coordTable.Data));
    
    % Data for table
    stationsPairData{i,1} = [true]; % checkbox
    stationsPairData{i,2} = [stationsPairs{i,1} '-' stationsPairs{i,2}]; % StationsPair
    
    % Calcolo distanza in funzione del tipo di sistema di riferimento
    if strcmp('Cartesian',coordSys_selected)
        selectedStationsCoordinates = [str2double(coordTable.Data{k,2}) str2double(coordTable.Data{k,3})]; %stazione 1
        selectedStationsCoordinates = [selectedStationsCoordinates; str2double(coordTable.Data{j,2}) str2double(coordTable.Data{j,3})]; %stazione 2
        stationsPairData{i,3} = pdist(selectedStationsCoordinates,'euclidean'); % Distance btw stations
    elseif strcmp('Geographical',coordSys_selected)
        % Elimino simboli che non servono
        % Coord stazione 1
        LAT1 =  strrep(coordTable.Data{k,2}, '°', ' ');
        LAT1 =  strrep(LAT1, '''', ' ');
        if ~strcmp(LAT1,coordTable.Data{k,2})
            LAT1 =  dms2degrees(str2num(strrep(LAT1, '"', ' ')));  %converti se non sono in decimali
        else
            LAT1 =  str2num(LAT1); %se è già in decimali converti in numero
        end
        LONG1 =  strrep(coordTable.Data{k,3}, '°', ' ');
        LONG1 =  strrep(LONG1, '''', ' ');
        if ~strcmp(LONG1,coordTable.Data{k,3})
            LONG1 =  dms2degrees(str2num(strrep(LONG1, '"', ' '))); %converti se non sono in decimali
        else
            LONG1 =  str2num(LONG1); %se è già in decimali converti in numero
        end
        % Coord stazione 2
        LAT2 =  strrep(coordTable.Data{j,2}, '°', ' ');
        LAT2 =  strrep(LAT2, '''', ' ');
        if ~strcmp(LAT2,coordTable.Data{j,2})
            LAT2 =  dms2degrees(str2num(strrep(LAT2, '"', ' '))); %converti se non sono in decimali
        else
            LAT2 =  str2num(LAT2); %se è già in decimali converti in numero
        end
        LONG2 =  strrep(coordTable.Data{j,3}, '°', ' ');
        LONG2 =  strrep(LONG2, '''', ' ');
        if ~strcmp(LONG2,coordTable.Data{j,3})
            LONG2 =  dms2degrees(str2num(strrep(LONG2, '"', ' '))); %converti se non sono in decimali
        else
            LONG2 =  str2num(LONG2); %se è già in decimali converti in numero
        end
        
        % Calcolo distanza
        stationsPairData{i,3} = pos2dist(LAT1,LONG1,LAT2,LONG2,1); % Distance btw stations in geographical coordinates
    end
    
end

% Ordina per distanza la tabella
[ranks_ordered, idx] = sort(cell2mat(stationsPairData(:,3)));
stationsPairData = stationsPairData(idx,:);

%% Riempio la tabella
% Column names and column format
columnname = {'','Stations pair','Distance'};
columnformat = {'logical','bank','bank'};

% Create the uitable
distTable = findobj(mainPropFig,'tag','distTable');
set(distTable,'enable','on'); %attivo tabella
set(distTable,'Data', stationsPairData); %import data
set(distTable,'ColumnWidth', {30 80 55}); %resize table

%% Attivo pulsanti per eseguire cross-correlazioni
set(findobj(mainPropFig,'tag','String_timelength_PP'),'enable','on');
set(findobj(mainPropFig,'tag','timelength_PP'),'enable','on');
set(findobj(mainPropFig,'tag','String_maxlag_PP'),'enable','on');
set(findobj(mainPropFig,'tag','maxlag_PP'),'enable','on');
set(findobj(mainPropFig,'tag','String_whitening_PP'),'enable','on');
set(findobj(mainPropFig,'tag','whitening_PP'),'enable','on');
% set(findobj(mainPropFig,'tag','String_avarageCrossCorr_PP'),'enable','on');
% set(findobj(mainPropFig,'tag','avarageCrossCorr_PP'),'enable','on');
set(findobj(mainPropFig,'tag','computeCrossCorrelations_PP'),'enable','on');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Attivazione Buttons
function activateButton
global Propagation
global mainPropFig

coordTable = Propagation.coordTable;
if ~any(cellfun(@isempty, coordTable.Data(:,2))) && ...
        ~any(cellfun(@isempty, coordTable.Data(:,3)))
    set(findobj(mainPropFig,'tag','SaveCoord'),'enable','on');
    set(findobj(mainPropFig,'tag','statPairDist'),'enable','on');
else
    set(findobj(mainPropFig,'tag','SaveCoord'),'enable','off');
    set(findobj(mainPropFig,'tag','statPairDist'),'enable','off');
end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Save & Load coordinates
function SaveCoordinates
global Propagation
% Carico tabella da salvare
coordTable = Propagation.coordTable;

waitfor(msgbox('The stations and the relative coordinates will be saved in a database with .coord extension'))
[filename, pathname] = uiputfile('*.coord','Save file as');
save(fullfile(pathname,filename),'coordTable')
% Proplay che il salvataggio è avvenuto
beep on; beep
h=msgbox('Data have been successfully saved!','Update','warn');
pause(1)
close(h)
end
function LoadCoordinates
global mainPropFig
global Propagation
[fileName,folder] = uigetfile({'*.coord*'},'Select file to be loaded','MultiSelect', 'off');
cd(folder)
load(fileName, '-mat' );

% Cancello tabella già esistente
delete(findobj(mainPropFig,'tag','coordTable'));

% Carico la tabella con già le coordinate
columnname = {'Station','X (LAT)','Y (LONG)'};
coordTable = uitable(mainPropFig,'Units','normalized','Position',[.005 .785-0.0335 .12 .1706],...
    'Data',coordTable.Data,...
    'ColumnWidth', {50 67 67},...
    'ColumnName', columnname,...
    'ColumnFormat', coordTable.ColumnFormat,...
    'ColumnEditable', [false true true],... %serve per attivare la modifica delle coordinate
    'RowName',[],...
    'CellSelectionCallback', @(numfld,event) activateButton,...
    'Tag','coordTable');
Propagation.coordTable = coordTable;

% Attiva buttons
activateButton
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ComputeCrossCorr
%% Get input from mainPropFig
global mainPropFig
global Propagation

selected = evalin('base','selected');
data_processing = evalin('base','data_processing');

% Cross-Corr input
timelength = str2num(get(findobj(mainPropFig,'tag','timelength_PP'),'string'));
whitening = get(findobj(mainPropFig,'tag','whitening_PP'),'value');
maxlag = str2num(get(findobj(mainPropFig,'tag','maxlag_PP'),'string'));
if isempty(timelength)
    beep
    waitfor(msgbox('You must specify the time length!','Update','error'));
    return
end
% Dati Propersion curve che vado ad integrare con le cross-correlation
distTable = findobj(mainPropFig,'tag','distTable');
dataForPropagation = distTable.Data;
% Seleziono solo le coppie che sono state checkate nella tabella%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NUOVO!!!
rowChecked = [distTable.Data{:,1}]';
dataForPropagation = dataForPropagation(rowChecked,:);

% % Coppie di stazioni %%%%%%%%%%%%%%%%%%%%%%%%% VECCHIO
%stationsPairs = Propagation.stationsPairs;

% Coppie di stazioni %%%%%%%%%%%%%%%%%%%%%%%%% NUOVO ==> fatto per poter
% considerare solo alcune coppie di sensori
a = char(dataForPropagation(:,2));
stn1 = a(:,1:5);
stn2 = a(:,7:end);
for i = 1:size(stn1,1)
   ChoosenstationsPairs{i,1} = stn1(i,:);
   ChoosenstationsPairs{i,2} = stn2(i,:);
end


% Segnali selezionati
data_selected = data_processing(selected,1); %Dati selezionati da tabella "Signal for processing"


%% Calcolo cross-correlazioni
%Loading bar
barracaricamento = waitbar(0,'Computing cross-correlations','Units','normalized','Position',[0.73,0.06,0.25,0.08]);

Fs = data_selected(1).fs;
Propagation.Fs = Fs;
maxlag=maxlag*Fs; % tempo di correlazione in punti
stazioni = {data_selected.stn};
for j = 1:size(ChoosenstationsPairs,1)
    %% 1) Signals for cross-correlation
    % Selezioni coppia sensori
    indSig1 = find(strcmp(ChoosenstationsPairs{j,1},stazioni),1);
    indSig2 = find(strcmp(ChoosenstationsPairs{j,2},stazioni),1);
    % Trovo i segnali corrispondenti
    signal_1 = data_selected(indSig1).signal;
    signal_2 = data_selected(indSig2).signal;
    
    
    %% 2) COMPUTING CROSS_CORRELATION
    % 2.1) Subdivide into subsignals which will be used to compute cross-correlation
    samplesTimeLength = timelength*60*Fs; %samples per second
    
    if rem(length(signal_1),samplesTimeLength) == 0
        signal_1 = reshape(signal_1,samplesTimeLength,[]);
        signal_2 = reshape(signal_2,samplesTimeLength,[]);
    else
        signal_1 = reshape(signal_1(rem(length(signal_1),samplesTimeLength)+1:end),samplesTimeLength,[]);
        signal_2 = reshape(signal_2(rem(length(signal_2),samplesTimeLength)+1:end),samplesTimeLength,[]);
    end
    
    % 2.2) Cross-correlation computation
    % Lista dei subsegnali
    subsignals = [1:size(signal_1,2)];
    numero=0;
    valid=0;
    param_time=1;
    
    for kk=1:length(subsignals)
        % Carica ogni singola traccia
        toto1_new_D1 = signal_1(:,kk);
        toto1_new_D2 = signal_2(:,kk);
        valid=valid+1;
        numero=numero+1; % conteggio del subsignal rispetto al primo
        index=(numero-1)*param_time; % conteggio del subsignal rispetto al primo
        
        
        %%%%%%%%%%%%%% FASE: WHITENING  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if whitening==1 %Se si applica il whitening
            
            % Traccia 1
            toto1=fft(toto1_new_D1); % Trasformata di fourier
            toto_final1=toto1./abs(toto1); % diviso per l'inverso del modulo equalizzando le frequenze.........'.*hanning(length(J)).^0.25)';
            toto_final1=real(ifft(toto_final1)); % Ritorno al segnale sbiancato..................................*hanning(length(toto_final1))';
            
            % Traccia 2
            toto2=fft(toto1_new_D2); % Trasformata di fourier
            toto_final2=toto2./abs(toto2);% diviso per l'inverso del modulo equalizzando le frequenze.........'.*hanning(length(J)).^0.25)';
            toto_final2=real(ifft(toto_final2));% Ritorno al segnale sbiancato..................................*hanning(length(toto_final1))';
            
        else % Se non si fa il whitening
            toto_final1=toto1_new_D1; % Non sbianco la traccia 1
            toto_final2=toto1_new_D2; % Non sbianco la traccia 2
        end
        %%%%%%%%%%%% FINE WHITENING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Opzioni cross-correlazione
        if valid==1
            % ###################### pourquoi /Fsnew
            time_corr_PP=[-maxlag:maxlag]/Fs; % intervallo di correlazione
            correlations=zeros(length(time_corr_PP),length(subsignals)*param_time); % inizializzazione dell'elenco delle correlazioni della coppia
            %             REFCorrelations_PP = zeros(size(correlations,1),size(stationsPairs,1));
            % ###################### qu'est-ce que Nan
            energie1=NaN(param_time*length(subsignals),1); % ?nergie 1
            energie2=NaN(param_time*length(subsignals),1); % ?nergie 2
        end
        
        %% pour chaque heure
        %Creo asse temporale
        Nombre_new=round(Fs*timelength*60);
        time_new=[0:Nombre_new-1]/Fs;
        for ii=1:param_time
            % intervallo di scorrimento per cross corr (th?oriquement 1h ?)
            interval=round(length(time_new)/param_time)*(ii-1)+[1:round(length(time_new)/param_time)];
            
            % Traccia 1 -remove mean & detrend
            minitrace1 = toto_final1;
            minitrace1=toto_final1(interval)-nanmean(toto_final1(interval)); %sottraggo media
            minitrace1=detrend(minitrace1); %Detrend           %minitrace1=max(0,minitrace1./max(abs(minitrace1)));%.*hanning(length(minitrace1))';;
            % Traccia 2 -remove mean & detrend
            minitrace2 = toto_final2;
            minitrace2=toto_final2(interval)-nanmean(toto_final2(interval)); %sottraggo media
            minitrace2=detrend(minitrace2); %Detrend           %minitrace2=max(0,minitrace2./max(abs(minitrace2)));%.*hanning(length(minitrace2))';
            
            
            energie1(index+ii)=sum(minitrace1.^2); % Energia della traccia 1 sull'intervallo considerato
            energie2(index+ii)=sum(minitrace2.^2); % Energia della traccia 1 sull'intervallo considerato
            
            % Correlazione
            if energie1(index+ii)~=0 && energie2(index+ii)~=0
                %test=xcorr(toto_final1(interval),toto_final2(interval),maxlag)./sqrt(energie1(index+ii).*energie2(index+ii)); % corr?lation crois?e normalis?e par rapport ? la racine carr?e du pdt des ?nergies au carr?
                test=xcorr(minitrace1,minitrace2,maxlag)./sqrt(energie1(index+ii).*energie2(index+ii));
                correlations(:,index+ii)=test; % ajout de la corr?lation consid?r?e (sur 1h) ? l'ensemble des corr?lations du jour consid?r?
                
                clear test % eliminazione delle variabili di correlazione
            end
        end
        
    end
    
    %%% if there are Nan in the correlations matrix set it equal to 0
    correlations(isnan(correlations))=0;
    
    %% CrossCorr media ==> di RIFERIMENTO
    REFCorrelations_PP(:,j) = nanmean(correlations,2);
    dataForPropagation{j,4} = nanmean(correlations,2);
    
    %% Avanzamento barra di caricamento
    waitbar((1/size(ChoosenstationsPairs,1))*j,barracaricamento,'Computing cross-correlations');
end
%%% PLOT: Rendo globali queste variabili per poter filtrare il grafico
Propagation.time_corr_PP = time_corr_PP;
Propagation.REFCorrelations_PP = REFCorrelations_PP;
Propagation.dataForPropagation = dataForPropagation;
close(barracaricamento)

%% Plot Propersion curve
PlotPropagation

%% Attivo pulsanti per eseguire filtro
set(findobj(mainPropFig,'tag','filtertype_text_PP'),'enable','on');
set(findobj(mainPropFig,'tag','filtertype_checkbox_PP'),'enable','on');
set(findobj(mainPropFig,'tag','filterfreq_text_PP'),'enable','on');
set(findobj(mainPropFig,'tag','filterfreq_PP'),'enable','on');
set(findobj(mainPropFig,'tag','computeFiltering_PP'),'enable','on');

end

function PlotPropagation
global Propagation
global mainPropFig
% Delete existing objects
delete(findobj(mainPropFig,'tag','PropCurv_Axis'));drawnow
delete(findobj(mainPropFig,'tag','xlimits_PPPlot'));drawnow
delete(findobj(mainPropFig,'tag','xlimits_PPPlot_text'));drawnow
delete(findobj(mainPropFig,'tag','crosscorrAMP_PPPlot_text'));drawnow
delete(findobj(mainPropFig,'tag','dynamicWinCorrSlider_PP'));drawnow
delete(findobj(mainPropFig,'tag','Reset_PPPlot'));drawnow
delete(findobj(mainPropFig,'tag','dynamicFiltersliderbar_PPPlot_text'));drawnow
delete(findobj(mainPropFig,'tag','dynamicFiltersliderbar_PPPlot'));drawnow

dataForPropagation = Propagation.dataForPropagation;
time_corr_PP = Propagation.time_corr_PP;

PropCurv_Axis = axes(mainPropFig,'Units','normalized','Position',[0.17 0.245 0.32 0.72],'Tag','PropCurv_Axis');
for i = 1:size(dataForPropagation,1)
    hold on
    plot(PropCurv_Axis,time_corr_PP,dataForPropagation{i,3}+dataForPropagation{i,4}./abs(max(dataForPropagation{i,4})),'color',[0,0,0]+0.5) %normalizzo per evidenziare le phases
end

ylim([0 dataForPropagation{end,3}+5]);
xlabel(PropCurv_Axis,'Correlation lag-time [s]','FontSize',12,'FontName','garamond');
ylabel(PropCurv_Axis,'Inter-station distance [m]','FontSize',12,'FontName','garamond');
% grid on; grid minor
PropCurv_Axis.XGrid = 'on';
PropCurv_Axis.YGrid = 'on';
PropCurv_Axis.XMinorGrid = 'on';
PropCurv_Axis.YMinorGrid = 'on';
PropCurv_Axis.Toolbar.Visible = 'on';
title(PropCurv_Axis,'Entire bandwidth','FontSize',10,'FontName','garamond');

% Pulsante modifica Xlimits
uicontrol(mainPropFig,'style','text','units','normalized','position',[.17 .150 .03 .03],...
    'string','Xlimits','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','xlimits_PPPlot_text');
uicontrol(mainPropFig,'style','edit','units','normalized','position',[.2 .150 .04 .03],'tag','xlimits_PPPlot',...
    'backgroundcolor',[1 1 1],'String',[num2str(PropCurv_Axis.XLim(1)) ',' num2str(PropCurv_Axis.XLim(2))],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring','Limits of xaxis. es. -2,2','Callback',@(numfld,event) updatePropagationPlot);

% Amplitude slidebar
uicontrol(mainPropFig,'style','text','units','normalized','position',[.2450 .150 .04 .03],...
    'string','Amplitude','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','crosscorrAMP_PPPlot_text');

NdynamicWinCorr = 10; %numero di steps della slidebar
stepSz = [1,NdynamicWinCorr];
uicontrol(mainPropFig,'style','slider','units','normalized','position',[.287 .150 .08 .03],...
    'Min',1,'Max',NdynamicWinCorr,'SliderStep',stepSz/(NdynamicWinCorr-1),'Value',1,...
    'Tag','dynamicWinCorrSlider_PP','callback',@(btn,event) sliderPlotAMP_PP(btn));

uicontrol(mainPropFig,'style','pushbutton','units','normalized','position',[.44 .150 .05 .03],'tag','Reset_PPPlot',...
    'backgroundcolor',[.7 .7 .7],'String','Reset','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring','Reset button plot back the NO-Filtered Propersion curve','Callback',@(numfld,event) PlotPropagation);

%%% se dynamic è stato scelto aggiungi la sliderbar per muoversi tra diverse frequenze
filterselected = get(findobj(mainPropFig,'tag','filtertype_checkbox_PP'),'value');
filtertype = get(findobj(mainPropFig,'tag','filtertype_checkbox_PP'),'string');
filtertype = filtertype(filterselected);
if strcmp(filtertype,'Dynamic')
    % Dynamic filter slider
uicontrol(mainPropFig,'style','text','units','normalized','position',[.17 .1068 .1150 .03],...
    'string','Change filter bandwidth','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','dynamicFiltersliderbar_PPPlot_text');
dataForPropagation_FILTERED = Propagation.dataForPropagation_FILTERED;
NdynamicWinCorr = size(dataForPropagation_FILTERED,2)-1; %numero di steps della slidebar
stepSz = [1,NdynamicWinCorr];
uicontrol(mainPropFig,'style','slider','units','normalized','position',[.287 .1068 .08 .03],...
    'Min',1,'Max',NdynamicWinCorr,'SliderStep',stepSz/(NdynamicWinCorr-1),'Value',1,...
    'Tag','dynamicFiltersliderbar_PPPlot','callback',@(btn,event) Filtersliderbar_PPPlot(btn));
end
%%%

% salvo le linee nel plot per poter usare la sliderbar
lineeMainplot = PropCurv_Axis.Children;
lineeMainplot_PP = zeros(length(lineeMainplot(1).YData),size(lineeMainplot,1));
for i = 1:size(lineeMainplot,1)
    lineeMainplot_PP(:,i) = lineeMainplot(i).YData';
end
Propagation.lineeMainplot_PP = lineeMainplot_PP;
end

function updatePropagationPlot
global mainPropFig
% Xlimits
xlimits = str2num(get(findobj(mainPropFig,'tag','xlimits_PPPlot'),'String'));
PropCurv_Axis = findobj(mainPropFig,'tag','PropCurv_Axis');
PropCurv_Axis.XLim = xlimits;
end

function ComputeFiltering_PP
global mainPropFig
global Propagation
% Get parameters
% filtering = get(findobj(mainPropFig,'tag','filtercheck_PP'),'value');
filterselected = get(findobj(mainPropFig,'tag','filtertype_checkbox_PP'),'value');
filtertype = get(findobj(mainPropFig,'tag','filtertype_checkbox_PP'),'string');
filtertype = filtertype(filterselected);
filterfreq = get(findobj(mainPropFig,'tag','filterfreq_PP'),'string');
Fs = Propagation.Fs;
dataForPropagation = Propagation.dataForPropagation;
dataForPropagation_FILTERED = dataForPropagation;
time_corr_PP = Propagation.time_corr_PP;

%Loading bar
barracaricamento = waitbar(0,'Filtering computation','Units','normalized','Position',[0.73,0.06,0.25,0.08]);

% Filtering
% Design lowpass filt
if strcmp(filtertype,'Lowpass')
    for j = 1:size(dataForPropagation,1)
        dataForPropagation_FILTERED{j,4} = lowpass(dataForPropagation{j,4},str2num(filterfreq), Fs,'ImpulseResponse','iir','Steepness',0.95);
        waitbar((1/size(dataForPropagation,1))*j,barracaricamento,'Filtering computation');
    end
Propagation.dataForPropagation_FILTERED = dataForPropagation_FILTERED;
PlotPropagation_FILTERED %It works only for low-high-band pass filtering    
end

% Design highpass filter
if strcmp(filtertype,'Highpass')
    for j = 1:size(dataForPropagation,1)
        dataForPropagation_FILTERED{j,4} = highpass(dataForPropagation{j,4},str2num(filterfreq), Fs,'ImpulseResponse','iir','Steepness',0.95);
        waitbar((1/size(dataForPropagation,1))*j,barracaricamento,'Filtering computation');
    end
Propagation.dataForPropagation_FILTERED = dataForPropagation_FILTERED;
PlotPropagation_FILTERED %It works only for low-high-band pass filtering    
end

% Design bandpass filter
if strcmp(filtertype,'Bandpass')
    for j = 1:size(dataForPropagation,1)
        dataForPropagation_FILTERED{j,4}   = bandpass(dataForPropagation{j,4},str2num(filterfreq), Fs,'ImpulseResponse','iir','Steepness',0.95);
        waitbar((1/size(dataForPropagation,1))*j,barracaricamento,'Filtering computation');    
    end
Propagation.dataForPropagation_FILTERED = dataForPropagation_FILTERED;
PlotPropagation_FILTERED %It works only for low-high-band pass filtering    
end

% Design dynamic filter
if strcmp(filtertype,'Dynamic')
filterfreqValues = str2num(filterfreq);
filterBands = filterfreqValues(1):filterfreqValues(3):filterfreqValues(2);
% Pre-alloco cell da riempire con i risultati
dataForPropagation_FILTERED = cell(size(dataForPropagation,1)+1,length(filterBands));
dataForPropagation_FILTERED{1,1} = 'Stations pairs';
for i = 1:size(dataForPropagation,1) %%%%%%%%%%%%
    % Titolo prima colonna
    dataForPropagation_FILTERED{i+1,1} =  dataForPropagation{i,2};
    for j = 1:length(filterBands)-1
        % Creo nome colonna
        if i == 1
            % Titolo prima riga
            dataForPropagation_FILTERED{1,j+1} = ['Bandwidth:' num2str(filterBands(j)) '-' num2str(filterBands(j+1))];
        end
        %Banda filtro
        filterBand = [filterBands(j) filterBands(j+1)];
        % Filtering
        resultFilterBand = bandpass(dataForPropagation{i,4},filterBand,Fs,'ImpulseResponse','iir','Steepness',0.95);
        dataForPropagation_FILTERED{i+1,j+1} = resultFilterBand;
        waitbar((1/size(dataForPropagation,1))*i,barracaricamento,'Filtering computation');
    end
end
Propagation.dataForPropagation_FILTERED = dataForPropagation_FILTERED;
% Plot for dynamic filtering
PlotPropagation_DynamicFilter   
end

close(barracaricamento)
end

function PlotPropagation_FILTERED
global Propagation
global mainPropFig
% Delete existing objects
delete(findobj(mainPropFig,'tag','PropCurv_Axis'));drawnow
PropCurv_Axis = findobj(mainPropFig,'tag','PropCurv_Axis');
cla(PropCurv_Axis)
delete(findobj(mainPropFig,'tag','xlimits_PPPlot'));drawnow
delete(findobj(mainPropFig,'tag','xlimits_PPPlot_text'));drawnow
delete(findobj(mainPropFig,'tag','crosscorrAMP_PPPlot_text'));drawnow
delete(findobj(mainPropFig,'tag','dynamicWinCorrSlider_PP'));drawnow
delete(findobj(mainPropFig,'tag','Reset_PPPlot'));drawnow
delete(findobj(mainPropFig,'tag','dynamicFiltersliderbar_PPPlot_text'));drawnow
delete(findobj(mainPropFig,'tag','dynamicFiltersliderbar_PPPlot'));drawnow

dataForPropagation_FILTERED = Propagation.dataForPropagation_FILTERED;
time_corr_PP = Propagation.time_corr_PP;


PropCurv_Axis = axes(mainPropFig,'Units','normalized','Position',[0.17 0.245 0.32 0.72],'Tag','PropCurv_Axis');
for i = 1:size(dataForPropagation_FILTERED,1)
    plot(PropCurv_Axis,time_corr_PP,dataForPropagation_FILTERED{i,3}+dataForPropagation_FILTERED{i,4}./abs(max(dataForPropagation_FILTERED{i,4})),'color',[0,0,0]+0.5) %normalizzo per evidenziare le phases
    hold(PropCurv_Axis,'on')
end

ylim([0 dataForPropagation_FILTERED{end,3}+5])
xlabel(PropCurv_Axis,'Correlation lag-time [s]','FontSize',12,'FontName','garamond');
ylabel(PropCurv_Axis,'Inter-station distance [m]','FontSize',12,'FontName','garamond');
% grid on; grid minor
PropCurv_Axis.XGrid = 'on';
PropCurv_Axis.YGrid = 'on';
PropCurv_Axis.XMinorGrid = 'on';
PropCurv_Axis.YMinorGrid = 'on';
PropCurv_Axis.XLim;
set(PropCurv_Axis,'Tag','PropCurv_Axis');

% Titolo
filterselected = get(findobj(mainPropFig,'tag','filtertype_checkbox_PP'),'value');
filtertype = get(findobj(mainPropFig,'tag','filtertype_checkbox_PP'),'string');
filtertype = filtertype(filterselected);
filterfreq = get(findobj(mainPropFig,'tag','filterfreq_PP'),'string');
title(PropCurv_Axis,[char(filtertype) ':' char(filterfreq) 'Hz'],'FontSize',10,'FontName','garamond');

% Pulsante modifica Xlimits
uicontrol(mainPropFig,'style','text','units','normalized','position',[.17 .150 .03 .03],...
    'string','Xlimits','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','xlimits_PPPlot_text');
uicontrol(mainPropFig,'style','edit','units','normalized','position',[.2 .150 .04 .03],'tag','xlimits_PPPlot',...
    'backgroundcolor',[1 1 1],'String',[num2str(PropCurv_Axis.XLim(1)) ',' num2str(PropCurv_Axis.XLim(2))],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring','Limits of xaxis. es. -2,2','Callback',@(numfld,event) updatePropagationPlot);

% Amplitude slidebar
uicontrol(mainPropFig,'style','text','units','normalized','position',[.2450 .150 .04 .03],...
    'string','Amplitude','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','crosscorrAMP_PPPlot_text');

NdynamicWinCorr = 10; %numero di steps della slidebar
stepSz = [1,NdynamicWinCorr];
uicontrol(mainPropFig,'style','slider','units','normalized','position',[.287 .150 .08 .03],...
    'Min',1,'Max',NdynamicWinCorr,'SliderStep',stepSz/(NdynamicWinCorr-1),'Value',1,...
    'Tag','dynamicWinCorrSlider_PP','callback',@(btn,event) sliderPlotAMP_PP(btn));

uicontrol(mainPropFig,'style','pushbutton','units','normalized','position',[.44 .150 .05 .03],'tag','Reset_PPPlot',...
    'backgroundcolor',[.7 .7 .7],'String','Reset','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring','Reset button plot back the NO-Filtered Propersion curve','Callback',@(numfld,event) PlotPropagation);


% salvo le linee nel plot per poter usare la sliderbar
lineeMainplot = PropCurv_Axis.Children;
lineeMainplot_PP = zeros(length(lineeMainplot(1).YData),size(lineeMainplot,1));
for i = 1:size(lineeMainplot,1)
    lineeMainplot_PP(:,i) = lineeMainplot(i).YData';
end
Propagation.lineeMainplot_PP = lineeMainplot_PP;

end

function PlotPropagation_DynamicFilter
global Propagation
global mainPropFig
% Delete existing objects
delete(findobj(mainPropFig,'tag','PropCurv_Axis'));drawnow
PropCurv_Axis = findobj(mainPropFig,'tag','PropCurv_Axis');
cla(PropCurv_Axis)
delete(findobj(mainPropFig,'tag','xlimits_PPPlot'));drawnow
delete(findobj(mainPropFig,'tag','xlimits_PPPlot_text'));drawnow
delete(findobj(mainPropFig,'tag','crosscorrAMP_PPPlot_text'));drawnow
delete(findobj(mainPropFig,'tag','dynamicWinCorrSlider_PP'));drawnow
delete(findobj(mainPropFig,'tag','Reset_PPPlot'));drawnow
delete(findobj(mainPropFig,'tag','dynamicFiltersliderbar_PPPlot_text'));drawnow
delete(findobj(mainPropFig,'tag','dynamicFiltersliderbar_PPPlot'));drawnow

dataForPropagation = Propagation.dataForPropagation; % per distance
dataForPropagation_FILTERED = Propagation.dataForPropagation_FILTERED;
time_corr_PP = Propagation.time_corr_PP;


for i = 1:size(dataForPropagation_FILTERED,2)-1
    delete(findobj(mainPropFig,'tag','PropCurv_Axis'));drawnow
    PropCurv_Axis = findobj(mainPropFig,'tag','PropCurv_Axis');
    cla(PropCurv_Axis)
    PropCurv_Axis = axes(mainPropFig,'Units','normalized','Position',[0.17 0.245 0.32 0.72],'Tag','PropCurv_Axis');
    for j = 1:size(dataForPropagation_FILTERED,1)-1
        plot(PropCurv_Axis,time_corr_PP,dataForPropagation{j,3}+dataForPropagation_FILTERED{j+1,i+1}./abs(max(dataForPropagation_FILTERED{j+1,i+1})),'color',[0,0,0]+0.5) %normalizzo per evidenziare le phases
        hold(PropCurv_Axis,'on')
    end
    % Plot characteristic
    ylim([0 dataForPropagation{end,3}+5])
    xlabel(PropCurv_Axis,'Correlation lag-time [s]','FontSize',12,'FontName','garamond');
    ylabel(PropCurv_Axis,'Inter-station distance [m]','FontSize',12,'FontName','garamond');
    % grid on; grid minor
    PropCurv_Axis.XGrid = 'on';
    PropCurv_Axis.YGrid = 'on';
    PropCurv_Axis.XMinorGrid = 'on';
    PropCurv_Axis.YMinorGrid = 'on';
    PropCurv_Axis.XLim
    set(PropCurv_Axis,'Tag','PropCurv_Axis');
    title(PropCurv_Axis,[dataForPropagation_FILTERED{1,i+1} 'Hz'],'FontSize',10,'FontName','garamond');
pause(1)
end



% Pulsante modifica Xlimits
uicontrol(mainPropFig,'style','text','units','normalized','position',[.17 .150 .03 .03],...
    'string','Xlimits','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','xlimits_PPPlot_text');
uicontrol(mainPropFig,'style','edit','units','normalized','position',[.2 .150 .04 .03],'tag','xlimits_PPPlot',...
    'backgroundcolor',[1 1 1],'String',[num2str(PropCurv_Axis.XLim(1)) ',' num2str(PropCurv_Axis.XLim(2))],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring','Limits of xaxis. es. -2,2','Callback',@(numfld,event) updatePropagationPlot);

% Amplitude slidebar
uicontrol(mainPropFig,'style','text','units','normalized','position',[.2450 .150 .04 .03],...
    'string','Amplitude','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','crosscorrAMP_PPPlot_text');

NdynamicWinCorr = 10; %numero di steps della slidebar
stepSz = [1,NdynamicWinCorr];
uicontrol(mainPropFig,'style','slider','units','normalized','position',[.287 .150 .08 .03],...
    'Min',1,'Max',NdynamicWinCorr,'SliderStep',stepSz/(NdynamicWinCorr-1),'Value',1,...
    'Tag','dynamicWinCorrSlider_PP','callback',@(btn,event) sliderPlotAMP_PP(btn));

uicontrol(mainPropFig,'style','pushbutton','units','normalized','position',[.44 .150 .05 .03],'tag','Reset_PPPlot',...
    'backgroundcolor',[.7 .7 .7],'String','Reset','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring','Reset button plot back the NO-Filtered Propersion curve','Callback',@(numfld,event) PlotPropagation);

% Dynamic filter slider
uicontrol(mainPropFig,'style','text','units','normalized','position',[.17 .1068 .1150 .03],...
    'string','Change filter bandwidth','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','dynamicFiltersliderbar_PPPlot_text');

dataForPropagation_FILTERED = Propagation.dataForPropagation_FILTERED;
NdynamicWinCorr = size(dataForPropagation_FILTERED,2)-1; %numero di steps della slidebar
stepSz = [1,NdynamicWinCorr];
uicontrol(mainPropFig,'style','slider','units','normalized','position',[.287 .1068 .08 .03],...
    'Min',1,'Max',NdynamicWinCorr,'SliderStep',stepSz/(NdynamicWinCorr-1),'Value',1,...
    'Tag','dynamicFiltersliderbar_PPPlot','callback',@(btn,event) Filtersliderbar_PPPlot(btn));

% salvo le linee nel plot per poter usare la sliderbar
lineeMainplot = PropCurv_Axis.Children;
lineeMainplot_PP = zeros(length(lineeMainplot(1).YData),size(lineeMainplot,1));
for i = 1:size(lineeMainplot,1)
    lineeMainplot_PP(:,i) = lineeMainplot(i).YData';
end
Propagation.lineeMainplot_PP = lineeMainplot_PP;

end

function sliderPlotAMP_PP(~)
global mainPropFig
global Propagation

% Slidebar
SliderselectedWinCorr = get(findobj(mainPropFig,'tag','dynamicWinCorrSlider_PP'),'value');

% Axes and plot
PropCurv_Axis = findobj(mainPropFig,'tag','PropCurv_Axis');
time_corr_PP = Propagation.time_corr_PP;
linee = PropCurv_Axis.Children;
delete(linee);

% Linee originali (non amplificate)
lineeMainplot_PP = Propagation.lineeMainplot_PP;

increment = 1:0.5:10;
increment = increment(round(SliderselectedWinCorr));
dataForPropagation = Propagation.dataForPropagation;

for i = 1:size(lineeMainplot_PP,2)
    j = size(lineeMainplot_PP,2)-i+1; %Le linee sono plottate in ordine inverso quindi ho bisogno di j che vada in senso opposto
    dist = dataForPropagation{j,3};
    plot(PropCurv_Axis,time_corr_PP,((lineeMainplot_PP(:,i)-dist).*increment)+dist,'color',[0,0,0]+0.5);

end
end

function Filtersliderbar_PPPlot(~)
global mainPropFig
global Propagation


% Slidebar
SliderselectedWinCorr = get(findobj(mainPropFig,'tag','dynamicFiltersliderbar_PPPlot'),'value');

% Dati
dataForPropagation = Propagation.dataForPropagation; % per distance
dataForPropagation_FILTERED = Propagation.dataForPropagation_FILTERED;
time_corr_PP = Propagation.time_corr_PP;

% Axes and plot
PropCurv_Axis = findobj(mainPropFig,'tag','PropCurv_Axis');
linee = PropCurv_Axis.Children;
delete(linee);

% Plot
    PropCurv_Axis = findobj(mainPropFig,'tag','PropCurv_Axis');
    for j = 1:size(dataForPropagation_FILTERED,1)-1
        plot(PropCurv_Axis,time_corr_PP,dataForPropagation{j,3}+dataForPropagation_FILTERED{j+1,SliderselectedWinCorr+1}./abs(max(dataForPropagation_FILTERED{j+1,SliderselectedWinCorr+1})),'color',[0,0,0]+0.5) %normalizzo per evidenziare le phases
        hold(PropCurv_Axis,'on')
    end
    % Plot characteristic
    ylim([0 dataForPropagation{end,3}+5])
    xlabel(PropCurv_Axis,'Correlation lag-time [s]','FontSize',12,'FontName','garamond');
    ylabel(PropCurv_Axis,'Inter-station distance [m]','FontSize',12,'FontName','garamond');
    % grid on; grid minor
    PropCurv_Axis.XGrid = 'on';
    PropCurv_Axis.YGrid = 'on';
    PropCurv_Axis.XMinorGrid = 'on';
    PropCurv_Axis.YMinorGrid = 'on';
    PropCurv_Axis.XLim
    set(PropCurv_Axis,'Tag','PropCurv_Axis');
    title(PropCurv_Axis,[dataForPropagation_FILTERED{1,SliderselectedWinCorr+1} 'Hz'],'FontSize',10,'FontName','garamond');
end
