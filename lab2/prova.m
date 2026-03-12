% =========================================================================
% SETUP PARAMETRI
% =========================================================================
M = 10^5;
theta = 5;
lambda1_true = 4 / 10000;
lambda2_true = 10 / 10000;
T = 30;

% =========================================================================
% PUNTO 5a: SIMULARE IL TEMPO DI DEFAULT (tau)
% =========================================================================
tau = simulate_default_time(lambda1_true, lambda2_true, theta, M, T);

% =========================================================================
% PUNTO 5b: FIT DELLA PROBABILITÀ DI SOPRAVVIVENZA
% =========================================================================
tau_sort = sort(tau);

S_exp = (M:-1:1)' / M;
idx_valid = S_exp > 0;
S_exp = S_exp(idx_valid);
tau_sort = tau_sort(idx_valid);

Y_log = log(S_exp);

% --- REGIONE 1 (0 a theta): STIMA DI LAMBDA1 ---
idx1 = tau_sort <= theta;
X1 = tau_sort(idx1);
Y1 = Y_log(idx1);

mdl1 = fitlm(X1, Y1, 'Intercept', false);
ci1 = mdl1.coefCI;
lambda1_hat = -mdl1.Coefficients.Estimate;
CI_lambda1 = sort(-ci1);

% --- REGIONE 2 (oltre theta): STIMA DI LAMBDA2 ---
idx2 = tau_sort > theta;
X2 = tau_sort(idx2);
Y2 = Y_log(idx2);

mdl2 = fitlm(X2, Y2);
ci2 = mdl2.coefCI;
lambda2_hat = -mdl2.Coefficients.Estimate(2);
CI_lambda2 = sort(-ci2(2, :));

% =========================================================================
% GRAFICO
% =========================================================================
Lambda_fit = zeros(size(tau_sort));
Lambda_fit(idx1) = lambda1_hat * tau_sort(idx1);
Lambda_fit(idx2) = lambda1_hat * theta + lambda2_hat * (tau_sort(idx2) - theta);

Y_fit = -Lambda_fit;

figure;
plot(tau_sort, Y_log, 'b.', 'MarkerSize', 1); hold on;
plot(tau_sort, Y_fit, 'r-', 'LineWidth', 2);
title('Fit Log-Lineare della Probabilità di Sopravvivenza (Esercizio 5b)');
xlabel('Tempo \tau (Anni)');
ylabel('ln( S(\tau) )');
legend('Dati Sperimentali (Simulati)', 'Curva Teorica (Fittata)', 'Location', 'SouthWest');
grid on;

% =========================================================================
% RISULTATI IN BASIS POINTS
% =========================================================================
fprintf('\n--- RISULTATI DEL FIT ---\n');
fprintf('Lambda 1 (Vero: 4.00 bps)  -> Stimato: %.2f bps  (CI 95%%: [%.2f, %.2f])\n', ...
    lambda1_hat*10000, CI_lambda1(1)*10000, CI_lambda1(2)*10000);
fprintf('Lambda 2 (Vero: 10.00 bps) -> Stimato: %.2f bps  (CI 95%%: [%.2f, %.2f])\n', ...
    lambda2_hat*10000, CI_lambda2(1)*10000, CI_lambda2(2)*10000);

% =========================================================================
% FUNCTION
% =========================================================================
function tau = simulate_default_time(lambda1, lambda2, theta, M, T)
rng(5)
U = rand(M, 1);
tau = zeros(M, 1);
target = lambda1 * theta;

for i = 1:M
    E = log(1 / U(i));
    if E < target
        tau(i) = E / lambda1;
    else
        tau(i) = theta + (E - target) / lambda2;
    end
    if tau(i) > T
        tau(i) = T;
    end
end
end