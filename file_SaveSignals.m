%%%%%%%%%%%%%%%%%%%%%%%%%       file_SaveSignals       %%%%%%%%%%%%%%%%%%%%
% Questa funzione permette di salvare i segnali nel nostro formato
% personale la cui estensione sarà .taru

function file_SaveSignals(data_processing)
waitfor(msgbox('All the signals within "Signals for processing" table will be saved in a database with .taru extension')) 
[filename, pathname] = uiputfile('*.taru','Save file as');
save(fullfile(pathname,filename),'data_processing')
% Display che il salvataggio è avvenuto
beep on; beep
h=msgbox('Data have been successfully saved!','Update','warn');
pause(1) 
close(h)
end