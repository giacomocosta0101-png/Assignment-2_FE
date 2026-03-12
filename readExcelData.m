function [dates, rates] = readExcelData( filename, formatData)
% Reads data from excel
%  It reads bid/ask prices and relevant dates
%  All input rates are in % units
%
% INPUTS:
%  filename: excel file name where data are stored
%  formatData: data format in Excel
% 
% OUTPUTS:
%  dates: struct with settlementDate, deposDates, futuresDates, swapDates
%  rates: struct with deposRates, futuresRates, swapRates

%% Dates from Excel

%Settlement date
settlement = readcell(filename, 'Sheet', 1, 'Range', 'E8');
%Date conversion
dates.settlement = datenum(settlement{1});

%Dates relative to depos
date_depositi = readcell(filename, 'Sheet', 1, 'Range', 'D11:D18');
dates.depos = datenum(cell2mat(date_depositi));

%Dates relative to futures: calc start & end
date_futures_read = readcell(filename, 'Sheet', 1, 'Range', 'Q12:R20');
numberFutures = size(date_futures_read,1);

dates.futures = ones(numberFutures,2);
dates.futures(:,1) = datenum(cell2mat(date_futures_read(:,1)));
dates.futures(:,2) = datenum(cell2mat(date_futures_read(:,2)));

%Date relative to swaps: expiry dates
date_swaps = readcell(filename, 'Sheet', 1, 'Range', 'D39:D88');
dates.swaps = datenum(cell2mat(date_swaps));

%% Rates from Excel (Bids & Asks)

%Depos
tassi_depositi = readmatrix(filename, 'Sheet', 1, 'Range', 'E11:F18');
rates.depos = tassi_depositi / 100;

%Futures
tassi_futures = readmatrix(filename, 'Sheet', 1, 'Range', 'E28:F36');
%Rates from futures
tassi_futures = 100 - tassi_futures;
rates.futures = tassi_futures / 100;

%Swaps
tassi_swaps = readmatrix(filename, 'Sheet', 1, 'Range', 'E39:F88');
rates.swaps = tassi_swaps / 100;

end % readExcelData