function [X0, U0, slack0, par0] = buildInitialGuess( ...
    initCfg, layout, measurementNames, y_measurements, u_cl, N_MHE)

    X0 = zeros(N_MHE + 1, layout.n_states);

    %% State initial guess

    for i = 1:numel(layout.stateNames)

        name = layout.stateNames{i};

        switch name

            case 'vx'
                X0(:, i) = getMeasurementWindow( ...
                    y_measurements, measurementNames, 'vx', N_MHE + 1);

            case 'r'
                X0(:, i) = getMeasurementWindow( ...
                    y_measurements, measurementNames, 'r', N_MHE + 1);

            case 'ay'
                X0(:, i) = getMeasurementWindow( ...
                    y_measurements, measurementNames, 'ay', N_MHE + 1);

            case 'vy'
                X0(:, i) = double(initCfg.vy) * ones(N_MHE + 1, 1);

            case 'Df'
                X0(:, i) = double(initCfg.Df_state) * ones(N_MHE + 1, 1);

            case 'Dr'
                X0(:, i) = double(initCfg.Dr_state) * ones(N_MHE + 1, 1);

            case 'Dsum'
                X0(:, i) = double(initCfg.Dsum_state) * ones(N_MHE + 1, 1);

            case 'lambda'
                X0(:, i) = double(initCfg.lambda_state) * ones(N_MHE + 1, 1);

            otherwise
                error('buildInitialGuess:UnknownState', ...
                    'Unknown state "%s".', name);

        end

    end

    %% Control initial guess

    U0 = u_cl(1:N_MHE, 1:layout.n_controls);

    %% Slack initial guess

    slack0 = zeros(layout.n_slacks, N_MHE);

    %% Parameter initial guess

    par0 = zeros(layout.n_params, 1);

    for i = 1:numel(layout.paramNames)

        name = layout.paramNames{i};

        switch name

            case 'Df'
                par0(i) = double(initCfg.Df_param);

            case 'Dr'
                par0(i) = double(initCfg.Dr_param);

            case 'Dsum'
                par0(i) = double(initCfg.Dsum_param);

            case 'lambda'
                par0(i) = double(initCfg.lambda_param);

            otherwise
                error('buildInitialGuess:UnknownParameter', ...
                    'Unknown parameter "%s".', name);

        end

    end

end


function y = getMeasurementWindow(y_measurements, measurementNames, name, nSamples)

    idx = find(strcmp(measurementNames, name), 1);

    if isempty(idx)
        error('getMeasurementWindow:MissingMeasurement', ...
            'Measurement "%s" is not available in y_measurements.', name);
    end

    y = y_measurements(1:nSamples, idx);

end