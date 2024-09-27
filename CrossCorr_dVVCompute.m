function CrossCorr_dVVCompute
global mainCrossFig
global data_selected
global crosscorr
global DynamicCorrWinUIFigure
global dataforPlotVideoCrossCorr
global dataToSave

%% Controllo iniziale
%1) Se "Dynamic" option è impostata sia come Filter Type che in Corr.window display Errore!
Listafiltri = get(findobj(mainCrossFig,'tag','filtertype_checkbox'),'String');
tipoFiltro = get(findobj(mainCrossFig,'tag','filtertype_checkbox'),'Value');
filtroselezionato = Listafiltri(tipoFiltro)
winCorrSelezionata = get(findobj(mainCrossFig,'tag','dvv_corrwindowValue'),'String')
    if strcmp(filtroselezionato,'Dynamic') && strcmp(winCorrSelezionata,'dynamic')
        beep
        sms=msgbox('dynamic option cannot be simultaneously selected in Filter type and in Corr.window!','Update','error');
        return
    end
    
%2) If plot piezometers has been selected check if the piezodata has been imported
choicePiezo = get(findobj(mainCrossFig,'tag','piezo_plotcheck'),'Value');
if choicePiezo == 1
    if evalin('base','~exist(''timeAxPiezo'')') == 1
        beep
        sms=msgbox('No piezometer data has been selected! Please select data in the "Import Piezo data" section!','Update','error');
        return
    end
end


%% Remove dvvplot if already exist
delete(findobj('tag','PlotVideoButton'));drawnow
delete(findobj(gcf,'type','axes','tag','drawnowdynamicCorrWinAxes'));drawnow
delete(findobj(gcf,'type','axes','tag','dvvPlot'));drawnow
delete(findobj(mainCrossFig,'tag','datiesclusi'));drawnow 
delete(findobj(mainCrossFig,'tag','datiesclusidvv'));drawnow 
delete(findobj('tag','settings_dvv'));drawnow
delete(findobj('tag','dVV_Xlimits'));drawnow
delete(findobj('tag','dVV_Xlimits_left'));drawnow
delete(findobj('tag','dVV_Xlimits_right'));drawnow
delete(findobj('tag','dVV_Ylimits'));drawnow
delete(findobj('tag','dVV_Ylimits_Value'));drawnow
delete(findobj('tag','water_Ylimits'));drawnow
delete(findobj('tag','water_Ylimits_Value'));drawnow
delete(findobj('tag','watertable_color'));drawnow
delete(findobj('tag','dvv_color'));drawnow
delete(findobj('tag','update_dvvPlot'));drawnow
delete(findobj('tag','reset_dvvPlot'));drawnow
delete(findobj('tag','Smoothing_text'));drawnow
delete(findobj('tag','Smoothing_type'));drawnow
delete(findobj('tag','Smoothing_window'));drawnow
delete(findobj('tag','PlotVideoButton'));drawnow
delete(findobj('tag','DynamicWinCorr_text'));drawnow
delete(findobj('tag','dynamicWinCorrSlider'));drawnow
delete(findobj('tag','dynamiCorrWinTitle'));drawnow
delete(findobj(mainCrossFig,'tag','TitleCC_dvvVSPiezo'));drawnow
delete(findobj(mainCrossFig,'tag','CCcolorBar'));drawnow
delete(findobj(mainCrossFig,'tag','axCC'));drawnow
delete(findobj(mainCrossFig,'tag','Ax_FreqBandAnalisys'));drawnow


% questi sono gli assi e i tasti dell'errorAnalysis
delete(findobj(gcf,'tag','Add_ErrorAnalysis_dvv'));drawnow
delete(findobj(gcf,'type','axes','tag','CrossCorrREF_Signalaxis'));drawnow
delete(findobj(gcf,'type','axes','tag','CrossCorrREF_Spectrumaxis'));drawnow
delete(findobj(gcf,'tag','timeWindow_ErrorField'));drawnow
delete(findobj(gcf,'tag','timeWindow_ErrorValue'));drawnow
delete(findobj(gcf,'tag','omegac_ErrorField'));drawnow
delete(findobj(gcf,'tag','omegac_ErrorValue'));drawnow
delete(findobj(gcf,'tag','Bandwidth_ErrorField'));drawnow
delete(findobj(gcf,'tag','Bandwidth_ErrorValue'));drawnow
delete(findobj(gcf,'tag','Compute_ErrorButton'));drawnow
delete(findobj(gcf,'tag','colorbarRMSError'));drawnow

% delete(findobj('tag','Timezone'));drawnow

%% Get input from other functions
correlations = crosscorr.correlations;
Fs = data_selected(1).fs; %serve nel caso si faccia filtro correlogramma
time_corr = crosscorr.time_corr;
dvv_corrwindowValue =  get(findobj(mainCrossFig,'tag','dvv_corrwindowValue'),'String');
dvv_corrfilterCheck = get(findobj(mainCrossFig,'tag','dvv_corrfilterCheck'),'Value');
dvv_EpsilonValue = get(findobj(mainCrossFig,'tag','dvv_EpsilonValue'),'String');
excludedata = get(findobj(mainCrossFig,'tag','exclude_correlogram'),'String');

% 1) correlogram time window selection ==> CREATION OF t matrix for dvv computation
% case 1: ==> AUTO
if strcmp(dvv_corrwindowValue,'auto') == 1
    t1 = time_corr(1);
    t2 = time_corr(end);
    t = [time_corr(1) time_corr(end)];
    
    % case 2: ==> Dynamic
elseif strcmp(dvv_corrwindowValue,'dynamic') == 1
    settingdVVparameters;
    choicedvvDynamic = crosscorr.choicedvvDynamic;
    
    if strcmp(choicedvvDynamic,'exitComputation') % Se si è cliccato su exit esci dal run di CrossCorr_dvvCompute
        return
    else
        % Get input parameters
        dynamicWindWidth = str2num(crosscorr.dynamicWindWidth);
        dynamicCorrelogramBoundaries = str2num(crosscorr.dynamicCorrelogramBoundaries);
        dynamicWinOverlap = crosscorr.dynamicWinOverlap;
        
        if strcmp(dynamicWinOverlap,'Overlap') % Se le finestre si devono sovrapporre
            t = [dynamicCorrelogramBoundaries(1) dynamicCorrelogramBoundaries(1)+dynamicWindWidth];
            i = 1;
            while unique(t(:,2)<dynamicCorrelogramBoundaries(1,2))
                i = i+1
                if i == 2
                    step = diff(t)/2;
                end
                t(i,:) = t(i-1,:)+step;
            end
            
        else %Se le finestre non si sovrappongono
            % Number of movingWindows
            correlogramInterval = abs(dynamicCorrelogramBoundaries(2)-dynamicCorrelogramBoundaries(1));
            N_movingWindows = floor(correlogramInterval/dynamicWindWidth);
            left = dynamicCorrelogramBoundaries(1);
            right = dynamicCorrelogramBoundaries(2);
            subIntervals = [left:dynamicWindWidth:right];
            t = [];
            for h = 1:N_movingWindows
                t(h,:) = [subIntervals(h) subIntervals(h+1)];
            end
        end
    end
    
    
    % case 3: ==> an interval has been selected
else
    timewin_correlogram = str2num(dvv_corrwindowValue);
    %     t1 = timewin_correlogram(1);
    %     t2 = timewin_correlogram(2);
    t = [timewin_correlogram(1) timewin_correlogram(2)];
end
crosscorr.t = t;
dataforPlotVideoCrossCorr.t = t;

%%%%%Caso 1 %%%% Se il filtro selezionato NON e' Dynamic %%%%%%%%%%%%%%%%%%
% 2) Filter the cross-correlations if dvv_corrfilterCheck is checked
% Se dinamico filtrala qui
if not(strcmp(filtroselezionato,'Dynamic'))
    if dvv_corrfilterCheck == 1
        RESU = crosscorr.correlations;
    else
        RESU = crosscorr.correlations_NOTFILTERED;
    end
    
% 3) Escludi alcune cross-correlazioni dal calcolo ==> questa opzione serve nel caso in cui ci fossero cross-correlazioni rumorose nel correlogramma   
if not(isempty(excludedata))
excludedata = str2num(excludedata);
rimuoviDA = excludedata(1);
rimuoviFINOA = excludedata(2);
timelength = str2num(get(findobj(mainCrossFig,'tag','timelength'),'string'));
escludiDA = round(rimuoviDA/timelength)
escludiFINOA = round(rimuoviFINOA/timelength);
% RImuovo dati dalla matrice delle cross-correlazioni
RESU(:,escludiDA:escludiFINOA) = [];
end

