% datafolder1 = fullfile('E:\', 'common_voice','cv-valid-train');
% ads_voice = audioDatastore(datafolder1,'IncludeSubfolders',true,'FileExtensions','.mp3','LabelSource','foldernames');
% datafolder2 = fullfile('G:\', 'musicNYU','background_noise');
% ads_noise = audioDatastore(datafolder2,'IncludeSubfolders',true,'FileExtensions','.wav','LabelSource','foldernames');
%  numFiles_voice = length(ads_voice.Files);
% 
% fs = 16e3;
% segmentDuration = 1;
% frameDuration = 0.025;
% hopDuration = 0.010;
% numBands = 40;
% frameLength = round(frameDuration*fs);
% hopLength = round(hopDuration*fs);
% 
% indices = (1:100:numFiles_voice) + 1;
% test_ads = subset(ads_voice,indices);
% 
% ns_voice = 40;
% % % ns_noisy = 0;
% ns_noise = 40;
% 
% Xtest_voice = testSetVoice(test_ads,ns_voice);
% % % ADSnew_shuffle = shuffle(ADSnew);
% % % Xtrain_noisy = trainSetNoisy(ADSnew_shuffle,ads_noise,ns_noisy);
% % % Xtrain_ = cat(4,Xtrain_voice,Xtrain_noisy);
% 
%  [~,~,~,numV] = size(Xtest_voice);

Xtest_noise = testSetNoise(ads_noise,ns_noise);
% Xtest = cat(4,Xtest_voice,Xtest_noise);
% [~,~,~,numN] = size(Xtest_noise);
% Ytest = "voice";
% Ytest = categorical(Ytest);
% Ytest(1:numV,1) = "voice";
% Ytest(1+ numV:numV+numN,1) = "noise";
 
%  net = load('voice_noise_net.mat','my_net');
%  net = net.my_net;
%  Preds = classify(net,Xtest);
%  numCorrect = nnz(Preds == Ytest);
% fracCorrect = numCorrect/length(Ytest);


    
    

