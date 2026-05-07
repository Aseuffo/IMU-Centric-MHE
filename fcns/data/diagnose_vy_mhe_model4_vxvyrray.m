function out = diagnose_vy_mhe_model4_vxvyrray(log, filter, Ts, X_estimate, U_estimate, N_MHE, opts)

%%  options / defaults
if nargin < 7 || isempty(opts), opts = struct(); end
if ~isfield(opts,'plot'),        opts.plot = true; end
if ~isfield(opts,'use_arrival'), opts.use_arrival = true; end
if ~isfield(opts,'Wc') || isempty(opts.Wc), opts.Wc = N_MHE; end
if ~isfield(opts,'model') || isempty(opts.model), opts.model = 4; end

if ~isfield(opts,'split_forces'), opts.split_forces = false; end
if ~isfield(opts,'ay_in_state'),  opts.ay_in_state  = false; end
if ~isfield(opts,'ay_drives_vy'), opts.ay_drives_vy = false; end
if ~isfield(opts,'ay_in_cost'),   opts.ay_in_cost   = false; end
if ~isfield(opts,'use_Dsum_lam'), opts.use_Dsum_lam = false; end
if ~isfield(opts,'DsumLam_as_params'), opts.DsumLam_as_params = false; end
if ~isfield(opts,'D_in_states'),  opts.D_in_states  = false; end

if ~isfield(opts,'par_estimate'), opts.par_estimate = []; end
if ~isfield(opts,'prefer_ay_state_constraint'), opts.prefer_ay_state_constraint = true; end

% Measurement noise sigmas (defaults)
sig_vx = 0.2^2;
sig_vy = 0.2^2;
sig_r  = 1e-3^2;
sig_ay = 0.10^2;
sig_Fyf = 0.1^2;   % N
sig_Fyr = 0.1^2;   % N

% Pull from EKF if present
if isfield(filter,'meas_cov') && ~isempty(filter.meas_cov)
    if isequal(size(filter.meas_cov),[3 3])
        sig_vx = sqrt(filter.meas_cov(1,1));
        sig_vy = sqrt(filter.meas_cov(2,2));
        sig_r  = sqrt(filter.meas_cov(3,3));
    elseif isequal(size(filter.meas_cov),[2 2])
        sig_vx = sqrt(filter.meas_cov(1,1));
        sig_r  = sqrt(filter.meas_cov(2,2));
    end
end
if isfield(filter,'force_cov') && ~isempty(filter.force_cov)
    if isequal(size(filter.force_cov),[1 1])
        sig_ay = sqrt(filter.force_cov(1,1));
    elseif isequal(size(filter.force_cov),[2 2])
        sig_Fyf = sqrt(filter.force_cov(1,1));
        sig_Fyr = sqrt(filter.force_cov(2,2));
    end
end

% Override by opts if provided
if isfield(opts,'sig_vx')  && ~isempty(opts.sig_vx),  sig_vx  = opts.sig_vx;  end
if isfield(opts,'sig_vy')  && ~isempty(opts.sig_vy),  sig_vy  = opts.sig_vy;  end
if isfield(opts,'sig_r')   && ~isempty(opts.sig_r),   sig_r   = opts.sig_r;   end
if isfield(opts,'sig_ay')  && ~isempty(opts.sig_ay),  sig_ay  = opts.sig_ay;  end
if isfield(opts,'sig_Fyf') && ~isempty(opts.sig_Fyf), sig_Fyf = opts.sig_Fyf; end
if isfield(opts,'sig_Fyr') && ~isempty(opts.sig_Fyr), sig_Fyr = opts.sig_Fyr; end

out.sigmas = struct('sig_vx',sig_vx,'sig_vy',sig_vy,'sig_r',sig_r,'sig_ay',sig_ay,'sig_Fyf',sig_Fyf,'sig_Fyr',sig_Fyr);

