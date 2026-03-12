function BPV = BasisPointValueFixed(reference_date, issue_date, maturity_date, dates, discounts)

    if isdatetime(maturity_date)
        maturity_date = datenum(maturity_date);
    end

    if isdatetime(reference_date)
        reference_date = datenum(reference_date);
    end

BPV = 0;
yf = 1; % unadjusted: yf is always 1

maturity_adj = business_date_offset(maturity_date,convention = 'modified_following');

for y = 1:60
    
    d = business_date_offset(issue_date, year_offset = y, convention = 'modified_following');
    
    df = get_discount_factor_by_zero_rates_linear_interp(reference_date, d, dates, discounts);
    
    BPV = BPV + df * yf;
    
    if d >= maturity_adj
        break
    end

end

end