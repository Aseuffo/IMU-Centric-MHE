function stats = plotMHEResults(matFile, opts, funcs)
% plotMHEResults
%
% Loads saved MHE results from a .mat file and generates post-processing
% plots.
%
% Usage:
%   stats = plotMHEResults('mhe_postprocessing_data.mat', opts, funcs)
%
% Required:
%   matFile : path to .mat file containing plotData
%
% Optional:
%   opts.plotSlack   = true / false
%   opts.plotForces  = true / false
%   opts.saveFigures = true / false
%   opts.saveFolder  = './resultsFigure'
%
% Optional funcs, required only if opts.plotForces == true:
%   funcs.loads
%   funcs.slips
%   funcs.latForces

    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    if nargin < 3
        funcs = struct();
    end

    opts = setDefaultOptions(opts);

    loaded = load(matFile);

    if ~isfield(loaded, 'plotData')
        error('The .mat file must contain a variable named plotData.');
    end

    D = loaded.plotData;

    %% Global style

    set(groot,'DefaultTextInterpreter','latex');
    set(groot,'DefaultColorbarTickLabelInterpreter','latex');
    set(groot,'DefaultLegendInterpreter','latex');
    set(groot,'DefaultAxesTickLabelInterpreter','latex');

    set(groot,'defaultAxesFontSize',14);
    set(groot,'DefaultLineLineWidth',1.5);
    set(groot,'DefaultFigureColor','w');

    %% Color convention

    cMeas = [0.0000 0.4470 0.7410];   % Blue
    cEst  = [0.8500 0.1500 0.1500];   % Red
    cAux  = [0.25   0.25   0.25];     % Gray

    lw = 1.5;

    lsMeas = '-';
    lsEst  = '--';

    %% Useful aliases

    N_MHE = D.N_MHE;
    t_inter = D.t_inter;
    t_est = t_inter(N_MHE+1:end);

    X_estimate = D.X_estimate;
    U_estimate = D.U_estimate;

    %% Calculate RMSE

    idx_vy  = (N_MHE+1):D.T_len;

    vx_true = D.vx_meas(idx_vy);
    vy_true = D.vy_meas(idx_vy);
    r_true  = D.r_meas(idx_vy);

    vx_est = X_estimate(:,1);
    vy_est = X_estimate(:,2);
    r_est  = X_estimate(:,3);

    stats.rmse_vx = sqrt(mean((vx_true - vx_est).^2, 'omitnan'));
    stats.rmse_vy = sqrt(mean((vy_true - vy_est).^2, 'omitnan'));
    stats.rmse_r  = sqrt(mean((r_true  - r_est ).^2, 'omitnan'));

    fprintf('\n------------------------------------------\n');
    fprintf('RMSE of longitudinal velocity (vx): %.6f m/s\n', stats.rmse_vx);
    fprintf('RMSE of lateral velocity (vy):      %.6f m/s\n', stats.rmse_vy);
    fprintf('RMSE of yaw rate (r):               %.6f rad/s\n', stats.rmse_r);
    fprintf('------------------------------------------\n');

    %% FIG 1: a_y and v_y

    f1 = figure('Name','Lateral Acceleration and Velocity Measured vs Estimated', ...
                'NumberTitle','off');

    tiledlayout(f1,2,1,'TileSpacing','compact','Padding','compact');

    ax1 = nexttile;
    hold(ax1,'on');

    plot(ax1, t_inter, D.ay_meas, lsMeas, ...
        'Color', cMeas, ...
        'LineWidth', lw, ...
        'DisplayName', 'Measured $a_y$');

    plot(ax1, t_est, D.ay_estimate, lsEst, ...
        'Color', cEst, ...
        'LineWidth', lw, ...
        'DisplayName', 'Model $a_y$');

    if D.ay_state_model_constraint == true && size(X_estimate,2) >= 4
        plot(ax1, t_est, X_estimate(:,4), ':', ...
            'Color', cAux, ...
            'LineWidth', lw, ...
            'DisplayName', 'State $a_y$');
    end

    title(ax1,'Lateral Acceleration ($a_y$)');
    xlabel(ax1,'Time [s]');
    ylabel(ax1,'Acceleration $[m/s^2]$');
    legend(ax1,'Location','best','Box','off');
    applyPaperAxis(ax1);

    ax2 = nexttile;
    hold(ax2,'on');

    plot(ax2, t_inter, D.vy_meas, lsMeas, ...
        'Color', cMeas, ...
        'LineWidth', lw, ...
        'DisplayName', 'Measured $v_y$');

    plot(ax2, t_est, X_estimate(:,2), lsEst, ...
        'Color', cEst, ...
        'LineWidth', lw, ...
        'DisplayName', 'Estimated $v_y$');

    title(ax2,'Lateral Velocity ($v_y$)');
    xlabel(ax2,'Time [s]');
    ylabel(ax2,'Velocity $[m/s]$');
    legend(ax2,'Location','best','Box','off');
    applyPaperAxis(ax2);

    linkaxes([ax1 ax2],'x');

    %% FIG 2: Errors

    f2 = figure('Name','Estimation Errors', 'NumberTitle','off');
    tiledlayout(f2,3,1,'TileSpacing','compact','Padding','compact');

    ax1 = nexttile;
    hold(ax1,'on');

    plot(ax1, t_inter, D.az_meas - 9.81, '-', ...
        'Color', cAux, ...
        'LineWidth', lw, ...
        'DisplayName', '$a_z - g$');

    title(ax1,'Vertical Acceleration Bias ($a_z - g$)');
    xlabel(ax1,'Time [s]');
    ylabel(ax1,'Acceleration $[m/s^2]$');
    legend(ax1,'Location','best','Box','off');
    applyPaperAxis(ax1);

    ax2 = nexttile;
    hold(ax2,'on');

    plot(ax2, t_est, D.ay_meas(N_MHE+1:end) - D.ay_estimate, '-', ...
        'Color', cAux, ...
        'LineWidth', lw, ...
        'DisplayName', '$a_y^{meas} - a_y^{model}$');

    title(ax2,'Lateral Acceleration Error');
    xlabel(ax2,'Time [s]');
    ylabel(ax2,'Acceleration $[m/s^2]$');
    legend(ax2,'Location','best','Box','off');
    applyPaperAxis(ax2);

    ax3 = nexttile;
    hold(ax3,'on');

    plot(ax3, t_est, D.vy_meas(N_MHE+1:end) - X_estimate(:,2), '-', ...
        'Color', cAux, ...
        'LineWidth', lw, ...
        'DisplayName', '$v_y^{meas} - v_y^{est}$');

    title(ax3,'Lateral Velocity Error');
    xlabel(ax3,'Time [s]');
    ylabel(ax3,'Velocity $[m/s]$');
    legend(ax3,'Location','best','Box','off');
    applyPaperAxis(ax3);

    linkaxes([ax1 ax2 ax3],'x');

    %% FIG 3: States

    f3 = figure('Name','States Measured vs Estimated', 'NumberTitle','off');
    tiledlayout(f3,3,1,'TileSpacing','compact','Padding','compact');

    ax1 = nexttile;
    hold(ax1,'on');

    plot(ax1, t_inter, D.y_measurements(:,1), lsMeas, ...
        'Color', cMeas, ...
        'LineWidth', lw, ...
        'DisplayName', 'Measured $v_x$');

    plot(ax1, t_est, X_estimate(:,1), lsEst, ...
        'Color', cEst, ...
        'LineWidth', lw, ...
        'DisplayName', 'Estimated $v_x$');

    title(ax1,'Longitudinal Velocity ($v_x$)');
    xlabel(ax1,'Time [s]');
    ylabel(ax1,'Velocity $[m/s]$');
    legend(ax1,'Location','best','Box','off');
    applyPaperAxis(ax1);

    ax2 = nexttile;
    hold(ax2,'on');

    plot(ax2, t_inter, D.y_measurements(:,2), lsMeas, ...
        'Color', cMeas, ...
        'LineWidth', lw, ...
        'DisplayName', 'Measured $r$');

    plot(ax2, t_est, X_estimate(:,3), lsEst, ...
        'Color', cEst, ...
        'LineWidth', lw, ...
        'DisplayName', 'Estimated $r$');

    title(ax2,'Yaw Rate ($r$)');
    xlabel(ax2,'Time [s]');
    ylabel(ax2,'Yaw Rate $[rad/s]$');
    legend(ax2,'Location','best','Box','off');
    applyPaperAxis(ax2);

    ax3 = nexttile;
    hold(ax3,'on');

    plot(ax3, t_inter, D.vy_meas, lsMeas, ...
        'Color', cMeas, ...
        'LineWidth', lw, ...
        'DisplayName', 'Measured $v_y$');

    plot(ax3, t_est, X_estimate(:,2), lsEst, ...
        'Color', cEst, ...
        'LineWidth', lw, ...
        'DisplayName', 'Estimated $v_y$');

    title(ax3,'Lateral Velocity ($v_y$)');
    xlabel(ax3,'Time [s]');
    ylabel(ax3,'Velocity $[m/s]$');
    legend(ax3,'Location','best','Box','off');
    applyPaperAxis(ax3);

    linkaxes([ax1 ax2 ax3],'x');

    %% FIG 4: v_y and slip-angle difference

    if isfield(D,'DIFF') && ~isempty(D.DIFF)

        figure('Name','vy and Slip Angle Difference','NumberTitle','off');
        hold on;

        plot(t_inter, D.vy_meas, lsMeas, ...
            'Color', cMeas, ...
            'LineWidth', lw, ...
            'DisplayName', 'Measured $v_y$');

        plot(t_est, X_estimate(:,2), lsEst, ...
            'Color', cEst, ...
            'LineWidth', lw, ...
            'DisplayName', 'Estimated $v_y$');

        plot(t_inter, D.DIFF(:,1), '-', ...
            'Color', cAux, ...
            'LineWidth', lw, ...
            'DisplayName', '$\alpha_f - \alpha_r$');

        title('Lateral Velocity and Slip Angle Difference');
        xlabel('Time [s]');
        ylabel('Value');
        legend('Location','best','Box','off');
        applyPaperAxis(gca);

    end

    %% FIG 5: Inputs

    f5 = figure('Name','Inputs Measured vs Estimated','NumberTitle','off');
    tiledlayout(f5,2,1,'TileSpacing','compact','Padding','compact');

    ax1 = nexttile;
    hold(ax1,'on');

    plot(ax1, t_inter, rad2deg(D.u_cl(:,1)), lsMeas, ...
        'Color', cMeas, ...
        'LineWidth', lw, ...
        'DisplayName', 'Measured $\delta$');

    plot(ax1, t_est, rad2deg(U_estimate(:,1)), lsEst, ...
        'Color', cEst, ...
        'LineWidth', lw, ...
        'DisplayName', 'Estimated $\delta$');

    title(ax1,'Steering Angle ($\delta$)');
    xlabel(ax1,'Time [s]');
    ylabel(ax1,'Angle $[deg]$');
    legend(ax1,'Location','best','Box','off');
    applyPaperAxis(ax1);

    ax2 = nexttile;
    hold(ax2,'on');

    plot(ax2, t_inter, D.u_cl(:,2), lsMeas, ...
        'Color', cMeas, ...
        'LineWidth', lw, ...
        'DisplayName', 'Measured $a_x$');

    plot(ax2, t_est, U_estimate(:,2), lsEst, ...
        'Color', cEst, ...
        'LineWidth', lw, ...
        'DisplayName', 'Estimated $a_x$');

    title(ax2,'Longitudinal Acceleration ($a_x$)');
    xlabel(ax2,'Time [s]');
    ylabel(ax2,'Acceleration $[m/s^2]$');
    legend(ax2,'Location','best','Box','off');
    applyPaperAxis(ax2);

    linkaxes([ax1 ax2],'x');

    %% Tire parameters

    plotTireParameters(D, t_est, cEst, cAux, lw);

    %% Lateral acceleration standalone

    figure('Name','Lateral Acceleration ay Measured vs Model','NumberTitle','off');
    hold on;

    plot(t_inter, D.ay_meas, lsMeas, ...
        'Color', cMeas, ...
        'LineWidth', lw, ...
        'DisplayName', 'Measured $a_y$');

    plot(t_est, D.ay_estimate, lsEst, ...
        'Color', cEst, ...
        'LineWidth', lw, ...
        'DisplayName', 'Model $a_y$');

    title('Lateral Acceleration ($a_y$)');
    xlabel('Time [s]');
    ylabel('Acceleration $[m/s^2]$');
    legend('Location','best','Box','off');
    applyPaperAxis(gca);

    %% Optional slack plots

    if opts.plotSlack == true
        plotSlackFigures(D, t_est, cAux, lw);
    end

    %% Optional force plots

    if opts.plotForces == true

        if isfield(D, 'forceData') && ~isempty(D.forceData)
    
            plotForceFiguresFromSavedData( ...
                D, ...
                t_est, ...
                cMeas, ...
                cEst, ...
                lw, ...
                lsMeas, ...
                lsEst);
    
        else
    
            error(['opts.plotForces is true, but plotData.forceData is missing. ', ...
                   'Compute forceData in the main script before saving the .mat file.']);
    
        end

   end

    %% Optional figure saving

    if opts.saveFigures == true
        saveAllFigures(opts.saveFolder);
    end

