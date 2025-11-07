% plotOtolithRollResponse.m
% Four columns: a_uL and a_sL vs roll angle, with a tilted head sketch above each.

clear; clc; close all;

% Parameters
g = 1;                              % units of G
angles_deg = [0, 10, 20, 25];       % roll angles (deg)
nCols = numel(angles_deg);

plothelper = PlotHelper();

% Layout
tiledlayout(1, nCols, "Padding", "compact", "TileSpacing", "compact");

% Head drawing parameters
headY   = 0.8;    % lowered vertical placement of head center
headX   = 1.5;    % horizontal center between bars (x=1 and x=2)
headR   = 0.20;   % head radius
eyeLen  = 0.30;   % eye-line length
noseLen = 0.15;   % nose length

% BEFORE the loop, create the layout with no gutters/margins
t = tiledlayout(1,4);
t.TileSpacing = 'none';    % was 'compact' — 'none' removes gaps between tiles
t.Padding     = 'none';    % removes outer frame padding

for k = 1:nCols
    theta = angles_deg(k);
    a_uL = g * sind(theta);
    a_sL = -g * cosd(theta);   % your sign convention

    nexttile; hold on;

    % ---- Bars ----
    x = [1 2];                 % 1 -> a_uL, 2 -> a_sL
    y = [a_uL, a_sL];
    bar(x, y, 0.6);
    yline(0, 'k-', 'LineWidth', 1);

    % Axes formatting
    xlim([0.5 2.5]);
    ylim([-1.2, 1.3]);  % slightly lowered top limit to center figure
    
    set(gca, 'XTick', [1 2], 'XTickLabel', {'a_{utricle}','a_{saccule}'});
    
    if(k ==1)
        ylabel('Acceleration (G)');
    end
    
    if(k~=1)
       set(gca,'YTick',[],'YTickLabel',[]);
        ylabel('');                       % remove label
    end
    title(sprintf('\\theta_r = %d^\\circ', theta));
    set(gca, 'FontName', 'Arial', 'YGrid', 'on'); box on;

    % ---- Draw head (lowered) ----
    th = linspace(0, 2*pi, 200);
    xc = headX + headR * cos(th);
    yc = headY + headR * sin(th);
    plot(xc, yc, 'k-', 'LineWidth', 1.5);

    % Eye-line
    ex = (eyeLen/2) * [cosd(theta), -cosd(theta)];
    ey = (eyeLen/2) * [sind(theta), -sind(theta)];
    plot(headX + ex, headY + ey, 'k-', 'LineWidth', 2);

    % Nose
    nx = noseLen * sind(theta);
    ny = -noseLen * cosd(theta);
    plot([headX, headX + nx], [headY, headY + ny], 'k-', 'LineWidth', 1.5);
    
    % ---- Highlight a_sL with delta label ----
    delta_s = a_sL + 1;                             % deviation from -1 G
    text(2, -1 - 0.15, sprintf('\\Delta=%.3f', delta_s), ...
         'HorizontalAlignment','center', 'VerticalAlignment','bottom', ...
         'Color',[0.85 0.33 0.10], 'FontSize',9, 'FontWeight','bold');

    % Make a_sL visually distinct
    b = findobj(gca,'Type','Bar');                  % last bar call handle
    if ~isempty(b)
        b.FaceColor = 'flat';
        b.CData(1,:) = [0 0.45 0.74];               % a_uL color
        b.CData(2,:) = [0.85 0.33 0.10];            % a_sL color
    end
    yline(-1,'--','-1 G','LabelVerticalAlignment','middle', ...
          'Color',[0.3 0.3 0.3],'Alpha',0.6);
      
    set(gcf, 'Units', 'inches', 'Position', [0 0 8 5]);  % width x height
    set(gca, 'DataAspectRatio', [1 1 1]);  % keep bars proportional


    hold off;
end

plothelper.addFilenameAnnotation()

set(gcf, 'Color', 'w');


