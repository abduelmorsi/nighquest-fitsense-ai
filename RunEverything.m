%% ========================================================================
%  QUICK START SCRIPT — Run this in MATLAB Online
%  Copy-paste the ENTIRE script and press Run.
%  Make sure ALL .m files and .mat files are in the same folder.
%  ========================================================================
clc; clear; close all;

%% STEP 1: Load YOUR collected sensor data (5 activities)
fprintf('=== STEP 1: Loading YOUR training data ===\n');

% =========================================================================
%  FILL IN YOUR FILENAMES BELOW!
%  Your files are likely in MobileSensorData/ folder on MATLAB Drive.
%  Check the filenames and replace the ones below.
%  Each file should contain an 'Acceleration' timetable variable.
% =========================================================================

% --- Activity 1: Sitting Still ---
fprintf('Loading sitting data...\n');
sittingFile = 'sittingStill.mat';  % Filename provided by user
data = load(sittingFile);
[sitClean, ~, ~, Fs] = preprocessSensorData(data.Acceleration);

% --- Activity 2: Walking Normally ---
fprintf('Loading walking data...\n');
walkingFile = 'walkingNormally.mat';  % Filename provided by user
data = load(walkingFile);
[walkClean, ~, ~, ~] = preprocessSensorData(data.Acceleration);

% --- Activity 3: Fast Walking ---
fprintf('Loading fast walking data...\n');
fastWalkFile = 'fastWalking.mat';  % Filename provided by user
data = load(fastWalkFile);
[fastWalkClean, ~, ~, ~] = preprocessSensorData(data.Acceleration);

% --- Activity 4: Jogging ---
fprintf('Loading jogging data...\n');
joggingFile = 'jogging.mat';  % Filename provided by user
data = load(joggingFile);
[jogClean, ~, ~, ~] = preprocessSensorData(data.Acceleration);

% --- Activity 5: Running ---
fprintf('Loading running data...\n');
runningFile = 'running.mat';  % Filename provided by user
data = load(runningFile);
[runClean, ~, ~, ~] = preprocessSensorData(data.Acceleration);

% --- Activity 6: Going on Stairs ---
fprintf('Loading stairs data...\n');
stairsFile = 'goingOnStairs.mat';  % Filename provided by user
data = load(stairsFile);
[stairsClean, ~, ~, ~] = preprocessSensorData(data.Acceleration);

% Package into cell arrays for training
trainingData = {sitClean, walkClean, fastWalkClean, jogClean, runClean, stairsClean};
trainingLabels = {'sitting', 'walking', 'fast_walking', 'jogging', 'running', 'stairs'};

fprintf('Training data ready: %d activities (%s)\n', ...
    length(trainingLabels), strjoin(trainingLabels, ', '));

%% STEP 2: Train the LSTM deep learning classifier
fprintf('\n=== STEP 2: Training LSTM (this takes 1-3 minutes) ===\n');
fprintf('A training progress window will pop up — let it run!\n\n');

[lstmNet, lstmAccuracy, YPred_LSTM, YTest_LSTM] = ...
    trainLSTMClassifier(trainingData, trainingLabels, Fs, 2);

fprintf('\n>>> LSTM ACCURACY: %.1f%% <<<\n', lstmAccuracy);
fprintf('Write this number down for the presentation!\n\n');

%% STEP 3: Train classic ML models for comparison
fprintf('=== STEP 3: Training Classic ML models ===\n');

allFeatures = [];
allLabelsML = {};
for i = 1:length(trainingData)
    data = trainingData{i};
    mag = sqrt(sum(data.^2, 2));
    ft = extractFeatures(data, mag, Fs, 2, 0.5);
    allFeatures = [allFeatures; ft];
    allLabelsML = [allLabelsML; repmat(trainingLabels(i), height(ft), 1)];
end

[bestModel, bestName, classicResults] = trainClassicML(allFeatures, allLabelsML);
fprintf('\nWrite down ALL these accuracy numbers for slide 6!\n\n');

%% STEP 4: Model comparison plot
fprintf('=== STEP 4: Generating model comparison plot ===\n');
plotModelComparison(lstmAccuracy, classicResults, YPred_LSTM, YTest_LSTM);
fprintf('>>> SCREENSHOT THIS PLOT for the presentation! <<<\n\n');

%% STEP 5: Now analyze the test workout data
fprintf('=== STEP 5: Analyzing test workout ===\n');
load('ExampleData.mat');  % Contains: Acceleration, Position

userWeight = 70;  % Change to your actual weight in kg!

[accelClean, magClean, timeVec, Fs] = preprocessSensorData(Acceleration);
[numSteps, stepLocs, ~] = detectSteps(magClean, Fs);

% GPS distance
totalDistance = 0;
if exist('Position', 'var') && ~isempty(Position)
    try
        totalDistance = haversine(Position.latitude, Position.longitude);
    catch
        totalDistance = numSteps * 0.75;
    end
else
    totalDistance = numSteps * 0.75;
end

% Classify with LSTM
windowSize = round(2 * Fs);
stepSize = round(windowSize * 0.5);
nSamples = size(accelClean, 1);
testSequences = {};
mag4lstm = sqrt(sum(accelClean.^2, 2));
data4ch = [accelClean, mag4lstm];
for startIdx = 1:stepSize:(nSamples - windowSize + 1)
    endIdx = startIdx + windowSize - 1;
    window = data4ch(startIdx:endIdx, :)';
    testSequences{end+1} = window;
end
activityPredictions = classify(lstmNet, testSequences);

% Calories
windowDurations = repmat(2, length(activityPredictions), 1);
[totalCalories, calTimeline, ~] = ...
    calculateCalories(cellstr(activityPredictions), windowDurations, userWeight);

%% STEP 6: Generate the Workout DNA fingerprint!
fprintf('\n=== STEP 6: Generating Workout DNA ===\n');
createWorkoutDNA(activityPredictions, magClean, numSteps, totalCalories, totalDistance, Fs);
fprintf('>>> SCREENSHOT THE WORKOUT DNA for the presentation! <<<\n');

%% STEP 7: Generate the full dashboard
fprintf('\n=== STEP 7: Generating dashboard ===\n');
plotFitnessDashboard(timeVec, accelClean, magClean, stepLocs, ...
    activityPredictions, calTimeline, totalCalories, numSteps, totalDistance, Fs);

%% STEP 8: Print all results for the presentation
fprintf('\n');
fprintf('=====================================================\n');
fprintf('  COPY THESE NUMBERS INTO YOUR PRESENTATION:\n');
fprintf('=====================================================\n');
fprintf('  Steps:      %d\n', numSteps);
fprintf('  Calories:   %.1f kcal\n', totalCalories);
fprintf('  Distance:   %.0f m\n', totalDistance);
fprintf('  Duration:   %.1f min\n', timeVec(end)/60);
fprintf('  LSTM Acc:   %.1f%%\n', lstmAccuracy);
fprintf('  Bananas:    %.1f\n', totalCalories/105);
fprintf('  Pizza:      %.1f slices\n', totalCalories/285);
fprintf('=====================================================\n');
fprintf('\n  SCREENSHOTS TO TAKE:\n');
fprintf('  1. Training Progress window (already showing)\n');
fprintf('  2. Model Comparison bar chart\n');
fprintf('  3. Workout DNA radar chart\n');
fprintf('  4. Full Dashboard\n');
fprintf('  5. Confusion Matrix\n');
fprintf('=====================================================\n');
