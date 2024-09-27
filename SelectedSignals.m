%%% Questa funzione serve per indicare quali segnali sono stati selezionati
%%% nella tabella "SIGNAL FOR PROCESSING". Questo è necessario se si vuole
%%% ad esempio filtrare/unire/tagliare/sovracampionare... solo i segnali
%%% selezionati. il vettore output della funzione è "selected" ed indica
%%% quali sono le righe selezionate dalla tabella "SIGNAL FOR PROCESSING"


function SelectedSignals(hObj,evt)
disp(evt);
selected = evt.Indices;
selected = unique(selected(:,1));
assignin('base','selected',selected); %serve per salvare nel base workspace la variabile selected che indica quali segnali sono stati selezionati nella uitable
end

