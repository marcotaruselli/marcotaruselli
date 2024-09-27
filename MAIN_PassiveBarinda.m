clear; clear global data;close('all','force'); clc;

global utilities

utilities.version = '2020.05.09';
utilities.softwareFolder = pwd;
utilities.handles = struct; 
utilities.historyVar = [];
utilities.trasdConstNanoSystem = 301239990;                                 % Transduction constant of the whole Nanometrics acquisition system [counts/(m/s)]
utilities.customCmap = [];
utilities.titlefontSize = 0.8;  
utilities.buttonfontSize = 0.4;
utilities.ListboxfontSize = 0.07;


addpath([utilities.softwareFolder '\JPlotResp_v1.80_dist']);
addpath([utilities.softwareFolder '\Documents']);
addpath(genpath(utilities.softwareFolder))

% Main window
utilities.handles.mainFig = figure('units','normalized','outerposition',[0 0 1 1],'WindowState','maximized','toolbar','none',...
    'menubar','none','numbertitle','off','name',['PaSSiVeBaRinDa ' utilities.version],...
    'defaultuicontrolunits','normalized','closerequestfcn',...
    ['button = questdlg(''Do you really want to exit the program?'',''Quit PaSSiVeBaRinDa'',''Yes'',''No'',''No'');',...
    'if strcmp(button,''No'') || strcmp(button,'''');clear button; return;',...
    'else set(findobj(0,''type'',''figure''),''closerequestfcn'',''closereq''); clear all; close(''all'',''force''); clc;end']);

%% MENU FILE
utilities.handles.file = uimenu(utilities.handles.mainFig,'label','File');
uimenu(utilities.handles.file,'label','Load signals','callback','[data] = file_LoadSignals;','enable','on');
uimenu(utilities.handles.file,'label','Save signals','callback','file_SaveSignals(data_processing);','enable','off');
% uimenu(utilities.handles.file,'label','Save','callback','DataSave(''start'');','enable','off');
% utilities.handles.fi
% uimenu(utilities.handles.file,'label','Reset Workspace','callback',...
%     ['button = questdlg(''All data loaded in the workspace will be deleted. Do you want to proceed?'',''Reset Workspace'',''Yes'',''No'',''No'');',...
%     'if strcmp(button,''No'') || strcmp(button,'''');clear button; return;',...
%     'else clearvars -except utilities; Undo; end'],'enable','off');
% uimenu(utilities.handles.file,'label','Join Datasets','separator','on','enable','off','callback','DataJoin(''start'');')
uimenu(utilities.handles.file,'label','Exit Passive Barinda','separator','on','callback',...
    ['button = questdlg(''Do you really want to exit the program?'',''Quit PaSSiVeBaRinDa'',''Yes'',''No'',''No'');',...
    'if strcmp(button,''No'') || strcmp(button,'''');clear button; return;',...
    'else set(findobj(0,''type'',''figure''),''closerequestfcn'',''closereq'');clear; close all; clc;end']);


%% MENU PROCESSING
utilities.handles.proc = uimenu(utilities.handles.mainFig,'label','Processing','enable','off');
utilities.handles.proc_align = uimenu(utilities.handles.proc,'label','Align Signals','callback','data_processing = proc_alignSignals(data_processing);');
utilities.handles.proc_resample = uimenu(utilities.handles.proc,'label','Resampling','callback','data_processing = proc_resampling(data_processing);');
utilities.handles.proc_merge = uimenu(utilities.handles.proc,'label','Merge','callback','data_processing = proc_merge(data_processing);');
utilities.handles.proc_filtering = uimenu(utilities.handles.proc,'label','Filter','callback','data_processing = proc_filtering(data_processing)');
utilities.handles.proc_cut = uimenu(utilities.handles.proc,'label','Cut','callback','data_processing = proc_cut(data_processing)');
utilities.handles.proc_deconvolution = uimenu(utilities.handles.proc,'label','Response Deconvolution','callback','ResponseDeconvolutionGUI(data_processing);');
utilities.handles.proc_spectralanalysis = uimenu(utilities.handles.proc,'label','Spectral Analysis','callback','SpectralAnalysis_MAIN(data_processing);');
utilities.handles.proc_polarization = uimenu(utilities.handles.proc,'label','Polarization Analysis','callback','PolarizationAnalysis(data_processing);');
utilities.handles.proc_polarization = uimenu(utilities.handles.proc,'label','HVSR Analysis','callback','HVSRAnalysis_MAIN(data_processing);');
% Passive interferometry
utilities.handles.proc_passiveInterferometry = uimenu(utilities.handles.proc,'label','Passive Interferometry');
% utilities.handles.proc_autoCorr = uimenu(utilities.handles.proc_passiveInterferometry,'label','Auto-Correlation Analysis');
utilities.handles.proc_crossCorr = uimenu(utilities.handles.proc_passiveInterferometry,'label','Cross-Correlation Analysis','callback','CrossCorr_Analysis_MAIN(data_processing);');
utilities.handles.proc_intraCorr = uimenu(utilities.handles.proc_passiveInterferometry,'label','Intra-Correlation Analysis');
utilities.handles.proc_propagationPlot = uimenu(utilities.handles.proc_passiveInterferometry,'label','Propagation plot','callback','Propagation_Analysis_MAIN(data_processing);');
% MASW
utilities.handles.proc_MASW = uimenu(utilities.handles.proc,'label','MASW');
utilities.handles.proc_MASW_ATTIVE = uimenu(utilities.handles.proc_MASW,'label','Attive','callback','MASW_MAIN_Attive(data_processing);');
utilities.handles.proc_MASW_PASSIVE = uimenu(utilities.handles.proc_MASW,'label','Passive','callback','MASW_MAIN_Passive(data_processing);');

%% MENU DISPLAY
utilities.handles.disp = uimenu(utilities.handles.mainFig,'label','Display','enable','on');
uimenu(utilities.handles.disp,'label','Plot signals','callback','display_plotsignals(data_processing);');
uimenu(utilities.handles.disp,'label','Video CrossCorr','callback','CrossCorr_plotDynamicCorrWindow;');


%% MENU SAVE
utilities.handles.save = uimenu(utilities.handles.mainFig,'label','Save','callback','Save_data');
% uimenu(utilities.handles.save,'label','Save','callback','[data] = file_LoadSignals;','enable','on');


%% LISTBOX RAW SIGNALS
%1) Name listbox
uicontrol('Style','text','units','normalized','Position',[.005 .965 .12 .025],...
    'String','Raw Signals','horizontalalignment','center','fontunits','normalized','fontsize',utilities.titlefontSize,...
    'backgroundcolor',[224/255 224/255 224/255])
%2) Crea Listbox
utilities.handles.listRaw = uicontrol('Style','listbox','units','normalized','position',[.005 .765 .12 .2],...
    'string','','value',1,'backgroundcolor',[1 1 1],'min',0,'max',10,'fontunits','normalized','fontsize',utilities.titlefontSize); %,'callback','');
%3) LoadSignals
    uicontrol('style','pushbutton','units','normalized','position',[.005 .7345 .035 .03 ],...
    'string','Load','fontunits','normalized','fontsize',utilities.buttonfontSize,'callback','[data] = file_LoadSignals;')

%4) Delete button
uicontrol('style','pushbutton','units','normalized','position',[.042 .7345 .035 .03 ],...
    'string','Delete','fontunits','normalized','fontsize',utilities.buttonfontSize,'callback','[data] = deleteSignalsRAW(data);')

%5) Process button
uicontrol('style','pushbutton','units','normalized','position',[.079 .7345 .035 .03 ],...
    'string','Process','fontunits','normalized','fontsize',utilities.buttonfontSize,'callback','data_processing = proc_processRawData(data);')

%% LIST SIGNALS FOR PROCESSING
uicontrol('Style','text','units','normalized','Position',[.005 .69 .12 .025],...
    'String','Signals for processing','horizontalalignment','center','fontunits','normalized','fontsize',utilities.titlefontSize,...
    'backgroundcolor',[153/255 255/255 153/255])

utilities.handles.table = uitable('Units','normalized','Position',[.005 .49 .12 .2],'backgroundcolor',[1 1 1],'CellSelectionCallback',@SelectedSignals);
% utilities.handles.listProcess = uicontrol('Style','listbox','units','normalized','position',[.005 .59 .12 .1],...
%     'string','','value',1,'backgroundcolor',[1 1 1],'min',0,'max',10,'fontunits','normalized','fontsize',utilities.titlefontSize); %'callback','');
%
utilities.handles.apply = uicontrol('style','pushbutton','units','normalized','position',[.005 .4585 .045 .03 ],...
    'string','Update','fontunits','normalized','fontsize',utilities.buttonfontSize,'callback',...
    '[data_processing] = proc_UpdateCoord(data_processing)','TooltipString', ['Click Update if you modified the coordinates', char(10)]);

%4) Delete button
uicontrol('style','pushbutton','units','normalized','position',[.052 .4585 .045 .03 ],...
    'string','Delete','fontunits','normalized','fontsize',utilities.buttonfontSize,'callback','[data_processing] = deleteSignalsforPROC(data_processing);')


%% WAIT BAR
uicontrol('Style','text','Units','normalized','Position',[.005 .03 .12 .025],...
    'String','Wait...','horizontalalignment','left','fontunits','normalized',...
    'fontsize',utilities.titlefontSize,'Tag','wait','Visible','off');
utilities.handleToWaitBar = axes('Units','normalized','Position',[.005 .005 .12 .025],'XLim',[0 1],'YLim',[0 1],'XTick',[],'YTick',[],...
'Color', 'w','XColor','w','YColor', 'w','tag','handleToWaitBar','Visible','off');
patch([0 0 0 0], [0 1 1 0], 'g','Parent', utilities.handleToWaitBar,'EdgeColor','none');
drawnow

%% Custom colormap cmapWBR
cmap(7,:) = [128/255 0 0];   %// color first row - red
cmap(6,:) = [1 0 0];   %// color 25th row - green
cmap(5,:) = [1 1 0];   %// color 50th row - blue
cmap(4,:) = [0 1 1];   %// color 50th row - blue
cmap(3,:) = [0 0 1];   %// color 50th row - blue
cmap(2,:) = [0 0 159/255];   %// color 50th row - blue
cmap(1,:) = [1 1 1];   %// color 50th row - blue
[X,Y] = meshgrid(1:3,1:64);  %// mesh of indices
cmapwbr = interp2(X([1,5,11,24,40,56,64],:),Y([1,5,11,24,40,56,64],:),cmap,X,Y); %// interpolate colormap
utilities.customCmap = cmapwbr;
clear cmap X Y cmapwbr

