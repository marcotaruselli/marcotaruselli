% function PolCompute(data,timeAx)
function PolCompute(data_processing)

global mainPolFig
global polPlotParameters


set(findobj(mainPolFig,'tag','pleaseWait'),'visible','on'); drawnow;

data = [data_processing(1).signal data_processing(2).signal data_processing(3).signal]; 

tempAxes = findobj(gcf,'type','axes');
for I = 1:size(tempAxes,1)
    if not(strcmpi(get(tempAxes(I),'tag'),'comp_x')) && not(strcmpi(get(tempAxes(I),'tag'),'comp_y')) && not(strcmpi(get(tempAxes(I),'tag'),'comp_z'))
     delete(tempAxes(I));
    end
end
delete(findobj(gcf,'type','polaraxes'))
%
polAlgorithmString = get(findobj(mainPolFig,'tag','polarization_algorithm'),'string');
polAlgorithmValue = get(findobj(mainPolFig,'tag','polarization_algorithm'),'value');
polAlgorithm = polAlgorithmString{polAlgorithmValue};
%
timeWin = str2double(get(findobj(mainPolFig,'tag','time_window'),'string'));
%
winOverlap = str2double(get(findobj(mainPolFig,'tag','time_window_overlap'),'string'));
%
winTaperingString = get(findobj(mainPolFig,'tag','time_window_tapering'),'string');
winTaperingValue = get(findobj(mainPolFig,'tag','time_window_tapering'),'value');
winTapering = winTaperingString{winTaperingValue};
%
fs = str2double(get(findobj(mainPolFig,'tag','sampling_frequency'),'string'));
%
spectralSmoothingString = get(findobj(mainPolFig,'tag','spectral_smoothing'),'string');
spectralSmoothingValue = get(findobj(mainPolFig,'tag','spectral_smoothing'),'value');
spectralSmoothing = spectralSmoothingString{spectralSmoothingValue};
%
smoothingBand = str2double(get(findobj(mainPolFig,'tag','smoothing_band'),'string'));
%
KObValue = str2double(get(findobj(mainPolFig,'tag','ko_b_value'),'string'));
%
freqAverages = str2double(get(findobj(mainPolFig,'tag','frequency_averages'),'string'));
%
beta2Axis = str2num(get(findobj(mainPolFig,'tag','beta2_axis'),'string'));
thetaHAxis = str2num(get(findobj(mainPolFig,'tag','thetaH_axis'),'string'));
thetaVAxis = str2num(get(findobj(mainPolFig,'tag','thetaV_axis'),'string'));
phiHHAxis = str2num(get(findobj(mainPolFig,'tag','phiHH_axis'),'string'));
phiVHAxis = str2num(get(findobj(mainPolFig,'tag','phiVH_axis'),'string'));
%
nAngles = str2double(get(findobj(mainPolFig,'tag','angular_samples'),'string'));

% % Filtering
% filterTypeString = get(findobj(mainPolFig,'tag','filter_type'),'string');
% filterTypeValue = get(findobj(mainPolFig,'tag','filter_type'),'value');
% filterType = filterTypeString{filterTypeValue};
% if not(strcmpi(filterType,'None'))
%     opts = struct('WindowStyle','modal','Interpreter','tex');
%     filterFrequencyTmp = get(findobj(mainPolFig,'tag','filter_frequency'),'string');
%     if isempty(filterFrequencyTmp) %&& not(strcmp(filterType,'None'))
%         errordlg('Please set filter frequency correctly!','Input parameter Error',opts);
%     elseif contains(filterFrequencyTmp,'-')
%         filterFreq = [str2double(filterFrequencyTmp(1:strfind(filterFrequencyTmp,'-')-1)) str2double(filterFrequencyTmp(strfind(filterFrequencyTmp,'-')+1:end))];
%     else
%         filterFreq = str2double(get(findobj(mainPolFig,'tag','filter_frequency'),'string'));
%     end
%     [data,timeAx] = DataFiltering(data,fs,timeAx,filterType,filterFreq,0.05);
% end

polPlotParameters.freqLim = [10/timeWin fs/2];
plotUpdate = 0;
opts = struct('WindowStyle','modal','Interpreter','tex');

