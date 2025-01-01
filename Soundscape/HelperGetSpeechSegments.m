function [segments, mask] = HelperGetSpeechSegments(audio,Fs)
%HELPERGETSPEECHSEGMENTS Extract speech segments from audio signal.

% Copyright (c) Theodoros Giannakopoulos All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
% * Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
% * Redistributions in binary form must reproduce the above copyright
% notice, this list of conditions and the following disclaimer in the
% documentation and/or other materials provided with the distribution
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
% IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
% THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
% PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
% CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
% This function is for internal use only and may change in the future.

%%
% Break the audio into 50-millisecond non-overlapping frames.
audio        = audio ./ max(abs(audio)); % Normalize amplitude
WindowLength = 50e-3 * Fs; %50e-3 * Fs
[segments,z]     = buffer(audio,WindowLength); %WindowLength

%%
% Compute the energy and spectral centroid for each frame.
numSegments      = size(segments,2);
signalEnergy     = zeros(1,numSegments);
win              = hamming(WindowLength);
freqBins         = (Fs/(2*WindowLength))*(1:WindowLength)';
spectralCentroid = zeros(1,numSegments);
for index = 1:numSegments
    data = segments(:,index);
    % Compute energy over window
    signalEnergy(index) = (1/(WindowLength)) * sum(abs(data.^2));
    % Multiply data by hamming window prior to spectral centroid
    % computation
    data = data .* win;
    dataFFT = (abs(fft(data,2*WindowLength)));
    dataFFT = dataFFT(1:WindowLength);  
    dataFFT = dataFFT / max(dataFFT);
    % Set centroid of low-energy segments to 0
    if (sum(data.^2)<0.010)
        spectralCentroid(index) = 0.0;
    else
        spectralCentroid(index) = sum(freqBins.*dataFFT)/sum(dataFFT);
    end
end
% Normalize spectral centroid
spectralCentroid = spectralCentroid / (Fs/2);

%%
% Smooth the computed energy and centroid by passing them through two
% consecutive median filters.
E = medfilt1(signalEnergy, 5);
E = medfilt1(E, 5);
C = medfilt1(spectralCentroid, 5);
C = medfilt1(C, 5);

%%
% Next, set thresholds for each feature. Regions where the feature values
% fall below their respective thresholds are treated as silence. 

% Get the average values of the smoothed feature sequences:
E_mean = mean(E);
Z_mean = mean(C);

% Find energy threshold:
Weight = 5;
[HistE, X_E] = hist(E, round(length(E) / 10));  % histogram computation
MaximaE = findMaxima(HistE, 3); % find the local maxima of the histogram
if (size(MaximaE,2)>=2) % if at least two local maxima have been found in the histogram:
    T_E = (Weight*X_E(MaximaE(1,1))+X_E(MaximaE(1,2))) / (Weight+1); % ... then compute the threshold as the weighted average between the two first histogram's local maxima.
else
    T_E = E_mean / 2;
end

% Find spectral centroid threshold:
[HistC, X_C] = hist(C, round(length(C) / 10));
MaximaC = findMaxima(HistC, 3);
if (size(MaximaC,2)>=2)
    T_C = (Weight*X_C(MaximaC(1,1))+X_C(MaximaC(1,2))) / (Weight+1);
else
    T_C = Z_mean / 2;
end

% Thresholding:
isSpeechRegion = (E>=T_E) & (C>=T_C);
%%
% Extract the segments of speech from the audio. Assume speech is
% present for samples where both energy and spectral centroid values exceed
% their respective thresholds.

% Get indices of frames where a speech-to-silence or silence-to-speech
% transition occurs.
regionStartPos  = find(diff([isSpeechRegion(1)-1, isSpeechRegion]));

% Get the length of the all-silence or all-speech regions.
RegionLengths   = diff([regionStartPos, numel(isSpeechRegion)+1]);

% Get speech-only regions.
isSpeechRegion  = isSpeechRegion(regionStartPos) == 1;
regionStartPos  = regionStartPos(isSpeechRegion);
RegionLengths   = RegionLengths(isSpeechRegion);

