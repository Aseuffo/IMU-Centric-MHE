function data = processCarState(carstatedata, sim)
    % Extract field names from the input structure
    fields = fieldnames(carstatedata);

    % Get "headstamp" (stamp from message)
    headstamp = getField(carstatedata, fields, 'stamp');

    % Get Time (convert headstamp to seconds)
    time = headstamp.value1 ./ 1e9;
    
    % Get Gear State
    gear = getField(carstatedata, fields, 'gear');
    if (isfield(gear,'gear'))
        gear = gear.gear;
    end

    % Get Engine RPM
    rpm = getField(carstatedata, fields, 'rpm');

    % Get Throttle Pedal
    throttle = getField(carstatedata, fields, 'throttle');

    % Get Throttle Pedal
    brake = getField(carstatedata, fields, 'brake');

    % Get Wheel Steer Angle
    steer = getField(carstatedata, fields, 'steer');
    if (isfield(steer,'Angle'))
        steer = steer.Angle;
    end
    
    % Get Wheel Speeds
    speed = getField(carstatedata, fields, 'wheelSpeed');

    % Extract individual tire speeds
    s_fl = speed.s_fl;  
    s_fr = speed.s_fr;  
    s_rl = speed.s_rl;  
    s_rr = speed.s_rr;  

    % Create time series for each tire speed
    s_fl_ts.Time = time;
    s_fl_ts.Data = s_fl;
    
    s_fr_ts.Time = time;
    s_fr_ts.Data = s_fr;
    
    s_rl_ts.Time = time;
    s_rl_ts.Data = s_rl;
    
    s_rr_ts.Time = time;
    s_rr_ts.Data = s_rr;

    % Create time series for other parameters
    gear_ts.Time = time;
    gear_ts.Data = gear.value1;
    
    rpm_ts.Time = time;
    rpm_ts.Data = rpm;
    
    throttle_ts.Time = time;
    throttle_ts.Data = throttle.value1;
    
    brake_ts.Time = time;
    brake_ts.Data = (brake.s_fl + brake.s_fr + brake.s_rl + brake.s_rr)./4;
    
    steer_ts.Time = time;
    steer_ts.Data = steer.ing;
    
    speed_ts.Time = time;
    speed_ts.Data = (s_fl + s_fr + s_rl + s_rr) ./ 4;

    % Assemble the output structure
    data.gear = gear_ts;
    data.rpm = rpm_ts;
    data.throttle = throttle_ts;
    data.brake = brake_ts;
    data.steer = steer_ts;
    data.speed = speed_ts;
    data.s_fl_speed = s_fl_ts;
    data.s_fr_speed = s_fr_ts;
    data.s_rl_speed = s_rl_ts;
    data.s_rr_speed = s_rr_ts;

end