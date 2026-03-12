function zero_rates = from_discount_factors_to_zero_rates(reference_date,dates,discounts)

day_count = 3; %ACT 365 for zero rates

year_frac = yearfrac(reference_date,dates,day_count);

zero_rates = -log(discounts)./year_frac; % FIX: ./ instead of /

end