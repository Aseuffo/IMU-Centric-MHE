function lap_indices = lapDetection(xdata, ydata, start_position, Ts, lapCfg)

    x = xdata(:);
    y = ydata(:);

    if numel(x) ~= numel(y)
        error('lapDetection:InvalidInput', ...
            'xdata and ydata must have the same length.');
    end

    if numel(start_position) ~= 2
        error('lapDetection:InvalidStartPosition', ...
            'start_position must contain [x0, y0].');
    end

    threshold = double(lapCfg.threshold);
    minGapSamples = round(double(lapCfg.min_gap_time) / Ts);

    sx = start_position(1);
    sy = start_position(2);

    %% Distance to start point

    dist = hypot(x - sx, y - sy);
    inside = dist < threshold;

    %% Ignore first inside-zone segment if trajectory starts inside

    if lapCfg.ignore_initial_inside_zone == true && inside(1)

        first_out = find(~inside, 1, 'first');

        if isempty(first_out)
            lap_indices = [];
            warning('lapDetection:NeverLeavesZone', ...
                'Trajectory starts inside the lap zone and never leaves it.');
            return;
        end

        inside(1:first_out-1) = false;

    end

    %% Lap event = entering the zone

    enter = inside & ~[false; inside(1:end-1)];

    lap_indices = find(enter);

    %% Debounce

    if numel(lap_indices) > 1
        keep = [true; diff(lap_indices) >= minGapSamples];
        lap_indices = lap_indices(keep);
    end

    if isempty(lap_indices)
        warning('lapDetection:NoLapCompleted', ...
            'No lap completed.');
    end

end