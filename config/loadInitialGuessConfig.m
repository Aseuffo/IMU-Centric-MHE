function initCfg = loadInitialGuessConfig(jsonFile)

    if ~isfile(jsonFile)
        error('loadInitialGuessConfig:FileNotFound', ...
            'Config file not found: %s', jsonFile);
    end

    txt = fileread(jsonFile);
    cfg = jsondecode(txt);

    if ~isfield(cfg, 'initial_guess')
        error('loadInitialGuessConfig:MissingInitialGuess', ...
            'The JSON file does not contain an "initial_guess" section.');
    end

    initCfg = cfg.initial_guess;

end