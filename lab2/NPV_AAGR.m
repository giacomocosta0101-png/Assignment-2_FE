function NPV = NPV_AAGR(datesCF, startCF, reference_date, AAGR, CF0, dates, discounts)
% Compute the Net Present Value of a series of monthly cash flows
% that grow every year according to a fixed Average Annual Growth Rate
%
% INPUTS:
% datesCF        : vector of monthly cash‑flow payment dates
% startCF        : starting date of the cash‑flow schedule 
% reference_date : valuation date used for discounting
% AAGR           : annual growth rate applied once per year (in March)
% CF0            : initial monthly cash flow
% dates          : vector of dates used for the discount curve 
% discounts      : vector of discount factors corresponding to dates
%
% OUTPUT:
% NPV            : present value of the entire cash‑flow stream
%

% We convert datetime inputs to serial numbers if needed
if isdatetime(datesCF)
    datesCF = datenum(datesCF);
end
if isdatetime(startCF)
    startCF = datenum(startCF);
end

% We extract the starting year from the starting date of the cash‑flow schedule 
[startYear, ~, ~] = datevec(startCF);

% We preallocate the cash‑flow vector
CF = zeros(size(datesCF));

for i = 1:length(datesCF)
    % We select the i-th payment date
    t = business_date_offset(datesCF(i),convention = 'modified_following');

    % For the selected date, we extract the corresponding year (y) and month (m)
    [y, m, ~] = datevec(t);

    % We compute the number of years passed from the start year
    years_passed = y - startYear;

    % Since the growth rate is applied only in March, we check if the payment
    % month is January or February or not
    if m < 3 
        % If it's January or February, we decrease the count of growth years 
        % because payments in these months occur before the annual increase 
        % applied in March
        years_passed = years_passed - 1;
    end

    % We ensure non‑negative number of years
    years_passed = max(years_passed, 0);

    % We apply annual growth to the initial monthly cash flow
    CF(i) = CF0 * (1 + AAGR)^years_passed;
end

% We initialize the Net Present value
NPV = 0;

for i = 1:length(datesCF)
    % We compute the discount factor for the specific payment date
    df = get_discount_factor_by_zero_rates_linear_interp( ...
            reference_date, datesCF(i), dates, discounts);

    % We add the discounted cash flow to the NPV
    NPV = NPV + CF(i) * df;
end

end