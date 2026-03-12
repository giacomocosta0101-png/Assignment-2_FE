function tau = simulate_default_time(lambda1, lambda2, theta, M)

rng(5)

U = rand(M,1);

tau = zeros(M,1);

target = lambda1 * theta;

for i = 1:M
    u = U(i);
    if log(1/u) < target
        tau(i) = log(1/u) / lambda1;
    else
        tau(i) = theta + (log(1/u) - lambda1*theta) / lambda2; % FIX: era lambda1 ora lambda2... aspetta
    end
 
end
end