function [dates, discounts, zeroRates] = bootstrap(datesSet, ratesSet)

% BOOTSTRAP  Constructs a discount factor curve via bootstrapping
%
%   The curve is built in three stages:
%   
%   1) Deposit rates        — short end of the curve
%   2) Futures rates        — intermediate maturities (up to 2Y swap)
%   3) Swap rates           — long end of the curve
%
%   INPUTS:
%   datesSet   – struct with fields:
%                  .settlement  : settlement date (datenum)
%                  .depos       : vector of deposit maturity dates
%                  .futures     : Nx2 matrix [settle_date, expiry_date]
%                  .swaps       : vector of swap maturity dates
%   ratesSet   – struct with fields:
%                  .depos       : Nx2 matrix of deposit rates [BID, ASK]
%                  .futures     : Nx2 matrix of futures rates [BID, ASK]
%                  .swaps       : Nx2 matrix of swap rates   [BID, ASK]
%
%   OUTPUTS:
%   dates      – vector of dates (including settlement at position 1)
%   discounts  – corresponding discount factors (1 at settlement)
%   zeroRates  – corresponding zero rates (0 at settlement)

%% ========================================================================
%  DEPOS
%  ========================================================================

reference_date = datesSet.settlement;

% Day-count convention for deposits (ACT/360)
day_count_depos = 2;

% Use only deposit maturities that fall before the first futures settlement
mask = datesSet.futures(1,1);
depo_dates = datesSet.depos(datesSet.depos < mask);

% Mid-market deposit rates (average of BID and ASK)
depo_rates = mean(ratesSet.depos, 2);
depo_rates = depo_rates(1:length(depo_dates));

% Convert simple deposit rates L(t0,ti) to discount factors B(t0,ti):
%   B(t0,ti) = 1 / (1 + delta(t0,ti) * L(t0,ti))
discounts = 1 ./ (1 + yearfrac(reference_date, depo_dates, day_count_depos) .* depo_rates);

% Initialise the output dates vector
dates = depo_dates;

%% ========================================================================
%  FUTURES
%  ========================================================================

day_count_futures = day_count_depos;

% Keep only futures whose expiry falls on or before the 2-year swap
% maturity:

mask_futures = datesSet.swaps(2);
future_dates_expiry  = datesSet.futures(datesSet.futures(:,2) <= mask_futures, 2);
future_dates_settle  = datesSet.futures(1:length(future_dates_expiry), 1);

% Mid-market futures rates (from price: fwd rate = 100 - Price)
rates_futures = mean(ratesSet.futures, 2);
rates_futures = rates_futures(1:length(future_dates_expiry));

% Year fractions between each futures settlement and expiry:
yearfrac_futures = yearfrac(future_dates_settle, future_dates_expiry, day_count_futures);

% Forward discount factors B(t0; ti-1, ti) from forward rates:

fwd_discounts = 1 ./ (1 + yearfrac_futures .* rates_futures);

% Iteratively chain forward discounts to obtain spot discount factors

i = 1;
for t_start = future_dates_settle'

    % Retrieve the discount factor at the futures settlement date
    if (any(ismember(dates, t_start)))
        % Exact match in the already-bootstrapped curve
        discount_start = discounts(ismember(dates, t_start));
    else
        % Interpolate on zero rates to get the discount factor
        discount_start = get_discount_factor_by_zero_rates_linear_interp( ...
            reference_date, t_start, dates, discounts);
    end

    % Spot discount at expiry = fwd discount * spot discount at settlement
    discount_end = fwd_discounts(i) * discount_start;

    % We store the results into discounts and dates:

    discounts = [discounts; discount_end];
    dates     = [dates; future_dates_expiry(i)];

    i = i + 1;

end

%% ========================================================================
%  SWAPS
%  ========================================================================

% Select swap maturities from 2Y swap expiry:

swap_2years  = datesSet.swaps(2);
dates_swaps  = datesSet.swaps(datesSet.swaps >= swap_2years);

% Mid-market swap rates:

rates_swaps = mean(ratesSet.swaps, 2);
rates_swaps = rates_swaps(datesSet.swaps >= swap_2years);

i = 1;

% Day-count convention for swaps (30E/360)
day_count_swap = 6;

for swap_expiry = dates_swaps'

    rate = rates_swaps(i);

    % Build the vector of annual coupon dates:

    coupon_dates = [];
    BPV = 0;

    for year = 1:51
        d_pay = datenum(datetime(reference_date, 'ConvertFrom', 'datenum') + calyears(year));
        d_pay = busdate(d_pay, "follow", holidays);
        coupon_dates = [coupon_dates; d_pay];

        if d_pay >= swap_expiry
            break
        end
    end

    % If the 2Y swap maturity was already covered by the futures strip,
    % skip this iteration

    if swap_expiry <= dates(end)
        i = i + 1;
        continue
    end

    % Compute the BPV (sum of delta_i * B_i) for all but the last period
    for n = 1:(length(coupon_dates) - 1)

        if n == 1
            t_prev = reference_date;
        else
            t_prev = coupon_dates(n - 1);
        end

        t_curr = coupon_dates(n);
        yf = yearfrac(t_prev, t_curr, day_count_swap);

        % we search for an already computed discounted factor. If not we
        % interpolate the discount factor at this coupon date

        if (any(ismember(dates, t_curr)))
            idx = find(dates == t_curr);
            df  = discounts(idx);
        else
            df = get_discount_factor_by_zero_rates_linear_interp( ...
                reference_date, t_curr, dates, discounts);
        end

        BPV = BPV + df * yf;

    end

    % Year fraction for the last coupon period:

    t_last_prev = coupon_dates(end - 1);
    yf_final    = yearfrac(t_last_prev, swap_expiry, day_count_swap);

    % Bootstrap the discount factor at swap maturity from the par-swap condition:
    %   1 = R * BPV + (1 + R * delta_N) * B(t0, TN)
    %   =>  B(t0, TN) = (1 - R * BPV) / (1 + R * delta_N):

    df = (1.0 - rate * BPV) / (1.0 + rate * yf_final);

    % we store the results:
    
    dates     = [dates; swap_expiry];
    discounts = [discounts; df];

    i = i + 1;

end

%% ========================================================================
%  ZERO RATES
%  ========================================================================

% Convert the full set of discount factors to continuously-compounded zero rates
zeroRates = from_discount_factors_to_zero_rates(reference_date, dates, discounts);

% Prepend the settlement date with discount = 1 and zero rate = 0
dates     = [reference_date; dates];
zeroRates = [0; zeroRates];
discounts = [1; discounts];

end