function FolderButtonpushed(currDir,fui)

selpath = uigetdir(currDir,'Select Folder with JEvalResp');
set(findobj(fui,'tag','jEvalFolder'),'string',selpath);

end