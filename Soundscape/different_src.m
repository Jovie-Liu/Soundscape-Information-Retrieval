% datafolder = fullfile('/Users/student/Desktop/dog_barking');
% ads_engine = audioDatastore(datafolder,'IncludeSubfolders',true); %'FileExtensions','.wav');
% % Xtrain_carpassing = [];
% % for k = 1:20
% ads_engine = shuffle(ads_engine);
% % ads_engine = subset(ads_engine,1:6500);
% numFiles_engine = length(ads_engine.Files);

% % % 
% fs = 44100;
% segmentDuration = 1;
% frameDuration = 0.025;
% hopDuration = 0.010;
% numBands = 40;
% frameLength = round(frameDuration*fs);
% hopLength = round(hopDuration*fs);
% 
% audio_agg = [];
% for i = 1:numFiles_engine
%     try
%         [audio,info] = read(ads_engine);
%         
%             inputFs = info.SampleRate;
%         
%             [P,Q] = rat(fs/inputFs);
%             abs(P/Q*inputFs-fs);
%             audio = resample(audio,P,Q);
%         if isvector(audio)
%             audio = HelperGetSpeechSegments(audio,fs);
%             audio = audio{1};
%             audio  = audio/ max(abs(audio));
%             audio_agg = [audio_agg; audio];
%         end
%     catch e
%         disp(e)
%     end
% end
% 
% range = 1:20*fs;
% sound(audio_agg(range),fs)
% 
% S = melSpectrogram(audio_agg,fs, ...
%     'WindowLength',frameLength, ...
%     'OverlapLength',frameLength - hopLength, ...
%     'FFTLength',1536, ...
%     'NumBands',numBands, ...
%     'FrequencyRange',[0,8000]);
% numHops = 98; %ceil((segmentDuration - frameDuration)/hopDuration);
% if length(S(1,:)) >= numHops
%     [y,~] = buffer(S(1,:),numHops);
%     [~,numClips] = size(y);
%     Xtrain = zeros([numBands,numHops,1,numClips],'single');
%     
%     for j = 1:numBands
%         [y,~] = buffer(S(j,:),numHops);
%         Xtrain(j,:,1,:) = y;
%     end
%     
%     epsil = 1e-6;
%     Xtrain = log10(Xtrain + epsil);
% else
%     Xtrain = [];
% end

% % % Xtrain_carpassing = cat(4,Xtrain_carpassing,Xtrain);
% % % end

% Xtrain_other = cat(4,Xtrain_noise,Xtrain_voice(:,:,:,1:1000),Xtrain_carpassing(:,:,:,1:1000),Xtrain_rain(:,:,:,1:1000),Xtrain_sing,Xtrain_melody,Xtrain_siren);
% % [~,~,~,numA] = size(Xtrain_airplane_all(:,:,:,1:3500));
% [~,~,~,numB] = size(Xtrain_bird);
% % [~,~,~,numC] = size(Xtrain_carpassing);
% [~,~,~,numD] = size(Xtrain_dog);
% 
% % [~,~,~,numV] = size(Xtrain_voice_all(:,:,:,1:3500));
% [~,~,~,numO] = size(Xtrain_other);
% % 
% Xtrain_multi = cat(4,Xtrain_airplane(:,:,:,1:ceil(numA*0.85)),...
%     Xtrain_bird(:,:,:,1:ceil(numB*0.85)),Xtrain_carpassing(:,:,:,1:ceil(numC*0.85)),...
%     Xtrain_dog(:,:,:,1:ceil(numD*0.85)),...
%     Xtrain_voice(:,:,:,1:ceil(numV*0.85)),Xtrain_other(:,:,:,1:ceil(numO*0.85)));
% % 

% Xtrain_multi = cat(4,Xtrain_bird(:,:,:,1:ceil(numB*0.85)),...
%     Xtrain_dog(:,:,:,1:ceil(numD*0.85)),Xtrain_other(:,:,:,1:ceil(numO*0.85)));
% % 

