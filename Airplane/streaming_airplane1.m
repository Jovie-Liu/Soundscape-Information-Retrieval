airnet = load('airnet.mat');
airnet = airnet.airnet;

% streaming audio
fs = 16e3;
classificationRate = 20;
audioIn = audioDeviceReader('SampleRate',fs, ...
    'SamplesPerFrame',floor(fs/classificationRate));
frameDuration = 0.025;
hopDuration = 0.010;
frameLength = floor(frameDuration*fs);
numBands = 40;
hopLength = floor(hopDuration*fs);
waveBuffer = zeros([fs,1]);

labels = airnet.Layers(end).Classes;
YBuffer(1:classificationRate/2) = categorical("background");
probBuffer = zeros([numel(labels),classificationRate/2]);

h = figure('Units','normalized','Position',[0.2 0.1 0.6 0.8]);

    specMin = -6;
    specMax = 2.3;


subplot(2, 4, [1 2]);
hWave = plot(zeros(1, fs));
axis tight
ylim([-1 1])
grid on

subplot(2, 4, [3 4])
hPcolor = pcolor(zeros(40, 98));
caxis([specMin+2 specMax])
shading flat

subplot(2, 4, [5 8])
hStem = stem(rand(1, 12), '.', 'linewidth', 30);
xlim([0.5 12.5]), grid on
ylim([0 1])


while ishandle(h)

    % Extract audio samples from the audio device and add the samples to
    % the buffer.
    x = audioIn();
    waveBuffer(1:end-numel(x)) = waveBuffer(numel(x)+1:end);
    waveBuffer(end-numel(x)+1:end) = x;

    % Compute the spectrogram of the latest audio samples.
    spec = melSpectrogram(waveBuffer,fs, ...
        'WindowLength',frameLength, ...
        'OverlapLength',frameLength - hopLength, ...
        'FFTLength',512, ...
        'NumBands',numBands, ...
        'FrequencyRange',[50,7000]);
    epsil = 1e-6;
    spec = log10(spec + epsil);

    % Classify the current spectrogram, save the label to the label buffer,
    % and save the predicted probabilities to the probability buffer.
    [YPredicted,probs] = classify(airnet,spec,'ExecutionEnvironment','cpu');
    YBuffer(1:end-1)= YBuffer(2:end);
    YBuffer(end) = YPredicted;
    probBuffer(:,1:end-1) = probBuffer(:,2:end);
    probBuffer(:,end) = probs';
 
    % Plot the current waveform and spectrogram.
%     subplot(2,1,1);
%     plot(waveBuffer)
%     axis tight
%     ylim([-0.2,0.2])

%     subplot(2,1,2)
%     subplot(211)
%     pcolor(spec)
%     specMin = -6;
%     specMax = 2.3;
%     caxis([specMin+2 specMax])
%     shading flat

    drawnow;
    
    try
        set(hWave, 'ydata', waveBuffer);
        set(hPcolor, 'cdata', spec);  
        set(hStem, 'ydata', probs);        

        if YMode == "background" || count<countThreshold || maxProb < probThreshold
            %title(" ")
        else
            %title(string(YMode),'FontSize',20)
        end

        drawnow        
    catch me
    end
    
% %     % Now do the actual command detection by performing a very simple
% %     % thresholding operation. Declare a detection and display it in the
% %     % figure title if all of the following hold:
% %     % 1) The most common label is not |background|.
% %     % 2) At least |countThreshold| of the latest frame labels agree.
% %     % 3) The maximum predicted probability of the predicted label is at
% %     % least |probThreshold|. Otherwise, do not declare a detection.
% %     [YMode,count] = mode(YBuffer);
% %     countThreshold = ceil(classificationRate*0.2);
% %     maxProb = max(probBuffer(labels == YMode,:));
% %     probThreshold = 0.7;
% %     subplot(2,1,1);
% %     if YMode == "noise" || count<countThreshold || maxProb < probThreshold
% %         title(" ")
% %     else
% %         title(string(YMode),'FontSize',20)
% %     end

% subplot(2,1,1);

probThreshold = 0.69;
judge = floor(numel(YBuffer)*0.3);
if all(YBuffer(end-judge:end) == 'airplane') && min(probBuffer(labels == 'airplane',end-judge:end)) > probThreshold
    title('airplane','FontSize',20)
else
    title(" ")
end

% if sum(YBuffer == 'airplane')/numel(YBuffer) > 0.1
%     title('airplane','FontSize',20)
% else
%     title(" ")
% end
     drawnow

end