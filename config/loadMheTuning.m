function tuning = loadMheTuning(jsonFile, flags)

    if ~isfile(jsonFile)
        error('loadMheTuning:FileNotFound', ...
              'Tuning file not found: %s', jsonFile);
    end

    txt = fileread(jsonFile);
    cfg = jsondecode(txt);

    caseName = chooseTuningCase(flags);

    if ~isfield(cfg.cases, caseName)
        error('loadMheTuning:MissingCase', ...
              'Tuning case "%s" is missing in %s.', caseName, jsonFile);
    end

    common = cfg.common;
    caseCfg = cfg.cases.(caseName);

    tuning = struct();

    tuning.caseName = caseName;

    %% Standard covariance matrices

    tuning.con_std = double(common.constraint_std(:));

    if flags.ay_in_state == true
        tuning.meas_std = double(common.measurement_std_with_ay(:));
    else
        tuning.meas_std = double(common.measurement_std_base(:));
    end

    if flags.split_forces == true
        tuning.force_std = double(common.force_std_split(:));
    else
        tuning.force_std = double(common.force_std_single(:));
    end

    tuning.parameter_prior_std = double(common.parameter_prior_std(:));

    %% State-defect slack std

    state_slack_std = double(caseCfg.state_slack_std(:));

    %% Extra slack std, following exactly the same order used in S

    extra_slack_std = [];
    extraSlackNames = {};

    if (flags.ay_in_cost == true) || (flags.ay_state_model_constraint == true)

        extra_slack_std = [extra_slack_std; ...
            double(common.extra_slack_std.ay_consistency)];

        extraSlackNames{end+1} = 'ay_consistency';

    end

    if flags.split_forces == true

        force_split_std = double(common.extra_slack_std.force_split(:));

        extra_slack_std = [extra_slack_std; force_split_std];

        extraSlackNames{end+1} = 'Fyf_split';
        extraSlackNames{end+1} = 'Fyr_split';

    end

    %% Final slack std

    tuning.state_slack_std = state_slack_std;
    tuning.extra_slack_std = extra_slack_std;
    tuning.slack_std = [state_slack_std; extra_slack_std];

    tuning.arrival_std = double(caseCfg.arrival_std(:));

    %% Covariances

    tuning.con_cov   = makeCov(tuning.con_std);
    tuning.meas_cov  = makeCov(tuning.meas_std);
    tuning.force_cov = makeCov(tuning.force_std);
    tuning.w_p       = makeCov(tuning.parameter_prior_std);

    tuning.slack_cov = makeCov(tuning.slack_std);
    tuning.arr_cov   = makeCov(tuning.arrival_std);

    %% Names, useful for debug

    tuning.stateNames = buildStateNames(flags);
    tuning.extraSlackNames = extraSlackNames;
    tuning.slackNames = [tuning.stateNames, tuning.extraSlackNames];

    tuning.raw = cfg;

    validateTuningDimensions(tuning, flags);

end


function C = makeCov(stdVec)

    stdVec = double(stdVec(:));
    C = diag(stdVec.^2);

end

function caseName = chooseTuningCase(flags)

    if flags.use_Dsum_lam == true && flags.DsumLam_as_params == false

        if flags.ay_in_state == true
            caseName = 'DsumLambdaStates_withAy';
        else
            caseName = 'DsumLambdaStates_noAy';
        end

    else

        if flags.ay_in_state == true && flags.D_in_states == true
            caseName = 'DStates_withAy';

        elseif flags.ay_in_state == true
            caseName = 'AyStateOnly';

        elseif flags.D_in_states == true
            caseName = 'DStates_noAy';

        else
            caseName = 'Base';
        end

    end

end


function stateNames = buildStateNames(flags)

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

end


function validateTuningDimensions(tuning, flags)

    nState = numel(tuning.stateNames);

    nExtraSlack = 0;

    if (flags.ay_in_cost == true) || (flags.ay_state_model_constraint == true)
        nExtraSlack = nExtraSlack + 1;
    end

    if flags.split_forces == true
        nExtraSlack = nExtraSlack + 2;
    end

    nSlack = nState + nExtraSlack;

    nMeas = 2;
    if flags.ay_in_state == true
        nMeas = 3;
    end

    nForce = 1;
    if flags.split_forces == true
        nForce = 2;
    end

    assertVectorLength(tuning.con_std, 2, 'constraint_std');
    assertVectorLength(tuning.meas_std, nMeas, 'measurement_std');
    assertVectorLength(tuning.force_std, nForce, 'force_std');
    assertVectorLength(tuning.parameter_prior_std, 2, 'parameter_prior_std');

    assertVectorLength(tuning.state_slack_std, nState, 'state_slack_std');
    assertVectorLength(tuning.slack_std, nSlack, 'full slack_std');
    assertVectorLength(tuning.arrival_std, nState, 'arrival_std');

end


function assertVectorLength(v, expectedLength, name)

    if numel(v) ~= expectedLength
        error('loadMheTuning:InvalidDimension', ...
              '%s has length %d, but expected length %d.', ...
              name, numel(v), expectedLength);
    end

end