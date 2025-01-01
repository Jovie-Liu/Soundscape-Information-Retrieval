function X = testSetVoice(test_ads,ns)

fs = 16e3;
segmentDuration = 1;
frameDuration = 0.025;
hopDuration = 0.010;
numBands = 40;
frameLength = round(frameDuration*fs);
hopLength = round(hopDuration*fs);

%20s voice signal ns = 20
duration      = ns*fs;
audioTestVoice = zeros(duration,1);
%maxSilenceSegment = 0.5;

numSamples = 1;
while numSamples < duration
    [data,info] = read(test_ads);
    inputFs = info.SampleRate;
    
    src = dsp.SampleRateConverter("InputSampleRate",inputFs, ...
    "OutputSampleRate",fs, ...
    "Bandwidth",7920);

    decimationFactor = inputFs/fs;
    L = floor(numel(data)/decimationFactor);
        data = data(1:decimationFactor*L);
        data = src(data);
    
    % Remove non-voice areas from the segment
    data = HelperGetSpeechSegments(data,fs);
    data = data{1};
    data  = data/ max(abs(data));
    audioTestVoice(numSamples:numSamples+numel(data)-1) = data;
%     %add noise
%     num_noise = randi(6);
%     index_noise = randi(sumFiles_noise,1,num_noise);
%     noise_aggregate = zeros(numel(data),1);
%     sample_noise = subset(ads_noise,index_noise);
%     sample_noise = transform(sample_noise,@SampleRateConvert,'IncludeInfo',true);
%     for j = 1:num_noise
%         noise = read(sample_noise);
%         
%         if numel(noise) > numel(data)
%             ind          = randi(numel(noise) - numel(data) + 1, 1, 1);
%             noiseSegment = noise(ind:ind + numel(data) - 1);
%             noise_aggregate = noise_aggregate + noiseSegment;
%         else
%             ind          = randi(numel(data) - numel(noise) + 1, 1, 1);
%             temp = zeros(numel(data),1);
%             temp(ind:ind + numel(noise) - 1) = noise;
%             noise_aggregate = noise_aggregate + temp;
%         end
%     end
%     SNR = randi(20)+10;
%     noise_aggregate  = noise_aggregate / max(abs(noise_aggregate));
%     noise_mix               = 10^(-SNR/20) * noise_aggregate * norm(data) / norm(noise_aggregate);
%     audioNoisy  = data + noise_mix;
%     audioNoisy  = audioNoisy / max(abs(audioNoisy));
%     
%     % Write noisy segment to training signal
%      audioTestVoice(numSamples:numSamples+numel(audioNoisy)-1) = audioNoisy;
%     % Random noise period
%     numSilenceSamples = randi(maxSilenceSegment * fs,1,1);
%     ind          = randi(numel(noise_aggregate)-numSilenceSamples + 1, 1, 1);
%     noise_silence = noise_aggregate(ind:ind + numSilenceSamples - 1);
%      audioTestVoice(numSamples+numel(audioNoisy):numSamples+numel(audioNoisy)+ numSilenceSamples-1) = noise_silence;
    
    numSamples        = numSamples + numel(data);
end

range = 1:20*fs;
sound(audioTestVoice(range),fs)


S = melSpectrogram(audioTestVoice,fs, ...
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