% 4) EPSILON
EPSILON = str2num(dvv_EpsilonValue);
%% dV/V Computation
dvvComputation(RESU,EPSILON,time_corr,t)
%% plot grafico per valutare correlazione tra dvv e dati piezometrici se caricati
dvv_corrwindowValue =  get(findobj(mainCrossFig,'tag','dvv_corrwindowValue'),'String')
if strcmp(dvv_corrwindowValue,'dynamic') == 1
plotCC_dvvVSPiezo_DynamicOption
end
%% Dati da salvare per plot moving correlogram window  (dynamic)
dataToSave.dataforPlotVideoCrossCorr = dataforPlotVideoCrossCorr;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%Caso 2 %%%% Se il filtro selezionato E' Dynamic %%%%%%%%%%%%%%%%%%
% Filter the cross-correlations 
% Se dinamico filtrala qui
if strcmp(filtroselezionato,'Dynamic')
    filterfreqDynamicCorrelogram = crosscorr.filterfreqDynamicCorrelogram;
    for i = 1:size(filterfreqDynamicCorrelogram,1)+1
    if i == 1
        % Parti usando il correlogramma nella broadband
        RESU = crosscorr.correlations; 
    else
        % Ora usa il correlogramma filtrato
        RESU   = bandpass(crosscorr.correlations_NOTFILTERED,filterfreqDynamicCorrelogram(i-1,:), Fs,'ImpulseResponse','iir','Steepness',0.95);
    end
% 3) EPSILON
EPSILON = str2num(dvv_EpsilonValue);

%% dV/V Computation
filterRange = i;
dvvComputationforDynamicFilter(RESU,EPSILON,time_corr,t,filterRange)

%Nascondi waitbar
    if i == filterRange(end)        
        % Nascondi waitBar
        wait = findobj(mainCrossFig,'tag','wait');
        handleToWaitBar = findobj(mainCrossFig,'tag','handleToWaitBar');
        set(wait,'visible','off')
        set(handleToWaitBar,'visible','off')
        p = get(handleToWaitBar,'Child');
        x = get(p,'XData');
        x(3:4) = 0;
        set(p,'XData',x);
        drawnow
    end
    
    % Plot risultato
    if i == size(filterfreqDynamicCorrelogram,1)+1
        plotFreqBandsAnalysis
    end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

function dvvComputation(RESU,EPSILON,time_corr,t)
global mainCrossFig
global data_selected
global crosscorr
global dataToSave
global dataforPlotVideoCrossCorr

%%    Waitbar   %%%%%
wait = findobj(mainCrossFig,'tag','wait');
handleToWaitBar = findobj(mainCrossFig,'tag','handleToWaitBar');
%%%%%%%%%%%%%%%%%%%%%%%%%


%% Computation of dV/V

lisse=31;
seuil=.0;
ultimaora=size(RESU,2); %SERVE PER DIRE FINO A CHE ORA HAI I DATI
dv=zeros(1,size(RESU,2));
dv_sg8_21=dv;



