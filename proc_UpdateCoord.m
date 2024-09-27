function data_processing = proc_UpdateCoord(data_processing)

global utilities

%% Aggiorna la colonna Coord della struct Data 
for idx = 1:size(data_processing,1)
    comp = utilities.handles.table.Data{idx,3};
    data_processing(idx).Comp = comp;
end

% Display che l'update è avvenuto
beep on; beep
h=msgbox('Components have been successfully update!','Update','warn');
pause(1) 
close(h)


cd(utilities.softwareFolder)