function data_processing = proc_alignSignals(data_processing);
global utilities

%% Controlli iniziali
% Se non sono stati selezionati segnali termina la funzione
if logical(evalin('base','~exist(''selected'')'))
    h=msgbox('No data have been selected! Please select data from "Signal for processing" list!','Update','error');
    return
else selected = evalin('base','selected'); % Se esiste carica la variabile selected dal base-workspace
end
% Dati da allineare
data_selected = data_processing(selected,1); %Dati selezionati da tabella "Signal for processing"


% Devono essere stati selezionati solo due segnali
if not(length(selected) == 2)
    h=msgbox('You MUST select two signals!','Update','error');
    return
end
% Check if the two selected signals have the same Fs
if ~isequal(data_selected(1).fs, data_selected(2).fs)
    beep
    waitfor(msgbox({'The signals MUST have the same sampling frequency!'},'Update','error'))
    return
end

%% MAIN FIGURE
figAlignMAIN = figure('numbertitle','off','Name','Align signals','Units','normalized','Position', [0.25 0.25 0.5 0.5]);

%% Segnali S1 e S2
S1= [data_selected(1).timeAx data_selected(1).signal];
S2= [data_selected(2).timeAx data_selected(2).signal];

%% Plot segnali da allineare
axInputSignals = axes(figAlignMAIN,'Units','normalized','Position',[0.05 0.6 0.9 0.3]);
axInputSignals.Toolbar.Visible = 'on';
plot(S1(:,1),S1(:,2),'b')
hold on
plot(S2(:,1),S2(:,2),'g')
legend('Signal 1', 'Signal 2')
grid on; grid minor
title('NOT aligned signals')
datetickzoom

%% Calcolo ritardo e allineo segnali
%%% Allineamento anche dell'asse temporale
d = finddelay(S1(:,2),S2(:,2));
if d > 0
    S2_Aligned = S2(d:end,:);
    if length(S2_Aligned) > length(S1(:,2)) %se S2 allineato rimane più lungo di S1
        S1_Aligned(:,2) = S1(1:end,2);
        S2_Aligned(length(S1_Aligned)+1:end,:) = [];
    else
        S1_Aligned(:,2) = S1(1:length(S2_Aligned),2);
    end
    S1_Aligned(:,1) = S2_Aligned(:,1);
else
    S1_Aligned = S1(abs(d):end,:);
    if length(S1_Aligned) > length(S2(:,2)) %se S2 allineato rimane più lungo di S1
        S2_Aligned(:,2) = S2(1:end,2);
        S1_Aligned(length(S2_Aligned)+1:end,:) = [];
    else
        S2_Aligned(:,2) = S2(1:length(S1_Aligned),2);
    end
    S2_Aligned(:,1) = S1_Aligned(:,1);
end
    
%% Display il ritardo e chiedi se continuare o uscire dal tool
frase = ['Between the two signals a delay of ' num2str(abs(d)) ' samples has been detected. Given Fs = ' ...
    num2str(data_selected(1).fs) 'Hz means a delay of ' num2str(abs(d)/data_selected(1).fs) 's.']; 
testo = annotation('textbox','Units','normalized','Position',[0.04 0.06 0.9 0.05],...
    'String',frase,'FontName','garamond','FontSize',10,'EdgeColor','none','LineStyle','none');

%% Plot segnali allineati
axAlignedSignals = axes(figAlignMAIN,'Units','normalized','Position',[0.05 0.19 0.9 0.3]);
axAlignedSignals.Toolbar.Visible = 'on';
plot(S1_Aligned(:,1),S1_Aligned(:,2),'b')
hold on
plot(S2_Aligned(:,1),S2_Aligned(:,2),'g')
legend('Signal 1', 'Signal 2')
grid on; grid minor
title('Aligned signals')
datetickzoom

%% Buttons
% Create Compute button
compute = uicontrol(figAlignMAIN,'Style','pushbutton','Units','normalized','Position', [0.85 0.06 0.1 0.04],...
    'String','Align','Callback', @(btn,event) ButtonPushed_Compute(btn,S1_Aligned,S2_Aligned,figAlignMAIN),...
    'FontWeight','bold');
% Create Cancel button
cancel = uicontrol(figAlignMAIN,'Style','pushbutton','Units','normalized','Position',  [0.85 0.02 0.1 0.04],...
    'String','Quit','Callback', @(btn, event) ButtonPushed_Cancel(btn,figAlignMAIN),...
    'FontWeight','bold');


end

function ButtonPushed_Compute(btn,S1_Aligned,S2_Aligned,figAlignMAIN)
selected = evalin('base','selected');
data_processing = evalin('base','data_processing');
% segnale 1
data_processing(selected(1)).timeAx = S1_Aligned(:,1); 
data_processing(selected(1)).signal = S1_Aligned(:,2);
% segnale 2
data_processing(selected(2)).timeAx = S2_Aligned(:,1); 
data_processing(selected(2)).signal = S2_Aligned(:,2);

% Esporta i segnali nel base workspace
assignin('base','data_processing',data_processing);

% Messaggio
beep
h=msgbox('The signals have been aligned!','Update','warn');
pause(1.5)
close(h);close(figAlignMAIN)
clc
end

function ButtonPushed_Cancel(btn,figAlignMAIN)
beep
h=msgbox('The signals have NOT been aligned!','Update','warn');
pause(1.5)
close(h);close(figAlignMAIN)
clc
end