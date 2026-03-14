function analyzeDefaultIntensities(tau, theta, Tmax)
% Piecewise-constant default intensity estimation.
%
%   analyzeDefaultIntensities(tau, theta, Tmax)
%
%   Fits a piecewise-constant hazard-rate model to simulated default times
%   by performing two separate log-linear regressions on the empirical
%   survival function:
%       - Region 1: [0, theta]   -->  intensity lambda_1
%       - Region 2: (theta, Tmax] -->  intensity lambda_2
%
%   Under a piecewise-constant intensity the survival probability is:
%       ln S(t) = -lambda_1 * t                              for t <= theta
%       ln S(t) = -lambda_1 * theta - lambda_2 * (t - theta) for t >  theta
%
%   The function also plots the empirical log-survival curve, the fitted
%   piecewise-linear model, and the 95 % confidence bands.
%
%   INPUTS:
%       tau   – Mx1 vector of simulated default/survival times;
%               censored observations (survived to maturity) have tau = T
%       theta – scalar, breakpoint separating the two intensity regimes
%       Tmax  – scalar, maximum horizon for the analysis grid
%
%   OUTPUTS:
%       (none – results are printed to console and plotted)

%% EMPIRICAL SURVIVAL FUNCTION

% Build a fine time grid and compute the empirical survival probability
% S(t) = P(tau >= t) estimated as the fraction of paths still alive at t

tgrid = linspace(0, Tmax, 500)';
S_emp = zeros(size(tgrid));

for i = 1:length(tgrid)

    S_emp(i) = mean(tau >= tgrid(i));

end

% Discard grid points where S_emp = 0 (log is undefined)

mask      = S_emp > 0;
tgrid_fit = tgrid(mask);
Y_log     = log(S_emp(mask));

%% REGION 1 (0 to theta): ESTIMATE LAMBDA_1

% In this region ln S(t) = -lambda_1 * t, so we fit a zero-intercept
% linear model and recover lambda_1 as the negated slope

idx1 = tgrid_fit <= theta;
X1   = tgrid_fit(idx1);
Y1   = Y_log(idx1);

mdl1        = fitlm(X1, Y1, 'Intercept', false);
lambda1_hat = -mdl1.Coefficients.Estimate;

% 95 % confidence interval (sign-flip reverses the order)

ci1         = mdl1.coefCI;
CI_lambda1  = sort(-ci1);

%% REGION 2 (theta to Tmax): ESTIMATE LAMBDA_2


% Shift the data so that the model becomes ln S_shifted = -lambda_2 * x
%   x = t - theta
%   ln S_shifted = ln S(t) + lambda_1 * theta

idx2 = tgrid_fit > theta;
X2   = tgrid_fit(idx2) - theta;
Y2   = Y_log(idx2) + lambda1_hat * theta;

mdl2        = fitlm(X2, Y2, 'Intercept', false);
lambda2_hat = -mdl2.Coefficients.Estimate;

ci2         = mdl2.coefCI;
CI_lambda2  = sort(-ci2);

%% PLOT

% Reconstruct the fitted piecewise-linear log-survival curve

Y_fit       = zeros(size(tgrid_fit));
Y_fit(idx1) = -lambda1_hat * tgrid_fit(idx1);
Y_fit(idx2) = -lambda1_hat * theta - lambda2_hat * (tgrid_fit(idx2) - theta);

figure;
plot(tgrid_fit, Y_log, 'b-', 'LineWidth', 1.5); hold on;
plot(tgrid_fit, Y_fit, 'r--', 'LineWidth', 2);
xline(theta, 'k--', '\theta=5', 'LabelVerticalAlignment', 'bottom');

title('Log-Linear Fit of the Survival Probability');
xlabel('Time \tau (Years)');
ylabel('ln( S(\tau) )');
legend('Empirical Data', 'Fitted Curve', 'Location', 'SouthWest');
grid on;

%% CONSOLE OUTPUT


fprintf('\n=== FIT RESULTS ===\n');
fprintf('lambda1_hat = %.6f (bps: %.2f)\n', lambda1_hat, lambda1_hat * 1e4);
fprintf('CI lambda1  = [%.6f, %.6f]\n', CI_lambda1(1), CI_lambda1(2));
fprintf('lambda2_hat = %.6f (bps: %.2f)\n', lambda2_hat, lambda2_hat * 1e4);
fprintf('CI lambda2  = [%.6f, %.6f]\n', CI_lambda2(1), CI_lambda2(2));

%% 95 % CONFIDENCE BANDS

% Upper and lower bounds obtained by plugging the CI endpoints of each
% lambda into the piecewise-linear formula
Y_up       = zeros(size(tgrid_fit));
Y_lo       = zeros(size(tgrid_fit));

Y_up(idx1) = -CI_lambda1(1) * tgrid_fit(idx1);
Y_lo(idx1) = -CI_lambda1(2) * tgrid_fit(idx1);

Y_up(idx2) = -CI_lambda1(1) * theta - CI_lambda2(1) * (tgrid_fit(idx2) - theta);
Y_lo(idx2) = -CI_lambda1(2) * theta - CI_lambda2(2) * (tgrid_fit(idx2) - theta);

plot(tgrid_fit, Y_up, 'g--', 'LineWidth', 1);
plot(tgrid_fit, Y_lo, 'g--', 'LineWidth', 1);
legend('Empirical Data', 'Fitted Curve', 'CI 95%', 'Location', 'SouthWest');

end