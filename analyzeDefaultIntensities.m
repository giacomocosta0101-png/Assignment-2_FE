function analyzeDefaultIntensities(tau, theta, Tmax)

% =========================================================================
% PUNTO 5b: FIT DELLA PROBABILITÀ DI SOPRAVVIVENZA
% =========================================================================

% FIX: usa TUTTI i tau inclusi sopravvissuti (tau=T)
% La survival empirica è P(tau > t) = #{tau > t} / M

tgrid = linspace(0, Tmax, 500)';
S_emp = zeros(size(tgrid));

for i = 1:length(tgrid)
    S_emp(i) = mean(tau >= tgrid(i));
end


% We exclude points were S_emp = 0:

mask = S_emp > 0;
tgrid_fit = tgrid(mask);
Y_log = log(S_emp(mask));

% --- first region (from 0 to theta): We estimate LAMBDA 1 ---

idx1 = tgrid_fit <= theta;

X1 = tgrid_fit(idx1);
Y1 = Y_log(idx1);

mdl1 = fitlm(X1, Y1, 'Intercept', false); % false = pass through the origin
% as we have that: ln(P(0,t)) = -lambda1*t

lambda1_hat = -mdl1.Coefficients.Estimate;
ci1 = mdl1.coefCI;
CI_lambda1 = sort(-ci1);

% --- REGIONE 2 (theta a Tmax): STIMA LAMBDA2 ---
idx2 = tgrid_fit > theta;
X2 = tgrid_fit(idx2) - theta;           % shift
Y2 = Y_log(idx2) + lambda1_hat * theta; % shift
mdl2 = fitlm(X2, Y2, 'Intercept', false);

lambda2_hat = -mdl2.Coefficients.Estimate;
ci2 = mdl2.coefCI;
CI_lambda2 = sort(-ci2);

% =========================================================================
% GRAFICO
% =========================================================================
Y_fit = zeros(size(tgrid_fit));
Y_fit(idx1) = -lambda1_hat * tgrid_fit(idx1);
Y_fit(idx2) = -lambda1_hat*theta - lambda2_hat*(tgrid_fit(idx2)-theta);

figure;
plot(tgrid_fit, Y_log, 'b-', 'LineWidth', 1.5); hold on;
plot(tgrid_fit, Y_fit, 'r--', 'LineWidth', 2);
xline(theta, 'k--', '\theta=5', 'LabelVerticalAlignment','bottom');
title('Fit Log-Lineare della Probabilità di Sopravvivenza (Esercizio 5b)');
xlabel('Tempo \tau (Anni)');
ylabel('ln( S(\tau) )');
legend('Dati Sperimentali','Curva Fittata','Location','SouthWest');
grid on;

% Risultati
fprintf('\n=== RISULTATI FIT ===\n');
fprintf('lambda1_hat = %.6f (bps: %.2f)\n', lambda1_hat, lambda1_hat*1e4);
fprintf('CI lambda1  = [%.6f, %.6f]\n', CI_lambda1(1), CI_lambda1(2));
fprintf('lambda2_hat = %.6f (bps: %.2f)\n', lambda2_hat, lambda2_hat*1e4);
fprintf('CI lambda2  = [%.6f, %.6f]\n', CI_lambda2(1), CI_lambda2(2));

Y_up = zeros(size(tgrid_fit));
Y_lo = zeros(size(tgrid_fit));
Y_up(idx1) = -CI_lambda1(1) * tgrid_fit(idx1);
Y_lo(idx1) = -CI_lambda1(2) * tgrid_fit(idx1);
Y_up(idx2) = -CI_lambda1(1)*theta - CI_lambda2(1)*(tgrid_fit(idx2)-theta);
Y_lo(idx2) = -CI_lambda1(2)*theta - CI_lambda2(2)*(tgrid_fit(idx2)-theta);

plot(tgrid_fit, Y_up, 'g--', 'LineWidth', 1);
plot(tgrid_fit, Y_lo, 'g--', 'LineWidth', 1);
legend('Dati Sperimentali','Curva Fittata','CI 95%','Location','SouthWest');

end