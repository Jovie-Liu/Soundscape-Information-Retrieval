datafolder = fullfile('/Users/student/Desktop/Rain');
ads_engine = audioDatastore(datafolder,'IncludeSubfolders',true,'FileExtensions','.wav');
numFiles_engine = length(ads_engine.Files);

fs = 16e3;
segmentDuration = 1;
frameDuration = 0.025;
hopDuration = 0.010;
numBands = 40;
frameLength = round(frameDuration*fs);
hopLength = round(hopDuration*fs);

Xtrain_agg = [];
for i = 1:numFiles_engine
    [audio,info] = read(ads_engine);
    inputFs = info.SampleRate;
    
    [P,Q] = rat(fs/inputFs);
    abs(P/Q*inputFs-fs);
    audio = resample(audio,P,Q);
    if isvector(audio)
        audio = HelperGetSpeechSegments(audio,fs);
        audio = audio{1};
        audio  = audio/ max(abs(audio));
        
        S = melSpectrogram(audio,fs, ...
            'WindowLength',frameLength, ...
            'OverlapLength',frameLength - hopLength, ...
            'FFTLength',512, ...
            'NumBands',numBands, ...
            'FrequencyRange',[0,8000]);
        numHops = 98; %ceil((segmentDuration - frameDuration)/hopDuration);
        if length(S(1,:)) >= numHops
            [y,~] = buffer(S(1,:),numHops);
            [~,numClips] = size(y);
            Xtrain = zeros([numBands,numHops,1,numClips],'single');
            
            for j = 1:numBands
                [y,~] = buffer(S(j,:),numHops);
                Xtrain(j,:,1,:) = y;
            end
            
            epsil = 1e-6;
            Xtrain = log10(Xtrain + epsil);
        else
            Xtrain = [];
        end
        
        if ~isempty(Xtrain)
            Xtrain_agg = cat(4,Xtrain_agg,Xtrain);
        end
    end
end