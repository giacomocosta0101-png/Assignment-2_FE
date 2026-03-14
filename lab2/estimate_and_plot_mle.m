function [lambda1_MLE, lambda2_MLE, CI_lambda1, CI_lambda2] = estimate_and_plot_mle(tau, theta, T, alpha, filename)
% Compute MLE estimators confidence interval for lambda1, lambda2 and plots 
% the log-linear survival fit.
%
% INPUTS:
% tau       : Vector with simulated default times        
% theta     : Time (in years) when the risk intensity changes           
% T         : Maximum time horizon 
% alpha     : Significance level for confidence intervals 
% filename  : output PDF path (e.g. 'mle_survival.pdf')
%            
% OUTPUT:
% lambda1_MLE   : estimator for lambda1
% lambda2_MLE   : estimator for lambda2
% CI_lambda1    : confidence interval for lambda1
% CI_lambda2    : confidence interval for lambda2

M = length(tau); % Number of simulated default times
z_alpha = norminv(1 - alpha/2); % Normal quantile for the confidence level alpha

% -------------------------------------------------------------------------
% MLE for Lambda 1 (First period: t <= theta) 
% -------------------------------------------------------------------------

% idx1 is a logical vector indicating which defaults occur in the first period
idx1 = (tau <= theta);

% k1 is the number of defaults that occur in the first period.
k1 = sum(idx1); 

% T1 is the total time at risk in the first period:
%   - For simulations with τ <= θ, we add τ (they default in period 1)
%   - For simulations with τ > θ, they survive the whole first period,
%     so we add θ for each of them.
T1 = sum(tau(idx1)) + sum(~idx1) * theta; % Total time exposed in period 1
   
% MLE for λ1 in a Poisson process / exponential model:
%   λ1_MLE = (number of events in period 1) / (total time at risk in period 1)
lambda1_MLE = k1 / T1; 

% Asymptotic standard error for λ1_MLE:
%   Var(λ1_MLE) ≈ λ1^2 / k1  → SE ≈ λ1_MLE / sqrt(k1)
SE_1 = lambda1_MLE / sqrt(k1); 

% Confidence interval for λ1 using normal approximation:
%   λ1_MLE ± z_alpha * SE_1
CI_lambda1 = lambda1_MLE + [-1, 1] * z_alpha * SE_1;

% -------------------------------------------------------------------------
% MLE for Lambda 2 (Second period: t > theta) 
% -------------------------------------------------------------------------

% idx2: defaults that occur strictly after θ.
idx2 = ~idx1;

% k2 is the number of defaults that occur in the second period.
k2 = sum(idx2); 

% T2 is the total time at risk in the second period:
%   For τ > θ, the time spent in period 2 is (τ - θ).
%   Simulations with τ <= θ do not contribute to T2.
T2 = sum(tau(idx2) - theta); % Total time exposed only in period 2

% MLE for λ2:
%   λ2_MLE = (number of events in period 2) / (total time at risk in period 2)
lambda2_MLE = k2 / T2; 

% Asymptotic standard error for λ2_MLE:
SE_2 = lambda2_MLE / sqrt(k2); 

% Confidence interval for λ2:
CI_lambda2 = lambda2_MLE + [-1, 1] * z_alpha * SE_2;

% -------------------------------------------------------------------------
% Plotting Log-Linear Survival 
% -------------------------------------------------------------------------

% Sort default times in ascending order to build the empirical survival curve
tau_sort = sort(tau); 

% Empirical survival probability:
% For ordered times τ_(1) <= ... <= τ_(M),
% the empirical survival at τ_(i) is approximately (M - i) / M.
%  We use (M-1:-1:1)' / M and drop the last point to avoid log(0).
P_experim = (M-1:-1:1)' / M; 

% We drop the last point τ_(M) because its empirical survival is 0,
% and log(0) is undefined.
tau_sort = tau_sort(1:end-1); 

% Log of empirical survival probabilities:
Y_log_exp = log(P_experim); 

% -------------------------------------------------------------------------
% Build the theoretical fitted log-survival curve
% -------------------------------------------------------------------------

% Initialize the fitted log-survival vector.
Y_fit = zeros(size(tau_sort)); 

% f1 marks times in the first period (τ <= θ),
% f2 marks times in the second period (τ > θ).
f1 = (tau_sort <= theta); 
f2 = ~f1; 

% In the first period (t <= θ), the survival function is:
%   S(t) = exp(-λ1 * t), so log S(t) = -λ1 * t
Y_fit(f1) = -lambda1_MLE * tau_sort(f1); 

% In the second period (t > θ), the survival function is:
%   S(t) = exp(-λ1 * θ) * exp(-λ2 * (t - θ)), so log S(t) = -λ1 * θ - λ2 * (t - θ)
Y_fit(f2) = -lambda1_MLE * theta - lambda2_MLE * (tau_sort(f2) - theta); 

% -------------------------------------------------------------------------
% Compute Confidence Interval Bounds for the Plot 
% -------------------------------------------------------------------------

% Y_CI_lower and Y_CI_upper represent the lower and upper bounds for
% the log-survival function, obtained by plugging the confidence interval
% endpoints of λ1 and λ2 into the piecewise log-survival formula.
Y_CI_lower = zeros(size(tau_sort)); 
Y_CI_upper = zeros(size(tau_sort)); 

% Period 1 (t <= theta):
%   log S_lower(t) = -λ1_upper * t
%   log S_upper(t) = -λ1_lower * t
Y_CI_lower(f1) = -CI_lambda1(2) * tau_sort(f1);
Y_CI_upper(f1) = -CI_lambda1(1) * tau_sort(f1);

% Period 2 (t > theta):
%   log S_lower(t) = -λ1_upper * θ - λ2_upper * (t - θ)
%   log S_upper(t) = -λ1_lower * θ - λ2_lower * (t - θ)
Y_CI_lower(f2) = -CI_lambda1(2) * theta - CI_lambda2(2) * (tau_sort(f2) - theta);
Y_CI_upper(f2) = -CI_lambda1(1) * theta - CI_lambda2(1) * (tau_sort(f2) - theta);

% -------------------------------------------------------------------------
% Generate Plot
% -------------------------------------------------------------------------

fig = figure('Visible', 'off'); 

% Plot empirical log-survival curve
plot(tau_sort, Y_log_exp, 'b-', 'LineWidth', 1.5); 
hold on;

% Plot fitted log-survival curve from the piecewise-constant intensity model
plot(tau_sort, Y_fit, 'r-', 'LineWidth', 1.5); 

% Add Confidence Bands to the Plot 
% Lower and upper log-survival bounds based on CI of λ1 and λ2.
plot(tau_sort, Y_CI_lower, 'r--', 'LineWidth', 0.5); 
plot(tau_sort, Y_CI_upper, 'r--', 'LineWidth', 0.5); 

% Vertical line at θ to show the change point in intensity.
xline(theta, 'k--', 'Theta', 'LabelVerticalAlignment', 'bottom'); 

% Add title and axis labels.
title('Log-Linear Survival Fit (MLE)', 'FontSize', 12); 
xlabel('Time to Default \tau (Years)', 'FontSize', 11); 
ylabel('ln(P(0,\tau))', 'FontSize', 11); 

legend('Empirical Data', 'Fitted Model (MLE)', '95% CI Bounds', '', 'Location', 'best');

% Limit x-axis to [0, T], where T is the maximum time horizon.
xlim([0, T]); 

grid on;

% Save the figure as vector PDF and close
exportgraphics(fig, filename, 'ContentType', 'vector');
close(fig);
fprintf('Plot saved to: %s\n', filename);

end
