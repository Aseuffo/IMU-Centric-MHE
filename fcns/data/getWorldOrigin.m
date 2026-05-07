function lla0 = getWorldOrigin(worldorigindata)
    % Extract field names from the input structure
    fields = fieldnames(worldorigindata);

    % Get "latitude"
    latitude = getField(worldorigindata, fields, 'latitude');

    % Get "longitude"
    longitude = getField(worldorigindata, fields, 'longitude');

    % Get "altitude"
    altitude = getField(worldorigindata, fields, 'altitude');

    lla0 = [latitude(1) longitude(1) altitude(1)];
end