function [data, meta] = loadLogData(log, Ts, vehicle, opts)
% loadLogData
%
% Loads, filters, segments, interpolates and prepares measured vehicle data.
%
% Output:
%   data.t
%   data.vx
%   data.vy
%   data.r
%   data.delta
%   data.ax
%   data.ay
%   data.az
%   data.Fyf
%   data.Fyr
%   data.x
%   data.y
%
%   meta.idx
%   meta.laps
%   meta.options

    if nargin < 4 || isempty(opts)
        opts = struct();
    end

    opts = setDefaultLoadOptions(opts, log);

    %% Start point

    start_position = startPointFromCarName(opts.carName);

    %% Read raw signals

    sig = readLogSignals(log);

    %% Lever-arm correction for lateral speed

    lever = leverArmFromCarName(opts.carName);

    if isempty(sig.vy)
        error('loadLogData:MissingVy', ...
              ['Could not find lateral speed signal. Expected one of:\n' ...
               '  - log.vyData.latSpeed.Data\n' ...
               '  - log.Measurements.KISTLER.latSpeed.Data\n' ...
               '  - log.kistlerData.latSpeed.Data\n']);
    end

    if sig.vyNeedsLeverCorrection
        sig.vy = sig.vy - lever * sig.rRaw;
    end

    %% Unify signal length

    n = min([ ...
        numel(sig.x), ...
        numel(sig.y), ...
        numel(sig.vx), ...
        numel(sig.vy), ...
        numel(sig.rRaw), ...
        numel(sig.ax), ...
        numel(sig.ayRaw), ...
        numel(sig.az), ...
        numel(sig.delta)]);

    if n < 2
        error('loadLogData:NotEnoughData','Not enough samples in log signals.');
    end

    sig = trimSignals(sig, n);

    %% Filtering

    sig.r  = sgolayfilt(hampel(sig.rRaw, 30), 3, 35);
    sig.ay = sgolayfilt(hampel(sig.ayRaw, 30), 3, 35);

    %% Lap detection and segment selection

    laps = lapDetection( ...
    sig.x, ...
    sig.y, ...
    start_position, ...
    Ts, ...
    opts.lap_detection);


    idx  = buildIdx(laps, opts, n);

    %% Time base

    t_full = getTimeVector(log, n);
    t_seg  = t_full(idx);
    t_seg  = t_seg - t_seg(1);

    t_inter = (t_seg(1):Ts:t_seg(end)).';

    %% Interpolation

    data = struct();

    data.t = t_inter;

    data.vx    = interp1(t_seg, sig.vx(idx),    t_inter, 'linear');
    data.vy    = interp1(t_seg, sig.vy(idx),    t_inter, 'linear');
    data.r     = interp1(t_seg, sig.r(idx),     t_inter, 'linear');
    data.delta = interp1(t_seg, sig.delta(idx), t_inter, 'linear');
    data.ax    = interp1(t_seg, sig.ax(idx),    t_inter, 'linear');
    data.ay    = interp1(t_seg, sig.ay(idx),    t_inter, 'linear');
    data.az    = interp1(t_seg, sig.az(idx),    t_inter, 'linear');

    data.x = interp1(t_seg, sig.x(idx), t_inter, 'linear');
    data.y = interp1(t_seg, sig.y(idx), t_inter, 'linear');

    %% Simple lateral force split

    [data.Fyf, data.Fyr] = computeSimpleLateralForceSplit( ...
        data.ay, ...
        data.delta, ...
        vehicle);

    %% Useful grouped signals for MHE

    data.y_measurements = [data.vx, data.r];
    data.u_cl = [data.delta, data.ax];

    %% Metadata

    meta = struct();

    meta.idx = idx;
    meta.laps = laps;
    meta.options = opts;
    meta.start_position = start_position;
    meta.vehicleType = opts.carName;

    %% Optional plot

    if opts.doPlot
        plotLoadedSegment(sig.x, sig.y, data.x, data.y, opts.carName);
    end

end

function opts = setDefaultLoadOptions(opts, log)

    default = struct();

    default.carName = string(log.vehicleType);

    default.lapStart = 2;
    default.numLaps = 3;

    % Important:
    % If endPlus is not empty, it overrides numLaps.
    default.endPlus = [];

    default.startOffset = 0;
    default.endOffset = 0;
    
    default.doPlot = false;
    
    default.lap_detection = struct();
    default.lap_detection.threshold = 50.0;
    default.lap_detection.min_gap_time = 2.0;
    default.lap_detection.ignore_initial_inside_zone = true;

    fields = fieldnames(default);

    for i = 1:numel(fields)
        f = fields{i};

        if ~isfield(opts, f) || isempty(opts.(f))
            opts.(f) = default.(f);
        end
    end

    opts.carName = string(opts.carName);

end

