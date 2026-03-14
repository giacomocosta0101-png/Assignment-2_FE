function tau = simulate_default_time(lambda1, lambda2, theta, M)
% Simulate default times from a given probability distribution
%
% INPUTS:
% lambda1 : intensity for times t <= theta
% lambda2 : intensity for times t > theta
% theta   : time at which the intensity switches from lambda1 to lambda2
% M       : number of simulated default times
%
% OUTPUT:
% tau     : vector containing the simulated default times
%

rng(5)  % Fix the random seed for for reproducibility

U = rand(M,1);      % Generate M independent uniform random numbers
tau = zeros(M,1);   % Preallocate the output vector

target = lambda1 * theta;  % Total accumulation of intensity up to time theta

for i = 1:M
    u = U(i);              % Extract the i-th uniform draw
    
    % We check if log(1/u), that represents the total amount of accumulated intensity
    % before the default, is reached before theta or not. 
    if log(1/u) < target 
        % If default occurs before theta, accumulated intensity grows as
        % lambda1 * t, so for finding tau(i) we solve: lambda1 * tau(i) = log(1/u)
        tau(i) = log(1/u) / lambda1;
    else
        % If default occurs after theta, the accumulation grows linearly with slope 
        % lambda1 up to theta and then with slope lambda2, so for finding
        % tau(i) we soolve: lambda1 * theta + lambda2 * (tau(i) - theta) = log(1/u)
        tau(i) = theta + (log(1/u) - lambda1*theta) / lambda2;
    end
end

end