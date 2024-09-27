%%%%%%%%%%%%%%%          ISTRUZIONI CODICE        %%%%%%%%%%%%%%%%%%%%%%%%%

%%% Questo codice è la parte universale che dev'essere aggiunta ad ogni
%%% funzione di processamento dei segnali per fare in modo che quando i
%%% segnali non sono stati selezionati prima del merge/filtro/taglio, il
%%% codice mette a display un errore il quale chiede di selezionare i
%%% segnali prima di processarli

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function data_processing = proc_UNIVERSALE(data_processing)

global utilities


%% 0.0) Prima di fare il merge controlla che i segnali siano stati selezionati!
% Se non sono stati selezionati termina la funzione
if logical(evalin('base','~exist(''selected'')'))
    h=msgbox('No data have been selected! Please select data from "Signal for processing" list!','Update','error');
    return
else selected = evalin('base','selected'); % Se esiste carica la variabile selected dal base-workspace
end




%% DA METTERE ALLA FINE
% Cancella il vettore che indica quali segnali sono stati selezionati dalla
% lista "Signal for processing"
evalin( 'base', 'clearvars selected' )