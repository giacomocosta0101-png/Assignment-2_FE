function plot_discount_Curves(dates, discounts, zero_rates, filename)
% PLOT_DISCOUNT_CURVES  Plot the bootstrapped discount curve and zero curve.
%
%   plot_discount_Curves(dates, discounts, zero_rates, filename)
%
%   Displays discount factors (left axis) and zero rates (right axis) on
%   a single figure with two vertical scales, and saves the result as a
%   vector PDF.
%
%   INPUTS:
%       dates      – Nx1 vector of curve dates (datenum)
%       discounts  – Nx1 vector of discount factors
%       zero_rates – Nx1 vector of zero rates
%       filename   – output PDF path (e.g. 'curves.pdf')
%
%   OUTPUT:
%       (none – a figure is saved as PDF)

% Convert serial date numbers to datetime for readable x-axis labels
dates_dt = datetime(dates, 'ConvertFrom', 'datenum');

fig = figure('Visible', 'off');

% Left axis: discount factors over the full set of dates
yyaxis left
plot(dates_dt, discounts, '-o', 'LineWidth', 1.2, 'MarkerSize', 3)
ylabel('Discount Factor')

% Right axis: zero rates excluding the settlement date (where rate = 0)
yyaxis right
plot(dates_dt(2:end), zero_rates(2:end), '-o', 'LineWidth', 1.2, 'MarkerSize', 3)
ylabel('Zero Rate')

grid on
xlabel('Dates')
title('Bootstrapped Discount Factors and Zero Rates')
legend('Discount Factors', 'Zero Rates', 'Location', 'best')

exportgraphics(fig, filename, 'ContentType', 'vector');
close(fig);
fprintf('Plot saved to: %s\n', filename);

end