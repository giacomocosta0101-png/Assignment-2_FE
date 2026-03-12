function discount_interp = get_discount_factor_by_zero_rates_linear_interp(reference_date, interp_date, dates, discounts)

zero_rates = from_discount_factors_to_zero_rates(reference_date, dates, discounts);

day_count = 3; % ACT/365

year_frac_dates = yearfrac(reference_date, dates, day_count);
year_frac_interp = yearfrac(reference_date, interp_date, day_count);

zero_interp = interp1(year_frac_dates, zero_rates, year_frac_interp, 'linear');

% flat extrapolation
zero_interp(year_frac_interp < year_frac_dates(1))   = zero_rates(1);
zero_interp(year_frac_interp > year_frac_dates(end))  = zero_rates(end);

discount_interp = exp(-zero_interp .* year_frac_interp);

end

