data_processing =  data_processing_Existing;
% data_processing_Existing = data_processing;
for k = 1:size(data_processing_Importing,1)
    for j = 1:size(data_processing_Existing,1)
        if strcmp(data_processing_Importing(k).name,data_processing_Existing(j).name)
            quest = [data_processing_Importing(k).name ' already exists. Do you want to substitute it with the new one?'];
            defaultAnsw = 'Yes';
            answer = questdlg(quest,'Answer to continue','Yes','No',defaultAnsw)
            if strcmp(answer,'Yes')
                data_processing(j) = data_processing_Importing(k,:);
            end
            if strcmp(answer,'No')
                continue
            end
        else
            data_processing =[data_processing;  data_processing_Importing(k,:)];
            break
        end
    end
end

