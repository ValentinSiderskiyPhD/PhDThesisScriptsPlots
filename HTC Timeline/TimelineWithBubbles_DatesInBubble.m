% --------------------------------------------------------
% TimelineWithBubbles_MonthNames_NoTicks.m
% --------------------------------------------------------
% Reads a CSV of 'Label' and 'Release Date' columns (with month names) 
% and plots a horizontal timeline with one bubble per unique release date.
% The x‐axis tick labels are removed; instead, each bubble has a larger, 
% angled date label just below it. Product names remain staggered above.

clc, clear, close all

%% 1) Specify the CSV filename
csvFile = 'htc_timeline_monthname.csv';

%% 2) Read the CSV into a table
T = readtable(csvFile, 'TextType', 'string');

% Determine variable names (MATLAB replaces spaces with underscores)
varNames = T.Properties.VariableNames;
labelVar = varNames{1};    % 'Label'
dateVar  = varNames{2};    % e.g. 'Release_Date'

%% 3) Convert the "Release Date" column (string) to datetime
% CSV format: "dd MMM yyyy" (e.g. "06 Jun 2017")
datesOriginal = datetime(T.(dateVar), 'InputFormat', 'dd MMM yyyy');

%% 4) Sort and remove duplicates
[datesSorted, sortIdx] = sort(datesOriginal);
labelsSorted = T.(labelVar)(sortIdx);

[datesUnique, ia] = unique(datesSorted, 'stable');
labelsUnique    = labelsSorted(ia);

%% 5) Prepare y‐coordinates for bubbles and labels
yLine = zeros(size(datesUnique));  % all bubbles on y = 0

% Stagger product names: odd indices at y = 0.08, even at y = 0.14
yLabel = nan(size(datesUnique));
for i = 1:numel(datesUnique)
    if mod(i,2) == 1
        yLabel(i) = 0.08;
    else
        yLabel(i) = 0.14;
    end
end

% Place date labels a bit lower (y = -0.04)
yDate = -0.04 * ones(size(datesUnique));

%% 6) Create the figure and plot the timeline
figure('Color','w');
ax = axes;
hold(ax, 'on');

% 6a) Plot each bubble at its date on the horizontal line y = 0
bubbleSize = 60;
scatter(datesUnique, yLine, bubbleSize, 'o', ...
        'MarkerFaceColor', [0.2 0.6 0.9], ...
        'MarkerEdgeColor', 'k', ...
        'LineWidth', 1.2);

% 6b) Annotate each bubble with its product name (staggered above)
for i = 1:numel(datesUnique)
    text(datesUnique(i), yLabel(i), labelsUnique(i), ...
         'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'bottom', ...
         'FontSize', 10, 'FontWeight', 'normal');
end

% 6c) Annotate each bubble with its release month/year below (angled, larger font)
for i = 1:numel(datesUnique)
    dateStr = datestr(datesUnique(i), 'mmm yyyy');  % e.g. "Apr 2016"
    text(datesUnique(i), yDate(i), dateStr, ...
         'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'top', ...
         'FontSize', 10, ...      % larger date font
         'Rotation', 45, ...
         'Color', 'k');
end

%% 7) Configure axes so y = 0 is the timeline, but remove tick labels
ax.YAxis.Visible   = 'off';       % hide the y‐axis
ax.XAxisLocation   = 'origin';    % place x-axis at y = 0 (timeline line)

% Remove x-axis tick labels and tick marks
ax.XTick = [];                    % no tick locations
ax.XColor = 'k';                  % keep the axis line visible (black)
ax.XAxis.LineWidth = 1;           % ensure timeline line is drawn

%% 8) Adjust plot limits so nothing is clipped
leftLimit  = min(datesUnique) - calmonths(1);
rightLimit = max(datesUnique) + calmonths(1);
xlim([leftLimit, rightLimit]);

ylim([-0.10, 0.20]);  % more room below for the larger date labels

%% 9) Add a title
title('HTC Headset Release Timeline', 'FontSize', 14, 'FontWeight', 'bold');

hold(ax, 'off');
