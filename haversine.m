function totalDist = haversine(lat, lon)
    % HAVERSINE Calculate total distance traveled using GPS coordinates
    %
    % Uses the Haversine formula to compute the great-circle distance between
    % consecutive GPS points and sums them for total distance.
    %
    % Inputs:
    %   lat - Vector of latitude values (degrees)
    %   lon - Vector of longitude values (degrees)
    %
    % Output:
    %   totalDist - Total distance traveled in meters
    %
    % Example:
    %   dist = haversine(Position.latitude, Position.longitude);
    %
    % Reference: https://en.wikipedia.org/wiki/Haversine_formula
    % Copyright 2026 FitSense AI Team

    R = 6371000; % Earth's radius in meters

    % Convert to radians
    latRad = deg2rad(lat);
    lonRad = deg2rad(lon);

    % Calculate differences between consecutive points (vectorized)
    dLat = diff(latRad);
    dLon = diff(lonRad);

    % Haversine formula (vectorized for all point pairs)
    a = sin(dLat/2).^2 + ...
        cos(latRad(1:end-1)) .* cos(latRad(2:end)) .* sin(dLon/2).^2;
    c = 2 * atan2(sqrt(a), sqrt(1 - a));
    distances = R * c;

    % Filter out GPS jumps (noise > 50m between consecutive readings)
    distances(distances > 50) = 0;

    totalDist = sum(distances);
end
