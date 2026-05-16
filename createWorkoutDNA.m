function createWorkoutDNA(activityLabels, magClean, numSteps, totalCalories, totalDistance, Fs)
    % CREATEWORKOUTDNA Create a unique "Workout DNA" radar/polar fingerprint
    %
    % Generates a creative polar visualization that creates a unique visual
    % signature for each workout session. This is the CREATIVITY differentiator.
    %
    % Inputs:
    %   activityLabels - Categorical/cell array of classified activities per window
    %   magClean       - Acceleration magnitude vector
    %   numSteps       - Total steps detected
    %   totalCalories  - Total calories burned
    %   totalDistance   - Total distance in meters
    %   Fs             - Sampling frequency
    %
    % Copyright 2026 FitSense AI Team

    if iscategorical(activityLabels)
        activityLabels = cellstr(activityLabels);
    end

    %% Calculate workout metrics (normalized 0-1 for radar chart)
    totalSamples = length(magClean);
    durationMin = totalSamples / Fs / 60;

    % Metric 1: Intensity (average acceleration magnitude)
    intensity = min(mean(magClean) / 15, 1);

    % Metric 2: Variability (coefficient of variation)
    variability = min(std(magClean) / mean(magClean) / 3, 1);

    % Metric 3: Step Frequency (steps per minute, normalized)
    stepFreq = min((numSteps / durationMin) / 200, 1); % 200 spm = max running

    % Metric 4: Activity Diversity (number of unique activities / total possible)
    uniqueActivities = numel(unique(activityLabels));
    diversity = min(uniqueActivities / 6, 1);

    % Metric 5: Peak Performance (max acceleration, normalized)
    peakPerf = min(max(magClean) / 30, 1);

    % Metric 6: Endurance (duration, normalized to 60 min)
    endurance = min(durationMin / 60, 1);

    % Metric 7: Calorie Efficiency (calories per minute)
    calEfficiency = min((totalCalories / durationMin) / 15, 1);

    % Metric 8: Distance Score (normalized to 5km)
    distScore = min(totalDistance / 5000, 1);

    %% Create Radar/Polar Chart
    metrics = [intensity, variability, stepFreq, diversity, ...
               peakPerf, endurance, calEfficiency, distScore, intensity]; % Close the loop
    metricLabels = {'Intensity', 'Variability', 'Step Freq', 'Diversity', ...
                    'Peak Power', 'Endurance', 'Cal Efficiency', 'Distance'};
    
    nMetrics = length(metricLabels);
    angles = linspace(0, 2*pi, nMetrics + 1);

    figure('Color', [0.1 0.1 0.15], 'Position', [100 100 600 600]);

    % Background circles
    hold on;
    for r = 0.2:0.2:1.0
        xCircle = r * cos(linspace(0, 2*pi, 100));
        yCircle = r * sin(linspace(0, 2*pi, 100));
        plot(xCircle, yCircle, '-', 'Color', [0.3 0.3 0.35], 'LineWidth', 0.5);
    end

    % Axis lines
    for i = 1:nMetrics
        plot([0 cos(angles(i))], [0 sin(angles(i))], '-', ...
            'Color', [0.3 0.3 0.35], 'LineWidth', 0.5);
    end

    % Plot the DNA fingerprint
    xData = metrics .* cos(angles);
    yData = metrics .* sin(angles);

    % Filled area with gradient effect
    fill(xData, yData, [0.0 0.8 0.6], ...
        'FaceAlpha', 0.25, 'EdgeColor', [0.0 1.0 0.7], 'LineWidth', 2.5);

    % Data points with glow effect
    scatter(xData(1:end-1), yData(1:end-1), 100, [0.0 1.0 0.7], 'filled', ...
        'MarkerEdgeColor', [0.0 0.8 0.5], 'LineWidth', 1.5);

    % Labels
    for i = 1:nMetrics
        labelR = 1.15;
        lx = labelR * cos(angles(i));
        ly = labelR * sin(angles(i));
        text(lx, ly, metricLabels{i}, ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.8 0.8 0.85], ...
            'FontName', 'Helvetica');
    end

    % Title
    title('🧬 Workout DNA Fingerprint', ...
        'FontSize', 16, 'FontWeight', 'bold', 'Color', [0.95 0.95 1.0], ...
        'FontName', 'Helvetica');

    % Center stats
    text(0, -0.05, sprintf('%.0f cal | %d steps | %.0fm', ...
        totalCalories, numSteps, totalDistance), ...
        'HorizontalAlignment', 'center', 'FontSize', 9, ...
        'Color', [0.6 0.6 0.65], 'FontName', 'Helvetica');

    axis equal;
    axis([-1.4 1.4 -1.4 1.4]);
    axis off;
    hold off;

    fprintf('  🧬 Workout DNA fingerprint generated!\n');
end
