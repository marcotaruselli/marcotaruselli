    % function PolHVRotate(plotUpdate,data,fs,timeWin,winOverlap,winTapering,nFFT,spectralSmoothing,nAngles)

function PolHRotate(plotUpdate,varargin)

global mainPolFig
global polPlotParameters
% global rotatedHVSRMean
global cmapwbr

%% Attivare gli assi con i segnali plottati
asse = findobj(mainPolFig,'type','axes','tag','comp_x');
set(asse,'visible','on')
dataObjs = get(asse, 'Children');
dataObjs.LineStyle = '-';
asse = findobj(mainPolFig,'type','axes','tag','comp_y');
set(asse,'visible','on')
dataObjs = get(asse, 'Children');
dataObjs.LineStyle = '-';
asse = findobj(mainPolFig,'type','axes','tag','comp_z');
set(asse,'visible','on')
dataObjs = get(asse, 'Children');
dataObjs.LineStyle = '-';
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
    nAngles = varargin{9};
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    dt = 1/fs;                                                                  % Sampling interval [s]
    timeWindowS = round(timeWin/dt);                                         % Time window lenght (for averaging) [sample]
    overlapS = round((winOverlap/100)*timeWindowS);
    thetaAx = 0:pi/nAngles:pi;
    
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
    
    %% SPECTRAL SAMPLING AND SMOOTHING ----------------------------------------
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
    
    %% --------------------------------------------------------------------
    winIndexes = 1:(timeWindowS-overlapS):size(data,1)-timeWindowS;
    if overlapS == 0
        winNumber = floor(size(data,1)/timeWindowS);
    else
        winNumber = 0;
        for winIndex = 1:(timeWindowS-overlapS):size(data,1)-timeWindowS
            winNumber = winNumber+1;
        end
    end
    timeWindowsTapeMatrix = repmat(timeWindowSTape,1,winNumber);            % Tapering
    
    %% PROCESS RADIAL COMPONENT AND COMPUTE HVSRA -------------------------
    radialMatrix = zeros(timeWindowS,winNumber);
    rotatedH = zeros(nFFTRange,winNumber);
    rotatedHMeanTemp = zeros(nFFTRange,length(thetaAx));
    %
    switch spectralSmoothing
        case('KonnoOhmachi')
            b = str2double(get(findobj(mainPolFig,'tag','ko_b_value'),'string'));
            konnoOhmachi = zeros(nFFTRange);
            % Compute KonnoOhmachi smoothing matrix -----------------------
            counter = 1;
            for f = firstFreqIndex:lastFreqIndex
                konnoOhmachi(:,counter) = ((sin(b*log10(freqAx/freqAx(f))))./(b*log10(freqAx/freqAx(f)))).^4;
                counter = counter + 1;
            end
            konnoOhmachi(isnan(konnoOhmachi)) = 0;                          % Faster
            %
            radialTempFSmooth = zeros(nFFTRange,1);
            for KK = 1:length(thetaAx)
                radialComp = data(:,1)*cos(thetaAx(KK)) + data(:,2)*sin(thetaAx(KK));
                % OPTION 1: VECTOR MULTIPLICATION (FASTER) ----------------
                counter = 1;
                for winIndex = 1:(timeWindowS-overlapS):size(data,1)-timeWindowS
                    radialTemp = radialComp(winIndex:winIndex+timeWindowS-1).*timeWindowSTape;
                    radialTempF = abs(fft(radialTemp,nFFT));
                    %                     radialTempF(nFFT/2 + 1:end,:) = [];
                    radialTempF = radialTempF(firstFreqIndex:lastFreqIndex,:);
                    for fStep = 1:nFFTRange
                        radialTempFSmooth(fStep,1) = mean(radialTempF.*konnoOhmachi(:,fStep));
                        % radialTempFSmooth(fStep,1) = mean(radialTempF.*konnoOhmachi(:,fStep),'omitnan'); % Slower
                    end
                    rotatedH(:,counter) = radialTempFSmooth;
                    counter = counter + 1;
                end
                % OPTION 2: MATRIX MULTIPLICATION (SLOWER) ----------------
                % winNumber = 0;
                % for winIndex = 1:(timeWindowS-overlapS):size(data,1)-timeWindowS
                %     radialMatrix(:,winNumber+1) = radialComp(winIndex:winIndex+timeWindowS-1);
                %     winNumber = winNumber+1;
                % end
                % radialMatrix = radialMatrix.*timeWindowsTapeMatrix;
                % radialMatrixF = abs(fft(radialMatrix,nFFT,1));
                % radialMatrixF(nFFT/2 + 1:end,:) = [];
                % for K = 1:winNumber
                %     radialTempF = mean(repmat(radialMatrixF(:,K),1,nFFT/2).*konnoOhmachi,1);
                %     rotatedHVSR(:,K) = radialTempF'./verticalMatrixFKO(:,K);    % Spectral ratio H/V
                % end
                % H/V Rotate ----------------------------------------------
                % HoverVMean = mean(HoverV,2);                              % Aritmetic mean (influenzata da valori lontani dalla media)
                rotatedHMeanTemp(:,KK) = geomean(rotatedH,2);         % Geometric mean (molto influenzata da valori bassi, meno influenzata da valori alti)
                % rotatedHVSRStd(:,KK) = std(rotatedHVSR,0,2);
                % Waitbar update ------------------------------------------
                p = get(handleToWaitBar,'Child'); x = get(p,'XData'); x(3:4) = KK/length(thetaAx); set(p,'XData',x); drawnow
            end
            
        case('Rectangular')
            bandWidth = str2double(get(findobj(mainPolFig,'tag','smoothing_band'),'string')); % [Hz]
            rectWin = round(bandWidth/df);
            for KK = 1:length(thetaAx)
                radialComp = data(:,1)*cos(thetaAx(KK)) + data(:,2)*sin(thetaAx(KK));
                winNumber = 0;
                for winIndex = 1:(timeWindowS-overlapS):size(data,1)-timeWindowS
                    radialMatrix(:,winNumber+1) = radialComp(winIndex:winIndex+timeWindowS-1);
                    winNumber = winNumber+1;
                end
                radialMatrix = radialMatrix.*timeWindowsTapeMatrix;
                radialMatrixF = abs(fft(radialMatrix,nFFT,1));
                %                 radialMatrixF(nFFT/2 + 1:end,:) = [];
                radialMatrixF = radialMatrixF(firstFreqIndex:lastFreqIndex,:);
                rotatedH = (movmean(radialMatrixF,rectWin,1));
                % H/V Rotate ----------------------------------------------
                % HoverVMean = mean(HoverV,2);                              % Aritmetic mean (influenzata da valori lontani dalla media)
                rotatedHMeanTemp(:,KK) = geomean(rotatedH,2);         % Geometric mean (molto influenzata da valori bassi, meno influenzata da valori alti)
                % rotatedHVSRStd(:,KK) = std(rotatedHVSR,0,2);
                % Waitbar update ------------------------------------------
                p = get(handleToWaitBar,'Child'); x = get(p,'XData'); x(3:4) = KK/length(thetaAx); set(p,'XData',x); drawnow
            end
            
        case('Triangular')
            bandWidth = str2double(get(findobj(mainPolFig,'tag','smoothing_band'),'string'));  % [Hz]
            triangWin = triang(round(bandWidth/df));
            for KK = 1:length(thetaAx)
                radialComp = data(:,1)*cos(thetaAx(KK)) + data(:,2)*sin(thetaAx(KK));
                winNumber = 0;
                for winIndex = 1:(timeWindowS-overlapS):size(data,1)-timeWindowS
                    radialMatrix(:,winNumber+1) = radialComp(winIndex:winIndex+timeWindowS-1);
                    winNumber = winNumber+1;
                end
                radialMatrix = radialMatrix.*timeWindowsTapeMatrix;
                radialMatrixF = abs(fft(radialMatrix,nFFT,1));
                %                 radialMatrixF(nFFT/2 + 1:end,:) = [];
                radialMatrixF = radialMatrixF(firstFreqIndex:lastFreqIndex,:);
                for I = 1:size(verticalMatrixF,2)
                    radialMatrixF(:,I) = conv(radialMatrixF(:,I),triangWin,'same');
                end
                rotatedH = radialMatrixF;
                % H/V Rotate ----------------------------------------------
                % HoverVMean = mean(HoverV,2);                              % Aritmetic mean (influenzata da valori lontani dalla media)
                rotatedHMeanTemp(:,KK) = geomean(rotatedH,2);         % Geometric mean (molto influenzata da valori bassi, meno influenzata da valori alti)
                % rotatedHVSRStd(:,KK) = std(rotatedHVSR,0,2);
                % Waitbar update ------------------------------------------
                p = get(handleToWaitBar,'Child'); x = get(p,'XData'); x(3:4) = KK/length(thetaAx); set(p,'XData',x); drawnow
            end
            
            
        case('None')
            for KK = 1:length(thetaAx)
                radialComp = data(:,1)*cos(thetaAx(KK)) + data(:,2)*sin(thetaAx(KK));
                winNumber = 0;
                for winIndex = 1:(timeWindowS-overlapS):size(data,1)-timeWindowS
                    radialMatrix(:,winNumber+1) = radialComp(winIndex:winIndex+timeWindowS-1);
                    winNumber = winNumber+1;
                end
                radialMatrix = radialMatrix.*timeWindowsTapeMatrix;
                radialMatrixF = abs(fft(radialMatrix,nFFT,1));
                %                 radialMatrixF(nFFT/2 + 1:end,:) = [];
                rotatedH = radialMatrixF(firstFreqIndex:lastFreqIndex,:);
                % H/V Rotate ----------------------------------------------
                % HoverVMean = mean(HoverV,2);                              % Aritmetic mean (influenzata da valori lontani dalla media)
                rotatedHMeanTemp(:,KK) = geomean(rotatedH,2);         % Geometric mean (molto influenzata da valori bassi, meno influenzata da valori alti)
                % rotatedHVSRStd(:,KK) = std(rotatedHVSR,0,2);
                % Waitbar update ------------------------------------------
                p = get(handleToWaitBar,'Child'); x = get(p,'XData'); x(3:4) = KK/length(thetaAx); set(p,'XData',x); drawnow
            end
    end
    
    delete(handleToWaitBar);
    rotatedHMean = [rotatedHMeanTemp rotatedHMeanTemp(:,2:end)];
    polPlotParameters.rotatedHMean = rotatedHMean;
    polPlotParameters.HThetaAx = [thetaAx pi+pi/nAngles:pi/nAngles:2*pi];
    polPlotParameters.freqAx = freqAx(firstFreqIndex:lastFreqIndex);
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FIGURE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Colormap
if strcmp(polPlotParameters.colormap,'cmapwbr')
    colormap(cmapwbr)
