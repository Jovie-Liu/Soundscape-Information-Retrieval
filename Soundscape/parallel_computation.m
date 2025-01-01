datafolder1 = fullfile('E:\', 'common_voice','cv-valid-train');
ads_voice = audioDatastore(datafolder1,'IncludeSubfolders',true,'FileExtensions','.mp3','LabelSource','foldernames');
datafolder2 = fullfile('G:\', 'musicNYU','background_noise');
ads_noise = audioDatastore(datafolder2,'IncludeSubfolders',true,'FileExtensions','.wav','LabelSource','foldernames');
 numFiles_voice = length(ads_voice.Files);

fs = 16e3;
segmentDuration = 1;
frameDuration = 0.025;
hopDuration = 0.010;
numBands = 40;
frameLength = round(frameDuration*fs);
hopLength = round(hopDuration*fs);
 
indices = 1:100:numFiles_voice;
train_ads = subset(ads_voice,indices);

[sample,info] = read(train_ads);
inputFs = info.SampleRate;
src = dsp.SampleRateConverter("InputSampleRate",inputFs, ...
    "OutputSampleRate",fs, ...
    "Bandwidth",7920);

T1 = tall(train_ads);
Xtrain_voice = cellfun(@(x)trainSetVoice(x,src),T1,"UniformOutput",false);
Xtrain_voice = gather(Xtrain_voice);
Xtrain_agg = [];
for i = 1:length(Xtrain_voice)
    if ~isempty(Xtrain_voice{i})
        Xtrain_agg = cat(4,Xtrain_agg,Xtrain_voice{i});
    end
end
[~,~,~,numV] = size(Xtrain_agg);

Xtrain_noise = trainSetNoise_parallel(ads_noise,round(numV/2));

Xtrain_reg = [];
for i = 1:length(Xtrain_noise)
    if ~isempty(Xtrain_background{i})
        Xtrain_reg = cat(4,Xtrain_reg,Xtrain_noise{i});
    end
end
[~,~,~,numN] = size(Xtrain_reg);

Ytrain = "voice";
Ytrain = categorical(Ytrain);
if numV < numN
    Xtrain_ = Xtrain_reg(:,:,:,1:numV);
    Xtrain = cat(4,Xtrain_agg,Xtrain_);
    Ytrain(1:numV,1) = "voice";
    Ytrain(1+ numV:numV+numV,1) = "noise";
else
    Xtrain_ = Xtrain_agg(:,:,:,1:numN);
    Xtrain = cat(4,Xtrain_,Xtrain_reg);
    Ytrain(1:numN,1) = "voice";
    Ytrain(1+ numN:numN+numN,1) = "noise";
end




net = load('commandNet.mat');
layers = net.trainedNet.Layers;
fc = fullyConnectedLayer(2); % 2 classes
layers(19) = fc;
layers(end) = classificationLayer;

miniBatchSize = 128;
% % validationFrequency = floor(numel(Ytrain)/miniBatchSize);
options = trainingOptions('adam', ...
    'InitialLearnRate',3e-4, ...
    'MaxEpochs',25, ...
    'MiniBatchSize',miniBatchSize, ...
    'Shuffle','every-epoch', ...
    'Plots','training-progress', ...
    'Verbose',false, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropFactor',0.1, ...
    'LearnRateDropPeriod',20);
% 
[my_net,infomation] = trainNetwork(Xtrain,Ytrain,layers,options);