% % % 
% Ytrain = "bird";
% Ytrain = categorical(Ytrain);
% % Ytrain(end+1:end+ceil(numA*0.85)) = "airplane";
% Ytrain(end+1:end+ceil(numB*0.85)) = "bird";
% % Ytrain(end+1:end+ceil(numC*0.85)) = "carpassing";
% Ytrain(end+1:end+ceil(numD*0.85)) = "dog";
% 
% % Ytrain(end+1:end+ceil(numV*0.85)) = "voice";
% Ytrain(end+1:end+ceil(numO*0.85)) = "other";
% Ytrain(1) = [];
% % 
% 
% Xtest_multi = cat(4,Xtrain_airplane(:,:,:,ceil(numA*0.85)+1:numA),...
%     Xtrain_bird(:,:,:,1+ceil(numB*0.85):numB),Xtrain_carpassing(:,:,:,1+ceil(numC*0.85):numC),...
%     Xtrain_dog(:,:,:,1+ceil(numD*0.85):numD),...
%     Xtrain_voice(:,:,:,1+ceil(numV*0.85):numV),Xtrain_other(:,:,:,1+ceil(numO*0.85):numO));
% 
% Xtest_multi = cat(4,Xtrain_bird(:,:,:,ceil(numB*0.85)+1:numB),...
%     Xtrain_dog(:,:,:,1+ceil(numD*0.85):numD),Xtrain_other(:,:,:,1+ceil(numO*0.85):numO));
% 
% Ytest = "bird";
% Ytest = categorical(Ytest);
% % Ytest(end+1:end+numA-ceil(numA*0.85)) = "airplane";
% Ytest(end+1:end+numB-ceil(numB*0.85)) = "bird";
% % Ytest(end+1:end+numC-ceil(numC*0.85)) = "carpassing";
% Ytest(end+1:end+numD-ceil(numD*0.85)) = "dog";
% 
% % Ytest(end+1:end+numV-ceil(numV*0.85)) = "voice";
% Ytest(end+1:end+numO-ceil(numO*0.85)) = "other";
% Ytest(1) = [];
% % % % 


% imageSize = [227 227 3];
% Xtrain_multi(:,:,2:3,:) = 0;
% Xtest_multi(:,:,2:3,:) = 0;

% imageSize = [40 98 1];
% epsil = 1e-6;
% augmenter = imageDataAugmenter( ...
%     'RandXTranslation',[-10 10], ...
%     'RandXScale',[0.8 1.2], ...
%     'FillValue',log10(epsil));
% augimdsTrain = augmentedImageDatastore(imageSize,Xtrain_multi,Ytrain, ...
%      'DataAugmentation',augmenter);
% augimdsTest = augmentedImageDatastore(imageSize,Xtest_multi,Ytest, ...
%      'DataAugmentation',augmenter);

% anet = alexnet;
% layers = anet.Layers;
% fc = fullyConnectedLayer(numel(categories(Ytrain))); % 2 classes
% layers(23) = fc;
% layers(end) = classificationLayer;
% % 
% 
% opts = trainingOptions('adam', ...
%     'InitialLearnRate',3e-4, ...
%     'MaxEpochs',25, ...
%     'MiniBatchSize',miniBatchSize, ...
%     'Shuffle','every-epoch', ...
%     'Plots','training-progress', ...
%     'Verbose',false, ...
%     'ValidationData',augimdsTest, ...
%     'ValidationFrequency',validationFrequency, ...
%     'LearnRateSchedule','piecewise', ...
%     'LearnRateDropFactor',0.1, ...
%     'LearnRateDropPeriod',20);
% [multi_net,infomation] = trainNetwork(augimdsTrain,layers,opts);


% classWeights = 1./countcats(Ytrain);
% classWeights = classWeights'/mean(classWeights);
% numClasses = numel(categories(Ytrain));
% 
% timePoolSize = ceil(imageSize(2)/8);
% dropoutProb = 0.2;
% numF = 30;
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
%     classificationLayer];
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
%     'ValidationData',{Xtest_multi,Ytest}, ...
%     'ValidationFrequency',validationFrequency, ...
%     'LearnRateSchedule','piecewise', ...
%     'LearnRateDropFactor',0.1, ...
%     'LearnRateDropPeriod',20);
% 
% [multinet,infomation] = trainNetwork(augimdsTrain,layers,options);
% % % 


% net = load('commandNet.mat');
% layers = net.trainedNet.Layers;
% fc = fullyConnectedLayer(numel(categories(Ytrain))); % 2 classes
% layers(19) = fc;
% layers(end) = classificationLayer;
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
%     'ValidationData',augimdsTest, ...
%     'ValidationFrequency',validationFrequency, ...
%     'LearnRateSchedule','piecewise', ...
%     'LearnRateDropFactor',0.1, ...
%     'LearnRateDropPeriod',20);
% 
% [my_net,infomation] = trainNetwork(augimdsTrain,layers,options);


% YValPred = classify(my_net,Xtest_multi);
% validationError = mean(YValPred' ~= Ytest);
% YTrainPred = classify(my_net,augimdsTrain);
% trainError = mean(YTrainPred' ~= Ytrain);
% disp("Training error: " + trainError*100 + "%")
% disp("Validation error: " + validationError*100 + "%")
% % 
% figure('Units','normalized','Position',[0.2 0.2 0.5 0.5]);
% cm = confusionchart(Ytest,YValPred);
% cm.Title = 'Confusion Matrix for Validation Data';
% cm.ColumnSummary = 'column-normalized';
% cm.RowSummary = 'row-normalized';
% sortClasses(cm, ["bird","dog","other"])

