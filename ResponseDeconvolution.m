function [signalDeconv] = ResponseDeconvolution(fui,jEvalFolderstring,signalRaw,fs,sensorRespName,digitizerRespName,filterType,filterFreq,plotResults,timeAx)


global utilities
% trasdConstTrillium = 301239990;     %Serve solo per plottare il confronto tra segnale RAW e deconvoluto

signalDeconv = NaN;


% set(findobj(fui,'type','uicontrol'),'enable','off')
% set(findobj(fui,'tag','pleaseWait'),'visible','on','enable','on');
%
% set(findobj(fui,'tag','sensorRespName'),'string');
%
% tmpstring = get(findobj(fui,'tag','jEvalFolder'),'string');
originalPath = cd;
cd(jEvalFolderstring);
% addpath(folder)
%
% tmpString1 = get(findobj(fui,'tag','sensorRespName'),'string');
% tmpIndex = strfind(tmpString1,'\');
% sensorRespName = tmpString1(tmpIndex(end)+1:end);
% status = copyfile(tmpString1,tmpstring,'f');
% tmpString2 = get(findobj(fui,'tag','digitizerRespName'),'string');
% tmpIndex = strfind(tmpString2,'\');
% digitizerRespName = tmpString2(tmpIndex(end)+1:end);
% status = copyfile(tmpString2,tmpstring,'f');
%
% filterTypeValue = get(findobj(fui,'tag','filterType'),'value');
% filterTypeString = get(findobj(fui,'tag','filterType'),'string');
% filterType = filterTypeString{filterTypeValue};
% filterFreq = str2num(get(findobj(fui,'tag','filterFreq'),'string'));


% %% Preparo il segnale
% [signalRaw,~] = highpass(signalRaw,filterFreq,fs,'ImpulseResponse','iir','Steepness',0.95);
% signalRaw = signalRaw - mean(signalRaw);

%% Compute spectrum of the signal
%     Nfft = 2^14;
Nfft = 2^nextpow2(size(signalRaw,1));
freqAx = 0:fs/(Nfft-1):fs;
signalRawF = fft(signalRaw,Nfft);

%% Compute Instrument responses with Java routine
set(findobj(fui,'tag','pleaseWait'),'visible','on','string','Computing Instrument response with Java routine...'); drawnow;
% Digitizer (Centaur)
if not(isempty(digitizerRespName))
code = ['java -Xmx512m -jar JEvalResp.jar "*" "*" "*" "*" ' num2str(0) ' ' num2str(fs) ' ' num2str(Nfft) ' -f ' digitizerRespName ' -u vel  -r cs -v -s lin'];
eval([ '[status,result] = system(''' code ''')'])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Per il Raspberry il file creato viene salvato con un nome strano quindi
%%% devo selezionare l'ultimo file creato nella cartella
%Get the directory contents
dirc = dir(jEvalFolderstring);
%Filter out all the folders.
dirc = dirc(find(~cellfun(@isdir,{dirc(:).name})));
%I contains the index to the biggest number which is the latest file
[A,I] = max([dirc(:).datenum]);
if ~isempty(I)
    digitizerSpectraNameCreated = dirc(I).name;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

% Sensor (Trillium)
if not(isempty(sensorRespName))
code = ['java -Xmx512m -jar JEvalResp.jar "*" "*" "*" "*" ' num2str(0) ' ' num2str(fs) ' ' num2str(Nfft) ' -f ' sensorRespName ' -u vel -r cs -v -s lin'];
eval([ '[status,result] = system(''' code ''')'])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Per il Raspberry il file creato viene salvato con un nome strano quindi
%%% devo selezionare l'ultimo file creato nella cartella
%Get the directory contents
dirc = dir(jEvalFolderstring);
%Filter out all the folders.
dirc = dirc(find(~cellfun(@isdir,{dirc(:).name})));
%I contains the index to the biggest number which is the latest file
[A,I] = max([dirc(:).datenum]);
if ~isempty(I)
    sensorSpectraNameCreated = dirc(I).name;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
%% Convert Instrument response files to .txt
set(findobj(fui,'tag','pleaseWait'),'visible','on','string','Converting Instrument response files to .txt...'); drawnow;
if not(isempty(sensorRespName))
tmpIndex = strfind(sensorRespName,'Z');
sensorSpectraName = [sensorSpectraNameCreated '.txt'];
status = movefile(sensorSpectraNameCreated,sensorSpectraName);
end
if not(isempty(digitizerRespName))
tmpIndex = strfind(digitizerRespName,'Z');
digitizerSpectraName = [digitizerSpectraNameCreated '.txt'];
status = movefile(digitizerSpectraNameCreated,digitizerSpectraName);
end

%% Substitute comma with dot
set(findobj(fui,'tag','pleaseWait'),'visible','on','string','Substituting commas with dots in *.txt files...'); drawnow;
% Sensor
if not(isempty(sensorRespName))
fid = fopen(sensorSpectraName);
dataTemp = textscan(fid,'%s%s%s');
fclose(fid);
%     FreqAxS = str2double(strrep(dataTemp{1,1}, ',', '.'))';
sensorReal =  str2double(strrep(dataTemp{1,2}, ',', '.'))';
sensorImag =  str2double(strrep(dataTemp{1,3}, ',', '.'))';
end
% Digitizer
if not(isempty(digitizerRespName))
fid = fopen(digitizerSpectraName);
dataTemp = textscan(fid,'%s%s%s');
fclose(fid);
%     FreqAxD = str2double(strrep(dataTemp{1,1}, ',', '.'))';
digitizerReal =  str2double(strrep(dataTemp{1,2}, ',', '.'))';
digitizerImag =  str2double(strrep(dataTemp{1,3}, ',', '.'))';
end

%% Crea risposta dei sensori
set(findobj(fui,'tag','pleaseWait'),'visible','on','string','Creating Instrument response...'); drawnow;
% Make Sensor FRF Hermitian
if not(isempty(sensorRespName))
sensorFRFTemp = sensorReal + sensorImag*1i;
sensorFRF = [sensorFRFTemp(1:Nfft/2 + 1) conj(fliplr(sensorFRFTemp(2:Nfft/2)))];
end
% Make Digitizer FRF Hermitian
if not(isempty(digitizerRespName))
digitizerFRFTemp = digitizerReal +digitizerImag*1i;
digitizerFRF = [digitizerFRFTemp(1:Nfft/2 + 1) conj(fliplr(digitizerFRFTemp(2:Nfft/2)))];
end

%% Instrument response removal (Deconvolution)
set(findobj(fui,'tag','pleaseWait'),'visible','on','string','Removing Instrument response...'); drawnow;
if not(isempty(digitizerRespName)) %se c'è anche digitalizzatore
signalDeconvF = signalRawF./(conj(digitizerFRF'));
signalDeconvF = signalDeconvF./(conj(sensorFRF'));
else %se c'è solo risposta del sensore
signalDeconvF = signalRawF./(conj(sensorFRF'));
% signalDeconvF = signalRawF.*(conj(sensorFRF'));
end
signalDeconvF(1,:) = 0;
signalDeconv = ifft(signalDeconvF,Nfft,'symmetric');
signalDeconv = signalDeconv(1:size(signalRaw,1),:);


%% remove files used to deconvolve
% answer = questdlg('Discard files used for deconvolution? This process does not delete the selected RESPs','Discard files','Yes','No','Yes');
% if strcmpi(answer,'Yes')
    if not(isempty(digitizerRespName))
        eval(['delete '  sensorSpectraName ' ' digitizerSpectraName ';'])
    else
        eval(['delete '  sensorSpectraName ';'])
    end
% end

cd(originalPath);
%% Filtering
if not(strcmpi(filterType,'none'))
    signalRaw = DataFiltering(signalRaw,fs,timeAx,filterType,filterFreq,0);
    signalDeconv = DataFiltering(signalDeconv,fs,timeAx,filterType,filterFreq,0);
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


if plotResults
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
    
    if not(isempty(digitizerRespName))
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
    else
    % Response functions of sensor 
    figure('name','SENSOR FRFs');
    subplot(2,1,1)
    plot(freqAx,abs(sensorFRF))
    grid on; grid minor;
    ylabel('Amplitude');title('SENSOR FRF')
    subplot(2,1,2)
    plot(freqAx,angle(sensorFRF))
    grid on; grid minor
    ylabel('Phase [rad]'); xlabel('Frequency (Hz)')      
    end
end