end


function opts = setDefaultOptions(opts)

    if ~isfield(opts,'plotSlack')
        opts.plotSlack = false;
    end

    if ~isfield(opts,'plotForces')
        opts.plotForces = false;
    end

    if ~isfield(opts,'saveFigures')
        opts.saveFigures = false;
    end

    if ~isfield(opts,'saveFolder')
        opts.saveFolder = './resultsFigure';
    end

end

function applyPaperAxis(ax)

    if nargin == 0 || isempty(ax)
        ax = gca;
    end

    set(ax, ...
        'Box','on', ...
        'LineWidth',0.8, ...
        'TickDir','out', ...
        'XMinorTick','on', ...
        'YMinorTick','on');

    set(ax, ...
        'XGrid','on', ...
        'YGrid','on', ...
        'GridAlpha',0.15, ...
        'MinorGridAlpha',0.08);

end

function plotDfDrStacked(t, Df, Dr, figName, cEst, lw)

    f = figure('Name',figName,'NumberTitle','off');
    tiledlayout(f,2,1,'TileSpacing','compact','Padding','compact');

    ax1 = nexttile;
    hold(ax1,'on');

    plot(ax1, t, Df, '-', ...
        'Color', cEst, ...
        'LineWidth', lw);

    title(ax1,'Estimated $D_f$');
    ylabel(ax1,'Value');
    applyPaperAxis(ax1);

    ax2 = nexttile;
    hold(ax2,'on');

    plot(ax2, t, Dr, '-', ...
        'Color', cEst, ...
        'LineWidth', lw);

    title(ax2,'Estimated $D_r$');
    xlabel(ax2,'Time [s]');
    ylabel(ax2,'Value');
    applyPaperAxis(ax2);

    linkaxes([ax1 ax2],'x');

