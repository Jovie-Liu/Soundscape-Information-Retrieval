% datafolder1 = fullfile('/Users/student/Desktop/pro/airplane/aircraft_use');
% ads_plane = audioDatastore(datafolder1,'IncludeSubfolders',true,'FileExtensions','.wav');
%  numFiles_plane = length(ads_plane.Files);
% % 
% datafolder2 = fullfile('/Users/student/Desktop/airplane/background');
% ads_background = audioDatastore(datafolder2,'IncludeSubfolders',true,'FileExtensions','.wav');
% datafolder3 = fullfile('E:\', 'common_voice','cv-valid-train');
% ads_voice = audioDatastore(datafolder3,'IncludeSubfolders',true,'FileExtensions','.mp3');
% numFiles_voice = length(ads_voice.Files);
% 
% datafolder4 = fullfile('G:\', 'musicNYU','music_sound');
% ads_music = audioDatastore(datafolder4,'IncludeSubfolders',true,'FileExtensions','.wav');
% 
% fs = 16e3;
% segmentDuration = 1;
% frameDuration = 0.025;
% hopDuration = 0.010;
% numBands = 40;
% frameLength = round(frameDuration*fs);
% hopLength = round(hopDuration*fs);
 
% indices = ceil(numFiles_plane/2):numFiles_plane;
% train_ads = subset(ads_plane,indices);
% 
% [sample,info] = read(ads_plane);
% inputFs = info.SampleRate;
% src = dsp.SampleRateConverter("InputSampleRate",inputFs, ...
%     "OutputSampleRate",fs, ...
%     "Bandwidth",7920);
% 
% T1 = tall(ads_plane);
% Xtrain_plane = cellfun(@(x)trainSetPlane(x,src),T1,"UniformOutput",false);
% Xtrain_plane = gather(Xtrain_plane);
% Xtrain_agg = [];
% for i = 1:length(Xtrain_plane)
%     Xtrain_agg = cat(4,Xtrain_agg,Xtrain_plane{i});
% end
% [~,~,~,numP] = size(Xtrain_agg);

% [sample,info] = read(ads_background);
% inputFs = info.SampleRate;
% src = dsp.SampleRateConverter("InputSampleRate",inputFs, ...
%     "OutputSampleRate",fs, ...
%     "Bandwidth",7920);
% 
% T2 = tall(ads_background);
% Xtrain_background = cellfun(@(x)trainSetPlane(x,src),T2,"UniformOutput",false);
% Xtrain_background = gather(Xtrain_background);
% Xtrain_ate = [];
% for i = 1:length(Xtrain_background)
%     if ~isempty(Xtrain_background{i})
%         Xtrain_ate = cat(4,Xtrain_ate,Xtrain_background{i});
%     end
% end
%  [~,~,~,numB] = size(Xtrain_ate);

% indices2 = (1:100:numFiles_voice) + 3;
% train_ads = subset(ads_voice,indices2);
% 
% [sample,info] = read(train_ads);
% inputFs = info.SampleRate;
% src = dsp.SampleRateConverter("InputSampleRate",inputFs, ...
%     "OutputSampleRate",fs, ...
%     "Bandwidth",7920);
% 
% T3 = tall(train_ads);
% Xtrain_voice = cellfun(@(x)trainSetVoice(x,src),T3,"UniformOutput",false);
% Xtrain_voice = gather(Xtrain_voice);
% Xtrain_agg2 = [];
% for i = 1:length(Xtrain_voice)
%     if ~isempty(Xtrain_voice{i})
%         Xtrain_agg2 = cat(4,Xtrain_agg2,Xtrain_voice{i});
%     end
% end
% [~,~,~,numV2] = size(Xtrain_agg2);

% T4 = tall(ads_music);
% Xtrain_music = cellfun(@trainSetMusic,T4,"UniformOutput",false);
% Xtrain_music = gather(Xtrain_music);
% Xtrain_temusic = [];
% for i = 1:length(Xtrain_music)
%     if ~isempty(Xtrain_music{i})
%         Xtrain_temusic = cat(4,Xtrain_temusic,Xtrain_music{i});
%     end
% end
%  [~,~,~,numM] = size(Xtrain_temusic);
 
% Xtrain = cat(4,Xtrain_agg(:,:,:,1:numB),Xtrain_ate);
% Ytrain = "airplane";
% Ytrain = categorical(Ytrain);
% Ytrain(1:numB,1) = "airplane";
% Ytrain(numB+1:numB+numB,1) = "background";

% 
% imageSize = [40 98 1];
% classWeights = 1./countcats(Ytrain);
% classWeights = classWeights'/mean(classWeights);
% numClasses = numel(categories(Ytrain));
% 
% timePoolSize = ceil(imageSize(2)/8);
% dropoutProb = 0.2;
% numF = 36;
% layers = [
%     imageInputLayer(imageSize)
% 
%     convolution2dLayer(3,numF,'Padding','same')
%     batchNormalizationLayer
%     reluLayer
% 
%     maxPooling2dLayer(3,'Stride',2,'Padding','same')
% 
%     convolution2dLayer(3,2*numF,'Padding','same')
%     batchNormalizationLayer
%     reluLayer
% 
%     maxPooling2dLayer(3,'Stride',2,'Padding','same')
% 
%     convolution2dLayer(3,4*numF,'Padding','same')
%     batchNormalizationLayer
%     reluLayer
% 
%     maxPooling2dLayer(3,'Stride',2,'Padding','same')
% 
%     convolution2dLayer(3,4*numF,'Padding','same')
%     batchNormalizationLayer
%     reluLayer
%     convolution2dLayer(3,4*numF,'Padding','same')
%     batchNormalizationLayer
%     reluLayer
% 
%     maxPooling2dLayer([1 timePoolSize])
% 
%     dropoutLayer(dropoutProb)
%     fullyConnectedLayer(numClasses)
%     softmaxLayer
%     weightedClassificationLayer(classWeights)];
% 
% miniBatchSize = 128;
% validationFrequency = floor(numel(Ytrain)/miniBatchSize);
% options = trainingOptions('adam', ...
%     'InitialLearnRate',3e-4, ...
%     'MaxEpochs',25, ...
%     'MiniBatchSize',miniBatchSize, ...
%     'Shuffle','every-epoch', ...
%     'Plots','training-progress', ...
%     'Verbose',false, ...
%     'LearnRateSchedule','piecewise', ...
%     'LearnRateDropFactor',0.1, ...
%     'LearnRateDropPeriod',20);
% 
% [airnet,infomation] = trainNetwork(Xtrain_5_30,Ytrain,layers,options);

% Xtrain_5_30 = Xtrain;
% Xtrain_5_30(1:4,:,:,:) = [];
% Xtrain_5_30(end-9:end,:,:,:) = [];


% indices = 95:100;
% test_ads = subset(ads_plane,indices);
% Xtest = testSetPlane(test_ads,10);
% Preds = classify(airnet,Xtest);
% numCorrect = nnz(Preds == 'airplane');
% fracCorrect = numCorrect/length(Preds);

% XValidation = Xtrain_agg(:,:,:,end-999:end);
% XValidation_5_30 = XValidation;
% XValidation_5_30(1:4,:,:,:) = [];
% XValidation_5_30(end-9:end,:,:,:) = [];
% 
% YValidation = "airplane";
% YValidation = categorical(YValidation);
% YValidation(1:1000) = "airplane";
% YValPred = classify(airnet,XValidation_5_30);
% validationError = sum(YValPred ~= YValidation')/numel(YValidation);
% YTrainPred = classify(airnet,Xtrain_5_30);
% trainError = mean(YTrainPred ~= Ytrain);
% disp("Training error: " + trainError*100 + "%")
% disp("Validation error: " + validationError*100 + "%")





