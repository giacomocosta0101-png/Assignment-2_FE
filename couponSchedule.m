function coupon_dates = couponSchedule(reference_date, T)

coupon_dates = [];
d = 0;

for y = 1:60
    % 1) Aggiungi 1 anno, 2 anni, 3 anni, ...
    d = d + business_date_offset(reference_date,year_offset = 1);

    % 3) Aggiungi la data 
    coupon_dates = [coupon_dates; d];

    % 4) Se abbiamo raggiunto la scadenza → stop
    if d >= T
        break
    end
end

end