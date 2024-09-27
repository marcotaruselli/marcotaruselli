global crosscorr
global dataToSave

%% Seleziono dati piezometro per confronto
dataPiezo = dataToSave.dataPiezo;
dv_timeAx = dataToSave.dv_timeAx;
timeAxPiezo = dataToSave.timeAxPiezo;
dv_timeAx = dv_timeAx';
% [max(min(dv_timeAx),min(timeAxPiezo)) min(max(dv_timeAx),max(timeAxPiezo))]

%% Trova orari simili e ricampiona il dato piezometrico
[~,ind1] = min(abs(bsxfun(@minus,datenum(timeAxPiezo),datenum(dv_timeAx)')));
timeAxPiezo_prova = timeAxPiezo(ind1,:)
dataPiezo = dataPiezo(ind1,:);
