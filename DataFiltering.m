function [dataOut,timeOut] = DataFiltering(dataIn,fs,timeAx,filterType,filterFreq,mutingPercentage)

%
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
switch(lower(filterType))
    case('highpass')
        [dataOut,d] = highpass(dataIn,filterFreq,fs,'ImpulseResponse','iir','Steepness',0.95);
    case('bandpass')
        [dataOut,d] = bandpass(dataIn,filterFreq,fs,'ImpulseResponse','iir','Steepness',0.9);
end
%     % Filter figure
%     figure
%     [h1,f] = freqz(d,8192,fs);
%     plot(f,mag2db(abs(h1)))
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Muting at the beginning and at the end to discard spurious oscillations due to filtering
if mutingPercentage > 0
    mutePerc = 0.05;
    L = size(dataOut,1);
    tapePerc = round(L*mutePerc);
    dataOut = dataOut(tapePerc:L-tapePerc,:);
    timeOut = timeAx(tapePerc:L-tapePerc,1);
end

