% plotOtolithRollResponse.m
% Four columns: a_uL and a_sL vs roll angle, with a tilted head sketch above each.
% Tested on MATLAB R2020b.

clear; clc; close all;

% -------------------- Parameters --------------------
g = 1;                              % units of G
angles_deg = [0, 10, 20, 25];       % roll angles (deg)
nCols = numel(angles_deg);

% Head drawing params (in data units of each subplot)
headY   = 1.6;     % vertical placement of head center
headX   = 0;     % horizontal center between bars (x=1 and x=2)
headR   = 0.30;     % head radius
eyeLen  = 0.45;     % eye-line length
noseLen = 0.23;     % nose length

% -------------------- Head scaling --------------------
headScale = 1.8;    % <— change this number to resize head (1 = normal, 1.5 = 50% bigger, etc.)
headR   = headR   * headScale;
eyeLen  = eyeLen  * headScale;
noseLen = noseLen * headScale;

% Optional helper (ignore if you don't use it)
if exist('PlotHelper','class') == 8 || exist('PlotHelper','class') == 2
    plothelper = PlotHelper();
else
    plothelper = [];
end

% -------------------- Layout (R2020b OK) --------------------
t = tiledlayout(1, nCols);
t.TileSpacing = 'none';             % no gaps between tiles
t.Padding     = 'none';             % no outer margins

ax = gobjects(1,nCols);             % pre-allocate axes handles
hBars = gobjects(1,nCols);          % store bar handles

% -------------------- FIRST LOOP: Create bar plots --------------------
for k = 1:nCols
    theta = angles_deg(k);
    a_uL  = g * sind(theta);
    a_sL  = -g * cosd(theta);       % your sign convention

    % ----- BASE AXES: bars (auto aspect; fills tile) -----
    ax(k) = nexttile(t, k);
    axk = ax(k);                    % alias for brevity
    hold(axk,'on');
    axk.PositionConstraint = 'innerposition';

    % bars
    x = [1 2];  y = [a_uL, a_sL];
    hBars(k) = bar(axk, x, y, 0.6);
    yline(axk, 0, 'k-', 'LineWidth', 1);

    % axes formatting
    xlim(axk, [0.5 2.5]);
    ylim(axk, [-1.2 1.3]);
    set(axk, 'XTick', [1 2], 'XTickLabel', {'a_{utricle}','a_{saccule}'}, ...
             'FontName','Arial','YGrid','on','Box','on','FontSize',12);
    if k == 1
        ylabel(axk, 'Acceleration (G)');
    else
       set(gca,'YTick',[],'YTickLabel',[]);
        ylabel('');     
    end
    title(axk, sprintf('\\theta_r = %d^\\circ', theta), 'Interpreter','tex');

    % color bars distinctly
    hBars(k).FaceColor = 'flat';
    hBars(k).CData(1,:) = [0.00 0.45 0.74];     % a_uL color
    hBars(k).CData(2,:) = [0.85 0.33 0.10];     % a_sL color

    % -1 G reference and Δ label for a_sL
    yline(axk, -1, '--', '-1 G', ...
      'LabelVerticalAlignment','middle', ...
      'LabelHorizontalAlignment','left', ...   
      'Color',[0.3 0.3 0.3],'Alpha',0.6);

    delta_s = a_sL + 1;   % deviation from -1 G
    text(axk, 2-0.25, -1-0.1 , sprintf('\\Delta=%.3f', delta_s), ...
        'HorizontalAlignment','left','VerticalAlignment','bottom', ...
        'Color',[0.85 0.33 0.10],'FontSize',9,'FontWeight','bold');
end

% -------------------- Figure sizing --------------------
set(gcf, 'Units','inches', 'Position',[0 0 8 5], 'PaperPositionMode','auto', 'Color','w');

% Force MATLAB to finalize the layout
drawnow;

% -------------------- SECOND LOOP: Add head overlays --------------------
for k = 1:nCols
    theta = angles_deg(k);
    axk = ax(k);
    hB = hBars(k);
    
    % ----- HEAD: overlay axes keeps circle round and centered -----
    % 1) true midpoint between the two bars
    xCenters  = hB.XEndPoints;
    headXmid  = mean(xCenters);

    % 2) overlay axes with equal aspect
    axH = axes('Position', axk.Position, 'Color','none', ...
               'XTick',[], 'YTick',[], 'Visible','off');

    axH.PositionConstraint = 'innerposition';
    hold(axH,'on');
    axis(axH,'equal');
    uistack(axH,'top');

    % Set limits - axis equal will maintain aspect ratio
    axH.XLim = axk.XLim;
    axH.YLim = [-3, 3];
    
    % 3) Translate head position to overlay coordinates
    baseXLim = axk.XLim;
    normalizedX = (headXmid - baseXLim(1)) / (baseXLim(2) - baseXLim(1));
    overlayXLim = axH.XLim;
    headXplot = overlayXLim(1) + normalizedX * (overlayXLim(2) - overlayXLim(1)) + headX;

    % 4) draw head
    th = linspace(0, 2*pi, 200);
    xc = headXplot + headR*cos(th);
    yc = headY      + headR*sin(th);
    plot(axH, xc, yc, 'k-', 'LineWidth', 1.5);

    % eye-line rotated by theta
    ex = (eyeLen/2) * [cosd(theta), -cosd(theta)];
    ey = (eyeLen/2) * [sind(theta), -sind(theta)];
    plot(axH, headXplot + ex, headY + ey, 'k-', 'LineWidth', 2);

    % nose (perpendicular to eye-line)
    nx = noseLen * sind(theta);
    ny = -noseLen * cosd(theta);
    plot(axH, [headXplot, headXplot+nx], [headY, headY+ny], 'k-', 'LineWidth', 1.5);

    hold(axH,'off');
end

plothelper.addFilenameAnnotation();