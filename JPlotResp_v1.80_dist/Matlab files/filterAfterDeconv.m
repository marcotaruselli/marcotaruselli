trasdConstTrillium = 301239990;

[signalRawFilt,d] = highpass(signalRaw,.05,fs,'ImpulseResponse','iir','Steepness',0.95);
[signalDeconvFilt,d] = highpass(signalDeconv,.05,fs,'ImpulseResponse','iir','Steepness',0.95);

% Filter figure
figure
[h1,f] = freqz(d,8192,fs);
plot(f,mag2db(abs(h1)))

Nfft = 2^nextpow2(size(signalRaw,1));
freqAx = 0:fs/(Nfft-1):fs;
signalRawF = fft(signalRaw,Nfft);
signalRawFiltF = fft(signalRawFilt,Nfft);
signalDeconvF = fft(signalDeconv,Nfft);
signalDeconvFiltF = fft(signalDeconvFilt,Nfft);

timeAx = 0:1/fs:(size(signalRaw,1)-1)*(1/fs);
% Raw Signal
figure('name','RAW SIGNAL')
subplot(3,2,1)
plot(timeAx,signalRaw)
ylabel('Vel [counts]');datetickzoom; title('RAW signal')
subplot(3,2,3)
plot(freqAx(1:ceil(Nfft/2)),abs(signalRawF(1:ceil(Nfft/2),:)))
ylabel('Amplitude')
subplot(3,2,5)
plot(freqAx(1:ceil(Nfft/2)),unwrap(angle(signalRawF(1:ceil(Nfft/2),:))))
ylabel('Phase')
subplot(3,2,2)
plot(timeAx,signalRawFilt)
ylabel('Vel [counts]');datetickzoom; title('RAW signal')
subplot(3,2,4)
plot(freqAx(1:ceil(Nfft/2)),abs(signalRawFiltF(1:ceil(Nfft/2),:)))
ylabel('Amplitude')
subplot(3,2,6)
plot(freqAx(1:ceil(Nfft/2)),unwrap(angle(signalRawFiltF(1:ceil(Nfft/2),:))))
ylabel('Phase')

% Deconvolved Signal
figure('name','DECONVOLVED SIGNAL')
subplot(3,2,1)
plot(timeAx,signalDeconv)
ylabel('Vel [m/s]');datetickzoom; title('DECONVOLVED signal')
subplot(3,2,3)
plot(freqAx(1:ceil(Nfft/2)),abs(signalDeconvF(1:ceil(Nfft/2),:)))
ylabel('Amplitude')
subplot(3,2,5)
plot(freqAx(1:ceil(Nfft/2)),unwrap(angle(signalDeconvF(1:ceil(Nfft/2),:))))
ylabel('Phase')
subplot(3,2,2)
plot(timeAx,signalDeconvFilt)
ylabel('Vel [m/s]');datetickzoom; title('DECONVOLVED signal')
subplot(3,2,4)
plot(freqAx(1:ceil(Nfft/2)),abs(signalDeconvFiltF(1:ceil(Nfft/2),:)))
ylabel('Amplitude')
subplot(3,2,6)
plot(freqAx(1:ceil(Nfft/2)),unwrap(angle(signalDeconvFiltF(1:ceil(Nfft/2),:))))
ylabel('Phase')


figure
plot(timeAx,signalRawFilt(:,1)/trasdConstTrillium,'-b')
hold on
plot(timeAx,signalDeconvFilt(:,1),'-r')
hold off
figure
plot(timeAx,signalRawFilt(:,2)/trasdConstTrillium,'-b')
hold on
plot(timeAx,signalDeconvFilt(:,2),'-r')
hold off
figure
plot(timeAx,signalRawFilt(:,3)/trasdConstTrillium,'-b')
hold on
plot(timeAx,signalDeconvFilt(:,3),'-r')
hold off