function plotModelComparison(lstmAccuracy, classicResults, YPred_LSTM, YTest_LSTM)
    % PLOTMODELCOMPARISON Visualize ML vs DL model comparison
    %
    % Creates a professional comparison figure showing:
    %   1. Accuracy bar chart (all models)
    %   2. LSTM confusion matrix
    %
    % Inputs:
    %   lstmAccuracy   - LSTM test accuracy (%)
    %   classicResults - Table from trainClassicML with Model and Accuracy columns
    %   YPred_LSTM     - LSTM predicted labels
    %   YTest_LSTM     - True test labels
    %
    % Copyright 2026 FitSense AI Team

    colors = struct(...
        'bg',      [0.10 0.10 0.14], ...
        'panel',   [0.15 0.15 0.20], ...
        'text',    [0.90 0.90 0.95], ...
        'accent1', [0.00 0.75 0.90], ...
        'accent3', [0.30 0.85 0.55], ...
        'grid',    [0.25 0.25 0.30]);

    fig = figure('Color', colors.bg, 'Position', [100 100 1200 500], ...
        'Name', 'Model Comparison');

    %% Panel 1: Accuracy Bar Chart
    ax1 = subplot(1, 2, 1);
    
    modelNames = [classicResults.Model(:); {'BiLSTM (Deep Learning)'}];
    accuracies = [classicResults.Accuracy_Pct(:); lstmAccuracy(:)];
    nModels = length(modelNames);
    
    barColors = repmat(colors.accent1, nModels, 1);
    barColors(end, :) = colors.accent3;  % Highlight LSTM in green
    
    b = bar(accuracies, 'FaceColor', 'flat');
    b.CData = barColors;
    b.EdgeColor = 'none';
    
    set(ax1, 'XTickLabel', modelNames, 'XTickLabelRotation', 25);
    ylabel('Accuracy (%)', 'Color', colors.text);
    title('Model Accuracy Comparison', 'Color', colors.text, 'FontSize', 14);
    ylim([0 105]);
    
    % Add accuracy labels on bars
    for i = 1:nModels
        text(i, accuracies(i) + 2, sprintf('%.1f%%', accuracies(i)), ...
            'HorizontalAlignment', 'center', 'Color', colors.text, ...
            'FontWeight', 'bold', 'FontSize', 11);
    end
    
    set(ax1, 'Color', colors.panel, 'XColor', colors.text, 'YColor', colors.text, ...
        'GridColor', colors.grid, 'FontSize', 10);
    grid(ax1, 'on');

    %% Panel 2: LSTM Confusion Matrix
    ax2 = subplot(1, 2, 2);
    
    if ~isempty(YPred_LSTM) && ~isempty(YTest_LSTM)
        cm = confusionchart(YTest_LSTM, YPred_LSTM, ...
            'ColumnSummary', 'column-normalized', ...
            'RowSummary', 'row-normalized', ...
            'Title', 'LSTM Confusion Matrix');
        cm.FontColor = colors.text;
        
        % Style the confusion chart
        sortClasses(cm, categories(YTest_LSTM));
    end
    
    sgtitle('🧠 AI Model Performance Analysis', ...
        'Color', colors.text, 'FontSize', 16, 'FontWeight', 'bold');

    fprintf('  📊 Model comparison plot generated!\n');
end
