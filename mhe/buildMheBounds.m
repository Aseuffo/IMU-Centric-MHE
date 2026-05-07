function bounds = buildMheBounds(boundsCfg, caseName, layout, N_MHE)

    bounds = struct();

    %% State bounds

    [x_lb, x_ub] = boundsFromNames( ...
        boundsCfg, ...
        layout.stateNames, ...
        caseName);

    %% Control bounds

    [u_lb, u_ub] = boundsFromNames( ...
        boundsCfg, ...
        layout.controlNames, ...
        caseName);

    %% Parameter bounds

    if isempty(layout.paramNames)
        par_lb = [];
        par_ub = [];
    else
        [par_lb, par_ub] = boundsFromNames( ...
            boundsCfg, ...
            layout.paramNames, ...
            caseName);
    end

    %% Slack bounds

    if ~isfield(boundsCfg.state_slack_bounds, caseName)
        error('buildMheBounds:MissingSlackCase', ...
            'Missing state_slack_bounds for case "%s".', caseName);
    end

    tmp = boundsCfg.state_slack_bounds.(caseName);
    state_slack_bounds = double(tmp(:));

    if numel(state_slack_bounds) ~= layout.n_states
        error('buildMheBounds:InvalidSlackDimension', ...
            'state_slack_bounds.%s has length %d, but n_states = %d.', ...
            caseName, numel(state_slack_bounds), layout.n_states);
    end

    extra_slack_bounds = [];

    if any(strcmp(layout.slackNames, 'ay_consistency'))

        tmp = boundsCfg.extra_slack_bounds.ay_consistency;
        extra_slack_bounds = [extra_slack_bounds; double(tmp)];

    end

    if any(strcmp(layout.slackNames, 'Fyf_split')) || ...
       any(strcmp(layout.slackNames, 'Fyr_split'))

        tmp = boundsCfg.extra_slack_bounds.force_split;
        extra_slack_bounds = [extra_slack_bounds; double(tmp(:))];

    end

    sl_base = [state_slack_bounds; extra_slack_bounds];

    if numel(sl_base) ~= layout.n_slacks
        error('buildMheBounds:InvalidFullSlackDimension', ...
            'sl_base has length %d, but n_slacks = %d.', ...
            numel(sl_base), layout.n_slacks);
    end

    %% Repeated bounds over horizon

    bounds.x_lb = x_lb;
    bounds.x_ub = x_ub;

    bounds.u_lb = u_lb;
    bounds.u_ub = u_ub;

    bounds.par_lb = par_lb;
    bounds.par_ub = par_ub;

    bounds.sl_base = sl_base;

    bounds.state_lb   = repmat(x_lb, N_MHE + 1, 1);
    bounds.state_ub   = repmat(x_ub, N_MHE + 1, 1);

    bounds.control_lb = repmat(u_lb, N_MHE, 1);
    bounds.control_ub = repmat(u_ub, N_MHE, 1);

    bounds.slack_lb   = repmat(-sl_base, N_MHE, 1);
    bounds.slack_ub   = repmat(+sl_base, N_MHE, 1);

end


function [lb, ub] = boundsFromNames(boundsCfg, names, caseName)

    lb = zeros(numel(names), 1);
    ub = zeros(numel(names), 1);

    for i = 1:numel(names)

        name = names{i};

        b = getVariableBound(boundsCfg, name, caseName);

        lb(i) = b(1);
        ub(i) = b(2);

    end

end


function b = getVariableBound(boundsCfg, name, caseName)

    if isfield(boundsCfg, 'case_overrides') && ...
       isfield(boundsCfg.case_overrides, caseName) && ...
       isfield(boundsCfg.case_overrides.(caseName), name)

        raw = boundsCfg.case_overrides.(caseName).(name);
        b = double(raw(:));
        return;

    end

    if ~isfield(boundsCfg.variables, name)
        error('getVariableBound:MissingVariableBound', ...
            'No bound found for variable "%s".', name);
    end

    raw = boundsCfg.variables.(name);
    b = double(raw(:));

    if numel(b) ~= 2
        error('getVariableBound:InvalidBound', ...
            'Bound for variable "%s" must have two entries [min, max].', name);
    end

end