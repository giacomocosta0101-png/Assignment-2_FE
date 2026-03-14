function BPV = BasisPointValueFloating(reference_date, maturity_date, dates, discounts)
% Compute the Basis Point Value (BPV) of the floating leg of a swap.
%
% INPUTS:
% reference_date : Valuation date (datetime or datenum)
% maturity_date  : Maturity date of the swap (datetime or datenum)
% dates          : Curve dates used for discounting (datenum)
% discounts      : Discount factors corresponding to 'dates'
%
% OUTPUT:
% BPV            : Basis Point Value of the floating leg

% We convert datenum to datetime if needed
if ~isdatetime(maturity_date)
    maturity_date = datetime(maturity_date, 'ConvertFrom', 'datenum');
end
if ~isdatetime(reference_date)
    reference_date = datetime(reference_date, 'ConvertFrom', 'datenum');
end
    
% We start from the maturity date
current_dt = maturity_date;

% We store the first unadjusted date (as datenum)
unadj_dates = datenum(current_dt);

% We build the floating schedule backwards in 3‑month increments
while true
    % We compute the previous unadjusted date: subtract 3 calendar months
    prev_dt = current_dt - calmonths(3);

    % We stop if the previous date is before or equal to the valuation date
    if datenum(prev_dt) <= datenum(reference_date)
       break
    end

    % We move backward in time
    current_dt = prev_dt;

    % We store the unadjusted date (as datenum)
    unadj_dates = [datenum(current_dt); unadj_dates];
end

% We initialize adjusted dates, discount factors, and BPV
adj_dates = unadj_dates;
discount_floating = zeros(length(adj_dates),1);
BPV = 0;

for i = 1:length(adj_dates) % Loop over all floating payment dates

    % Apply modified_following adjustment
    adj_dates(i) = business_date_offset(unadj_dates(i), convention = 'modified_following');

    % Compute discount factor for the adjusted date
    discount_floating(i) = get_discount_factor_by_zero_rates_linear_interp( ...
                               datenum(reference_date), ...
                               datenum(adj_dates(i)), ...
                               dates, discounts);

     % We compute ACT/360 year fraction
     if i == 1
        % For the fisrt floating payment we start from the valuation date
        yf = yearfrac(datenum(reference_date), datenum(adj_dates(i)), 2);
     else
        % For the other floating payments we start from previous adjusted date
        yf = yearfrac(datenum(adj_dates(i-1)), datenum(adj_dates(i)), 2);
     end

        % We upload the BPV
        BPV = BPV + yf * discount_floating(i);
end

end