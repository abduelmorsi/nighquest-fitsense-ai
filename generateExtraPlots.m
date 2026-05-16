% =========================================================================
% QUICK SCRIPT: Generate the remaining 2 screenshots for Slides 4 and 5
% Instructions: Just hit Run!
% =========================================================================

% Ensure variables from RunEverything exist
if ~exist('YTest_LSTM', 'var')
    error('Please run RunEverything.m first so the data is loaded into memory!');
end

fprintf('Generating plots...\n');

%% 1. Confusion Matrix (For Slide 5)
fig1 = figure('Name', 'Confusion Matrix', 'Color', [0.1 0.12 0.16], 'Position', [100 100 600 400]);
cm = confusionchart(YTest_LSTM, YPred_LSTM);
cm.Title = 'BiLSTM Activity Classification';
cm.ColumnSummary = 'column-normalized';
cm.RowSummary = 'row-normalized';
cm.FontColor = 'white';
fprintf('>>> SCREENSHOT FIGURE 1 and save as "confusion_matrix.png" <<<\n');

%% 2. Before/After Filtering Plot (For Slide 4)
% We'll use a chunk of walking data to demonstrate the noise removal
data = load('walkingNormally.mat');
rawAccel = data.Acceleration{100:600, :}; % Grab 500 samples (roughly 10 seconds)
timeVec = (0:length(rawAccel)-1) / Fs;

% Apply the same Butterworth filter as in your pipeline
[b, a] = butter(4, [0.5 15]/(Fs/2));
cleanAccel = filtfilt(b, a, rawAccel);

fig2 = figure('Name', 'Before/After Filtering', 'Color', [0.1 0.12 0.16], 'Position', [750 100 600 400]);

% Plot Raw Data
ax1 = subplot(2,1,1);
plot(timeVec, rawAccel(:,1), 'Color', [0.94 0.39 0.28], 'LineWidth', 1); 
title('Raw Accelerometer Data (Noisy & Includes Gravity)', 'Color', 'w', 'FontSize', 12);
ylabel('Acceleration', 'Color', 'w');
set(ax1, 'Color', 'none', 'XColor', 'w', 'YColor', 'w', 'Box', 'off');

% Plot Cleaned Data
ax2 = subplot(2,1,2);
plot(timeVec, cleanAccel(:,1), 'Color', [0.3 0.85 0.56], 'LineWidth', 1.5);
title('Cleaned Signal (Gravity Removed + Bandpass Filtered)', 'Color', 'w', 'FontSize', 12);
xlabel('Time (s)', 'Color', 'w');
ylabel('Acceleration', 'Color', 'w');
set(ax2, 'Color', 'none', 'XColor', 'w', 'YColor', 'w', 'Box', 'off');

sgtitle('Signal Processing Pipeline', 'Color', 'w', 'FontSize', 16, 'FontWeight', 'bold');
fprintf('>>> SCREENSHOT FIGURE 2 and save as "before_after.png" <<<\n\n');
fprintf('Once saved, refresh your presentation in the browser!\n');