switch polAlgorithm
    
    case{'HV rotate','H rotate','SVD spectral matrix'}
        if isnan(timeWin)
            errordlg('Please specify time window length','Input parameter Error',opts);
            return
        elseif timeWin <= 0 || timeWin > (size(data,1)-1)*(1/fs)
            errordlg('Time window must be >= 0s and < signal duration','Input parameter Error',opts);
            return
        end
        if isnan(winOverlap)
            set(findobj(mainPolFig,'tag','time_window_overlap'),'string','0')
        elseif winOverlap < 0 || winOverlap > 99
            errordlg('Win Overlap must be >= 0% and < 99%','Input parameter Error',opts);
            return
        end
        if strcmp(get(findobj(mainPolFig,'tag','FFT_samples'),'string'),'auto')
            nFFT = 2^(nextpow2(round(timeWin*fs)));
        else
            nFFT = str2double(get(findobj(mainPolFig,'tag','FFT_samples'),'string'));
            if nFFT < 2 || isnan(nFFT)
                errordlg('Please correct FFT samples value [i.e., \geq time Window*sampling frequency ]','Input parameter Error',opts);
                return
            elseif nFFT < round(timeWin*fs)
                warndlg(['Be aware that FFT algorithm will considere just ' num2str(nFFT) ' time samples to compute the frequency spectrum.'],'Input parameter Warning',opts);
                return
            end
        end
        freqRangeTmp = get(findobj(mainPolFig,'tag','frequency_range'),'string');
        if strcmp(freqRangeTmp,'auto')
            freqRange = [1/(str2double(get(findobj(mainPolFig,'tag','time_window'),'string'))/10) fs/2];
        else
            freqRange = [str2double(freqRangeTmp(1:strfind(freqRangeTmp,'-')-1)) str2double(freqRangeTmp(strfind(freqRangeTmp,'-')+1:end))];
            if freqRange(1)<0 || freqRange(2)>fs/2 || freqRange(1)>freqRange(2) || any(isnan(freqRange))
                errordlg('Please correct frequency range','Input parameter Error',opts);
                return
            elseif freqRange(1)==0 && strcmp(freqAxis,'Logarithmic')
                errordlg('Lower limit of logarithmic frequency axis cannot be 0','Input parameter Error',opts);
                return
            end
        end
        switch spectralSmoothing
            case('KonnoOhmachi')
                if KObValue <= 0 || KObValue >= 100
                    errordlg('KonnoOhmachi b value must be 0 < b < 100','Input parameter Error',opts);
                    return
                end
            case{'Rectangular','Triangular'}
                if smoothingBand <= fs/nFFT || smoothingBand >= floor(fs/2) || isnan(smoothingBand)
                    errordlg(['Smoothing band must be >' num2str(fs/nFFT) ' and <' num2str(fs/2)],'Input parameter Error',opts);
                    return
                end
        end
        switch polAlgorithm
            case{'HV rotate','H rotate'}
                if nAngles < 2 || isnan(nAngles)
                    errordlg('Please correct Angular samples value','Input parameter Error',opts);
                    return
                end
                if strcmpi(polAlgorithm,'HV rotate')
                    PolHVRotate(plotUpdate,data,fs,timeWin,winOverlap,winTapering,nFFT,freqRange,spectralSmoothing,nAngles);
                elseif strcmpi(polAlgorithm,'H rotate')
                    PolHRotate(plotUpdate,data,fs,timeWin,winOverlap,winTapering,nFFT,freqRange,spectralSmoothing,nAngles);
                end
            case('SVD spectral matrix')
                if freqAverages < 2
                    errordlg('Please correct frequency averages value','Input parameter Error',opts);
                    return
                end
                if isempty(beta2Axis) || numel(beta2Axis) == 1 || min(beta2Axis)<0 || max(beta2Axis)>1
                    errordlg('Please correct Beta^2 Ax values','Input parameter Error',opts);
                    return
                end
                if isempty(thetaHAxis) || numel(thetaHAxis) == 1 || min(thetaHAxis)<0 || max(thetaHAxis)>360
                    errordlg('Please correct thetaH Ax values','Input parameter Error',opts);
                    return
                end
                if isempty(thetaVAxis) || numel(thetaVAxis) == 1 || min(thetaVAxis)<0 || max(thetaVAxis)>90
                    errordlg('Please correct thetaV Ax values','Input parameter Error',opts);
                    return
                end
                if isempty(phiHHAxis) || numel(phiHHAxis) == 1 || min(phiHHAxis)<-180 || max(phiHHAxis)>180
                    errordlg('Please correct phiHH Ax values','Input parameter Error',opts);
                    return
                end
                if isempty(phiVHAxis) || numel(phiVHAxis) == 1 || min(phiVHAxis)<-90 || max(phiVHAxis)>90
                    errordlg('Please correct phiVH Ax values','Input parameter Error',opts);
                    return
                end
                PolSVDSpectralMatrix(plotUpdate,data,fs,timeWin,winOverlap,winTapering,nFFT,freqRange,spectralSmoothing,freqAverages,...
                    beta2Axis,thetaHAxis,thetaVAxis,phiHHAxis,phiVHAxis);
        end
        
    case('PCA covariance matrix')
        PolPCACovMatrix(data,fs)
        
end

set(findobj(mainPolFig,'tag','pleaseWait'),'visible','off'); drawnow;