%smoothing%%%
% for l=1:size(RESU,1)
% RESUs(l,[1:size(RESU,2)])=sgolayfilt(RESU(l,[1:size(RESU,2)]),1,lisse);
% end
% RESU=RESUs; figure; imagesc(RESU');
% %pause

%normalization
for i=1:size(RESU,2)
    RESUn(:,i)=RESU(:,i)./max(abs(RESU(:,i)));
end


RESU=RESUn;
RESU(isnan(RESU))=0;

time=[-floor(size(RESU,1)/2):floor(size(RESU,1)/2)];

CC=zeros(length(EPSILON),size(RESU,2));

ref=nanmean(RESU(:,1:ultimaora),2);
% ref=nanmean(RESU(:,450:800),2);

for h = 1:size(t,1)
    
    % Finestra correlogramma usata per dvvComputation
    t1 = t(h,1);
    t2 = t(h,2);
    
    
    % CALCOLO TIME WINDOW
    %QUI GUARDO A CHE POSIZIONE CORRISPONDE t1 NEL CORRELOGRAMMA(-1000:1000)
    [c index]=min(abs(time_corr-t1));
    closestValue=time_corr(index);
    leftvalueoftimewindow=find(time_corr==closestValue);
    %QUI GUARDO A CHE POSIZIONE CORRISPONDE t2 NEL CORRELOGRAMMA(-1000:1000)
    [c index]=min(abs(time_corr-t2));
    closestValue=time_corr(index);
    rightvalueoftimewindow=find(time_corr==closestValue);
    %COSTRUISCO LA TIME WINDOW
    time_window=[leftvalueoftimewindow:rightvalueoftimewindow];
    %%MARCO: PROVO A FARE UN NUOVO VETTORE DI RIFERIMENTO!
    ref3=ref'; %MARCO
    %
    % % calcul du dV/V
    % %%%%%%
    %%CREO IL VETTORE RIFERIMENTO2 PER CAPIRE COME IL CODICE CALCOLA REF2
    riFsrimento2=[]; %MARCO
    coeffcorrel=[]; %MARCO
    time2matrix=[];
    for jj=1:length(EPSILON)
        %waitbar(jj/length(EPSILON),h)
        time2=(time).*(1+EPSILON(jj));
        time2matrix=[time2matrix; time2];
        ref2=interp1(time,ref,time2,'spline');%the interpolation of average cross correlations
        %riFsrimento2=[riFsrimento2; ref2]; %scritto da MARCO non serve a nulla
        for hour=1:size(RESU,2)
            temp=corrcoef(ref2(time_window),RESU(time_window,hour)); %calcolo il coefficente di correlazione solo per la finestra temporale selezionata
            CC(jj,hour)=temp(2);%the matrix of cross correlations coefficients for each interpolated av. xcorr and filtered av, xcorr            
        end
        
        %%%%%    Waitbar   %%%%%
        set(wait,'visible','on')
        set(handleToWaitBar,'visible','on')
        p = get(handleToWaitBar,'Child');
        x = get(p,'XData');
        x(3:4) = jj/length(EPSILON);
        set(p,'XData',x);
        drawnow
        %%%%%%%%%%%%%%%%%%%%%%%%%
        
    end %close(h)
    
    
    [cc b]=max(CC);
    %plot(find(cc>0.0),-sgolayfilt(EPSILON(b(find(cc>0.0)))*100,8,51))
    dv_complete(h,:)=EPSILON(b)*100;
    dv=EPSILON(b)*100;
    xt=find(cc>seuil);
    lisse=3;
    dv_sg8_21(h,:)=sgolayfilt(pchip(xt,EPSILON(b(find(cc>seuil)))*100,[1:size(RESU,2)]),1,lisse);
    
    
    %% Calcolo errore da formula Weaver 2011 ==> ATTENZIONE L'Ho spostato nella funzione CrossCorr_errorAnalysis
    correlationCoefficient = max(CC(:,:));
    %     % t1 Preso da sopra
    %     % t2 Preso da sopra
    %     T = 1/(20-1);
    %     Wc = (19/2);
    %     rmsteorico = (sqrt(1-X.^2)./(2*X)).* sqrt((6*sqrt(pi/2)*T)/(Wc^2*(t2^3-t1^3)));
    crosscorr.correlationCoefficient = correlationCoefficient;
        
    %%
    %DISATTIVATO IO RIGA SOTTO
    %plot([1:size(RESU,2)]/24,dv(t,:),'color',[.7,.7,.7]); axis([0 size(RESU,2)/24 EPSILON(1)*100 EPSILON(end)*100]);
    % plot([1:size(RESU,2)]/24,dv_sg8_21(t,:),'color',[.6,.6,.6]); axis([0 size(RESU,2)/24 EPSILON(1)*100 EPSILON(end)*100]);
    %
    % drawnow
    crosscorr.CC = CC; %è una prova per vedere se riesco a valutare l' affidabilità di epsilon in funzione del CC ad esso associato
    crosscorr.dv_complete = dv_complete;  %==> Questa serve nel caso in cui si usi la funzione "dynamic" in corr.Window
    crosscorr.dv = dv; %La rendo globale per fare il plot;  % nel caso "dynamic" questo dv/v fa riferimento a quello calcolato con l'ultima finestra dell corr.window
    dataforPlotVideoCrossCorr.dv_complete = dv_complete;
    
    % se filter Dynamic è selezionato crea un dvv per poi fare il grafico Fig.4 articolo Voison 2016
    Listafiltri = get(findobj(mainCrossFig,'tag','filtertype_checkbox'),'String');
tipoFiltro = get(findobj(mainCrossFig,'tag','filtertype_checkbox'),'Value');
filtroselezionato = Listafiltri(tipoFiltro);

if strcmp(filtroselezionato,'Dynamic')
    dv_filteredCorrelogram
crosscorr.dv_filteredCorrelogram = dv_filteredCorrelogram;
end
    % Smothing data
    % queste due righe servono solo per la sliderbar
    dv_smoothSlider = smoothdata(dv_complete,2,'movmean');
    dataforPlotVideoCrossCorr.dv_smoothSlider = dv_smoothSlider;
    
    %% Plot dV/V
    % Remove dvvplot if already exist
    delete(findobj('tag','PlotVideoButton'));drawnow
    delete(findobj(gcf,'type','axes','tag','drawnowdynamicCorrWinAxes'));drawnow
    delete(findobj(gcf,'type','axes','tag','dvvPlot'));drawnow
    delete(findobj('tag','settings_dvv'));drawnow
    delete(findobj('tag','dVV_Xlimits'));drawnow
    delete(findobj('tag','dVV_Xlimits_left'));drawnow
    delete(findobj('tag','dVV_Xlimits_right'));drawnow
    delete(findobj('tag','dVV_Ylimits'));drawnow
    delete(findobj('tag','dVV_Ylimits_Value'));drawnow
    delete(findobj('tag','water_Ylimits'));drawnow
    delete(findobj('tag','water_Ylimits_Value'));drawnow
    delete(findobj('tag','watertable_color'));drawnow
    delete(findobj('tag','dvv_color'));drawnow
    delete(findobj('tag','update_dvvPlot'));drawnow
    delete(findobj('tag','reset_dvvPlot'));drawnow
    delete(findobj('tag','Smoothing_text'));drawnow
    delete(findobj('tag','Smoothing_type'));drawnow
    delete(findobj('tag','Smoothing_window'));drawnow
    % delete(findobj('tag','Timezone'));drawnow
    % crosscorr.dv = dv; %La rendo globale per fare il plot;
    
    %% Plot
    % Fai il plot solo se non è stato selezionato un filtro dynamic
    Listafiltri = get(findobj(mainCrossFig,'tag','filtertype_checkbox'),'String');
    tipoFiltro = get(findobj(mainCrossFig,'tag','filtertype_checkbox'),'Value');
    filtroselezionato = Listafiltri(tipoFiltro)
    if not(strcmp(filtroselezionato,'Dynamic'))
        plotdvv(t1,t2) %t1,t2 servono solo per fare il titolo al plot dV/V
        set(findobj('Tag','Save dvv Plot'),'enable','on');
    
    %% CorrWindows ==> Plottare sopra il correlogramma il rettangolo che indica la corr.window
    axesCorrelogram = crosscorr.graficoCorrelogramma.Parent; % Riprendo l'axes del correlogramma
    XaxisLimCorrel = axesCorrelogram.XLim; % Leggo i limiti in X
    YaxisLimCorrel = axesCorrelogram.YLim; % Leggo i limiti in Y
    
    correlogramplot = findobj(gcf,'tag','Correlogram') % Richiamo la figura del correlogramma
    % Creo nuovo asse per rettangolo CorrWindow
    asseCorrWindow = axes('Position',[0.1800 0.2809 0.3350 0.6791],'XLim',XaxisLimCorrel,'Tag','drawnowdynamicCorrWinAxes')
    % Plotto il rettangolo
    rectangle(asseCorrWindow,'Position',[t1 YaxisLimCorrel(1) abs(-t2-(-t1)) 1],'EdgeColor','r','LineWidth',1.4,'LineStyle','-.')
    set(gca,'Visible','off')
    %% Se ho eliminato alcune cross-correlazioni disegno un rettangolo rosso sopra quella parte di dati
    excludedata = get(findobj(mainCrossFig,'tag','exclude_correlogram'),'String');
    if not(isempty(excludedata))
        excludedata = str2num(excludedata);
        rimuoviDA = excludedata(1);
        rimuoviFINOA = excludedata(2);
        timelength = str2num(get(findobj(mainCrossFig,'tag','timelength'),'string'));
        escludiDA = round(rimuoviDA/timelength);
        escludiFINOA = round(rimuoviFINOA/timelength);
        
        rectCnt = escludiDA;
        rectDelta = escludiFINOA-escludiDA;
        % Draw rectangle in upper axes
        rectY = [rectCnt rectCnt + rectDelta];
        rectX = axesCorrelogram.XLim;
        pch1 = patch(axesCorrelogram, rectX([1,2,2,1]), rectY([1 1 2 2]), 'r', ...
            'EdgeColor', 'none', 'FaceAlpha', 0.3,'tag','datiesclusi'); % FaceAlpha controls transparency
    end
    
    end
    
    %% Salva frame per fare il video
    % moviedVVframes(h) = getframe;
end

%% Calcolo corrcoeff tra dV/V e dato Piezometrico se è stato caricato
    choicePiezo = get(findobj(mainCrossFig,'tag','piezo_plotcheck'),'Value'); %Controlla se sono stati caricati dati piezometrici   
    if choicePiezo == 1 
        crosscorr.CCdvv_vs_Piezo = [];
        for k = 1:size(t,1)
        % Carica dati piezometrici e asse temporale dvv
        timeAxPiezo = evalin('base', 'timeAxPiezo');
        dataPiezo = evalin('base', 'dataPiezo');
        dv_timeAx = crosscorr.timeAx;
        dv_timeAx = dv_timeAx';
        % Trova stesso timeAx
        [~,ind1] = min(abs(bsxfun(@minus,datenum(timeAxPiezo),datenum(dv_timeAx)')));
        timeAxPiezoLimited = timeAxPiezo(ind1,:);
        dataPiezoLimited = dataPiezo(ind1,:);
        
        % 1) Escludi parti dei dati piezometrici se sono state scartate alcune cross-correlazioni
%         BlocksList = get(findobj(mainCrossFig,'tag','exclude_correlogram'),'String');
%         if not(isempty(BlocksList))
%             BlocksList = str2num(BlocksList);
%             rimuoviDA = BlocksList(1);
%             rimuoviFINOA = BlocksList(2);
%             timelength = str2num(get(findobj(mainCrossFig,'tag','timelength'),'string'));
%             escludiDA = round(rimuoviDA/timelength);
%             escludiFINOA = round(rimuoviFINOA/timelength);
%             % RImuovo dati dalla matrice delle cross-correlazioni
%             dataPiezoLimited(escludiDA:escludiFINOA) = [];
%         end

        % Calcola corr coeff
        CCdvv_vs_PiezoValue = corrcoef(dv_complete(k,:),dataPiezoLimited');
        CCdvv_vs_Piezo(k) = CCdvv_vs_PiezoValue(1,2);
        end
        crosscorr.CCdvv_vs_Piezo = CCdvv_vs_Piezo;
    end


    
%% Possibilità di fare l'analisi dell'errore di epsilon
CrossCorr_errorAnalysis

end

%%% Se è stato selezionato il filtro Dynamic usa questa funzione per fare il dV/V
function dvvComputationforDynamicFilter(RESU,EPSILON,time_corr,t,filterRange)
global mainCrossFig
global data_selected
global crosscorr
global dataToSave
global dataforPlotVideoCrossCorr

%%    Waitbar   %%%%%
wait = findobj(mainCrossFig,'tag','wait');
handleToWaitBar = findobj(mainCrossFig,'tag','handleToWaitBar');
%%%%%%%%%%%%%%%%%%%%%%%%%


%% Computation of dV/V

lisse=31;
seuil=.0;
ultimaora=size(RESU,2); %SERVE PER DIRE FINO A CHE ORA HAI I DATI
dv=zeros(1,size(RESU,2));
dv_sg8_21=dv;



%smoothing%%%
% for l=1:size(RESU,1)
% RESUs(l,[1:size(RESU,2)])=sgolayfilt(RESU(l,[1:size(RESU,2)]),1,lisse);
% end
% RESU=RESUs; figure; imagesc(RESU');
% %pause

%normalization
for i=1:size(RESU,2)
    RESUn(:,i)=RESU(:,i)./max(abs(RESU(:,i)));
end


RESU=RESUn;
RESU(isnan(RESU))=0;

time=[-floor(size(RESU,1)/2):floor(size(RESU,1)/2)];

CC=zeros(length(EPSILON),size(RESU,2));

ref=nanmean(RESU(:,1:ultimaora),2);
% ref=nanmean(RESU(:,450:800),2);

for h = 1:size(t,1)
    
    % Finestra correlogramma usata per dvvComputation
    t1 = t(h,1);
    t2 = t(h,2);
    
    
    % CALCOLO TIME WINDOW
    %QUI GUARDO A CHE POSIZIONE CORRISPONDE t1 NEL CORRELOGRAMMA(-1000:1000)
    [c index]=min(abs(time_corr-t1));
    closestValue=time_corr(index);
    leftvalueoftimewindow=find(time_corr==closestValue);
    %QUI GUARDO A CHE POSIZIONE CORRISPONDE t2 NEL CORRELOGRAMMA(-1000:1000)
    [c index]=min(abs(time_corr-t2));
    closestValue=time_corr(index);
    rightvalueoftimewindow=find(time_corr==closestValue);
    %COSTRUISCO LA TIME WINDOW
    time_window=[leftvalueoftimewindow:rightvalueoftimewindow];
    %%MARCO: PROVO A FARE UN NUOVO VETTORE DI RIFERIMENTO!
    ref3=ref'; %MARCO
    %
    % % calcul du dV/V
    % %%%%%%
    %%CREO IL VETTORE RIFERIMENTO2 PER CAPIRE COME IL CODICE CALCOLA REF2
    riFsrimento2=[]; %MARCO
    coeffcorrel=[]; %MARCO
    time2matrix=[];
    for jj=1:length(EPSILON)
        %waitbar(jj/length(EPSILON),h)
        time2=(time).*(1+EPSILON(jj));
        time2matrix=[time2matrix; time2];
        ref2=interp1(time,ref,time2,'spline');%the interpolation of average cross correlations
        %riFsrimento2=[riFsrimento2; ref2]; %scritto da MARCO non serve a nulla
        for hour=1:size(RESU,2)
            temp=corrcoef(ref2(time_window),RESU(time_window,hour)); %calcolo il coefficente di correlazione solo per la finestra temporale selezionata
            CC(jj,hour)=temp(2);%the matrix of cross correlations coefficients for each interpolated av. xcorr and filtered av, xcorr
            
        end
        
        %%%%%    Waitbar   %%%%%
        set(wait,'visible','on')
        set(handleToWaitBar,'visible','on')
        p = get(handleToWaitBar,'Child');
        x = get(p,'XData');
        x(3:4) = jj/length(EPSILON);
        set(p,'XData',x);
        drawnow
        %%%%%%%%%%%%%%%%%%%%%%%%%
        
    end %close(h)
    
    
    [cc b]=max(CC);
    %plot(find(cc>0.0),-sgolayfilt(EPSILON(b(find(cc>0.0)))*100,8,51))
    dv_complete(h,:)=EPSILON(b)*100;
    dv=EPSILON(b)*100;
    xt=find(cc>seuil);
    lisse=3;
    dv_sg8_21(h,:)=sgolayfilt(pchip(xt,EPSILON(b(find(cc>seuil)))*100,[1:size(RESU,2)]),1,lisse);
    
    
 
    %plot([1:size(RESU,2)]/24,dv(t,:),'color',[.7,.7,.7]); axis([0 size(RESU,2)/24 EPSILON(1)*100 EPSILON(end)*100]);
    % plot([1:size(RESU,2)]/24,dv_sg8_21(t,:),'color',[.6,.6,.6]); axis([0 size(RESU,2)/24 EPSILON(1)*100 EPSILON(end)*100]);
    %
    % drawnow
    crosscorr.CC = CC; %è una prova per vedere se riesco a valutare l' affidabilità di epsilon in funzione del CC ad esso associato
    crosscorr.dv_complete = dv_complete;  %==> Questa serve nel caso in cui si usi la funzione "dynamic" in corr.Window
    crosscorr.dv = dv; %La rendo globale per fare il plot;  % nel caso "dynamic" questo dv/v fa riferimento a quello calcolato con l'ultima finestra dell corr.window
    dataforPlotVideoCrossCorr.dv_complete = dv_complete;
    
    % Salvo dVV se filter Dynamic è selezionato crea un dvv per poi fare il grafico Fig.4 articolo Voison 2016
    Listafiltri = get(findobj(mainCrossFig,'tag','filtertype_checkbox'),'String');
    tipoFiltro = get(findobj(mainCrossFig,'tag','filtertype_checkbox'),'Value');
    filtroselezionato = Listafiltri(tipoFiltro);   
    if strcmp(filtroselezionato,'Dynamic')
        if filterRange == 1
        dv_filteredCorrelogram(filterRange,:) = dv;
        crosscorr.dv_filteredCorrelogram = dv_filteredCorrelogram;
        else
        dv_filteredCorrelogram = crosscorr.dv_filteredCorrelogram;
        dv_filteredCorrelogram(filterRange,:) = dv;
        crosscorr.dv_filteredCorrelogram = dv_filteredCorrelogram;
        end
    end
    
    
    % Smothing data
    % queste due righe servono solo per la sliderbar
    dv_smoothSlider = smoothdata(dv_complete,2,'movmean');
    dataforPlotVideoCrossCorr.dv_smoothSlider = dv_smoothSlider; 
      
end



end


%%%%%%%%%%%% Getting parameters for Dynamic Corr. window computation of dV/V %%%%%%%%%%%
function settingdVVparameters
global DynamicCorrWinUIFigure
global crosscorr

%% Crea finestra richiesta dati per calcolare il dV/V per diversi finestre del correlogramma

% a) Crea figure
DynamicCorrWinUIFigure = figure('numbertitle','off','Name','Dynamic Corr. window parameters','toolbar','none','menubar','none','Position', [600 450 355 187]);

% b) Create WindowWidthFieldLabel
WindowWidthEditFieldLabel = uicontrol(DynamicCorrWinUIFigure,'Style','text','Position',[50 146 150 22],'HorizontalAlignment','left',...
    'FontSize',9,'String','Corr. window width [s] ');

% c) Create WindowWidthEditField
WindowWidthEditField = uicontrol(DynamicCorrWinUIFigure,'Style','edit','Position',[200 148 92 22],'TooltipString',...
    'If you set eg. 1 the time window widht will be 1 second','Tag','dynamicWindWidth');


% d) Create CorrLimitsEditFieldLabel
CorrLimitsFieldLabel = uicontrol(DynamicCorrWinUIFigure,'Style','text','Position',[50 110 150 22],'HorizontalAlignment','left',...
    'FontSize',9,'String','Limits of the correlogram');

% e) Create CorrLimitsEditField
CorrLimitsEditField = uicontrol(DynamicCorrWinUIFigure,'Style','edit','Position',[200 112 92 22],'TooltipString',...
    'You must set the boundaries of the correlogram within which the corr.window will move','Tag','dynamicCorrelogramBoundaries');

