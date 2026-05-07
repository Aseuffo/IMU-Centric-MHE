function data = processSlam(slamdata, sim)
    % Extract field names from the input structure
    fields = fieldnames(slamdata);

    % Get "headstamp" (stamp from message)
    headstamp = getField(slamdata, fields, 'stamp');

    % Get "position"
    position = getField(slamdata, fields, 'position');

    % Get "orientation"
    orientation = getField(slamdata, fields, 'orientation');

    % Get "pose covariance"
    poseCov = getField(slamdata, fields, 'pose_covariance');

    % Get "speed"
    speed = getField(slamdata, fields, 'twist_linear');

    % Get "twist covariance"
    twistCov = getField(slamdata, fields, 'twist_covariance');

    % Get Time (convert headstamp to seconds)
    time = getTimestamp(headstamp, sim);
    
    % Extract x and y positions
    x = position.value0;
    y = position.value1;
    z = position.value2;

    % Create time series for x and y coordinates
    x_ts.Time = time;
    x_ts.Data = x;

    x_cov_ts.Time = time;
    % x_cov_ts.Data = (poseCov.value0 + poseCov.value7) / 2;
    x_cov_ts.Data = (poseCov.value0_value0 + poseCov.value0_value5) / 2;

    
    y_ts.Time = time;
    y_ts.Data = y;

    y_cov_ts.Time = time;
    % y_cov_ts.Data = (poseCov.value0 + poseCov.value7) / 2;
    y_cov_ts.Data = (poseCov.value0_value0 + poseCov.value5_value5) / 2;


    z_ts.Time = time;
    z_ts.Data = z;

    z_cov_ts.Time = time;
    % z_cov_ts.Data = poseCov.value14;
    z_cov_ts.Data = poseCov.value3_value5;

    speed_ts.Time = time;
    speed_ts.Data = speed.value0;
    
    speed_cov_ts.Time = time;
    % speed_cov_ts.Data = twistCov.value0;
    speed_cov_ts.Data = twistCov.value0_value0;

    speedLat_ts.Time = time;
    speedLat_ts.Data = speed.value1;
    
    speedLat_cov_ts.Time = time;
    % speedLat_cov_ts.Data = twistCov.value7;
    speedLat_cov_ts.Data = twistCov.value0_value5;

    % Assemble the output structure with XY data
    data.x = x_ts;
    data.y = y_ts;
    data.z = z_ts;
    data.xCov = x_cov_ts;
    data.yCov = y_cov_ts;
    data.zCov = z_cov_ts;
    data.speed = speed_ts;
    data.speedCov = speed_cov_ts;
    data.speedLat = speedLat_ts;
    data.speedLatCov = speedLat_cov_ts;

    % Calculate and add yaw to the output
    euler = quat2eul([orientation.w, orientation.x, orientation.y, orientation.z]).';
    yaw = euler(1,:);
    pitch = euler(2,:);
    roll = euler(3,:);

    yaw_ts.Time = time;
    yaw_ts.Data = yaw;
    pitch_ts.Time = time;
    pitch_ts.Data = pitch;
    roll_ts.Time = time;
    roll_ts.Data = roll;

    yaw_cov_ts.Time = time;
    % yaw_cov_ts.Data = poseCov.value35;
    yaw_cov_ts.Data = poseCov.value0_value0;

    data.yaw = yaw_ts;
    data.pitch = pitch_ts;
    data.roll = roll_ts;
    data.yawCov = yaw_cov_ts;
end