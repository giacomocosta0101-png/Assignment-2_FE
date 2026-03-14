% runAssignment2
%  group 5, AY2025-2026
%
% This script deals with different topic: interest rate curve bootstrapping, 
% P&L computation for an Interest Rate Swap, coupon bond pricing, asset swap 
% spread computation, CDS bootstrapping, simulation of default times with 
% survival probability fitting, NPV computation of growing cash flows.

%% Settings
formatData='dd/mm/yyyy';

%% Read market data
[datesSet, ratesSet] = readExcelData('MktData_CurveBootstrap.xls', formatData);

%% Bootstrap
[dates, discounts, zero_rates]=bootstrap(datesSet, ratesSet); 

plot_discount_Curves(dates, discounts, zero_rates, 'Bootstrap_results.pdf');

%% Exercise 1

N = 100e6;                 % notional
R_trader = 0.04117;        % rate received by the trader
R_bank = 0.04027;          % Bank XX rate 
R_fair =  0.04127;         % fair  mid-market rate
day_count_swap = 6;        % convention E30/360

% We compute the PnL versus the bank rate (PnL.bank), the PnL versus the fair 
% rate implied by the bootstrapped discount curve (PnL.fair) and we determine 
% how much the trader gains/losses versus the bank after accounting for the 
% fair rate
PnL = computePnL(N, R_trader, R_bank, R_fair, dates, discounts);

%% Exercise 2

% We compute the price of the bond as the value of the notional
priceBond = N;

%% Exercise 3

reference_date = dates(1);          % 15-Feb 2008
issue_d = datetime(2007,3,31);      % date in which we issued the bond
maturityBond = datetime(2012,3,31); % maturity of the bond
coupon = 0.046;                     % annual coupon of the bond
cleanPrice = 101.5;                 % clean price (in percentage) 
faceValue = 1;                      % face value of the bond

% We compute the asset swap spread
s = assetSwapSpread(reference_date, maturityBond, issue_d, ...
    coupon, faceValue, cleanPrice, dates, discounts);

%% Exercise 4

datesCDS_known = [1; 2; 3; 4; 5; 7]; % Vector of maturities for which market CDS spreads are available
datesCDS = (1:1:7)'; % Vector of dates for which we want CDSspreads
spreadsCDS_known = [29; 34; 37; 39; 40; 40] * 1e-4; % Vector of known market CDS spreads (converted in decimal)
recovery = 0.40; % Recovery

% We use cubic spline interpolation for obtaining the CDS spreads
% for the missing maturities
spreadsCDS = spline(datesCDS_known, spreadsCDS_known, datesCDS);

% We convert reference_date in datetime
ref_dt = datetime(reference_date, 'ConvertFrom', 'datenum');
% We compute datesCDS
datesCDS = datenum(ref_dt + calyears(1:7)');

% Bootstrapping

%  Approximate method (flag = 1): neglect the accrual on default.
[datesCDS, survProbs_approx, intensities_approx] = bootstrapCDS( ...
    dates, discounts, datesCDS, spreadsCDS, 1, recovery);

% Exact method including accrual (flag = 2)
[datesCDS, survProbs_exact, intensities_exact] = bootstrapCDS( ...
    dates, discounts, datesCDS, spreadsCDS, 2, recovery);

% Jarrow–Turnbull approximation (flag = 3)
[datesCDS, survProbs_JT, intensities_JT] = bootstrapCDS( ...
    dates, discounts, datesCDS, spreadsCDS, 3, recovery);


plot_intensities(reference_date, datesCDS, intensities_approx, ...
    intensities_exact, intensities_JT, 'intensities.pdf')
%% Exercise 5

lambda1 = 4e-4;   % 4 bps
lambda2 = 10e-4;  % 10 bps
theta   = 5;      % time (in years) when the risk intensity changes
T    = 30;        % horizontal time
M       = 1e5;    % number of simulations
alpha = 0.05;     % significance level for confidence intervals

% We simulate the default time 
tau = simulate_default_time(lambda1, lambda2,theta, M);

analyzeDefaultIntensities(tau, theta, T)

% We fit the sulvival probability, we provide an estimator and 
% a confidence Interval for 𝜆1 and 𝜆2  
[lambda1_MLE, lambda2_MLE, CI_lambda1, CI_lambda2] = estimate_and_plot_mle(tau, ...
    theta, T, alpha, 'mle_survival.pdf');
%% Exercise 6

reference_date = datesSet.settlement; % Valuation date used for discounting (15-Feb-2008)
startCF = datetime(2008,3,19); % first payment date
AAGR = 0.05;   % Annual Average Growth Rate applied once per year in March
CF0a = 1500;   % Initial monthly cash flows (Case a)
CF0b = 6000;   % Initial monthly cash flows (Case b)

% We compute the last payment date: 20 years of monthly payments, ending one month before
% the 20-year anniversary so that the schedule contains exactly 20*12 payments
endCF   = startCF + calyears(20) - calmonths(1);

% We generate all monthly payment dates from startCF to endCF
datesCF = (startCF:calmonths(1):endCF)';

% We compute the NPV for case (a)
NPVa = NPV_AAGR(datesCF, startCF, reference_date, AAGR, CF0a, dates, discounts);

% We compute the NPV for case (b) 
NPVb = NPV_AAGR(datesCF, startCF, reference_date, AAGR, CF0b, dates, discounts);