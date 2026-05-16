function [net, accuracy, YPred, YTest] = trainLSTMClassifier(allData, allLabels, Fs, windowSec)
    % TRAINLSTMCLASSIFIER Train an LSTM deep learning network for activity recognition
    %
    % Takes labeled sensor data segments and trains a bidirectional LSTM
    % network to classify activities. Demonstrates Deep Learning Toolbox mastery.
    %
    % Inputs:
    %   allData   - Cell array where each cell is [N×3] accel data for one recording
    %   allLabels - Cell array of string labels matching each recording
    %   Fs        - Sampling frequency
    %   windowSec - Window size in seconds (default: 2)
    %
    % Outputs:
    %   net      - Trained LSTM network
    %   accuracy - Classification accuracy on test set
    %   YPred    - Predicted labels for test set
    %   YTest    - True labels for test set
    %
    % Copyright 2026 FitSense AI Team

    if nargin < 4, windowSec = 2; end

    fprintf('\n=== Training LSTM Activity Classifier ===\n');

    %% Segment data into windows
    windowSize = round(windowSec * Fs);
    overlapFrac = 0.5;
    stepSize = round(windowSize * (1 - overlapFrac));

    sequences = {};
    labels = {};

    for rec = 1:length(allData)
        data = allData{rec};  % [N×3] matrix
        label = allLabels{rec};
        nSamples = size(data, 1);

        % Compute magnitude as 4th channel
        mag = sqrt(sum(data.^2, 2));
        data4ch = [data, mag]; % [N×4]

        for startIdx = 1:stepSize:(nSamples - windowSize + 1)
            endIdx = startIdx + windowSize - 1;
            window = data4ch(startIdx:endIdx, :)';  % [4 × windowSize] — features × time

            sequences{end+1} = window;
            labels{end+1} = label;
        end
    end

    labels = categorical(labels);
    fprintf('  Created %d training sequences\n', length(sequences));
    fprintf('  Classes: %s\n', strjoin(string(categories(labels)), ', '));

    %% Train-test split (80-20)
    nTotal = length(sequences);
    idx = randperm(nTotal);
    nTrain = round(0.8 * nTotal);

    XTrain = sequences(idx(1:nTrain));
    YTrain = labels(idx(1:nTrain));
    XTest = sequences(idx(nTrain+1:end));
    YTest = labels(idx(nTrain+1:end));

    %% Define LSTM Architecture
    numFeatures = 4;  % ax, ay, az, magnitude
    numClasses = numel(categories(labels));

    layers = [
        sequenceInputLayer(numFeatures, 'Name', 'input')
        
        % Bidirectional LSTM captures patterns in both time directions
        bilstmLayer(128, 'OutputMode', 'sequence', 'Name', 'bilstm1')
        dropoutLayer(0.3, 'Name', 'drop1')
        
        bilstmLayer(64, 'OutputMode', 'last', 'Name', 'bilstm2')
        dropoutLayer(0.2, 'Name', 'drop2')
        
        fullyConnectedLayer(32, 'Name', 'fc1')
        reluLayer('Name', 'relu1')
        
        fullyConnectedLayer(numClasses, 'Name', 'fc_out')
        softmaxLayer('Name', 'softmax')
        classificationLayer('Name', 'classification')
    ];

    %% Training Options
    options = trainingOptions('adam', ...
        'MaxEpochs', 30, ...
        'MiniBatchSize', min(32, nTrain), ...
        'InitialLearnRate', 0.001, ...
        'LearnRateSchedule', 'piecewise', ...
        'LearnRateDropFactor', 0.5, ...
        'LearnRateDropPeriod', 10, ...
        'GradientThreshold', 1, ...
        'ValidationData', {XTest, YTest}, ...
        'ValidationFrequency', 5, ...
        'Shuffle', 'every-epoch', ...
        'Verbose', true, ...
        'Plots', 'training-progress');

    %% Train the Network
    fprintf('  Training LSTM network...\n');
    net = trainNetwork(XTrain, YTrain, layers, options);

    %% Evaluate
    YPred = classify(net, XTest);
    YTest = YTest(:); % Force column vector to prevent matrix expansion
    YPred = YPred(:); % Force column vector
    accuracy = sum(YPred == YTest) / numel(YTest) * 100;
    fprintf('\n  ✅ LSTM Test Accuracy: %.1f%%\n', accuracy);
end
