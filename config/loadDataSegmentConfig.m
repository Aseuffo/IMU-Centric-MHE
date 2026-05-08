function loadOpts = loadDataSegmentConfig(jsonFile)

    if ~isfile(jsonFile)
        error('loadDataSegmentConfig:FileNotFound', ...
            'Config file not found: %s', jsonFile);
    end

    txt = fileread(jsonFile);
    cfg = jsondecode(txt);

    if ~isfield(cfg, 'data_segment')
        error('loadDataSegmentConfig:MissingSection', ...
            'The JSON file does not contain a "data_segment" section.');
    end

    ds = cfg.data_segment;

    loadOpts = struct();

    loadOpts.lapStart = ds.lapStart;
    loadOpts.numLaps  = ds.numLaps;

    if isfield(ds, 'endPlus') && ~isempty(ds.endPlus)
        loadOpts.endPlus = ds.endPlus;
    else
        loadOpts.endPlus = [];
    end

    loadOpts.startOffset = ds.startOffset;
    loadOpts.endOffset   = ds.endOffset;

    loadOpts.doPlot = ds.doPlot;

end