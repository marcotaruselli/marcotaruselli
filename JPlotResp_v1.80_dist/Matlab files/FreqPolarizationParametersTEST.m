clear; close('all','force'); clc;

fs = 200;
ts = 1/fs;
tw = 30*60;
f1 = [10 15];
f2 = [30 40];
f3 = [55 60];
f4 = [70 80];
f5 = [85 90];
angle1 = pi/4;
angle2 = 3*pi/4;
angle3 = 5*pi/4;
angle4 = 7*pi/4;
angle5 = [pi/8 pi/8];
timeAx = 0:ts:tw;
noiseScaling = .05;

noise = (rand(1,length(timeAx)) - 0.5)*noiseScaling;
sig1 = chirp(timeAx,f1(1),tw,f1(2));
sig2 = chirp(timeAx,f2(1),tw,f2(2));
sig3 = chirp(timeAx,f3(1),tw,f3(2));
sig4 = chirp(timeAx,f4(1),tw,f4(2));
sig5 = chirp(timeAx,f5(1),tw,f5(2));

sig = sig1 + sig2 + sig3 + sig4 + sig5;

data(:,1) = (sig1*cos(angle1) + sig2*cos(angle2) + sig3*cos(angle3) + sig4*cos(angle4) + sig5*sin(angle5(1))*cos(angle5(2)) + (rand(1,length(timeAx)) - 0.5)*noiseScaling)';
data(:,2) = (sig1*sin(angle1) + sig2*sin(angle2) + sig3*sin(angle3) + sig4*sin(angle4) + sig5*sin(angle5(1))*sin(angle5(2)) + (rand(1,length(timeAx)) - 0.5)*noiseScaling)';
data(:,3) = (sig5*cos(angle5(1)) + (rand(1,length(timeAx)) - 0.5)*noiseScaling)';

Nfft = 2^nextpow2(length(sig1));
sigF = fft(sig,Nfft);
df = fs/Nfft;
freqAx = 0:df:fs-df;

dataF = fft(data,Nfft);

figure
subplot(311)
plot(timeAx,sig)
subplot(312)
plot(freqAx(1:Nfft/2),abs(sigF(1:Nfft/2)))
subplot(313)
plot(freqAx(1:Nfft/2),angle(sigF(1:Nfft/2)))

figure
subplot(311)
plot(freqAx(1:Nfft/2),abs(dataF(1:Nfft/2,1)))
subplot(312)
plot(freqAx(1:Nfft/2),abs(dataF(1:Nfft/2,2)))
subplot(313)
plot(freqAx(1:Nfft/2),abs(dataF(1:Nfft/2,3)))



