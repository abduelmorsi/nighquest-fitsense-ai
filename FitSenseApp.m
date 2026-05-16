classdef FitSenseApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure            matlab.ui.Figure
        MainGrid            matlab.ui.container.GridLayout
        LeftPanel           matlab.ui.container.Panel
        RightPanel          matlab.ui.container.Panel

        % Left Panel - Title
        TitleLabel          matlab.ui.control.Label
        SubtitleLabel       matlab.ui.control.Label

        % Left Panel - User Profile
        ProfilePanel        matlab.ui.container.Panel
        WeightLabel         matlab.ui.control.Label
        WeightField         matlab.ui.control.NumericEditField
        HeightLabel         matlab.ui.control.Label
        HeightField         matlab.ui.control.NumericEditField

        % Left Panel - Buttons
        LoadDataButton      matlab.ui.control.Button
        RunAnalysisButton   matlab.ui.control.Button

        % Left Panel - Results
        ResultsPanel        matlab.ui.container.Panel
        StepsLabel          matlab.ui.control.Label
        StepsValue          matlab.ui.control.Label
        CaloriesLabel       matlab.ui.control.Label
        CaloriesValue       matlab.ui.control.Label
        DistanceLabel       matlab.ui.control.Label
        DistanceValue       matlab.ui.control.Label
        DurationLabel       matlab.ui.control.Label
        DurationValue       matlab.ui.control.Label
        FunFactLabel        matlab.ui.control.Label

        % Left Panel - Status
        StatusLamp          matlab.ui.control.Lamp
        StatusLabel         matlab.ui.control.Label

        % Right Panel - Tabs
        TabGroup            matlab.ui.container.TabGroup
        RawDataTab          matlab.ui.container.Tab
        ProcessedTab        matlab.ui.container.Tab
        FrequencyTab        matlab.ui.container.Tab
        SummaryTab          matlab.ui.container.Tab

        % Axes inside tabs
        RawAxes             matlab.ui.control.UIAxes
        ProcessedAxes       matlab.ui.control.UIAxes
        FFTAxes             matlab.ui.control.UIAxes
        PieAxes             matlab.ui.control.UIAxes
        CalorieAxes         matlab.ui.control.UIAxes
    end

    % Private properties for data storage
    properties (Access = private)
        AccelData
        PosData
        AccelClean
        MagClean
        TimeVec
        Fs
        NumSteps
        StepLocs
        TotalDistance
        TotalCalories
        ActivityPredictions
    end

    % Callbacks
    methods (Access = private)

        function LoadDataButtonPushed(app, ~)
            [file, filepath] = uigetfile('*.mat', 'Select Sensor Data File');
            if isequal(file, 0), return; end

            app.StatusLamp.Color = [1 0.8 0];
            app.StatusLabel.Text = 'Loading...';
            drawnow;

            try
                data = load(fullfile(filepath, file));
                fnames = fieldnames(data);

                % Find acceleration data
                app.AccelData = [];
                app.PosData = [];
                for i = 1:length(fnames)
                    val = data.(fnames{i});
                    if istimetable(val)
                        vn = val.Properties.VariableNames;
                        if any(contains(lower(vn), 'x')) || any(contains(lower(vn), 'acceleration'))
                            if size(val.Variables, 2) >= 3 && isempty(app.AccelData)
                                app.AccelData = val;
                            end
                        end
                        if any(contains(lower(vn), 'lat'))
                            app.PosData = val;
                        end
                    end
                end

                if isempty(app.AccelData)
                    % Fallback: take first timetable with 3+ columns
                    for i = 1:length(fnames)
                        val = data.(fnames{i});
                        if istimetable(val) && size(val.Variables, 2) >= 3
                            app.AccelData = val;
                            break;
                        end
                    end
                end

                if isempty(app.AccelData)
                    error('No acceleration timetable found in file.');
                end

                % Plot raw data
                t = timeElapsed(app.AccelData.Timestamp);
                rawVars = app.AccelData.Variables;
                cla(app.RawAxes);
                hold(app.RawAxes, 'on');
                plot(app.RawAxes, t, rawVars(:,1), 'Color', [0 0.75 0.9], 'LineWidth', 1);
                plot(app.RawAxes, t, rawVars(:,2), 'Color', [0.95 0.4 0.3], 'LineWidth', 1);
                plot(app.RawAxes, t, rawVars(:,3), 'Color', [0.3 0.85 0.55], 'LineWidth', 1);
                hold(app.RawAxes, 'off');
                legend(app.RawAxes, {'X','Y','Z'}, 'TextColor', [0.85 0.85 0.9]);
                title(app.RawAxes, 'Raw Acceleration Data', 'Color', [0.9 0.9 0.95]);
                xlabel(app.RawAxes, 'Time (s)', 'Color', [0.7 0.7 0.75]);
                ylabel(app.RawAxes, 'Acceleration (m/s^2)', 'Color', [0.7 0.7 0.75]);

                app.RunAnalysisButton.Enable = 'on';
                app.StatusLamp.Color = [0.3 0.85 0.55];
                app.StatusLabel.Text = ['Loaded: ' file];
                app.TabGroup.SelectedTab = app.RawDataTab;

            catch e
                app.StatusLamp.Color = [0.95 0.3 0.3];
                app.StatusLabel.Text = ['Error: ' e.message];
            end
        end

        function RunAnalysisButtonPushed(app, ~)
            if isempty(app.AccelData), return; end

            app.StatusLamp.Color = [1 0.8 0];
            app.StatusLabel.Text = 'Analyzing...';
            drawnow;

            try
                % 1. Preprocess
                [app.AccelClean, app.MagClean, app.TimeVec, app.Fs] = ...
                    preprocessSensorData(app.AccelData);

                % 2. Step Detection
                [app.NumSteps, app.StepLocs, ~] = detectSteps(app.MagClean, app.Fs);

                % 3. Distance
                app.TotalDistance = 0;
                if ~isempty(app.PosData)
                    try
                        app.TotalDistance = haversine( ...
                            app.PosData.latitude, app.PosData.longitude);
                    catch
                        app.TotalDistance = app.NumSteps * 0.75;
                    end
                else
                    app.TotalDistance = app.NumSteps * 0.75;
                end

                % 4. Calories (simple MET-based)
                durationSec = app.TimeVec(end);
                userWt = app.WeightField.Value;
                [app.TotalCalories, calTimeline, ~] = ...
                    calculateCalories({'walking'}, durationSec, userWt);

                % === UPDATE RESULTS PANEL ===
                app.StepsValue.Text = sprintf('%d', app.NumSteps);
                app.CaloriesValue.Text = sprintf('%.1f kcal', app.TotalCalories);
                app.DistanceValue.Text = sprintf('%.0f m', app.TotalDistance);
                app.DurationValue.Text = sprintf('%.1f min', durationSec / 60);
                app.FunFactLabel.Text = sprintf('= %.1f bananas burned!', app.TotalCalories / 105);

                % === PLOT: Processed + Steps ===
                cla(app.ProcessedAxes);
                hold(app.ProcessedAxes, 'on');
                plot(app.ProcessedAxes, app.TimeVec, app.MagClean, ...
                    'Color', [0.3 0.85 0.55], 'LineWidth', 1);
                if ~isempty(app.StepLocs)
                    validLocs = app.StepLocs(app.StepLocs <= length(app.TimeVec));
                    scatter(app.ProcessedAxes, ...
                        app.TimeVec(validLocs), app.MagClean(validLocs), ...
                        25, [0.95 0.75 0.2], 'filled', 'MarkerFaceAlpha', 0.8);
                end
                hold(app.ProcessedAxes, 'off');
                title(app.ProcessedAxes, ...
                    sprintf('Step Detection (%d steps)', app.NumSteps), ...
                    'Color', [0.9 0.9 0.95]);
                xlabel(app.ProcessedAxes, 'Time (s)', 'Color', [0.7 0.7 0.75]);
                ylabel(app.ProcessedAxes, '|Accel| (m/s^2)', 'Color', [0.7 0.7 0.75]);
                legend(app.ProcessedAxes, {'Magnitude','Steps'}, 'TextColor', [0.85 0.85 0.9]);

                % === PLOT: FFT Frequency Spectrum ===
                N = length(app.MagClean);
                Y = fft(app.MagClean);
                P = abs(Y(1:floor(N/2)+1)).^2 / N;
                freqs = (0:floor(N/2)) * app.Fs / N;
                validIdx = freqs > 0 & freqs <= 10;

                cla(app.FFTAxes);
                bar(app.FFTAxes, freqs(validIdx), P(validIdx), ...
                    'FaceColor', [0 0.75 0.9], 'EdgeColor', 'none', 'FaceAlpha', 0.85);
                title(app.FFTAxes, 'Frequency Spectrum (FFT)', 'Color', [0.9 0.9 0.95]);
                xlabel(app.FFTAxes, 'Frequency (Hz)', 'Color', [0.7 0.7 0.75]);
                ylabel(app.FFTAxes, 'Power', 'Color', [0.7 0.7 0.75]);

                % === PLOT: Summary Tab - Calorie Timeline + Pie ===
                cla(app.CalorieAxes);
                if ~isempty(calTimeline)
                    calTime = linspace(0, durationSec/60, length(calTimeline));
                    area(app.CalorieAxes, calTime, calTimeline, ...
                        'FaceColor', [0.95 0.4 0.3], 'FaceAlpha', 0.4, ...
                        'EdgeColor', [0.95 0.4 0.3], 'LineWidth', 2);
                end
                title(app.CalorieAxes, ...
                    sprintf('Calorie Burn (%.1f kcal)', app.TotalCalories), ...
                    'Color', [0.9 0.9 0.95]);
                xlabel(app.CalorieAxes, 'Time (min)', 'Color', [0.7 0.7 0.75]);
                ylabel(app.CalorieAxes, 'Cumulative kcal', 'Color', [0.7 0.7 0.75]);

                % Switch to processed tab
                app.TabGroup.SelectedTab = app.ProcessedTab;

                app.StatusLamp.Color = [0.3 0.85 0.55];
                app.StatusLabel.Text = 'Analysis Complete!';

            catch e
                app.StatusLamp.Color = [0.95 0.3 0.3];
                app.StatusLabel.Text = ['Error: ' e.message];
            end
        end
    end

    % Component initialization
    methods (Access = private)

        function createComponents(app)

            % === Colors ===
            bgDark   = [0.11 0.11 0.15];
            panelBg  = [0.14 0.14 0.19];
            cardBg   = [0.17 0.17 0.22];
            textMain = [0.92 0.92 0.96];
            textDim  = [0.6 0.6 0.65];
            accent   = [0 0.75 0.9];
            green    = [0.3 0.85 0.55];

            % === UIFigure ===
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [50 50 1200 700];
            app.UIFigure.Name = 'FitSense AI - Fitness Analytics Dashboard';
            app.UIFigure.Color = bgDark;

            % === Main Grid (sidebar + content) ===
            app.MainGrid = uigridlayout(app.UIFigure);
            app.MainGrid.ColumnWidth = {260, '1x'};
            app.MainGrid.RowHeight = {'1x'};
            app.MainGrid.ColumnSpacing = 0;
            app.MainGrid.RowSpacing = 0;
            app.MainGrid.Padding = [0 0 0 0];
            app.MainGrid.BackgroundColor = bgDark;

            % ============================================================
            %  LEFT PANEL (Sidebar)
            % ============================================================
            app.LeftPanel = uipanel(app.MainGrid);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;
            app.LeftPanel.BackgroundColor = panelBg;
            app.LeftPanel.BorderType = 'none';

            leftGrid = uigridlayout(app.LeftPanel);
            leftGrid.ColumnWidth = {'1x'};
            leftGrid.RowHeight = {40, 20, 10, 'fit', 10, 40, 40, 15, 'fit', '1x', 'fit'};
            leftGrid.Padding = [15 15 15 15];
            leftGrid.RowSpacing = 3;
            leftGrid.BackgroundColor = panelBg;

            % Row 1: Title
            app.TitleLabel = uilabel(leftGrid);
            app.TitleLabel.Layout.Row = 1;
            app.TitleLabel.Layout.Column = 1;
            app.TitleLabel.Text = 'FitSense AI';
            app.TitleLabel.FontSize = 22;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.FontColor = textMain;

            % Row 2: Subtitle
            app.SubtitleLabel = uilabel(leftGrid);
            app.SubtitleLabel.Layout.Row = 2;
            app.SubtitleLabel.Layout.Column = 1;
            app.SubtitleLabel.Text = 'Intelligent Fitness Analytics';
            app.SubtitleLabel.FontSize = 11;
            app.SubtitleLabel.FontColor = textDim;

            % Row 3: spacer (handled by RowHeight)

            % Row 4: Profile Panel
            app.ProfilePanel = uipanel(leftGrid);
            app.ProfilePanel.Layout.Row = 4;
            app.ProfilePanel.Layout.Column = 1;
            app.ProfilePanel.Title = 'User Profile';
            app.ProfilePanel.BackgroundColor = cardBg;
            app.ProfilePanel.ForegroundColor = textDim;
            app.ProfilePanel.BorderType = 'line';
            app.ProfilePanel.FontSize = 11;

            profGrid = uigridlayout(app.ProfilePanel);
            profGrid.ColumnWidth = {'fit', '1x'};
            profGrid.RowHeight = {28, 28};
            profGrid.Padding = [8 8 8 8];
            profGrid.RowSpacing = 5;
            profGrid.BackgroundColor = cardBg;

            app.WeightLabel = uilabel(profGrid);
            app.WeightLabel.Layout.Row = 1; app.WeightLabel.Layout.Column = 1;
            app.WeightLabel.Text = 'Weight (kg)';
            app.WeightLabel.FontColor = textDim;

            app.WeightField = uieditfield(profGrid, 'numeric');
            app.WeightField.Layout.Row = 1; app.WeightField.Layout.Column = 2;
            app.WeightField.Value = 70;
            app.WeightField.BackgroundColor = panelBg;
            app.WeightField.FontColor = textMain;

            app.HeightLabel = uilabel(profGrid);
            app.HeightLabel.Layout.Row = 2; app.HeightLabel.Layout.Column = 1;
            app.HeightLabel.Text = 'Height (cm)';
            app.HeightLabel.FontColor = textDim;

            app.HeightField = uieditfield(profGrid, 'numeric');
            app.HeightField.Layout.Row = 2; app.HeightField.Layout.Column = 2;
            app.HeightField.Value = 175;
            app.HeightField.BackgroundColor = panelBg;
            app.HeightField.FontColor = textMain;

            % Row 5: spacer

            % Row 6: Load Data Button
            app.LoadDataButton = uibutton(leftGrid, 'push');
            app.LoadDataButton.Layout.Row = 6;
            app.LoadDataButton.Layout.Column = 1;
            app.LoadDataButton.Text = 'Load Sensor Data';
            app.LoadDataButton.FontSize = 13;
            app.LoadDataButton.FontWeight = 'bold';
            app.LoadDataButton.FontColor = [1 1 1];
            app.LoadDataButton.BackgroundColor = accent;
            app.LoadDataButton.ButtonPushedFcn = createCallbackFcn(app, @LoadDataButtonPushed, true);

            % Row 7: Run Analysis Button
            app.RunAnalysisButton = uibutton(leftGrid, 'push');
            app.RunAnalysisButton.Layout.Row = 7;
            app.RunAnalysisButton.Layout.Column = 1;
            app.RunAnalysisButton.Text = 'Run Analysis';
            app.RunAnalysisButton.FontSize = 13;
            app.RunAnalysisButton.FontWeight = 'bold';
            app.RunAnalysisButton.FontColor = [1 1 1];
            app.RunAnalysisButton.BackgroundColor = green;
            app.RunAnalysisButton.Enable = 'off';
            app.RunAnalysisButton.ButtonPushedFcn = createCallbackFcn(app, @RunAnalysisButtonPushed, true);

            % Row 8: spacer

            % Row 9: Results Panel
            app.ResultsPanel = uipanel(leftGrid);
            app.ResultsPanel.Layout.Row = 9;
            app.ResultsPanel.Layout.Column = 1;
            app.ResultsPanel.Title = 'Workout Results';
            app.ResultsPanel.BackgroundColor = cardBg;
            app.ResultsPanel.ForegroundColor = textDim;
            app.ResultsPanel.BorderType = 'line';
            app.ResultsPanel.FontSize = 11;

            resGrid = uigridlayout(app.ResultsPanel);
            resGrid.ColumnWidth = {'fit', '1x'};
            resGrid.RowHeight = {24, 24, 24, 24, 8, 24};
            resGrid.Padding = [10 10 10 10];
            resGrid.RowSpacing = 4;
            resGrid.BackgroundColor = cardBg;

            app.StepsLabel = uilabel(resGrid);
            app.StepsLabel.Layout.Row = 1; app.StepsLabel.Layout.Column = 1;
            app.StepsLabel.Text = 'Steps';
            app.StepsLabel.FontColor = textDim;
            app.StepsValue = uilabel(resGrid);
            app.StepsValue.Layout.Row = 1; app.StepsValue.Layout.Column = 2;
            app.StepsValue.Text = '--';
            app.StepsValue.FontSize = 14;
            app.StepsValue.FontWeight = 'bold';
            app.StepsValue.FontColor = accent;
            app.StepsValue.HorizontalAlignment = 'right';

            app.CaloriesLabel = uilabel(resGrid);
            app.CaloriesLabel.Layout.Row = 2; app.CaloriesLabel.Layout.Column = 1;
            app.CaloriesLabel.Text = 'Calories';
            app.CaloriesLabel.FontColor = textDim;
            app.CaloriesValue = uilabel(resGrid);
            app.CaloriesValue.Layout.Row = 2; app.CaloriesValue.Layout.Column = 2;
            app.CaloriesValue.Text = '--';
            app.CaloriesValue.FontSize = 14;
            app.CaloriesValue.FontWeight = 'bold';
            app.CaloriesValue.FontColor = [0.95 0.4 0.3];
            app.CaloriesValue.HorizontalAlignment = 'right';

            app.DistanceLabel = uilabel(resGrid);
            app.DistanceLabel.Layout.Row = 3; app.DistanceLabel.Layout.Column = 1;
            app.DistanceLabel.Text = 'Distance';
            app.DistanceLabel.FontColor = textDim;
            app.DistanceValue = uilabel(resGrid);
            app.DistanceValue.Layout.Row = 3; app.DistanceValue.Layout.Column = 2;
            app.DistanceValue.Text = '--';
            app.DistanceValue.FontSize = 14;
            app.DistanceValue.FontWeight = 'bold';
            app.DistanceValue.FontColor = green;
            app.DistanceValue.HorizontalAlignment = 'right';

            app.DurationLabel = uilabel(resGrid);
            app.DurationLabel.Layout.Row = 4; app.DurationLabel.Layout.Column = 1;
            app.DurationLabel.Text = 'Duration';
            app.DurationLabel.FontColor = textDim;
            app.DurationValue = uilabel(resGrid);
            app.DurationValue.Layout.Row = 4; app.DurationValue.Layout.Column = 2;
            app.DurationValue.Text = '--';
            app.DurationValue.FontSize = 14;
            app.DurationValue.FontWeight = 'bold';
            app.DurationValue.FontColor = [0.95 0.75 0.2];
            app.DurationValue.HorizontalAlignment = 'right';

            % Row 5 in resGrid: spacer

            app.FunFactLabel = uilabel(resGrid);
            app.FunFactLabel.Layout.Row = 6;
            app.FunFactLabel.Layout.Column = [1 2];
            app.FunFactLabel.Text = 'Load data to begin';
            app.FunFactLabel.FontSize = 11;
            app.FunFactLabel.FontColor = [0.7 0.6 0.3];
            app.FunFactLabel.HorizontalAlignment = 'center';

            % Row 10: flex spacer (handled by '1x')

            % Row 11: Status bar
            statusGrid = uigridlayout(leftGrid);
            statusGrid.Layout.Row = 11;
            statusGrid.Layout.Column = 1;
            statusGrid.ColumnWidth = {16, '1x'};
            statusGrid.RowHeight = {20};
            statusGrid.Padding = [0 0 0 0];
            statusGrid.BackgroundColor = panelBg;

            app.StatusLamp = uilamp(statusGrid);
            app.StatusLamp.Layout.Row = 1;
            app.StatusLamp.Layout.Column = 1;
            app.StatusLamp.Color = textDim;

            app.StatusLabel = uilabel(statusGrid);
            app.StatusLabel.Layout.Row = 1;
            app.StatusLabel.Layout.Column = 2;
            app.StatusLabel.Text = 'Ready';
            app.StatusLabel.FontSize = 11;
            app.StatusLabel.FontColor = textDim;

            % ============================================================
            %  RIGHT PANEL (Visualizations)
            % ============================================================
            app.RightPanel = uipanel(app.MainGrid);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;
            app.RightPanel.BackgroundColor = bgDark;
            app.RightPanel.BorderType = 'none';

            rightGrid = uigridlayout(app.RightPanel);
            rightGrid.ColumnWidth = {'1x'};
            rightGrid.RowHeight = {'1x'};
            rightGrid.Padding = [10 10 10 10];
            rightGrid.BackgroundColor = bgDark;

            % TabGroup
            app.TabGroup = uitabgroup(rightGrid);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 1;

            % --- Tab 1: Raw Data ---
            app.RawDataTab = uitab(app.TabGroup);
            app.RawDataTab.Title = 'Raw Data';
            app.RawDataTab.BackgroundColor = bgDark;

            rawGrid = uigridlayout(app.RawDataTab);
            rawGrid.ColumnWidth = {'1x'};
            rawGrid.RowHeight = {'1x'};
            rawGrid.Padding = [5 5 5 5];
            rawGrid.BackgroundColor = bgDark;

            app.RawAxes = uiaxes(rawGrid);
            app.RawAxes.Layout.Row = 1;
            app.RawAxes.Layout.Column = 1;
            app.RawAxes.BackgroundColor = panelBg;
            app.RawAxes.XColor = textDim;
            app.RawAxes.YColor = textDim;
            title(app.RawAxes, 'Load sensor data to begin', 'Color', textDim);

            % --- Tab 2: Processed ---
            app.ProcessedTab = uitab(app.TabGroup);
            app.ProcessedTab.Title = 'Steps & Signal';
            app.ProcessedTab.BackgroundColor = bgDark;

            procGrid = uigridlayout(app.ProcessedTab);
            procGrid.ColumnWidth = {'1x'};
            procGrid.RowHeight = {'1x'};
            procGrid.Padding = [5 5 5 5];
            procGrid.BackgroundColor = bgDark;

            app.ProcessedAxes = uiaxes(procGrid);
            app.ProcessedAxes.Layout.Row = 1;
            app.ProcessedAxes.Layout.Column = 1;
            app.ProcessedAxes.BackgroundColor = panelBg;
            app.ProcessedAxes.XColor = textDim;
            app.ProcessedAxes.YColor = textDim;

            % --- Tab 3: FFT ---
            app.FrequencyTab = uitab(app.TabGroup);
            app.FrequencyTab.Title = 'Frequency (FFT)';
            app.FrequencyTab.BackgroundColor = bgDark;

            fftGrid = uigridlayout(app.FrequencyTab);
            fftGrid.ColumnWidth = {'1x'};
            fftGrid.RowHeight = {'1x'};
            fftGrid.Padding = [5 5 5 5];
            fftGrid.BackgroundColor = bgDark;

            app.FFTAxes = uiaxes(fftGrid);
            app.FFTAxes.Layout.Row = 1;
            app.FFTAxes.Layout.Column = 1;
            app.FFTAxes.BackgroundColor = panelBg;
            app.FFTAxes.XColor = textDim;
            app.FFTAxes.YColor = textDim;

            % --- Tab 4: Summary ---
            app.SummaryTab = uitab(app.TabGroup);
            app.SummaryTab.Title = 'Calorie Burn';
            app.SummaryTab.BackgroundColor = bgDark;

            sumGrid = uigridlayout(app.SummaryTab);
            sumGrid.ColumnWidth = {'1x'};
            sumGrid.RowHeight = {'1x'};
            sumGrid.Padding = [5 5 5 5];
            sumGrid.BackgroundColor = bgDark;

            app.CalorieAxes = uiaxes(sumGrid);
            app.CalorieAxes.Layout.Row = 1;
            app.CalorieAxes.Layout.Column = 1;
            app.CalorieAxes.BackgroundColor = panelBg;
            app.CalorieAxes.XColor = textDim;
            app.CalorieAxes.YColor = textDim;

            % === Show figure ===
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        function app = FitSenseApp
            createComponents(app)
            registerApp(app, app.UIFigure)
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.UIFigure)
        end
    end
end
