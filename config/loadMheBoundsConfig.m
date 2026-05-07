function boundsCfg = loadMheBoundsConfig(jsonFile)

    if ~isfile(jsonFile)
        error('loadMheBoundsConfig:FileNotFound', ...
            'Config file not found: %s', jsonFile);
    end

    txt = fileread(jsonFile);
    cfg = jsondecode(txt);

    if ~isfield(cfg, 'bounds')
        error('loadMheBoundsConfig:MissingBounds', ...
            'The JSON file does not contain a "bounds" section.');
    end

    boundsCfg = cfg.bounds;

end