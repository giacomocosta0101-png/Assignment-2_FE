function zero_rates = from_discount_factors_to_zero_rates(reference_date, dates, discounts)
% Convert discount factors into zero rates
%
% INPUTS:
% reference_date : Valuation date
% dates              : Vector of dates used for the discount curve 
% discounts          : Vector of discount factors corresponding to dates
% 
% OUTPUT:
% zero_rates     : Vector of continuously compounded zero rates
%                   

day_count = 3; % ACT/365 convention

% We compute year fractions from reference_date to each date in dates
year_frac = yearfrac(reference_date, dates, day_count);

% We convert discount factors to continuously compounded zero rates
zero_rates = -log(discounts) ./ year_frac;

end