end

function plotTireParameters(D, t_est, cEst, cAux, lw)

    X_estimate = D.X_estimate;
    par_estimate = D.par_estimate;

    if D.params_are_decision && D.use_Dsum_lam == false

        Df_hat = par_estimate(:,1);
        Dr_hat = par_estimate(:,2);

        plotDfDrStacked( ...
            t_est, ...
            Df_hat, ...
            Dr_hat, ...
            'Tire Parameters Df Dr', ...
            cEst, ...
            lw);

    elseif D.use_Dsum_lam == true && D.DsumLam_as_params == true

        Dsum_hat = par_estimate(:,1);
        lam_hat  = par_estimate(:,2);

        Df_hat = lam_hat .* Dsum_hat;
        Dr_hat = (1 - lam_hat) .* Dsum_hat;

        plotDfDrStacked( ...
            t_est, ...
            Df_hat, ...
            Dr_hat, ...
            'Tire Parameters Df Dr from Dsum lambda params', ...
            cEst, ...
            lw);

        plotDsumLambda(t_est, Dsum_hat, lam_hat, ...
            'Decision Params Dsum lambda', cAux, lw);

    elseif D.use_Dsum_lam == true && D.DsumLam_as_params == false

        if D.ay_in_state == true
            Dsum_hat = X_estimate(:,5);
            lam_hat  = X_estimate(:,6);
        else
            Dsum_hat = X_estimate(:,4);
            lam_hat  = X_estimate(:,5);
        end

        Df_hat = lam_hat .* Dsum_hat;
        Dr_hat = (1 - lam_hat) .* Dsum_hat;

        plotDfDrStacked( ...
            t_est, ...
            Df_hat, ...
            Dr_hat, ...
            'Tire Parameters Df Dr from Dsum lambda states', ...
            cEst, ...
            lw);

        plotDsumLambda(t_est, Dsum_hat, lam_hat, ...
            'States Dsum lambda', cAux, lw);

    elseif D.D_in_states == true

        if D.ay_in_state == true
            idx_Df = 5;
            idx_Dr = 6;
        else
            idx_Df = 4;
            idx_Dr = 5;
        end

        Df_hat = X_estimate(:,idx_Df);
        Dr_hat = X_estimate(:,idx_Dr);

        plotDfDrStacked( ...
            t_est, ...
            Df_hat, ...
            Dr_hat, ...
            'Tire Parameters Df Dr in State', ...
            cEst, ...
            lw);
    end

