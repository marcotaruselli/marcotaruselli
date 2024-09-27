function [signalRaw,signalDeconv,fs] = ResponseDeconvolution(fui)

trasdConstTrillium = 301239990;     %Serve solo per plottare il confronto tra segnale RAW e deconvoluto

[data,folder] = uigetfile({'*.miniseed;*.mseed'},'Select file to be deconvolved','MultiSelect', 'on');
if data == 0
    signalRaw = NaN;
    signalDeconv = NaN;
    fs = NaN;
    return
end

set(findobj(fui,'type','uicontrol'),'enable','off')
set(findobj(fui,'tag','pleaseWait'),'visible','on','enable','on');

set(findobj(fui,'tag','sensorRespName'),'string');

tmpstring = get(findobj(fui,'tag','jEvalFolder'),'string');
cd(tmpstring);
addpath(folder)

tmpString1 = get(findobj(fui,'tag','sensorRespName'),'string');
tmpIndex = strfind(tmpString1,'\');
sensorRespName = tmpString1(tmpIndex(end)+1:end);
status = copyfile(tmpString1,tmpstring,'f');
tmpString2 = get(findobj(fui,'tag','digitizerRespName'),'string');
tmpIndex = strfind(tmpString2,'\');
digitizerRespName = tmpString2(tmpIndex(end)+1:end);
status = copyfile(tmpString2,tmpstring,'f');

filterTypeValue = get(findobj(fui,'tag','filterType'),'value');
filterTypeString = get(findobj(fui,'tag','filterType'),'string');
filterType = filterTypeString{filterTypeValue};
filterFreq = str2num(get(findobj(fui,'tag','filterFreq'),'string'));


%% SE CARICHI UN SOLO SEGNALE
if ischar(data)
    % 1) Crea il segnale formato da una riga relativa al dato e la seconda riga relativa al tempo
    [X,I] = rdmseed(data);
    for j = 1:size(I,2)
        k = [I(j).XBlockIndex];
        name = [X(1).StationIdentifierCode '_' X(1).ChannelIdentifier '_'  datestr(X(1).t(1),'ddmmmyyyyHHMM')];
        eval([name '(:,' num2str(j) ')  = [cat(1,X(k(:,1)).d)];']);
        eval([name '= double(' name ');']);
    end
    fs = X(1).SampleRate;
    timeAx = cat(1,X(k(:,1)).t);
    
    %% Preparo il segnale
    eval(['signalRaw = ' name ';'] );
    signalRaw = signalRaw - mean(signalRaw);
    
    %% Compute spectrum of the signal
    %     Nfft = 2^14;
    Nfft = 2^nextpow2(size(signalRaw,1));
    freqAx = 0:fs/(Nfft-1):fs;
    signalRawF = fft(signalRaw,Nfft);
    
    %% Compute Instrument responses with Java routine
    % Digitizer (Centaur)
    code = ['java -jar JEvalResp.jar "*" "*" "*" "*" ' num2str(0) ' ' num2str(fs) ' ' num2str(Nfft) ' -f ' digitizerRespName ' -stage 3 -u vel  -r cs -v -s lin'];
    eval([ '[status,result] = system(''' code ''')'])
    % Sensor (Trillium)
    code = ['java -jar JEvalResp.jar "*" "*" "*" "*" ' num2str(0) ' ' num2str(fs) ' ' num2str(Nfft) ' -f ' sensorRespName ' -u vel  -r cs -v -s lin'];
    eval([ '[status,result] = system(''' code ''')'])
    
    %% Convert Instrument response files to .txt
    tmpIndex = strfind(sensorRespName,'Z');
    sensorSpectraName = ['SPECTRA' sensorRespName(5:tmpIndex(end)) '.txt'];
    status = movefile(['SPECTRA' sensorRespName(5:tmpIndex(end))],sensorSpectraName);
    tmpIndex = strfind(digitizerRespName,'Z');
    digitizerSpectraName = ['SPECTRA' digitizerRespName(5:tmpIndex(end)) '.txt'];
    status = movefile(['SPECTRA' digitizerRespName(5:tmpIndex(end))],digitizerSpectraName);
    
    %% Substitute comma with dot
    % Sensor
    fid = fopen(sensorSpectraName);
    dataTemp = textscan(fid,'%s%s%s');
    fclose(fid);
    %     FreqAxS = str2double(strrep(dataTemp{1,1}, ',', '.'))';
    sensorReal =  str2double(strrep(dataTemp{1,2}, ',', '.'))';
    sensorImag =  str2double(strrep(dataTemp{1,3}, ',', '.'))';
    % Digitizer
    fid = fopen(digitizerSpectraName);
    dataTemp = textscan(fid,'%s%s%s');
    fclose(fid);
    %     FreqAxD = str2double(strrep(dataTemp{1,1}, ',', '.'))';
    digitizerReal =  str2double(strrep(dataTemp{1,2}, ',', '.'))';
    digitizerImag =  str2double(strrep(dataTemp{1,3}, ',', '.'))';
    
    %% Crea risposta dei sensori
    % Make Sensor FRF Hermitian
    sensorFRFTemp = sensorReal + sensorImag*1i;
    sensorFRF = [sensorFRFTemp(1:Nfft/2 + 1) conj(fliplr(sensorFRFTemp(2:Nfft/2)))];
    % Make Digitizer FRF Hermitian
    digitizerFRFTemp = digitizerReal +digitizerImag*1i;
    digitizerFRF = [digitizerFRFTemp(1:Nfft/2 + 1) conj(fliplr(digitizerFRFTemp(2:Nfft/2)))];
    
    %% Instrument response removal (Deconvolution)
    signalDeconvF = signalRawF./(conj(digitizerFRF'));
    signalDeconvF = signalDeconvF./(conj(sensorFRF'));
    signalDeconvF(1,:) = 0;
    signalDeconv = ifft(signalDeconvF,Nfft,'symmetric');
    signalDeconv = signalDeconv(1:size(signalRaw,1),:);
    
    %% Filtering
    switch(lower(filterType))
        case('highpass')
            [signalRaw,~] = highpass(signalRaw,filterFreq,fs,'ImpulseResponse','iir','Steepness',0.95);
            [signalDeconv,d] = highpass(signalDeconv,filterFreq,fs,'ImpulseResponse','iir','Steepness',0.95);
            signalRawF = fft(signalRaw,Nfft);
            signalDeconvF = fft(signalDeconv,Nfft);
    end
    
    %     %%% SALVATAGGIO
    %     currentFolder = pwd;
    %     cd('C:\Users\marco\Desktop\')
    %     if ~exist('SignalsWithoutRESP', 'dir')
    %         mkdir('SignalsWithoutRESP')
    %     end
    %     cd('C:\Users\marco\Desktop\SignalsWithoutRESP')
    %     eval([name '_withoutRESP = segnale_withoutInstrResp ;'])
    %     eval(['save ' name '_withoutRESP.mat ' name '_withoutRESP'])
    %     cd([currentFolder])
    
    
    if get(findobj(fui,'tag','plotResults'),'value')
        % Raw Signal
        figure('name','RAW SIGNAL')
        subplot(3,1,1)
        plot(timeAx,signalRaw)
        ylabel('Vel [counts]');datetickzoom; title('RAW signal')
        subplot(3,1,2)
        plot(freqAx(1:ceil(Nfft/2)),abs(signalRawF(1:ceil(Nfft/2),:)))
        ylabel('Amplitude')
        subplot(3,1,3)
        plot(freqAx(1:ceil(Nfft/2)),unwrap(angle(signalRawF(1:ceil(Nfft/2),:))))
        ylabel('Phase')
        
        % Deconvolved Signal
        figure('name','DECONVOLVED SIGNAL')
        subplot(3,1,1)
        plot(timeAx,signalDeconv)
        ylabel('Vel [m/s]');datetickzoom; title('DECONVOLVED signal')
        subplot(3,1,2)
        plot(freqAx(1:ceil(Nfft/2)),abs(signalDeconvF(1:ceil(Nfft/2),:)))
        ylabel('Amplitude')
        subplot(3,1,3)
        plot(freqAx(1:ceil(Nfft/2)),unwrap(angle(signalDeconvF(1:ceil(Nfft/2),:))))
        ylabel('Phase')
        
        % Response functions of sensor and digitizer
        figure('name','SENSOR & DIGITIZER FRFs');
        subplot(2,2,1)
        plot(freqAx,abs(sensorFRF))
        grid on; grid minor;
        ylabel('Amplitude');title('SENSOR FRF')
        subplot(2,2,3)
        plot(freqAx,angle(sensorFRF))
        grid on; grid minor
        ylabel('Phase [rad]'); xlabel('Frequency (Hz)')
        subplot(2,2,2)
        plot(freqAx,abs(digitizerFRF))
        grid on; grid minor;
        ylabel('Amplitude');title('DIGITIZER FRF')
        subplot(2,2,4)
        plot(freqAx,angle(digitizerFRF))
        grid on; grid minor
        ylabel('Phase [rad]'); xlabel('Frequency (Hz)')
        
    end
    
    
    %% SE CARICHI PIU' DI UN SEGNALE
elseif iscell(data) %se sono stati caricati più segnali
    for ii = 1:size(data,2)
        cd(folder)
        segnale = data{:,ii};
        [X,I] = rdmseed(segnale);
        for j = 1:size(I,2)
            k = [I(j).XBlockIndex];
            name = [X(1).StationIdentifierCode '_' X(1).ChannelIdentifier '_'  datestr(X(1).t(1),'ddmmmyyyyHHMM')];
            eval([name '(:,' num2str(j) ')  = [cat(1,X(k(:,1)).d)];']);
            eval([name '= double(' name ');']);
        end
        fs = X(1).SampleRate;
        timeAx = [cat(1,X(k(:,1)).t)];
        
        %% Preparo il segnale
        eval(['signal = ' name ';'] );
        signal = signal - mean(signal);
        % figure;subplot(3,1,1);plot(timeAx,signal);ylabel('counts');datetickzoom; title('RAW signal')
        
        %% Compute spectrum of the signal
        Nfft = 2^14;
        % Nfft = 2^nextpow2(length(signal));
        freqAx = 0:fs/(Nfft-1):fs;
        signalRawF = fft(signal,Nfft);
        %         magRawSignal = abs(FFTsignal);
        %         phaseRawSignal = rad2deg(angle(FFTsignal));
        % subplot(3,1,2);plot(freqAx(1:ceil(Nfft/2)),magRawSignal(1:ceil(Nfft/2)));ylabel('counts'); title('Ampiezza')
        % subplot(3,1,3);plot(freqAx(1:ceil(Nfft/2)),Phase(1:ceil(Nfft/2)));ylabel('counts');title('Phase')
        
        
        %% Compute Instrument responses
        % Compute instrument response (Trillium+Centaur) - Automatic java code
        %downloaded from IRIS website
        
        % Trillium (Seismometer)
        code = ['java -jar JEvalResp.jar "*" "*" "*" "*" ' num2str(0) ' ' num2str(fs) ' ' num2str(Nfft) ' -f RESP.XX.NN466..FHZ.CENTAUR.1.1000.0_001.LP -stage 3 -u vel  -r cs -v -s lin'];
        eval([ '[status,result] = system(''' code ''')'])
        
        %Centaur (Digitalizer)
        code = ['java -jar JEvalResp.jar "*" "*" "*" "*" ' num2str(0) ' ' num2str(fs) ' ' num2str(Nfft) ' -f RESP.XX.NS348..BHZ.TrilliumCompact20.20.753  -u vel  -r cs -v -s lin'];
        eval([ '[status,result] = system(''' code ''')'])
        
        %% Convert file to .txt
        movefile('SPECTRA.XX.NS348..BHZ','SPECTRA.XX.NS348..BHZ.txt'); %Trillium
        movefile('SPECTRA.XX.NN466..FHZ','SPECTRA.XX.NN466..FHZ.txt'); %Centaur
        
        %% Substitution of comma with dot
        % Trillium
        fid = fopen('SPECTRA.XX.NS348..BHZ.txt');
        dataTemp = textscan(fid,'%s%s%s');
        fclose(fid);
        freqAx = str2double(strrep(dataTemp{1,1}, ',', '.'))';
        Real_Trillium =  str2double(strrep(dataTemp{1,2}, ',', '.'))';
        Im_Trillium =  str2double(strrep(dataTemp{1,3}, ',', '.'))';
        
        % Centaur
        fid = fopen('SPECTRA.XX.NN466..FHZ.txt');
        dataTemp = textscan(fid,'%s%s%s');
        fclose(fid);
        freqAx = str2double(strrep(dataTemp{1,1}, ',', '.'))';
        Real_Centaur =  str2double(strrep(dataTemp{1,2}, ',', '.'))';
        Im_Centaur =  str2double(strrep(dataTemp{1,3}, ',', '.'))';
        
        %% Crea risposta dei sensori e fai il plot
        % Trillium
        sensorFRF = Real_Trillium +Im_Trillium*1i;
        AmpInstrumResponse_Trillium = abs(sensorFRF);
        PhaseInstrumResponse_Trillium = rad2deg(angle(sensorFRF));
        % figure;
        % subplot(2,2,1); plot(freqAx,AmpInstrumResponse_Trillium); ylabel('Amplitude');title('Amplitude')
        % grid on; grid minor;title( 'Trillium response')
        % subplot(2,2,3);plot(freqAx,PhaseInstrumResponse_Trillium);ylabel('Phase [degrees]'); xlabel('Frequency (Hz)')
        % grid on; grid minor
        % supertitle('RESP TRILLIUM')
        
        % Centaur
        digitizerFRF = Real_Centaur +Im_Centaur*1i;
        AmpInstrumResponse_Centaur = abs(digitizerFRF);
        PhaseInstrumResponse_Centaur = rad2deg(angle(digitizerFRF));
        % figure;
        % subplot(2,2,1); plot(freqAx,AmpInstrumResponse_Centaur); ylabel('Amplitude');title('RESP TRILLIUM')
        % grid on; grid minor;title( 'Centaur response')
        % subplot(2,2,3);plot(freqAx,PhaseInstrumResponse_Centaur);ylabel('Phase [degrees]'); xlabel('Frequency (Hz)')
        % grid on; grid minor
        
        %% make symmetric the instrum. resp.
        % Trillium
        left_RESP_Trillium = sensorFRF(1:Nfft/2);
        reale_RESP_Trillium = real(fliplr(left_RESP_Trillium));
        immag_RESP_Trillium = imag(fliplr(left_RESP_Trillium));
        right__RESP_Trillium = reale_RESP_Trillium-immag_RESP_Trillium*1i;
        sensorFRF = [left_RESP_Trillium right__RESP_Trillium];
        AmpInstrumResponse_Trillium = abs(sensorFRF);
        PhaseInstrumResponse_Trillium = rad2deg(angle(sensorFRF));
        % figure(2);
        % subplot(2,2,2); plot(freqAx,AmpInstrumResponse_Trillium); ylabel('Amplitude');title('Amplitude')
        % grid on; grid minor;title( 'Trillium response Corrected')
        % subplot(2,2,4);plot(freqAx,PhaseInstrumResponse_Trillium);ylabel('Phase [degrees]'); xlabel('Frequency (Hz)')
        % grid on; grid minor
        
        % Centaur
        left_RESP_Centaur = digitizerFRF(1:Nfft/2);
        reale_RESP_Centaur = real(fliplr(left_RESP_Centaur));
        immag_RESP_Centaur = imag(fliplr(left_RESP_Centaur));
        right__RESP_Centaur = reale_RESP_Centaur-immag_RESP_Centaur*1i;
        digitizerFRF = [left_RESP_Centaur right__RESP_Centaur];
        AmpInstrumResponse_Centaur = abs(digitizerFRF);
        PhaseInstrumResponse_Centaur = rad2deg(angle(digitizerFRF));
        % figure(3);
        % subplot(2,2,2); plot(freqAx,AmpInstrumResponse_Centaur); ylabel('Amplitude');title('RESP TRILLIUM')
        % grid on; grid minor;title( 'Centaur response Corrected')
        % subplot(2,2,4);plot(freqAx,PhaseInstrumResponse_Centaur);ylabel('Phase [degrees]'); xlabel('Frequency (Hz)')
        % grid on; grid minor
        
        
        %% Instrument response removal from signal_test (Deconvolution)
        signalDeconvF = signalRawF./digitizerFRF';
        signalDeconvF = signalDeconvF./sensorFRF';
        
        %% Build up signal without instrum. resp.
        reale =real(signalDeconvF);
        imaginary = imag(signalDeconvF);
        reale(1) = 0;
        signalDeconvF = reale + imaginary*1i;
        % figure;semilogx(freqAx,abs(signalDeconvF));title('Spectrum of signal without RESP')
        
        % segnale_withoutInstrResp = real(ifft(spettro_without_InstResp,Nsamples)); %segnale
        signalDeconv = ifft(signalDeconvF,Nfft,'symmetric');
        magSignalwithoutRESP = abs(signalDeconvF); %Magnitude
        phaseSignalwithoutRESP = rad2deg(angle(signalDeconvF)); %Phase
        % figure;
        % % subplot(3,1,1);plot(timeAx,segnale_withoutInstrResp);datetickzoom; title('Signal without instrument response')
        %
        % subplot(3,1,1);plot(segnale_withoutInstrResp);datetickzoom; title('Signal without instrument response')
        % subplot(3,1,2);plot(freqAx(1:ceil(Nfft/2)),X_Mag_withoutRESP(1:ceil(Nfft/2)));ylim([0 100]); title('Ampiezza')
        % subplot(3,1,3);plot(freqAx(1:ceil(Nfft/2)),Phase_withoutRESP(1:ceil(Nfft/2)));title('Phase') %Se plottassi i grafici fino alla frequenza di campionamento
        
        
        %% Comparison of the spectrum without and with instrum. resp. removal
        % figure;subplot(2,1,1);semilogx(freqAx(1:ceil(Nfft/2)),magRawSignal(1:ceil(Nfft/2))/trasdConstTrillium); title('Mag RAW signal');
        % hold on;semilogx(freqAx(1:ceil(Nfft/2)),X_Mag_withoutRESP(1:ceil(Nfft/2)));title('Mag signal without RESP');
        % ylim([0 0.01])
        % subplot(2,1,2);plot(freqAx(1:ceil(Nfft/2)),unwrap(Phase(1:ceil(Nfft/2))));title('Phase RAW signal')
        % hold on;plot(freqAx(1:ceil(Nfft/2)),unwrap(Phase_withoutRESP(1:ceil(Nfft/2))));title('Phase signal without RESP')
        % suptitle('Comparison RAW vs RAW without RESP')
        
        
        %         %%% SALVATAGGIO
        %         currentFolder = pwd;
        %         cd('C:\Users\marco\Desktop\')
        %         if ~exist('SignalsWithoutRESP', 'dir')
        %             mkdir('SignalsWithoutRESP')
        %         end
        %         cd('C:\Users\marco\Desktop\SignalsWithoutRESP')
        %         eval([name '_withoutRESP = segnale_withoutInstrResp ;'])
        %         eval(['save ' name '_withoutRESP.mat ' name '_withoutRESP'])
        %         cd([currentFolder])
        
        
        
        if get(plotResultsHandle,'value')
            %1)
            figure;subplot(3,1,1);plot(timeAx,signal);ylabel('counts');datetickzoom; title('RAW signal')
            
            %2)
            subplot(3,1,2);plot(freqAx(1:ceil(Nfft/2)),magRawSignal(1:ceil(Nfft/2),:));ylabel('counts'); title('Amplitude')
            subplot(3,1,3);plot(freqAx(1:ceil(Nfft/2)),phaseRawSignal(1:ceil(Nfft/2),:));ylabel('counts');title('Phase')
            
            %3)
            figure;
            subplot(2,2,1); plot(freqAx,AmpInstrumResponse_Trillium); ylabel('Amplitude');title('Amplitude')
            grid on; grid minor;title( 'Trillium response')
            subplot(2,2,3);plot(freqAx,PhaseInstrumResponse_Trillium);ylabel('Phase [degrees]'); xlabel('Frequency (Hz)')
            grid on; grid minor
            supertitle('RESP TRILLIUM')
            
            %4)
            figure;
            subplot(2,2,1); plot(freqAx,AmpInstrumResponse_Centaur); ylabel('Amplitude');title('RESP TRILLIUM')
            grid on; grid minor;title( 'Centaur response')
            subplot(2,2,3);plot(freqAx,PhaseInstrumResponse_Centaur);ylabel('Phase [degrees]'); xlabel('Frequency (Hz)')
            grid on; grid minor
            
            %5)
            figure(2);
            subplot(2,2,2); plot(freqAx,AmpInstrumResponse_Trillium); ylabel('Amplitude');title('Amplitude')
            grid on; grid minor;title( 'Trillium response Corrected')
            subplot(2,2,4);plot(freqAx,PhaseInstrumResponse_Trillium);ylabel('Phase [degrees]'); xlabel('Frequency (Hz)')
            grid on; grid minor
            
            %6)
            figure(3);
            subplot(2,2,2); plot(freqAx,AmpInstrumResponse_Centaur); ylabel('Amplitude');title('RESP TRILLIUM')
            grid on; grid minor;title( 'Centaur response Corrected')
            subplot(2,2,4);plot(freqAx,PhaseInstrumResponse_Centaur);ylabel('Phase [degrees]'); xlabel('Frequency (Hz)')
            grid on; grid minor
            
            %7)
            figure;semilogx(freqAx,abs(signalDeconvF));title('Spectrum of signal without RESP')
            legend('x','y','z')
            %8)
            figure;
            subplot(3,1,1);plot(signalDeconv);datetickzoom; title('Signal without instrument response')
            subplot(3,1,2);plot(freqAx(1:ceil(Nfft/2)),magSignalwithoutRESP(1:ceil(Nfft/2),:));ylim([0 100]); title('Amplitude')
            subplot(3,1,3);plot(freqAx(1:ceil(Nfft/2)),phaseSignalwithoutRESP(1:ceil(Nfft/2),:));title('Phase') %Se plottassi i grafici fino alla frequenza di campionamento
            
            %9)
            figure;subplot(2,1,1);semilogx(freqAx(1:ceil(Nfft/2)),magRawSignal(1:ceil(Nfft/2),:)/trasdConstTrillium); title('Mag RAW signal');
            hold on;semilogx(freqAx(1:ceil(Nfft/2)),magSignalwithoutRESP(1:ceil(Nfft/2),:));title('Mag signal without RESP');
            ylim([0 0.01])
            subplot(2,1,2);plot(freqAx(1:ceil(Nfft/2)),unwrap(phaseRawSignal(1:ceil(Nfft/2),:)));title('Phase RAW signal')
            hold on;plot(freqAx(1:ceil(Nfft/2)),unwrap(phaseSignalwithoutRESP(1:ceil(Nfft/2),:)));title('Phase signal without RESP')
            suptitle('Comparison RAW vs RAW without RESP')
        end
        
        
    end
end

set(findobj(fui,'type','uicontrol'),'enable','on')
set(findobj(fui,'tag','pleaseWait'),'visible','off');

