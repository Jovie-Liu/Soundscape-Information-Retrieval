fds = fileDatastore(fullfile('/Users/student/Desktop/dog+bark'),'ReadFcn',@load,'FileExtensions','.mat');
numFiles = length(fds.Files);
for i = 1: numFiles
    data = read(fds);
    tags = lower(data.metadata.tags);
    
    dog = strfind(tags,'dog');
    indicator = false;
    for j = 1:length(dog)
        if ~isempty(dog{j})
            indicator = true;
            break;
        end
    end
    
    if indicator == false
        file = data.metadata.filenameOrig;
        A = [file,'.mat'];
        delete(A)
        B = [file,'.wav'];
        delete(B)
    end

    
end