end


function plotDsumLambda(t_est, Dsum_hat, lam_hat, figName, cAux, lw)

    f = figure('Name',figName,'NumberTitle','off');
    tiledlayout(f,2,1,'TileSpacing','compact','Padding','compact');

    ax1 = nexttile;
    hold(ax1,'on');

    plot(ax1, t_est, Dsum_hat, '-', ...
        'Color', cAux, ...
        'LineWidth', lw, ...
        'DisplayName', '$D_{sum}$');

    title(ax1,'$D_{sum}$');
    xlabel(ax1,'Time [s]');
    ylabel(ax1,'Value');
    legend(ax1,'Location','best','Box','off');
    applyPaperAxis(ax1);

    ax2 = nexttile;
    hold(ax2,'on');

    plot(ax2, t_est, lam_hat, '-', ...
        'Color', cAux, ...
        'LineWidth', lw, ...
        'DisplayName', '$\lambda$');

    title(ax2,'$\lambda$');
    xlabel(ax2,'Time [s]');
    ylabel(ax2,'Value');
    legend(ax2,'Location','best','Box','off');
    applyPaperAxis(ax2);

    linkaxes([ax1 ax2],'x');

end

function plotSlackFigures(D, t_est, cAux, lw)

    if ~isfield(D,'S_estimate') || isempty(D.S_estimate)
        warning('opts.plotSlack is true, but S_estimate is missing or empty.');
        return;
    end

    S_estimate = D.S_estimate;

    slackNames = {'v_x', 'v_y', 'r'};

    nSlack = min(size(S_estimate,2), numel(slackNames));

    for k = 1:nSlack

        figure('Name',['Defect Slack ', slackNames{k}], ...
               'NumberTitle','off');

        hold on;

        plot(t_est, S_estimate(:,k), '-', ...
            'Color', cAux, ...
            'LineWidth', lw, ...
            'DisplayName', ['$\mathrm{Slack}\ ', slackNames{k}, '$']);

        title(['Defect Slack on $', slackNames{k}, '$']);
        xlabel('Time [s]');
        ylabel('Slack');
        legend('Location','best','Box','off');
        applyPaperAxis(gca);

    end

