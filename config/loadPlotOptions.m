function plotOpts = loadPlotOptions(jsonFile)

    if ~isfile(jsonFile)
        error('loadPlotOptions:FileNotFound', ...
            'Config file not found: %s', jsonFile);
    end

    txt = fileread(jsonFile);
    cfg = jsondecode(txt);

    if ~isfield(cfg, 'plot')
        error('loadPlotOptions:MissingPlotSection', ...
            'The JSON file does not contain a "plot" section.');
    end

    p = cfg.plot;

    plotOpts = struct();

    plotOpts.plotSlack   = logical(p.plotSlack);
    plotOpts.plotForces  = logical(p.plotForces);
    plotOpts.saveFigures = logical(p.saveFigures);
    plotOpts.saveFolder  = char(p.saveFolder);
    plotOpts.dataFile    = char(p.dataFile);

end