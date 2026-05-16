function [numSteps, stepLocs, peakVals] = detectSteps(magClean, Fs)
    % DETECTSTEPS Detect steps using adaptive peak finding on acceleration magnitude
    %
    % Applies bandpass filtering to isolate walking frequency band (1-3 Hz)
    % and uses adaptive threshold peak detection.
    %
    % Inputs:
    %   magClean - Filtered acceleration magnitude vector
    %   Fs       - Sampling frequency (Hz)
    %
    % Outputs:
    %   numSteps  - Total number of detected steps
    %   stepLocs  - Indices of detected step peaks
    %   peakVals  - Amplitude values at detected peaks
    %
    % Copyright 2026 FitSense AI Team

    %% Bandpass filter for walking frequency band (1-3 Hz)
    fLow = 1;    % Hz - lower bound of walking frequency
    fHigh = min(3, Fs/2 - 0.5); % Hz - upper bound
    
    if Fs > 2 * fHigh
        [b, a] = butter(3, [fLow, fHigh] / (Fs/2), 'bandpass');
        magStep = filtfilt(b, a, magClean);
    else
        magStep = magClean - mean(magClean);
    end

    %% Adaptive peak detection
    % Minimum peak height = 1 standard deviation above mean
    minPeakHeight = std(magStep) * 0.8;
    
    % Minimum distance between steps = 0.35 seconds (max ~170 steps/min for running)
    minPeakDist = round(Fs * 0.35);

    [peakVals, stepLocs] = findpeaks(magStep, ...
        'MinPeakHeight', minPeakHeight, ...
        'MinPeakDistance', minPeakDist);

    numSteps = length(stepLocs);
    fprintf('  Detected %d steps\n', numSteps);
end
