function data = processVyCoG(locdata, sim, movmean_window_size)
if nargin < 3
    movmean_window_size = 0.1;
end

% Extract field names from the input structure
fields = fieldnames(locdata);

% Get "headstamp" (stamp from message)
headstamp = getField(locdata, fields, 'stamp');

% Get Time (convert headstamp to seconds)
time = headstamp./ 1e9;

% Get the lateral velocity
vy = getField(locdata, fields, 'x__loc_measures_vy_kistler_measure_value1');
vx = getField(locdata, fields, 'x__loc_measures_vy_kistler_measure_value0');


% Get longitudinal and lateral speed measurements
longSpeed = vx;
latSpeed = vy;

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