%%  load & align measured signals
sim = false;
try
    [t, vx_m, vy_m, r_m, delta_m, ax_m, ay_m, az_m, Fyf_m, Fyr_m, road_bank, alpha_f_m, alpha_r_m, grip_f_m, grip_r_m, wheel_fr, wheel_fl, wheel_rl, wheel_rr] = load_log(log, Ts, sim); %#ok<ASGLU>
catch
    [t, vx_m, vy_m, r_m, delta_m, ax_m, ay_m, az_m, Fyf_m, Fyr_m, road_bank, alpha_f_m, alpha_r_m, grip_f_m, grip_r_m] = load_log(log, Ts, sim); %#ok<ASGLU>
    wheel_fr = []; wheel_fl = []; wheel_rl = []; wheel_rr = [];
end

T_len = numel(vx_m);
assert(N_MHE >= 1 && N_MHE < T_len, 'N_MHE out of range.');

k0    = N_MHE + 1;
k_idx = k0:T_len;
T     = numel(k_idx);

T_use = min([T, size(X_estimate,1), size(U_estimate,1)]);
k_idx = k_idx(1:T_use);
T     = T_use;

vx_mea = vx_m(k_idx);
vy_mea = vy_m(k_idx);
r_mea  = r_m(k_idx);
ay_mea = ay_m(k_idx);
t_aln  = t(k_idx);

Fyf_mea = [];
Fyr_mea = [];
if exist('Fyf_m','var') && ~isempty(Fyf_m), Fyf_mea = Fyf_m(k_idx); end
if exist('Fyr_m','var') && ~isempty(Fyr_m), Fyr_mea = Fyr_m(k_idx); end

out.t = t_aln;

%%  infer/parse estimate layout
nx_est = size(X_estimate,2);

% Always expect [vx vy r ...] as first three in your MHE scripts
vx_est = X_estimate(1:T,1);
vy_est = X_estimate(1:T,2);
r_est  = X_estimate(1:T,3);

hasAyState = false;
if isfield(opts,'ay_in_state')
    hasAyState = logical(opts.ay_in_state);
else
    hasAyState = (nx_est==4 || nx_est==6);
end

ay_state_est = [];
if hasAyState
    ay_state_est = X_estimate(1:T,4);
end

% Determine where tire terms live
Df_est = [];
Dr_est = [];
Dsum_est = [];
lam_est  = [];

if opts.use_Dsum_lam
    if opts.DsumLam_as_params
        if isempty(opts.par_estimate)
            error('Dsum/lam are parameters but opts.par_estimate is empty. Pass opts.par_estimate = [Dsum lam] over time.');
        end
        Dsum_est = opts.par_estimate(1:T,1);
        lam_est  = opts.par_estimate(1:T,2);
    else
        if hasAyState
            if nx_est < 6, error('Expected X_estimate to include [.. ay Dsum lam] (6 cols) but it does not.'); end
            Dsum_est = X_estimate(1:T,5);
            lam_est  = X_estimate(1:T,6);
        else
            if nx_est < 5, error('Expected X_estimate to include [.. Dsum lam] (5 cols) but it does not.'); end
            Dsum_est = X_estimate(1:T,4);
            lam_est  = X_estimate(1:T,5);
        end
    end
    Df_est = lam_est .* Dsum_est;
    Dr_est = (1 - lam_est) .* Dsum_est;
else
    % Df/Dr either in state or in decision params (opts.par_estimate)
    if opts.D_in_states
        if hasAyState
            if nx_est < 6, error('Expected X_estimate to include [.. ay Df Dr] (6 cols) but it does not.'); end
            Df_est = X_estimate(1:T,5);
            Dr_est = X_estimate(1:T,6);
        else
            if nx_est < 5, error('Expected X_estimate to include [.. Df Dr] (5 cols) but it does not.'); end
            Df_est = X_estimate(1:T,4);
            Dr_est = X_estimate(1:T,5);
        end
    else
        if isempty(opts.par_estimate)
            error('Df/Dr are parameters but opts.par_estimate is empty. Pass opts.par_estimate = [Df Dr] over time.');
        end
        Df_est = opts.par_estimate(1:T,1);
        Dr_est = opts.par_estimate(1:T,2);
    end
end

