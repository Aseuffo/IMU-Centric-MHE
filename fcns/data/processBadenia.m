function data = processBadenia(badeniaData, sim)
    % Extract field names from the input structure
    fields = fieldnames(badeniaData);

    % Get "headstamp" (stamp from message)
    headstamp = getField(badeniaData, fields, 'stamp');

    % Get Time (convert headstamp to seconds)
    time = getTimestamp(headstamp, sim);
    
    % Get Wheels Loads
    wLoadFl = getField(badeniaData, fields, 'wheelLoad_fl');
    wLoadFr = getField(badeniaData, fields, 'wheelLoad_fr');
    wLoadRl = getField(badeniaData, fields, 'wheelLoad_rl');
    wLoadRr = getField(badeniaData, fields, 'wheelLoad_rr');

    % Create time series for other parameters
    wLoadFl_ts.Time = time;
    wLoadFl_ts.Data = wLoadFl;
    wLoadFr_ts.Time = time;
    wLoadFr_ts.Data = wLoadFr;
    wLoadRl_ts.Time = time;
    wLoadRl_ts.Data = wLoadRl;
    wLoadRr_ts.Time = time;
    wLoadRr_ts.Data = wLoadRr;

    % Assemble the output structure
    data.wLoadFl = wLoadFl_ts;
    data.wLoadFr = wLoadFr_ts;
    data.wLoadRl = wLoadRl_ts;
    data.wLoadRr = wLoadRr_ts;
    
end