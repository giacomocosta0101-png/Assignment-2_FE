% runAssignment2
%  group X, AY20ZZ-20ZZ
% Computes Euribor 3m bootstrap with a single-curve model
%

%% Settings
formatData='dd/mm/yyyy'; %Pay attention to your computer settings 

%% Read market data
% This fuction works on Windows OS. Pay attention on other OS.

[datesSet, ratesSet] = readExcelData('MktData_CurveBootstrap.xls', formatData);

%% Bootstrap
% dates includes SettlementDate as first date
[dates, discounts, zero_rates]=bootstrap(datesSet, ratesSet); % TBC

%% Plot Results

%discount curve
plot(dates,discounts)

figure

%zero-rates
plot(dates(2:end),zero_rates(2:end))

%% Exercise 1

N = 100e6;                 % notional
R_trader = 0.04117;               % rate received by the trader
R_bank = 0.04027;          % rate Bank XX
R_fair =  0.04127;         % fair rate
day_count_swap = 6;        % 30/360

PnL = computePnL(N, R_trader, R_bank, R_fair, dates, discounts);
%% Exercise 2

priceBond = N;

%% Exercise 3

reference_date = dates(1); % FIX: era business_date_offset(issue_d, day_offset=2)
issue_d = datetime(2007,3,31);
maturityBond = datetime(2012,3,31);
coupon = 0.046;
cleanPrice = 101.5;
faceValue = 1; 

ASW = assetSwapSpread(reference_date, maturityBond, issue_d, ...
    coupon, faceValue, cleanPrice, dates, discounts);

%% Exercise 4

datesCDS_known = [1;2;3;4;5;7];
datesCDS = (1:1:7)';
spreadsCDS_known = [29;34;37;39;40;40] * 1e-4;
recovery = 0.40;

% Point a 

spreadsCDS = spline(datesCDS_known, spreadsCDS_known,datesCDS);
ref_dt = datetime(reference_date, 'ConvertFrom', 'datenum');
datesCDS = datenum(ref_dt + calyears(1:7)');

% Approx (flag = 1)
[datesCDS, survProbs_approx, intensities_approx]  = bootstrapCDS(dates, discounts, datesCDS, spreadsCDS, 1, recovery);

% Exact (flag = 2)
[datesCDS, survProbs_exact, intensities_exact] = bootstrapCDS(dates, discounts, datesCDS, spreadsCDS, 2, recovery);

% JT (flag = 3)
[datesCDS, survProbs_JT, intensities_JT]  = bootstrapCDS(dates, discounts, datesCDS, spreadsCDS, 3, recovery);

%% Exercise 5

lambda1 = 4e-4;   % 4 bps
lambda2 = 10e-4;  % 10 bps
theta   = 5;      % anni
T    = 30;     % orizzonte
M       = 1e5;    % numero di simulazioni

tau = simulate_default_time(lambda1, lambda2,theta, M);

% Point b
analyzeDefaultIntensities(tau, theta, T)

%% Exercise 6

reference_date = datesSet.settlement;   % 15-Feb-2008
startCF = datetime(2008,3,19);
endCF   = startCF + calyears(20)-calmonths(1);
datesCF = (startCF:calmonths(1):endCF)';

AAGR = 0.05;

CF0a = 1500;   
CF0b = 6000;   

NPVa = NPV_AAGR(datesCF, startCF, reference_date, AAGR, CF0a,dates,discounts);
NPVb = NPV_AAGR(datesCF, startCF, reference_date, AAGR, CF0b,dates,discounts);