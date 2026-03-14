function s = assetSwapSpread(reference_date, maturity, ...
    issue_date, coupon, faceValue, cleanPrice, dates, discounts)
% Compute the Asset Swap Spread (ASW)
%
% INPUTS:
% reference_date : valuation date
% maturity       : bond maturity date
% issue_date     : bond issue date
% coupon         : annual coupon rate
% faceValue      : face value of the bond
% cleanPrice     : clean price quoted in percentage
% dates          : Vector of dates used for the discount curve
% discounts      : Vector of discount factors corresponding to dates
%
% OUTPUT:
% s : Asset Swap Spread

% We compute the Basis Point Value of the floating leg
BPV_floating = BasisPointValueFloating(reference_date, maturity, dates, discounts);

% We compute the Basis Point Value of the fixed leg
BPV_fixed = BasisPointValueFixed(reference_date, issue_date, maturity, dates, discounts);

% We compute the adjusted maturity date using modified following convention
maturity_adj = business_date_offset(maturity, convention = 'modified_following');

% We compute the discount factor at maturity
df_maturity = get_discount_factor_by_zero_rates_linear_interp(reference_date, ...
    maturity_adj, dates, discounts);

% We compute the theoretical price without default risk:
% Present value of coupons + present value of the face value
price_not_default = coupon * BPV_fixed + faceValue * df_maturity;

% We compute the accrual from the issue date to valuation date
% using 30/360 day count convention
accrual = coupon * yearfrac(issue_date, reference_date, 6);

% We compute the dirty market price by summing the clean price (not in
% percentage) and the accrual
% since the clean price is quoted in percentage, we divide it by 100
dirty_price = cleanPrice/100 + accrual;

% We compute the Asset Swap Spread
s = (price_not_default - dirty_price) / BPV_floating;

end