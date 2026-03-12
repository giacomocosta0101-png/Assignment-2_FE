function PnL = computePnL(N, R_trader, R_bank, R_fair, dates, discounts)

reference_date = dates(1);
day_count_swap = 6; % 30/360

maturity6y = business_date_offset(reference_date, year_offset = 6);
coupon_dates = couponSchedule(reference_date, maturity6y);

BPV = 0;
for i = 1:length(coupon_dates)
    if i == 1
        t_prev = reference_date;
    else
        t_prev = coupon_dates(i-1);
    end
    yf = yearfrac(t_prev, coupon_dates(i), day_count_swap);
    df = get_discount_factor_by_zero_rates_linear_interp(...
         reference_date, coupon_dates(i), dates, discounts);
    BPV = BPV + df * yf;
end

PnL.bank = N * (R_trader - R_bank) * BPV;
PnL.fair = N * (R_trader - R_fair) * BPV;
PnL.net  = PnL.bank - PnL.fair;

end