delta_est = U_estimate(1:T,1);
ax_est    = U_estimate(1:T,2);

out.used = struct('hasAyState',hasAyState,'use_Dsum_lam',opts.use_Dsum_lam,'DsumLam_as_params',opts.DsumLam_as_params,'D_in_states',opts.D_in_states);

%%  build CasADi functions (state reduced to x=[vx; vy; r; Df; Dr])
% Meas-mode mapping:
%   0 -> [vx; r]
%   1 -> [vx; r; ay]
%   2 -> [vx; r; Fyf; Fyr]
%   3 -> [vx; vy; r]
%   4 -> [vx; vy; r; ay]
if isfield(opts,'measModeA') && ~isempty(opts.measModeA)
    measModeA = opts.measModeA;
else
    if opts.split_forces
        measModeA = 2;
    elseif opts.ay_in_cost
        measModeA = 1;
    else
        measModeA = 0;
    end
end

if isfield(opts,'measModeB') && ~isempty(opts.measModeB)
    measModeB = opts.measModeB;
else
    if measModeA == 1 || measModeA == 2 || measModeA == 4
        measModeB = measModeA;
    else
        measModeB = 1;
    end
end

[~, h_fun_A, A_fun_A, C_fun_A] = build_aug_bicycle_casadi(Ts, measModeA, filter, opts);
[~, h_fun_B, A_fun_B, C_fun_B] = build_aug_bicycle_casadi(Ts, measModeB, filter, opts);

%%  predict along trajectory (ay, and forces if needed)
ay_pred = nan(T,1);
Fyf_pred = nan(T,1);
Fyr_pred = nan(T,1);

for k = 1:T
    xk = [vx_est(k); vy_est(k); r_est(k); Df_est(k); Dr_est(k)];
    uk = [delta_est(k); ax_est(k)];
    yk = full(h_fun_B(xk,uk));

    % Extract ay if present
    if numel(yk) >= 3
        if measModeB == 1
            ay_pred(k) = yk(3);
        elseif measModeB == 4
            ay_pred(k) = yk(4);
        end
    end

    % Extract forces if present
    if measModeB == 2
        Fyf_pred(k) = yk(3);
        Fyr_pred(k) = yk(4);
    end
end

out.ay_pred  = ay_pred;
out.Fyf_pred = Fyf_pred;
out.Fyr_pred = Fyr_pred;

%%  residuals consistent with your MHE choices
% Measured ay residual (if you want)
e_ay_meas = [];
if ~all(isnan(ay_pred))
    e_ay_meas = ay_mea - ay_pred;
end

% "constraint-like" residual if ay is in the state but doesn't drive vy:
%   ay_state - ay_model  (this matches the added constraint/cost term)
e_ay_state = [];
if hasAyState && ~all(isnan(ay_pred))
    e_ay_state = ay_state_est - ay_pred;
end

out.e_ay_meas  = e_ay_meas;
out.e_ay_state = e_ay_state;

% Choose reference residual for regression/whiteness reporting
use_state_constraint = (hasAyState && opts.prefer_ay_state_constraint && ~opts.ay_drives_vy);
if use_state_constraint && ~isempty(e_ay_state)
    e_ay_ref = e_ay_state;
    ay_ref   = ay_state_est;
    out.ay_ref_source = 'ay_state';
else
    e_ay_ref = e_ay_meas;
    ay_ref   = ay_mea;
    out.ay_ref_source = 'ay_meas';
end

%%  residual basis regression (on chosen ay residual)
if isempty(e_ay_ref) || all(isnan(e_ay_ref))
    out.D1 = struct();
