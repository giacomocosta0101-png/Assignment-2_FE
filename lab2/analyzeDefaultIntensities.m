function [lambda1_OLS, lambda2_OLS, CI_lambda1, CI_lambda2] = analyzeDefaultIntensities(tau, theta, T, alpha, filename)
% Compute OLS estimators, confidence interval for lambda1, lambda2 and plots 
% the log-linear survival fit.
%
% INPUTS:
% tau       : Vector with simulated default times        
% theta     : Time (in years) when the risk intensity changes           
% T         : Maximum time horizon 
% alpha     : Significance level for confidence intervals 
% filename  : Output PDF path (e.g. 'OLS_regression.pdf')
%            
% OUTPUT:
% lambda1_OLS   : estimator for lambda1
% lambda2_OLS   : estimator for lambda2
% CI_lambda1    : confidence interval for lambda1
% CI_lambda2    : confidence interval for lambda2

% -------------------------------------------------------------------------
% Empirical Survival Function
% -------------------------------------------------------------------------

% Build a fine time grid and compute the empirical survival probability
tgrid = linspace(0, T, 500)';
S_emp = zeros(size(tgrid));

for i = 1:length(tgrid)
    S_emp(i) = mean(tau >= tgrid(i));
end

% Discard grid points where empirical survival is 0
mask = S_emp > 0;
tgrid_fit = tgrid(mask);
Y_log = log(S_emp(mask));

% -------------------------------------------------------------------------
% OLS for Lambda 1 (First period: t <= theta) 
% -------------------------------------------------------------------------

% idx1 indicates times in the first period
idx1 = (tgrid_fit <= theta);
X1 = tgrid_fit(idx1);
Y1 = Y_log(idx1);

% Fit a zero-intercept linear model
mdl1 = fitlm(X1, Y1, 'Intercept', false);

% Recover lambda1 as the negated slope
lambda1_OLS = -mdl1.Coefficients.Estimate;

% Confidence interval for lambda1
ci1 = mdl1.coefCI(alpha);
CI_lambda1 = sort(-ci1);

% -------------------------------------------------------------------------
% OLS for Lambda 2 (Second period: t > theta) 
% -------------------------------------------------------------------------

% idx2 indicates times in the second period
idx2 = (tgrid_fit > theta);

% Shift the data to fit ln S_shifted = -lambda_2 * x
X2 = tgrid_fit(idx2) - theta;
Y2 = Y_log(idx2) + lambda1_OLS * theta;

% Fit a zero-intercept linear model
mdl2 = fitlm(X2, Y2, 'Intercept', false);

% Recover lambda2 as the negated slope
lambda2_OLS = -mdl2.Coefficients.Estimate;

% Confidence interval for lambda2
ci2 = mdl2.coefCI(alpha);
CI_lambda2 = sort(-ci2);

% -------------------------------------------------------------------------
% Build the theoretical fitted log-survival curve
% -------------------------------------------------------------------------

% Initialize the fitted log-survival vector
Y_fit = zeros(size(tgrid_fit));

% First period 
Y_fit(idx1) = -lambda1_OLS * tgrid_fit(idx1);

% Second period 
Y_fit(idx2) = -lambda1_OLS * theta - lambda2_OLS * (tgrid_fit(idx2) - theta);

% -------------------------------------------------------------------------
% Compute Confidence Interval Bounds for the Plot 
% -------------------------------------------------------------------------

% Initialize the bounds vectors
Y_CI_lower = zeros(size(tgrid_fit));
Y_CI_upper = zeros(size(tgrid_fit));

% First period bounds
Y_CI_lower(idx1) = -CI_lambda1(2) * tgrid_fit(idx1);
Y_CI_upper(idx1) = -CI_lambda1(1) * tgrid_fit(idx1);

% Second period bounds
Y_CI_lower(idx2) = -CI_lambda1(2) * theta - CI_lambda2(2) * (tgrid_fit(idx2) - theta);
Y_CI_upper(idx2) = -CI_lambda1(1) * theta - CI_lambda2(1) * (tgrid_fit(idx2) - theta);

% -------------------------------------------------------------------------
% Generate Plot
% -------------------------------------------------------------------------

fig = figure('Visible', 'off');

% Plot empirical log-survival curve
plot(tgrid_fit, Y_log, 'b-', 'LineWidth', 1.5);
hold on;

% Plot fitted log-survival curve 
plot(tgrid_fit, Y_fit, 'r-', 'LineWidth', 1.5);

% Add Confidence Bands to the Plot
plot(tgrid_fit, Y_CI_lower, 'r--', 'LineWidth', 0.5);
plot(tgrid_fit, Y_CI_upper, 'r--', 'LineWidth', 0.5);

% Vertical line at theta 
xline(theta, 'k--', 'Theta', 'LabelVerticalAlignment', 'bottom');

% Add title and axis labels
title('Log-Linear Survival Fit (OLS)', 'FontSize', 12);
xlabel('Time to Default \tau (Years)', 'FontSize', 11);
ylabel('ln(P(0,\tau))', 'FontSize', 11);

legend('Empirical Data', 'Fitted Model (OLS)', '95% CI Bounds', 'Location', 'best');

% Limit x-axis to [0, T]
xlim([0, T]);

grid on;

% Save the figure as vector PDF and close
exportgraphics(fig, filename, 'ContentType', 'vector');
close(fig);
fprintf('Plot saved to: %s\n', filename);

end