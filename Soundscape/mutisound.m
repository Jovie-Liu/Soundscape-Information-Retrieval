% datafolder = fullfile('/Users/student/Desktop/','background_noise','FSDnoisy18k.audio_train');
% ads = audioDatastore(datafolder,'IncludeSubfolders',true,'FileExtensions','.wav','LabelSource','foldernames');

% fs = 44100;
% segmentDuration = 1;
% frameDuration = 0.025;
% hopDuration = 0.010;
% numBands = 40;
% frameLength = round(frameDuration*fs);
% hopLength = round(hopDuration*fs);

% T1 = tall(ads);
% Xtrain = cellfun(@trainSetMulti,T1,"UniformOutput",false);
% Xtrain = gather(Xtrain);
% Ytrain_agg = "Acoustic_guitar";
% Ytrain_agg = categorical(Ytrain_agg);
% Xtrain_agg = [];
% Ytrain = ads.Labels;
% for i = 1:length(Xtrain)
%     if ~isempty(Xtrain{i})
%         [~,~,~,numN] = size(Xtrain{i});
%         Xtrain_agg = cat(4,Xtrain_agg,Xtrain{i});
%         Ytrain_agg(end+1:end+numN) = Ytrain(i);
%     end
% end
% 
% Ytrain_agg(1) = [];

% [~,~,~,num] = size(Xtrain_agg);
% A = zeros(227,227,3,floor(num/2));
% A(100:139,100:197,1,:) = Xtrain_agg(:,:,:,1:floor(num/2));
% 
% B = zeros(227,227,3,num-floor(num/2));
% B(100:139,100:197,1,:) = Xtrain_agg(:,:,:,floor(num/2)+1:num);
% 
% epsil = 1e-6;
% sz = size(A);
% specSize = sz(1:2);
% imageSize = [specSize 3];
% augmenter = imageDataAugmenter( ...
%     'RandXTranslation',[-10 10], ...
%     'RandXScale',[0.8 1.2], ...
%     'FillValue',log10(epsil));
% augimdsTrainA = augmentedImageDatastore(imageSize,A,Ytrain_agg(1:floor(num/2)), ...
%     'DataAugmentation',augmenter);
% augimdsTrainB = augmentedImageDatastore(imageSize,B,Ytrain_agg(floor(num/2)+1:num), ...
%     'DataAugmentation',augmenter);
% ads_train = combine(augimdsTrainA,augimdsTrainB);

imageSize = [227 227 3];
Xtrain_agg(:,:,2:3,:) = 0;
augimdsTrain = augmentedImageDatastore(imageSize,Xtrain_agg,Ytrain_agg, ...
     'DataAugmentation',augmenter);

anet = alexnet;
layers = anet.Layers;
fc = fullyConnectedLayer(20); % 2 classes
layers(23) = fc;
layers(end) = classificationLayer;
% 
opts = trainingOptions('sgdm','InitialLearnRate',0.001);
[multi_net,infomation] = trainNetwork(augimdsTrain,layers,opts);

imageSize = [40 98 1];
classWeights = 1./countcats(Ytrain);
classWeights = classWeights'/mean(classWeights);
numClasses = numel(categories(Ytrain));

timePoolSize = ceil(imageSize(2)/8);
dropoutProb = 0.2;
numF = 36;
layers = [
    imageInputLayer(imageSize)

    convolution2dLayer(3,numF,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(3,'Stride',2,'Padding','same')

    convolution2dLayer(3,2*numF,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(3,'Stride',2,'Padding','same')

    convolution2dLayer(3,4*numF,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(3,'Stride',2,'Padding','same')

    convolution2dLayer(3,4*numF,'Padding','same')
    batchNormalizationLayer
    reluLayer
    convolution2dLayer(3,4*numF,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer([1 timePoolSize])

    dropoutLayer(dropoutProb)
    fullyConnectedLayer(numClasses)
    softmaxLayer
    weightedClassificationLayer(classWeights)];

miniBatchSize = 128;
validationFrequency = floor(numel(Ytrain)/miniBatchSize);
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

[airnet,infomation] = trainNetwork(Xtrain_5_30,Ytrain,layers,options);

