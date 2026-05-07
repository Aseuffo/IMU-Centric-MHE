function flags = loadMheFlags(jsonFile)

    if ~isfile(jsonFile)
        error('loadMheFlags:FileNotFound', ...
            'Config file not found: %s', jsonFile);
    end

    txt = fileread(jsonFile);
    cfg = jsondecode(txt);

    if ~isfield(cfg, 'flags')
        error('loadMheFlags:MissingFlags', ...
            'The JSON file does not contain a "flags" section.');
    end

    flags = cfg.flags;

    %% Coherence rules

    if flags.ay_drives_vy == true
        flags.ay_in_state = true;
    end

    if flags.use_Dsum_lam == true
        if flags.DsumLam_as_params == true
            flags.D_in_states = false;
        else
            flags.D_in_states = true;
        end
    end

    flags.ay_state_model_constraint = ...
        (flags.ay_in_state == true) && ...
        (flags.ay_drives_vy == false);

    %% Sanity checks

    assert(flags.optimised_input == true, ...
        'This file is for optimised_input = true only.');

    assert(~(flags.ay_in_state && flags.ay_in_cost), ...
        'Invalid flags: ay_in_state and ay_in_cost cannot both be true.');

    assert(~(flags.split_forces && flags.ay_in_cost), ...
        'Invalid flags: split_forces and ay_in_cost cannot both be true.');

    assert(~(flags.split_forces && flags.ay_in_state), ...
        'Invalid flags: split_forces and ay_in_state cannot both be true.');

    assert(~(flags.use_Dsum_lam && flags.DsumLam_as_params && flags.D_in_states), ...
        'Invalid: DsumLam_as_params=true implies D_in_states=false.');

end