% f) Create Windows overlap selection
WinOverlapFieldLabel = uicontrol(DynamicCorrWinUIFigure,'Style','text','Position',[50 80 150 22],'HorizontalAlignment','left',...
    'FontSize',9,'String','50% Overlap');

% g) Create Windows overlap selection
WinOverlapCheckbox = uicontrol(DynamicCorrWinUIFigure,'Style','checkbox','Position',[200 80 150 22],'HorizontalAlignment','left',...
    'FontSize',9,'Value',1,'Tooltip',['If selected the corr.windows will be overlapped each other.' 10 ...
    'i.e. corr.win = 1s; limits = 0,5; then the used corr wind will be: 0,1 0.5,1.5 1,2 and so on'],...
    'Tag','dynamicWinOverlap');

% h)Create ProceedButton
ProceedButton = uicontrol(DynamicCorrWinUIFigure, 'Style','pushbutton','String','Proceed','Position',[200 45 91 22],...
    'Callback', @(hObject, eventdata) selectedButton(hObject, eventdata),'Tag','proceedComputation');

% i)Create ExitButton
ExitButton = uicontrol(DynamicCorrWinUIFigure, 'Style','pushbutton','String','Exit','ForegroundColor','r','Position',[100 45 91 22],...
    'TooltipString','If you exit you run out the computation of the dV/V',...
    'Callback', @(hObject, eventdata) selectedButton(hObject, eventdata),'Tag','exitComputation');

% l) Create TextArea
TextArea = uicontrol(DynamicCorrWinUIFigure,'Style','text','FontSize',6.8,'HorizontalAlignment','left','FontAngle','italic','Position',[10 5 331 28],...
    'String',{'Help: Using the "dynamic" cross. window the software will compute the dV/V by sliding a corr.window along the x-axis of the correlogram'});

uiwait(gcf)
end
function selectedButton(hObject, eventdata)
global crosscorr
global DynamicCorrWinUIFigure
%% 1) Get input parameters
% a) Larghezza in secondi della finestra da far scorrere
dynamicWindWidth = get(findobj(DynamicCorrWinUIFigure,'tag','dynamicWindWidth'),'String');
crosscorr.dynamicWindWidth = dynamicWindWidth;

% b) Limiti del correlogramma
dynamicCorrelogramBoundaries = get(findobj(DynamicCorrWinUIFigure,'tag','dynamicCorrelogramBoundaries'),'String');
crosscorr.dynamicCorrelogramBoundaries = dynamicCorrelogramBoundaries;

% c) Windows Overlap
dynamicWinOverlap = get(findobj(DynamicCorrWinUIFigure,'tag','dynamicWinOverlap'),'value');
if dynamicWinOverlap == 1
    dynamicWinOverlap = 'Overlap'
else
    dynamicWinOverlap = 'NoOverlap'
end
crosscorr.dynamicWinOverlap = dynamicWinOverlap;
%% 2) Get pushed button
exitButton = get(findobj(DynamicCorrWinUIFigure,'tag','exitComputation'),'Value');
proceedButton = get(findobj(DynamicCorrWinUIFigure,'tag','proceedComputation'),'Value');

if exitButton == 1
    choicedvvDynamic = 'exitComputation';
elseif proceedButton ==1
    choicedvvDynamic = 'proceedComputation';
end
crosscorr.choicedvvDynamic = choicedvvDynamic;

% chiudi la finestra del settagio dei parametri
close(DynamicCorrWinUIFigure)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function resetdVV(btn)
global crosscorr
global mainCrossFig
global dataforPlotVideoCrossCorr
% Elimino parte relativa al calcolo dell'errore
delete(findobj(gcf,'tag','Add_ErrorAnalysis_dvv'));drawnow
delete(findobj(mainCrossFig,'tag','datiesclusidvv'));drawnow 
delete(findobj(gcf,'type','axes','tag','CrossCorrREF_Signalaxis'));drawnow
delete(findobj(gcf,'type','axes','tag','CrossCorrREF_Spectrumaxis'));drawnow
delete(findobj(gcf,'tag','timeWindow_ErrorField'));drawnow
delete(findobj(gcf,'tag','timeWindow_ErrorValue'));drawnow
delete(findobj(gcf,'tag','omegac_ErrorField'));drawnow
delete(findobj(gcf,'tag','omegac_ErrorValue'));drawnow
delete(findobj(gcf,'tag','Bandwidth_ErrorField'));drawnow
delete(findobj(gcf,'tag','Bandwidth_ErrorValue'));drawnow
delete(findobj(gcf,'tag','Compute_ErrorButton'));drawnow
delete(findobj(mainCrossFig,'type','axes','tag','drawnowdynamicCorrWinAxes'));

