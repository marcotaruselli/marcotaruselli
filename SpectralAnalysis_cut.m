
function SpectralAnalysis_cut
global utilities
global spectralAnalysis

%segnale
data_selected = spectralAnalysis.data_selected;



waittext = uicontrol(utilities.handles.mainFig,'style','text','units','normalized','position',[.93 .01 .06 .04],'string','Wait...',...
    'ForegroundColor','r','FontSize',12,'FontWeight','bold','Tag','waittext');


%% 2a) Definisco T0
T0 = data_selected.timeAx(1);

%% 2b) Definisco End
End = data_selected.timeAx(end);

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
    'String','Compute','Callback', @(btn,event) ButtonPushed_Compute(btn,Cutfigure));
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
function ButtonPushed_Compute(btn,Cutfigure)
global utilities
global spectralAnalysis

%segnale
data_selected = spectralAnalysis.data_selected;

startcut = datenum(get(utilities.handles.from_edit,'String'));
endcut = datenum(get(utilities.handles.to_edit,'String'));

% Taglia all'inzio
data_selected.signal(data_selected.timeAx<startcut) = [];
data_selected.timeAx(data_selected.timeAx<startcut) = [];
% Taglia alla fine
data_selected.signal(data_selected.timeAx>endcut) = [];
data_selected.timeAx(data_selected.timeAx>endcut) = [];


%% 3) Update con il segnale filtrato
spectralAnalysis.data_selected = data_selected;

%% 4) Update mainfig
set(findobj(spectralAnalysis.mainSpectralAnalysisFig,'tag','Signals_startTime'),'string',datestr(data_selected.timeAx(1)));
set(findobj(spectralAnalysis.mainSpectralAnalysisFig,'tag','Signals_endTime'),'string',datestr(data_selected.timeAx(end)));


%% Messaggio finale
h=msgbox('Data has been cut!','Update','warn');
pause(1)
close(h);close(Cutfigure)
delete(findobj('tag','waittext'));drawnow
clc

%% Aggiornamento plot
ax1_spectralAnalysis = spectralAnalysis.ax1_spectralAnalysis; %richiamo asse
delete(get(ax1_spectralAnalysis,'Children')); %Cancella il plot esistente e aggiornalo col segnale filtrato
plot(ax1_spectralAnalysis,data_selected.timeAx,data_selected.signal,'Color','k');
beep on; beep
gca
set(get(ax1_spectralAnalysis,'XLabel'),'String','Time');

if strcmp(data_selected.name(1:3),'Dec')
    set(get(ax1_spectralAnalysis,'YLabel'),'String','m/s');
else
set(get(ax1_spectralAnalysis,'YLabel'),'String','Signal not deconvolved','Color','r');    
end

grid(ax1_spectralAnalysis,'on')
grid(ax1_spectralAnalysis,'minor')
datetick(ax1_spectralAnalysis);
set(ax1_spectralAnalysis,'XLim',[data_selected.timeAx(1), data_selected.timeAx(end)])

%% rendi invisibili gli assi e cancella plot già esistenti
ax2_spectralAnalysis = spectralAnalysis.ax2_spectralAnalysis;
set(ax2_spectralAnalysis,'visible','off')
delete(get(ax2_spectralAnalysis, 'children'))
ax3_spectralAnalysis = spectralAnalysis.ax3_spectralAnalysis;
set(ax3_spectralAnalysis,'visible','off')
delete(get(ax3_spectralAnalysis, 'children'))

%% Cancella colorbar se esistono
colorbar('off')
end

%%%%%%%%%%%%%%       ButtonPushed_Cancel        %%%%%%%%%%%%%%%%%%%%%%%%%%%
function ButtonPushed_Cancel(btn,Cutfigure)
beep
h=msgbox('No data has been cut!','Update','warn');
pause(1)
close(h);close(Cutfigure)
clc
end
