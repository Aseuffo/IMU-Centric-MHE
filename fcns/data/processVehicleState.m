function data = processVehicleState(vehicleData, sim, movmean_window_size)
    if nargin < 3
            movmean_window_size = 0.1;
    end
    
    % Extract field names from the input structure
    fields = fieldnames(vehicleData);

    % Get "headstamp" (stamp from message)
    headstamp = getField(vehicleData, fields, 'stamp');

    linearAcceleration = getField(vehicleData, fields, 'linAcc');
    angularVelocity = getField(vehicleData, fields, 'angVel');

    % Get Time (convert headstamp to seconds)
    time = getTimestamp(headstamp, sim);

    % Get Long/Lat Accelerations
    longAcc = linearAcceleration.value0;
    % longAccCov = linearAcceleration.Cov_value0;
    longAccCov = linearAcceleration.Cov_value0_value0;
    latAcc = linearAcceleration.value1;
    % latAccCov = linearAcceleration.Cov_value1;
    latAccCov = linearAcceleration.Cov_value1_value1;
    % Get Yaw Rate
    yawRate = angularVelocity.value2;
    % yawRateCov = angularVelocity.Cov_value2;
    yawRateCov = angularVelocity.Cov_value2_value2;


    % Causal Filtering
    dt = mean(diff(time));
    window_size = round(movmean_window_size / dt);
    % longAcc = movmean(longAcc, [window_size 1]);
    % latAcc = movmean(latAcc, [window_size 1]);
    % yawRate = movmean(yawRate, [window_size 1]);

    % Create time series
    longAcc_ts.Time = time;
    longAcc_ts.Data = longAcc;
    latAcc_ts.Time = time;
    latAcc_ts.Data = latAcc;
    yawRate_ts.Time = time;
    yawRate_ts.Data = yawRate;
    longAccCov_ts.Time = time;
    longAccCov_ts.Data = longAccCov;
    latAccCov_ts.Time = time;
    latAccCov_ts.Data = latAccCov;
    yawRateCov_ts.Time = time;
    yawRateCov_ts.Data = yawRateCov;    

    % Assemble the output structure
    data.longAcc = longAcc_ts;
    data.latAcc = latAcc_ts;
    data.yawRate = yawRate_ts;
    data.longAccCov = longAccCov_ts;
    data.latAccCov = latAccCov_ts;
    data.yawRateCov = yawRateCov_ts;
end 