% Get start and end indices for each speech region. Extend the region by 5
% windows on each side.
startIndices = zeros(1,numel(RegionLengths));
endIndices   = zeros(1,numel(RegionLengths));
for index=1:numel(RegionLengths)
   startIndices(index) = max(1, (regionStartPos(index) - 5) * WindowLength + 1); 
   endIndices(index)   = min(numel(audio), (regionStartPos(index) + RegionLengths(index) + 5) * WindowLength); 
end

%%
% Finally, merge intersecting speech segments.
activeSegment       = 1;
isSegmentsActive    = zeros(1,numel(startIndices));
isSegmentsActive(1) = 1;
for index = 2:numel(startIndices)
    if startIndices(index) <= endIndices(activeSegment)
        % Current segment intersects with previous segment
        if endIndices(index) > endIndices(activeSegment)
           endIndices(activeSegment) =  endIndices(index);
        end
    else
        % New speech segment detected
        activeSegment = index;
        isSegmentsActive(index) = 1;
    end
end

mask = zeros(size(audio));
if ~isempty(startIndices) &&  ~isempty(endIndices)
    numSegments = sum(isSegmentsActive);
    segments    = cell(1,numSegments);
    limits      = zeros(2,numSegments);
    speechSegmentsIndices  = find(isSegmentsActive);
    for index = 1:length(speechSegmentsIndices)
        segments{index} = audio(startIndices(speechSegmentsIndices(index)):endIndices(speechSegmentsIndices(index)));
        limits(:,index) = [startIndices(speechSegmentsIndices(index)) ; endIndices(speechSegmentsIndices(index))];
        mask(startIndices(speechSegmentsIndices(index)) : endIndices(speechSegmentsIndices(index))) = 1;
    end
else
    segments = {audio};
end

function [Maxima, countMaxima] = findMaxima(f, step)
% findMaxima Maxima estimation
%   This function estimates the local maxima of a sequence
%
% ARGUMENTS:
% f: the input sequence
% step: the size of the "search" window
%
% RETURN:
% Maxima: [2xcountMaxima] matrix containing: 
%         1. the maxima's indices
%         2. the maxima's values
% countMaxima: the number of maxima
%
%
% STEP 1: find maxima:
% 

countMaxima = 0;
for i=1:length(f)-step-1 % for each element of the sequence:
    if (i>step)
        if (( mean(f(i-step:i-1))< f(i)) && ( mean(f(i+1:i+step))< f(i)))  
            % IF the current element is larger than its neighbors (2*step window)
            % --> keep maximum:
            countMaxima = countMaxima + 1;
            Maxima(1,countMaxima) = i;   %#ok
            Maxima(2,countMaxima) = f(i);%#ok
        end
    else
        if (( mean(f(1:i))<= f(i)) && ( mean(f(i+1:i+step))< f(i)))  
            % IF the current element is larger than its neighbors (2*step window)
            % --> keep maximum:
            countMaxima = countMaxima + 1;
            Maxima(1,countMaxima) = i;    %#ok
            Maxima(2,countMaxima) = f(i); %#ok
        end
        
    end
end

%
% STEP 2: post process maxima:
%

MaximaNew = [];
countNewMaxima = 0;
i = 0;
while (i<countMaxima)
    % get current maximum:
    i = i + 1;

    tempMax = Maxima(1,i);
    tempVals = Maxima(2,i);
    
    % search for "neighbor maxima":
    while ((i<countMaxima) && ( Maxima(1,i+1) - tempMax(end) < step / 2))
        i = i + 1;
        tempMax(end+1) = Maxima(1,i);  %#ok
        tempVals(end+1) = Maxima(2,i); %#ok
    end
    
   
    % find the maximum value and index from the tempVals array:
    %MI = findCentroid(tempMax, tempVals); MM = tempVals(MI);
    
    [MM, MI] = max(tempVals);
        
    if (MM>0.02*mean(f)) % if the current maximum is "large" enough:
        countNewMaxima = countNewMaxima + 1;   % add maxima
        % keep the maximum of all maxima in the region:
        MaximaNew(1,countNewMaxima) = tempMax(MI);  %#ok
        MaximaNew(2,countNewMaxima) = f(MaximaNew(1,countNewMaxima)); %#ok
    end        
    tempMax = [];%#ok
    tempVals = [];%#ok
end

Maxima = MaximaNew;
countMaxima = countNewMaxima;