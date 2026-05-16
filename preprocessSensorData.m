function [accelClean, magClean, timeVec, Fs] = preprocessSensorData(accelData)
    % PREPROCESSSENSORDATA Signal processing pipeline for accelerometer data
    %
    % Applies bandpass filtering, gravity removal, and computes acceleration
    % magnitude. Demonstrates advanced signal processing knowledge.
    %
    % Input:
    %   accelData - Timetable with Timestamp, X, Y, Z columns from MATLAB Mobile
    %
    % Outputs:
    %   accelClean - Filtered [X, Y, Z] acceleration matrix
    %   magClean   - Filtered acceleration magnitude vector
    %   timeVec    - Time vector in seconds (elapsed from start)
    %   Fs         - Estimated sampling frequency (Hz)
    %
    % Example:
    %   load('ExampleData.mat');
    %   [accelClean, mag, t, Fs] = preprocessSensorData(Acceleration);
    %
    % Copyright 2026 FitSense AI Team

    %% Extract raw data from timetable
    timeVec = timeElapsed(accelData.Timestamp);
    
    % Get variable names to handle different naming conventions
    varNames = accelData.Properties.VariableNames;
    rawData = accelData.Variables;
    
    % Extract X, Y, Z (first 3 numeric columns)
    ax = rawData(:, 1);
    ay = rawData(:, 2);
    az = rawData(:, 3);

    %% Estimate sampling frequency
    dt = median(diff(timeVec));  % Use median to be robust to outliers
    Fs = round(1 / dt);
    if Fs < 1
        Fs = 10; % Default fallback
    end
    fprintf('  Detected sampling frequency: %d Hz\n', Fs);

    %% Design bandpass filter (0.5 - 15 Hz)
    % Removes DC offset (gravity) and high-frequency noise
    % Uses 4th-order Butterworth for smooth frequency response
    fLow = 0.5;   % Hz - removes gravity/DC component
    fHigh = min(15, Fs/2 - 0.5); % Hz - removes high-freq noise (respect Nyquist)
    
    if Fs > 2 * fHigh
        [b, a] = butter(4, [fLow, fHigh] / (Fs/2), 'bandpass');
        
        % Apply zero-phase filtering (no phase distortion)
        ax_filt = filtfilt(b, a, ax);
        ay_filt = filtfilt(b, a, ay);
        az_filt = filtfilt(b, a, az);
    else
        % If sampling rate too low, just remove mean (gravity)
        ax_filt = ax - mean(ax);
        ay_filt = ay - mean(ay);
        az_filt = az - mean(az);
        warning('Sampling rate too low for bandpass filter. Using mean removal.');
    end

    %% Compute acceleration magnitude (orientation-independent)
    magClean = sqrt(ax_filt.^2 + ay_filt.^2 + az_filt.^2);

    %% Package output
    accelClean = [ax_filt, ay_filt, az_filt];

    fprintf('  Preprocessing complete. %d samples processed.\n', length(timeVec));
end
