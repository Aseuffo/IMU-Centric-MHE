function [sym, states, controls, params] = buildMheSymbols(layout)
    import casadi.*

    sym = struct();

    allNames = unique([ ...
        layout.stateNames, ...
        layout.controlNames, ...
        layout.paramNames]);

    for i = 1:numel(allNames)
        name = allNames{i};
        sym.(name) = SX.sym(name);
    end

    states = vertcatFromNames(sym, layout.stateNames);
    controls = vertcatFromNames(sym, layout.controlNames);

    if isempty(layout.paramNames)
        params = SX.sym('params', 0, 1);
    else
        params = vertcatFromNames(sym, layout.paramNames);
    end

end

function v = vertcatFromNames(sym, names)

    if isempty(names)
        v = SX.sym('empty', 0, 1);
        return;
    end

    v = sym.(names{1});

    for i = 2:numel(names)
        v = [v; sym.(names{i})];
    end

end