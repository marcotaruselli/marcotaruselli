clear; clc; close('all','force');

% Performs deconvolution of the acquisition chain (sensor + digitizer) through spectral division.
% Works with *.miniseed (Nanometrics) and *.mseed (Geopsy) files.

currDir = cd;

fui = figure('units','normalized','position',[.3 .3 .4 .3],'menubar','none','name','Response Deconvolution','numbertitle','off');

uicontrol('style','text','units','normalized','position',[.01 .9 .85 .1],'string','Select Folder with JEvalResp')
uicontrol('style','edit','units','normalized','position',[.01 .8 .85 .1],'enable','off','string',currDir,'tag','jEvalFolder');
uicontrol('style','pushbutton','units','normalized','position',[.865 .8 .13 .1],'string','Browse','callback','FolderButtonpushed(currDir,fui);')

uicontrol('style','text','units','normalized','position',[.01 .65 .85 .1],'string','Select Sensor response')
uicontrol('style','edit','units','normalized','position',[.01 .55 .85 .1],'enable','off','tag','sensorRespName');
uicontrol('style','pushbutton','units','normalized','position',[.865 .55 .13 .1],'string','Browse','callback','SensorButtonpushed(currDir,fui);')

uicontrol('style','text','units','normalized','position',[.01 .4 .85 .1],'string','Select Digitizer response')
uicontrol('style','edit','units','normalized','position',[.01 .3 .85 .1],'enable','off','tag','digitizerRespName');
uicontrol('style','pushbutton','units','normalized','position',[.865 .3 .13 .1],'string','Browse','callback','DigitizerButtonpushed(currDir,fui);')

uicontrol('style','text','units','normalized','position',[.25 .03 .1 .07],'string','Filter','horizontalalignment','right')
uicontrol('style','popupmenu','units','normalized','position',[.36 .08 .12 .04],'string',{'None','HighPass'},'value',2,'tag','filterType');
uicontrol('style','edit','units','normalized','position',[.49 .045 .08 .07],'string','0.05','tag','filterFreq');

uicontrol('style','checkbox','units','normalized','position',[.65 .05 .15 .05],'value',1,'string','Plot results','tag','plotResults');

uicontrol('style','pushbutton','units','normalized','position',[.865 .03 .13 .13],'string','Deconvolve','fontweight','bold','callback',...
    '[signalRaw,signalDeconv,fs] = ResponseDeconvolution(fui);')

uicontrol('style','text','units','normalized','position',[.05 .05 .3 .1],'string','Please wait...','visible','off','tag','pleaseWait')