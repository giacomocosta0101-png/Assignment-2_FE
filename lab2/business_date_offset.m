function adjusted_date = business_date_offset(base_date, varargin)
% BUSINESS_DATE_OFFSET Compute a business-adjusted date from a base date plus calendar offsets.
%
%   adjusted_date = BUSINESS_DATE_OFFSET(base_date)
%   adjusted_date = BUSINESS_DATE_OFFSET(base_date, Name, Value, ...)
%
%   Applies year, month, and day offsets to a reference date, then rolls the
%   result to the nearest valid business day according to the chosen
%   convention. Weekend and holiday detection relies on MATLAB's ISBUSDAY
%   (Financial Toolbox).
%
%   Input: calendar date (MATLAB serial date number or datetime scalar)
%
%   Name-Value Parameters (Optional):
%       'year_offset'   - Integer number of years to add  (default: 0).
%       'month_offset'  - Integer number of months to add (default: 0).
%       'day_offset'    - Integer number of days to add   (default: 0).
%       'convention'    - Business-day roll convention (default: 'following'):
%               'following'           - roll forward to the next business day.
%               'modified_following'  - roll forward, but if that crosses the
%                                       month boundary, roll backward instead.
%
%   Output:
%       adjusted_date: Adjusted business date returned as a serial date number

    %% 1. Read inputs
    % We convert datetime to datenum if needed (we always work with serial dates):
    if isdatetime(base_date)
        base_date = datenum(base_date);
    end

    % We put at zero the optional parameters which have not been present at input:
    p = inputParser;
    addParameter(p, 'year_offset',  0,           @isnumeric);
    addParameter(p, 'month_offset', 0,           @isnumeric);
    addParameter(p, 'day_offset',   0,           @isnumeric);
    addParameter(p, 'convention',   'following', @ischar);
    parse(p, varargin{:});

    %% 2. Apply year/month/day offset
    % calyears and calmonths handle impossible dates automatically
    dt = datetime(base_date, 'ConvertFrom', 'datenum');
    dt = dt + calyears(p.Results.year_offset) ...
            + calmonths(p.Results.month_offset) ...
            + days(p.Results.day_offset);
    raw_date = datenum(dt);

    %% 3. Roll to business day
    % First, roll forward to the next business day (following convention):
    adj = raw_date;
    while ~isbusday(adj), adj = adj + 1; end

    % If convention is 'modified_following' and rolling forward crossed
    % the month boundary, roll backward instead:
    if strcmp(p.Results.convention, 'modified_following')
        if month(datetime(adj, 'ConvertFrom', 'datenum')) ~= month(dt)
            adj = raw_date;
            while ~isbusday(adj), adj = adj - 1; end
        end
    end

    adjusted_date = adj;
end
