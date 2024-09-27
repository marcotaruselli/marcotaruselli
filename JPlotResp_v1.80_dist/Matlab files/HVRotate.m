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

% data = data(1:360000,:);  % Sirotti 20170214
% data = data(80000:500000,:);  % Sirotti 20170728

%% Set processing parameters ----------------------------------------------
trasdConstAcqSystem = 301239990;                                            % Transduction constant of the whole acquisition system [counts/(m/s)]
timeWindow = 20;                                                            % Time window lenght (for averaging) [s]
freqMin = 1/(timeWindow/10);                                                % Minimum admissible frequency [Hz]
overlap = 90;                                                               % Time window overlap (for averaging) [%]
freqAverages = 10;                                                          % Number of averages to compute average frequency spectra
winTapering = 'hamming';                                                    % Time window tapering mask
spectralSmoothing = 'none'; %'KonnoOhmachi'; %none';                        % Spectral smoothing type
fftSample = 2^16;                                                           % Samples of frequency axis (number or 'auto' [== 2^(nextpow2(timeWindowS))])
filtering = 'none';                                                         % {'highpass';'bandpass_unique';'bandpass_tuned'}
% bandPassFilters = 250:-10:50;
bandPassFilters = 90;
% bandPassFilters = [110 180;
%     100 170
%     90 160
%     80 140
%     60 120];
nAngles = 50;                                                               % Samples of theta axis (divide pi by this number)
colormapRange = [0 15];
freqCircles = [10 50 100];
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
dt = 1/fs;                                                                  % Sampling interval [s]
timeWindowS = round(timeWindow/dt);                                         % Time window lenght (for averaging) [sample]
overlapS = round((overlap/100)*timeWindowS);
thetaAx = 0:pi/nAngles:pi;
freqLim = [freqMin 7]; %fs/2];





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
    firstFreqIndex = find(freqAx >= freqLim(1),1,'first');
    if isempty(firstFreqIndex)
        firstFreqIndex = 2;
    end
    lastFreqIndex = find(freqAx >= freqLim(2),1,'first');
    if isempty(lastFreqIndex)
        lastFreqIndex = length(freqAx);
    end
    % Smoothing matrix ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if strcmp(spectralSmoothing,'KonnoOhmachi')
        b = 40;
        konnoOhmachi = zeros(length(freqAx));
        for f = 1:length(freqAx)
            konnoOhmachi(:,f) = ((sin(b*log10(freqAx/freqAx(f))))./(b*log10(freqAx/freqAx(f)))).^4;
        end
    end
    
    
    %% HVSR AS A FUNCTION OF AZIMUTH ------------------------------------------
    
    winNumber = floor(size(data,1)/timeWindowS);
    timeWindowsTapeMatrix = repmat(timeWindowSTape,1,winNumber);
    verticalMatrix = reshape(data(1:timeWindowS*winNumber,3),timeWindowS,winNumber);
    verticalMatrix = verticalMatrix.*timeWindowsTapeMatrix;
    verticalMatrixF = abs(fft(verticalMatrix,fftSample,1));
    verticalMatrixF(fftSample/2 + 1:end,:) = [];
    rotatedHVSRMeanTemp = zeros(fftSample/2,length(thetaAx));
    %     rotatedHVSRStd = zeros(fftSample/2,length(angRotation));
    for KK = 1:length(thetaAx)
        radialComp = data(:,1)*cos(thetaAx(KK)) + data(:,2)*sin(thetaAx(KK));
        radialMatrix = reshape(radialComp(1:timeWindowS*winNumber),timeWindowS,winNumber);
        radialMatrix = radialMatrix.*timeWindowsTapeMatrix;
        radialMatrixF = abs(fft(radialMatrix,fftSample,1));
        radialMatrixF(fftSample/2 + 1:end,:) = [];
        %         rotatedHVSR = radialMatrixF./verticalMatrixF;
        rotatedHVSR = zeros(fftSample/2,winNumber);
        if strcmp(spectralSmoothing,'KonnoOhmachi')
            for K = 1:winNumber
                radialTempF = sum(repmat(radialMatrixF(:,K),1,fftSample/2).*konnoOhmachi,1,'omitnan');
                verticalTempF = sum(repmat(verticalMatrixF(:,K),1,fftSample/2).*konnoOhmachi,1,'omitnan');
                rotatedHVSR(:,K) = radialTempF./verticalTempF;              % Spectral ratio H/V
            end
        elseif strcmp(spectralSmoothing,'none')
            for K = 1:winNumber
                rotatedHVSR(:,K) = radialMatrixF(:,K)./verticalMatrixF(:,K); % Spectral ratio H/V
            end
        end
        % Mean and Std of H/V
        %         HoverVMean = mean(HoverV,2);                              % Aritmetic mean (influenzata da valori lontani dalla media)
        rotatedHVSRMeanTemp(:,KK) = geomean(rotatedHVSR,2);                 % Geometric mean (molto influenzata da valori bassi, meno influenzata da valori alti)
        %         rotatedHVSRStd(:,KK) = std(rotatedHVSR,0,2);
    end
    
    rotatedHVSRMean = [rotatedHVSRMeanTemp rotatedHVSRMeanTemp(:,2:end)];
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% FIGURES
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    thetaAx = [thetaAx pi+pi/nAngles:pi/nAngles:2*pi];
    
    % Cartesian Plot of HVSR Vs Azimuth - linear frequency axis ~~~~~~~~~~~~~~~
    figure('units','centimeters','position',[5 3 17.4 15],'menubar','figure');
    [X,Y] = meshgrid(freqAx,180*(thetaAx/pi));
    
    %     axes('units','normalized','position',[.055 1.015-(.15*I+(.25/6)*I) .43 .15])
    surf(X,Y,rotatedHVSRMean','edgecolor','none');
    view(2);
    caxis(colormapRange)
    colormap(jet)
    colorbar
    set(gca,'xlim',[freqLim(1) freqLim(2)],'ylim',[0 180*(thetaAx(end))/pi],'tickdir','out','ticklength',[.005 .005],...
        'box','on','FontUnits','points','fontsize',7,'FontName','Arial','ylim',[0 180])
    %     title(['STAGE ' num2str(I-1)],'fontweight','bold')
    %     if I == size(cutFileNames1,1)
    %         xlabel('Frequency [Hz]')
    %         title(cutFileNames1{I}(10:16),'fontweight','bold')
    %     end
    ylabel('HVSR [-]');
    %     if not(I == size(cutFileNames1,1))
    %         set(gca,'xticklabel',[]);
    %     end
    
    
    % Cartesian Plot of HVSR Vs Azimuth - logarithmic frequency axis ~~~~~~~~~~
    fig = figure('units','centimeters','position',[5 3 17.4 15],'menubar','figure');
    %     axes('units','normalized','position',[.055 1.015-(.15*I+(.25/6)*I) .43 .15])
    surf(X,Y,rotatedHVSRMean','edgecolor','none');
    view(2);
    caxis(colormapRange)
    colormap(jet)
    colorbar
    set(gca,'xscale','log','xlim',[freqLim(1) freqLim(2)],'ylim',[0 180*(thetaAx(end))/pi],'tickdir','out','ticklength',[.005 .005],... % ,'xlim',FreqLim,
        'box','on','FontUnits','points','fontsize',7,'FontName','Arial','ylim',[0 180])
    %     title(['STAGE ' num2str(I-1)],'fontweight','bold')
    %     if I == size(cutFileNames1,1)
    %         xlabel('Frequency [Hz]')
    %         title(cutFileNames1{I}(10:16),'fontweight','bold')
    %     end
    ylabel('HVSR [-]');
    %     if not(I == size(cutFileNames1,1))
    %         set(gca,'xticklabel',[]);
    %     end
    
    
    %% POLAR FIGURES ----------------------------------------------------------
    [THETA,RR] = meshgrid(thetaAx,freqAx(firstFreqIndex:lastFreqIndex));
    [A,B] = pol2cart(THETA,RR);
    %
    circleSize = .45;
    for I = 1:length(freqCircles)
        freqCirclesLabels{I} = [num2str(freqCircles(I)) 'Hz'];
    end
    % Polar Plot of HVSR Vs Azimuth - linear frequency axis ~~~~~~~~~~~~~~~~~~~
    figure('units','centimeters','position',[5 3 19 7],'menubar','figure','toolbar','none')
    
    axes('units','normalized','position',[-0.124+(0.2*(3-1)) .3 circleSize circleSize],'FontUnits','points','fontsize',8,'FontName','timesnewroman')
    surf(A,B,rotatedHVSRMean(firstFreqIndex:lastFreqIndex,:),'edgecolor','none');
    caxis(colormapRange)
    colormap(jet)
    view(0,90)
    axis tight
    axis equal
    set(gca,'visible','off')
    % Colorbar
    colHandle = colorbar('southoutside');
    set(colHandle,'units','normalized','position',[.3 .08 .4 .03],'ticks',[0 5 10 15 20],...
        'ticklabels',{'0';'5';'10';'15';'20'},'fontsize',8,'FontName','timesnewroman')
    % Set and correct polar axes
    axes('units','normalized','position',[-0.124+(0.2*(3-1)) .3 circleSize circleSize],'color','none','FontUnits','points','fontsize',8,'FontName','timesnewroman')
    polarplot([],[]);
    set(gca,'color','none','ThetaTickLabel',{'\fontsize{8}E','','','\fontsize{8}N','','','\fontsize{8}W','','','\fontsize{8}S','',''})
    set(gca,'rlim',[0 freqAx(lastFreqIndex)],'RColor',[1 1 1],'RTick',freqCircles,'RTickLabels',freqCirclesLabels,...
        'linewidth',1,'gridlinestyle','-','gridcolor','w','gridalpha',0.6,...
        'fontsize',7,'fontweight','bold')
    %         title(['STAGE ' num2str(I-1)])
    
    
    
    %% POLAR IMAGE WITH LOGARITHMIC FREQUENCY AXIS ----------------------------
    % Factor used to multiply frequency axis values in order to avoid negative
    % values in the logarithmic frequency axis that would mess the polar plot up
    minCorrFactorLogFreqPlot = 1/freqLim(1);
    corrFactorLogFreqPlot = minCorrFactorLogFreqPlot*1.5;
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    freqAxLog = log10(corrFactorLogFreqPlot*freqAx(firstFreqIndex:lastFreqIndex));
    [THETA,RRLog] = meshgrid(thetaAx,freqAxLog);
    [X,Y] = pol2cart(THETA,RRLog);
    freqCircles = corrFactorLogFreqPlot*[1 5 10 50 100];
    for I = 1:length(freqCircles)
        freqCirclesLabels{I} = [num2str(freqCircles(I)/corrFactorLogFreqPlot) 'Hz'];
    end
    % Polar Plot of HVSR Vs Azimuth - logarithmic frequency axis ~~~~~~~~~~~~~~
    figure('units','centimeters','position',[5 3 19 7],'menubar','figure','toolbar','none')
    
    axes('units','normalized','position',[-0.124+(0.2*(3-1)) .3 circleSize circleSize],'FontUnits','points','fontsize',8,'FontName','timesnewroman')
    surf(X,Y,rotatedHVSRMean(firstFreqIndex:lastFreqIndex,:),'edgecolor','none');
    caxis(colormapRange)
    colormap(jet)
    view(0,90)
    axis tight
    axis equal
    set(gca,'visible','off')
    % Colorbar
    colHandle = colorbar('southoutside');
    set(colHandle,'units','normalized','position',[.3 .08 .4 .03],'ticks',[0 5 10 15 20],...
        'ticklabels',{'0';'5';'10';'15';'20'},'fontsize',8,'FontName','timesnewroman')
    % Set and correct polar axes
    axes('units','normalized','position',[-0.124+(0.2*(3-1)) .3 circleSize circleSize],'color','none','FontUnits','points','fontsize',8,'FontName','timesnewroman')
    polarplot([],[]);
    set(gca,'color','none','ThetaTickLabel',{'\fontsize{8}E','','','\fontsize{8}N','','','\fontsize{8}W','','','\fontsize{8}S','',''})
    set(gca,'rlim',[0 1],'RColor',[1 1 1],'RTick',log10(freqCircles)/max(freqAxLog),'RTickLabels',freqCirclesLabels,...
        'linewidth',1,'gridlinestyle','-','gridcolor','w','gridalpha',0.6,...
        'fontsize',7,'fontweight','bold')
    %         title(['STAGE ' num2str(I-1)])
    
end

% % Save figure -----------------------------------------------------------
% rez = 300;                                                                 % resolution (dpi) of final graphic
% f = gcf;
% figpos = getpixelposition(f);
% resolution = get(0,'ScreenPixelsPerInch');
% set(f,'paperunits','inches','papersize',figpos(3:4)/resolution,'paperposition',[0 0 figpos(3:4)/resolution]);
% path = 'C:\Users\Diego\Desktop\';
% name = 'spectRotate';
% print(f,fullfile(path,name),'-dtif',['-r',num2str(rez)],'-opengl')