dv = crosscorr.dv;
delete(findobj(gcf,'type','axes','tag','dvvPlot'));drawnow

t = dataforPlotVideoCrossCorr.t; % Serve solo per riselezionare i dati della Finestra correlogramma usata per dvvComputation
if size(t,1) == 1
    t1 = t(1);
    t2 = t(2);
else
    t1 = t(end,1);
    t2 = t(end,2);
end
plotdvv(t1,t2)


%% CorrWindows ==> Plottare sopra il correlogramma il rettangolo che indica la corr.window
axesCorrelogram = crosscorr.graficoCorrelogramma.Parent; % Riprendo l'axes del correlogramma
XaxisLimCorrel = axesCorrelogram.XLim; % Leggo i limiti in X
YaxisLimCorrel = axesCorrelogram.YLim; % Leggo i limiti in Y

correlogramplot = findobj(gcf,'tag','Correlogram') % Richiamo la figura del correlogramma
% Creo nuovo asse per rettangolo CorrWindow
asseCorrWindow = axes('Position',[0.1800 0.2809 0.3350 0.6791],'XLim',XaxisLimCorrel,'Tag','drawnowdynamicCorrWinAxes')
% Plotto il rettangolo
rectangle(asseCorrWindow,'Position',[t1 YaxisLimCorrel(1) abs(-t2-(-t1)) 1],'EdgeColor','r','LineWidth',1.4,'LineStyle','-.')
set(gca,'Visible','off')

%% Possibilità di fare l'analisi dell'errore di epsilon
CrossCorr_errorAnalysis
end

function plotdvv(t1,t2)
global crosscorr
global mainCrossFig
global data_selected
global dataToSave
global dataforPlotVideoCrossCorr
global rettangoloEscludidati

% Elimino variabili che potrebbero già esistere e che conterrebbero due
% valori se non fossero cancellate
delete(findobj('tag','Smoothing_type'));drawnow
delete(findobj('tag','Smoothing_window'));drawnow
delete(findobj('tag','PlotVideoButton'));drawnow
delete(findobj('tag','DynamicWinCorr_text'));drawnow
delete(findobj('tag','dynamicWinCorrSlider'));drawnow
delete(findobj('tag','dynamiCorrWinTitle'));drawnow

%% Plot title
dv = crosscorr.dv;
dataToSave.dv = dv; %Dato da salvare
dvvtitle = crosscorr.TITOLOCORRELOGRAMMA;
dvv_corrwindowValue =  get(findobj(mainCrossFig,'tag','dvv_corrwindowValue'),'String');
dvvtitle = [dvvtitle '| correlogramWindow [' num2str(t1) ';' num2str(t2) ']'];
dataforPlotVideoCrossCorr.dvvtitle = dvvtitle;
%% Resampling asse temporale per plot
%%% con queste 4 righe funzionava il codice vecchio in cui l'ora associata
%%% al dV/V era quella dell'inizio della finestra temporale considerata
% timevector = data_selected(1).timeAx;
% startTime = timevector(1);
% endTime = timevector(end);
% timeAx = linspace(startTime,endTime,length(dv));

%%% nuovo codice il tempo per il calcolo del dVV è la mezzeria della
%%% finestra temporale considerata
timevector = data_selected(1).timeAx;
timeAx = datetime(timevector,'ConvertFrom','datenum');
startTime = timeAx(1);
endTime = timeAx(end);
timelength = str2num(get(findobj(mainCrossFig,'tag','timelength'),'string'));
timeAx = startTime+minutes(timelength/2):minutes(timelength):endTime-minutes(timelength/2); %considero la mezzeria del timelength usato
%%%

% Conversione timeAx to UTC time
TimezoneSurvey = get(findobj(mainCrossFig,'tag','Timezone'),'String');
dataforPlotVideoCrossCorr.TimezoneSurvey = TimezoneSurvey;
% timeAx = datetime(timevector,'ConvertFrom','datenum');
timeAx = datetime(timeAx,'TimeZone','UTC');
timeAx.TimeZone = TimezoneSurvey;
timeAx.Format = 'dd/MM/yyyy HH:mm:ss';


% 1) Escludi parti del dato se sono state scartate alcune cross-correlazioni 
BlocksList = get(findobj(mainCrossFig,'tag','exclude_correlogram'),'String');
if not(isempty(BlocksList))
BlocksList = str2num(BlocksList);
rimuoviDA = BlocksList(1);
rimuoviFINOA = BlocksList(2);
timelength = str2num(get(findobj(mainCrossFig,'tag','timelength'),'string'));
escludiDA = round(rimuoviDA/timelength);
escludiFINOA = round(rimuoviFINOA/timelength);
% RImuovo dati dalla matrice delle cross-correlazioni
rectX = [timeAx(:,escludiDA) timeAx(:,escludiFINOA) timeAx(:,escludiFINOA) timeAx(:,escludiDA)];
rettangoloEscludidati.rectX = rectX;
timeAx(:,escludiDA:escludiFINOA) = [];
end
crosscorr.timeAx = timeAx;
dv_timeAx = timeAx;
dataToSave.dv_timeAx = dv_timeAx;
dataforPlotVideoCrossCorr.dv_timeAx = dv_timeAx;

%% Plot dV/V senza Smoothing
ax_dvv = axes('Position',[0.55 0.7 0.42 0.26]);
crosscorr.ax_dvv = ax_dvv;
yyaxis(ax_dvv, 'left');
dvplot = plot(ax_dvv,timeAx,dv,'Color',[160/255 160/255 160/255],'LineStyle','-.','Tag','line_dV_Plot');
crosscorr.dvplot = dvplot;
set(gca,'Tag','dvvPlot')
% Proprietà asse Y sinistro
ylabel('dV/V %','Units', 'Normalized', 'Position', [-0.025, 0.5, 0]);
ax_dvv.YAxis(1).Color = [64/255 64/255 64/255]; %Colore asse Y sinistro
crosscorr.ylim_dvv = ax_dvv.YAxis(1).Limits;


% Proprietà asse Y destro
% Se non esistono piezometri cancella Yticklabel
choicePiezo = get(findobj(mainCrossFig,'tag','piezo_plotcheck'),'Value');
if choicePiezo == 0
    ax_dvv.YAxis(2).Color = [64/255 64/255 64/255];
    ax_dvv.YAxis(2).TickValues = [];  %disattiva secondo asse y
end
crosscorr.ylim_groundwater = ax_dvv.YAxis(2).Limits;
% ax_dvv.YAxis(2).Visible = 'off';

% Proprietà asse X
xlabel('Time')
title(dvvtitle,'FontSize',9,'FontName','garamond')
grid on; grid minor
legend('dV/V','Location','southeast')
datetickzoom
% dragzoom();

%% Plot dV/V con Smoothing
dvv_smoothingValue = get(findobj(mainCrossFig,'tag','dvv_smoothingValue'),'Value');
if dvv_smoothingValue == 1
    [dv_smooth,smoothdefaultWind] = smoothdata(dv,'movmean');
    dataToSave.dv_smooth = dv_smooth; %Dato da salvare
    crosscorr.dv_smooth = dv_smooth;
    crosscorr.smoothdefaultWind = smoothdefaultWind;
    
    hold on
    dvsmoothplot = plot(ax_dvv,timeAx,dv_smooth,'Color',[96/255 96/255 96/255],'LineStyle','-','Tag','line_dVSmoothed_Plot')
    crosscorr.dvsmoothplot = dvsmoothplot;
    legend('dV/V','dV/V Smoothed','Location','southeast')
end

%% Plot Piezo data if selected
if choicePiezo == 1
    timeAxPiezo = evalin('base', 'timeAxPiezo');
    dataPiezo = evalin('base', 'dataPiezo');
    timeAxPiezo.TimeZone = TimezoneSurvey;
    dataToSave.dataPiezo = dataPiezo; % Dato da salvare
    dataToSave.timeAxPiezo = timeAxPiezo; % Dato da salvare
    dataforPlotVideoCrossCorr.dataPiezo = dataPiezo; % Dato per plot video
    dataforPlotVideoCrossCorr.timeAxPiezo = timeAxPiezo; % Dato per plot video
    yyaxis(ax_dvv, 'right');
    dv_watertableplot = plot(timeAxPiezo,dataPiezo,'b');
    crosscorr.dv_watertableplot = dv_watertableplot;
    yticksPiezo = linspace(ceil(min(dataPiezo)),ceil(max(dataPiezo)),10);
    crosscorr.ylimPiezo = yticks;
    timeAx.Format = 'dd/MM/yyyy HH:mm:ss';
%     timeAxPiezo.Format = 'dd/MM/yyyy HH:mm:ss';   
    leftLim = max(min(timeAx),min(timeAxPiezo));
    leftLim.Format = 'dd/MM/yyyy HH:mm:ss';   
    rightLim = min(max(timeAx),max(timeAxPiezo));
%     rightLim.Format = 'dd/MM/yyyy HH:mm:ss';       
    xlim([max(min(timeAx),min(timeAxPiezo)) min(max(timeAx),max(timeAxPiezo))]);
    datetick('x','HH:MM')
    % Prorpietà asse destro
    ax_dvv.YAxis(2).Color = 'b';
    ylabel('Water table [m]','Units', 'Normalized', 'Position', [1.04 0.5, 0]);
    legend('dV/V','dV/V Smoothed','Piezometer data','Location','southeast')
