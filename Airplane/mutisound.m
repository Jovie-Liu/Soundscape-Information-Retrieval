% datafolder = fullfile('G:\', 'musicNYU','background_noise','FSDnoisy18k.audio_train');
% ads = audioDatastore(datafolder,'IncludeSubfolders',true,'FileExtensions','.wav','LabelSource','foldernames');

% fs = 44100;
% segmentDuration = 1;
% frameDuration = 0.025;
% hopDuration = 0.010;
% numBands = 40;
% frameLength = round(frameDuration*fs);
% hopLength = round(hopDuration*fs);

T1 = tall(ads);
Xtrain = cellfun(trainSetMulti,T1,"UniformOutput",false);
Xtrain = gather(Xtrain);
Xtrain_agg = [];
for i = 1:length(Xtrain)
    if ~isempty(Xtrain{i})
        Xtrain_agg = cat(4,Xtrain_agg,Xtrain{i});
    end
end

YTrain_agg = ads.Labels;