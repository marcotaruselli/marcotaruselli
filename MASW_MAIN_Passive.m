function MASW_MAIN_Passive(data_processing)
% global utilities
global mainFig_MASWPassive
global data_selected
global MASW_Passive
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
MASW_Passive.data_selected = data_selected;

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
mainFig_MASWPassive = figure('units','normalized','outerposition',[0 0 1 1],'WindowState','maximized','toolbar','none','MenuBar','none',...
    'numbertitle','off','name','PropERSION CURVE ANALYSIS');

% Disegno riquadri
annotation(mainFig_MASWPassive,'line',[0.13 0.995],[0.99 0.99],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga sopra orizzontale
annotation(mainFig_MASWPassive,'line',[0.13 0.13],[0.007 0.99],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga sx verticale
annotation(mainFig_MASWPassive,'line',[0.995 0.995],[0.007 0.99],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga dx verticale
annotation(mainFig_MASWPassive,'line',[0.13 0.995],[0.007 0.007],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga sotto orizzontale
annotation(mainFig_MASWPassive,'line',[0.527 0.527],[0.007 0.99],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga dx verticale
annotation(mainFig_MASWPassive,'line',[0.527 0.995],[0.485 0.485],'Color',[0.6,0.6,0.6],'LineWidth',0.001,'Units','normalized'); % Riga dx verticale


% Propersion curve: Stations ------------------------------------------------
uicontrol(mainFig_MASWPassive,'style','text','units','normalized','position',[.006 .96 .118 .0285],...
    'string','Stations coordinates','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',[230/255 237/255 130/255]);
annotation(mainFig_MASWPassive,'rectangle','Units','normalized','Position',[.005 .96 .119 .03],'FaceColor','none','Color',[0.6 0.6 0.6])

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
uicontrol(mainFig_MASWPassive,'style','pushbutton','units','normalized','position',[.005 .7515-0.0335 .06 .03],...
    'string','Load coord.','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'Tag','LoadCoord','Callback',@(numfld,event) LoadCoordinates);

% Button save
uicontrol(mainFig_MASWPassive,'style','pushbutton','units','normalized','position',[.065 .7515-0.0335 .06 .03],...
    'string','Save coord.','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'Tag','SaveCoord','Enable','off','Callback',@(numfld,event) SaveCoordinates);

% Button Compute distance of stations pair
uicontrol(mainFig_MASWPassive,'style','pushbutton','units','normalized','position',[.005 .718-0.0335 .12 .03],...
    'string','Compute distance of stations-pair','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'Tag','statPairDist','Enable','off','Callback',@(numfld,event) TableStationsPairDistance);

%% Tabella distanze
columnname = {'','Stations pair','Distance'};
columnformat = {'logical','bank','bank'};
% Create the uitable
distTable = uitable(mainFig_MASWPassive,'Units','normalized','Position',[0.005 .5330-0.0335+0.06 .12 .12],...
    'ColumnWidth', {30 80 75},...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'ColumnEditable', [true false false],...
    'RowName',[],'Enable','on',...
    'Tag','distTable');%,...
MASW_Passive.distTable = distTable;


% Table Distances position ==> [0.005 .4754 .12 .2376]

%% Cross-correlation parameters --------------------------------------------------------
uicontrol(mainFig_MASWPassive,'style','text','units','normalized','position',[.006 0.4378-0.0335+0.0576+0.06 .118 .0285],...
    'string','Cross-Correlation setting','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',[230/255 237/255 130/255]);
annotation(mainFig_MASWPassive,'rectangle','Units','normalized','Position',[.005 0.4380-0.0335+0.0576+0.06 .119 .03],'FaceColor','none','Color',[0.6 0.6 0.6])

% Time-length signals
uicontrol(mainFig_MASWPassive,'style','text','units','normalized','position',[.005 .3688+0.0576+0.06 .07 .03],...
    'string','Time length [m]','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off','tag','String_timelength_MASWPassive');
uicontrol(mainFig_MASWPassive,'style','edit','units','normalized','position',[.075 .3688+0.0576+0.06 .05 .03],...
    'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tag','timelength_MASWPassive','Enable','off',...
    'tooltipstring',['Select the signals time-length to compute the cross-correlation. Time in minutes' 10 ...
    'If the chosen length does not return null reminder, a first part of the signal will be discarded.']);

% Maxlag
uicontrol('style','text','units','normalized','position',[.005 .3368+0.0576+0.06 .07 .03],...
    'string','Maxlag [s]','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','off','tag','String_maxlag_MASWPassive');
uicontrol('style','edit','units','normalized','position',[.075 .3368+0.0576+0.06 .05 .03],...
    'backgroundcolor',[1 1 1],'String',10,'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tag','maxlag_MASWPassive','Enable','off',...
    'tooltipstring','Express maxlag in second. The code will convert it in samples.');

% Whitening
uicontrol('style','text','units','normalized','position',[.005 .3048+0.0576+0.06 .07 .03],...
    'string','Weighting','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','String_whitening_MASWPassive');
uicontrol('style','popupmenu','units','normalized','position',[.075 .3048+0.0576+0.06 .05 .03],...
    'String',{'Time', 'Frequency', 'Both','None'},'value',2,...
    'horizontalalignment','left','fontunits','normalized','fontsize',.5,'Tag','Weighting_MASWPassive',...
    'tooltipstring',['You can decide to compute the time-domain Weighting or' 10 ...
    'the Frequency-domain Weighting (whitening) or both together' 10 ...
    'When Time-domain Weighting or Both is selected, the signals are firstly high-pass filtered at 0.05Hz to improve the quality of this procedure'],...
    'Callback',@(hObject, eventdata) CrossCorr_WeightingActivation(hObject, eventdata));

% Avarage cross-corr belonging to station pairs with same distance
uicontrol('style','text','units','normalized','position',[.005 .2728+0.0576+0.06 .07 .03],...
    'string','Stack Cross-corr','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Enable','on','Tag','String_StackCrossCorr_MASWPassive');
uicontrol('style','popupmenu','units','normalized','position',[.075 .2728+0.0576+0.06 .05 .03],'String','yes',...
    'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'Tag','stackCrossCorr_MASWPassive','Enable','on',...
    'Value',1,'tooltipstring','The cross-correlation referred to station pairs with same inter-distance will be stacked together');


%% Filtering
% Check if filter data or not
uicontrol('style','text','units','normalized','position',[.005 .2408+0.0576+0.06 .07 .03],...
    'string','Cross-corr. Filter','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','filtercheck_MASWPassive');
filtercheck = uicontrol('style','checkbox','units','normalized','position',[.075 .2408+0.0576+0.06 .05 .03],...
    'string','Yes','Value',0,'horizontalalignment','left','fontunits','normalized','fontsize',.5,'Tag','filtercheck_MASWPassive',...
    'TooltipString','Do you want to filter the cross-correlations?',...
    'Callback',@(hObject, eventdata) MASWPassive_filteractivation(hObject, eventdata));

% Filter type
uicontrol(mainFig_MASWPassive,'style','text','units','normalized','position',[.005 .2088+0.0576+0.06 .07 .03],'Enable','off',...
    'string','Filter type','horizontalalignment','left','fontunits','normalized','fontsize',.5,'Tag','filtertype_text_MASWPassive',...
    'backgroundcolor',[.8 .8 .8]);
uicontrol(mainFig_MASWPassive,'style','popupmenu','units','normalized','position',[.075 .2088+0.0576+0.06 .05 .03],'Enable','off','tag','filter_type',...
    'string',{'Lowpass','Highpass','Bandpass','Dynamic'},'horizontalalignment','right','fontunits','normalized','fontsize',.5,'Tag','filtertype_checkbox_MASWPassive');
% Filter frequency
uicontrol(mainFig_MASWPassive,'style','text','units','normalized','position',[.005 .1768+0.0576+0.06 .07 .03],'Enable','off',...
    'string','Filter freq [Hz]','horizontalalignment','left','fontunits','normalized','fontsize',.5,'Tag','filterfreq_text_MASWPassive',...
    'backgroundcolor',[.8 .8 .8]);
uicontrol(mainFig_MASWPassive,'style','edit','units','normalized','position',[.075 .1768+0.0576+0.06 .05 .03],'Enable','off','tag','filter_frequency_MASWPassive',...
    'string','1','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Tag','filterfreq_MASWPassive',...
    'tooltipstring',['Indicate Fcut for Highpass/Lowpass i.e. 4' newline ...
    'Fcut1,Fcut2 for Bandpass i.e. 1,20' newline 'Fmin,Fmax,Fstep for dynamic i.e. 1,100,2' newline...
    'In "dynamic" case the Propagation will be filtered at frequency-step es.1-3Hz, 3-5Hz,...']);

% Button Compute cross-correlations of stations pairs
uicontrol(mainFig_MASWPassive,'style','pushbutton','units','normalized','position',[.005 .1448+0.0576+0.06 .12 .03],...
    'string','Compute cross-correlations','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'Tag','computeCrossCorrelations_MASWPassive','Enable','off','Callback',@(numfld,event) ComputeCrossCorr);

%% Analysis settings

uicontrol(mainFig_MASWPassive,'style','text','units','normalized','position',[.005 .224 .12 .03],...
    'string',' Analysis settings','horizontalalignment','left','fontunits','normalized','fontsize',.6,'fontweight','bold',...
    'backgroundcolor',[230/255 237/255 130/255],'enable','off','Tag','AnalysisSettingsTitle');
annotation(mainFig_MASWPassive,'rectangle','Units','normalized','Position',[0.0040    0.2242    0.1210    0.0315],...
    'FaceColor','none','Color',[0.6 0.6 0.6],'Tag','AnalysisSettingsTitleContour')

% Frequency band
uicontrol(mainFig_MASWPassive,'style','text','units','normalized','position',[0.005    0.190    0.07    0.0300],...
    'string','Bandwidth [Hz]','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'enable','off','tag','MASW_bandwidthText');
uicontrol(mainFig_MASWPassive,'style','edit','units','normalized','position',[0.075    0.190    0.05    0.0300],...
    'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tag','MASW_bandwidth_edit','String','auto','enable','off',...
    'tooltipstring',['Select the frequency limits for the analysis [Hz]. If "auto" is selected the frequency limits' 10 ...
    'range between 0 and fNy. es. 1,100']);

% Velocity vector
uicontrol(mainFig_MASWPassive,'style','text','units','normalized','position',[0.0050    0.1580    0.0700    0.0300],...
    'string','Velocity  [m/s]','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'enable','off','tag','MASW_velocityText');
uicontrol(mainFig_MASWPassive,'style','edit','units','normalized','position',[0.0750    0.1580    0.0500    0.0300],...
    'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tag','MASW_velocity_edit','String','10:10:1000','enable','off',...
    'tooltipstring',['Create the velocity vector as Vmin:Vstep:Vmax. es.10:10:1000']);
%
% % Offset vector
% uicontrol(mainFig_MASWPassive,'style','text','units','normalized','position',[0.0050    0.1260    0.0700    0.0300],...
%     'string','Offset vector','horizontalalignment','left','fontunits','normalized','fontsize',.5,'Tag','MASW_offsetText',...
%     'backgroundcolor',[.8 .8 .8],'enable','off');
% uicontrol(mainFig_MASWPassive,'style','popupmenu','units','normalized','position',[0.0750    0.1260    0.0500    0.0300],...
%     'string',{'REAL offset','EQUAL offset'},'Value',2,'horizontalalignment','right','fontunits','normalized','fontsize',.5,'enable','off',...
%     'Tag','MASW_offset_choice','Tooltip',['If "REAL offset" is selected the traces offset vector is defined based on the real distance among the stations' 10 ...
%     'If "EQUAL offset" is selected the traces offset vector is defined as 0:dx:(nCh-1)*dx where dx is the "offset" showed in the INFO tab above' 10 ...
%     'I put this option in case the user want to use the geographical coordinates and therefore to check what would change if the interdistance among stations is not constant']);

% Method
uicontrol(mainFig_MASWPassive,'style','text','units','normalized','position',[0.0050    0.1260    0.0700    0.0300],'enable','off',...
    'string','Method','horizontalalignment','left','fontunits','normalized','fontsize',.5,'Tag','MASW_methodText',...
    'backgroundcolor',[.8 .8 .8]);
uicontrol(mainFig_MASWPassive,'style','popupmenu','units','normalized','position',[0.0750    0.1260    0.0500    0.0300],'enable','off',...
    'string',{'TauP','FK','PhaseShift'},'Value',1,'horizontalalignment','right','fontunits','normalized','fontsize',.5,...
    'Callback',@(numfld,event) activationRequiredParameters,'Tag','MASW_method_choice');

% Step in frequenza
uicontrol(mainFig_MASWPassive,'style','text','units','normalized','position',[0.0050    0.0940    0.0700    0.0300],'enable','off',...
    'string','Freq. Step','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'tag','MASW_freqStepText','Enable','off');
uicontrol(mainFig_MASWPassive,'style','edit','units','normalized','position',[0.0750    0.0940    0.0500    0.0300],'enable','off',...
    'backgroundcolor',[1 1 1],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tag','MASW_freqStep_edit','String','1','Enable','off',...
    'tooltipstring',['Specify the frequency step. es. 1 Hz']);

% Button Compute the vector containing the position of traces
uicontrol(mainFig_MASWPassive,'style','pushbutton','units','normalized','position',[ 0.0050    0.0620    0.12    0.0300],'enable','off',...
    'string','Compute Analysis','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'Tag','ComputeAnalysisBUTTON','Callback',@(numfld,event) ComputeSurfWavesAnalysis);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Attiva tasti filtro
function MASWPassive_filteractivation(hObject,eventdata)
global mainFig_MASWPassive
filtercheck = findobj('Tag','filtercheck_MASWPassive');
filtertype_text = findobj('Tag','filtertype_text_MASWPassive');
filtertype_checkbox = findobj('Tag','filtertype_checkbox_MASWPassive');
filterfreq_text = findobj('Tag','filterfreq_text_MASWPassive');
filterfreq = findobj('Tag','filterfreq_MASWPassive');

% Se opzione filtro è selezionata, attiva la parte di inserimento dati filtro
choice = filtercheck.Value;
if  choice == 1
    set(filtertype_text,'Enable','on')
    set(filtertype_checkbox,'Enable','on')
    set(filterfreq_text,'Enable','on')
    set(filterfreq,'Enable','on')
end

% Se opzione filtro NON è selezionata, disattiva la parte di inserimento dati filtro
if choice == 0
    set(filtertype_text,'Enable','off')
    set(filtertype_checkbox,'Enable','off')
    set(filterfreq_text,'Enable','off')
    set(filterfreq,'Enable','off')
end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Creazione tabelle
function TableSelectedStations(data_processing)
global mainFig_MASWPassive
global MASW_Passive

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
coordTable = uitable(mainFig_MASWPassive,'Units','normalized','Position',[.005 .785-0.0335 .12 .1706],...
    'Data',stationsList,...
    'ColumnWidth', {50 67 67},...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'ColumnEditable', [false true true],... %serve per attivare la modifica delle coordinate
    'RowName',[],...
    'CellSelectionCallback', @(numfld,event) activateButton,...
    'Tag','coordTable');
MASW_Passive.coordTable = coordTable;
end

function TableStationsPairDistance
%% Calcolo distanze
global mainFig_MASWPassive
global MASW_Passive
% Get coordinate system
coordSysOptions = get(findobj(mainFig_MASWPassive,'tag','coordSystem'),'value');
coordSys_selected = get(findobj(mainFig_MASWPassive,'tag','coordSystem'),'string');
coordSys_selected = coordSys_selected{coordSysOptions};

% Trovo coppie di stazioni possibili
coordTable = MASW_Passive.coordTable;
stationsPairs = nchoosek(coordTable.Data(:,1)',2);
MASW_Passive.stationsPairs = stationsPairs;

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
distTable = findobj(mainFig_MASWPassive,'tag','distTable');
set(distTable,'enable','on'); %attivo tabella
set(distTable,'Data', stationsPairData); %import data
set(distTable,'ColumnWidth', {30 80 55}); %resize table

%% Attivo pulsanti per eseguire cross-correlazioni
set(findobj(mainFig_MASWPassive,'tag','String_timelength_MASWPassive'),'enable','on');
set(findobj(mainFig_MASWPassive,'tag','timelength_MASWPassive'),'enable','on');
set(findobj(mainFig_MASWPassive,'tag','String_maxlag_MASWPassive'),'enable','on');
set(findobj(mainFig_MASWPassive,'tag','maxlag_MASWPassive'),'enable','on');
set(findobj(mainFig_MASWPassive,'tag','String_whitening_MASWPassive'),'enable','on');
set(findobj(mainFig_MASWPassive,'tag','whitening_MASWPassive'),'enable','on');
% set(findobj(mainFig_MASWPassive,'tag','String_avarageCrossCorr_MASWPassive'),'enable','on');
% set(findobj(mainFig_MASWPassive,'tag','avarageCrossCorr_MASWPassive'),'enable','on');
set(findobj(mainFig_MASWPassive,'tag','computeCrossCorrelations_MASWPassive'),'enable','on');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Attivazione Buttons
function activateButton
global MASW_Passive
global mainFig_MASWPassive

coordTable = MASW_Passive.coordTable;
if ~any(cellfun(@isempty, coordTable.Data(:,2))) && ...
        ~any(cellfun(@isempty, coordTable.Data(:,3)))
    set(findobj(mainFig_MASWPassive,'tag','SaveCoord'),'enable','on');
    set(findobj(mainFig_MASWPassive,'tag','statPairDist'),'enable','on');
else
    set(findobj(mainFig_MASWPassive,'tag','SaveCoord'),'enable','off');
    set(findobj(mainFig_MASWPassive,'tag','statPairDist'),'enable','off');
end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Save & Load coordinates
function SaveCoordinates
global MASW_Passive
% Carico tabella da salvare
coordTable = MASW_Passive.coordTable;

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
global mainFig_MASWPassive
global MASW_Passive
[fileName,folder] = uigetfile({'*.coord*'},'Select file to be loaded','MultiSelect', 'off');
cd(folder)
load(fileName, '-mat' );

% Cancello tabella già esistente
delete(findobj(mainFig_MASWPassive,'tag','coordTable'));

% Carico la tabella con già le coordinate
columnname = {'Station','X (LAT)','Y (LONG)'};
coordTable = uitable(mainFig_MASWPassive,'Units','normalized','Position',[.005 .785-0.0335 .12 .1706],...
    'Data',coordTable.Data,...
    'ColumnWidth', {50 67 67},...
    'ColumnName', columnname,...
    'ColumnFormat', coordTable.ColumnFormat,...
    'ColumnEditable', [false true true],... %serve per attivare la modifica delle coordinate
    'RowName',[],...
    'CellSelectionCallback', @(numfld,event) activateButton,...
    'Tag','coordTable');
MASW_Passive.coordTable = coordTable;

% Attiva buttons
activateButton
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% COMPUTE CROSS-CORR
function ComputeCrossCorr
%% Get input from mainFig_MASWPassive
global mainFig_MASWPassive
global MASW_Passive

% Cancella i risultati dell'analisi MASW se già stata fatta
delete(findobj(mainFig_MASWPassive,'tag','result1MASW_Axis'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','result2MASW_Axis'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','cbar1LIM'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','cbar1LIM_value'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','cbar2LIM'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','cbar2LIM_value'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','cbar3LIM'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','cbar3LIM_value'));drawnow


selected = evalin('base','selected');
data_processing = evalin('base','data_processing');

% Cross-Corr input
timelength = str2num(get(findobj(mainFig_MASWPassive,'tag','timelength_MASWPassive'),'string'));
whitening = get(findobj(mainFig_MASWPassive,'tag','whitening_MASWPassive'),'value');
maxlag = str2num(get(findobj(mainFig_MASWPassive,'tag','maxlag_MASWPassive'),'string'));
if isempty(timelength)
    beep
    waitfor(msgbox('You must specify the time length!','Update','error'));
    return
end
% Dati Propersion curve che vado ad integrare con le cross-correlation
distTable = findobj(mainFig_MASWPassive,'tag','distTable');
dataForMASWPassive = distTable.Data;
% Seleziono solo le coppie che sono state checkate nella tabella%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NUOVO!!!
rowChecked = [distTable.Data{:,1}]';
dataForMASWPassive = dataForMASWPassive(rowChecked,:);

% % Coppie di stazioni %%%%%%%%%%%%%%%%%%%%%%%%% VECCHIO
%stationsPairs = MASW_Passive.stationsPairs;

% Coppie di stazioni %%%%%%%%%%%%%%%%%%%%%%%%% NUOVO ==> fatto per poter
% considerare solo alcune coppie di sensori
a = char(dataForMASWPassive(:,2));
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
MASW_Passive.Fs = Fs;
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
            time_corr_MASWPassive=[-maxlag:maxlag]/Fs; % intervallo di correlazione
            correlations=zeros(length(time_corr_MASWPassive),length(subsignals)*param_time); % inizializzazione dell'elenco delle correlazioni della coppia
            %             REFCorrelations_MASWPassive = zeros(size(correlations,1),size(stationsPairs,1));
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
    REFCorrelations_MASWPassive(:,j) = nanmean(correlations,2);
    dataForMASWPassive{j,4} = nanmean(correlations,2);
    
    %% Avanzamento barra di caricamento
    waitbar((1/size(ChoosenstationsPairs,1))*j,barracaricamento,'Computing cross-correlations');
end

%% QUI INSERISCO LO STACKING
% Trovo coppie con stessa distanza
tabellaDati = cell2table(dataForMASWPassive);
distanzeAll = table2array(tabellaDati(:,3));
distanzeUniche = unique(distanzeAll);

for i = 1:length(distanzeUniche)
    pos = find(distanzeUniche(i) == distanzeAll);
    selectedData = table2array(tabellaDati(pos(1):pos(end),4));
    selectedData = sum(cell2mat(selectedData'),2); % ==> STACKING
    STACKEDCorrelations_MASWPassive(:,i) = selectedData;
end
%%%%

%%% PLOT: Rendo globali queste variabili per poter filtrare il grafico
MASW_Passive.time_corr_MASWPassive = time_corr_MASWPassive;
MASW_Passive.distanzeUniche = distanzeUniche;
MASW_Passive.REFCorrelations_MASWPassive = REFCorrelations_MASWPassive;
MASW_Passive.STACKEDCorrelations_MASWPassive = STACKEDCorrelations_MASWPassive;
MASW_Passive.dataForMASWPassive = dataForMASWPassive;
close(barracaricamento)



%% Filtering and Plot cross-corr
choice = get(findobj(mainFig_MASWPassive,'tag','filtercheck_MASWPassive'),'value');
choice = choice{1};
% Se opzione filtro è selezionata, attiva la parte di inserimento dati filtro
if  choice == 1
    ComputeFiltering_MASWPassive
    PlotCrossCorrelations_FILTERED %It works only for low-high-band pass filtering
else
    PlotCrossCorrelations
end

%% Attivo pulsanti per eseguire le MASW
set(findobj(mainFig_MASWPassive,'tag','AnalysisSettingsTitle'),'enable','on');
set(findobj(mainFig_MASWPassive,'tag','MASW_bandwidthText'),'enable','on');
set(findobj(mainFig_MASWPassive,'tag','MASW_bandwidth_edit'),'enable','on');
set(findobj(mainFig_MASWPassive,'tag','MASW_velocityText'),'enable','on');
set(findobj(mainFig_MASWPassive,'tag','MASW_velocity_edit'),'enable','on');
% set(findobj(mainFig_MASWPassive,'tag','MASW_offsetText'),'enable','on');
% set(findobj(mainFig_MASWPassive,'tag','MASW_offset_choice'),'enable','on');
set(findobj(mainFig_MASWPassive,'tag','MASW_methodText'),'enable','on');
set(findobj(mainFig_MASWPassive,'tag','MASW_method_choice'),'enable','on');
% set(findobj(mainFig_MASWPassive,'tag','MASW_freqStepText'),'enable','on');
% set(findobj(mainFig_MASWPassive,'tag','MASW_freqStep_edit'),'enable','on');
set(findobj(mainFig_MASWPassive,'tag','ComputeAnalysisBUTTON'),'enable','on');

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Plot cross-corr
function PlotCrossCorrelations
global MASW_Passive
global mainFig_MASWPassive
% Delete existing objects
delete(findobj(mainFig_MASWPassive,'tag','MASWPassive_Axis'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','xlimits_MASWPassivePlot'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','xlimits_MASWPassivePlot_text'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','crosscorrAMP_MASWPassivePlot_text'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','dynamicWinCorrSlider_MASWPassive'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','Reset_MASWPassivePlot'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','dynamicFiltersliderbar_MASWPassivePlot_text'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','dynamicFiltersliderbar_MASWPassivePlot'));drawnow

distanzeUniche = MASW_Passive.distanzeUniche;
STACKEDCorrelations_MASWPassive = MASW_Passive.STACKEDCorrelations_MASWPassive;
dataForMASWPassive = MASW_Passive.dataForMASWPassive;
time_corr_MASWPassive = MASW_Passive.time_corr_MASWPassive;

MASWPassive_Axis = axes(mainFig_MASWPassive,'Units','normalized','Position',[0.17 0.245 0.32 0.72],'Tag','MASWPassive_Axis');
for i = 1:length(distanzeUniche)
    hold on
    plot(MASWPassive_Axis,time_corr_MASWPassive,repmat(distanzeUniche(i),size(STACKEDCorrelations_MASWPassive,1),1)+STACKEDCorrelations_MASWPassive(:,i)./abs(max(STACKEDCorrelations_MASWPassive(:,i))),'color',[0,0,0]+0.5) %normalizzo per evidenziare le phases
end

ylim([0 dataForMASWPassive{end,3}+unique(diff(distanzeUniche))]);
xlabel(MASWPassive_Axis,'Correlation lag-time [s]','FontSize',12,'FontName','garamond');
ylabel(MASWPassive_Axis,'Inter-station distance [m]','FontSize',12,'FontName','garamond');

% grid on; grid minor
MASWPassive_Axis.XGrid = 'on';
MASWPassive_Axis.YGrid = 'on';
MASWPassive_Axis.XMinorGrid = 'on';
MASWPassive_Axis.YMinorGrid = 'on';
MASWPassive_Axis.Toolbar.Visible = 'on';
title(MASWPassive_Axis,'Stacked and normalized Cross-correlations','FontSize',10,'FontName','garamond');

% Pulsante modifica Xlimits
uicontrol(mainFig_MASWPassive,'style','text','units','normalized','position',[.17 .150 .03 .03],...
    'string','Xlimits','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','xlimits_MASWPassivePlot_text');
uicontrol(mainFig_MASWPassive,'style','edit','units','normalized','position',[.2 .150 .04 .03],'tag','xlimits_MASWPassivePlot',...
    'backgroundcolor',[1 1 1],'String',[num2str(MASWPassive_Axis.XLim(1)) ',' num2str(MASWPassive_Axis.XLim(2))],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring','Limits of xaxis. es. -2,2','Callback',@(numfld,event) updateCrossCorrPlot);

% Amplitude slidebar
uicontrol(mainFig_MASWPassive,'style','text','units','normalized','position',[.2450 .150 .04 .03],...
    'string','Amplitude','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','crosscorrAMP_MASWPassivePlot_text');

NdynamicWinCorr = 20; %numero di steps della slidebar
stepSz = [1,NdynamicWinCorr];
uicontrol(mainFig_MASWPassive,'style','slider','units','normalized','position',[.287 .150 .08 .03],...
    'Min',1,'Max',NdynamicWinCorr,'SliderStep',stepSz/(NdynamicWinCorr-1),'Value',1,...
    'Tag','dynamicWinCorrSlider_MASWPassive','callback',@(btn,event) sliderPlotAMP_MASWPassive(btn));

uicontrol(mainFig_MASWPassive,'style','pushbutton','units','normalized','position',[.44 .150 .05 .03],'tag','Reset_MASWPassivePlot',...
    'backgroundcolor',[.7 .7 .7],'String','Reset','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring','Reset button plot back the NO-Filtered Propersion curve','Callback',@(numfld,event) ResetPlot);

%%% se dynamic è stato scelto aggiungi la sliderbar per muoversi tra diverse frequenze
% filterselected = get(findobj(mainFig_MASWPassive,'tag','filtertype_checkbox_MASWPassive'),'value');
% filtertype = get(findobj(mainFig_MASWPassive,'tag','filtertype_checkbox_MASWPassive'),'string');
% filtertype = filtertype(filterselected);
% if strcmp(filtertype,'Dynamic')
%     % Dynamic filter slider
% uicontrol(mainFig_MASWPassive,'style','text','units','normalized','position',[.17 .1068 .1150 .03],...
%     'string','Change filter bandwidth','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
%     'backgroundcolor',[.8 .8 .8],'Tag','dynamicFiltersliderbar_MASWPassivePlot_text');
% dataForMASWPassive_FILTERED = MASW_Passive.dataForMASWPassive_FILTERED;
% NdynamicWinCorr = size(dataForMASWPassive_FILTERED,2)-1; %numero di steps della slidebar
% stepSz = [1,NdynamicWinCorr];
% uicontrol(mainFig_MASWPassive,'style','slider','units','normalized','position',[.287 .1068 .08 .03],...
%     'Min',1,'Max',NdynamicWinCorr,'SliderStep',stepSz/(NdynamicWinCorr-1),'Value',1,...
%     'Tag','dynamicFiltersliderbar_MASWPassivePlot','callback',@(btn,event) Filtersliderbar_MASWPassivePlot(btn));
% end
%%%

% salvo le linee nel plot per poter usare la sliderbar
lineeMainplot = MASWPassive_Axis.Children;
lineeMainplot_MASWPassive = zeros(length(lineeMainplot(1).YData),size(lineeMainplot,1));
for i = 1:size(lineeMainplot,1)
    lineeMainplot_MASWPassive(:,i) = lineeMainplot(i).YData';
end
MASW_Passive.lineeMainplot_MASWPassive = lineeMainplot_MASWPassive;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updateCrossCorrPlot
global mainFig_MASWPassive
% Xlimits
xlimits = str2num(get(findobj(mainFig_MASWPassive,'tag','xlimits_MASWPassivePlot'),'String'));
MASWPassive_Axis = findobj(mainFig_MASWPassive,'tag','MASWPassive_Axis');
MASWPassive_Axis.XLim = xlimits;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FIltering
function ComputeFiltering_MASWPassive
global mainFig_MASWPassive
global MASW_Passive

filterselected = get(findobj(mainFig_MASWPassive,'tag','filtertype_checkbox_MASWPassive'),'value');
filtertype = get(findobj(mainFig_MASWPassive,'tag','filtertype_checkbox_MASWPassive'),'string');
filtertype = filtertype(filterselected);
filterfreq = get(findobj(mainFig_MASWPassive,'tag','filterfreq_MASWPassive'),'string');
% Carico dati
dataForMASWPassive = MASW_Passive.dataForMASWPassive; % Serve solo per la barra di caricamento
time_corr_MASWPassive = MASW_Passive.time_corr_MASWPassive;
Fs = MASW_Passive.Fs;
STACKEDCorrelations_MASWPassive = MASW_Passive.STACKEDCorrelations_MASWPassive;
dataForMASWPassive_FILTERED = STACKEDCorrelations_MASWPassive;

%Loading bar
barracaricamento = waitbar(0,'Filtering computation','Units','normalized','Position',[0.73,0.06,0.25,0.08]);

% Filtering
% Design lowpass filt
if strcmp(filtertype,'Lowpass')
    for j = 1:size(STACKEDCorrelations_MASWPassive,2)
        dataForMASWPassive_FILTERED(:,j) = lowpass(STACKEDCorrelations_MASWPassive(:,j),str2num(filterfreq), Fs,'ImpulseResponse','iir','Steepness',0.95);
        waitbar((1/size(dataForMASWPassive,1))*j,barracaricamento,'Filtering computation');
    end
    MASW_Passive.dataForMASWPassive_FILTERED = dataForMASWPassive_FILTERED;
end

% Design highpass filter
if strcmp(filtertype,'Highpass')
    for j = 1:size(STACKEDCorrelations_MASWPassive,2)
        dataForMASWPassive_FILTERED(:,j) = highpass(STACKEDCorrelations_MASWPassive(:,j),str2num(filterfreq), Fs,'ImpulseResponse','iir','Steepness',0.95);
        waitbar((1/size(dataForMASWPassive,1))*j,barracaricamento,'Filtering computation');
    end
    MASW_Passive.dataForMASWPassive_FILTERED = dataForMASWPassive_FILTERED;
end

% Design bandpass filter
if strcmp(filtertype,'Bandpass')
    for j = 1:size(STACKEDCorrelations_MASWPassive,2)
        dataForMASWPassive_FILTERED(:,j)   = bandpass(STACKEDCorrelations_MASWPassive(:,j),str2num(filterfreq), Fs,'ImpulseResponse','iir','Steepness',0.95);
        waitbar((1/size(dataForMASWPassive,1))*j,barracaricamento,'Filtering computation');
    end
    MASW_Passive.dataForMASWPassive_FILTERED = dataForMASWPassive_FILTERED;
    
end
close(barracaricamento)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Plot cross-corr filtrate
function PlotCrossCorrelations_FILTERED
global MASW_Passive
global mainFig_MASWPassive
% Delete existing objects
delete(findobj(mainFig_MASWPassive,'tag','MASWPassive_Axis'));drawnow
MASWPassive_Axis = findobj(mainFig_MASWPassive,'tag','MASWPassive_Axis');
% cla(MASWPassive_Axis)
delete(findobj(mainFig_MASWPassive,'tag','xlimits_MASWPassivePlot'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','xlimits_MASWPassivePlot_text'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','crosscorrAMP_MASWPassivePlot_text'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','dynamicWinCorrSlider_MASWPassive'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','Reset_MASWPassivePlot'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','dynamicFiltersliderbar_MASWPassivePlot_text'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','dynamicFiltersliderbar_MASWPassivePlot'));drawnow

dataForMASWPassive_FILTERED = MASW_Passive.dataForMASWPassive_FILTERED;
time_corr_MASWPassive = MASW_Passive.time_corr_MASWPassive;
distanzeUniche = MASW_Passive.distanzeUniche;
time_corr_MASWPassive = MASW_Passive.time_corr_MASWPassive;

MASWPassive_Axis = axes(mainFig_MASWPassive,'Units','normalized','Position',[0.17 0.245 0.32 0.72],'Tag','MASWPassive_Axis');
for i = 1:size(dataForMASWPassive_FILTERED,2)
    hold on
    plot(MASWPassive_Axis,time_corr_MASWPassive,repmat(distanzeUniche(i),size(dataForMASWPassive_FILTERED,1),1)+dataForMASWPassive_FILTERED(:,i)./abs(max(dataForMASWPassive_FILTERED(:,i))),'color',[0,0,0]+0.5) %normalizzo per evidenziare le phases
end

ylim([0  max(distanzeUniche)+unique(diff(distanzeUniche))]);
xlabel(MASWPassive_Axis,'Correlation lag-time [s]','FontSize',12,'FontName','garamond');
ylabel(MASWPassive_Axis,'Inter-station distance [m]','FontSize',12,'FontName','garamond');
% grid on; grid minor
MASWPassive_Axis.XGrid = 'on';
MASWPassive_Axis.YGrid = 'on';
MASWPassive_Axis.XMinorGrid = 'on';
MASWPassive_Axis.YMinorGrid = 'on';
MASWPassive_Axis.XLim;
set(MASWPassive_Axis,'Tag','MASWPassive_Axis');

% Titolo
filterselected = get(findobj(mainFig_MASWPassive,'tag','filtertype_checkbox_MASWPassive'),'value');
filtertype = get(findobj(mainFig_MASWPassive,'tag','filtertype_checkbox_MASWPassive'),'string');
filtertype = filtertype(filterselected);
filterfreq = get(findobj(mainFig_MASWPassive,'tag','filterfreq_MASWPassive'),'string');
title(MASWPassive_Axis,[char(filtertype) ':' char(filterfreq) 'Hz'],'FontSize',10,'FontName','garamond');

% Pulsante modifica Xlimits
uicontrol(mainFig_MASWPassive,'style','text','units','normalized','position',[.17 .150 .03 .03],...
    'string','Xlimits','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','xlimits_MASWPassivePlot_text');
uicontrol(mainFig_MASWPassive,'style','edit','units','normalized','position',[.2 .150 .04 .03],'tag','xlimits_MASWPassivePlot',...
    'backgroundcolor',[1 1 1],'String',[num2str(MASWPassive_Axis.XLim(1)) ',' num2str(MASWPassive_Axis.XLim(2))],'horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring','Limits of xaxis. es. -2,2','Callback',@(numfld,event) updateCrossCorrPlot);

% Amplitude slidebar
uicontrol(mainFig_MASWPassive,'style','text','units','normalized','position',[.2450 .150 .04 .03],...
    'string','Amplitude','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','crosscorrAMP_MASWPassivePlot_text');

NdynamicWinCorr = 20; %numero di steps della slidebar
stepSz = [1,NdynamicWinCorr];
uicontrol(mainFig_MASWPassive,'style','slider','units','normalized','position',[.287 .150 .08 .03],...
    'Min',1,'Max',NdynamicWinCorr,'SliderStep',stepSz/(NdynamicWinCorr-1),'Value',1,...
    'Tag','dynamicWinCorrSlider_MASWPassive','callback',@(btn,event) sliderPlotAMP_MASWPassive(btn));

uicontrol(mainFig_MASWPassive,'style','pushbutton','units','normalized','position',[.44 .150 .05 .03],'tag','Reset_MASWPassivePlot',...
    'backgroundcolor',[.7 .7 .7],'String','Reset','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'tooltipstring','Reset button plot back the NO-Filtered Propersion curve','Callback',@(numfld,event) ResetPlot);


% salvo le linee nel plot per poter usare la sliderbar
lineeMainplot = MASWPassive_Axis.Children;
lineeMainplot_MASWPassive = zeros(length(lineeMainplot(1).YData),size(lineeMainplot,1));
for i = 1:size(lineeMainplot,1)
    lineeMainplot_MASWPassive(:,i) = lineeMainplot(i).YData';
end
MASW_Passive.lineeMainplot_MASWPassive = lineeMainplot_MASWPassive;

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ResetPlot
global mainFig_MASWPassive
choice = get(findobj(mainFig_MASWPassive,'tag','filtercheck_MASWPassive'),'value');
choice = choice{1};
% Se opzione filtro è selezionata, attiva la parte di inserimento dati filtro
if  choice == 1
    PlotCrossCorrelations_FILTERED %It works only for low-high-band pass filtering
else
    PlotCrossCorrelations
end
end

function sliderPlotAMP_MASWPassive(~)
global mainFig_MASWPassive
global MASW_Passive
% Slidebar
SliderselectedWinCorr = get(findobj(mainFig_MASWPassive,'tag','dynamicWinCorrSlider_MASWPassive'),'value');
% Axes
MASWPassive_Axis = findobj(mainFig_MASWPassive,'tag','MASWPassive_Axis');
linee = MASWPassive_Axis.Children;
delete(linee);
% Plot data
distanzeUniche = MASW_Passive.distanzeUniche;
STACKEDCorrelations_MASWPassive = MASW_Passive.STACKEDCorrelations_MASWPassive;
dataForMASWPassive = MASW_Passive.dataForMASWPassive;
time_corr_MASWPassive = MASW_Passive.time_corr_MASWPassive;

% Linee originali (non amplificate)
lineeMainplot_MASWPassive = MASW_Passive.lineeMainplot_MASWPassive;

increment = 1:0.5:30;
increment = increment(round(SliderselectedWinCorr));
dataForMASWPassive = MASW_Passive.dataForMASWPassive;

for i = 1:size(lineeMainplot_MASWPassive,2)
    j = size(lineeMainplot_MASWPassive,2)-i+1; %Le linee sono plottate in ordine inverso quindi ho bisogno di j che vada in senso opposto
    dist = distanzeUniche(j);
    plot(MASWPassive_Axis,time_corr_MASWPassive,((lineeMainplot_MASWPassive(:,i)-dist).*increment)+dist,'color',[0,0,0]+0.5);
    
end
end
function Filtersliderbar_MASWPassivePlot(~)
global mainFig_MASWPassive
global MASW_Passive


% Slidebar
SliderselectedWinCorr = get(findobj(mainFig_MASWPassive,'tag','dynamicFiltersliderbar_MASWPassivePlot'),'value');

% Dati
dataForMASWPassive = MASW_Passive.dataForMASWPassive; % per distance
dataForMASWPassive_FILTERED = MASW_Passive.dataForMASWPassive_FILTERED;
time_corr_MASWPassive = MASW_Passive.time_corr_MASWPassive;

% Axes and plot
MASWPassive_Axis = findobj(mainFig_MASWPassive,'tag','MASWPassive_Axis');
linee = MASWPassive_Axis.Children;
delete(linee);

% Plot
MASWPassive_Axis = findobj(mainFig_MASWPassive,'tag','MASWPassive_Axis');
for j = 1:size(dataForMASWPassive_FILTERED,1)-1
    plot(MASWPassive_Axis,time_corr_MASWPassive,dataForMASWPassive{j,3}+dataForMASWPassive_FILTERED{j+1,SliderselectedWinCorr+1}./abs(max(dataForMASWPassive_FILTERED{j+1,SliderselectedWinCorr+1})),'color',[0,0,0]+0.5) %normalizzo per evidenziare le phases
    hold(MASWPassive_Axis,'on')
end
% Plot characteristic
ylim([0 dataForMASWPassive{end,3}+5])
xlabel(MASWPassive_Axis,'Correlation lag-time [s]','FontSize',12,'FontName','garamond');
ylabel(MASWPassive_Axis,'Inter-station distance [m]','FontSize',12,'FontName','garamond');
% grid on; grid minor
MASWPassive_Axis.XGrid = 'on';
MASWPassive_Axis.YGrid = 'on';
MASWPassive_Axis.XMinorGrid = 'on';
MASWPassive_Axis.YMinorGrid = 'on';
MASWPassive_Axis.XLim
set(MASWPassive_Axis,'Tag','MASWPassive_Axis');
title(MASWPassive_Axis,[dataForMASWPassive_FILTERED{1,SliderselectedWinCorr+1} 'Hz'],'FontSize',10,'FontName','garamond');
end


%% ANALISI MASW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% COMPUTE ANALYSIS
function ComputeSurfWavesAnalysis
global MASW_Passive
global mainFig_MASWPassive
delete(findobj(mainFig_MASWPassive,'tag','result1MASW_Axis'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','result2MASW_Axis'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','cbar1LIM'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','cbar1LIM_value'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','cbar2LIM'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','cbar2LIM_value'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','cbar3LIM'));drawnow
delete(findobj(mainFig_MASWPassive,'tag','cbar3LIM_value'));drawnow

%Wait
avviso = annotation(mainFig_MASWPassive,'textbox','String','WAIT!!!','Color','b','FontWeight','bold','FontSize',15,...
    'Units','normalized','Position',[0.03 0.05 0.06 0.05],'EdgeColor','none','Tag','avviso');
drawnow

% Importa dati da mainFIG ----------------------------------
choice = get(findobj(mainFig_MASWPassive,'tag','filtercheck_MASWPassive'),'value');
choice = choice{1};
% Se opzione filtro è selezionata, scegli i dati filtrati
if  choice == 1
    dataRaw = MASW_Passive.dataForMASWPassive_FILTERED;
else
    dataRaw = MASW_Passive.STACKEDCorrelations_MASWPassive;
end
data_selected = MASW_Passive.data_selected;

% INPUT  ------------------------------------------------------------------
fs = data_selected(1).fs;
[ns,nx] = size(dataRaw);
distanzeUniche = MASW_Passive.distanzeUniche;
dx = mean(diff(distanzeUniche));
dt = 1/fs;
t = 0:dt:(ns-1)*dt;
x = 0:dx:(nx-1)*dx;


% Input data from mainFig ----------------------------------------------
MASW_bandwidth_edit = get(findobj(mainFig_MASWPassive,'tag','MASW_bandwidth_edit'),'String');
MASW_velocity_edit = get(findobj(mainFig_MASWPassive,'tag','MASW_velocity_edit'),'String');
MASW_method_list = get(findobj(mainFig_MASWPassive,'tag','MASW_method_choice'),'String');
MASW_method_choice = get(findobj(mainFig_MASWPassive,'tag','MASW_method_choice'),'Value');
MASW_freqStep = get(findobj(mainFig_MASWPassive,'tag','MASW_freqStep_edit'),'String');

% Freq
if strcmp(MASW_bandwidth_edit,'auto')
    freqMin = 0.05;
    freqMax = fs/2;
else
    range = str2num(MASW_bandwidth_edit);
    freqMin = range(1);
    freqMax = range(2);
end
res_freq = str2num(MASW_freqStep);
f_vector = freqMin:res_freq:freqMax;

% Vel
eval(['velRange = '  MASW_velocity_edit ';']);
min_vel = min(velRange);                           % VelocitÃ  minima per l'analisi [m/s]
max_vel = max(velRange);
res_vel = velRange(2)-velRange(1);                            % Step in velocitÃ  per l'analisi [m/s]

% Offset
min_offset = min(x);                    % Offset minimo per l'analisi [m]
max_offset = max(x);                    % Offset massimo per l'analisi [m]
offsetRes = dx;                          % Step in offset per l'analisi [m]
sourceOffset = 0;

% Metodo scelto
method = MASW_method_list(MASW_method_choice);


%% Method taup ------------------------------------------------------------
if strcmp(method,'TauP')
    dataRaw = dataRaw(:,[round((min_offset-sourceOffset)/dx)+1:round(offsetRes/dx):round((max_offset-sourceOffset)/dx)+1]);
    [ns,nx] = size(dataRaw);
    norm1 = max(abs(dataRaw));
    normalizzazione = meshgrid(norm1(:),1:ns);
    dataRaw = dataRaw./normalizzazione;
    % Tau-P ---------------------------------------------------------------
    p = fliplr(1./velRange);                                              % which p-values
    [tauP, M] = lpradonArosio(dataRaw,t,x,p,freqMin,freqMax,1,1);                 % transform
    % passo a freq-V
    Nsamples = length(t);
    N = 2^nextpow2(Nsamples);
    FreqAxis = 0:fs/(N-1):fs;
    taupF = fft(tauP,N,1);
    FreqAxis = FreqAxis(1:N/2);
    taupF_Mag = abs(taupF(1:N/2,:));
    
elseif strcmp(method,'PhaseShift')
    zerop_t = 4*2^(nextpow2(ns));             % Zero-padding temporale [-]
    % PhaseShift ----------------------------------------------------------
    dataRaw = dataRaw(:,[round((min_offset-sourceOffset)/dx)+1:round(offsetRes/dx):round((max_offset-sourceOffset)/dx)+1]);
    dataRaw = [dataRaw; zeros(zerop_t-ns,size(dataRaw,2))];                                                            % Zero-padding temporale
    [ns,nx] = size(dataRaw);
    f_vector = freqMin:res_freq:freqMax;
    V_vector = min_vel:res_vel:max_vel;
    %% FV Transform calculation - Phase-shift method
    fst = fs;                                                                                       % Frequenza campionamento temporale [Hz]
    dft = fst/ns;                                                                                   % Passo di campionamento in frequenza [Hz]
    fqzt = 0:dft:fst/2 - dft;                                                                       % Asse frequenze temporali da 0 a +Ny [Hz]
    offset_ax = (sourceOffset+(min_offset-sourceOffset)):offsetRes:(sourceOffset+(min_offset-sourceOffset))+(nx-1)*offsetRes;
    trasf = fft(dataRaw,ns,1);
    fv = zeros(length(V_vector),length(f_vector));
    counter_v = 1;
    w = waitbar(0,'Computing FV spectrum...');
    set(findobj(w,'type','patch'),'facecolor','b','edgecolor','b')
    for vel = min_vel:res_vel:max_vel
        counter_f = 1;
        for freq = freqMin:res_freq:freqMax
            fv(counter_v,counter_f) = sum(trasf(round(freq/dft),:)./abs(trasf(round(freq/dft),:)).*exp(2*pi*i*offset_ax*freq/vel));
            counter_f = counter_f + 1;
        end
        waitbar(counter_v/length(V_vector),w)
        counter_v = counter_v + 1;
    end
    close(w)
    FV = abs(fv);
    % Normalizzo lo spettro
    FV = FV / max(max(FV));
    
elseif strcmp(method,'FK')
    %      zerop_t = 4*2^(nextpow2(ns));             % Zero-padding temporale [-]
    %      zerop_x = 4*2^(nextpow2(nx));             % Zero-padding temporale [-]
    zerop_t = 4096;
    zerop_x = 2058;

    dataRaw = dataRaw(:,round((min_offset-sourceOffset)/dx)+1:round((max_offset-sourceOffset)/dx)+1);
    [ns,nx] = size(dataRaw); 
    dataRaw = [dataRaw; zeros(zerop_t-ns,nx)];                                                            % Zero-padding temporale
    dataRaw = [dataRaw zeros(size(dataRaw,1),zerop_x-nx)];                                                   % Zero-padding spaziale
    [ns,nx] = size(dataRaw);
    % 2D Transform calculation
    fst = fs;                                                                                       % Frequenza campionamento temporale [Hz]
    dft = fst/ns;                                                                                   % Passo di campionamento in frequenza [Hz]
    fqzt = 0:dft:fst/2 - dft;                                                                       % Asse frequenze temporali da 0 a +Ny [Hz]
    fss = 1/dx;                                                                                     % Frequenza campionamento spaziale [1/m]
    dfs = fss/nx;                                                                                   % Passo campionamento frequenze spaziali
    fqzs = 0:dfs:(fss - dfs);                                                                       % Asse frequenze spaziali da 0 a fss
    Spettro2d = fft2(dataRaw,ns,nx);                                                                   % Trasformata 2D della matrice    
end

%% Plot results -----------------------------------------------------------
if strcmp(method,'TauP')
    % ==> Plot time-V
    result1MASW_Axis = axes(mainFig_MASWPassive,'Units','normalized','Position',[0.58 0.58 0.36 0.34]);
    result1MASW_Axis.Toolbar.Visible = 'on';
    imagesc(t,velRange,fliplr(tauP));
    set(gca,'Tag','result1MASW_Axis');
%     colormap(jet);
    ylabel('Velocity [m/s]');
    xlabel('time [s]');
    title(['\tau-v Spectrum'],'fontweight','bold')
    result1MASW_Axis.Toolbar.Visible = 'on';
    % Colorbar
    posizioneAsse = result1MASW_Axis.Position;
    cbar1 = colorbar;
    cbar1.Position = [0.95 posizioneAsse(1,2) 0.01 posizioneAsse(4)];
    cbar1.Label.String = '[-]'
    MASW_Passive.cbar1 = cbar1;
    limiticbar1 = cbar1.Limits;
    uicontrol('style','text','Tag','cbar1LIM','units','normalized','position',[0.83 0.52 0.05 0.025],...
        'string','Cbar Lim','horizontalalignment','center','fontunits','normalized','fontsize',.6,'FontWeight','bold',...
        'backgroundcolor',[.8 .8 .8]);
    uicontrol('style','edit','tag','cbar1LIM_value','units','normalized','position',[0.88 0.52 0.06 0.025],...
        'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Tooltip','Set colorbar limits',...
        'String',[num2str(limiticbar1(1)) ',' num2str(limiticbar1(2))],'Callback',@(numfld,event) updateChanges_taup);
    
    % ==> Plot freq-V
    result2MASW_Axis = axes(mainFig_MASWPassive,'Units','normalized','Position',[0.58 0.1 0.36 0.35]);
    result2MASW_Axis.Toolbar.Visible = 'on';
    %     imagesc(FreqAxis,velRange,fliplr(taupF_Mag)); %MIO VECCHIO
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PRESO DA CODICE DIEGO TauPMethodCaLitaTest
    [nt,nh] = size(dataRaw);
    %if N==2; h=h/max(abs(h));end;
    nfft = 2*(2^nextpow2(nt));
    df = fs/nfft;                                                                                   % Passo di campionamento in frequenza [Hz]
    fqzt = 0:df:(nfft/2)*df;                                                                       % Asse frequenze temporali da 0 a +Ny [Hz]
    ilow  = floor(freqMin*dt*nfft)+1;
    if ilow < 2
        ilow=2;
    end
    ihigh = floor(freqMax*dt*nfft)+1;
    if ihigh > floor(nfft/2)+1
        ihigh=floor(nfft/2)+1;
    end
    % Normalizzo lo spettro
    Mtemp = abs(M(ilow:ihigh,:))';
    Mtemp = Mtemp / max(max(Mtemp));
    imagesc(fqzt(ilow:ihigh),1./p,20*log10(Mtemp+eps));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(gca,'Tag','result2MASW_Axis')
    axis xy
    colormap(jet)
    ylabel('Phase velocity [m/s]');
    xlabel('Frequency [Hz]');
    result2MASW_Axis.Toolbar.Visible = 'on';
    title(['f-v Spectrum from \tau-p Transform'],'fontweight','bold');
    % Colorbar
    posizioneAsse = result2MASW_Axis.Position;
    cbar2 = colorbar;
    cbar2.Position = [0.95 posizioneAsse(1,2) 0.01 posizioneAsse(4)];
    cbar2.Label.String = '[dB]'
    MASW_Passive.cbar2 = cbar2;
    limiticbar2 = cbar2.Limits;
    uicontrol('style','text','Tag','cbar2LIM','units','normalized','position',[0.83 0.037 0.05 0.025],...
        'string','Cbar Lim','horizontalalignment','center','fontunits','normalized','fontsize',.6,'FontWeight','bold',...
        'backgroundcolor',[.8 .8 .8]);
    uicontrol('style','edit','tag','cbar2LIM_value','units','normalized','position',[0.88 0.037 0.06 0.025],...
        'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Tooltip','Set colorbar limits',...
        'String',[num2str(limiticbar2(1)) ',' num2str(limiticbar2(2))],'Callback',@(numfld,event) updateChanges_taup);
    % ---------------------------------------------------------------------    
elseif strcmp(method,'PhaseShift')
    result1MASW_Axis = axes(mainFig_MASWPassive,'Units','normalized','Position',[0.58 0.58 0.36 0.34]);
    result1MASW_Axis.Toolbar.Visible = 'on';
    imagesc(f_vector,V_vector,20*log10(FV+eps))
    mindb = fix(20*log10(min(min(FV))+eps));
    set(gca,'Tag','result1MASW_Axis');
    axis xy                                                                 % Setta gli assi in modalitÃ  cartesiana
    colormap(jet)
    result1MASW_Axis.Toolbar.Visible = 'on';
    % Colorbar
    posizioneAsse = result1MASW_Axis.Position;
    cbar3 = colorbar;
    cbar.Position = [0.95 posizioneAsse(1,2) 0.01 posizioneAsse(4)];
    cbar3.Label.String = '[dB]';
    MASW_Passive.cbar3 = cbar3;
    limiticbar3 = cbar3.Limits;
    
    uicontrol('style','text','Tag','cbar3LIM','units','normalized','position',[0.83 0.52 0.05 0.025],...
        'string','Cbar Lim','horizontalalignment','center','fontunits','normalized','fontsize',.6,'FontWeight','bold',...
        'backgroundcolor',[.8 .8 .8]);
    uicontrol('style','edit','tag','cbar3LIM_value','units','normalized','position',[0.88 0.52 0.06 0.025],...
        'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Tooltip','Set colorbar limits',...
        'String',[num2str(limiticbar3(1)) ',' num2str(limiticbar3(2))],'Callback',@(numfld,event) updateChanges_Phaseshift);
    
    axis([min(f_vector) max(f_vector) min(V_vector) max(V_vector)]);
    xlabel('Frequency [Hz]'); 
    ylabel('Phase velocity [m/s]'); 
    title(['fv Spectrum'],'interpreter','none','fontweight','bold');
    
    % ---------------------------------------------------------------------
elseif strcmp(method,'FK')
    result1MASW_Axis = axes(mainFig_MASWPassive,'Units','normalized','Position',[0.58 0.58 0.36 0.34]);
    result1MASW_Axis.Toolbar.Visible = 'on';
    
    fqzt_sample = find((fqzt-freqMin)>=0,1,'first'):find((fqzt-freqMax)<=0,1,'last');
    fqzt = fqzt(fqzt_sample);
    %     % Trovo i campioni di fqzs corrispondenti al range di numeri d'onda selezionato
    %     fqzs_sample = find((fqzs-min_offset)>=0,1,'first'):find((fqzs-max_offset)<=0,1,'last');
    %     fqzs = fqzs(fqzs_sample);
    %     % Costruisco la matrice considerando lo spettro in tutta la sua interezza (k positivi e negativi)
    %     Spettro2d_unwrapped = Spettro2d(fqzt_sample(1):fqzt_sample(end),fqzs_sample(1):fqzs_sample(end));
    Spettro2d_unwrapped = Spettro2d(fqzt_sample(1):fqzt_sample(end),:);
    % Normalizzo lo spettro
    Spettro2d_unwrapped = Spettro2d_unwrapped/max(max(Spettro2d_unwrapped));
    %     % Disegna la trasformata
    imagesc(fqzs,fqzt,20*log10(abs(Spettro2d_unwrapped)+eps));
    axis xy                                                                 % Setta gli assi in modalità cartesiana
    set(gca,'Tag','result1MASW_Axis');
    colormap(jet)                                                          % Per gestire più colormap nella stessa figura
    axis([min(fqzs) max(fqzs) min(fqzt) max(fqzt)]);
    xlabel('Wavenumber [1/m]'); 
    ylabel('Frequency [Hz]');   
    title(['FK Spectrum'],'interpreter','none','fontweight','bold');
    % Colorbar
    posizioneAsse = result1MASW_Axis.Position;
    cbar3 = colorbar;
    cbar3.Position = [0.95 posizioneAsse(1,2) 0.01 posizioneAsse(4)];
    cbar3.Label.String = '[dB]'
    MASW_Passive.cbar3 = cbar3;
    limiticbar3 = cbar3.Limits;
    uicontrol('style','text','Tag','cbar3LIM','units','normalized','position',[0.83 0.52 0.05 0.025],...
        'string','Cbar Lim','horizontalalignment','center','fontunits','normalized','fontsize',.6,'FontWeight','bold',...
        'backgroundcolor',[.8 .8 .8]);
    uicontrol('style','edit','tag','cbar3LIM_value','units','normalized','position',[0.88 0.52 0.06 0.025],...
        'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Tooltip','Set colorbar limits',...
        'String',[num2str(limiticbar3(1)) ',' num2str(limiticbar3(2))],'Callback',@(numfld,event) updateChanges_FK);
       
end

delete(avviso);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Attivo tasti in funzione del metodo scelto
function activationRequiredParameters
global MASW_Passive
global mainFig_MASWPassive

%% Scelta del metodo
listOfMethods = get(findobj(mainFig_MASWPassive,'tag','MASW_method_choice'),'string');
chosenMethod = get(findobj(mainFig_MASWPassive,'tag','MASW_method_choice'),'value');
chosenMethod = listOfMethods(chosenMethod); %Metodo scelto per effettuare analisi HVettrale

%% Disattivo parametri non necessari per HV analysis
switch char(chosenMethod)
    case 'TauP'
        set(findobj(mainFig_MASWPassive,'tag','MASW_freqStepText'),'enable','off');
        set(findobj(mainFig_MASWPassive,'tag','MASW_freqStep_edit'),'enable','off');
        
    case 'PhaseShift'
        set(findobj(mainFig_MASWPassive,'tag','MASW_freqStepText'),'enable','on');
        set(findobj(mainFig_MASWPassive,'tag','MASW_freqStep_edit'),'enable','on');
        
    case 'FK'
        set(findobj(mainFig_MASWPassive,'tag','MASW_freqStepText'),'enable','off');
        set(findobj(mainFig_MASWPassive,'tag','MASW_freqStep_edit'),'enable','off');
end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updateChanges_taup
global MASW_Passive
global mainFig_MASWPassive
result1MASW_Axis = findobj(mainFig_MASWPassive,'tag','result1MASW_Axis');
result2MASW_Axis = findobj(mainFig_MASWPassive,'tag','result2MASW_Axis');
cbar1LIM = str2num(get(findobj(mainFig_MASWPassive,'tag','cbar1LIM_value'),'string'));
cbar2LIM = str2num(get(findobj(mainFig_MASWPassive,'tag','cbar2LIM_value'),'string'));

% tau-P
cbar1 = MASW_Passive.cbar1;
result1MASW_Axis.CLim = cbar1LIM;
cbar1.Limits = cbar1LIM; %Aggiorna colorbar

cbar2 = MASW_Passive.cbar2;
result2MASW_Axis.CLim = cbar2LIM;
cbar2.Limits = cbar2LIM; %Aggiorna colorbar

end

function updateChanges_Phaseshift
global MASW_Passive
global mainFig_MASWPassive
result1MASW_Axis = findobj(mainFig_MASWPassive,'tag','result1MASW_Axis');
cbar3LIM = str2num(get(findobj(mainFig_MASWPassive,'tag','cbar3LIM_value'),'string'));

% Phase shift
cbar3 = MASW_Passive.cbar3;
result1MASW_Axis.CLim = cbar3LIM;
cbar3.Limits = cbar3LIM; %Aggiorna colorbar
end

function updateChanges_FK
global MASW_Passive
global mainFig_MASWPassive
result1MASW_Axis = findobj(mainFig_MASWPassive,'tag','result1MASW_Axis');
cbar3LIM = str2num(get(findobj(mainFig_MASWPassive,'tag','cbar3LIM_value'),'string'));

% FK
cbar3 = MASW_Passive.cbar3;
result1MASW_Axis.CLim = cbar3LIM;
cbar3.Limits = cbar3LIM; %Aggiorna colorbar

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
