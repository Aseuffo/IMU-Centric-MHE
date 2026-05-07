function lapCfg = loadLapDetectionConfig(jsonFile)

    if ~isfile(jsonFile)
        error('loadLapDetectionConfig:FileNotFound', ...
            'Config file not found: %s', jsonFile);
    end

    txt = fileread(jsonFile);
    cfg = jsondecode(txt);

    if ~isfield(cfg, 'lap_detection')
        error('loadLapDetectionConfig:MissingSection', ...
            'The JSON file does not contain a "lap_detection" section.');
    end

    lapCfg = cfg.lap_detection;

end