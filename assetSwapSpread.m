function s = assetSwapSpread(reference_date, maturity, issue_date, coupon, faceValue, cleanPrice, dates, discounts)

BPV_floating = BasisPointValueFloating(reference_date, maturity, dates, discounts);

BPV_fixed = BasisPointValueFixed(reference_date, issue_date,maturity, dates, discounts);

maturity_adj = business_date_offset(maturity, convention = 'modified_following');

df_maturity = get_discount_factor_by_zero_rates_linear_interp(reference_date, ...
    maturity_adj, dates, discounts);

price_not_default = coupon * BPV_fixed + faceValue * df_maturity; % FIX: faceValue=1
accrual = coupon * yearfrac(issue_date, reference_date, 6);
dirty_price = cleanPrice/100 + accrual; % FIX: cleanPrice in decimali

s = (price_not_default - dirty_price) / BPV_floating;

end

