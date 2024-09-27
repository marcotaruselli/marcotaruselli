function DigitizerButtonpushed(currDir,fui)

[filename, path] = uigetfile([currDir '\*.*'],'Select Digitizer Response file','MultiSelect','off');
set(findobj(fui,'tag','digitizerRespName'),'string',[path filename]);

end