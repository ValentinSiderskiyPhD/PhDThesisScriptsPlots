% plotOtolithResponses2x2.m
% 2x2 layout showing otolith responses to:
%   - Roll tilt (25°)
%   - Pitch tilt (25°)
%   - Lateral acceleration (0.422 G)
%   - Anterior acceleration (0.422 G)
% Each panel shows 4 bars: a_utricle_ant, a_utricle_lat, a_saccule_vert, a_saccule_ant

clear; clc; close all;

% -------------------- Parameters --------------------
g = 1;                              % units of G
theta_deg = 25;                     % tilt angle (deg)
a_lin = 0.422;                      % linear acceleration (G)

% Head drawing params (in data units)
headY   = 2.0;      % vertical placement of head center
headX   = 0;        % horizontal offset
headR   = 0.35;     % head radius
eyeLen  = 0.50;     % eye-line length
noseLen = 0.25;     % nose length

% Head scaling
headScale = 1.5;
headR   = headR   * headScale;
eyeLen  = eyeLen  * headScale;
noseLen = noseLen * headScale;

try
    plothelper = PlotHelper();
catch ME
    rethrow(ME);
end

% -------------------- Scenario Data --------------------
% Each row: [a_ut_ant, a_ut_lat, a_sacc_vert, a_sacc_ant]
scenarios = {
    'Roll Tilt (25°)', ...
        [0, g*sind(theta_deg), -g*cosd(theta_deg), 0];
    
    'Pitch Tilt (25°)', ...
        [-g*sind(theta_deg), 0, -g*cosd(theta_deg), -g*sind(theta_deg)];
    
    'Lateral Accel (0.422 G)', ...
        [0, a_lin, -1, 0];
    
    'Anterior Accel (0.422 G)', ...
        [-a_lin, 0, -1, -a_lin];
};

labels = {'a_{utricle-ant}', 'a_{utricle-lat}', 'a_{saccule-vert}', 'a_{saccule-ant}'};
colors = [0.85 0.33 0.10;    % red for anterior
          0.00 0.45 0.74;    % blue for lateral
          0.47 0.67 0.19;    % green for saccule vert
          0.93 0.69 0.13];   % yellow/orange for saccule ant

% -------------------- Layout --------------------
figure('Units','inches', 'Position',[0 0 10 8], 'PaperPositionMode','auto', 'Color','w');
t = tiledlayout(2, 2);
t.TileSpacing = 'compact';
t.Padding     = 'compact';

ax = gobjects(4,1);
hBars = gobjects(4,1);

% -------------------- FIRST LOOP: Create bar plots --------------------
for k = 1:4
    ax(k) = nexttile(t, k);
    axk = ax(k);
    hold(axk,'on');
    
    title_str = scenarios{k,1};
    accel_vals = scenarios{k,2};
    
    % bars
    x = 1:4;
    hBars(k) = bar(axk, x, accel_vals, 0.65);
    yline(axk, 0, 'k-', 'LineWidth', 1);
    
    % axes formatting
    xlim(axk, [0.5 4.5]);
    ylim(axk, [-1.2 1.3]);
    set(axk, 'XTick', 1:4, 'XTickLabel', labels, ...
             'FontName','Arial','YGrid','on','Box','on','FontSize',11);
    
    ylabel(axk, 'Acceleration (G)');
    
    title(axk, title_str, 'Interpreter','tex', 'FontSize',13, 'FontWeight','bold');
    
    % color bars
    hBars(k).FaceColor = 'flat';
    for i = 1:4
        hBars(k).CData(i,:) = colors(i,:);
    end
    
    % -1 G reference line
    yline(axk, -1, '--', '-1 G', ...
      'LabelVerticalAlignment','middle', ...
      'LabelHorizontalAlignment','left', ...   
      'Color',[0.3 0.3 0.3],'Alpha',0.6);
end

% Force layout
drawnow;

