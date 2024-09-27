function [data] = deleteSignalsRAW(data)

global utilities
% global data

dataUpdate = data;

ListBoxValue = get(utilities.handles.listRaw,'Value'); %segnali selezionati in listRAW

% elimina i segnali che non servono
dataUpdate(ListBoxValue) = [];

if length(dataUpdate) == 0 
    clear data
    set(utilities.handles.listRaw,'string',[],'FontSize',utilities.ListboxfontSize,'Value',1); % Ho dovuto mettere Value,1 perchè altrimenti quando caricavo un solo segnale la listRaw non si riempiva
    cd(utilities.softwareFolder)
    
else
% Crea lista nomi per riempire listbox
for ind=1:length(dataUpdate)
    LboxNames{ind} = dataUpdate(ind).name; %compile cell array of names.
end
% Riempi listbox
set(utilities.handles.listRaw,'string',LboxNames,'FontSize',utilities.ListboxfontSize,'Value',1); % Ho dovuto mettere Value,1 perchè altrimenti quando caricavo un solo segnale la listRaw non si riempiva
set(utilities.handles.listRaw,'max',length(LboxNames)); %make it so you can select more than 1.
cd(utilities.softwareFolder)
end

data = dataUpdate;
end