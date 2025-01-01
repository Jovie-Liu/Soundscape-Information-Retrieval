function C = trainSetNoise_parallel(ads_noise,numV)

fs = 16e3;
segmentDuration = 1;
frameDuration = 0.025;
hopDuration = 0.010;
numBands = 40;
frameLength = round(frameDuration*fs);
hopLength = round(hopDuration*fs);
inputFs = 44100;
numHops = ceil((segmentDuration - frameDuration)/hopDuration);

decimationFactor = 441;

% % src = dsp.SampleRateConverter("InputSampleRate",inputFs, ...
% %         "OutputSampleRate",fs, ...
% %         "Bandwidth",7920);
    
%1000s noisy signal
sumFiles_noise = length(ads_noise.Files);

C = cell(numV,1);
parfor i = 1: numV

    num_noise = 1+randi(5);
    index_noise = randi(sumFiles_noise,1,num_noise);
    sample_noise = subset(ads_noise,index_noise);
    
    base = read(sample_noise);
    if numel(base) >= 2*44100
    src = dsp.SampleRateConverter("InputSampleRate",inputFs, ...
        "OutputSampleRate",fs, ...
        "Bandwidth",7920);
    
    L = floor(numel(base)/decimationFactor);
    base = base(1:decimationFactor*L);
    base = src(base);
    
    noise_aggregate = zeros(numel(base),1);
    
    for j = 1:num_noise-1
        
        noise = read(sample_noise);
        
        src = dsp.SampleRateConverter("InputSampleRate",inputFs, ...
        "OutputSampleRate",fs, ...
        "Bandwidth",7920);
    
        L = floor(numel(noise)/decimationFactor);
        noise = noise(1:decimationFactor*L);
        noise = src(noise);
        
        
        if numel(noise) > numel(base)
            ind          = randi(numel(noise) - numel(base) + 1, 1, 1);
            noiseSegment = noise(ind:ind + numel(base) - 1);
            noise_aggregate = noise_aggregate + noiseSegment;
        else
            ind          = randi(numel(base) - numel(noise) + 1, 1, 1);
            temp = zeros(numel(base),1);
            temp(ind:ind + numel(noise) - 1) = noise;
            noise_aggregate = noise_aggregate + temp;
        end
    end
    noise_aggregate = HelperGetSpeechSegments(noise_aggregate,fs);
    noise_aggregate = noise_aggregate{1};
    noise_aggregate  = noise_aggregate / max(abs(noise_aggregate));
    
% %     L = floor(numel(noise_aggregate)/decimationFactor);
% %     noise_aggregate = noise_aggregate(1:decimationFactor*L);
% %     noise_aggregate = src(noise_aggregate);
% %     reset(src)
        
    S = melSpectrogram(noise_aggregate,fs, ...
        'WindowLength',frameLength, ...
        'OverlapLength',frameLength - hopLength, ...
        'FFTLength',512, ...
        'NumBands',numBands, ...
        'FrequencyRange',[50,7000]);
    
    if length(S(1,:)) >= numHops
        [y,~] = buffer(S(1,:),numHops);
        [~,numClips] = size(y);
        X = zeros([numBands,numHops,1,numClips],'single');
        
        for k = 1:numBands
            [y,~] = buffer(S(k,:),numHops);
            X(k,:,1,:) = y;
        end
        
        epsil = 1e-6;
        X = log10(X + epsil);
    else
        X = [];
    end
    C{i} = X;
    else
        C{i} = [];
    end
end