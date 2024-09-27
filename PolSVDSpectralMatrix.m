function PolSVDSpectralMatrix(plotUpdate,varargin)

global utilities
global mainPolFig
global polPlotParameters
global normHistType

%% Nascondere plot segnali altrimenti si sovrappongono al plot della SVD
asse = findobj(mainPolFig,'type','axes','tag','comp_x');
set(asse,'visible','off')
dataObjs = get(asse, 'Children');
dataObjs.LineStyle = 'none';
asse = findobj(mainPolFig,'type','axes','tag','comp_y');
set(asse,'visible','off')
dataObjs = get(asse, 'Children');
dataObjs.LineStyle = 'none';
asse = findobj(mainPolFig,'type','axes','tag','comp_z');
set(asse,'visible','off')
dataObjs = get(asse, 'Children');
dataObjs.LineStyle = 'none';
%%

if not(plotUpdate)
    
    data = varargin{1};
    fs = varargin{2};
    timeWin = varargin{3};
    winOverlap = varargin{4};
    winTapering = varargin{5};
    nFFT = varargin{6};
    freqRange = varargin{7};
    spectralSmoothing = varargin{8};
    freqAverages = varargin{9};
    beta2Axis = varargin{10};
    thetaHAxis = varargin{11};
    thetaVAxis = varargin{12};
    phiHHAxis = varargin{13};
    phiVHAxis = varargin{14};
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dt = 1/fs;                                                               % Sampling interval [s]
    timeWindowS = round(timeWin/dt);                                         % Time window lenght (for averaging) [sample]
    overlapS = round((winOverlap/100)*timeWindowS);
    
    
    %% TIME WINDOW TAPERING MASK ------------------------------------------
    switch(lower(winTapering))
        case('hann')
            timeWindowSTape = hann(timeWindowS);
        case('hamming')
            timeWindowSTape = hamming(timeWindowS);
        case('tukey')
            timeWindowSTape = tukeywin(timeWindowS);
        case('none')
            timeWindowSTape = rectwin(timeWindowS);
        case('blackmanharris')
            timeWindowSTape = blackmanharris(timeWindowS);
    end
    timeWindowSTape3C = repmat(timeWindowSTape,1,3);
    %% SPECTRAL SAMPLING AND SMOOTHING ------------------------------------
    df = fs/nFFT;
    freqAx = 0:df:(nFFT/2-1)*df;
    firstFreqIndex = find(freqAx >= freqRange(1),1,'first');
    if isempty(firstFreqIndex)
        firstFreqIndex = 1;
    end
    lastFreqIndex = find(freqAx >= freqRange(2),1,'first');
    if isempty(lastFreqIndex)
        lastFreqIndex = length(freqAx);
    end
    nFFTRange = length(firstFreqIndex:lastFreqIndex);
    
    % Waitbar -------------------------------------------------------------
    handleToWaitBar = axes('Units','normalized','Position',[.25 .005 .1 .03],'XLim',[0 1],'YLim',[0 1],'XTick',[],'YTick',[],...
        'Color', [.3 .35 .4],'XColor', [.3 .35 .4],'YColor', [.3 .35 .4],'tag','waitbar');
    patch([0 0 0 0], [0 1 1 0], [1 1 1],'Parent', handleToWaitBar,'EdgeColor','none');
    drawnow
    
    %     % Smoothing matrix ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    %     if strcmp(spectralSmoothing,'KonnoOhmachi')
    %         b = str2double(get(findobj(mainPolFig,'tag','ko_b_value'),'string'));
    %         konnoOhmachi = zeros(length(freqAx));
    %         for f = 1:length(freqAx)
    %             konnoOhmachi(:,f) = ((sin(b*log10(freqAx/freqAx(f))))./(b*log10(freqAx/freqAx(f)))).^4;
    %         end
    %     end
    
    
    %% COMPUTE FREQUENCY POLARIZATION PARAMETERS --------------------------
    winIndexes = 1:(timeWindowS-overlapS):size(data,1)-timeWindowS;
    winNumber = length(winIndexes);
    sizePolPar = floor(winNumber/freqAverages);
    %
    autoSpectX = zeros(nFFTRange,freqAverages);
    autoSpectY = zeros(nFFTRange,freqAverages);
    autoSpectZ = zeros(nFFTRange,freqAverages);
    crossSpectXY = zeros(nFFTRange,freqAverages);
    crossSpectXZ = zeros(nFFTRange,freqAverages);
    crossSpectYZ = zeros(nFFTRange,freqAverages);
    %
    betaSquaredSVDTrace = zeros(sizePolPar,nFFTRange);
    % betaSquaredEIG = zeros(sizePolPar,nFFTRange);
    % coheDiego = zeros(sizePolPar,nFFTRange);
    thetaH = zeros(sizePolPar,nFFTRange);
    thetaV = zeros(sizePolPar,nFFTRange);
    phiHH = zeros(sizePolPar,nFFTRange);
    phiVH = zeros(sizePolPar,nFFTRange);
    %
    nWin = 0;
    polParCount = 1;
    
    %     bandWidth = str2double(get(findobj(mainPolFig,'tag','smoothing_band'),'string')); % [Hz]
    %     rectWin = round(bandWidth/df);
    
    while nWin <= winNumber - freqAverages %+ 1
        
        for nSubWin = 1:freqAverages
            dataTemp = data(winIndexes(nWin+nSubWin):winIndexes(nWin+nSubWin)+timeWindowS-1,:).*timeWindowSTape3C;
            dataTempF = fft(dataTemp,nFFT,1);
            
            %             dataTempF = movmean(dataTempF,rectWin,1);
            
            autoSpectX(:,nSubWin) = dataTempF(firstFreqIndex:lastFreqIndex,1).*conj(dataTempF(firstFreqIndex:lastFreqIndex,1));
            autoSpectY(:,nSubWin) = dataTempF(firstFreqIndex:lastFreqIndex,2).*conj(dataTempF(firstFreqIndex:lastFreqIndex,2));
            autoSpectZ(:,nSubWin) = dataTempF(firstFreqIndex:lastFreqIndex,3).*conj(dataTempF(firstFreqIndex:lastFreqIndex,3));
            crossSpectXY(:,nSubWin) = dataTempF(firstFreqIndex:lastFreqIndex,1).*conj(dataTempF(firstFreqIndex:lastFreqIndex,2));
            crossSpectXZ(:,nSubWin) = dataTempF(firstFreqIndex:lastFreqIndex,1).*conj(dataTempF(firstFreqIndex:lastFreqIndex,3));
            crossSpectYZ(:,nSubWin) = dataTempF(firstFreqIndex:lastFreqIndex,2).*conj(dataTempF(firstFreqIndex:lastFreqIndex,3));
        end
        % Compute mean Spectral Covariance Matrix
        spectCovMatrix(1,1,:) = mean(autoSpectX,2);
        spectCovMatrix(1,2,:) = mean(crossSpectXY,2);
        spectCovMatrix(1,3,:) = mean(crossSpectXZ,2);
        spectCovMatrix(2,2,:) = mean(autoSpectY,2);
        spectCovMatrix(2,3,:) = mean(crossSpectYZ,2);
        spectCovMatrix(3,3,:) = mean(autoSpectZ,2);
        spectCovMatrix(2,1,:) = mean(conj(crossSpectXY),2);
        spectCovMatrix(3,1,:) = mean(conj(crossSpectXZ),2);
        spectCovMatrix(3,2,:) = mean(conj(crossSpectYZ),2);
        
        for I = 1:nFFTRange
            % Compute Singular value decomposition of the spectral density matrix
            [~,S,V] = svd(spectCovMatrix(:,:,I));
            % [~,eigValue] = eig(spectCovMatrix(:,:,I));
            
            %% POLARIZATION PARAMETERS - Degree of polarization -----------
            % Parameter obtained from the singular values of the spectral density matrix
            betaSquaredSVDTrace(polParCount,I) = (3*trace(S.^2) - (trace(S))^2)/(2*((trace(S))^2));
            % betaSquaredEIG(polParCount,I) = (2*(eigValue(1,1)-eigValue(2,2))^2 + 2*(eigValue(1,1)-eigValue(3,3))^2 + 2*(eigValue(2,2)-eigValue(3,3))^2)/(4*(trace(eigValue))^2);
            % betaSquaredEIGTrace(polParCount,I) = (3*trace(eigValue.^2) - (trace(eigValue))^2)/(2*((trace(eigValue))^2));
            
            % coheDiego(polParCount,I) = ((abs(spectCovMatrix(1,2,I)))^2 *(abs(spectCovMatrix(1,3,I)))^2 *(abs(spectCovMatrix(2,3,I)))^2)/(spectCovMatrix(1,1,I)*spectCovMatrix(2,2,I)*spectCovMatrix(3,3,I));
            % coheDiego(polParCount,I) = (1/3)*(((abs(spectCovMatrix(1,2,I)))^2)/(spectCovMatrix(1,1,I)*spectCovMatrix(2,2,I)) +...
            %           ((abs(spectCovMatrix(1,3,I)))^2)/(spectCovMatrix(1,1,I)*spectCovMatrix(3,3,I)) +...
            %           ((abs(spectCovMatrix(2,3,I)))^2)/(spectCovMatrix(2,2,I)*spectCovMatrix(3,3,I)));
            % Double polarization parameter (if = 1 --> 2 polarizations at frequency f exist)
            % doublePolDiego(polParCount,I) = 1-(S(1,1,I)-S(2,2,I)+S(3,3,I))/trace(S(:,:,I));
            
            %% POLARIZATION PARAMETERS - Polarization angles -------------------
            tempPhaseTerm = exp(1i*2*pi*freqAx(I+firstFreqIndex-1)*(0:(1/freqAx(I+firstFreqIndex-1))/500:1/freqAx(I+firstFreqIndex-1)-(1/freqAx(I+firstFreqIndex-1))/500));
            %% Backazimuth angle
            tempFunct2 = abs(real((sqrt(V(1,1)^2+V(2,1)^2)).*tempPhaseTerm));
            [~,index2] = max(tempFunct2.^2);
            thetaHtemp2 = 2*pi*freqAx(I+firstFreqIndex-1)*((index2-1)*((1/freqAx(I+firstFreqIndex-1))/500));
            % thetaH(I) = atand(real(V(2,1,I)*exp(-1i*thetaHtemp))/real(V(1,1,I)*exp(-1i*thetaHtemp)));                     % Range -90°/+90°
            % thetaH(polParCount,I) = atand((real(V(2,1)*exp(-1i*thetaHtemp2)))/(real(V(1,1)*exp(-1i*thetaHtemp2))));       % Range -90°/+90°
            thetaH(polParCount,I) = mod(atan2d(real(V(2,1)*exp(-1i*thetaHtemp2)),real(V(1,1)*exp(-1i*thetaHtemp2))),360);   % Range 0°/+360° - 0° means East counterclockwise
            %% Incident angle
            % tempFunct3 = abs(real((sqrt(((sqrt(V(1,1)^2+V(2,1)^2)).*exp(-1i*thetaHtemp2))^2+V(3,1)^2)).*tempPhaseTerm));
            tempFunct3 = abs(real(sqrt((sqrt(V(1,1)^2+V(2,1)^2))^2+V(3,1)^2).*tempPhaseTerm));
            [~,index3] = max(tempFunct3.^2);
            thetaVtemp2 = 2*pi*freqAx(I+firstFreqIndex-1)*((index3-1)*((1/freqAx(I+firstFreqIndex-1))/500));
            % thetaVtemp = -0.5*angle(V(3,1)^2+V(1,1)^2+V(2,1)^2) + pi/2;
            thetaV(polParCount,I) = atand(abs((real(V(3,1)*exp(-1i*thetaVtemp2)))/(real((sqrt(V(1,1)^2+V(2,1)^2))*exp(-1i*thetaVtemp2)))));   % 0° means horizontal
            %             thetaV(polParCount,I) = atand(abs((real((sqrt(V(1,1)^2+V(2,1)^2))*exp(-1i*thetaVtemp2)))/(real(V(3,1)*exp(-1i*thetaVtemp2)))));     % 90° means horizontal
            %% Phase lag between principal horizontal components
            %             phiHH(polParCount,I) = rad2deg(wrapToPi(angle(V(1,1)) - angle(V(2,1))));
            phiHH(polParCount,I) = rad2deg(angle(V(1,1)*V(2,1)));
            %% Phase lag between principal horizontal and vertical components
            phiVH(polParCount,I) = rad2deg(thetaHtemp2-angle(V(3,1)));
        end
        polParCount = polParCount + 1;
        nWin = nWin + freqAverages;
        % Waitbar update --------------------------------------------------
        p = get(handleToWaitBar,'Child'); x = get(p,'XData'); x(3:4) = polParCount/sizePolPar; set(p,'XData',x); drawnow
    end
    
    delete(handleToWaitBar); drawnow;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     thetaH = mod(mod(abs(thetaH-360),360)+90,360);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % necessario per il plot con asse delle frequenze logaritmico (altrimenti il surf non plotta il valore max dell'asse beta)
    % in teoria andrebbe fatto anche per i parametri angolari di polarizzazione (sempre per plottare i valori massimi nel caso di asse delle frequenze logaritmico)
    beta2Axis = [beta2Axis beta2Axis(end)+(beta2Axis(2)-beta2Axis(1))];
    
    %% Histogram counts with selected normalization -----------------------
    histBeta = zeros(length(beta2Axis)-1,nFFTRange);
    histThetaH = zeros(length(thetaHAxis)-1,nFFTRange);
    histThetaV = zeros(length(thetaVAxis)-1,nFFTRange);
    histPhiHH = zeros(length(phiHHAxis)-1,nFFTRange);
    histPhiVH = zeros(length(phiVHAxis)-1,nFFTRange);
    %
    normHistTypeString = get(findobj(mainPolFig,'tag','hist_count_normalization'),'string');
    normHistTypeValue = get(findobj(mainPolFig,'tag','hist_count_normalization'),'value');
    normHistType = normHistTypeString{normHistTypeValue};
    for I = 1:nFFTRange
        [histBeta(:,I),~] = histcounts(betaSquaredSVDTrace(:,I),beta2Axis,'Normalization',normHistType);
        % [histBeta(:,I),~] = histcounts(betaSquaredEIG(:,I),beta2Axis,'Normalization',normHistType);
        [histThetaH(:,I),~] = histcounts(thetaH(:,I),thetaHAxis,'Normalization',normHistType);
        [histThetaV(:,I),~] = histcounts(thetaV(:,I),thetaVAxis,'Normalization',normHistType);
        [histPhiHH(:,I),~] = histcounts(phiHH(:,I),phiHHAxis,'Normalization',normHistType);
        [histPhiVH(:,I),~] = histcounts(phiVH(:,I),phiVHAxis,'Normalization',normHistType);
    end
    % betaSquaredSVDTraceMEAN = mean(betaSquaredSVDTrace,1);
    % coheDiegoMEAN = mean(coheDiego,1);
    
    polPlotParameters.SVDPolResults{1,1} = beta2Axis;
    polPlotParameters.SVDPolResults{1,2} = histBeta;
    polPlotParameters.SVDPolResults{2,1} = thetaHAxis;
    polPlotParameters.SVDPolResults{2,2} = histThetaH;
    polPlotParameters.SVDPolResults{3,1} = thetaVAxis;
    polPlotParameters.SVDPolResults{3,2} = histThetaV;
    polPlotParameters.SVDPolResults{4,1} = phiHHAxis;
    polPlotParameters.SVDPolResults{4,2} = histPhiHH;
    polPlotParameters.SVDPolResults{5,1} = phiVHAxis;
    polPlotParameters.SVDPolResults{5,2} = histPhiVH;
    polPlotParameters.freqAx = freqAx(firstFreqIndex:lastFreqIndex);
    
end

% Max values of polarization parameters -----------------------------------
[~,indexBeta] = max(polPlotParameters.SVDPolResults{1,2}(:));
[rowIBeta, colIBeta] = ind2sub(size(polPlotParameters.SVDPolResults{1,2}),indexBeta);
[~,indexThetaH] = max(polPlotParameters.SVDPolResults{2,2}(:));
[rowIThetaH, colIThetaH] = ind2sub(size(polPlotParameters.SVDPolResults{2,2}),indexThetaH);
[~,indexThetaV] = max(polPlotParameters.SVDPolResults{3,2}(:));
[rowIThetaV, colIThetaV] = ind2sub(size(polPlotParameters.SVDPolResults{3,2}),indexThetaV);
[~,indexPhiHH] = max(polPlotParameters.SVDPolResults{4,2}(:));
[rowIPhiHH, colIPhiHH] = ind2sub(size(polPlotParameters.SVDPolResults{4,2}),indexPhiHH);
[~,indexPhiVH] = max(polPlotParameters.SVDPolResults{5,2}(:));
[rowIPhiVH, colIPhiVH] = ind2sub(size(polPlotParameters.SVDPolResults{5,2}),indexPhiVH);

% Colormap ----------------------------------------------------------------
if strcmp(polPlotParameters.colormap,'cmapwbr')
    colormap(utilities.customCmap)
else
    colormap(polPlotParameters.colormap)
end
% Colormap range ----------------------------------------------------------
colormapRangeTmp = polPlotParameters.colormapRange;
if isempty(colormapRangeTmp) || strcmp(colormapRangeTmp,'auto')
    colormapRange = 'auto';
else
    colormapRange = [str2double(colormapRangeTmp(1:strfind(colormapRangeTmp,'-')-1)) str2double(colormapRangeTmp(strfind(colormapRangeTmp,'-')+1:end))];
end
%
set(0,'currentfigure',mainPolFig);
% Beta Squared ------------------------------------------------------------
axes('units','normalized','position',[.2 1.105-(.19*1+(.25/5)*2) .7 .155])
if strcmpi(colormapRange,'auto')
    clims = [min(polPlotParameters.SVDPolResults{1,2}(:)) max(polPlotParameters.SVDPolResults{1,2}(:))];
else
    clims = colormapRange;
end
if strcmp(polPlotParameters.freqAxis,'Logarithmic')
    surf(polPlotParameters.freqAx,polPlotParameters.SVDPolResults{1,1}(1:end-1),polPlotParameters.SVDPolResults{1,2},'edgecolor','none');
    view(2);
    caxis(clims);
    %     pcolor(polPlotParameters.freqAx,polPlotParameters.SVDPolResults{1,1}(2:end),polPlotParameters.SVDPolResults{1,2})
    %     shading flat
    set(gca,'xscale','log')
else
    imagesc(polPlotParameters.freqAx,polPlotParameters.SVDPolResults{1,1}(1:end-1),polPlotParameters.SVDPolResults{1,2},clims)
    axis xy
end
set(gca,'ylim',[0 1],'ytick',[0 .2 .4 .6 .8 1],'box','on','xlim',polPlotParameters.freqLim)
ylabel('\beta^2 [-]')
c = colorbar('position',[.91 1.105-(.19*1+(.25/5)*2) .02 .155]);
temp = c.Limits;
set(c.Label,'string',normHistType,'HorizontalAlignment','center','FontSize',8,'Position',[3 diff(temp)/2 0])
hold on
plot(polPlotParameters.freqAx(colIBeta),polPlotParameters.SVDPolResults{1,1}(rowIBeta),'pr','markersize',7)
% plot(freqAx,betaSquaredSVDTraceMEAN,'r','linewidth',2)
% plot(freqAx,coheDiegoMEAN,'m','linewidth',2)
hold off

% Theta H -----------------------------------------------------------------
axes('units','normalized','position',[.2 1.105-(.19*2+(.25/5)*2) .7 .155])
if strcmpi(colormapRange,'auto')
    clims = [min(polPlotParameters.SVDPolResults{2,2}(:)) max(polPlotParameters.SVDPolResults{2,2}(:))];
else
    clims = (colormapRange);
end
if strcmp(polPlotParameters.freqAxis,'Logarithmic')
    surf(polPlotParameters.freqAx,polPlotParameters.SVDPolResults{2,1}(1:end-1),polPlotParameters.SVDPolResults{2,2},'edgecolor','none');
    view(2);
    caxis(clims);
    %     pcolor(polPlotParameters.freqAx,polPlotParameters.SVDPolResults{1,1}(2:end),polPlotParameters.SVDPolResults{1,2})
    %     shading flat
    set(gca,'xscale','log')
else
    imagesc(polPlotParameters.freqAx,polPlotParameters.SVDPolResults{2,1}(1:end-1),polPlotParameters.SVDPolResults{2,2},clims)
    axis xy
end
set(gca,'ylim',[0 360],'ytick',[0 90 180 270 360],'box','on','xlim',polPlotParameters.freqLim)
ylabel('\Theta_H [deg]')
c = colorbar('position',[.91 1.105-(.19*2+(.25/5)*2) .02 .155]);
temp = c.Limits;
set(c.Label,'string',normHistType,'HorizontalAlignment','center','FontSize',8,'Position',[3 diff(temp)/2 0])
hold on
plot(polPlotParameters.freqAx(colIThetaH),polPlotParameters.SVDPolResults{2,1}(rowIThetaH),'pr','markersize',7)
hold off

% Theta V -----------------------------------------------------------------
axes('units','normalized','position',[.2 1.105-(.19*3+(.25/5)*2) .7 .155])
if strcmpi(colormapRange,'auto')
    clims = [min(polPlotParameters.SVDPolResults{3,2}(:)) max(polPlotParameters.SVDPolResults{3,2}(:))];
else
    clims = (colormapRange);
end
if strcmp(polPlotParameters.freqAxis,'Logarithmic')
    surf(polPlotParameters.freqAx,polPlotParameters.SVDPolResults{3,1}(1:end-1),polPlotParameters.SVDPolResults{3,2},'edgecolor','none');
    view(2);
    caxis(clims);
    %     pcolor(polPlotParameters.freqAx,polPlotParameters.SVDPolResults{1,1}(2:end),polPlotParameters.SVDPolResults{1,2})
    %     shading flat
    set(gca,'xscale','log')
else
    imagesc(polPlotParameters.freqAx,polPlotParameters.SVDPolResults{3,1}(1:end-1),polPlotParameters.SVDPolResults{3,2},clims)
    axis xy
end
set(gca,'ylim',[0 90],'ytick',[0 30 60 90],'box','on','xlim',polPlotParameters.freqLim)
ylabel('\Theta_V [deg]')
c = colorbar('position',[.91 1.105-(.19*3+(.25/5)*2) .02 .155]);
temp = c.Limits;
set(c.Label,'string',normHistType,'HorizontalAlignment','center','FontSize',8,'Position',[3 diff(temp)/2 0])
hold on
plot(polPlotParameters.freqAx(colIThetaV),polPlotParameters.SVDPolResults{3,1}(rowIThetaV),'pr','markersize',7)
hold off

% Phi HH ------------------------------------------------------------------
axes('units','normalized','position',[.2 1.105-(.19*4+(.25/5)*2) .7 .155])
if strcmpi(colormapRange,'auto')
    clims = [min(polPlotParameters.SVDPolResults{4,2}(:)) max(polPlotParameters.SVDPolResults{4,2}(:))];
else
    clims = (colormapRange);
end
if strcmp(polPlotParameters.freqAxis,'Logarithmic')
    surf(polPlotParameters.freqAx,polPlotParameters.SVDPolResults{4,1}(1:end-1),polPlotParameters.SVDPolResults{4,2},'edgecolor','none');
    view(2);
    caxis(clims);
    %     pcolor(polPlotParameters.freqAx,polPlotParameters.SVDPolResults{1,1}(2:end),polPlotParameters.SVDPolResults{1,2})
    %     shading flat
    set(gca,'xscale','log')
else
    imagesc(polPlotParameters.freqAx,polPlotParameters.SVDPolResults{4,1}(1:end-1),polPlotParameters.SVDPolResults{4,2},clims)
    axis xy
end
set(gca,'ylim',[-180 180],'ytick',[-180 -90 0 90 180],'box','on','xlim',polPlotParameters.freqLim)
ylabel('\phi_H_H [deg]')
c = colorbar('position',[.91 1.105-(.19*4+(.25/5)*2) .02 .155]);
temp = c.Limits;
set(c.Label,'string',normHistType,'HorizontalAlignment','center','FontSize',8,'Position',[3 diff(temp)/2 0])
hold on
plot(polPlotParameters.freqAx(colIPhiHH),polPlotParameters.SVDPolResults{4,1}(rowIPhiHH),'pr','markersize',7)
hold off

% Phi VH ------------------------------------------------------------------
axes('units','normalized','position',[.2 1.105-(.19*5+(.25/5)*2) .7 .155])
if strcmpi(colormapRange,'auto')
    clims = [min(polPlotParameters.SVDPolResults{5,2}(:)) max(polPlotParameters.SVDPolResults{5,2}(:))];
else
    clims = (colormapRange);
end
if strcmp(polPlotParameters.freqAxis,'Logarithmic')
    surf(polPlotParameters.freqAx,polPlotParameters.SVDPolResults{5,1}(1:end-1),polPlotParameters.SVDPolResults{5,2},'edgecolor','none');
    view(2);
    caxis(clims);
    %     pcolor(polPlotParameters.freqAx,polPlotParameters.SVDPolResults{1,1}(2:end),polPlotParameters.SVDPolResults{1,2})
    %     shading flat
    set(gca,'xscale','log')
else
    imagesc(polPlotParameters.freqAx,polPlotParameters.SVDPolResults{5,1}(1:end-1),polPlotParameters.SVDPolResults{5,2},clims)
    axis xy
end
set(gca,'ylim',[-90 90],'ytick',[-90 -45 0 45 90],'box','on','xlim',polPlotParameters.freqLim)
xlabel('Frequency [Hz]'); ylabel('\phi_V_H [deg]')
c = colorbar('position',[.91 1.105-(.19*5+(.25/5)*2) .02 .155]);
temp = c.Limits;
set(c.Label,'string',normHistType,'HorizontalAlignment','center','FontSize',8,'Position',[3 diff(temp)/2 0])
hold on
plot(polPlotParameters.freqAx(colIPhiVH),polPlotParameters.SVDPolResults{5,1}(rowIPhiVH),'pr','markersize',7)
hold off

