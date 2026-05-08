function workspaceData = runMHEExperiment(vehicle,log)
    import casadi.*
    %% Hyper-params
    Ts     = 0.05;     % [s]
    period = 0.1;      % [s]
    N_MHE  = round(period/Ts);   % horizon length (stages)
    
    %% Config path  
    configFile = './config/mhe_tuning.json';
    
    %% Flags 
    flags = loadMheFlags(configFile);
    
    %% Vehicle params
    model = 4;
    wb   = vehicle.geometry.wheelbase;
    lf   = vehicle.geometry.lf;
    lr = vehicle.geometry.lr;
    hc = vehicle.geometry.h_G;
    mass = vehicle.physics.mass;
    g0   = vehicle.physics.g;
    Jz = vehicle.physics.Jz;
    Cl = vehicle.aerodynamics.Cl;
    rho  = vehicle.aerodynamics.rho;
    Area = vehicle.aerodynamics.S;
    aero_split = vehicle.aerodynamics.aero_split;
    
    %% Load measured data
    
    loadOpts = loadDataSegmentConfig(configFile);

    lapCfg = loadLapDetectionConfig(configFile);
    loadOpts.lap_detection = lapCfg;
    
    [logData, logMeta] = loadLogData(log, Ts, vehicle, loadOpts);
    
    t_inter = logData.t;
    
    vx_meas = logData.vx;
    vy_meas = logData.vy;
    r_meas  = logData.r;
    
    delta_meas = logData.delta;
    ax_meas    = logData.ax;
    ay_meas    = logData.ay;
    az_meas    = logData.az;
    
    Fyf_meas = logData.Fyf;
    Fyr_meas = logData.Fyr;
    
    
    slip_f = -atan((vy_meas + r_meas * lf) ./ max(vx_meas,2)) + delta_meas;
    slip_r =  atan((-vy_meas + r_meas * lr) ./ max(vx_meas,2));
    DIFF   = slip_f - slip_r;
    
    %% Measurement & input stacks
    [y_measurements, measurementNames] = buildMeasurementStack( ...
    vx_meas, ...
    r_meas, ...
    ay_meas, ...
    Fyf_meas, ...
    Fyr_meas, ...
    flags);
    
    % Inputs 
    u_cl = [delta_meas, ax_meas];

    %% Layout

    layout = buildMheLayout(flags);
    
    fprintf('\nActive states:\n');
    disp(layout.stateNames.');
    
    fprintf('Active parameters:\n');
    disp(layout.paramNames.');
    
    fprintf('Active slacks:\n');
    disp(layout.slackNames.');
    
    %% Symbols
    
    [sym, states, controls, params] = buildMheSymbols(layout);
    
    vx = sym.vx;
    vy = sym.vy;
    r  = sym.r;
    
    delta = sym.delta;
    ax    = sym.ax;
    
    if isfield(sym, 'ay')
        ay = sym.ay;
    end
    
    if isfield(sym, 'Df')
        Df_sym = sym.Df;
    end
    
    if isfield(sym, 'Dr')
        Dr_sym = sym.Dr;
    end
    
    if isfield(sym, 'Dsum')
        Dsum = sym.Dsum;
    end
    
    if isfield(sym, 'lambda')
        lam = sym.lambda;
    end
    
    n_states   = layout.n_states;
    n_controls = layout.n_controls;
    n_params   = layout.n_params;
    n_slacks   = layout.n_slacks;
    
    params_are_decision = layout.params_are_decision;

    
    %% Tuning

    tuning = loadMheTuning(configFile, flags);
    
    V            = makePrecision(tuning.meas_cov);
    W            = makePrecision(tuning.con_cov);
    F            = makePrecision(tuning.force_cov);
    slack_weight = makePrecision(tuning.slack_cov);
    arr_weight   = makePrecision(tuning.arr_cov);
    W_para       = makePrecision(tuning.w_p);
    
    fprintf('\nLoaded MHE tuning case: %s\n', tuning.caseName);


    %% Bounds & constraints

    args = struct();
    
    args.lbg = zeros(n_states * N_MHE, 1);
    args.ubg = zeros(n_states * N_MHE, 1);
    
    boundsCfg = loadMheBoundsConfig(configFile);
    
    bounds = buildMheBounds( ...
        boundsCfg, ...
        tuning.caseName, ...
        layout, ...
        N_MHE);
    
    args.lbx = [ ...
        bounds.state_lb; ...
        bounds.control_lb; ...
        bounds.slack_lb; ...
        bounds.par_lb];
    
    args.ubx = [ ...
        bounds.state_ub; ...
        bounds.control_ub; ...
        bounds.slack_ub; ...
        bounds.par_ub];
    
    %% Slack indices
    idx_defect_slack = 1:n_states; %#ok<NASGU>
    
    idx_ay_slack = find(strcmp(layout.slackNames, 'ay_consistency'));
    
    idx_force_slack = find( ...
        strcmp(layout.slackNames, 'Fyf_split') | ...
        strcmp(layout.slackNames, 'Fyr_split'));
    
   %% Tire model pieces

    MACROPARAMS_F = vehicle.tires.front.Macroparams;
    B_f = MACROPARAMS_F(1);
    C_f = MACROPARAMS_F(2);
    E_f = MACROPARAMS_F(4);
    
    MACROPARAMS_R = vehicle.tires.rear.Macroparams;
    B_r = MACROPARAMS_R(1);
    C_r = MACROPARAMS_R(2);
    E_r = MACROPARAMS_R(4);
    
   
    
    %% Helper to guard vx in slip computation
    
    vx_eff = @(vv) if_else(vv < 2.0, 2.0, vv);
    
    %% Slip angles
    
    alpha_f = delta - atan2(vy + r * lf, vx_eff(vx));
    alpha_r = -atan2(vy - r * lr, vx_eff(vx));
    
    alpha_front_and_rear = [alpha_f; alpha_r];
    
    slips = Function( ...
        'alpha', ...
        {states, controls}, ...
        {alpha_front_and_rear});
    
    %% Vertical loads

    Fz_f = ...
        lr / wb * mass * g0 ...
        + 0.5 * Cl * rho * Area * vx^2 * aero_split ...
        - mass * ax * hc / wb;
    
    Fz_r = ...
        lf / wb * mass * g0 ...
        + 0.5 * Cl * rho * Area * vx^2 * (1.0 - aero_split) ...
        + mass * ax * hc / wb;
    
    loads = Function( ...
        'Fz', ...
        {states, controls}, ...
        {[Fz_f; Fz_r]});
    
    %% Choose Df/Dr expressions depending on mode

    if flags.use_Dsum_lam 
    
        Dsum_s = sym.Dsum;
        lam_s  = sym.lambda;
    
        D_f = lam_s * Dsum_s;
        D_r = (1.0 - lam_s) * Dsum_s;
    
    else
    
        D_f = sym.Df;
        D_r = sym.Dr;
    
    end
    
    %% Lateral forces by selected tire model

    switch model
    
        case 1
            % Linear tire model
            K_f = B_f * C_f * D_f;
            K_r = B_r * C_r * D_r;
    
            Fyf = K_f * Fz_f * alpha_f;
            Fyr = K_r * Fz_r * alpha_r;
    
        case 2
            % Piecewise linear saturated tire model
            K_f = B_f * C_f * D_f;
            K_r = B_r * C_r * D_r;
    
            Fyf = if_else( ...
                alpha_f * K_f < -D_f, ...
                -D_f, ...
                if_else(alpha_f * K_f > D_f, D_f, alpha_f * K_f)) * Fz_f;
    
            Fyr = if_else( ...
                alpha_r * K_r < -D_r, ...
                -D_r, ...
                if_else(alpha_r * K_r > D_r, D_r, alpha_r * K_r)) * Fz_r;
    
        case 3
            % Pacejka-like tire model
            af = alpha_f;
            ar = alpha_r;
    
            Fyf = D_f * sin( ...
                C_f * atan2(B_f * af, 1) ...
                - E_f * ((B_f * af) - atan2(B_f * af, 1))) * Fz_f;
    
            Fyr = D_r * sin( ...
                C_r * atan2(B_r * ar, 1) ...
                - E_r * ((B_r * ar) - atan2(B_r * ar, 1))) * Fz_r;
    
        case 4
            % Sinusoidal small-angle approximation
            af = alpha_f;
            ar = alpha_r;
    
            Fyf = D_f * sin(B_f * af) * Fz_f;
            Fyr = D_r * sin(B_r * ar) * Fz_r;
    
        case 5
            % Simplified Pacejka-like model without E term
            af = alpha_f;
            ar = alpha_r;
    
            Fyf = D_f * sin(C_f * atan2(B_f * af, 1)) * Fz_f;
            Fyr = D_r * sin(C_r * atan2(B_r * ar, 1)) * Fz_r;
    
        otherwise
            error('Unknown tire model selected.');
    
    end
    
    %% Tire force and lateral acceleration functions

    Fy = [Fyf; Fyr];
    
    Fy_over_m = (Fyf * cos(delta) + Fyr) / mass;
    
    latForces = Function( ...
        'latForces', ...
        {states, controls, params}, ...
        {Fy});
    
    latacc = Function( ...
        'latacc', ...
        {states, controls, params}, ...
        {Fy_over_m});
    
    %% Continuous-time dynamics
    vx_d = ax + vy*r;
    r_d  = (Fyf*cos(delta)*lf - Fyr*lr)/Jz;
    if flags.ay_in_state && flags.ay_drives_vy 
        vy_d = -vx*r + ay;
    else
        vy_d = -vx*r + (Fyf*cos(delta) + Fyr)/mass;
    end
    
    Df_d   = 0;
    Dr_d   = 0;
    Dsum_d = 0;
    lam_d  = 0;
    
    rhs = [vx_d; vy_d; r_d];
    ay_d   = jacobian(((Fyf*cos(delta) + Fyr)/mass),[vx,vy,r])*rhs;
    
    if flags.ay_in_state 
        rhs = [rhs; ay_d];
    end
    
    if flags.use_Dsum_lam  && flags.DsumLam_as_params == false
        rhs = [rhs; Dsum_d; lam_d];
    elseif flags.D_in_states 
        rhs = [rhs; Df_d; Dr_d];
    end
    
    f = Function('f', {states, controls, params}, {rhs});
    
    %% Measurement model
    if flags.ay_in_state 
        meas_rhs = [vx; r; ay];
    else
        meas_rhs = [vx; r];
    end
    h = Function('h', {states}, {meas_rhs});
    
    %% Decision variables (multiple shooting)
    X = SX.sym('X', n_states,   N_MHE+1);
    U = SX.sym('U', n_controls, N_MHE);
    S = SX.sym('S', n_slacks,   N_MHE);
    
    %% Parameters (NOT decision variables)
    if flags.ay_in_state  || flags.ay_in_cost 
         P_meas = SX.sym('P_meas', 3, N_MHE+1);   % [vx; r; ay]
    elseif flags.split_forces 
         P_meas = SX.sym('P_meas', 4, N_MHE+1);   % [vx; r; Fyf; Fyr]
    else
         P_meas = SX.sym('P_meas', 2, N_MHE+1);   % [vx; r]
    end
    
    P_u         = SX.sym('P_u',    2, N_MHE);     % [delta; ax]
    x_prior_par = SX.sym('x_prior_par', n_states, 1);
    
    % param prior exists whenever params are decision vars
    if params_are_decision
        D_prior_par = SX.sym('D_prior_par', n_params, 1);
    end
    
    %% Objective
    obj = 0;
    g   = [];
    
    if flags.ay_in_state 
        % measurement penalties (vx, r, ay) at all nodes
        for k = 1:N_MHE+1
          st = X(:,k);
          yk = P_meas(:,k);
          obj = obj + (yk - h(st))' * V * (yk - h(st));
        end
    
        % inertial-constraint on ay vs tire-model latacc:
        for k = 1:N_MHE
          st = X(:,k);  uk = U(:,k);
          ayk = st(4);
          ayh = latacc(st, uk, params);
    
          if flags.ay_state_model_constraint 
              % commented line because ay dynamic is defined with the Jacobian 
              % obj = obj + (ayk - ayh - S(idx_ay_slack,k))' * F(1) * (ayk - ayh - S(idx_ay_slack,k)); 
          else
              obj = obj + (ayk - ayh)' * F(1) * (ayk - ayh);
          end
        end
    
    elseif flags.ay_in_state == false && flags.ay_in_cost 
        % measurement penalties (vx, r) at all nodes
        for k = 1:N_MHE+1
          st = X(:,k);
          yk = P_meas(1:2,k);
          obj = obj + (yk - h(st))' * V * (yk - h(st));
        end
    
        % lateral acceleration penalty at stages where control exists (with slack)
        for k = 1:N_MHE
          st  = X(:,k);  uk = U(:,k);
          ayk = P_meas(3,k);
          ayh = latacc(st, uk, params);
          obj = obj + (ayk - ayh - S(idx_ay_slack,k))' * F(1) * (ayk - ayh - S(idx_ay_slack,k));
        end
    
    else
        % measurement penalties (vx, r) at all nodes
        for k = 1:N_MHE+1
          st = X(:,k);
          yk = P_meas(1:2,k);
          obj = obj + (yk - h(st))' * V * (yk - h(st));
        end
    end
    
    if flags.split_forces 
        % lateral Forces penalty at stages where control exists
        for k = 1:N_MHE
          st  = X(:,k);  uk = U(:,k);
          yk  = P_meas(3:4,k);
          yh  = latForces(st, uk, params);
          obj = obj + (yk - yh - S(idx_force_slack,k))' * F * (yk - yh - S(idx_force_slack,k));
        end
    end
    
    % control tracking penalty
    for k = 1:N_MHE
      uk = U(:,k);
      um = P_u(:,k);
      obj = obj + (um - uk)' * W * (um - uk);
    end
    
    % slack penalty
    for k = 1:N_MHE
      obj = obj + S(:,k)' * slack_weight * S(:,k);
    end
    
    % arrival cost
    obj = obj + (X(:,1) - x_prior_par)' * arr_weight * (X(:,1) - x_prior_par);
    
    % parameter prior whenever params exist as decision vars
    if params_are_decision
        obj = obj + (params - D_prior_par)' * W_para * (params - D_prior_par);
    end
    
    %% Dynamics constraints (RK4)
    adjustState = @(x) [if_else(x(1) < 2.0, 2.0, x(1)); x(2:end)];
    
    for k = 1:N_MHE
      st = adjustState(X(:,k));
      uk = U(:,k);
    
      k1 = f(st, uk, params);
      k2 = f(st + Ts/2*k1, uk, params);
      k3 = f(st + Ts/2*k2, uk, params);
      k4 = f(st + Ts*k3,   uk, params);
      st_next_rk4 = st + Ts/6*(k1 + 2*k2 + 2*k3 + k4);
    
      g = [g; X(:,k+1) - st_next_rk4 - S(1:n_states,k)];
    end
    
    %% Pack NLP
    nPmeas = P_meas.size1() *(N_MHE+1);
    nPu    = P_u.size1()    * N_MHE;
    nX     = n_states       *(N_MHE+1);
    nU     = n_controls     * N_MHE;
    nS     = n_slacks       * N_MHE;
    
    % parameters vector
    p = vertcat( ...
          reshape(P_meas, nPmeas, 1), ...
          reshape(P_u,    nPu,    1), ...
          x_prior_par);
    
    % decision vars (always X,U,S; optionally params)
    OPT_variables = [ reshape(X, nX, 1);
                      reshape(U, nU, 1);
                      reshape(S, nS, 1) ];
    
    if params_are_decision
        p = vertcat( ...
          reshape(P_meas, nPmeas, 1), ...
          reshape(P_u,    nPu,    1), ...
          x_prior_par, ...
          D_prior_par);
    
        OPT_variables = [ reshape(X, nX, 1);
                          reshape(U, nU, 1);
                          reshape(S, nS, 1);
                          reshape(params, n_params, 1) ];
    end
    
    nlp_mhe = struct('f', obj, 'x', OPT_variables, 'g', g, 'p', p);

    %% Solver 
    opts = loadSolverOptions(configFile);
    solver = nlpsol('solver', 'ipopt', nlp_mhe, opts);
    
    %% Index helpers for unpacking
    idx = buildDecisionVectorIndex(layout, N_MHE);
    
    %% Storage
    T_len = size(y_measurements,1);
    if T_len <= N_MHE
        error('MHE:InvalidHorizon', ...
            'T_len = %d must be larger than N_MHE = %d.', T_len, N_MHE);
    end
    X_estimate       = zeros(T_len - N_MHE, n_states);
    U_estimate       = zeros(T_len - N_MHE, n_controls);
    S_estimate       = zeros(T_len - N_MHE, n_slacks);
    ay_estimate      = zeros(T_len - N_MHE, 1);
    par_estimate     = zeros(T_len - N_MHE, n_params);
    xprior_history   = zeros(T_len - N_MHE, n_states);
    par_sol = [];

    
    %% Initial guesses

    initCfg = loadInitialGuessConfig(configFile);
    
    [X0, U0, slack0, par0] = buildInitialGuess( ...
        initCfg, ...
        layout, ...
        measurementNames, ...
        y_measurements, ...
        u_cl, ...
        N_MHE);
    
    xprior0 = X0(1, :).';
    
    D_prior_par0 = par0;
    
    %% Build x0 vector
    
    x0_vec = [ ...
        reshape(X0', [], 1); ...
        reshape(U0', [], 1); ...
        reshape(slack0', [], 1)];
    
    if layout.params_are_decision
        x0_vec = [x0_vec; reshape(par0, [], 1)];
    end

    
    % Warm-start duals
    lam_x = [];
    lam_g = [];
    
    tic
    for k = 1:(T_len - N_MHE)
    
      % windowed parameters
      y_win = y_measurements(k:k+N_MHE, :);
      u_win = u_cl(k:k+N_MHE-1, :);
    
      % Pack parameters (measurements, reference inputs, arrival mean, param prior)
      p_vec = [ reshape(y_win', [], 1);
                reshape(u_win', [], 1);
                xprior0(:) ];
    
      if params_are_decision
          p_vec = [p_vec; D_prior_par0(:)];
      end
    
      % assemble args
      call_args = {'x0', x0_vec, ...
                   'lbx', args.lbx, 'ubx', args.ubx, ...
                   'lbg', args.lbg, 'ubg', args.ubg, ...
                   'p', p_vec};
    
      if ~isempty(lam_x)
        call_args = [call_args, {'lam_x0', lam_x, 'lam_g0', lam_g}];
      end
    
      sol = solver(call_args{:});
    
      % unpack solution
      X_sol   = reshape(full(sol.x(idx.state_start:idx.state_end))',     n_states,   N_MHE+1).';
      U_sol   = reshape(full(sol.x(idx.control_start:idx.control_end))', n_controls, N_MHE).';
      S_sol   = reshape(full(sol.x(idx.slack_start:idx.slack_end))',     n_slacks,   N_MHE).';
          
      if layout.params_are_decision
        par_sol = full(sol.x(idx.par_start:idx.par_end));
      else
        par_sol = [];
      end
    
      % store estimate at back of window
      X_estimate(k,:)     = X_sol(end,:);
      U_estimate(k,:)     = U_sol(end,:);
      S_estimate(k,:)     = S_sol(end,:);
      xprior_history(k,:) = xprior0.';
    
      if params_are_decision
          par_estimate(k,:) = par_sol.';
      end
    
      % Evaluate model-based lateral acceleration at the last node
      if n_params == 0
          pk_eval = zeros(0,1);
      else
          pk_eval = par_sol;
      end
      ay_estimate(k,:) = full(latacc(X_sol(end,:).', U_sol(end,:).', pk_eval));
    
      % Shift X, U, S forward by one
      X0 = [X_sol(2:end,:); X_sol(end,:)];
      U0 = [U_sol(2:end,:); U_sol(end,:)];
      S0 = [S_sol(2:end,:); S_sol(end,:)];
    
      % Arrival mean for next window
      xprior0 = X_sol(2,:).';
    
      % Update priors
      if params_are_decision
          D_prior_par0 = par_sol;
          par0 = par_sol;
      else
          par0 = [];
      end
    
      % Rebuild x0 vector
      x0_vec = [ reshape(X0', [], 1);
                 reshape(U0', [], 1);
                 reshape(S0', [], 1) ];
    
      if params_are_decision
          x0_vec = [x0_vec;
                    reshape(par0, [], 1)];
      end
    
      % warm-start duals
      lam_x = full(sol.lam_x);
      lam_g = full(sol.lam_g);
    end
    toc
    
    %% Save data needed for post-processing and plots
    
    plotData = struct();
    
    % Time / horizon information
    plotData.N_MHE  = N_MHE;
    plotData.T_len  = T_len;
    plotData.t_inter = t_inter;
    
    % Measurements
    plotData.vx_meas = vx_meas;
    plotData.vy_meas = vy_meas;
    plotData.r_meas  = r_meas;
    plotData.ay_meas = ay_meas;
    plotData.az_meas = az_meas;
    
    plotData.delta_meas = delta_meas;
    plotData.ax_meas    = ax_meas;
    
    plotData.y_measurements = y_measurements;
    plotData.u_cl = u_cl;
    
    % Estimates
    plotData.X_estimate  = X_estimate;
    plotData.U_estimate  = U_estimate;
    plotData.S_estimate  = S_estimate;
    plotData.par_estimate = par_estimate;
    plotData.ay_estimate  = ay_estimate;
    
    % Optional diagnostic quantities
    plotData.DIFF = DIFF;
    
    % Measured tire forces
    plotData.Fyf_meas = Fyf_meas;
    plotData.Fyr_meas = Fyr_meas;
    
    % Model / estimation flags
    plotData.ay_state_model_constraint = flags.ay_state_model_constraint;
    plotData.params_are_decision = params_are_decision;
    plotData.use_Dsum_lam = flags.use_Dsum_lam;
    plotData.DsumLam_as_params = flags.DsumLam_as_params;
    plotData.ay_in_state = flags.ay_in_state;
    plotData.D_in_states = flags.D_in_states;
    plotData.n_params = n_params;
    
    % Vehicle parameters needed for force reconstruction
    plotData.mass = mass;
    plotData.lf = lf;
    plotData.lr = lr;
    plotData.wb = wb;
    
    % Save file
    saveFolder = './resultsData';
    if ~exist(saveFolder, 'dir')
        mkdir(saveFolder);
    end

    plotData.forceData = computeForcePlotData( ...
    plotData, ...
    loads, ...
    slips, ...
    latForces);
    
    saveFile = fullfile(saveFolder, 'mhe_postprocessing_data.mat');
    save(saveFile, 'plotData', '-v7.3');
    
    fprintf('\nSaved post-processing data in:\n%s\n', saveFile);
    
    %% Plot

    plotOpts = loadPlotOptions(configFile);
    
    funcs = struct();
    funcs.loads     = loads;
    funcs.slips     = slips;
    funcs.latForces = latForces;
    
    plotMHEResults(plotOpts.dataFile, plotOpts, funcs);
    
    workspaceData = struct();

    workspaceData.mheResults.X_estimate = X_estimate;
    workspaceData.mheResults.U_estimate = U_estimate;
    workspaceData.mheResults.par_estimate = par_estimate;

    workspaceData.simConfig.Ts = Ts;
    workspaceData.simConfig.vehicle = vehicle;
end


function forceData = computeForcePlotData(D, loads, slips, latForces)
    % computeForcePlotData
    %
    % Computes all force/slip quantities needed for post-processing plots.
    %
    %
    % Inputs:
    %   D          : plotData struct
    %   loads      : CasADi function for vertical loads
    %   slips      : CasADi function for slip angles
    %   latForces  : CasADi function for lateral tire forces
    %
    % Output:
    %   forceData : struct containing numerical arrays only

    N_MHE = D.N_MHE;

    t_est = D.t_inter(N_MHE+1:end);
    N = numel(t_est);

    X_estimate = D.X_estimate;
    U_estimate = D.U_estimate;

    %% Measured data used on the MHE interval

    Fyf_meas_used = D.Fyf_meas(N_MHE+1:end);
    Fyr_meas_used = D.Fyr_meas(N_MHE+1:end);

    vx_used    = D.vx_meas(N_MHE+1:end);
    vy_used    = D.vy_meas(N_MHE+1:end);
    r_used     = D.r_meas(N_MHE+1:end);
    delta_used = D.delta_meas(N_MHE+1:end);
    ax_used    = D.ax_meas(N_MHE+1:end);

    U_used = [delta_used, ax_used];

    %% Build measured-state vector with correct dimension

    X_used = [vx_used, vy_used, r_used];

    if D.ay_in_state 
        X_used = [X_used, D.ay_meas(N_MHE+1:end)];
    end

    if D.use_Dsum_lam  && D.DsumLam_as_params == false

        if D.ay_in_state 
            X_used = [X_used, X_estimate(:,5), X_estimate(:,6)];
        else
            X_used = [X_used, X_estimate(:,4), X_estimate(:,5)];
        end

    elseif D.D_in_states 

        if D.ay_in_state 
            X_used = [X_used, X_estimate(:,5), X_estimate(:,6)];
        else
            X_used = [X_used, X_estimate(:,4), X_estimate(:,5)];
        end

    end

    %% Preallocate numerical arrays

    alpha_f_hat = zeros(N,1);
    alpha_r_hat = zeros(N,1);

    Fyf_hat = zeros(N,1);
    Fyr_hat = zeros(N,1);

    Fyf_scatter = zeros(N,1);
    Fyr_scatter = zeros(N,1);

    Fyf_scatter_ay = zeros(N,1);
    Fyr_scatter_ay = zeros(N,1);

    Fyf_used = zeros(N,1);
    Fyr_used = zeros(N,1);

    af2_meas = zeros(N,1);
    ar2_meas = zeros(N,1);

    %% Measured force/slip quantities

    for i = 1:N

        st_used = X_used(i,:).';
        uk_used = U_used(i,:).';

        Fz_meas = full(loads(st_used, uk_used));
        a_meas  = full(slips(st_used, uk_used));

        af2_meas(i) = a_meas(1);
        ar2_meas(i) = a_meas(2);

        Fyf_used(i) = Fyf_meas_used(i) ./ Fz_meas(1);
        Fyr_used(i) = Fyr_meas_used(i) ./ Fz_meas(2);

    end

    %% Estimated force/slip quantities

    for i = 1:N

        st = X_estimate(i,:).';
        uk = U_estimate(i,:).';

        if D.n_params == 0
            pk = zeros(0,1);
        else
            pk = D.par_estimate(i,:).';
        end

        a = full(slips(st, uk));

        alpha_f_hat(i) = a(1);
        alpha_r_hat(i) = a(2);

        Fz_hat_i = full(loads(st, uk));

        Fy_hat_i = full(latForces(st, uk, pk));

        Fyf_hat(i) = Fy_hat_i(1);
        Fyr_hat(i) = Fy_hat_i(2);

        Fyf_scatter(i) = Fy_hat_i(1) ./ Fz_hat_i(1);
        Fyr_scatter(i) = Fy_hat_i(2) ./ Fz_hat_i(2);

        if D.ay_in_state 

            ayt = X_estimate(i,4);
            deltat = U_estimate(i,1);

            c = cos(deltat);

            Fyf_inter = (D.mass .* ayt) .* D.lr ./ (D.wb .* c);
            Fyr_inter = (D.lf ./ D.wb) .* (D.mass .* ayt);

            Fyf_scatter_ay(i) = Fyf_inter ./ Fz_hat_i(1);
            Fyr_scatter_ay(i) = Fyr_inter ./ Fz_hat_i(2);

        end

    end

    %% Store numerical results only

    forceData.t_est = t_est;

    forceData.Fyf_meas_used = Fyf_meas_used;
    forceData.Fyr_meas_used = Fyr_meas_used;

    forceData.Fyf_hat = Fyf_hat;
    forceData.Fyr_hat = Fyr_hat;

    forceData.alpha_f_hat = alpha_f_hat;
    forceData.alpha_r_hat = alpha_r_hat;

    forceData.Fyf_scatter = Fyf_scatter;
    forceData.Fyr_scatter = Fyr_scatter;

    forceData.Fyf_scatter_ay = Fyf_scatter_ay;
    forceData.Fyr_scatter_ay = Fyr_scatter_ay;

    forceData.Fyf_used = Fyf_used;
    forceData.Fyr_used = Fyr_used;

    forceData.af2_meas = af2_meas;
    forceData.ar2_meas = ar2_meas;

    forceData.vy_err = abs(D.vy_meas(N_MHE+1:end) - X_estimate(:,2));

end

function P = makePrecision(C)

    if isdiag(C)
        P = diag(1 ./ diag(C));
    else
        P = C \ eye(size(C));
    end

end