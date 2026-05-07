function opts = loadSolverOptions(jsonFile)

    if ~isfile(jsonFile)
        error('loadSolverOptions:FileNotFound', ...
            'Config file not found: %s', jsonFile);
    end

    txt = fileread(jsonFile);
    cfg = jsondecode(txt);

    if ~isfield(cfg, 'solver')
        error('loadSolverOptions:MissingSolverOptions', ...
            'The JSON file does not contain a "solver" section.');
    end

    opts = cfg.solver;

    % Safety conversion for string fields
    if isfield(opts, 'ipopt')

        if isfield(opts.ipopt, 'warm_start_init_point')
            opts.ipopt.warm_start_init_point = ...
                char(opts.ipopt.warm_start_init_point);
        end

        if isfield(opts.ipopt, 'mu_strategy')
            opts.ipopt.mu_strategy = ...
                char(opts.ipopt.mu_strategy);
        end

    end

end