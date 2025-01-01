function X = testSetNoise(ads_noise,ns)

fs = 16e3;
segmentDuration = 1;
frameDuration = 0.025;
hopDuration = 0.010;
numBands = 40;
frameLength = round(frameDuration*fs);
hopLength = round(hopDuration*fs);
inputFs = 44100;

%20s noisy signal

duration      = ns*fs;
audioTestNoise = zeros(duration,1);
% % maxSilenceSegment = 0.5;
sumFiles_noise = length(ads_noise.Files);

numSamples = 1;
while numSamples < duration
    
    num_noise = 1+randi(5);
    index_noise = randi(sumFiles_noise,1,num_noise);
    sample_noise = subset(ads_noise,index_noise);
    
    base = read(sample_noise);
    
    src = dsp.SampleRateConverter("InputSampleRate",inputFs, ...
        "OutputSampleRate",fs, ...
        "Bandwidth",7920);
    
    decimationFactor = 441;
    
    L = floor(numel(base)/decimationFactor);
    base = base(1:decimationFactor*L);
    base = src(base);
    
    noise_aggregate = zeros(numel(base),1);
    
    for j = 1:num_noise-1
        
        noise = read(sample_noise);
        
        src = dsp.SampleRateConverter("InputSampleRate",inputFs, ...
            "OutputSampleRate",fs, ...
            "Bandwidth",7920);
        
        decimationFactor = 441;
        
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
    
    
    % Write noisy segment to training signal
    audioTestNoise(numSamples:numSamples+numel(noise_aggregate)-1) = noise_aggregate;
    % Random silence period
    % %         numSilenceSamples = randi(maxSilenceSegment * fs,1,1);
    
    numSamples        = numSamples + numel(noise_aggregate); % + numSilenceSamples;
    
end

range = 1:20*fs;
sound(audioTestNoise(range),fs)


S = melSpectrogram(audioTestNoise,fs, ...
    'WindowLength',frameLength, ...
    'OverlapLength',frameLength - hopLength, ...
    'FFTLength',512, ...
    'NumBands',numBands, ...
    'FrequencyRange',[50,7000]);

numHops = ceil((segmentDuration - frameDuration)/hopDuration);
[y,~] = buffer(S(1,:),numHops);
[~,numClips] = size(y);
X = zeros([numBands,numHops,1,numClips],'single');

for i = 1:numBands
    [y,~] = buffer(S(i,:),numHops);
    X(i,:,1,:) = y;
end

epsil = 1e-6;
X = log10(X + epsil);