function coupon_dates = couponSchedule(reference_date, T)

% Generate the annual coupon payment dates between the reference date and  
% the maturity date
%
% INPUTS:
% reference_date : Start date of the schedule (valuation date)
% T              : Maturity date 
%
% OUTPUTS:
% coupon_dates   : Vector containing all coupon payment dates
%                  from reference_date up to T

% We convert datenum in datatime if needed

if ~isdatetime(reference_date)
    reference_date = datetime(reference_date, 'ConvertFrom', 'datenum');
end
if ~isdatetime(T)
    T = datetime(T, 'ConvertFrom', 'datenum');
end

% Initialization:

coupon_dates = [];
y = 1; % Counter for the number of years added

% We continue generating dates until maturity is reached

while true

     % We compute the unadjusted coupon date: reference_date + y years
     unadj = reference_date + calyears(y);
     
     % We Stop if the unadjusted date is strictly beyond maturity
     if unadj > T
        break
     end

     % We apply business-day adjustment
     adj = business_date_offset(unadj);

     % We upload the date
     coupon_dates = [coupon_dates; adj];
       
     % We move to next year
     y = y + 1;
 end

end