else
    colormap(polPlotParameters.colormap)
end
% Colormap range
colormapRangeTmp = polPlotParameters.colormapRange;
if isempty(colormapRangeTmp) || strcmp(colormapRangeTmp,'auto')
    colormapRange = [min(polPlotParameters.rotatedHMean(:)) max(polPlotParameters.rotatedHMean(:))];
else
    colormapRange = [str2double(colormapRangeTmp(1:strfind(colormapRangeTmp,'-')-1)) str2double(colormapRangeTmp(strfind(colormapRangeTmp,'-')+1:end))];
end
%
axes('units','normalized','position',[.22 .07 .7 .65])
%
switch polPlotParameters.axesType
    
    case('Cartesian')
        [X,Y] = meshgrid(polPlotParameters.freqAx,180*(polPlotParameters.HThetaAx/pi));
        if strcmp(polPlotParameters.HVSRAngularRule,'0° = N, increasing clockwise')
            indexThetaAxNew = 1:length(polPlotParameters.HThetaAx);
            indexPi2 = find(polPlotParameters.HThetaAx == pi/2);
            if not(isempty(indexPi2))
                indexThetaAxNew = circshift(fliplr(indexThetaAxNew),indexPi2);
            else
                temp = find(polPlotParameters.HThetaAx < pi/2,1,'last');
                indexThetaAxNew = circshift(fliplr(indexThetaAxNew),temp);
            end
            surf(X,Y,polPlotParameters.rotatedHMean(:,indexThetaAxNew)','edgecolor','none');
        else
            surf(X,Y,polPlotParameters.rotatedHMean','edgecolor','none');
        end
        view(2);
        caxis(colormapRange)
        colorbar
        set(gca,'xlim',[polPlotParameters.freqLim(1) polPlotParameters.freqLim(2)],'ylim',[0 180*(polPlotParameters.HThetaAx(end))/pi],'tickdir','out','ticklength',[.005 .005],...
            'box','on','FontUnits','points','fontsize',7,'FontName','Arial','ylim',[0 180])
        if strcmp(polPlotParameters.freqAxis,'Logarithmic')
            set(gca,'xscale','log')
        end
        xlabel('Frequency [Hz]'); ylabel('Angle [deg]');
        
    case('Polar')
        
        freqCircles = polPlotParameters.freqLim(1):round((polPlotParameters.freqLim(2)-polPlotParameters.freqLim(1))/3):polPlotParameters.freqLim(2);
        %         freqCircles = [10 50 100 150];
        circleSize = .45;
        for I = 1:length(freqCircles)
            freqCirclesLabels{I} = [num2str(freqCircles(I)) 'Hz'];
        end
        if strcmp(polPlotParameters.freqAxis,'Linear')
            
            [a,indTemp1] = min(abs(polPlotParameters.freqLim(1)-polPlotParameters.freqAx));
            [a,indTemp2] = min(abs(polPlotParameters.freqLim(2)-polPlotParameters.freqAx));
            
            [THETA,RR] = meshgrid(polPlotParameters.HThetaAx,polPlotParameters.freqAx(indTemp1:indTemp2));
            [A,B] = pol2cart(THETA,RR);
            % axes('units','normalized','position',[-0.124+(0.2*(3-1)) .3 circleSize circleSize],'FontUnits','points','fontsize',8,'FontName','timesnewroman')
            surf(A,B,polPlotParameters.rotatedHMean(indTemp1:indTemp2,:),'edgecolor','none');
            caxis(colormapRange)
            view(0,90)
            axis tight
            axis equal
            set(gca,'visible','off')
            % Colorbar
            colHandle = colorbar('southoutside');
            set(colHandle,'units','normalized','position',[.3 .08 .4 .03],'ticks',[0 5 10 15 20],...
                'ticklabels',{'0';'5';'10';'15';'20'},'fontsize',8,'FontName','timesnewroman')
            % Set and correct polar axes
            % axes('units','normalized','position',[-0.124+(0.2*(3-1)) .3 circleSize circleSize],'color','none','FontUnits','points','fontsize',8,'FontName','timesnewroman')
            axPos = get(gca,'position');
            axes('units','normalized','position',axPos,'color','none')
            polarplot([],[]);
            set(gca,'color','none','ThetaTickLabel',{'\fontsize{8}E','','','\fontsize{8}N','','','\fontsize{8}W','','','\fontsize{8}S','',''})
            set(gca,'rlim',[0 polPlotParameters.freqLim(2)],'RColor',[1 1 1],'RTick',freqCircles,'RTickLabels',freqCirclesLabels,...
                'linewidth',1,'gridlinestyle','-','gridcolor','w','gridalpha',0.6,...
                'fontsize',7,'fontweight','bold')
            
        elseif strcmp(polPlotParameters.freqAxis,'Logarithmic')
            % Factor used to scale freq axis values in order to avoid negative values in the log freq axis that would mess the polar plot up
            minCorrFactorLogFreqPlot = 1/polPlotParameters.freqLim(1);
            corrFactorLogFreqPlot = minCorrFactorLogFreqPlot*1.5;
            %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            freqAxLog = log10(corrFactorLogFreqPlot*freqAx(firstFreqIndex:lastFreqIndex));
            [THETA,RRLog] = meshgrid(polPlotParameters.HThetaAx,freqAxLog);
            [X,Y] = pol2cart(THETA,RRLog);
            freqCircles = corrFactorLogFreqPlot*[1 5 10 50 100];
            for I = 1:length(freqCircles)
                freqCirclesLabels{I} = [num2str(freqCircles(I)/corrFactorLogFreqPlot) 'Hz'];
            end
            % axes('units','normalized','position',[-0.124+(0.2*(3-1)) .3 circleSize circleSize],'FontUnits','points','fontsize',8,'FontName','timesnewroman')
            surf(X,Y,polPlotParameters.rotatedHMean,'edgecolor','none');
            caxis(colormapRange)
            view(0,90)
            axis tight
            axis equal
            set(gca,'visible','off')
            % Colorbar
            colHandle = colorbar('southoutside');
            set(colHandle,'units','normalized','position',[.3 .08 .4 .03],'ticks',[0 5 10 15 20],...
                'ticklabels',{'0';'5';'10';'15';'20'},'fontsize',8,'FontName','timesnewroman')
            % Set and correct polar axes
            % axes('units','normalized','position',[-0.124+(0.2*(3-1)) .3 circleSize circleSize],'color','none','FontUnits','points','fontsize',8,'FontName','timesnewroman')
            axPos = get(gca,'position');
            axes('units','normalized','position',axPos,'color','none')
            polarplot([],[]);
            set(gca,'color','none','ThetaTickLabel',{'\fontsize{8}E','','','\fontsize{8}N','','','\fontsize{8}W','','','\fontsize{8}S','',''})
            set(gca,'rlim',[0 1],'RColor',[1 1 1],'RTick',log10(freqCircles)/max(freqAxLog),'RTickLabels',freqCirclesLabels,...
                'linewidth',1,'gridlinestyle','-','gridcolor','w','gridalpha',0.6,...
                'fontsize',7,'fontweight','bold')
        end
end

% % % Save figure -----------------------------------------------------------
% % rez = 300;                                                                 % resolution (dpi) of final graphic
% % f = gcf;
% % figpos = getpixelposition(f);
% % resolution = get(0,'ScreenPixelsPerInch');
% % set(f,'paperunits','inches','papersize',figpos(3:4)/resolution,'paperposition',[0 0 figpos(3:4)/resolution]);
% % path = 'C:\Users\Diego\Desktop\';
% % name = 'spectRotate';
% % print(f,fullfile(path,name),'-dtif',['-r',num2str(rez)],'-opengl')
