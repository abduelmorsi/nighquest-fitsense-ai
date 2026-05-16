function elapsed = timeElapsed(datetime_array)
    % TIMEELAPSED Converts datetime array to elapsed seconds (vectorized)
    %
    % This function converts an array of datetime elements into elapsed time
    % in seconds from the first data point. Uses vectorized operations for
    % efficiency instead of loop-based approach.
    %
    % Input:
    %   datetime_array - Array of datetime values from sensor data
    %
    % Output:
    %   elapsed - Numeric array of elapsed time in seconds
    %
    % Example:
    %   t = timeElapsed(Acceleration.Timestamp);
    %
    % Copyright 2026 FitSense AI Team

    elapsed = seconds(datetime_array - datetime_array(1));
end
