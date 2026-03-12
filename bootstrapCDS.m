function [datesCDS, survProbs, intensities] = bootstrapCDS(datesDF, discounts, datesCDS, spreadsCDS, flag, recovery)
    
    if isdatetime(datesCDS)
        datesCDS = datenum(datesCDS);
    end
    if isdatetime(datesDF)
        datesDF = datenum(datesDF);
    end


    % We initialize the variables:
    
    N = length(datesCDS);
    survProbs = zeros(N, 1);
    intensities = zeros(N, 1);
    
    % We impose that the valuation date is the reference_date, which is the
    % first pillar of the dates array
    
    t0 = datesDF(1); 
    
    % INTERPOLATION OF DISCOUNT FACTORS
    % We have to compute the discount factors related to the maturity of
    % each CDS
    
    i = (1:length(datesCDS))';
    B(i) = get_discount_factor_by_zero_rates_linear_interp(t0, datesCDS(i), datesDF, discounts);

    % We compute the yearfraction: for CDS it is usually used ACT/365
    
    day_count = 3; %ACT/365 
    
    deltas = zeros(N, 1);
    deltas(1) = yearfrac(t0, datesCDS(1), day_count);
    
    for i = 2:N
        deltas(i) = yearfrac(datesCDS(i-1), datesCDS(i), 3);
    end
    
    % BOOTSTRAPPING:

    if flag == 1  % Neglecting the Accrual
        
        for i = 1:N
            S_N = spreadsCDS(i); % We fix the CDS rate
            
            sum_fee_passed = 0; %We store the fee leg: sum(delta(ti-1,ti)*B(to,ti)*survivalprob(ti)
            sum_cont_passed = 0; % We store the contingent leg: sum(B(ti)*P(ti-1<default<ti)
            
            % We compute the sum up to the last iteration (everything is
            % known up to ti-1):

            for j = 1:(i-1)
                % P_j e P_{j-1}
                P_j = survProbs(j);
                
                if j == 1
                    P_j_minus_1 = 1.0; % P(t0) = 1
                else
                    P_j_minus_1 = survProbs(j-1);
                end
                
                sum_fee_passed = sum_fee_passed+ deltas(j) * B(j) * P_j;
                sum_cont_passed = sum_cont_passed + B(j) * (P_j_minus_1 - P_j);

            end
            
            % We define P_i_minus_1 = P(t0,ti-1) 

            if i == 1
                P_i_minus_1 = 1.0;
            else
                P_i_minus_1 = survProbs(i-1);
            end
            
            % We apply the bootstrapping procedure by inverting the CDS
            % NPV's and isolating the only unknown P(t0,ti)

            Num = (1 - recovery) * sum_cont_passed ...
                  - S_N * sum_fee_passed ...
                  + (1 - recovery) * B(i) * P_i_minus_1; %Numerator
                  
            Den = B(i) * (S_N * deltas(i) + (1 - recovery)); %Denominator
            
            % We compute the unknown probability P(t0,ti):

            survProbs(i) = Num / Den;
            
            % We extract the Hazard Rate Piecewise constant from the
            % formula P (t0,ti) = P(t0,ti-1) * exp(-lambda_i *
            % delta(ti-1,ti)):

            intensities(i) = -log(survProbs(i) / P_i_minus_1) / deltas(i);
        end
        
    elseif flag == 2
        for i = 1:N
            S_N = spreadsCDS(i); % We fix the CDS rate
            
            sum_fee_passed = 0; %We store the fee leg: sum(delta(ti-1,ti)*B(to,ti)*survivalprob(ti)
            sum_cont_passed = 0; % We store the contingent leg: sum(B(ti)*P(ti-1<default<ti)
            
            sum_accrual_passed = 0;
            
            % We compute the sum up to the last iteration (everything is
            % known up to ti-1):

            for j = 1:(i-1)
                % P_j e P_{j-1}
                P_j = survProbs(j);
                
                if j == 1
                    P_j_minus_1 = 1.0; % P(t0) = 1
                else
                    P_j_minus_1 = survProbs(j-1);
                end
                
                sum_fee_passed = sum_fee_passed+ deltas(j) * B(j) * P_j;
                sum_cont_passed = sum_cont_passed + B(j) * (P_j_minus_1 - P_j);
                sum_accrual_passed = sum_accrual_passed + deltas(j)/2* B(j)*(P_j_minus_1 - P_j);
            end
        
            % We define P_i_minus_1 = P(t0,ti-1) 

            if i == 1
                P_i_minus_1 = 1.0;
            else
                P_i_minus_1 = survProbs(i-1);
            end
           
            % We apply the bootstrapping procedure by inverting the CDS
            % NPV's and isolating the only unknown P(t0,ti)

            Num = (1 - recovery) * sum_cont_passed ...
                  - S_N * (sum_fee_passed + sum_accrual_passed)...
                  - S_N * deltas(i)*B(i)*P_i_minus_1/2+...
                  + (1 - recovery) * B(i) * P_i_minus_1;
                  
            Den = B(i) * (S_N * deltas(i)/2 + (1 - recovery));


            % We compute the unknown probability P(t0,ti):

            survProbs(i) = Num / Den;
            
            % We extract the Hazard Rate Piecewise constant from the
            % formula P (t0,ti) = P(t0,ti-1) * exp(-lambda_i *
            % delta(ti-1,ti)):

            intensities(i) = -log(survProbs(i) / P_i_minus_1) / deltas(i);
 
            
        end

        
    elseif flag == 3
        % We implement Jarrow-Turnbull         
        % survProbs(i) = exp(- (spreadsCDS(i)/(1-recovery)) * yearfrac(t0, datesCDS(i), day_count) );

        intensities = spreadsCDS ./ (1 - recovery);
        for i = 1:N
            yf = yearfrac(t0, datesCDS(i), day_count);
            survProbs(i) = exp(-intensities(i)*yf);
        end
    end
end