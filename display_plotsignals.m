function display_plotsignals(data_processing)
global utilities

%% 0) Prima di applicare la funzione controlla che qualche segnale sia stato selezionato!
if logical(evalin('base','~exist(''selected'')'))
    h=msgbox('No data have been selected! Please select data from "Signal for processing" list!','Update','error');
    return
else
    selected = evalin('base','selected'); % Se esiste carica la variabile selected dal base-workspace
end

%% 1) Creo vettore dei dati selezionati dalla tabella
% Dati selezionati
data_selected = data_processing(selected,1); %Dati selezionati da tabella "Signal for processing"

nSig = size(data_selected,1);
figure

for I = 1:nSig
    subplot(nSig,1,I)
    plot(data_selected(I).timeAx,data_selected(I).signal);
    eval(['xlim([' num2str(data_selected(I).timeAx(1)) ',' num2str(data_selected(I).timeAx(end)) '])'])
    titolo = regexprep(data_selected(I).name,'_','','emptymatch');
    title(titolo)
    eval(['legend(''' data_selected(I).Comp ''');'])
    datetickzoom
    if I == nSig
        xlabel('Time')
    end
end