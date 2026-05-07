function data = processGps(gpsdata, lla0, sim)
    % Extract field names from the input structure
    fields = fieldnames(gpsdata);

    % Get "headstamp" (stamp from message)
    headstamp = getField(gpsdata, fields, 'stamp');

    % Get "latitude"
    latitude = getField(gpsdata, fields, 'latitude');

    % Get "longitude"
    longitude = getField(gpsdata, fields, 'longitude');

    % Get "altitude"
    altitude = getField(gpsdata, fields, 'altitude');

    % Get "positionCov"
    covariance = getField(gpsdata, fields, 'positionCov');

    % Get "speed"
    speed = getField(gpsdata, fields, 'speed');

    % Get Time (convert headstamp to seconds)
    time = getTimestamp(headstamp, sim);
    
    % Convert latitude, longitude, altitude to flat Earth coordinates (XYZ)
    [x0,y0] = ll2utm(lla0(1),lla0(2));
    [x,y] = ll2utm(latitude,longitude);
    x = x-x0;
    y = y-y0;
    z = altitude-lla0(3);

    % Create time series for x and y coordinates
    x_ts.Time = time;
    x_ts.Data = x;

    x_cov_ts.Time = time;
    % x_cov_ts.Data = (covariance.value0 + covariance.value4) / 2;
    x_cov_ts.Data = (covariance.value0_value0 + covariance.value0_value1) / 2;

    y_ts.Time = time;
    y_ts.Data = y;

    y_cov_ts.Time = time;
    % y_cov_ts.Data = (covariance.value0 + covariance.value4) / 2;
    y_cov_ts.Data = (covariance.value0_value0 + covariance.value0_value1) / 2;

    z_ts.Time = time;
    z_ts.Data = z;

    z_cov_ts.Time = time;
    % z_cov_ts.Data = covariance.value8;
    z_cov_ts.Data = covariance.value0_value2;


    speed_ts.Time = time;
    speed_ts.Data = sqrt(speed.value0.^2 + speed.value1.^2);
    
    speed_cov_ts.Time = time;
    % speed_cov_ts.Data = speed.Cov_value0_value0 + speed.Cov_value1;
    speed_cov_ts.Data = speed.Cov_value0_value0 + speed.Cov_value1_value1;

    % Assemble the output structure with XY data
    data.x = x_ts;
    data.y = y_ts;
    data.z = z_ts;
    data.xCov = x_cov_ts;
    data.yCov = y_cov_ts;
    data.zCov = z_cov_ts;
    data.speed = speed_ts;
    data.speedCov = speed_cov_ts;
    
    % Check if the "angle" field exists
    if any(contains(fields, 'angle'))
        % Get "angle"
        angle = getField(gpsdata, fields, 'angle');

        % Create time series
        yaw_ts.Time = time;
        yaw_ts.Data = unwrap(angle.value2);

        yaw_cov_ts.Time = time;
        % yaw_cov_ts.Data = angle.Cov_value8;
        yaw_cov_ts.Data = angle.Cov_value0_value2;
        
        % Add yaw to the output structure
        data.yaw = yaw_ts;
        data.yawCov = yaw_cov_ts;
    end
end