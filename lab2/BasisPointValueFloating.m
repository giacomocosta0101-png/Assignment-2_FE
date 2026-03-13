function BPV = BasisPointValueFloating(reference_date, maturity_date, dates, discounts)

    if isdatetime(maturity_date)
        maturity_date = datenum(maturity_date);
    end
    if isdatetime(reference_date)
        reference_date = datenum(reference_date);
    end
        
    current_dt = datetime(maturity_date, 'ConvertFrom', 'datenum');
    unadj_dates = datenum(current_dt);
    
    prev_dt = current_dt;
    
    while true
    
        if datenum(prev_dt) <= reference_date
    
            break
        end
    
        prev_dt = current_dt - calmonths(3);
        
        current_dt = prev_dt;
        unadj_dates = [datenum(current_dt); unadj_dates];
    end
    
    adj_dates = unadj_dates;
    discount_floating = zeros(length(adj_dates),1);
    
    for i = 1:length(adj_dates)
        adj_dates(i) = business_date_offset(unadj_dates(i), ...
            'convention', 'modified_following');
    end
    
    BPV = 0;
    for i = 2:length(adj_dates)
        discount_floating(i) = get_discount_factor_by_zero_rates_linear_interp( ...
            reference_date, adj_dates(i), dates, discounts);
        yf  = yearfrac(adj_dates(i-1), adj_dates(i), 2);
        BPV = BPV + yf * discount_floating(i);
    end

end