end


function plotForceFiguresFromSavedData(D, t_est, cMeas, cEst, lw, lsMeas, lsEst)

    FD = D.forceData;

    %% Scatter: Front tire

    figure('Name','Front Tire Force Scatter Measured vs Estimated', ...
           'NumberTitle','off');

    hold on;

    scatter(FD.alpha_f_hat, FD.Fyf_scatter, 18, cEst, ...
        'filled', ...
        'DisplayName','Estimated');

    scatter(FD.af2_meas, FD.Fyf_used, 18, cMeas, ...
        'filled', ...
        'DisplayName','Measured');

    xlabel('$\alpha_f$ [rad]');
    ylabel('$F_{yf}/F_{z,f}$ [-]');
    title('Front normalized lateral force vs slip angle');
    legend('Location','best','Box','off');
    applyPaperAxis(gca);

    %% Scatter: Rear tire

    figure('Name','Rear Tire Force Scatter Measured vs Estimated', ...
           'NumberTitle','off');

    hold on;

    scatter(FD.alpha_r_hat, FD.Fyr_scatter, 18, cEst, ...
        'filled', ...
        'DisplayName','Estimated');

    scatter(FD.ar2_meas, FD.Fyr_used, 18, cMeas, ...
        'filled', ...
        'DisplayName','Measured');

    xlabel('$\alpha_r$ [rad]');
    ylabel('$F_{yr}/F_{z,r}$ [-]');
    title('Rear normalized lateral force vs slip angle');
    legend('Location','best','Box','off');
    applyPaperAxis(gca);

    %% Time series lateral forces

    fF = figure('Name','Lateral Forces Measured vs Estimated', ...
                'NumberTitle','off');

    tiledlayout(fF,2,1,'TileSpacing','compact','Padding','compact');

    ax1 = nexttile;
    hold(ax1,'on');

    plot(ax1, t_est, FD.Fyf_meas_used, lsMeas, ...
        'Color', cMeas, ...
        'LineWidth', lw, ...
        'DisplayName','Measured $F_{yf}$');

    plot(ax1, t_est, FD.Fyf_hat, lsEst, ...
        'Color', cEst, ...
        'LineWidth', lw, ...
        'DisplayName','Estimated $F_{yf}$');

    title(ax1,'Front lateral force');
    xlabel(ax1,'Time [s]');
    ylabel(ax1,'Force [N]');
    legend(ax1,'Location','best','Box','off');
    applyPaperAxis(ax1);

    ax2 = nexttile;
    hold(ax2,'on');

    plot(ax2, t_est, FD.Fyr_meas_used, lsMeas, ...
        'Color', cMeas, ...
        'LineWidth', lw, ...
        'DisplayName','Measured $F_{yr}$');

    plot(ax2, t_est, FD.Fyr_hat, lsEst, ...
        'Color', cEst, ...
        'LineWidth', lw, ...
        'DisplayName','Estimated $F_{yr}$');

    title(ax2,'Rear lateral force');
    xlabel(ax2,'Time [s]');
    ylabel(ax2,'Force [N]');
    legend(ax2,'Location','best','Box','off');
    applyPaperAxis(ax2);

    linkaxes([ax1 ax2],'x');

    %% Extra plots if ay is in the state

    if isfield(D, 'ay_in_state') && D.ay_in_state == true

        figure('Name','Front Tire Force Scatter from ay State', ...
               'NumberTitle','off');

        hold on;

        scatter(FD.af2_meas, FD.Fyf_used, 22, 'o', ...
            'MarkerEdgeColor', cMeas, ...
            'MarkerFaceColor','none', ...
            'LineWidth',1.1, ...
            'DisplayName','Measured');

        scatter(FD.alpha_f_hat, FD.Fyf_scatter_ay, 22, 'o', ...
            'MarkerEdgeColor', cEst, ...
            'MarkerFaceColor',cEst, ...
            'LineWidth',0.8, ...
            'DisplayName','Estimated from $a_y$ state');

        xlabel('$\alpha_f$ [rad]');
        ylabel('$F_{yf}/F_{z,f}$ [-]');
        title('Front normalized lateral force vs slip angle');
        legend('Location','best','Box','off');
        applyPaperAxis(gca);

        figure('Name','Rear Tire Force Scatter from ay State', ...
               'NumberTitle','off');

        hold on;

        scatter(FD.ar2_meas, FD.Fyr_used, 22, 'o', ...
            'MarkerEdgeColor', cMeas, ...
            'MarkerFaceColor','none', ...
            'LineWidth',1.1, ...
            'DisplayName','Measured');

        scatter(FD.alpha_r_hat, FD.Fyr_scatter_ay, 22, 'o', ...
            'MarkerEdgeColor', cEst, ...
            'MarkerFaceColor',cEst, ...
            'LineWidth',0.8, ...
            'DisplayName','Estimated from $a_y$ state');

        xlabel('$\alpha_r$ [rad]');
        ylabel('$F_{yr}/F_{z,r}$ [-]');
        title('Rear normalized lateral force vs slip angle');
        legend('Location','best','Box','off');
        applyPaperAxis(gca);

        %% Colored by vy error

        if isfield(FD, 'vy_err')

            vy_err = FD.vy_err;

        else

            vy_err = abs(D.vy_meas(D.N_MHE+1:end) - D.X_estimate(:,2));

        end

        figure('Name','Front Tire Force Scatter Colored by vy Error', ...
               'NumberTitle','off');

        hold on;

        scatter(FD.af2_meas, FD.Fyf_used, 14, 'o', ...
            'MarkerEdgeColor', cMeas, ...
            'MarkerFaceColor','none', ...
            'LineWidth',1.0, ...
            'DisplayName','Measured');

        scatter(FD.alpha_f_hat, FD.Fyf_scatter_ay, 14, vy_err, ...
            'filled', ...
            'DisplayName','Estimated');

        xlabel('$\alpha_f$ [rad]');
        ylabel('$F_{yf}/F_{z,f}$ [-]');
        title('Front normalized lateral force vs slip angle');

        cb = colorbar;
        cb.Label.String = '$|v_y^{meas} - v_y^{est}|$ $[m/s]$';
        cb.Label.Interpreter = 'latex';

        colormap(gca,'turbo');
        clim(prctile(vy_err,[2 98]));

        legend('Location','best','Box','off');
        applyPaperAxis(gca);

        figure('Name','Rear Tire Force Scatter Colored by vy Error', ...
               'NumberTitle','off');

        hold on;

        scatter(FD.ar2_meas, FD.Fyr_used, 14, 'o', ...
            'MarkerEdgeColor', cMeas, ...
            'MarkerFaceColor','none', ...
            'LineWidth',1.0, ...
            'DisplayName','Measured');

        scatter(FD.alpha_r_hat, FD.Fyr_scatter_ay, 14, vy_err, ...
            'filled', ...
            'DisplayName','Estimated');

        xlabel('$\alpha_r$ [rad]');
        ylabel('$F_{yr}/F_{z,r}$ [-]');
        title('Rear normalized lateral force vs slip angle');

        cb = colorbar;
        cb.Label.String = '$|v_y^{meas} - v_y^{est}|$ $[m/s]$';
        cb.Label.Interpreter = 'latex';

        colormap(gca,'turbo');
        clim(prctile(vy_err,[2 98]));

        legend('Location','best','Box','off');
        applyPaperAxis(gca);

    end

