function [totalCalories, calorieTimeline, metValues] = calculateCalories(activityLabels, durations, userWeight)
    % CALCULATECALORIES Estimate calories burned using MET-based model
    %
    % Maps predicted activity labels to Metabolic Equivalent (MET) values
    % from the Compendium of Physical Activities and calculates calorie
    % expenditure.
    %
    % Inputs:
    %   activityLabels - Cell array or categorical of activity names per window
    %   durations      - Duration in seconds for each window
    %   userWeight     - User body weight in kg
    %
    % Outputs:
    %   totalCalories    - Total estimated calories burned (kcal)
    %   calorieTimeline  - Cumulative calorie vector over time
    %   metValues        - MET value assigned to each window
    %
    % Formula: kcal/min = (MET × 3.5 × body_weight_kg) / 200
    %
    % Reference: Compendium of Physical Activities
    % Copyright 2026 FitSense AI Team

    %% MET Lookup Table (from Compendium of Physical Activities)
    metMap = containers.Map( ...
        {'sitting', 'standing', 'walking', 'fast_walking', 'jogging', 'running', 'stairs', 'unknown'}, ...
        [1.3,       1.8,        3.5,       5.0,            7.0,       9.8,       8.0,      2.0]);

    %% Convert labels to string for lookup
    if iscategorical(activityLabels)
        activityLabels = cellstr(activityLabels);
    elseif ischar(activityLabels)
        activityLabels = {activityLabels};
    end

    %% Calculate calories per window
    nWindows = length(activityLabels);
    metValues = zeros(nWindows, 1);
    caloriesPerWindow = zeros(nWindows, 1);

    for i = 1:nWindows
        label = lower(strtrim(activityLabels{i}));
        
        if metMap.isKey(label)
            metValues(i) = metMap(label);
        else
            metValues(i) = 2.0; % Default for unknown activities
        end
        
        % kcal = (MET × 3.5 × weight_kg) / 200 × duration_minutes
        durationMin = durations(i) / 60;
        caloriesPerWindow(i) = (metValues(i) * 3.5 * userWeight) / 200 * durationMin;
    end

    %% Results
    totalCalories = sum(caloriesPerWindow);
    calorieTimeline = cumsum(caloriesPerWindow);

    fprintf('  Total estimated calories: %.1f kcal\n', totalCalories);
    
    % Fun comparisons for presentation!
    fprintf('  🍌 That''s equivalent to %.1f bananas!\n', totalCalories / 105);
    fprintf('  🍕 Or %.1f slices of pizza!\n', totalCalories / 285);
    fprintf('  🏃 Keep it up!\n');
end
