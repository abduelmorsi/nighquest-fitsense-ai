function plotFitnessDashboard(timeVec, accelClean, magClean, stepLocs, ...
    activityLabels, calorieTimeline, totalCalories, numSteps, totalDistance, Fs)
    % PLOTFITNESSDASHBOARD Create a comprehensive multi-panel fitness visualization
    %
    % Generates a professional 6-panel dashboard showing all key fitness metrics.
    % Demonstrates advanced MATLAB data visualization techniques.
    %
    % Inputs:
    %   timeVec         - Time vector in seconds
    %   accelClean      - [N×3] filtered acceleration data
    %   magClean        - Acceleration magnitude vector
    %   stepLocs        - Indices of detected steps
    %   activityLabels  - Classified activity labels per window
    %   calorieTimeline - Cumulative calorie vector
    %   totalCalories   - Total calories burned
    %   numSteps        - Total step count
    %   totalDistance    - Total distance in meters
    %   Fs              - Sampling frequency
    %
    % Copyright 2026 FitSense AI Team

    %% Color Palette (professional dark theme)
    colors = struct(...
        'bg',       [0.10 0.10 0.14], ...
        'panel',    [0.15 0.15 0.20], ...
        'text',     [0.90 0.90 0.95], ...
        'accent1',  [0.00 0.75 0.90], ...  % Cyan
        'accent2',  [0.95 0.40 0.30], ...  % Coral
        'accent3',  [0.30 0.85 0.55], ...  % Green
        'accent4',  [0.95 0.75 0.20], ...  % Gold
        'accent5',  [0.70 0.40 0.95], ...  % Purple
        'grid',     [0.25 0.25 0.30]);

    fig = figure('Color', colors.bg, 'Position', [50 50 1400 900], ...
        'Name', 'FitSense AI Dashboard');

    %% Panel 1: Raw Acceleration (XYZ)
    ax1 = subplot(2, 3, 1);
    hold on;
    plot(timeVec, accelClean(:,1), 'Color', colors.accent1, 'LineWidth', 1);
    plot(timeVec, accelClean(:,2), 'Color', colors.accent2, 'LineWidth', 1);
    plot(timeVec, accelClean(:,3), 'Color', colors.accent3, 'LineWidth', 1);
    hold off;
    title('Acceleration (X, Y, Z)', 'Color', colors.text, 'FontSize', 12);
    xlabel('Time (s)', 'Color', colors.text);
    ylabel('Acceleration (m/s²)', 'Color', colors.text);
    legend('X', 'Y', 'Z', 'TextColor', colors.text, 'Color', colors.panel, ...
        'EdgeColor', colors.grid, 'Location', 'northeast');
    styleAxis(ax1, colors);

    %% Panel 2: Magnitude + Step Detection
    ax2 = subplot(2, 3, 2);
    hold on;
    plot(timeVec, magClean, 'Color', colors.accent5, 'LineWidth', 1);
    if ~isempty(stepLocs)
        validLocs = stepLocs(stepLocs <= length(timeVec));
        scatter(timeVec(validLocs), magClean(validLocs), 30, colors.accent4, ...
            'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.7);
    end
    hold off;
    title(sprintf('Step Detection (%d steps)', numSteps), 'Color', colors.text, 'FontSize', 12);
    xlabel('Time (s)', 'Color', colors.text);
    ylabel('|Acceleration| (m/s²)', 'Color', colors.text);
    legend('Magnitude', 'Steps', 'TextColor', colors.text, 'Color', colors.panel, ...
        'EdgeColor', colors.grid);
    styleAxis(ax2, colors);

    %% Panel 3: Activity Classification Pie Chart
    ax3 = subplot(2, 3, 3);
    if ~isempty(activityLabels)
        if iscategorical(activityLabels)
            actCat = activityLabels;
        else
            actCat = categorical(activityLabels);
        end
        actCounts = countcats(actCat);
        actNames = categories(actCat);
        validIdx = actCounts > 0;
        
        pieColors = [colors.accent1; colors.accent2; colors.accent3; 
                     colors.accent4; colors.accent5; [0.5 0.8 0.9]];
        
        if any(validIdx)
            p = pie(actCounts(validIdx));
            % Style pie chart
            for i = 1:length(p)
                if isa(p(i), 'matlab.graphics.chart.primitive.Pie') || ...
                   isa(p(i), 'matlab.graphics.primitive.Patch')
                    colorIdx = mod(ceil(i/2)-1, size(pieColors,1)) + 1;
                    try p(i).FaceColor = pieColors(colorIdx, :); end
                end
                if isa(p(i), 'matlab.graphics.primitive.Text')
                    p(i).Color = colors.text;
                    p(i).FontSize = 9;
                end
            end
            legend(actNames(validIdx), 'TextColor', colors.text, 'Color', colors.panel, ...
                'EdgeColor', colors.grid, 'Location', 'southoutside', 'Orientation', 'horizontal');
        end
    end
    title('Activity Breakdown', 'Color', colors.text, 'FontSize', 12);
    set(ax3, 'Color', colors.bg);

    %% Panel 4: Calorie Burn Timeline
    ax4 = subplot(2, 3, 4);
    if ~isempty(calorieTimeline)
        calTime = linspace(0, timeVec(end), length(calorieTimeline));
        area(calTime / 60, calorieTimeline, 'FaceColor', colors.accent2, ...
            'FaceAlpha', 0.4, 'EdgeColor', colors.accent2, 'LineWidth', 2);
    end
    title(sprintf('Calorie Burn (%.1f kcal total)', totalCalories), ...
        'Color', colors.text, 'FontSize', 12);
    xlabel('Time (min)', 'Color', colors.text);
    ylabel('Cumulative kcal', 'Color', colors.text);
    styleAxis(ax4, colors);

    %% Panel 5: FFT Frequency Spectrum
    ax5 = subplot(2, 3, 5);
    N = length(magClean);
    Y = fft(magClean);
    P = abs(Y(1:floor(N/2)+1)).^2 / N;
    freqs = (0:floor(N/2)) * Fs / N;
    
    validFreqIdx = freqs <= 10 & freqs > 0;
    bar(freqs(validFreqIdx), P(validFreqIdx), 'FaceColor', colors.accent1, ...
        'EdgeColor', 'none', 'FaceAlpha', 0.8);
    title('Frequency Spectrum (FFT)', 'Color', colors.text, 'FontSize', 12);
    xlabel('Frequency (Hz)', 'Color', colors.text);
    ylabel('Power', 'Color', colors.text);
    styleAxis(ax5, colors);

    %% Panel 6: Summary Stats Card
    ax6 = subplot(2, 3, 6);
    axis off;
    set(ax6, 'Color', colors.bg);
    
    durationMin = timeVec(end) / 60;
    avgPace = durationMin / (totalDistance / 1000 + eps);
    
    summaryText = {
        sprintf('\\bf\\fontsize{16}🏋 WORKOUT SUMMARY')
        ''
        sprintf('\\fontsize{13}👣  Steps:      %d', numSteps)
        sprintf('\\fontsize{13}🔥  Calories:   %.1f kcal', totalCalories)
        sprintf('\\fontsize{13}📏  Distance:   %.0f m', totalDistance)
        sprintf('\\fontsize{13}⏱️  Duration:   %.1f min', durationMin)
        sprintf('\\fontsize{13}🏃  Avg Pace:   %.1f min/km', avgPace)
        ''
        sprintf('\\fontsize{11}🍌 = %.1f bananas burned!', totalCalories/105)
    };
    
    text(0.5, 0.5, summaryText, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'Color', colors.text, 'FontSize', 11, ...
        'BackgroundColor', colors.panel, 'EdgeColor', colors.accent3, ...
        'Margin', 15, 'LineWidth', 2, 'Interpreter', 'tex');

    %% Overall title
    sgtitle('FitSense AI — Fitness Analytics Dashboard', ...
        'Color', colors.text, 'FontSize', 18, 'FontWeight', 'bold');

    fprintf('  📊 Dashboard generated!\n');
end

%% Helper function to style axes
function styleAxis(ax, colors)
    set(ax, 'Color', colors.panel, 'XColor', colors.grid, 'YColor', colors.grid, ...
        'GridColor', colors.grid, 'GridAlpha', 0.3, 'FontSize', 10);
    grid(ax, 'on');
    ax.GridLineStyle = ':';
end
