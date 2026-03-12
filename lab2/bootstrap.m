function [dates, discounts, zeroRates]=bootstrap(datesSet, ratesSet)

reference_date = datesSet.settlement;

% select the correct depos and their rates
% We make a list of the depo dates we will use for bootstrapping
day_count_depos = 2;
mask = datesSet.futures(1,1);
depo_dates = datesSet.depos(datesSet.depos<mask);

depo_rates = mean(ratesSet.depos,2); % Compute the mean BID ASK

% We make an array of the depo rates needed 
depo_rates = depo_rates(1:length(depo_dates));

% convert rate L(t0,ti) to discount B(t0,ti) and append the results to the current list of dates and discounts
discounts = 1./(1+yearfrac(reference_date,depo_dates,day_count_depos).*depo_rates); % FIX: ./ instead of /

% We update the terminal dates vector:

dates = depo_dates;
      
% FUTURES

day_count_futures = day_count_depos;

% We keep only futures whose settle date is before or equal to the 2y swap maturity
mask_futures = datesSet.swaps(2); %We select as limit the two year swap expiry

% select the correct futures and their rates
future_dates_expiry = datesSet.futures(datesSet.futures(:,2)<=mask_futures,2);
future_dates_settle = datesSet.futures(1:length(future_dates_expiry),1);

% Futures price = 100 - fwd rate -> fwd rate = (100 - Price)
% We compute the mean of BID ASK

rates_futures = mean(ratesSet.futures,2);
rates_futures = rates_futures(1:length(future_dates_expiry));

%  We make a cycle to compute, from the fwd rate (ti-1,ti) the discount factors at ti:
% convert the forward rates L(t0;ti-1, ti) to the forward discount B(t0;ti-1,ti)

yearfrac_futures = yearfrac(future_dates_settle,future_dates_expiry,day_count_futures);
fwd_discounts = 1./(1+yearfrac_futures.*rates_futures); % FIX: ./ instead of /

i = 1;
for t_start = future_dates_settle'  % FIX: transpose to iterate over rows
    
    if (any(ismember(dates, t_start)))
        discount_start = discounts(ismember(dates, t_start)); % FIX: was discounts(end), wrong index
    else
        discount_start = get_discount_factor_by_zero_rates_linear_interp(reference_date,t_start,dates,discounts);
    end
    
    discount_end = fwd_discounts(i)*discount_start;

    discounts = [discounts; discount_end];
    dates = [dates; future_dates_expiry(i)]; % FIX: append before incrementing i

    i = i + 1; % FIX: moved after append, was causing off-by-one

end
%% SWAP

swap_2years = datesSet.swaps(2);
dates_swaps = datesSet.swaps(datesSet.swaps>=swap_2years);

rates_swaps = mean(ratesSet.swaps,2);
rates_swaps = rates_swaps(datesSet.swaps>=swap_2years); % FIX: was rates_swaps(2:end), now aligned to dates_swaps

i = 1;

day_count_swap = 6; % FIX: was 1 (ACT/ACT), should be 6 (30E/360) for swaps

for swap_expiry = dates_swaps'  % FIX: transpose to iterate over rows
    
    rate = rates_swaps(i);
    coupon_dates = [];
    BPV = 0;

    for year = 1:51
        d_pay = datenum(datetime(reference_date, 'ConvertFrom', 'datenum') + calyears(year));
        d_pay = busdate(d_pay, "follow", holidays);
        coupon_dates = [coupon_dates; d_pay];
        
        if d_pay>=swap_expiry 
            break
        end
    end

    % We make a control: it can happen that the 2y-swap maturity has been covered 
    % by the futures bootstrapping, so we check: if it has happened so, we skip the iteration:
    if swap_expiry <= dates(end)
        i = i + 1;
        continue
    end
    
    for n = 1:(length(coupon_dates)-1)
        
        if n ==1
            t_prev = reference_date;
        else
            t_prev = coupon_dates(n-1);
        end
        
        t_curr = coupon_dates(n);
        yf = yearfrac(t_prev,t_curr,day_count_swap);

        if (any(ismember(dates, t_curr))) % FIX: was t_start (undefined in this scope)
            idx = find(dates == t_curr); % FIX: was t_start
            df = discounts(idx);
        else
            df = get_discount_factor_by_zero_rates_linear_interp(reference_date,t_curr,dates,discounts);
        end
        
        BPV = BPV + df*yf;

    end

    t_last_prev = coupon_dates(end-1); % FIX: was coupon_date(n-2) — typo + wrong index
    yf_final = yearfrac(t_last_prev, swap_expiry, day_count_swap); % FIX: was year_frac_30e_360 (undefined function)

    % Bootstrap formula: B(t0,TN) = (1 - R * BPV) / (1 + R * yf_N)
    % derived from par swap condition: 1 = R * sum(yf_i * B_i) + B_N

    df = (1.0 - rate * BPV) / (1.0 + rate * yf_final);
    
    %We store terminal dates and discount factors
    dates = [dates; swap_expiry]; % FIX: was missing semicolon
    discounts = [discounts; df]; % FIX: was discounts.append(df) — Python syntax

    i = i + 1;



end

zeroRates = from_discount_factors_to_zero_rates(reference_date,dates,discounts);

dates = [reference_date; dates];
zeroRates = [0; zeroRates];
discounts = [1; discounts];


end