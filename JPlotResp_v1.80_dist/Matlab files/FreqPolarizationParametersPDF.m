clear; close('all','force'); clc;

%% Open a *.mat file to be processed --------------------------------------
[filename,folder] = uigetfile({'*.mat'},'Select file to be analyzed','MultiSelect', 'off');
if filename == 0
    clear filename folder
    return
end
temp = load([folder filename]);
data = temp.data;
fs = temp.fs;                                                                 % Sampling frequency[Hz]

%% Set processing parameters ----------------------------------------------
trasdConstAcqSystem = 301239990;                                            % Transduction constant of the whole acquisition system [counts/(m/s)]
timeWindow = 20;                                                            % Time window lenght (for averaging) [s]
freqMin = 1/(timeWindow/10);                                                % Minimum admissible frequency [Hz]
overlap = 90;                                                               % Time window overlap (for averaging) [%]
freqAverages = 10;                                                          % Number of averages to compute average frequency spectra
winTapering = 'hamming';                                                    % Time window tapering mask
spectralSmoothing = 'none'; %'KonnoOhmachi'; %none';                        % Spectral smoothing type
fftSample = 2^14;                                                           % Samples of frequency axis (number or 'auto' [== 2^(nextpow2(timeWindowS))])
filtering = 'none';                                                         % {'highpass';'bandpass_unique';'bandpass_tuned'}
% bandPassFilters = 250:-10:50;
bandPassFilters = 90;
% bandPassFilters = [110 180;
%     100 170
%     90 160
%     80 140
%     60 120];
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dt = 1/fs;                                                                  % Sampling interval [s]
timeWindowS = round(timeWindow/dt);                                         % Time window lenght (for averaging) [sample]
overlapS = round((overlap/100)*timeWindowS);

% freqLim = [(1/timeWindow)*10 180]; %fs/2];

