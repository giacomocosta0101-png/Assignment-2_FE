function PnL = computePnL(N, R_trader, R_bank, R_fair, dates, discounts)
% Compute bank, fair, and net PnL of a 6Y par swap.
%
% INPUTS:
%  N          : Notional of the swap
%  R_trader   : Rate received by the trader.
%  R_bank     : Rate used by the bank
%  R_fair     : Fair rate implied by the bootstrapped discount curve
%  dates      : Vector of dates used for the discount curve 
%  discounts  : Vector of discount factors corresponding to dates
%
% OUTPUT:
%  PnL        : Struct with three fields:
%               PnL.bank  = PnL versus bank rate
%               PnL.fair  = PnL versus fair rate
%               PnL.net   = Difference between bank and fair PnL
%

reference_date = dates(1);
day_count_swap = 6; % day count 30/360

% Compute the 6-year maturity date by adding 6 calendar years to the reference date.
% This is needed because the exit condition in couponSchedule compares unadjusted dates.
 maturity6y = reference_date + calyears(6);

% We generate the vector of dates (between reference_date and maturity6y) 
% in which we receive a coupon payment:

coupon_dates = couponSchedule(reference_date, maturity6y);

% We initialize the basis point value:

BPV = 0;

for i = 1:length(coupon_dates)

    % we select the previous date in which we have received a coupon
    % payment
    if i == 1
        % for the first coupon, the previous date is the reference date 
        t_prev = reference_date; 
    else
        t_prev = coupon_dates(i-1);
    end

    % We compute the year fraction between the previous date and the current coupon date
    % under the 30/360 convention.
    yf = yearfrac(t_prev, coupon_dates(i), day_count_swap);

    % We compute the discount factor for the current coupon date, obtained by
    % the discount curve 
    df = get_discount_factor_by_zero_rates_linear_interp(...
         reference_date, coupon_dates(i), dates, discounts);

    % We update the BPV 
    BPV = BPV + df * yf;
end

% We compute the PnL versus the bank rate as notional times rate difference times BPV
PnL.bank = N * (R_trader - R_bank) * BPV;

% We compute the PnL versus the fair rate implied by the bootstrapped discount curve
PnL.fair = N * (R_trader - R_fair) * BPV;

% We compute how much the trader gains/losses versus the bank after
% accounting for the fair rate

PnL.net  = PnL.bank - PnL.fair;

end