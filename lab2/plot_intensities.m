function plot_intensities(datesCDS, intensities_approx, ...
    intensities_exact, intensities_JT, filename)

% PLOT_INTENSITIES Plot and compare CDS bootstrap default intensities.
%
%   PLOT_INTENSITIES(datesCDS, intensities_approx, intensities_exact,
%       intensities_JT, filename)
%
%   Plots the three default intensity curves (Approx, Exact, JT) on the
%   same axes as staircase plots and saves the figure as a PDF.
%
%   Inputs:
%       datesCDS             - Pillar dates (serial date numbers).
%       intensities_approx   - Intensities from approximate bootstrap (flag=1).
%       intensities_exact    - Intensities from exact bootstrap (flag=2).
%       intensities_JT       - Intensities from JT bootstrap (flag=3).
%       filename             - Output PDF path (e.g. 'intensities.pdf').
%
%   See also BOOTSTRAPCDS, STAIRS, DATETICK.
% -------------------------------------------------------------------------

    date_labels = datetime(datesCDS, 'ConvertFrom', 'datenum');

    fig = figure('Visible', 'off');

    stairs(date_labels, intensities_approx, 'b-',  'LineWidth', 1.5); hold on;
    stairs(date_labels, intensities_exact,  'r--', 'LineWidth', 1.5);
    stairs(date_labels, intensities_JT,     'k-.', 'LineWidth', 1.5); hold off;

    legend('Approx', 'Exact', 'JT', 'Location', 'best');
    xlabel('Date');
    ylabel('Default Intensity');
    title('CDS Bootstrap - Default Intensities');
    grid on;

    exportgraphics(fig, filename, 'ContentType', 'vector');
    close(fig);

    fprintf('Plot saved to: %s\n', filename);

end