end

function plotForceFigures(D, funcs, t_est, cMeas, cEst, lw, lsMeas, lsEst)

    requiredFuncs = {'loads','slips','latForces'};

    for k = 1:numel(requiredFuncs)
        if ~isfield(funcs, requiredFuncs{k})
            error('opts.plotForces is true, but funcs.%s is missing.', requiredFuncs{k});
        end
    end

    loads     = funcs.loads;
    slips     = funcs.slips;
    latForces = funcs.latForces;

    N_MHE = D.N_MHE;
    X_estimate = D.X_estimate;
    U_estimate = D.U_estimate;

    N = numel(t_est);

    Fyf_meas_used = D.Fyf_meas(N_MHE+1:end);
    Fyr_meas_used = D.Fyr_meas(N_MHE+1:end);

    vx_used    = D.vx_meas(N_MHE+1:end);
    vy_used    = D.vy_meas(N_MHE+1:end);
    r_used     = D.r_meas(N_MHE+1:end);
    delta_used = D.delta_meas(N_MHE+1:end);
    ax_used    = D.ax_meas(N_MHE+1:end);

    U_used = [delta_used, ax_used];

    X_used = [vx_used, vy_used, r_used];

    if D.ay_in_state == true
        X_used = [X_used, D.ay_meas(N_MHE+1:end)];
    end

    if D.use_Dsum_lam == true && D.DsumLam_as_params == false

        if D.ay_in_state == true
            X_used = [X_used, X_estimate(:,5), X_estimate(:,6)];
        else
            X_used = [X_used, X_estimate(:,4), X_estimate(:,5)];
        end

    elseif D.D_in_states == true

        if D.ay_in_state == true
            X_used = [X_used, X_estimate(:,5), X_estimate(:,6)];
        else
            X_used = [X_used, X_estimate(:,4), X_estimate(:,5)];
        end

    end

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

        if D.ay_in_state == true

            ayt = X_estimate(i,4);
            deltat = U_estimate(i,1);
            c = cos(deltat);

            Fyf_inter = (D.mass .* ayt) .* D.lr ./ (D.wb .* c);
            Fyr_inter = (D.lf ./ D.wb) .* (D.mass .* ayt);

            Fyf_scatter_ay(i) = Fyf_inter ./ Fz_hat_i(1);
            Fyr_scatter_ay(i) = Fyr_inter ./ Fz_hat_i(2);

        end

        Fy_hat_i = full(latForces(st, uk, pk));

        Fyf_hat(i) = Fy_hat_i(1);
        Fyr_hat(i) = Fy_hat_i(2);

        Fyf_scatter(i) = Fy_hat_i(1) ./ Fz_hat_i(1);
        Fyr_scatter(i) = Fy_hat_i(2) ./ Fz_hat_i(2);

    end

    %% Scatter force plots

    figure('Name','Front Tire Force Scatter Measured vs Estimated','NumberTitle','off');
    hold on;

    scatter(alpha_f_hat, Fyf_scatter, 18, cEst, ...
        'filled', ...
        'DisplayName', 'Estimated');

    scatter(af2_meas, Fyf_used, 18, cMeas, ...
        'filled', ...
        'DisplayName', 'Measured');

    xlabel('$\alpha_f$ [rad]');
    ylabel('$F_{yf}/F_{z,f}$ [-]');
    title('Front normalized lateral force vs slip angle');
    legend('Location','best','Box','off');
    applyPaperAxis(gca);

    figure('Name','Rear Tire Force Scatter Measured vs Estimated','NumberTitle','off');
    hold on;

    scatter(alpha_r_hat, Fyr_scatter, 18, cEst, ...
        'filled', ...
        'DisplayName', 'Estimated');

    scatter(ar2_meas, Fyr_used, 18, cMeas, ...
        'filled', ...
        'DisplayName', 'Measured');

    xlabel('$\alpha_r$ [rad]');
    ylabel('$F_{yr}/F_{z,r}$ [-]');
    title('Rear normalized lateral force vs slip angle');
    legend('Location','best','Box','off');
    applyPaperAxis(gca);

    %% Time series lateral forces

    fF = figure('Name','Lateral Forces Measured vs Estimated','NumberTitle','off');
    tiledlayout(fF,2,1,'TileSpacing','compact','Padding','compact');

    ax1 = nexttile;
    hold(ax1,'on');

    plot(ax1, t_est, Fyf_meas_used, lsMeas, ...
        'Color', cMeas, ...
        'LineWidth', lw, ...
        'DisplayName', 'Measured $F_{yf}$');

    plot(ax1, t_est, Fyf_hat, lsEst, ...
        'Color', cEst, ...
        'LineWidth', lw, ...
        'DisplayName', 'Estimated $F_{yf}$');

    title(ax1,'Front lateral force');
    xlabel(ax1,'Time [s]');
    ylabel(ax1,'Force [N]');
    legend(ax1,'Location','best','Box','off');
    applyPaperAxis(ax1);

    ax2 = nexttile;
    hold(ax2,'on');

    plot(ax2, t_est, Fyr_meas_used, lsMeas, ...
        'Color', cMeas, ...
        'LineWidth', lw, ...
        'DisplayName', 'Measured $F_{yr}$');

    plot(ax2, t_est, Fyr_hat, lsEst, ...
        'Color', cEst, ...
        'LineWidth', lw, ...
        'DisplayName', 'Estimated $F_{yr}$');

    title(ax2,'Rear lateral force');
    xlabel(ax2,'Time [s]');
    ylabel(ax2,'Force [N]');
    legend(ax2,'Location','best','Box','off');
    applyPaperAxis(ax2);

    linkaxes([ax1 ax2],'x');

    %% Extra plots if ay is in the state

    if D.ay_in_state == true

        figure('Name','Front Tire Force Scatter from ay State','NumberTitle','off');
        hold on;

        scatter(af2_meas, Fyf_used, 22, 'o', ...
            'MarkerEdgeColor', cMeas, ...
            'MarkerFaceColor', 'none', ...
            'LineWidth', 1.1, ...
            'DisplayName', 'Measured');

        scatter(alpha_f_hat, Fyf_scatter_ay, 22, 'o', ...
            'MarkerEdgeColor', cEst, ...
            'MarkerFaceColor', cEst, ...
            'LineWidth', 0.8, ...
            'DisplayName', 'Estimated');

        xlabel('$\alpha_f$ [rad]');
        ylabel('$F_{yf}/F_{z,f}$ [-]');
        title('Front normalized lateral force vs slip angle');
        legend('Location','best','Box','off');
        applyPaperAxis(gca);

        figure('Name','Rear Tire Force Scatter from ay State','NumberTitle','off');
        hold on;

        scatter(ar2_meas, Fyr_used, 22, 'o', ...
            'MarkerEdgeColor', cMeas, ...
            'MarkerFaceColor', 'none', ...
            'LineWidth', 1.1, ...
            'DisplayName', 'Measured');

        scatter(alpha_r_hat, Fyr_scatter_ay, 22, 'o', ...
            'MarkerEdgeColor', cEst, ...
            'MarkerFaceColor', cEst, ...
            'LineWidth', 0.8, ...
            'DisplayName', 'Estimated');

        xlabel('$\alpha_r$ [rad]');
        ylabel('$F_{yr}/F_{z,r}$ [-]');
        title('Rear normalized lateral force vs slip angle');
        legend('Location','best','Box','off');
        applyPaperAxis(gca);

        vy_err = abs(D.vy_meas(N_MHE+1:end) - X_estimate(:,2));

        figure('Name','Front Tire Force Scatter Colored by vy Error','NumberTitle','off');
        hold on;

        scatter(af2_meas, Fyf_used, 14, 'o', ...
            'MarkerEdgeColor', cMeas, ...
            'MarkerFaceColor', 'none', ...
            'LineWidth', 1.0, ...
            'DisplayName', 'Measured');

        scatter(alpha_f_hat, Fyf_scatter_ay, 14, vy_err, ...
            'filled', ...
            'DisplayName', 'Estimated');

        xlabel('$\alpha_f$ [rad]');
        ylabel('$F_{yf}/F_{z,f}$ [-]');
        title('Front normalized lateral force vs slip angle');
        legend('Location','best','Box','off');

        cb = colorbar;
        cb.Label.String = '$|v_y^{meas} - v_y^{est}|$ $[m/s]$';
        cb.Label.Interpreter = 'latex';

        colormap(gca,'turbo');
        clim(prctile(vy_err,[2 98]));

        applyPaperAxis(gca);

        figure('Name','Rear Tire Force Scatter Colored by vy Error','NumberTitle','off');
        hold on;

        scatter(ar2_meas, Fyr_used, 14, 'o', ...
            'MarkerEdgeColor', cMeas, ...
            'MarkerFaceColor', 'none', ...
            'LineWidth', 1.0, ...
            'DisplayName', 'Measured');

        scatter(alpha_r_hat, Fyr_scatter_ay, 14, vy_err, ...
            'filled', ...
            'DisplayName', 'Estimated');

        xlabel('$\alpha_r$ [rad]');
        ylabel('$F_{yr}/F_{z,r}$ [-]');
        title('Rear normalized lateral force vs slip angle');
        legend('Location','best','Box','off');

        cb = colorbar;
        cb.Label.String = '$|v_y^{meas} - v_y^{est}|$ $[m/s]$';
        cb.Label.Interpreter = 'latex';

        colormap(gca,'turbo');
        clim(prctile(vy_err,[2 98]));

        applyPaperAxis(gca);

    end

