function [datesCDS, survProbs, intensities] = bootstrapCDS(datesDF, discounts, datesCDS, spreadsCDS, flag, recovery)
% Bootstrap survival probabilities and computation of 
% intensities from market CDS spreads
%
% INPUTS:
% datesDF     : vector of dates of the discount curve (datetime or datenum)    
% discounts   : vector of discount factors corresponding to datesDF
% datesCDS    : vector of CDS maturities (datetime or datenum)
% spreadsCDS  : vector of market CDS spreads corresponding to datesCDS
% flag        : method selector for the bootstrapping:
%               1 = neglecting the accrual on default
%               2 = including the accrual on default
%               3 = Jarrow–Turnbull approximation
% recovery    : recovery rate 
%
% OUTPUTS:
% datesCDS    : CDS maturities (returned as numeric datenum if input was datetime)
% survProbs   : vector of survival probabilities from t0 to datesCDS(i)
% intensities : vector of piecewise-constant intensities
%

% If CDS maturities are provided as datetime, we convert them to datenum
if isdatetime(datesCDS)
    datesCDS = datenum(datesCDS);
end

% If discount-curve dates are provided as datetime, we convert them to datenum
if isdatetime(datesDF)
    datesDF = datenum(datesDF);
end

% Initialization
N = length(datesCDS); % Number of CDS maturities 
survProbs   = zeros(N, 1); % Vector of survival probabilities
intensities = zeros(N, 1); % Vector of intensities

t0 = datesDF(1);% The valuation date is the first pillar of the 
% discount % curve

% We compute the discount factors B(t0, ti) at each CDS maturity 
% ti = datesCDS(i).
i = (1:N)';  % column vector of indices 1,...,N
B(i) = get_discount_factor_by_zero_rates_linear_interp(t0, datesCDS(i), datesDF, discounts);


% For computing year fractions for CDS, we use the convention ACT/365
day_count = 3; 

% We initialize the vector deltas such that deltas(i) will store 
% the year fraction between consecutive CDS dates.
deltas = zeros(N, 1);

% For the first date, we compute the year fraction between t0 
% and the first CDS maturity
deltas(1) = yearfrac(t0, datesCDS(1), day_count);

% For the other dates we compute it from datesCDS(i-1) to datesCDS(i).
for i = 2:N
    deltas(i) = yearfrac(datesCDS(i-1), datesCDS(i), day_count);
end

% -------------------------------------------------------------------------
% BOOTSTRAPPING PROCEDURE
% -------------------------------------------------------------------------
% CASE 1: flag == 1 (Neglecting the Accrual on Default)
% -------------------------------------------------------------------------
if flag == 1 

    % We loop over each CDS maturity i, bootstrapping P(t0, ti).
    for i = 1:N
        
        % S_N is the CDS spread for maturity datesCDS(i).
        S_N = spreadsCDS(i);
        
        % sum_fee_passed accumulates the fee leg contributions from
        % previous intervals
        % Each term is: delta_j * B(t0, t_j) * P(t0, t_j)
        sum_fee_passed = 0;
        
        % sum_cont_passed accumulates the contingent leg contributions
        % from previous intervals 
        % Each term is: B(t0, t_j) * [P(t0, t_{j-1}) - P(t0, t_j)]
        % which represents the discounted probability of default in
        % (t_{j-1}, t_j].
        sum_cont_passed = 0;
        
        % We compute the sums up to the last known survival probability
        % (everything is known up to t_{i-1}).
        for j = 1:(i-1)
            
            % P_j = P(t0, t_j)
            P_j = survProbs(j);
            
            % P_{j-1} = P(t0, t_{j-1})
            % For j = 1, t_{j-1} = t0, so P(t0, t0) = 1.
            if j == 1
                P_j_minus_1 = 1.0; % P(t0, t0) = 1
            else
                P_j_minus_1 = survProbs(j-1);
            end
            
            % We add the fee leg contribution for interval j:
            % delta_j * B(t0, t_j) * P(t0, t_j)
            sum_fee_passed = sum_fee_passed + deltas(j) * B(j) * P_j;
            
            % We add the contingent leg contribution for interval j:
            % B(t0, t_j) * [P(t0, t_{j-1}) - P(t0, t_j)]
            sum_cont_passed = sum_cont_passed + B(j) * (P_j_minus_1 - P_j);
        end
        
        % We define P_i_minus_1 = P(t0, t_{i-1}).
        % For i = 1, t_{i-1} = t0, so P(t0, t0) = 1.
        if i == 1
            P_i_minus_1 = 1.0;
        else
            P_i_minus_1 = survProbs(i-1);
        end
        
        % We impose the NPV of fee leg is equal to NPV of the contingent leg
        % (1 - recovery) * [sum_cont_passed + B(t0, t_i) * (P_i_minus_1 - P_i)]
        % = S_N * [sum_fee_passed + delta_i * B(t0, t_i) * P_i]
        %
        % We solve for P_i = P(t0, t_i): 
        % P_i = Num / Den, where Num and Den are defined below
        
        Num = (1 - recovery) * sum_cont_passed ...
              - S_N * sum_fee_passed ...
              + (1 - recovery) * B(i) * P_i_minus_1;  % Numerator
              
        Den = B(i) * (S_N * deltas(i) + (1 - recovery)); % Denominator
        
        % We compute the unknown survival probability P(t0, t_i).
        survProbs(i) = Num / Den;
        
        % Once we have P(t0, t_i) and P(t0, t_{i-1}), we can ecompute λ_i
        % from:  
        %       P(t0, t_i) = P(t0, t_{i-1}) * exp(-λ_i * delta_i)
        % Rearranging:
        %       λ_i = - (1 / delta_i) * log( P(t0, t_i) / P(t0, t_{i-1}) )
        intensities(i) = -log(survProbs(i) / P_i_minus_1) / deltas(i);
    end