end

% Set xlim
timeAx.Format = 'dd-MM-yyyy HH:mm:ss';
startime = timeAx(1);
endtime = timeAx(end);
dvvfigure = findobj(gcf,'tag','dvvPlot');
TimezoneSurvey = get(findobj(mainCrossFig,'tag','Timezone'),'String');
dvvfigure.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);

%% Se sono stati escludi dati dal correlogramma disegna un rettangolo rosso
rettangoloEscludidati.timeAx = timeAx;
rettangoloEscludidati.ax_dvv = ax_dvv;
rettangoloRossoescludiDati % Funzione per plottare rettangolo sopra i dati esclusi dal calcolo dV/V

%% Aggiunta pulsanti per modificare il plot
% Settings grafici
dvvplotsettings(timeAx);
% Settings smoothing
if dvv_smoothingValue == 1
    dvvSmoothingOptions
end


%% Message dv/v computation completed
% Display che il load è avvenuto
beep on; beep
sms=msgbox('dV/V has been computed!','Update','warn');
pause(1)
close(sms)
%%%%%    Waitbar   %%%%%
wait = findobj(mainCrossFig,'tag','wait');
handleToWaitBar = findobj(mainCrossFig,'tag','handleToWaitBar');
set(wait,'visible','off')
set(handleToWaitBar,'visible','off')
p = get(handleToWaitBar,'Child');
x = get(p,'XData');
x(3:4) = 0;
set(p,'XData',x);
drawnow
end

function rettangoloRossoescludiDati % Serve per plottare rettangolo rosso sopra plot dV/V se sono state scartare cross-corr nel calcolo del dV/V
global mainCrossFig
global rettangoloEscludidati
timeAx = rettangoloEscludidati.timeAx;
ax_dvv = rettangoloEscludidati.ax_dvv;
if isfield(rettangoloEscludidati,'rectX')
rectX = rettangoloEscludidati.rectX;
end

startime = timeAx(1);
endtime = timeAx(end);
excludedata = get(findobj(mainCrossFig,'tag','exclude_correlogram'),'String');
if not(isempty(excludedata))
ax_dvv_datiEsclusi = axes('Position',[0.55 0.7 0.42 0.26]);
TimezoneSurvey = get(findobj(mainCrossFig,'tag','Timezone'),'String');
dvvfigure.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);
rectY = ax_dvv.YAxis(1).Limits;
rectY = [rectY(1) rectY(1) rectY(2) rectY(2)];
fill(rectX,rectY, 'r', ...
    'EdgeColor', 'none', 'FaceAlpha', 0.3,'tag','datiesclusidvv'); % FaceAlpha controls transparency
TimezoneSurvey = get(findobj(mainCrossFig,'tag','Timezone'),'String');
ax_dvv_datiEsclusi.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);
set(gca,'Visible','off')
end
end

function plotCC_dvvVSPiezo_DynamicOption
global crosscorr
global mainCrossFig

% dvv_corrwindowValue =  get(findobj(mainCrossFig,'tag','dvv_corrwindowValue'),'String')
% if strcmp(dvv_corrwindowValue,'dynamic') == 1

CCdvv_vs_Piezo = crosscorr.CCdvv_vs_Piezo
t = crosscorr.t;
CorrWinCentered = mean(t,2);

%% Disegno asse su mainfig
% Titlo
uicontrol('style','text','units','normalized','position',[.175 .059 .14 .03],...
    'string','CC between dVV & Piezometer:','horizontalalignment','center',...
    'fontunits','normalized','fontsize',.6,'Tag','TitleCC_dvvVSPiezo',...
    'Tooltip',['This plot tells you which is the correlation between the dV/V and the piazometer curves' 10 ...
    'for each correlogram time windows selected by dynamic option in corr.Win tab']);

axCC = axes(mainCrossFig,'Position',[0.18 0.03 0.335 0.03]);
imagesc(CorrWinCentered,ones(1,length(CorrWinCentered)),CCdvv_vs_Piezo)
% axCC.YLim = [-1, 1];
correlogramLimits = findobj(mainCrossFig,'tag','Correlogram');
axCC.XLim = correlogramLimits.XLim;
axCC.YTickLabel = [];
set(gca,'tag','axCC');

b = colorbar('units','normalized','location','south','Position',[0.465 0.065 0.05 0.02],'Tag','CCcolorBar'  )
b.Limits = [-1 1];
b.Label.String = 'CC';
b.Label.Position = [-1.3 0.15 0];
b.Label.FontWeight = 'bold'
 
% end

end

function plotFreqBandsAnalysis
global mainCrossFig
global crosscorr
delete(findobj(mainCrossFig,'tag','Ax_FreqBandAnalisys'));drawnow

% Creazione asse su cui fare il plot
ax_FrequencyBands = axes('Position',[0.56 0.55 0.42 0.41],'XGrid','on','XMinorGrid','on','YGrid','on','YMinorGrid','on',...
    'Tag','Ax_FreqBandAnalisys');

% Richiamo dati necessari per il plot
dv_filteredCorrelogram = crosscorr.dv_filteredCorrelogram;
dynamicBroadband = crosscorr.dynamicBroadband;
filterfreqDynamicCorrelogram = crosscorr.filterfreqDynamicCorrelogram;
coppieFrequenze = [str2num(dynamicBroadband); filterfreqDynamicCorrelogram];
coppieFrequenze = num2str(coppieFrequenze);

% Dati asse x
correlations = crosscorr.correlations;
xAxisPlot = -size(correlations,2)+1:size(correlations,2)-1;

% Calcolo autocorrelazion broadband
AutoCorrBroadband = xcorr(dv_filteredCorrelogram(1,:),'normalized');
% Plot autocorrelation
plot(xAxisPlot,AutoCorrBroadband,'b','LineWidth',5)
hold on

% Calcolo cross-correlazione per diverse bande in frequenza e plot
for i = 1:size(dv_filteredCorrelogram,1)-1
CrossCorrFreqRange = xcorr(dv_filteredCorrelogram(1,:),dv_filteredCorrelogram(i+1,:),'normalized');
% Calcolo coefficenti correlazione per colorare le linee
coefficenti = zeros(size(dv_filteredCorrelogram,1)-1,1);
% Colora le linee in base ai coefficenti di correlazione
if i == 1
coefficenti(i) = corrcoef(dv_filteredCorrelogram(1,:));
else
cc = corrcoef(dv_filteredCorrelogram(1,:),dv_filteredCorrelogram(i+1,:));
coefficenti(i) = cc(1,2);
end

% Plot con diversi markers per ogni linea
typemarkers = {'o';'+';'*';'.';'x';'square';'diamond';'^';'v';'>';'<';'pentagram';'hexagram';'o';'+';'*';'.';'x';'square';'diamond';'^';'v';'>';'<';'pentagram';'hexagram';'o';'+';'*';'.';'x';'square';'diamond';'^';'v';'>';'<';'pentagram';'hexagram'}; %fatto una lista lunga perché magari un domani avrò tanti dati
h = plot(xAxisPlot,CrossCorrFreqRange);
if coefficenti(i)>0 && coefficenti(i)<0.6  || coefficenti(i)>-0.6 && coefficenti(i)<0
    h.Color = [0.7 0.7 0.7];
    h.Marker = typemarkers{i};
    h.MarkerSize = 3;
    h.MarkerFaceColor = [0.7 0.7 0.7];
elseif coefficenti(i)>0.6
    h.Color = 'g';
    h.Marker = typemarkers{i};
    h.MarkerSize = 3;
    h.MarkerFaceColor = 'g';
elseif coefficenti(i)<-0.6
    h.Color = 'r';
    h.Marker = typemarkers{i};
    h.MarkerSize = 3;
    h.MarkerFaceColor = 'r';
end



end
l = legend(coppieFrequenze);
l.FontSize = 8;
l.Location = 'SouthEast';
title(l,'Frequency bands','FontSize',9,'FontName','garamond');
ax_FrequencyBands.XGrid = 'on';
ax_FrequencyBands.YGrid = 'on';
ax_FrequencyBands.XMinorGrid = 'on';
ax_FrequencyBands.YMinorGrid = 'on';
ax_FrequencyBands.YLim = [-1.1,1.1];
title('Frequency Bands','FontSize',10,'FontName','garamond');
xlabel('Minutes');
% Sistemo xtick
timelength = str2double(get(findobj(mainCrossFig,'tag','timelength'),'string'));
XticksPlot = ax_FrequencyBands.XTick;
xticklabels({timelength*XticksPlot}); %Ytick in minuti

% RiTagga asse
set(gca,'tag','Ax_FreqBandAnalisys')
end

function dvvplotsettings(timeAx)
global mainCrossFig
global data_selected
global crosscorr

uicontrol('style','text','units','normalized','position',[0.546 0.62 .06 .03],...
    'string','Plot settings','horizontalalignment','center','fontunits','normalized','fontsize',.6,...
    'Tag','settings_dvv');

% Xlimits
uicontrol('style','text','units','normalized','position',[.55 .59 .05 .03],...
    'string','Xlimits','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','dVV_Xlimits');