function sig = readLogSignals(log)

    sig = struct();

    sig.x = col(log.slamData.x.Data);
    sig.y = col(log.slamData.y.Data);

    sig.vx = col(log.Measurements.KISTLER.longSpeed.Data);
    sig.rRaw = col(log.vehiclestateData.yawRate.Data);

    sig.ax = col(log.vehiclestateData.longAcc.Data);
    sig.ayRaw = col(log.vehiclestateData.latAcc.Data);
    sig.az = col(log.imuData.vertAcc.Data);
    sig.delta = col(log.carData.steer.Data);

    sig.vy = [];
    sig.vyNeedsLeverCorrection = false;

    if isfield(log,'vyData') && ...
       isfield(log.vyData,'latSpeed') && ...
       isfield(log.vyData.latSpeed,'Data') && ...
       ~isempty(log.vyData.latSpeed.Data)

        sig.vy = col(log.vyData.latSpeed.Data);
        sig.vyNeedsLeverCorrection = false;

    elseif isfield(log,'Measurements') && ...
           isfield(log.Measurements,'KISTLER') && ...
           isfield(log.Measurements.KISTLER,'latSpeed') && ...
           isfield(log.Measurements.KISTLER.latSpeed,'Data') && ...
           ~isempty(log.Measurements.KISTLER.latSpeed.Data)

        sig.vy = col(log.Measurements.KISTLER.latSpeed.Data);
        sig.vyNeedsLeverCorrection = true;

    elseif isfield(log,'kistlerData') && ...
           isfield(log.kistlerData,'latSpeed') && ...
           isfield(log.kistlerData.latSpeed,'Data') && ...
           ~isempty(log.kistlerData.latSpeed.Data)

        sig.vy = col(log.kistlerData.latSpeed.Data);
        sig.vyNeedsLeverCorrection = true;

    end

end


function sig = trimSignals(sig, n)

    names = fieldnames(sig);

    for i = 1:numel(names)

        f = names{i};

        if isnumeric(sig.(f)) && numel(sig.(f)) >= n
            sig.(f) = sig.(f)(1:n);
        end

    end

end


function [Fyf, Fyr] = computeSimpleLateralForceSplit(ay, delta, vehicle)

    m  = vehicle.physics.mass;
    lf = vehicle.geometry.lf;
    lr = vehicle.geometry.lr;
    wb = vehicle.geometry.wheelbase;

    c = cos(delta);

    c(abs(c) < 1e-6) = 1e-6;

    Fyf = (m .* ay) .* lr ./ (wb .* c);
    Fyr = (lf ./ wb) .* (m .* ay);

end

function lever = leverArmFromCarName(carName)

    carTag = lower(string(carName));

    if contains(carTag,"indy") || contains(carTag,"indylight")
        lever = 2.0978;

    elseif contains(carTag,"superformula") || contains(carTag,"sf")
        lever = 1.994;

    else
        lever = 0.0;
    end

end


function sp = startPointFromCarName(carName)

    s = lower(string(carName));

    if contains(s, "ferrari")
        sp = [48.17; 174.225];

    elseif contains(s, "corvette")
        sp = [48.17; 174.225];

    elseif contains(s, "indy") || contains(s, "indylight")
        sp = [48.17; 174.225];

    elseif contains(s, "superformula") || contains(s, "sf")
        sp = [48.17; 174.225];

    else
        warning('Unknown car name "%s". Using default start position.', string(carName));
        sp = [48.17; 174.225];
    end

end


function t = getTimeVector(log, n)

    if isfield(log,'vyData') && ...
       isfield(log.vyData,'longSpeed') && ...
       isfield(log.vyData.longSpeed,'Time')

        t = col(log.vyData.longSpeed.Time);

    elseif isfield(log,'slamData') && ...
           isfield(log.slamData,'x') && ...
           isfield(log.slamData.x,'Time')

        t = col(log.slamData.x.Time);

    else
        t = (0:n-1).';
        return;
    end

    if numel(t) < n
        dt = 1;

        if numel(t) >= 2
            dt = median(diff(t));
        end

        t = [t; t(end) + dt*(1:(n-numel(t)))'];
    end

    t = t(1:n);

end


function idx = buildIdx(laps, opts, n)

    if isempty(laps) || numel(laps) < 2
        idx = 1:n;
        return;
    end

    laps = laps(:).';

    k = max(1, min(numel(laps), round(opts.lapStart)));

    startIdx = laps(k) + round(opts.startOffset);

    if ~isempty(opts.endPlus)
        endIdx = startIdx + round(opts.endPlus);
    else
        L  = max(1, round(opts.numLaps));
        k2 = min(numel(laps), k + L);
        endIdx = laps(k2) + round(opts.endOffset);
    end

    startIdx = max(1, min(n, startIdx));
    endIdx   = max(1, min(n, endIdx));

    if endIdx <= startIdx
        warning('Invalid segment indices. Using full signal.');
        idx = 1:n;
    else
        idx = startIdx:endIdx;
    end

end


function plotLoadedSegment(x_all, y_all, x_inter, y_inter, carName)

    figure('Name','Loaded Log Segment','NumberTitle','off');
    hold on;

    plot(x_all, y_all, 'b.-', ...
        'DisplayName','Measured');

    plot(x_inter, y_inter, 'r--', ...
        'LineWidth',1.5, ...
        'DisplayName','Interpolated segment');

    grid on;
    axis equal;

    xlabel('X Position');
    ylabel('Y Position');

    title(sprintf('Measured vs Interpolated | carName = "%s"', string(carName)));

    legend('Location','best');

end


function v = col(v)

    v = v(:);

end