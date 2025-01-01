function Xtrain_music = trainSetMusic(audio)
if numel(audio) >= 2*44100
    fs = 16e3;
    inputFs = 44100;
    % % numSamples = 1;
    % % duration      = ns*fs;
    % % audioTraining = zeros(duration,1);
    % % maxSilenceSegment = 0.5;
    
    src = dsp.SampleRateConverter("InputSampleRate",inputFs, ...
    "OutputSampleRate",fs, ...
    "Bandwidth",7920);

    decimationFactor = 441;
    frameDuration = 0.025;
    hopDuration = 0.010;
    numBands = 40;
    frameLength = round(frameDuration*fs);
    hopLength = round(hopDuration*fs);
    
    L = floor(numel(audio)/decimationFactor);
    audio = audio(1:decimationFactor*L);
    audio = src(audio);
    reset(src)
    
    % Remove non-voice areas from the segment
    audio = HelperGetSpeechSegments(audio,fs);
    audio = audio{1};
    audio  = audio/ max(abs(audio));
    % Write speech segment to training signal
    % audioTraining = [audioTraining;audio];
    % Random silence period
    % %     numSilenceSamples = randi(maxSilenceSegment * fs,1,1);
    
    % numSamples        = numSamples + numel(audio); % + numSilenceSamples;
    S_voice = melSpectrogram(audio,fs, ...
        'WindowLength',frameLength, ...
        'OverlapLength',frameLength - hopLength, ...
        'FFTLength',512, ...
        'NumBands',numBands, ...
        'FrequencyRange',[50,7000]);
    numHops = 98; %ceil((segmentDuration - frameDuration)/hopDuration);
    if length(S_voice(1,:)) >= numHops
        [y,~] = buffer(S_voice(1,:),numHops);
        [~,numClips] = size(y);
        Xtrain_music = zeros([numBands,numHops,1,numClips],'single');
        
        for i = 1:numBands
            [y,~] = buffer(S_voice(i,:),numHops);
            Xtrain_music(i,:,1,:) = y;
        end
        
        epsil = 1e-6;
        Xtrain_music = log10(Xtrain_music + epsil);
    else
        Xtrain_music = [];
    end
else
    Xtrain_music = [];
end