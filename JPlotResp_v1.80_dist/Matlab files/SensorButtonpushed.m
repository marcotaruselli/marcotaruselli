function SensorButtonpushed(currDir,fui)

[filename, path] = uigetfile([currDir '\*.*'],'Select Sensor Response file','MultiSelect','off');
set(findobj(fui,'tag','sensorRespName'),'string',[path filename]);

end