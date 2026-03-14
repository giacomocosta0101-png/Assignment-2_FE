function plot_intensities(reference_date, datesCDS, intensities_approx, ...
    intensities_exact, intensities_JT, filename)
% PLOT_INTENSITIES  Plot and compare CDS bootstrap default intensities.
%
%   plot_intensities(reference_date, datesCDS, intensities_approx,
%       intensities_exact, intensities_JT, filename)
%
%   Plots the three default intensity curves (Approx, Exact, JT) on the
%   same axes as staircase plots and saves the figure as a PDF.
%   The reference date is prepended so that the staircase covers the
%   full interval from t0 to the last pillar date.
%
%   INPUTS:
%       reference_date       – valuation date (datenum)
%       datesCDS             – Nx1 pillar dates (datenum)
%       intensities_approx   – Nx1 intensities from approximate bootstrap
%       intensities_exact    – Nx1 intensities from exact bootstrap
%       intensities_JT       – Nx1 intensities from Jarrow-Turnbull bootstrap
%       filename             – output PDF path (e.g. 'intensities.pdf')
%
%   OUTPUT:
%       (none – a figure is saved as PDF)

% Prepend the reference date so the staircase starts from t0
dates_plot = [reference_date; datesCDS];
approx_plot = [intensities_approx(1); intensities_approx];
exact_plot  = [intensities_exact(1);  intensities_exact];
JT_plot     = [intensities_JT(1);     intensities_JT];

% Convert to datetime for readable x-axis labels
date_labels = datetime(dates_plot, 'ConvertFrom', 'datenum');

fig = figure('Visible', 'off');

stairs(date_labels, approx_plot, 'b-',  'LineWidth', 1.5); hold on;
stairs(date_labels, exact_plot,  'r--', 'LineWidth', 1.5);
stairs(date_labels, JT_plot,     'k-.', 'LineWidth', 1.5); hold off;

legend('Approx (no accrual)', 'Exact (with accrual)', 'Jarrow-Turnbull', ...
    'Location', 'best');
xlabel('Date');
ylabel('Default Intensity');
title('CDS Bootstrap - Piecewise Constant Default Intensities');
grid on;

exportgraphics(fig, filename, 'ContentType', 'vector');
close(fig);
fprintf('Plot saved to: %s\n', filename);

end