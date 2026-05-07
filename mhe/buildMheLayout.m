function layout = buildMheLayout(flags)

    layout = struct();

    %% States

    stateNames = {'vx', 'vy', 'r'};

    if flags.ay_in_state == true
        stateNames{end+1} = 'ay';
    end

    if flags.use_Dsum_lam == true && flags.DsumLam_as_params == false

        stateNames{end+1} = 'Dsum';
        stateNames{end+1} = 'lambda';

    elseif flags.D_in_states == true

        stateNames{end+1} = 'Df';
        stateNames{end+1} = 'Dr';

    end

    %% Parameters

    paramNames = {};

    if flags.use_Dsum_lam == true && flags.DsumLam_as_params == true

        paramNames = {'Dsum', 'lambda'};

    elseif flags.use_Dsum_lam == false && flags.D_in_states == false

        paramNames = {'Df', 'Dr'};

    end

    %% Controls

    controlNames = {'delta', 'ax'};

    %% Slacks

    slackNames = stateNames;

    if flags.ay_in_cost == true || flags.ay_state_model_constraint == true
        slackNames{end+1} = 'ay_consistency';
    end

    if flags.split_forces == true
        slackNames{end+1} = 'Fyf_split';
        slackNames{end+1} = 'Fyr_split';
    end

    layout.stateNames = stateNames;
    layout.paramNames = paramNames;
    layout.controlNames = controlNames;
    layout.slackNames = slackNames;

    layout.n_states = numel(stateNames);
    layout.n_params = numel(paramNames);
    layout.n_controls = numel(controlNames);
    layout.n_slacks = numel(slackNames);

    layout.params_are_decision = layout.n_params > 0;

end