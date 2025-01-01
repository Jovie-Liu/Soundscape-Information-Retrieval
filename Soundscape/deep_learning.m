img = imread('filename.png');
imshow(img)
net = alexnet;
pred = classify(net,img);
ly = net.Layers;
inlayer = ly(1);
insz = inlayer.InputSize;
layer3 = ly(3);
sz3 = layer3.InputSize;
outlayer = ly(end);
categorynames = outlayer.Classes;

% The classify function gives the class to which the network 
% assigns the highest score. You can obtain the predicted scores for 
% all the classes 
[pred,scores] = classify(net,img);
bar(scores);
highscores = scores > 0.01;
bar(scores(highscores));
xticklabels(categorynames(highscores));

%dynamic criterion
%thresh = median(scores) + std(scores);
%highscores = scores > thresh;

%–±÷√±Í«©
% xticks(1:length(scores(highscores)))
% xticklabels(categorynames(highscores))
% xtickangle(60)

%datastore
imds = imageDatastore('file*.jpg'); %filenames starting with 'file'
fname = imds.Files;
img = readimage(imds,7); %read; readimage; readall
preds = classify(net,imds);
[preds,scores] = classify(net,imds);
max(scores,[],2);

%image preprocess
sz = size(img);
% net = alexnet;
% inlayer = net.Layers(1);
insz = inlayer.InputSize;
img = imresize(img,[227,227]); %input size 227x227x3
imshow(img);

%image preprocessing in datastore
imds = imageDatastore('*.jpg');
auds = augmentedImageDatastore([227 227],imds);
preds = classify(net, auds);

%convert grayscale to color image
montage(imds); %display images
auds = augmentedImageDatastore([227 227],imds,'ColorPreprocessing','gray2rgb');
preds = classify(net,auds);

%subfolder
flwrds = imageDatastore('Flowers','IncludeSubfolders',true);

%transfer learning
%label images
load pathToImages
flwrds = imageDatastore(pathToImages,'IncludeSubfolders',true,"LabelSource","foldernames");
flowernames = flwrds.Labels;

[flwrTrain, flwrTest] = splitEachLabel(flwrds,0.6,"randomized"); % 60% for training
[flwrTrain, flwrTest] = splitEachLabel(flwrds,50); % 50 images in training

%modify network layers
anet = alexnet;
layers = anet.Layers;
fc = fullyConnectedLayer(12);
layers(23) = fc;
layers(end) = classificationLayer;

opts = trainingOptions('sgdm','InitialLearnRate',0.001);

%Evaluating performance

plot(info.TrainingLoss);
flwrPreds = classify(flowernet,testImgs);
flwrActual = testImgs.Labels;
numCorrect = nnz(flwrPreds == flwrActual);
fracCorrect = numCorrect/length(flwrActual);

%The (j,k) element of the confusion matrix is a count of how many images 
% from class j the network predicted to be in class k. Hence, diagonal 
% elements represent correct classifications; off-diagonal elements represent misclassifications.
confusionchart(testImgs.Labels,flwrPreds);


