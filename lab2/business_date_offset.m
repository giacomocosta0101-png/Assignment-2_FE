function adjusted_date = business_date_offset(base_date, varargin)
    % FIX: accetta sia datenum (double) che datetime
    if isdatetime(base_date)
        base_date = datenum(base_date);
    end
    % BUSINESS_DATE_OFFSET Return the closest following business date after applying offset
%
% Parameters:
%   base_date (double): Reference date as MATLAB serial date number
%   year_offset (int, optional): Number of years to add (default: 0)
%   month_offset (int, optional): Number of months to add (default: 0)
%   day_offset (int, optional): Number of days to add (default: 0)
%   convention (string, optional): Business day convention ('following' or 'modified_following', default: 'following')
%
% Returns:
%   adjusted_date (double): Closest following business date as serial number
%
% Example:
%   adjusted = business_date_offset(datenum('15-Mar-2024'), 'year_offset', 1, 'month_offset', 2);
%   adjusted = business_date_offset(datenum('31-May-2024'), 'year_offset', 1, 'convention', 'modified_following');
% Parse optional arguments
    p = inputParser;
    addParameter(p, 'year_offset', 0, @isnumeric);
    addParameter(p, 'month_offset', 0, @isnumeric);
    addParameter(p, 'day_offset', 0, @isnumeric);
    addParameter(p, 'convention', 'following', @ischar);
    parse(p, varargin{:});
    year_offset = p.Results.year_offset;
    month_offset = p.Results.month_offset;
    day_offset = p.Results.day_offset;
    convention = lower(p.Results.convention);
% Convert serial date to datetime for easier manipulation
    base_dt = datetime(base_date, 'ConvertFrom', 'datenum');
% Extract year, month, day
    [y, m, d] = ymd(base_dt);
% Adjust year and month
    total_months = m + month_offset;
    year_add = floor((total_months - 1) / 12);
    new_month = mod(total_months - 1, 12) + 1;
    new_year = y + year_offset + year_add;
% Handle invalid day (e.g., Feb 31 -> Feb 28/29)
    last_day = eomday(new_year, new_month);
    new_day = min(d, last_day);
% Create adjusted date
    adjusted_dt = datetime(new_year, new_month, new_day) + days(day_offset);
% Convert back to serial date number
    adjusted_date = datenum(adjusted_dt);
% Store the target month for modified following check
    target_month = month(adjusted_dt);
    target_year = year(adjusted_dt);
% Adjust to business day based on convention
if strcmp(convention, 'modified_following')
% Modified Following: move forward, but if it crosses month boundary, move backward
while ~isbusday(adjusted_date)
            adjusted_date = adjusted_date + 1;
end
% Check if we've moved to a different month
        adjusted_dt_check = datetime(adjusted_date, 'ConvertFrom', 'datenum');
if month(adjusted_dt_check) ~= target_month || year(adjusted_dt_check) ~= target_year
% We crossed into next month, so go backward instead
            adjusted_date = datenum(datetime(target_year, target_month, new_day));
while ~isbusday(adjusted_date)
                adjusted_date = adjusted_date - 1;
end
end
else
% Default Following: just move forward to next business day
while ~isbusday(adjusted_date)
            adjusted_date = adjusted_date + 1;
end
end
end