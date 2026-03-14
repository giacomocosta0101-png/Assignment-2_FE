function BPV = BasisPointValueFixed(reference_date, issue_date, maturity_date, dates, discounts)
% Basis Point Value of a fixed-rate bond (annual coupons), with modified
% following unadjusted convention
%
%   BPV = BasisPointValueFixed(reference_date, issue_date, maturity_date, dates, discounts)
%
%   Computes the BPV (annuity factor) of a fixed-coupon bond paying annual
%   coupons with unadjusted year fractions (yf = 1 for every period).
%   The BPV equals the present value of a 1-unit annuity on the coupon
%   schedule:
%
%       BPV = sum_{i=1}^{N}  delta_i * B(t0, t_i)
%
%   with delta_i = 1 (unadjusted annual) and B(t0, t_i) obtained by
%   linear interpolation on the supplied zero-rate curve.
%
%   Coupon dates are generated annually from the issue date, adjusted with
%   the Modified Following business-day convention; the loop stops at the
%   first coupon date that reaches or exceeds the (adjusted) maturity.
%
%   INPUTS:
%       reference_date – valuation date (datenum or datetime)
%       issue_date     – bond issue date (datenum or datetime)
%       maturity_date  – bond maturity date (datenum or datetime)
%       dates          – Nx1 vector of curve dates (datenum)
%       discounts      – Nx1 vector of discount factors on those dates
%
%   OUTPUT:
%       BPV – scalar, the basis point value (annuity factor)

% Convert datetime inputs to datenum if necessary
if isdatetime(maturity_date)
    maturity_date = datenum(maturity_date);
end
if isdatetime(reference_date)
    reference_date = datenum(reference_date);
end

BPV = 0;

% Year fraction is always 1 (unadjusted annual coupon schedule)

yf = 1;

% Adjust the maturity date to a valid business day (Modified Following)
maturity_adj = business_date_offset(maturity_date, convention = 'modified_following');

% Loop over annual coupon dates starting from the issue date
for y = 1:60

    % Coupon date = issue date + y years, adjusted Modified Following
    d = business_date_offset(issue_date, year_offset = y, convention = 'modified_following');

    % Discount factor at this coupon date via zero-rate interpolation
    df = get_discount_factor_by_zero_rates_linear_interp(reference_date, d, dates, discounts);

    % Accumulate the present value of the coupon period
    BPV = BPV + df * yf;

    % Stop once we reach the maturity payment date
    if d >= maturity_adj
        break
    end

end

end