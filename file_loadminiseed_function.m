function [X,I,datocreato] = file_loadminiseed_function(signal,Nsignals,folder)

cd(folder)
[X,I] = rdmseed(signal);


%%%%%%%%%%%%%%%%%      Ripara struttura I         %%%%%%%%%%%%%%%%%%%%%%%%%
%%% Questa parte serve per risolvere il problema riscontrato con RS dove
%%% capitava per alcuni segnali che la struttura I era formata da due righe
%%% di cui la prima era vuota. questa è una soluzione che per il caso
%%% osservato funziona, però non so se funzionerà per tutti i casi che
%%% incontrerò.
% repairI = I;
% for i = 1:size(repairI,2)
%     if  ~contains(I(i).ChannelFullName,X(1).ChannelIdentifier)
%         repairI(i) = [];
%     end
% end
% I = repairI;
% %%%%
datocreato = [];
for ii = 1:size(I,2)
    
    %% 1)Se non ci sono buchi allora
    if isempty(I(ii).GapBlockIndex)
        k = [I(ii).XBlockIndex];
        if ~isempty(datestr(X(k(1)).t)) %l'ho messo perchè a volte il RS è vuoto
            % Importo dati
            name = [X(k(1)).StationIdentifierCode '_' X(k(1)).ChannelIdentifier '_'  datestr(X(k(1)).t(1),'ddmmmyyyyHHMM')];
            signal  = double([cat(1,X(k(:,1)).d)]);
            stn = X(k(1)).StationIdentifierCode;
            fs = X(k(1)).SampleRate;
            timeAx = cat(1,X(k(:,1)).t);
            %%% fine 1 %%%
            
            %%%%%%%%%%%    A: Riscrivo vettore temporale     %%%%%%%%%%%%%
            % E' necessario perchè ho notato che a volte il vettore
            % temporale scaricato dal miniseed manca di alcune ore. Questo
            % poi si traduce in errori quando viene effettuato il cut dei
            % segnali
            
            starttimevec=timeAx(1);
            endtimevec=timeAx(end);
            % da convertire in questo formato
            formatOut = 'yyyy-mm-dd HH:MM:SS.FFF';
            % Converti tempo iniziale nel formato necessario per usare datetime function
            startstring = datestr(starttimevec,'dd-mmm-yy HH:MM:SS.FFF');
            startstring = datestr(datenum(startstring,'dd-mmm-yy HH:MM:SS.FFF'),formatOut);
            % Converti tempo finale nel formato necessario per usare datetime function
            endstring = datestr(endtimevec,'dd-mmm-yy HH:MM:SS.FFF');
            endstring = datestr(datenum(endstring,'dd-mmm-yy HH:MM:SS.FFF'),formatOut);
            % Creo nuovo vettore temporale
            t1 = datetime(startstring,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');
            t2 = datetime(endstring,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');
            timeAx = t1:seconds(1/fs):t2;
            timeAx = datenum(timeAx)';
            %%%%%%%%%%%%%%      Fine sezione A   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            %Creo struct segnale
            row = 1;
            eval(['datosegnale(' num2str(row) ',1).name = name;'])
            eval(['datosegnale(' num2str(row) ',1).fs = fs;'])
            if contains(X(k(1)).ChannelIdentifier, {'X', 'HEW','EHE','BHE'})
                eval(['datosegnale(' num2str(row) ',1).Comp = ' '''East''' ';'])
            elseif contains(X(k(1)).ChannelIdentifier, {'Y', 'HNS','EHN','BHN'})
                eval(['datosegnale(' num2str(row) ',1).Comp = ' '''North''' ';'])
            elseif contains(X(k(1)).ChannelIdentifier, {'Z','HNZ','EHZ','BHZ'})
                eval(['datosegnale(' num2str(row) ',1).Comp = ' '''Vertical''' ';'])
            end
            eval(['datosegnale(' num2str(row) ',1).stn = stn;'])
            eval(['datosegnale(' num2str(row) ',1).signal = signal;'])
            eval(['datosegnale(' num2str(row) ',1).timeAx = timeAx;'])
            % se aggiungo anche l'ora di inzio e di fine poi creo confusione con il merge
            %     starttime = datestr(timeAx(1),'dd-mmm-yyyy HH:MM:SS.fff');
            %     eval(['datosegnale(' num2str(row) ',1).start_time = starttime;'])
            %     endtime = datestr(timeAx(end),'dd-mmm-yyyy HH:MM:SS.fff');
            %     eval(['datosegnale(' num2str(row) ',1).end_time = endtime;'])
            % Esporto segnale
            datocreato = [datocreato;datosegnale];
        end
        %% 2) Se ci sono buchi crea un vettore "edges" che permetta di separare i segnali dove ci sono i buchi
    else
        intervals = 1;
        for j = 1:length(I(ii).GapBlockIndex)
            intervals = [intervals I(ii).GapBlockIndex(j)];
            if j == length(I(ii).GapBlockIndex)
                intervals = [intervals I(ii).XBlockIndex(end)];
            end
        end
        edges = [];
        for k = 1:length(intervals)
            edges = [edges intervals(k)-1];
            edges = [edges intervals(k)];
        end
        edges(1) = [];
        edges(end-1) = [];
        Nedges = vec2mat((1:length(edges)),2);
        
        % Importo dati
        for i = 1:length(intervals)-1
            k = [I(ii).XBlockIndex(edges(Nedges(i,1)):edges(Nedges(i,2)))];
            name = [X(k(1)).StationIdentifierCode '_' X(k(1)).ChannelIdentifier '_'  datestr(X(k(1)).t(1),'ddmmmyyyyHHMM')];
            signal  = double([cat(1,X(k(:,1)).d)]);
            fs = X(k(1)).SampleRate;
            stn = X(k(1)).StationIdentifierCode;
            timeAx = cat(1,X(k(:,1)).t);
            %%% fine 2 %%%
            
            %%%%%%%%%%%    A: Riscrivo vettore temporale     %%%%%%%%%%%%%
            % E' necessario perchè ho notato che a volte il vettore
            % temporale scaricato dal miniseed manca di alcune ore. Questo
            % poi si traduce in errori quando viene effettuato il cut dei
            % segnali
            
            starttimevec=timeAx(1);
            endtimevec=timeAx(end);
            % da convertire in questo formato
            formatOut = 'yyyy-mm-dd HH:MM:SS.FFF';
            % Converti tempo iniziale nel formato necessario per usare datetime function
            startstring = datestr(starttimevec,'dd-mmm-yy HH:MM:SS.FFF');
            startstring = datestr(datenum(startstring,'dd-mmm-yy HH:MM:SS.FFF'),formatOut);
            % Converti tempo finale nel formato necessario per usare datetime function
            endstring = datestr(endtimevec,'dd-mmm-yy HH:MM:SS.FFF');
            endstring = datestr(datenum(endstring,'dd-mmm-yy HH:MM:SS.FFF'),formatOut);
            % Creo nuovo vettore temporale
            t1 = datetime(startstring,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');
            t2 = datetime(endstring,'InputFormat','yyyy-MM-dd HH:mm:ss.SSS');
            timeAx = t1:seconds(1/fs):t2;
            timeAx = datenum(timeAx)';
            %%%%%%%%%%%%%%      Fine sezione A   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %Creo struct segnale
            row = 1;
            eval(['datosegnale(' num2str(row) ',1).name = name;'])
            eval(['datosegnale(' num2str(row) ',1).fs = fs;'])
            if contains(X(k(1)).ChannelIdentifier, {'X', 'HEW','EHE'})
                eval(['datosegnale(' num2str(row) ',1).Comp = ' '''East''' ';'])
            elseif contains(X(k(1)).ChannelIdentifier, {'Y', 'HNS','EHN'})
                eval(['datosegnale(' num2str(row) ',1).Comp = ' '''North''' ';'])
            elseif contains(X(k(1)).ChannelIdentifier, {'Z','HNZ','EHZ'})
                eval(['datosegnale(' num2str(row) ',1).Comp = ' '''Vertical''' ';'])
            end
            eval(['datosegnale(' num2str(row) ',1).stn = stn;'])
            eval(['datosegnale(' num2str(row) ',1).signal = signal;'])
            eval(['datosegnale(' num2str(row) ',1).timeAx = timeAx;'])
            % se aggiungo anche l'ora di inzio e di fine poi creo confusione con il merge
            %         starttime = datestr(timeAx(1),'dd-mmm-yyyy HH:MM:SS.fff');
            %         eval(['datosegnale(' num2str(row) ',1).start_time = starttime;'])
            %         endtime = datestr(timeAx(end),'dd-mmm-yyyy HH:MM:SS.fff');
            %         eval(['datosegnale(' num2str(row) ',1).end_time = endtime;'])
            datocreato = [datocreato;datosegnale];
        end
    end
end



end