uicontrol('style','edit','units','normalized','position',[.60 .59 .08 .03],'backgroundcolor',[1 1 1],...
    'String',[datestr(timeAx(1))],'horizontalalignment','center','Callback',@(numfld,event) updatedVV,...
    'fontunits','normalized','fontsize',.5,'tooltipstring','Start time limit','Tag','dVV_Xlimits_left');
uicontrol('style','edit','units','normalized','position',[.685 .59 .08 .03],'backgroundcolor',[1 1 1],...
    'String',[datestr(timeAx(end))],'horizontalalignment','center','Callback',@(numfld,event) updatedVV,...
    'fontunits','normalized','fontsize',.5,'tooltipstring','End time limit','Tag','dVV_Xlimits_right');

% dVV Ylimits
uicontrol('style','text','units','normalized','position',[.55 .558 .05 .03],...
    'string','dV/V Ylimits','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.8 .8 .8],'Tag','dVV_Ylimits');
uicontrol('style','edit','units','normalized','position',[.60 .558 .08 .03],'backgroundcolor',[1 1 1],...
    'horizontalalignment','center','String',[num2str(crosscorr.ylim_dvv(1)) ',' num2str(crosscorr.ylim_dvv(2))],'fontunits','normalized','fontsize',.5,'tooltipstring',...
    'Limits of dV/V yaxis. es. -2,2','Tag','dVV_Ylimits_Value','Callback',@(numfld,event) updatedVV);


% Groundwater Ylimits
choicePiezo = get(findobj(mainCrossFig,'tag','piezo_plotcheck'),'Value');
if choicePiezo == 1
    uicontrol('style','text','units','normalized','position',[.55 .5260 .05 .03],...
        'string','Water Ylimits','horizontalalignment','center','fontunits','normalized','fontsize',.5,...
        'backgroundcolor',[.8 .8 .8],'Tag','water_Ylimits');
    ylimPiezoPlot = crosscorr.ylimPiezo;
    uicontrol('style','edit','units','normalized','position',[.60 .5260 .08 .03],'backgroundcolor',[1 1 1],...
        'horizontalalignment','center','fontunits','normalized','fontsize',.5,'String',[num2str(min(ylimPiezoPlot)) ',' num2str(max(ylimPiezoPlot))],...
        'tooltipstring','Limits of water table Yaxis. es. -2,2','Tag','water_Ylimits_Value','Callback',@(numfld,event) updatedVV);
end

% dVV Color
uicontrol('style','pushbutton','units','normalized','position',[.685 .558 .08 .03],...
    'string','dV/V Colour','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
    'backgroundcolor',[.7 .7 .7],'callback',@(btn,event) dvv_color(btn),'Tag','dvv_color')

% Water table Color
if choicePiezo == 1
    uicontrol('style','pushbutton','units','normalized','position',[.685 .5260 .08 .03],...
        'string','Water Colour','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
        'backgroundcolor',[.7 .7 .7],'callback',@(btn,event) watertable_color(btn),'Tag','watertable_color')
end

% Reset button
uicontrol('style','pushbutton','units','normalized','position',[.73 .491 .035 .03],...
    'string','Reset','horizontalalignment','left','fontunits','normalized','fontsize',.5,'FontWeight','bold',...
    'backgroundcolor',[.7 .7 .7],'callback',@(btn,event) resetdVV(btn),'Tag','reset_dvvPlot')

% % Update button
% uicontrol('style','pushbutton','units','normalized','position',[.73 .47 .035 .03],...
%     'string','Update','horizontalalignment','left','fontunits','normalized','fontsize',.5,'FontWeight','bold',...
%     'backgroundcolor',[.7 .7 .7],'callback',@(btn,event) updatedVV(btn),'Tag','update_dvvPlot')

%) Dynamic cross window options
dvv_corrwindowValue =  get(findobj(mainCrossFig,'tag','dvv_corrwindowValue'),'String');
if strcmp(dvv_corrwindowValue,'dynamic') == 1
    %Titolo
    uicontrol('style','text','units','normalized','position',[.772 .540 .13 .03],...
        'string','Dynamic Corr. window','horizontalalignment','center','fontunits','normalized','fontsize',.6,...
        'Tag','dynamiCorrWinTitle');
    % Plot video button
    uicontrol('style','pushbutton','units','normalized','position',[.889 .5 .06 .03],...
        'string','Plot video','horizontalalignment','left','fontunits','normalized','fontsize',.5,...
        'backgroundcolor',[.7 .7 .7],'callback','CrossCorr_plotDynamicCorrWindow','Tag','PlotVideoButton');
    
    % Slider bar title
    uicontrol('style','text','units','normalized','position',[.79 .5 .04 .03],...
        'string','Win. Corr','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Tag','DynamicWinCorr_text',...
        'backgroundcolor',[.8 .8 .8]);
    % Slidebar
    global dataforPlotVideoCrossCorr
    NdynamicWinCorr = size(dataforPlotVideoCrossCorr.t,1); %numero finestre che si muovono nel correlogramma
    stepSz = [1,NdynamicWinCorr];
    uicontrol('style','slider','units','normalized','position',[.83 .5 .05 .03],...
        'Min',1,'Max',NdynamicWinCorr,'SliderStep',stepSz/(NdynamicWinCorr-1),'Value',NdynamicWinCorr,'Tag','dynamicWinCorrSlider',...
        'callback',@(btn,event) SliderUpdatePlot(btn));
    
end
end

function SliderUpdatePlot(btn)
global mainCrossFig
global crosscorr
global dataforPlotVideoCrossCorr

SliderselectedWinCorr = get(findobj(mainCrossFig,'tag','dynamicWinCorrSlider'),'value');

dvvaxes = findobj(mainCrossFig,'type','axes','tag','dvvPlot');
yyaxis(dvvaxes, 'left');
lineePlottate = get(dvvaxes, 'Children');
delete(lineePlottate);

% dvv plot
dv_timeAx = dataforPlotVideoCrossCorr.dv_timeAx;
dv = dataforPlotVideoCrossCorr.dv_complete;
dvvplot = plot(dvvaxes,dv_timeAx,dv(SliderselectedWinCorr,:),'Color',[160/255 160/255 160/255],'LineStyle','-.','marker','none');
% dvv smoothed plot
hold on
dv_smoothSlider = dataforPlotVideoCrossCorr.dv_smoothSlider;
dvvSmoothato = plot(dvvaxes,dv_timeAx,dv_smoothSlider(SliderselectedWinCorr,:),'Color',[96/255 96/255 96/255],'LineStyle','-','marker','none')

% Tile
t = dataforPlotVideoCrossCorr.t;
t1 = t(SliderselectedWinCorr,1);
t2 = t(SliderselectedWinCorr,2);
dvvtitle = crosscorr.TITOLOCORRELOGRAMMA;
dvv_corrwindowValue =  get(findobj(mainCrossFig,'tag','dvv_corrwindowValue'),'String');
dvvtitle = [dvvtitle '| correlogramWindow [' num2str(t1) ';' num2str(t2) ']'];
dataforPlotVideoCrossCorr.dvvtitle = dvvtitle;
set(dvvaxes.Title,'String',dvvtitle,'fontsize',9,'fontname','garamond');

legend(dvvaxes,'dV/V','dV/V Smoothed','Piezometer data','Location','southeast');
%     legend( [dvvplot;dvvSmoothato;dvv_watertableplot;] , {'dV/V','dV/V Smoothed','Piezometer data'} ,'Location','southeast' );


%% CorrWindows ==> Plottare sopra il correlogramma il rettangolo che indica la corr.window
axesCorrelogram = crosscorr.graficoCorrelogramma.Parent; % Riprendo l'axes del correlogramma
XaxisLimCorrel = axesCorrelogram.XLim; % Leggo i limiti in X
YaxisLimCorrel = axesCorrelogram.YLim; % Leggo i limiti in Y

delete(findobj(mainCrossFig,'type','axes','tag','drawnowdynamicCorrWinAxes'));
correlogramplot = findobj(mainCrossFig,'tag','Correlogram') % Richiamo la figura del correlogramma
% Creo nuovo asse per rettangolo CorrWindow
asseCorrWindow = axes('Position',[0.1800 0.2809 0.3350 0.6791],'XLim',XaxisLimCorrel,'Tag','drawnowdynamicCorrWinAxes')
% Plotto il rettangolo
t = dataforPlotVideoCrossCorr.t;
t1 = t(SliderselectedWinCorr,1);
t2 = t(SliderselectedWinCorr,2);
rectangle(asseCorrWindow,'Position',[t1 YaxisLimCorrel(1) abs(-t2-(-t1)) 1],'EdgeColor','r','LineWidth',1.4,'LineStyle','-.')
set(gca,'Visible','off')


end

function dvvSmoothingOptions
global crosscorr;
% Creo tasti
uicontrol('style','text','units','normalized','position',[0.762 0.62 .12 .03],...
    'string','Smoothing dVV','horizontalalignment','center','fontunits','normalized','fontsize',.6,...
    'Tag','settings_dvv');
Smoothing_text = uicontrol('style','text','units','normalized','position',[0.79 .59 .06 .03],...
    'string','Smoothing type','horizontalalignment','center','fontunits','normalized','fontsize',.5,'Tag','Smoothing_text',...
    'backgroundcolor',[.8 .8 .8]);
