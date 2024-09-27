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
data = data(80000:500000,:);  % Sirotti 20170728

%% Set processing parameters ----------------------------------------------
trasdConstAcqSystem = 301239990;                                            % Transduction constant of the whole acquisition system [counts/(m/s)]
timeWindow = 20;                                                            % Time window lenght (for averaging) [s]
freqMin = 1/(timeWindow/10);                                                % Minimum admissible frequency [Hz]
overlap = 90;                                                               % Time window overlap (for averaging) [%]
freqAverages = 10;                                                          % Number of averages to compute average frequency spectra
winTapering = 'hamming';                                                    % Time window tapering mask
spectralSmoothing = 'none'; %'KonnoOhmachi'; %none';                        % Spectral smoothing type
fftSample = 2^14;                                                           % Samples of frequency axis (number or 'auto' [== 2^(nextpow2(timeWindowS))])
filtering = 'bandpass_unique';                                                         % {'highpass';'bandpass_unique';'bandpass_tuned'}
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
    
    %     bandPassFiltersTemp = [bandPassFilters(Ifilt)-10 bandPassFilters(Ifilt)+10];
    
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
            %             for I = 1:size(fileNamesBlock,1)
            %                 [dataBlockNoResp{I},d] = bandpass(dataBlockNoResp{I},bandPassFiltersTemp,fs,'ImpulseResponse','iir','Steepness',0.9);
                %             end
                [data,d] = bandpass(data,[1 10],fs,'ImpulseResponse','iir','Steepness',0.95);
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
    
    figure
    subplot(311)
    plot(data(:,1),'r')
    subplot(312)
    plot(data(:,2),'g')
    subplot(313)
    plot(data(:,3),'b')
    
    %% FIGURES WITH HODOGRAMS AND EIGENVECTORS --------------------------------
    %     figure('Name',['Filter ' num2str(bandPassFiltersTemp) 'Hz'])
    figure
%     scaleFactor = 1e6;                                                          % Unit conversione from [m/s] to [mum/s]
    %     axLimit = 1.5e-7*scaleFactor;
    % Figure with eigenvectors not scaled ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    
%     data = data*scaleFactor;
    axLimit = max(abs(data(:)));
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

