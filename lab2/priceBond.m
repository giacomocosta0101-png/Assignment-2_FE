function [price, dfT] = priceBond(coupon_dates, settlement_date, discounts, FV, couponRate)

for i = 1:length(coupon_dates)
   
    % Year fraction 
    yf = yearfrac(settlement_date,  coupon_dates(i), 1); 

    % discount factor obtained by interpolation from the bootstrapped 
    % discount factor curve
    df = interpDF(settlement_date, coupon_dates(i), discounts);

    % We add to the price the net present value of the coupon
    price = price + FV * couponRate * yf * df;
end

% we consider the face value discounted
dfT = interpDF(reference_date, maturity_8y, dates, discounts);
price = price + FV * dfT;
end