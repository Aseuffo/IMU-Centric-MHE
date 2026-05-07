function data = processKistler(kistlerdata, sim, movmean_window_size)
    if nargin < 3
        movmean_window_size = 0.1;
    end

    % Extract field names from the input structure
    fields = fieldnames(kistlerdata);
    
    % Get "headstamp" (stamp from message)
    headstamp = getField(kistlerdata, fields, 'stamp');
    
    % Get Time (convert headstamp to seconds)
    time = getTimestamp(headstamp, sim);
    
    % Get correvit speeds
    velcorr = getField(kistlerdata, fields, 'velCorXY');
    
    % Get longitudinal and lateral speed measurements
    longSpeed = velcorr.value0;
    latSpeed = velcorr.value1;

    % Causal Filtering
    dt = mean(diff(time));
    window_size = round(movmean_window_size / dt);
    % longSpeed = movmean(longSpeed, [window_size 1]);
    % latSpeed = movmean(latSpeed, [window_size 1]);

    % Create time series
    longSpeed_ts.Time = time;
    longSpeed_ts.Data = longSpeed;
    latSpeed_ts.Time = time;
    latSpeed_ts.Data = latSpeed;
    
    % Assemble the output structure
    data.longSpeed = longSpeed_ts;
    data.latSpeed = latSpeed_ts;
end