% Blood Pressure Response to Cold Pressor Test
% Systolic data loaded from MAT file; diastolic data from text description

% Load extracted systolic BP data
load('McAuley1997Fig3_SysColdPressor.mat');
%   Finapres_sys            [Nx2]: [time, systolic]
%   Finapres_sys_plusError  [Nx2]: [time, systolic+error]
%   Vitalmap_sys            [Nx2]: [time, systolic]
%   Vitalmap_sys_minusError [Nx2]: [time, systolic?error]

% Round time to nearest whole minute
time = round(Finapres_sys(:,1));  % [2 4 6 8 10 11 12]

% Extract systolic values and compute error bars
finapres_vals = Finapres_sys(:,2);
finapres_err  = Finapres_sys_plusError(:,2) - finapres_vals;    % upper SEM
vitalmap_vals = Vitalmap_sys(:,2);
vitalmap_err  = vitalmap_vals - Vitalmap_sys_minusError(:,2);  % lower SEM

% Diastolic data at each time point (mmHg)
% Vitalmap: 64.8 at t=2–10, interpolated 71.35 at t=11, 77.9 at t=12
% Finapres: 67.3 at t=2–10, interpolated 81.35 at t=11, 93.5 at t=12
diastolic_vitalmap = [64.8, 64.8, 64.8, 64.8, 64.8, 71.35, 77.9];
diastolic_finapres = [67.3, 67.3, 67.3, 67.3, 67.3, 81.35, 93.5];

% Compute dynamic y-limits to include both systolic ± error and diastolic
all_low  = [vitalmap_vals - vitalmap_err; finapres_vals - finapres_err; diastolic_vitalmap'];
all_high = [vitalmap_vals + vitalmap_err; finapres_vals + finapres_err; diastolic_finapres'];
ymin = min(all_low) - 5;
ymax = max(all_high) + 5;

% Figure setup
figure('Color',[1 1 1],'Position',[100 100 1200 600]);
hold on;

% Shaded background for Rest (0–10?min) and Cold Pressor (10–12?min)
h1 = fill([0 10 10 0], [ymin ymin ymax ymax], [0.92 0.92 0.92], ...
    'EdgeColor','none','FaceAlpha',0.3);
h2 = fill([10 12 12 10], [ymin ymin ymax ymax], [0.8 0.9 1], ...
    'EdgeColor','none','FaceAlpha',0.3);

% Remove shading from legend
h1.Annotation.LegendInformation.IconDisplayStyle = 'off';
h2.Annotation.LegendInformation.IconDisplayStyle = 'off';

% Labels for shaded regions
text(5, ymax-1,'Rest','FontSize',12,'FontWeight','bold','HorizontalAlignment','center');
text(11, ymax-1,'Cold Pressor Test','FontSize',12,'FontWeight','bold','HorizontalAlignment','center');

% Plot Vitalmap systolic with error bars
errorbar(time, vitalmap_vals, vitalmap_err, 'o--', ...
    'Color',[0.2 0.2 0.2],'MarkerFaceColor','w','LineWidth',1.5, ...
    'DisplayName','Vitalmap Systolic');

% Plot Finapres systolic with error bars
errorbar(time, finapres_vals, finapres_err, 's-', ...
    'Color',[0.85 0.33 0.10],'MarkerFaceColor','y','LineWidth',1.5, ...
    'DisplayName','Finapres Systolic');

% Plot diastolic BP
plot(time, diastolic_vitalmap, 'o--', 'Color',[0 0.5 0], ...
    'MarkerFaceColor','g','LineWidth',1.2,'DisplayName','Vitalmap Diastolic');
plot(time, diastolic_finapres, 's--', 'Color',[0.7 0 0.7], ...
    'MarkerFaceColor','m','LineWidth',1.2,'DisplayName','Finapres Diastolic');

% Formatting
xlabel('Time (min)','FontSize',12);
ylabel('Blood Pressure (mmHg)','FontSize',12);
title('Blood Pressure Response to Cold Pressor Test','FontSize',14,'FontWeight','bold');
xlim([0 13]);
ylim([ymin ymax]);
grid on;
legend('Location','northwest');
hold off;