% -------------------------------------------------------------------------
% CASE 2: flag == 2  (Including the Accrual on Default)
% -------------------------------------------------------------------------
elseif flag == 2
    
     for i = 1:N
        
        % S_N is the CDS spread for maturity datesCDS(i).
        S_N = spreadsCDS(i);
        
        % sum_fee_passed: fee leg contributions from previous intervals.
        sum_fee_passed = 0;
        
        % sum_cont_passed: contingent leg contributions from previous intervals.
        sum_cont_passed = 0;
        
        % sum_accrual_passed: accrued premium contributions from previous intervals.
        sum_accrual_passed = 0;
        
        % We compute the sums up to the last known survival probability
        % (everything is known up to t_{i-1}).
        for j = 1:(i-1)
            
            P_j = survProbs(j); % P_j = P(t0, t_j)
            
            if j == 1
                P_j_minus_1 = 1.0; % P(t0, t0) = 1
            else
                P_j_minus_1 = survProbs(j-1); % P_{j-1} = P(t0, t_{j-1})
            end
            
            % Fee leg contribution for interval j:
            sum_fee_passed = sum_fee_passed + deltas(j) * B(j) * P_j;
            
            % Contingent leg contribution for interval j:
            sum_cont_passed = sum_cont_passed + B(j) * (P_j_minus_1 - P_j);
            
            % Accrual on default contribution for interval j:
            % Approximated as delta_j/2 * B(t0, t_j) * [P(t0, t_{j-1}) - P(t0, t_j)]
            sum_accrual_passed = sum_accrual_passed + deltas(j)/2 * B(j) * (P_j_minus_1 - P_j);
        end
        
        % Previous survival probability
        if i == 1
            P_i_minus_1 = 1.0;
        else
            P_i_minus_1 = survProbs(i-1);
        end
        
        % Now we write the NPV of the CDS including accrual on default.
        % The premium leg includes:
        %   - regular coupons: sum_fee_passed + delta_i * B(t0, t_i) * P_i
        %   - accrued coupons on default: sum_accrual_passed + delta_i/2 * B(t0, t_i) * (P_i_minus_1 - P_i)
        %
        % The contingent leg is the same as before.
        %
        % We solve for P_i = Num / Den
        %
        Num = (1 - recovery) * sum_cont_passed ...
              - S_N * (sum_fee_passed + sum_accrual_passed) ...
              - S_N * deltas(i) * B(i) * P_i_minus_1 / 2 ...
              + (1 - recovery) * B(i) * P_i_minus_1;
          
        Den = B(i) * (S_N * deltas(i)/2 + (1 - recovery));
        
        % We compute the unknown survival probability P(t0, t_i)
        survProbs(i) = Num / Den;
        
        % We compute λ_i as before
        intensities(i) = -log(survProbs(i) / P_i_minus_1) / deltas(i);
    end

% -------------------------------------------------------------------------
% CASE 3: flag == 3  (Jarrow–Turnbull Approximation)
% -------------------------------------------------------------------------
elseif flag == 3
         
    % Compute intensities directly λ_i ≈ S_i / (1 - recovery)
    % where  S_i = spreadsCDS(i)
    intensities = spreadsCDS ./ (1 - recovery);
    
    % We compute survival probabilities as:
    % P(t0, t_i) = exp( - λ_i * yearfrac(t0, t_i) )
    % with ACT/365 convention
    for i = 1:N
        yf = yearfrac(t0, datesCDS(i), day_count);
        survProbs(i) = exp(-intensities(i) * yf);
    end
end

end