%% TAPERING (at the beginnings and at the ends of each recording --------
% % L = length(dataBlock{1}(:,1));
% % tapeWin = tukeywin(L,0.1);
% % tapeMat = repmat(tapeWin,1,3);
% for I = 1:size(fileNamesBlock,1)
%     L = length(dataBlock{I}(:,1));
%     %     dataBlock{I} = dataBlock{I};
%     tapePerc = round(L*0.05);
%     dataBlockNoResp{I} = dataBlockNoResp{I}(tapePerc:L-tapePerc,:);
% end

%% FILTERING
for Ifilt = 1:length(bandPassFilters)
    
    bandPassFiltersTemp = [bandPassFilters(Ifilt)-10 bandPassFilters(Ifilt)+10];
    
    % ZERO-PHASE FILTERING ---------------------------------------------------
    % % Butterwoth Filter
    % Ws = 0.5/((fs/2));
    % Wp = 0.05/((fs/2));
    % [n,Wn] = buttord(Wp,Ws,1,30);
    % [b,a] = butter(n,Wn,'high');
    % for I = 1:size(fileNamesBlock,1)
    %     dataBlockNoResp{I} = filtfilt(b,a,dataBlockNoResp{I});
    %     %     dataBlock{I} = filtfilt(b,a,dataBlock{I});
    % end
    % % dataRockNoResp = filtfilt(b,a,dataRockNoResp);
    % % dataRock = filtfilt(b,a,dataRock);
    % figure
    % freqz(b,a,2048,fs); title('Butterworth Highpass Filter')
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % IIR Filter
    switch(lower(filtering))
        case('highpass')
            for I = 1:size(fileNamesBlock,1)
                %     [dataBlock{I},d] = highpass(dataBlock{I},1,fs,'ImpulseResponse','iir','Steepness',0.95);
                [dataBlockNoResp{I},d] = highpass(dataBlockNoResp{I},.5,fs,'ImpulseResponse','iir','Steepness',0.95);
            end
        case('bandpass_unique')
            for I = 1:size(fileNamesBlock,1)
                [dataBlockNoResp{I},d] = bandpass(dataBlockNoResp{I},bandPassFiltersTemp,fs,'ImpulseResponse','iir','Steepness',0.9);
            end
        case('bandpass_tuned')
            for I = 1:size(fileNamesBlock,1)
                [dataBlockNoResp{I},d] = bandpass(dataBlockNoResp{I},bandPassFilters(I,:),fs,'ImpulseResponse','iir','Steepness',0.95);
            end
    end
    %     % Filter figure
    %     figure
    %     [h1,f] = freqz(d,8192,fs);
    %     plot(f,mag2db(abs(h1)))
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % Muting at the beginning and at the end to discard spurious oscillations due to filtering
    mutePerc = 0.05;
    L = size(data,1);
    tapePerc = round(L*mutePerc);
    data = data(tapePerc:L-tapePerc,:);
    
    %% TIME WINDOW TAPERING MASK ----------------------------------------------
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
    
    %% SPECTRAL SAMPLING AND SMOOTHING ----------------------------------------
    if strcmp(fftSample,'auto')
        fftSample = 2^(nextpow2(timeWindowS));
    end
    df = fs/fftSample;
    freqAx = 0:df:(fftSample/2-1)*df;
    freqMinSample = find(freqAx>freqMin,1,'first');
    %     %     firstFreqIndex = find(freqAx >= freqLim(1),1,'first');
    %     %     if isempty(firstFreqIndex)
    %     %         firstFreqIndex = 2;
    %     %     end
    %     %     lastFreqIndex = find(freqAx >= freqLim(2),1,'first');
    %     %     if isempty(lastFreqIndex)
    %     %         lastFreqIndex = length(freqAx);
    %     %     end
    %     % Smoothing matrix ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    %     if strcmp(spectralSmoothing,'KonnoOhmachi')
    %         b = 40;
    %         konnoOhmachi = zeros(length(freqAx));
    %         for f = 1:length(freqAx)
    %             konnoOhmachi(:,f) = ((sin(b*log10(freqAx/freqAx(f))))./(b*log10(freqAx/freqAx(f)))).^4;
    %         end
    %     end
    
    %% COMP0UTE FREQUENCY POLARIZATION PARAMETERS -------------------------
    winIndexes = 1:(timeWindowS-overlapS):size(data,1)-timeWindowS;
    winNumber = length(winIndexes);
    sizePolPar = floor(winNumber/freqAverages);
    %
    autoSpectX = zeros(fftSample/2,freqAverages);
    autoSpectY = zeros(fftSample/2,freqAverages);
    autoSpectZ = zeros(fftSample/2,freqAverages);
    crossSpectXY = zeros(fftSample/2,freqAverages);
    crossSpectXZ = zeros(fftSample/2,freqAverages);
    crossSpectYZ = zeros(fftSample/2,freqAverages);
    %
    betaSquaredSVDTrace = zeros(sizePolPar,fftSample/2);
    betaSquaredEIG = zeros(sizePolPar,fftSample/2);
    thetaH = zeros(sizePolPar,fftSample/2);
    thetaV = zeros(sizePolPar,fftSample/2);
    phiHH = zeros(sizePolPar,fftSample/2);
    phiVH = zeros(sizePolPar,fftSample/2);
    %
    nWin = 0;
    polParCount = 1;
    while nWin <= winNumber - freqAverages %+ 1
        
        for nSubWin = 1:freqAverages
            dataTemp = data(winIndexes(nWin+nSubWin):winIndexes(nWin+nSubWin)+timeWindowS-1,:).*timeWindowSTape3C;
            eventFreqTemp = fft(dataTemp,fftSample,1);
            autoSpectX(:,nSubWin) = eventFreqTemp(1:fftSample/2,1).*conj(eventFreqTemp(1:fftSample/2,1));
            autoSpectY(:,nSubWin) = eventFreqTemp(1:fftSample/2,2).*conj(eventFreqTemp(1:fftSample/2,2));
            autoSpectZ(:,nSubWin) = eventFreqTemp(1:fftSample/2,3).*conj(eventFreqTemp(1:fftSample/2,3));
            crossSpectXY(:,nSubWin) = eventFreqTemp(1:fftSample/2,1).*conj(eventFreqTemp(1:fftSample/2,2));
            crossSpectXZ(:,nSubWin) = eventFreqTemp(1:fftSample/2,1).*conj(eventFreqTemp(1:fftSample/2,3));
            crossSpectYZ(:,nSubWin) = eventFreqTemp(1:fftSample/2,2).*conj(eventFreqTemp(1:fftSample/2,3));
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
        
        for I = freqMinSample:fftSample/2
            % Compute Singular value decomposition of the spectral density matrix
            [~,S,V] = svd(spectCovMatrix(:,:,I));
            % [~,eigValue] = eig(spectCovMatrix(:,:,I));
            % POLARIZATION PARAMETERS - Degree of polarization ----------------
            % Parameter obtained from the singular values of the spectral density matrix
            betaSquaredSVDTrace(polParCount,I) = (3*trace(S.^2) - (trace(S))^2)/(2*((trace(S))^2));
            % betaSquaredEIG(polParCount,I) = (2*(eigValue(1,1)-eigValue(2,2))^2 + 2*(eigValue(1,1)-eigValue(3,3))^2 + 2*(eigValue(2,2)-eigValue(3,3))^2)/(4*(trace(eigValue))^2);
            % betaSquaredEIGTrace(polParCount,I) = (3*trace(eigValue.^2) - (trace(eigValue))^2)/(2*((trace(eigValue))^2));
            % POLARIZATION PARAMETERS - Polarization angles -------------------
            tempPhaseTerm = exp(1i*2*pi*freqAx(I)*(0:(1/freqAx(I))/500:1/freqAx(I)-(1/freqAx(I))/500));
            % Backazimuth angle
            tempFunct2 = abs(real((sqrt(V(1,1)^2+V(2,1)^2)).*tempPhaseTerm));
            [~,index2] = max(tempFunct2.^2);
            thetaHtemp2 = 2*pi*freqAx(I)*((index2-1)*((1/freqAx(I))/500));
            %         thetaH(I) = atand(real(V(2,1,I)*exp(-1i*thetaHtemp))/real(V(1,1,I)*exp(-1i*thetaHtemp)));               % Range -90°/+90°
            %             thetaH(polParCount,I) = atand((real(V(2,1)*exp(-1i*thetaHtemp2)))/(real(V(1,1)*exp(-1i*thetaHtemp2))));             % Range -90°/+90°
            thetaH(polParCount,I) = mod(atan2d(real(V(2,1)*exp(-1i*thetaHtemp2)),real(V(1,1)*exp(-1i*thetaHtemp2))),360);     % Range 0°/+360°
            % Incident angle
            %             tempFunct3 = abs(real((sqrt(((sqrt(V(1,1)^2+V(2,1)^2)).*exp(-1i*thetaHtemp2))^2+V(3,1)^2)).*tempPhaseTerm));
            tempFunct3 = abs(real(sqrt((sqrt(V(1,1)^2+V(2,1)^2))^2+V(3,1)^2).*tempPhaseTerm));
            [~,index3] = max(tempFunct3.^2);
            thetaVtemp2 = 2*pi*freqAx(I)*((index3-1)*((1/freqAx(I))/500));
            %             thetaVtemp = -0.5*angle(V(3,1)^2+V(1,1)^2+V(2,1)^2) + pi/2;
            thetaV(polParCount,I) = atand(abs((real(V(3,1)*exp(-1i*thetaVtemp2)))/(real((sqrt(V(1,1)^2+V(2,1)^2))*exp(-1i*thetaVtemp2)))));         % 0° means horizontal
            %             thetaV(polParCount,I) = atand(abs((real((sqrt(V(1,1)^2+V(2,1)^2))*exp(-1i*thetaVtemp2)))/(real(V(3,1)*exp(-1i*thetaVtemp2))))); % 90° means horizontal
            % Phase lag between principal horizontal components
            %             phiHH(polParCount,I) = rad2deg(wrapToPi(angle(V(1,1)) - angle(V(2,1))));
            phiHH(polParCount,I) = rad2deg(angle(V(1,1)*V(2,1)));
            % Phase lag between principal horizontal and vertical components
            phiVH(polParCount,I) = rad2deg(thetaHtemp2-angle(V(3,1)));
        end
        polParCount = polParCount + 1;
        nWin = nWin + freqAverages;
    end
    %%
    edgesBeta = 0:.01:1;
    %     edgesThetaH = -90:1:90;
    edgesThetaH = 0:1:360;
    edgesThetaV = 0:1:90;
    edgesPhiHH = -180:1:180;
    edgesPhiVH = -90:1:90;
    %     histBeta = zeros(length(edgesBeta)-1,fftSample/2 - (freqMinSample-1));
    %     histThetaH = zeros(length(edgesThetaH)-1,fftSample/2 - (freqMinSample-1));
    %     histThetaV = zeros(length(edgesThetaV)-1,fftSample/2 - (freqMinSample-1));
    %     histPhiHH = zeros(length(edgesPhiHH)-1,fftSample/2 - (freqMinSample-1));
    %     histPhiVH = zeros(length(edgesPhiVH)-1,fftSample/2 - (freqMinSample-1));
    histBeta = zeros(length(edgesBeta)-1,fftSample/2);
    histThetaH = zeros(length(edgesThetaH)-1,fftSample/2);
    histThetaV = zeros(length(edgesThetaV)-1,fftSample/2);
    histPhiHH = zeros(length(edgesPhiHH)-1,fftSample/2);
    histPhiVH = zeros(length(edgesPhiVH)-1,fftSample/2);
    
    normHistType = 'probability'; %'pdf'; %'count';
    for I = freqMinSample:fftSample/2
        [histBeta(:,I),~] = histcounts(betaSquaredSVDTrace(:,I),edgesBeta,'Normalization',normHistType);
        %             [histBeta(:,I),~] = histcounts(betaSquaredEIG(:,I),edgesBeta,'Normalization',normHistType);
        [histThetaH(:,I),~] = histcounts(thetaH(:,I),edgesThetaH,'Normalization',normHistType);
        [histThetaV(:,I),~] = histcounts(thetaV(:,I),edgesThetaV,'Normalization',normHistType);
        [histPhiHH(:,I),~] = histcounts(phiHH(:,I),edgesPhiHH,'Normalization',normHistType);
        [histPhiVH(:,I),~] = histcounts(phiVH(:,I),edgesPhiVH,'Normalization',normHistType);
    end
    
    
    %% Custom colormap
    cmap(7,:) = [128/255 0 0];   %// color first row - red
    cmap(6,:) = [1 0 0];   %// color 25th row - green
    cmap(5,:) = [1 1 0];   %// color 50th row - blue
    cmap(4,:) = [0 1 1];   %// color 50th row - blue
    cmap(3,:) = [0 0 1];   %// color 50th row - blue
    cmap(2,:) = [0 0 159/255];   %// color 50th row - blue
    cmap(1,:) = [1 1 1];   %// color 50th row - blue
    [X,Y] = meshgrid([1:3],[1:64]);  %// mesh of indices
    cmapDiego = interp2(X([1,5,11,24,40,56,64],:),Y([1,5,11,24,40,56,64],:),cmap,X,Y); %// interpolate colormap
    
    pdfScaling = 1;
    freqAxLimPlot = [2 7];
    figure('units','centimeters','position',[5 3 13 18],'menubar','figure');
    %     colormap(flipud(bone))
    colormap(cmapDiego)
    % 1
    axes('units','normalized','position',[.1 1.105-(.19*1+(.25/5)*2) .8 .155])
    imagesc(freqAx,edgesBeta(1:end-1),histBeta)
    axis xy
    c = colorbar('position',[.91 1.105-(.19*1+(.25/5)*2) .02 .155]);
    temp = c.Limits;
    set(c.Label,'string','Probability','HorizontalAlignment','center','FontSize',8,'Position',[3 diff(temp)/2 0])
    caxis([0 max(histBeta(:))*pdfScaling])
    set(gca,'ylim',[0 1.05],'ytick',[0 .2 .4 .6 .8 1],'box','on','xlim',freqAxLimPlot)
    ylabel('\beta^2 [-]')
    title(['FFTs ' num2str(fftSample) '; Tw ' num2str(timeWindow) 's; Taper ' winTapering '; SpectSmooth ' spectralSmoothing '; Filt ' filtering])
    % 2
    axes('units','normalized','position',[.1 1.105-(.19*2+(.25/5)*2) .8 .155])
    imagesc(freqAx,edgesThetaH(1:end-1),histThetaH)
    axis xy
    c = colorbar('position',[.91 1.105-(.19*2+(.25/5)*2) .02 .155]);
    temp = c.Limits;
    set(c.Label,'string','Probability','HorizontalAlignment','center','FontSize',8,'Position',[3 diff(temp)/2 0])
    caxis([0 max(histThetaH(:))*pdfScaling])
    set(gca,'ylim',[0 360],'ytick',[0 90 180 270 360],'box','on','xlim',freqAxLimPlot)
    %     set(gca,'ylim',[-90 90],'ytick',[-90 -45 0 45 90],'box','on','xlim',[0 freqAx(fftSample/2)])
    ylabel('\Theta_H [deg]')
    % 3
    axes('units','normalized','position',[.1 1.105-(.19*3+(.25/5)*2) .8 .155])
    imagesc(freqAx,edgesThetaV(1:end-1),histThetaV)
    axis xy
    c = colorbar('position',[.91 1.105-(.19*3+(.25/5)*2) .02 .155]);
    temp = c.Limits;
    set(c.Label,'string','Probability','HorizontalAlignment','center','FontSize',8,'Position',[3 diff(temp)/2 0])
    caxis([0 max(histThetaV(:))*pdfScaling])
    set(gca,'ylim',[0 90],'ytick',[0 30 60 90],'box','on','xlim',freqAxLimPlot)
    ylabel('\Theta_V [deg]')
    % 4
    axes('units','normalized','position',[.1 1.105-(.19*4+(.25/5)*2) .8 .155])
    imagesc(freqAx,edgesPhiHH(1:end-1),histPhiHH)
    axis xy
    c = colorbar('position',[.91 1.105-(.19*4+(.25/5)*2) .02 .155]);
    temp = c.Limits;
    set(c.Label,'string','Probability','HorizontalAlignment','center','FontSize',8,'Position',[3 diff(temp)/2 0])
    caxis([0 max(histPhiHH(:))*pdfScaling])
    set(gca,'ylim',[-180 180],'ytick',[-180 -90 0 90 180],'box','on','xlim',freqAxLimPlot)
    ylabel('\phi_H_H [deg]')
    % 5
    axes('units','normalized','position',[.1 1.105-(.19*5+(.25/5)*2) .8 .155])
    imagesc(freqAx,edgesPhiVH(1:end-1),histPhiVH)
    axis xy
    c = colorbar('position',[.91 1.105-(.19*5+(.25/5)*2) .02 .155]);
    temp = c.Limits;
    set(c.Label,'string','Probability','HorizontalAlignment','center','FontSize',8,'Position',[3 diff(temp)/2 0])
    caxis([0 max(histPhiVH(:))*pdfScaling])
    set(gca,'ylim',[-90 90],'ytick',[-90 -45 0 45 90],'box','on','xlim',freqAxLimPlot)
    xlabel('Frequency [Hz]'); ylabel('\phi_V_H [deg]')
    
    %%
    
    %     phiVH2 = phiVH;
    %
    %     indexTemp = find((phiVH>90).*(phiVH<=180));
    %     phiVH2(indexTemp) = -180+phiVH(indexTemp);
    %     indexTemp = find((phiVH>180).*(phiVH<270));
    %     phiVH2(indexTemp) = 270 - phiVH(indexTemp);
    %     indexTemp = find((phiVH>270).*(phiVH<=360));
    %     phiVH2(indexTemp) = -360+phiVH(indexTemp);
    %     indexTemp = find((phiVH<-90).*(phiVH>=-180));
    %     phiVH2(indexTemp) = 180+phiVH(indexTemp);
    %     indexTemp = find((phiVH<-180).*(phiVH>-270));
    %     phiVH2(indexTemp) = 270+phiVH(indexTemp);
    %     indexTemp = find((phiVH<-270).*(phiVH>=-360));
    %     phiVH2(indexTemp) = 360+phiVH(indexTemp);
    %     phiVH2(phiVH2 == 270) = 90;
    %     phiVH2(phiVH2 == -270) = -90;
    %
    %     indexBeta = ones(size(betaSquaredSVDTrace))*NaN;
    %     indexBeta(betaSquaredSVDTrace <= 0.95) = 1;
    %
    %
    %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     % FIGURE POLARIZATION PARAMETERS
    %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     figure('units','centimeters','position',[5 3 17.4 15],'menubar','figure');
    %     %
    %     axes('units','normalized','position',[.065 1.015-(.15*1+(.25/6)*1) .915 .155])
    %     hold on
    %     plot(freqAx,betaSquaredSVDTrace,'-r')
    %     plot(freqAx,betaSquaredSVDTrace.*indexBeta,'color',[.85 .85 .85],'linewidth',1)
    %     hold off
    %     set(gca,'ylim',[0 1],'ytick',[0 .2 .4 .6 .8 1],'box','on')
    %     ylabel('\beta^2 [-]')
    %     title(['FFTsample: ' num2str(fftSample) '; Tw: ' num2str(timeWindow) 's; Taper: ' winTapering '; SpectSmooth: ' spectralSmoothing '; Filter: ' filtering])
    %     %
    %     axes('units','normalized','position',[.065 1.015-(.15*2+(.25/6)*2) .915 .155])
    %     hold on
    %     plot(freqAx,thetaH,'-r','linewidth',1)
    %     plot(freqAx,thetaH.*indexBeta,'color',[.85 .85 .85],'linewidth',1)
    %     hold off
    %     set(gca,'ylim',[0 360],'ytick',[0 90 180 270 360],'box','on')
    %     ylabel('\Theta_H [deg]')
    %     %
    %     axes('units','normalized','position',[.065 1.015-(.15*3+(.25/6)*3) .915 .155])
    %     hold on
    %     plot(freqAx,phiHH,'-r','linewidth',1)
    %     plot(freqAx,phiHH.*indexBeta,'color',[.85 .85 .85],'linewidth',1)
    %     hold off
    %     set(gca,'ylim',[-180 180],'ytick',[-180 -90 0 90 180],'box','on')
    %     ylabel('\phi_H_H [deg]')
    %     %
    %     axes('units','normalized','position',[.065 1.015-(.15*4+(.25/6)*4) .915 .155])
    %     hold on
    %     plot(freqAx,thetaV,'-r','linewidth',1)
    %     plot(freqAx,thetaV.*indexBeta,'color',[.85 .85 .85],'linewidth',1)
    %     hold off
    %     set(gca,'ylim',[0 90],'ytick',[0 30 60 90],'box','on')
    %     ylabel('\Theta_V [deg]')
    %     %
    %     axes('units','normalized','position',[.065 1.015-(.15*5+(.25/6)*5) .915 .155])
    %     hold on
    %     plot(freqAx,phiVH2,'-r','linewidth',1)
    %     plot(freqAx,phiVH2.*indexBeta,'linestyle','-','color',[.85 .85 .85],'linewidth',1)
    %     hold off
    %     set(gca,'ylim',[-90 90],'ytick',[-90 -45 0 45 90],'box','on')
    %     xlabel('Frequency [Hz]'); ylabel('\phi_V_H [deg]')
    
    
    
    %% PRINCIPAL COMPONENT ANALYSIS -------------------------------------------
    %     [coeff,score,latent,tsquared,explained,mu] = pca(data);
    [coeff,score,latent,~,explained,~] = pca(data);
    %     % Rotation of the PCA eigenvectors ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    %     rotatedCoeffV = rotatefactors(coeff(:,1:2));
    %     rotatedCoeffP = rotatefactors(coeff(:,1:3),'Method','promax');
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% FIGURES
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % %% FIGURES WITH TIME SERIES -----------------------------------------------
    % timeAx = 0:dt:(length(dataBlockRaw{1}(:,1))-1)*dt;
    % % Figure with Raw Data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % figure
    % subplot(311)
    % hold on
    % plot(timeAx,dataBlockRaw{1}(:,1)/trasdConstAcqSystem,'-k');
    % plot(timeAx,dataBlockNoRespRaw{1}(:,1),'-r');
    % hold off
    % subplot(312)
    % hold on
    % plot(timeAx,dataBlockRaw{1}(:,2)/trasdConstAcqSystem,'-k');
    % plot(timeAx,dataBlockNoRespRaw{1}(:,2),'-g');
    % hold off
    % subplot(313)
    % hold on
    % plot(timeAx,dataBlockRaw{1}(:,3)/trasdConstAcqSystem,'-k');
    % plot(timeAx,dataBlockNoRespRaw{1}(:,3),'-b');
    % hold off
    % % Figure with Filtered Data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % % figure('units','centimeters','position',[5 3 19 7],'menubar','figure','toolbar','none')
    % figure
    % % axSize = .2;
    % counter = 1;
    % for I = 1:size(fileNamesBlock,1)
    %     %     axes('units','normalized','position',[.1+(I-1)*axSize .3 axSize axSize],'FontUnits','points','fontsize',8,'FontName','Arial')
    %     subplot(5,1,counter)
    %     timeAx = 0:dt:(length(dataBlockNoResp{I}(:,1))-1)*dt;
    %     hold on
    %     plot(timeAx,dataBlockNoResp{I}(:,1),'-r');
    %     plot(timeAx,dataBlockNoResp{I}(:,2),'-g');
    %     plot(timeAx,dataBlockNoResp{I}(:,3),'-b');
    %     %     set(gca,'xlim',[],'ylim',[])
    %     xlabel('Time');ylabel('Amp');
    %     counter = counter +1;
    % end
    
    %% FIGURES WITH HODOGRAMS AND EIGENVECTORS --------------------------------
    %     figure('Name',['Filter ' num2str(bandPassFiltersTemp) 'Hz'])
    figure
    scaleFactor = 1e6;                                                          % Unit conversione from [m/s] to [mum/s]
    axLimit = 1.5e-7*scaleFactor;
    % Figure with eigenvectors not scaled ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    
    data = data*scaleFactor;
    %     axes('units','normalized','position',[.1+(I-1)*axSize .3 axSize axSize],'FontUnits','points','fontsize',8,'FontName','Arial')
    subplot(131)
    plot(data(:,1),data(:,2),'color',[.7 .7 .7]);
    hold on
    hleg(1) = plot([-coeff(1,1) coeff(1,1)],[-coeff(2,1) coeff(2,1)],'-r','linewidth',2);
    hleg(2) = plot([-coeff(1,2) coeff(1,2)],[-coeff(2,2) coeff(2,2)],'--g','linewidth',2);
    hleg(3) = plot([-coeff(1,3) coeff(1,3)],[-coeff(2,3) coeff(2,3)],':b','linewidth',2);
    %     % Rotated eigenvectors
    %     plot([-rotatedCoeffV(1,1,I) rotatedCoeffV(1,1,I)],[-rotatedCoeffV(2,1,I) rotatedCoeffV(2,1,I)],'--r','linewidth',1);
    %     plot([-rotatedCoeffV(1,2,I) rotatedCoeffV(1,2,I)],[-rotatedCoeffV(2,2,I) rotatedCoeffV(2,2,I)],'--g','linewidth',1);
    %     %     plot([-rotatedCoeff(1,3,I) rotatedCoeff(1,3,I)],[-rotatedCoeff(2,3,I) rotatedCoeff(2,3,I)],'--b','linewidth',1);
    %     plot([-rotatedCoeffP(1,1,I) rotatedCoeffP(1,1,I)],[-rotatedCoeffP(2,1,I) rotatedCoeffP(2,1,I)],':r','linewidth',2);
    %     plot([-rotatedCoeffP(1,2,I) rotatedCoeffP(1,2,I)],[-rotatedCoeffP(2,2,I) rotatedCoeffP(2,2,I)],':g','linewidth',2);
    %     plot([-rotatedCoeffP(1,3,I) rotatedCoeffP(1,3,I)],[-rotatedCoeffP(2,3,I) rotatedCoeffP(2,3,I)],':b','linewidth',2);
    hold off
    axis equal
    set(gca,'xlim',[-axLimit axLimit],'ylim',[-axLimit axLimit],'FontUnits','points','fontsize',7,'FontName','Arial')
    xlabel('\bfE [\mum/s]');ylabel('\bfN  [\mum/s]');
    
    legend(hleg,['Expl. Var: ' num2str(explained(1),'%2.1f') '%'],[num2str(explained(2),'%2.1f') '%'],[num2str(explained(3),'%2.1f') '%'])
    subplot(132)
    plot(data(:,1),data(:,3),'color',[.7 .7 .7]);
    hold on
    plot([-coeff(1,1) coeff(1,1)],[-coeff(3,1) coeff(3,1)],'-r','linewidth',2);
    plot([-coeff(1,2) coeff(1,2)],[-coeff(3,2) coeff(3,2)],'--g','linewidth',2);
    plot([-coeff(1,3) coeff(1,3)],[-coeff(3,3) coeff(3,3)],':b','linewidth',2);
    %     % Rotated eigenvectors
    %     plot([-rotatedCoeffV(1,1,I) rotatedCoeffV(1,1,I)],[-rotatedCoeffV(3,1,I) rotatedCoeffV(3,1,I)],'--r','linewidth',1);
    %     plot([-rotatedCoeffV(1,2,I) rotatedCoeffV(1,2,I)],[-rotatedCoeffV(3,2,I) rotatedCoeffV(3,2,I)],'--g','linewidth',1);
    %     %     plot([-rotatedCoeff(1,3,I) rotatedCoeff(1,3,I)],[-rotatedCoeff(3,3,I) rotatedCoeff(3,3,I)],'--b','linewidth',1);
    %     plot([-rotatedCoeffP(1,1,I) rotatedCoeffP(1,1,I)],[-rotatedCoeffP(3,1,I) rotatedCoeffP(3,1,I)],':r','linewidth',2);
    %     plot([-rotatedCoeffP(1,2,I) rotatedCoeffP(1,2,I)],[-rotatedCoeffP(3,2,I) rotatedCoeffP(3,2,I)],':g','linewidth',2);
    %     plot([-rotatedCoeffP(1,3,I) rotatedCoeffP(1,3,I)],[-rotatedCoeffP(3,3,I) rotatedCoeffP(3,3,I)],':b','linewidth',2);
    hold off
    axis equal
    set(gca,'xlim',[-axLimit axLimit],'ylim',[-axLimit axLimit],'FontUnits','points','fontsize',7,'FontName','Arial')
    xlabel('\bfE [\mum/s]');ylabel('\bfZ  [\mum/s]');
    subplot(133)
    plot(data(:,2),data(:,3),'color',[.7 .7 .7]);
    hold on
    plot([-coeff(2,1) coeff(2,1)],[-coeff(3,1) coeff(3,1)],'-r','linewidth',2);
    plot([-coeff(2,2) coeff(2,2)],[-coeff(3,2) coeff(3,2)],'--g','linewidth',2);
    plot([-coeff(2,3) coeff(2,3)],[-coeff(3,3) coeff(3,3)],':b','linewidth',2);
    %     % Rotated eigenvectors
    %     plot([-rotatedCoeffV(2,1,I) rotatedCoeffV(2,1,I)],[-rotatedCoeffV(3,1,I) rotatedCoeffV(3,1,I)],'--r','linewidth',1);
    %     plot([-rotatedCoeffV(2,2,I) rotatedCoeffV(2,2,I)],[-rotatedCoeffV(3,2,I) rotatedCoeffV(3,2,I)],'--g','linewidth',1);
    %     %     plot([-rotatedCoeff(2,3,I) rotatedCoeff(2,3,I)],[-rotatedCoeff(3,3,I) rotatedCoeff(3,3,I)],'--b','linewidth',1);
    %     plot([-rotatedCoeffP(2,1,I) rotatedCoeffP(2,1,I)],[-rotatedCoeffP(3,1,I) rotatedCoeffP(3,1,I)],':r','linewidth',2);
    %     plot([-rotatedCoeffP(2,2,I) rotatedCoeffP(2,2,I)],[-rotatedCoeffP(3,2,I) rotatedCoeffP(3,2,I)],':g','linewidth',2);
    %     plot([-rotatedCoeffP(2,3,I) rotatedCoeffP(2,3,I)],[-rotatedCoeffP(3,3,I) rotatedCoeffP(3,3,I)],':b','linewidth',2);
    hold off
    axis equal
    set(gca,'xlim',[-axLimit axLimit],'ylim',[-axLimit axLimit],'FontUnits','points','fontsize',7,'FontName','Arial')
    xlabel('\bfN [\mum/s]');ylabel('\bfZ  [\mum/s]');
    
end

%     % Figure with scaled eigenvectors ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%     figure('Name',['Filter ' num2str(bandPassFiltersTemp) 'Hz'])
%     vectAmplifier = 20;                                                         % Scale factor to be applied to the explained variance of the eigenvectors for plotting purpouses
%     counter = 1;
%     for I = 1:size(fileNamesBlock,1)
%         dataBlockNoResp{I} = dataBlockNoResp{I}*scaleFactor;
%         xComp1 = vectAmplifier*scaleFactor*sqrt(latent(1,I))*coeff(1,1,I);
%         yComp1 = vectAmplifier*scaleFactor*sqrt(latent(1,I))*coeff(2,1,I);
%         zComp1 = vectAmplifier*scaleFactor*sqrt(latent(1,I))*coeff(3,1,I);
%         xComp2 = vectAmplifier*scaleFactor*sqrt(latent(2,I))*coeff(1,2,I);
%         yComp2 = vectAmplifier*scaleFactor*sqrt(latent(2,I))*coeff(2,2,I);
%         zComp2 = vectAmplifier*scaleFactor*sqrt(latent(2,I))*coeff(3,2,I);
%         xComp3 = vectAmplifier*scaleFactor*sqrt(latent(3,I))*coeff(1,3,I);
%         yComp3 = vectAmplifier*scaleFactor*sqrt(latent(3,I))*coeff(2,3,I);
%         zComp3 = vectAmplifier*scaleFactor*sqrt(latent(3,I))*coeff(3,3,I);
%         %     axes('units','normalized','position',[.1+(I-1)*axSize .3 axSize axSize],'FontUnits','points','fontsize',8,'FontName','Arial')
%         subplot(3,5,counter)
%         plot(dataBlockNoResp{I}(:,1),dataBlockNoResp{I}(:,2),'color',[.7 .7 .7]);
%         hold on
%         hleg(1) = plot([-xComp1 xComp1],[-yComp1 yComp1],'-r','linewidth',2);
%         hleg(2) = plot([-xComp2 xComp2],[-yComp2 yComp2],'-g','linewidth',2);
%         hleg(3) = plot([-xComp3 xComp3],[-yComp3 yComp3],'-b','linewidth',2);
%         hold off
%         axis equal
%         set(gca,'xlim',[-axLimit axLimit],'ylim',[-axLimit axLimit],'FontUnits','points','fontsize',7,'FontName','Arial')
%         xlabel('\bfE [\mum/s]');ylabel('\bfN  [\mum/s]');
%         title(['\bfSTAGE ' num2str(I-1)])
%         legend(hleg,['Expl. Var: ' num2str(explained(1,I),'%2.1f') '%'],[num2str(explained(2,I),'%2.1f') '%'],[num2str(explained(3,I),'%2.1f') '%'])
%         subplot(3,5,counter+5)
%         plot(dataBlockNoResp{I}(:,1),dataBlockNoResp{I}(:,3),'color',[.7 .7 .7]);
%         hold on
%         plot([-xComp1 xComp1],[-zComp1 zComp1],'-r','linewidth',2);
%         plot([-xComp2 xComp2],[-zComp2 zComp2],'-g','linewidth',2);
%         plot([-xComp3 xComp3],[-zComp3 zComp3],'-b','linewidth',2);
%         hold off
%         axis equal
%         set(gca,'xlim',[-axLimit axLimit],'ylim',[-axLimit axLimit],'FontUnits','points','fontsize',7,'FontName','Arial')
%         xlabel('\bfE [\mum/s]');ylabel('\bfZ  [\mum/s]');
%         subplot(3,5,counter+10)
%         plot(dataBlockNoResp{I}(:,2),dataBlockNoResp{I}(:,3),'color',[.7 .7 .7]);
%         hold on
%         plot([-yComp1 yComp1],[-zComp1 zComp1],'-r','linewidth',2);
%         plot([-yComp2 yComp2],[-zComp2 zComp2],'-g','linewidth',2);
%         plot([-yComp3 yComp3],[-zComp3 zComp3],'-b','linewidth',2);
%         hold off
%         axis equal
%         set(gca,'xlim',[-axLimit axLimit],'ylim',[-axLimit axLimit],'FontUnits','points','fontsize',7,'FontName','Arial')
%         xlabel('\bfN [\mum/s]');ylabel('\bfZ  [\mum/s]');
%         counter = counter +1;
%     end

