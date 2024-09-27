V.20201123 - Marco
-19/04/2012 corretto un baco nella funzione cross-correlazione
- aggiungo le MASW passive. I codici per i metodi tauP e phaseshift funzionano. Li ho controllati usando 
i codici che mi aveva passato Diego con i dati di CaLita (C:\Users\marco\OneDrive - Politecnico di Milano\Progetti\tau-p transform & MASW\Codici Arosio\Dati attivi Calita)
- NB non ha senso fare phaseShift-azimuth stack per le cross-correlazioni perchè non si hanno coordinate visto che le cross-corr sono calcolate usando due sensori
V.20201103 - Marco
-Aggiungo funzionalità per MASW (tau-p transform e phaseshift)
- Ho aggiunto la possibilità nal calcolo della cross-correlazione di escludere delle cross-correlazioni nella
stima del dV/V. Se vuoi tornare alla versione precedente copia tutti i file con prefisso
"CrossCorr_" dalla versione V. 20200509

V. 20200509 - Marco
- Sistemato un problema nell'analisi HVSR con smoothing. Corretto riga 109 del file PolHVRotate.
La riga 110 è stata commentata perché era quella che dava problemi.

V.20200509 - Marco
- il 14/10/2020 ho modificato una funzione del tool Propagation plot per fare in modo che si potesse fare il grafico solo per le coppie di sensori scelti
- Aggiungo possibilità di fare il filtro dinamico e quindi di calcolare Grafico a V
- sistemato nell'analisi di polarizzazione il fatto che quando si usava il metodo SVD i risultati venivano plottati
  sopra il plot del segnale.

V.20200508 - Marco
Aggiornamenti funzione WinCorr Dynamic:
- Aggiunto alla mainCrossFig opzione di cambiare tramite slidebar i plot del rettangolo della CorrWind e la curva dVV quando
  si utilizza l'opzione Dynamic.
- Aggiunto il calcolo e il plot del coefficente di correlazione tra dVV e piezoData con opzione dynamic. Ovviamente questo tool
  funziona solo se sono stati caricati dati piezometrici

V.20200505 - Marco
- Aggiunto la possibilità di fare il time-domain weighting nella cross-correlazione. Vedere libro ambient seismic noise p.153.
  Questa procedura si affianca al whitening e ho visto che migliora un pochino il risultato (differenze si vedono nel correlogramma).
  C'è la possibilità sia di applicare solo whitening, sia solo time-domain weightin che entrambi che nulla.
  Questo nuovo metodo aggiunto richiedere un high-pass filter del segnale (che ho impostato a 0.05Hz) per rimuovere eventuali trend presenti nel segnale.
	

V.20200417 - Marco
- Sistemato baco funzione loadsignals che creava problemi nel caso in cui il segnale avesse dei buchi (riga 27-28 funzione file_loadminiseed_function)
- Aggiunto funzione per allineare segnali
- Aggiunto delete button anche per signals for processing

V.20200414 - Marco
- modificato la funzione file_loadminiseed_function; ora è possibile caricare file miniseed contenenti
più di una componente. 
- aggiunto il pulsante delete for i raw data

V.20200409 - Marco
- Quando i segnali vengono deconvoluti con la rispsota del sensore il nome del segnale stesso verrà modificato 
  aggiungendo all'inizio "Dec_" questo è stato fatto per fare in modo che quando si fa l'analisi spettrale
  i grafici che si ottengono possano avere le unità di misura corrette. Se la rimozione della risposta del sensore
  non è stata fatta allora nelle unità di misura comparirà "Signal not deconvolved".

V.20200408 - Marco
- Modificato le funzioni per la rimozione della risposta del sensore in maniera tale che si possano deconvolvere
 più segnali alla volta e che si possa deconvolvere anche nel caso fosse solo disponibile la RESP del sensore
 e non del digitalizzatore (e viceversa) come ad esempio per il Raspberry shake.

V.20200401 - Marco
- La banda di affidabilità della curva HVSR non è più ottenuta facendo HV+/-std ma considerando l'intervallo
  di confidenza al 95%.

V.20200325 - Marco
- Inserimento HVSR analysis: Qui ho messo la possibilitià di fare lo smoothing triangolare,rettangolare e konnoohmachi. 
	Ho implementato solo Konnoohmachi per ora.

- In processing ho inserito il sotto-menu "passive interferometry" in cui è possibile fare: intra, cross-correlation
  e propagation plot.

- Inserimento analisi "propagation plot" che permette di valutare se c'è propagazione del campo d'onda tra tutte le coppie disponibili di
  sensori. NB la parte di intra-correlazione non è stata ancora implementata.


V.20200205
- Corretto baco su plora plot PolHVRotate e PolHRotate

V.20200131
- Unito correttamente le routine per l'analisi di polarizzazione al resto del codice (Arosio).

V.20200128 - Marco
- inserisco l'analisi dell'errore per il calcolo del dV/V utilizzando
la formula proposta da weaver nel 2011.
 
V.20200115 - Marco
- Ho implementato l'analisi spettrale che non era stata completata nella V. 20191101
- Nella main figure dell'analisi di cross-correlazione ho tolto il pulsante
update perchè ora l'aggiornamento del plot è automatico modifcando i valori
negli edit del plot setting. Il button update è stato rimosso ed è rimasto
solo il tasto reset.
- metto lo slider nel plotdynamic della finestra di correlazione così
da potersi spostare tra una finestra e un'altra della corrWin per calcolo dvv

V.20200107
- ho corretto il file update dvv perchè era un casino!
- qui inserisco la possibilità di impostare una Corr.window dinamica e che
quindi scorre da -maxlag a +maxlag (fissati dall'utente) creando un video del grafico dv/V che 
appunto cambia al muoversi della corr.window.

V.20191211
- qui provo ad inserire la parte in cui faccio l'allineamento dei segnali 
(esempio caso del Ventasso dove i RaspberryShake avevano preso il timing sbagliato)
. Ho deciso di non inserirla perchè non utile per ora


V.20191128
- Ho fatto un upgrade della funzione file_Loadsignals per fare in modo che quando si hanno
già dei segnali in signal for processing e carico un file .taru i segnali già presenti
non vengano eliminati.

- Ho aggiunto la funzione SortStruct che serve per ordinare in ordine alfabetico la variabile
data_processing ogni qualvolta si faccia qualche processo su di essa. Questo fa si
che ogni volta la tabella dei "signal for processing" sia sempre in ordine alfabetico/temporale

- Risolto il problema della presenza di buchi nei segnali. 

- Risolto problema col merge. Nella versione precedente si potevano mergiare solo selezionando
segnali con stessa Fs. Ora si può mergiare selezionando tutti i segnali (poco utile questa cosa ma è una comodità).

- Avendo risolto il problema sopra ora quando si tagliano i segnali non dovrebbero esserci
problemi e i segnali tagliati dovrebbero avere stessa ora di inizio e di fine. se questo non avviene è perchè 
i segnali non hanno ora comune di inizio/fine. In questo caso conviene sovraccampionare ad 
una frequenza che permetta di trovare un'ora comune in entrambi i segnali.

V. 20191101
-In questa versione di PassiveBarinda inserisco l'analisi spettrale ==> Non è ancora terminata

-ho aggiunto la funzioneSave_data. Per aggiungere i segnali nella lista delle variabili che si possono salvare
basta rendere <globale "dataToSave"> la variabile di interesse


