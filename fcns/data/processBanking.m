function data = processBanking(slam_front, sim, movmean_window_size)
if nargin < 3
    movmean_window_size = 0.1;
end

% Extract field names from the input structure
fields = fieldnames(slam_front);

% Get "headstamp" (stamp from message)
headstamp = getField(slam_front, fields, 'stamp');

% Get Time (convert headstamp to seconds)
time = headstamp./ 1e9;

% Get the lateral velocity
bank = getField(slam_front,fields,'bank');

% Get longitudinal and lateral speed measurements
road_bank = bank ;

% Causal Filtering
dt = mean(diff(time));
window_size = round(movmean_window_size / dt);
% road_bank = movmean(road_bank, [window_size 1]);

% Create time series
roadBank_ts.Time = time;
roadBank_ts.Data = road_bank;

% Assemble the output structure
data.roadBank = roadBank_ts;

end