end

function saveAllFigures(saveFolder)

    if ~exist(saveFolder, 'dir')
        mkdir(saveFolder);
    end

    figHandles = findobj('Type', 'figure');

    for i = 1:length(figHandles)

        fig = figHandles(i);
        figName = get(fig, 'Name');

        if isempty(figName)
            figName = ['Figure_' num2str(i)];
        end

        figName = sanitizeFileName(figName);

        saveas(fig, fullfile(saveFolder, [figName '.fig']));
        exportgraphics(fig, fullfile(saveFolder, [figName '.png']), ...
            'Resolution', 300);

    end

    fprintf('\nSaved figures in:\n%s\n', saveFolder);

end

function cleanName = sanitizeFileName(name)

    cleanName = char(name);

    cleanName = strrep(cleanName, ' ', '_');
    cleanName = strrep(cleanName, '/', '_');
    cleanName = strrep(cleanName, '\', '_');
    cleanName = strrep(cleanName, '$', '');
    cleanName = strrep(cleanName, '{', '');
    cleanName = strrep(cleanName, '}', '');
    cleanName = strrep(cleanName, '^', '');
    cleanName = strrep(cleanName, ',', '');
    cleanName = strrep(cleanName, ':', '');
    cleanName = strrep(cleanName, '(', '');
    cleanName = strrep(cleanName, ')', '');

end