else
    Phi = [ ...
        ones(T,1), ...
        vx_est.^2, ...
        vx_est.*r_est, ...
        vy_est.*r_est, ...
        r_est.^2, ...
        vy_est, ...
        delta_est, ...
        delta_est.*vx_est, ...
        ax_est ];

    phi_names = {'1','vx^2','vx*r','vy*r','r^2','vy','delta','delta*vx','ax'};

    beta  = Phi \ e_ay_ref;
    e_hat = Phi * beta;
    R2 = 1 - sum((e_ay_ref-e_hat).^2) / max(sum((e_ay_ref-mean(e_ay_ref)).^2), eps);

    out.D1.mean_eay = mean(e_ay_ref,'omitnan');
    out.D1.std_eay  = std(e_ay_ref,'omitnan');
    out.D1.R2_basis = R2;
    out.D1.beta     = beta;

    fprintf('\n[D1] ay residual (%s): mean=%.4f, std=%.4f, R2(basis)=%.2f\n', out.ay_ref_source, out.D1.mean_eay, out.D1.std_eay, out.D1.R2_basis);
    fprintf('[D1] beta terms:\n');
    disp(array2table(beta(:).', 'VariableNames', phi_names));

    z = e_ay_ref ./ max(sig_ay, 1e-12);
    acf_lags = 100;
    acf_z = acf_coeff(z, acf_lags);

    out.D1.z_mean = mean(z,'omitnan');
    out.D1.z_std  = std(z,'omitnan');
    out.D1.acf_z  = acf_z;

    fprintf('[D1] z=eay/sig_ay (sig_ay=%.3g): mean=%.3f, std=%.3f, max|acf(1..%d)|=%.3f\n', ...
        sig_ay, out.D1.z_mean, out.D1.z_std, acf_lags, max(abs(acf_z)));

    if ~all(isnan(ay_pred))
        [peakAy, lagAy] = bestlag(ay_ref, ay_pred, Ts);
        out.D1.lag_ay_s    = lagAy;
        out.D1.lag_ay_peak = peakAy;
        fprintf('[D1] best lag %s vs ay_pred: %.1f ms (peak corr=%.3f)\n', out.ay_ref_source, 1e3*lagAy, peakAy);
    end
end

%%  Fisher / CRB weights for measModeA/measModeB
% Build R based on measurement channels in each mode
R_A = meas_cov_from_mode(measModeA, sig_vx, sig_vy, sig_r, sig_ay, sig_Fyf, sig_Fyr);
R_B = meas_cov_from_mode(measModeB, sig_vx, sig_vy, sig_r, sig_ay, sig_Fyf, sig_Fyr);

WA = chol(inv(R_A), 'lower');
WB = chol(inv(R_B), 'lower');

% Arrival prior on x_{k0}: x=[vx; vy; r; Df; Dr]
if isfield(filter,'arr_cov') && isequal(size(filter.arr_cov),[5 5])
    P0 = filter.arr_cov;
else
    P0 = diag([0.5, 0.5, 0.02, 1e-3, 1e-3]).^2;
end

if opts.use_arrival
    P0inv = inv(P0);
else
    P0inv = zeros(5,5);
end

%%  rolling-window Fisher about x_{k0}
Wc = min(opts.Wc, T);
condA = nan(T,1); condB = nan(T,1);
minsvA = nan(T,1); minsvB = nan(T,1);

for k = 1:T
    k0w = max(1, k - Wc + 1);
    k1w = k;

    InfoA = fisher_window_x0(vx_est,vy_est,r_est,Df_est,Dr_est, delta_est,ax_est, ...
                             k0w,k1w, A_fun_A, C_fun_A, WA);
    InfoA = regularize_info((InfoA + InfoA.')/2 + P0inv);

    sA = svd(InfoA);
    minsvA(k) = sA(end);
    condA(k)  = sA(1)/max(sA(end), eps);

    InfoB = fisher_window_x0(vx_est,vy_est,r_est,Df_est,Dr_est, delta_est,ax_est, ...
                             k0w,k1w, A_fun_B, C_fun_B, WB);
    InfoB = regularize_info((InfoB + InfoB.')/2 + P0inv);

    sB = svd(InfoB);
    minsvB(k) = sB(end);
    condB(k)  = sB(1)/max(sB(end), eps);
end

out.fisher.Wc = Wc;
out.fisher.condA = condA;
out.fisher.condB = condB;
out.fisher.min_sigmaA = minsvA;
out.fisher.min_sigmaB = minsvB;
out.fisher.measModeA = measModeA;
out.fisher.measModeB = measModeB;

fprintf('\n--- Rolling-window Fisher (x0) summary (Wc=%d) ---\n', Wc);
fprintf('Median cond(Info) ModeA=%d: %.3e | ModeB=%d: %.3e\n', measModeA, median(condA,'omitnan'), measModeB, median(condB,'omitnan'));

%%  representative CRB + corr(Df,Dr)
k_rep = max(1, round(T/2));
k0w = max(1, k_rep - Wc + 1);
k1w = k_rep;

InfoA_rep = fisher_window_x0(vx_est,vy_est,r_est,Df_est,Dr_est, delta_est,ax_est, ...
                             k0w,k1w, A_fun_A, C_fun_A, WA);
InfoB_rep = fisher_window_x0(vx_est,vy_est,r_est,Df_est,Dr_est, delta_est,ax_est, ...
                             k0w,k1w, A_fun_B, C_fun_B, WB);

InfoA_rep = regularize_info((InfoA_rep+InfoA_rep.')/2 + P0inv);
InfoB_rep = regularize_info((InfoB_rep+InfoB_rep.')/2 + P0inv);

CRB_A = pinv(InfoA_rep);
CRB_B = pinv(InfoB_rep);

out.CRB.A = CRB_A;
out.CRB.B = CRB_B;

names = {'vx0','vy0','r0','Df','Dr'};
stdA = sqrt(max(diag(CRB_A),0));
stdB = sqrt(max(diag(CRB_B),0));

out.CRB.stdA = array2table(stdA(:).', 'VariableNames', names);
out.CRB.stdB = array2table(stdB(:).', 'VariableNames', names);

idxp = [4 5];
covpA = CRB_A(idxp,idxp); dA = sqrt(diag(covpA)); corrpA = covpA ./ (dA*dA.');
covpB = CRB_B(idxp,idxp); dB = sqrt(diag(covpB)); corrpB = covpB ./ (dB*dB.');

out.CRB.corr_pA = corrpA;
out.CRB.corr_pB = corrpB;

[~,~,V_A] = svd(InfoA_rep);
[~,~,V_B] = svd(InfoB_rep);
out.CRB.weak_dirA = V_A(:,end);
out.CRB.weak_dirB = V_B(:,end);

fprintf('\n=== Representative window CRB (arrival=%d) ===\n', opts.use_arrival);
fprintf('ModeA=%d std:\n'); disp(out.CRB.stdA);
fprintf('ModeB=%d std:\n'); disp(out.CRB.stdB);
fprintf('Corr(Df,Dr) ModeA: %.3f | ModeB: %.3f\n', corrpA(1,2), corrpB(1,2));
fprintf('Weak dir A: '); fprintf('%.3e ', out.CRB.weak_dirA); fprintf('\n');
fprintf('Weak dir B: '); fprintf('%.3e ', out.CRB.weak_dirB); fprintf('\n');

%%  plots
if opts.plot
    if ~all(isnan(ay_pred))
        figure('Color','w','Name','ay reference vs model');
        subplot(3,1,1);
        plot(t_aln, ay_ref, t_aln, ay_pred); grid on; legend([out.ay_ref_source ' ref'],'ay pred');
        ylabel('a_y [m/s^2]');
        subplot(3,1,2);
        plot(t_aln, (ay_ref - ay_pred)); grid on; ylabel('e_{ay}');
        subplot(3,1,3);
        if exist('e_hat','var')
            plot(t_aln, e_hat); grid on; ylabel('e_{ay} fit'); xlabel('t [s]');
        else
            plot(t_aln, (ay_ref - ay_pred)); grid on; ylabel('e_{ay}'); xlabel('t [s]');
        end
    end

    figure('Color','w','Name','Rolling-window Fisher conditioning');
    subplot(2,1,1);
    plot(t_aln, log10(condA), t_aln, log10(condB)); grid on;
    legend(sprintf('ModeA=%d log10 cond',measModeA), sprintf('ModeB=%d log10 cond',measModeB));
    ylabel('log10(cond)');
    subplot(2,1,2);
    plot(t_aln, log10(minsvA), t_aln, log10(minsvB)); grid on;
    legend(sprintf('ModeA=%d log10 \\sigma_{min}',measModeA), sprintf('ModeB=%d log10 \\sigma_{min}',measModeB));
    ylabel('log10(\sigma_{min})'); xlabel('t [s]');
end

end

%% Helpers

function R = meas_cov_from_mode(mode, sig_vx, sig_vy, sig_r, sig_ay, sig_Fyf, sig_Fyr)
% mode:
%   0 -> [vx; r]
%   1 -> [vx; r; ay]
%   2 -> [vx; r; Fyf; Fyr]
%   3 -> [vx; vy; r]
%   4 -> [vx; vy; r; ay]
switch mode
    case 0
        R = diag([sig_vx^2, sig_r^2]);
    case 1
        R = diag([sig_vx^2, sig_r^2, sig_ay^2]);
    case 2
        R = diag([sig_vx^2, sig_r^2, sig_Fyf^2, sig_Fyr^2]);
    case 3
        R = diag([sig_vx^2, sig_vy^2, sig_r^2]);
    case 4
        R = diag([sig_vx^2, sig_vy^2, sig_r^2, sig_ay^2]);
    otherwise
        error('Unknown meas mode.');
end

d = diag(R);
d(d<=0 | ~isfinite(d)) = 1e-12;
R = diag(d);
end

function Info = fisher_window_x0(vx,vy,r,Df,Dr, delta,ax, k0w,k1w, A_fun, C_fun, Wmeas)
nx = 5;
F  = eye(nx);
Info = zeros(nx,nx);

for j = k0w:k1w
    xj = [vx(j); vy(j); r(j); Df(j); Dr(j)];
    uj = [delta(j); ax(j)];

    Cj = full(C_fun(xj,uj));
    Sj = Cj * F;

    Sjw  = Wmeas * Sj;
    Info = Info + Sjw.' * Sjw;

    if j < k1w
        Aj = full(A_fun(xj,uj));
        F  = Aj * F;
    end
end
end

function M = regularize_info(M)
n = size(M,1);
eps_rel = 1e-12;
M = (M + M.')/2;
M = M + eps_rel * trace(M)/max(n,1) * eye(n);
end

function acf = acf_coeff(x, nlags)
    x = x(:) - mean(x(:),'omitnan');
    den = sum(x.^2,'omitnan');
    acf = zeros(nlags,1);
    for k=1:nlags
        acf(k) = sum(x(1:end-k).*x(1+k:end),'omitnan') / max(den, eps);
    end
end

function [peak, lag_s] = bestlag(a, b, Ts)
a = a(:); b = b(:);
n = min(numel(a), numel(b));
a = a(1:n); b = b(1:n);
[cc,lags] = xcorr(a, b, 'coeff');
[peak,idx] = max(cc);
lag_s = lags(idx)*Ts;
end

%% CasADi model builder

function [fd_fun,h_fun,A_fun,C_fun] = build_aug_bicycle_casadi(Ts, measMode, P, opts)
import casadi.*

if nargin < 4 || isempty(opts), opts = struct(); end
if ~isfield(opts,'model') || isempty(opts.model), opts.model = 4; end
model = opts.model;

x = SX.sym('x', 5);      % [vx; vy; r; Df; Dr]
u = SX.sym('u', 2);      % [delta; ax]

vx = x(1); vy = x(2); r = x(3);
Df = x(4); Dr = x(5);

delta = u(1);
ax    = u(2);

m  = P.mass;
Iz = P.Jz;
wb = P.wheelbase;
lf = P.lf;
lr = P.lr;

g  = P.g;
hc = P.h_G;

Cl = P.Cl;
rho = P.rho;
Area = P.S;
aero_split = P.aero_split;

twf = 0; twr = 0;
if isfield(P,'tf') && ~isempty(P.tf), twf = P.tf; end
if isfield(P,'tr') && ~isempty(P.tr), twr = P.tr; end

Mf = P.front.Macroparams(:);
Mr = P.rear.Macroparams(:);

Bf = Mf(1);
Br = Mr(1);

Cf = Mf(2); Cr = Mr(2);
Ef = Mf(4); Er = Mr(4);

vx_base = if_else(vx < 2.0, 2.0, vx);

vx_fl = vx_base - r*twf/2;
vx_fr = vx_base + r*twf/2;
vx_rl = vx_base - r*twr/2;
vx_rr = vx_base + r*twr/2;

alpha_fl = delta - atan2(vy + lf*r, vx_fl);
alpha_fr = delta - atan2(vy + lf*r, vx_fr);
alpha_rl =      - atan2(vy - lr*r, vx_rl);
alpha_rr =      - atan2(vy - lr*r, vx_rr);

alpha_f = 0.5*(alpha_fl + alpha_fr);
alpha_r = 0.5*(alpha_rl + alpha_rr);

af = -alpha_f;
ar = -alpha_r;

Fz_f = lr/wb*m*g + 0.5*Cl*rho*Area*(vx_base^2)*aero_split         - m*ax*hc/wb;
Fz_r = lf/wb*m*g + 0.5*Cl*rho*Area*(vx_base^2)*(1-aero_split)     + m*ax*hc/wb;

switch model
  case 1
    K_r = Br*Cr*Dr;  K_f = Bf*Cf*Df;
    Fyf = K_f * Fz_f * (-alpha_f);
    Fyr = K_r * Fz_r * (-alpha_r);

  case 2
    K_r = Br*Cr*Dr;  K_f = Bf*Cf*Df;
    Fyf = if_else((-alpha_f*K_f) < (-Df), -Df, if_else((-alpha_f*K_f) > ( Df),  Df, (-alpha_f*K_f))) * Fz_f;
    Fyr = if_else((-alpha_r*K_r) < (-Dr), -Dr, if_else((-alpha_r*K_r) > ( Dr),  Dr, (-alpha_r*K_r))) * Fz_r;

  case 3
    Fyf = Df * sin(Cf*atan2(Bf*af,1) - Ef*((Bf*af) - atan2(Bf*af,1))) * Fz_f;
    Fyr = Dr * sin(Cr*atan2(Br*ar,1) - Er*((Br*ar) - atan2(Br*ar,1))) * Fz_r;

  case 4
    Fyf = Df * sin(Bf*af) * Fz_f;
    Fyr = Dr * sin(Br*ar) * Fz_r;

  case 5
    Fyf = Df * sin(Cf*atan2(Bf*af,1)) * Fz_f;
    Fyr = Dr * sin(Cr*atan2(Br*ar,1)) * Fz_r;

  otherwise
    error('Unknown model selected.');
end

ay = (Fyf*cos(delta) + Fyr)/m;

vx_dot = ax + vy*r;
vy_dot = ay - vx*r;
r_dot  = (lf*Fyf*cos(delta) - lr*Fyr)/Iz;

fc = [vx_dot; vy_dot; r_dot; 0; 0];

switch measMode
    case 0
        h = [vx; r];
    case 1
        h = [vx; r; ay];
    case 2
        h = [vx; r; Fyf; Fyr];
    case 3
        h = [vx; vy; r];
    case 4
        h = [vx; vy; r; ay];
    otherwise
        error('Unknown measMode.');
end

k1 = fc;
k2 = substitute(fc, x, x + (Ts/2)*k1);
k3 = substitute(fc, x, x + (Ts/2)*k2);
k4 = substitute(fc, x, x + Ts*k3);
fd = x + (Ts/6)*(k1 + 2*k2 + 2*k3 + k4);

fd_fun = Function('fd_fun', {x,u}, {fd});
h_fun  = Function('h_fun',  {x,u}, {h});
A_fun  = Function('A_fun',  {x,u}, {jacobian(fd, x)});
C_fun  = Function('C_fun',  {x,u}, {jacobian(h,  x)});
end

function y = clamp(x, lo, hi)
y = fmin(fmax(x, lo), hi);
end
