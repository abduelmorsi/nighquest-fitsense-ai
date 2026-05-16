function [bestModel, bestName, allResults] = trainClassicML(featureTable, labels)
    % TRAINCLASSICML Train and compare multiple classic ML classifiers
    %
    % Trains SVM, KNN, Decision Tree, and Random Forest classifiers on
    % extracted features. Returns the best performing model for comparison
    % with the LSTM deep learning approach.
    %
    % Inputs:
    %   featureTable - Table of extracted features (from extractFeatures.m)
    %   labels       - Categorical or cell array of activity labels per window
    %
    % Outputs:
    %   bestModel  - Trained model with highest accuracy
    %   bestName   - Name of the best model
    %   allResults - Table comparing all model accuracies
    %
    % Copyright 2026 FitSense AI Team

    fprintf('\n=== Training Classic ML Classifiers ===\n');

    if ~iscategorical(labels)
        labels = categorical(labels);
    end

    %% Prepare data
    X = table2array(featureTable);
    Y = labels;

    % Handle NaN and Inf values
    X(isnan(X)) = 0;
    X(isinf(X)) = 0;

    % Normalize features (z-score)
    mu = mean(X);
    sigma = std(X);
    sigma(sigma == 0) = 1; % Avoid division by zero
    X_norm = (X - mu) ./ sigma;

    %% Cross-validation partition
    cv = cvpartition(Y, 'HoldOut', 0.2);
    XTrain = X_norm(cv.training, :);
    YTrain = Y(cv.training);
    XTest = X_norm(cv.test, :);
    YTest = Y(cv.test);

    %% Train multiple models
    modelNames = {'SVM (RBF)', 'KNN (k=5)', 'Decision Tree', 'Random Forest'};
    accuracies = zeros(4, 1);
    models = cell(4, 1);

    % 1. SVM with RBF kernel
    fprintf('  Training SVM (RBF)...\n');
    try
        t = templateSVM('KernelFunction', 'rbf', 'Standardize', true);
        models{1} = fitcecoc(XTrain, YTrain, 'Learners', t);
        YPred = predict(models{1}, XTest);
        accuracies(1) = sum(YPred == YTest) / numel(YTest) * 100;
    catch
        accuracies(1) = 0;
    end

    % 2. KNN
    fprintf('  Training KNN (k=5)...\n');
    try
        models{2} = fitcknn(XTrain, YTrain, 'NumNeighbors', 5, 'Standardize', true);
        YPred = predict(models{2}, XTest);
        accuracies(2) = sum(YPred == YTest) / numel(YTest) * 100;
    catch
        accuracies(2) = 0;
    end

    % 3. Decision Tree
    fprintf('  Training Decision Tree...\n');
    try
        models{3} = fitctree(XTrain, YTrain, 'MaxNumSplits', 50);
        YPred = predict(models{3}, XTest);
        accuracies(3) = sum(YPred == YTest) / numel(YTest) * 100;
    catch
        accuracies(3) = 0;
    end

    % 4. Random Forest (Ensemble)
    fprintf('  Training Random Forest...\n');
    try
        models{4} = fitcensemble(XTrain, YTrain, 'Method', 'Bag', 'NumLearningCycles', 100);
        YPred = predict(models{4}, XTest);
        accuracies(4) = sum(YPred == YTest) / numel(YTest) * 100;
    catch
        accuracies(4) = 0;
    end

    %% Results comparison
    allResults = table(modelNames', accuracies, ...
        'VariableNames', {'Model', 'Accuracy_Pct'});
    
    [~, bestIdx] = max(accuracies);
    bestModel = models{bestIdx};
    bestName = modelNames{bestIdx};

    fprintf('\n  === Model Comparison ===\n');
    disp(allResults);
    fprintf('  🏆 Best Model: %s (%.1f%%)\n', bestName, accuracies(bestIdx));
end
