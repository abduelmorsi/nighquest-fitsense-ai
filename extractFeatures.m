function featureTable = extractFeatures(accelClean, magClean, Fs, windowSec, overlapFrac)
    % EXTRACTFEATURES Extract time and frequency domain features from sensor data
    %
    % Uses sliding window approach to compute statistical and spectral features
    % suitable for activity classification via ML/DL models.
    %
    % Inputs:
    %   accelClean  - [N×3] filtered acceleration matrix [X, Y, Z]
    %   magClean    - [N×1] acceleration magnitude vector
    %   Fs          - Sampling frequency (Hz)
    %   windowSec   - Window duration in seconds (default: 2)
    %   overlapFrac - Overlap fraction 0-1 (default: 0.5)
    %
    % Output:
    %   featureTable - Table with extracted features per window
    %
    % Example:
    %   features = extractFeatures(accelClean, mag, 50, 2, 0.5);
    %
    % Copyright 2026 FitSense AI Team

    if nargin < 4, windowSec = 2; end
    if nargin < 5, overlapFrac = 0.5; end

    windowSize = round(windowSec * Fs);
    stepSize = round(windowSize * (1 - overlapFrac));
    nSamples = size(accelClean, 1);

    % Pre-allocate feature storage
    nWindows = floor((nSamples - windowSize) / stepSize) + 1;
    featureNames = {};
    allFeatures = [];

    for w = 1:nWindows
        startIdx = (w - 1) * stepSize + 1;
        endIdx = startIdx + windowSize - 1;

        if endIdx > nSamples
            break;
        end

        % Extract window data
        winX = accelClean(startIdx:endIdx, 1);
        winY = accelClean(startIdx:endIdx, 2);
        winZ = accelClean(startIdx:endIdx, 3);
        winMag = magClean(startIdx:endIdx);

        % === TIME DOMAIN FEATURES ===
        signals = {winX, winY, winZ, winMag};
        sigLabels = {'X', 'Y', 'Z', 'Mag'};
        
        feats = [];
        names = {};
        
        for s = 1:4
            sig = signals{s};
            lbl = sigLabels{s};
            
            feats = [feats, ...
                mean(sig), ...            % Mean
                std(sig), ...             % Standard deviation
                var(sig), ...             % Variance
                rms(sig), ...             % Root mean square
                max(sig) - min(sig), ...  % Peak-to-peak range
                skewness(sig), ...        % Skewness (asymmetry)
                kurtosis(sig), ...        % Kurtosis (peakedness)
                iqr(sig), ...             % Interquartile range
                sum(sig.^2), ...          % Signal energy
                sum(abs(diff(sign(sig))))/2/length(sig)];  % Zero crossing rate
            
            names = [names, ...
                {[lbl '_mean'], [lbl '_std'], [lbl '_var'], [lbl '_rms'], ...
                 [lbl '_p2p'], [lbl '_skew'], [lbl '_kurt'], [lbl '_iqr'], ...
                 [lbl '_energy'], [lbl '_zcr']}];
        end

        % === FREQUENCY DOMAIN FEATURES (on magnitude) ===
        N = length(winMag);
        Y = fft(winMag);
        P = abs(Y(1:floor(N/2)+1)).^2 / N;  % Power spectrum
        freqs = (0:floor(N/2)) * Fs / N;
        
        % Remove DC component
        P(1) = 0;
        freqs_noDC = freqs(2:end);
        P_noDC = P(2:end);
        
        if ~isempty(P_noDC) && sum(P_noDC) > 0
            [~, maxIdx] = max(P_noDC);
            domFreq = freqs_noDC(maxIdx);                        % Dominant frequency
            spectralEnergy = sum(P_noDC);                        % Total spectral energy
            P_norm = P_noDC / sum(P_noDC);
            P_norm(P_norm == 0) = eps;
            spectralEntropy = -sum(P_norm .* log2(P_norm));      % Spectral entropy
            meanFreq = sum(freqs_noDC .* P_noDC') / sum(P_noDC); % Mean frequency
        else
            domFreq = 0;
            spectralEnergy = 0;
            spectralEntropy = 0;
            meanFreq = 0;
        end
        
        feats = [feats, domFreq, spectralEnergy, spectralEntropy, meanFreq];
        if w == 1  % Only set names once
            names = [names, {'domFreq', 'spectralEnergy', 'spectralEntropy', 'meanFreq'}];
        end

        allFeatures = [allFeatures; feats];
        
        if w == 1
            featureNames = names;
        end
    end

    % Create table
    featureTable = array2table(allFeatures, 'VariableNames', featureNames);
    fprintf('  Extracted %d features from %d windows\n', width(featureTable), height(featureTable));
end