% -------------------- SECOND LOOP: Add head overlays --------------------
for k = 1:4
    axk = ax(k);
    hB = hBars(k);
    
    % Find midpoint of bars
    xCenters  = hB.XEndPoints;
    headXmid  = mean(xCenters);
    
    % Create overlay axes
    axH = axes('Position', axk.Position, 'Color','none', ...
               'XTick',[], 'YTick',[], 'Visible','off');
    axH.PositionConstraint = 'innerposition';
    hold(axH,'on');
    axis(axH,'equal');
    uistack(axH,'top');
    
    % Set limits
    axH.XLim = axk.XLim;
    axH.YLim = [-3, 3];
    
    % Translate head position
    baseXLim = axk.XLim;
    normalizedX = (headXmid - baseXLim(1)) / (baseXLim(2) - baseXLim(1));
    overlayXLim = axH.XLim;
    headXplot = overlayXLim(1) + normalizedX * (overlayXLim(2) - overlayXLim(1)) + headX;
    
    % Draw head circle
    th = linspace(0, 2*pi, 200);
    xc = headXplot + headR*cos(th);
    yc = headY      + headR*sin(th);
    plot(axH, xc, yc, 'k-', 'LineWidth', 1.5);
    
    % Draw features based on scenario
    switch k
        case 1  % Roll tilt - frontal view with tilted eye-line
            theta = theta_deg;
            % Eye-line rotated by theta
            ex = (eyeLen/2) * [cosd(theta), -cosd(theta)];
            ey = (eyeLen/2) * [sind(theta), -sind(theta)];
            plot(axH, headXplot + ex, headY + ey, 'k-', 'LineWidth', 2);
            % Add circular eyes on the eye-line
            eye_spacing = eyeLen/2.5;
            % Left eye
            ex_left = headXplot - eye_spacing * cosd(theta);
            ey_left = headY - eye_spacing * sind(theta);
            plot(axH, ex_left, ey_left, 'ko', 'MarkerSize', 6, 'MarkerFaceColor', 'k');
            % Right eye
            ex_right = headXplot + eye_spacing * cosd(theta);
            ey_right = headY + eye_spacing * sind(theta);
            plot(axH, ex_right, ey_right, 'ko', 'MarkerSize', 6, 'MarkerFaceColor', 'k');
            % Nose (perpendicular to eye-line, downward)
            nx = noseLen * sind(theta);
            ny = -noseLen * cosd(theta);
            plot(axH, [headXplot, headXplot+nx], [headY, headY+ny], 'k-', 'LineWidth', 1.5);
            
        case 2  % Pitch tilt - profile view
            theta = theta_deg;
            % Eye (single point for profile)
            plot(axH, headXplot, headY, 'ko', 'MarkerSize', 6, 'MarkerFaceColor', 'k');
            % Nose projecting at pitch angle (0° = horizontal right, positive = tilt up)
            nose_x = headXplot + (headR + noseLen) * cosd(theta);
            nose_y = headY + (headR + noseLen) * sind(theta);
            % Line from edge of circle to nose tip
            edge_x = headXplot + headR * cosd(theta);
            edge_y = headY + headR * sind(theta);
            plot(axH, [edge_x, nose_x], [edge_y, nose_y], 'k-', 'LineWidth', 2);
            
        case 3  % Lateral acceleration - upright with arrow
            % Horizontal eye-line (upright)
            ex = (eyeLen/2) * [1, -1];
            plot(axH, headXplot + ex, [headY, headY], 'k-', 'LineWidth', 2);
            % Add circular eyes on the eye-line
            eye_spacing = eyeLen/2.5;
            % Left eye
            plot(axH, headXplot - eye_spacing, headY, 'ko', 'MarkerSize', 6, 'MarkerFaceColor', 'k');
            % Right eye
            plot(axH, headXplot + eye_spacing, headY, 'ko', 'MarkerSize', 6, 'MarkerFaceColor', 'k');
            % Nose (downward)
            plot(axH, [headXplot, headXplot], [headY, headY-noseLen], 'k-', 'LineWidth', 1.5);
            % Arrow pointing left (lateral acceleration) - above head
            arrow_y = headY + headR + 0.3;
            arrow_len = 0.8;
            quiver(axH, headXplot + arrow_len/2, arrow_y, -arrow_len, 0, 0, ...
                  'Color', colors(2,:), 'LineWidth', 2.5, 'MaxHeadSize', 0.5);
            
        case 4  % Anterior acceleration - upright with forward arrow
            % Horizontal eye-line (upright)
            ex = (eyeLen/2) * [1, -1];
            plot(axH, headXplot + ex, [headY, headY], 'k-', 'LineWidth', 2);
            % Add circular eyes on the eye-line
            eye_spacing = eyeLen/2.5;
            % Left eye
            plot(axH, headXplot - eye_spacing, headY, 'ko', 'MarkerSize', 6, 'MarkerFaceColor', 'k');
            % Right eye
            plot(axH, headXplot + eye_spacing, headY, 'ko', 'MarkerSize', 6, 'MarkerFaceColor', 'k');
            % Nose (downward)
            plot(axH, [headXplot, headXplot], [headY, headY-noseLen], 'k-', 'LineWidth', 1.5);
            % Arrow coming "out of page" - circle with center dot - above head
            arrow_y = headY + headR + 0.3;
            plot(axH, headXplot, arrow_y, 'o', 'MarkerSize', 14, ...
                'Color', colors(1,:), 'LineWidth', 2.5, 'MarkerFaceColor', 'none');
            plot(axH, headXplot, arrow_y, '.', 'MarkerSize', 12, ...
                'Color', colors(1,:), 'MarkerFaceColor', colors(1,:));
    end
    
    hold(axH,'off');
end

% Force final layout
drawnow;

% Add padding for filename annotation
t.OuterPosition = [0, 0.05, 0.99, 0.95];
plothelper.addFilenameAnnotation();