Smoothing_listbox = uicontrol('style','popupmenu','units','normalized','position',[0.855 .587 .06 .032],'tag','Smoothing_type',...
    'horizontalalignment','right','fontunits','normalized','fontsize',.5,...
    'string',{'Movmean','Movmedian','Gaussian','Lowess','Loess','Rlowess','Rloess','Sgolay'},'Callback',@(numfld,event) updatedVV);
Smoothing_edit = uicontrol('style','edit','units','normalized','position',[0.92 .59 .03 .03],...
    'horizontalalignment','center','fontunits','normalized','fontsize',.5,'Tag','Smoothing_window','Callback',@(numfld,event) updatedVV,...
    'backgroundcolor','w','String',num2str(crosscorr.smoothdefaultWind),'TooltipString','It specifies the length of the window used by the smoothing method');

end

function updatedVV 
global mainCrossFig
global dataToSave
global crosscorr
global dataforPlotVideoCrossCorr
delete(findobj(mainCrossFig,'tag','datiesclusidvv'));drawnow 

SliderselectedWinCorr = get(findobj(mainCrossFig,'tag','dynamicWinCorrSlider'),'value')

% Richiamo asse plot dvv
dvvaxes = findobj(mainCrossFig,'type','axes','tag','dvvPlot');

% Update X lim
startime = datetime(get(findobj(mainCrossFig,'tag','dVV_Xlimits_left'),'String'));
endtime = datetime(get(findobj(mainCrossFig,'tag','dVV_Xlimits_right'),'String'));
if size(startime,1) ~= 1
    startime = startime(1,1);
    endtime = endtime(1,1);
end
TimezoneSurvey = get(findobj(mainCrossFig,'tag','Timezone'),'String');
dvvaxes.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);

% Update X lim dVV_Xlimits_right
startime = datetime(get(findobj(mainCrossFig,'tag','dVV_Xlimits_left'),'String'));
endtime = datetime(get(findobj(mainCrossFig,'tag','dVV_Xlimits_right'),'String'));
if size(startime,1) ~= 1
    startime = startime(1,1);
    endtime = endtime(1,1);
end
TimezoneSurvey = dataforPlotVideoCrossCorr.TimezoneSurvey;
dvvaxes.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);

% Aggiorno posizione rettangolo rosso se sono stati escludi dei dati
global rettangoloEscludidati
if isfield(rettangoloEscludidati,'rectX')
rectX = rettangoloEscludidati.rectX;
end
excludedata = get(findobj(mainCrossFig,'tag','exclude_correlogram'),'String');
if not(isempty(excludedata))
ax_dvv_datiEsclusi = axes('Position',[0.55 0.7 0.42 0.26]);
TimezoneSurvey = get(findobj(mainCrossFig,'tag','Timezone'),'String');
dvvaxes.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);
rectY = dvvaxes.YAxis(1).Limits;
rectY = [rectY(1) rectY(1) rectY(2) rectY(2)];
fill(rectX,rectY, 'r', ...
    'EdgeColor', 'none', 'FaceAlpha', 0.3,'tag','datiesclusidvv'); % FaceAlpha controls transparency
TimezoneSurvey = get(findobj(mainCrossFig,'tag','Timezone'),'String');
ax_dvv_datiEsclusi.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);
set(gca,'Visible','off')
end

% Update Y lim dVV
new_dVVYlimits = get(findobj(mainCrossFig,'tag','dVV_Ylimits_Value'),'String');
if strcmp(class(new_dVVYlimits),'cell') %questo ciclo if l'ho messo perchè dvvYlimits si riempie ogni volta che faccio update
    new_dVVYlimits = new_dVVYlimits{1,:}
end
dvvaxes.YLim = str2num(new_dVVYlimits);

% Update Y lim Piezo
new_PiezoYlimits = get(findobj(mainCrossFig,'tag','water_Ylimits_Value'),'String');
if not(isempty(new_PiezoYlimits))
    if strcmp(class(new_PiezoYlimits),'cell') %questo ciclo if l'ho messo perchè dvvYlimits si riempie ogni volta che faccio update
        new_PiezoYlimits = new_PiezoYlimits{1,:}
    end
    dvvaxes.YAxis(2).Limits = str2num(new_PiezoYlimits);
end

% Smoothing dV/V curve
dvv_smoothingType = findobj(mainCrossFig,'tag','Smoothing_type');
dvv_smoothingType = dvv_smoothingType.String(dvv_smoothingType.Value);
dvv_smoothingWindow = findobj(mainCrossFig,'tag','Smoothing_window');
dvv_smoothingWindow = str2num(dvv_smoothingWindow.String);
yyaxis(dvvaxes,'left')
lineePlottate = get(dvvaxes, 'Children');
dvvSmoothato = lineePlottate(1);
dvvplot = lineePlottate(2);
delete(dvvSmoothato)
dv = dataforPlotVideoCrossCorr.dv_complete;
dv_timeAx = dataforPlotVideoCrossCorr.dv_timeAx;
dv_smooth = smoothdata(dv,2,dvv_smoothingType{1,1},dvv_smoothingWindow); %% ATTENZIONE AGGIORNO SOLO L'ultimo dvv
dataToSave.dv_smooth = dv_smooth; %Dato da salvare
% queste due righe servono solo per la sliderbar
dv_smoothSlider = smoothdata(dv,2,dvv_smoothingType{1,1},dvv_smoothingWindow); %% ATTENZIONE AGGIORNO SOLO L'ultimo dvv
dataforPlotVideoCrossCorr.dv_smoothSlider = dv_smoothSlider;
yyaxis(dvvaxes,'left')
hold on
% % % SliderselectedWinCorr = get(findobj(mainCrossFig,'tag','dynamicWinCorrSlider'),'value');
if not(isempty(SliderselectedWinCorr)) == 1
dvvSmoothato = plot(dvvaxes,dv_timeAx,dv_smooth(SliderselectedWinCorr,:),'Color',[96/255 96/255 96/255],'LineStyle','-','marker','none');
else
    dvvSmoothato = plot(dvvaxes,dv_timeAx,dv_smooth,'Color',[96/255 96/255 96/255],'LineStyle','-','marker','none');
end
dvvaxes.YLim = str2num(new_dVVYlimits);
dvvaxes.XLim = datetime([startime.Year endtime.Year],[startime.Month endtime.Month],[startime.Day endtime.Day],[startime.Hour endtime.Hour],[startime.Minute endtime.Minute],[startime.Second endtime.Second],'TimeZone',TimezoneSurvey);
% dvv_watertableplot = dataforPlotVideoCrossCorr.dvv_watertableplot;
dvvaxes
legend(dvvaxes,'dV/V','dV/V Smoothed','Piezometer data','Location','southeast');

%% CorrWindows ==> Plottare sopra il correlogramma il rettangolo che indica la corr.window
if not(isempty(SliderselectedWinCorr)) == 1 % Solo se è stata usata l'opzione Dynamic
axesCorrelogram = crosscorr.graficoCorrelogramma.Parent; % Riprendo l'axes del correlogramma
XaxisLimCorrel = axesCorrelogram.XLim; % Leggo i limiti in X
YaxisLimCorrel = axesCorrelogram.YLim; % Leggo i limiti in Y

delete(findobj(mainCrossFig,'type','axes','tag','drawnowdynamicCorrWinAxes'));
correlogramplot = findobj(mainCrossFig,'tag','Correlogram') % Richiamo la figura del correlogramma
% Creo nuovo asse per rettangolo CorrWindow
asseCorrWindow = axes('Position',[0.1800 0.2809 0.3350 0.6791],'XLim',XaxisLimCorrel,'Tag','drawnowdynamicCorrWinAxes')
% Plotto il rettangolo
t = dataforPlotVideoCrossCorr.t;
t1 = t(SliderselectedWinCorr,1);
t2 = t(SliderselectedWinCorr,2);
rectangle(asseCorrWindow,'Position',[t1 YaxisLimCorrel(1) abs(-t2-(-t1)) 1],'EdgeColor','r','LineWidth',1.4,'LineStyle','-.')
set(gca,'Visible','off')
end

end

function dvv_color(btn) %Change dVV curve colour
dvv_color = uisetcolor; %scegli colore
global crosscorr
global mainCrossFig
dvvfigure = findobj(gcf,'tag','dvvPlot');
dvplot = crosscorr.dvplot;
dvsmoothplot = crosscorr.dvsmoothplot;
dvplot.Color = dvv_color;
dvvfigure.YAxis(1).Color = dvv_color;
dvv_smoothingValue = get(findobj(mainCrossFig,'tag','dvv_smoothingValue'),'Value'); %se c'è anche plot dvv smoothato
if dvv_smoothingValue == 1
    dvsmoothplot.Color = dvplot.Color;
    dvplot.Color(4) = 0.3;  % 50% transparent
end
end

function watertable_color(btn) %Change Grounwater curve colour
watertable_color = uisetcolor; %scegli colore
global crosscorr
dvvfigure = findobj(gcf,'tag','dvvPlot');
dv_watertableplot = crosscorr.dv_watertableplot;
dv_watertableplot.Color = watertable_color;
dvvfigure.YAxis(2).Color = watertable_color;
end