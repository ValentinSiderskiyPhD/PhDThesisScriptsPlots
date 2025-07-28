%% Load and prepare data
load('McAuley1997Fig3_SysColdPressor.mat');
time            = round(Finapres_sys(:,1));      % [2 4 6 8 10 11 12]
finapres_sys    = Finapres_sys(:,2);
finapres_err    = Finapres_sys_plusError(:,2)  - finapres_sys;
vitalmap_sys    = Vitalmap_sys(:,2);
vitalmap_err    = vitalmap_sys - Vitalmap_sys_minusError(:,2);

% Diastolic data at each time point
diastolic_vital = [64.8, 64.8, 64.8, 64.8, 64.8, 71.35, 77.9];
diastolic_finap = [67.3, 67.3, 67.3, 67.3, 67.3, 81.35, 93.5];

%% Compute baseline averages and errors over the first five (rest) points
n_baseline             = 5;
baseline_sys_avg_vital = mean(vitalmap_sys(1:n_baseline));
baseline_sys_err_vital = std( vitalmap_sys(1:n_baseline) ) / sqrt(n_baseline);
baseline_sys_avg_finap = mean(finapres_sys(1:n_baseline));
baseline_sys_err_finap = std( finapres_sys(1:n_baseline) ) / sqrt(n_baseline);
baseline_dia_avg_vital = mean(diastolic_vital(1:n_baseline));
fra_err_vital         = baseline_sys_err_vital / baseline_sys_avg_vital;
baseline_dia_err_vital = fra_err_vital * baseline_dia_avg_vital;
baseline_dia_avg_finap = mean(diastolic_finap(1:n_baseline));
fra_err_finap         = baseline_sys_err_finap / baseline_sys_avg_finap;
baseline_dia_err_finap = fra_err_finap * baseline_dia_avg_finap;

%% Compute MAP at all time points
MAP_vital_all = diastolic_vital + (vitalmap_sys   - diastolic_vital)/3;
MAP_finap_all = diastolic_finap + (finapres_sys   - diastolic_finap)/3;

%% Compute baseline MAP using averaged baseline values
baseline_MAP_vital = baseline_dia_avg_vital + ...
    (baseline_sys_avg_vital - baseline_dia_avg_vital)/3;
baseline_MAP_finap = baseline_dia_avg_finap + ...
    (baseline_sys_avg_finap  - baseline_dia_avg_finap)/3;

%% Extract only baseline, 11?min, and 12?min MAP values
idx11    = find(time == 11);
idx12    = find(time == 12);
MAP_time = [10, 11, 12];  % 10 marks baseline period on x-axis

MAP_vital_raw = [baseline_MAP_vital, MAP_vital_all(idx11), MAP_vital_all(idx12)];
MAP_finap_raw = [baseline_MAP_finap,  MAP_finap_all(idx11),  MAP_finap_all(idx12)];

%% Align Finapres MAP to match Vitalmap baseline
MAP_finap_shifted = MAP_finap_raw - baseline_MAP_finap + baseline_MAP_vital;

%% Estimate MAP SEM for these three points
map_err_vital = [
    sqrt((2/3*baseline_dia_err_vital)^2 + (1/3*baseline_sys_err_vital)^2), ...
    sqrt((2/3*baseline_dia_err_vital)^2 + (1/3*vitalmap_err(idx11))^2), ...
    sqrt((2/3*baseline_dia_err_vital)^2 + (1/3*vitalmap_err(idx12))^2)
];
map_err_finap = [
    sqrt((2/3*baseline_dia_err_finap)^2 + (1/3*baseline_sys_err_finap)^2), ...
    sqrt((2/3*baseline_dia_err_finap)^2 + (1/3*finapres_err(idx11))^2), ...
    sqrt((2/3*baseline_dia_err_finap)^2 + (1/3*finapres_err(idx12))^2)
];

%% Project central MAP at 12 min
sbp_change_frac = (vitalmap_sys(idx12) - baseline_sys_avg_vital) / baseline_sys_avg_vital;
central_sys_12  = baseline_sys_avg_vital * (1 + 1.35 * sbp_change_frac);
central_map_12  = diastolic_vital(idx12) + (central_sys_12 - diastolic_vital(idx12)) / 3;
% Error for projected central MAP
central_sys_err = vitalmap_err(idx12) * 1.35;
central_map_err = (1/3) * central_sys_err;

%% Plot MAP comparison with projected central MAP
figure('Color','w','Position',[600 300 700 500]);
hold on;

% Shaded CPT
ymin = min([MAP_vital_raw - map_err_vital, ...
            MAP_finap_shifted - map_err_finap, ...
            central_map_12 - central_map_err]) - 2;
ymax = max([MAP_vital_raw + map_err_vital, ...
            MAP_finap_shifted + map_err_finap, ...
            central_map_12 + central_map_err]) + 2;
fill([10 12 12 10], [ymin ymin ymax ymax], [0.8 0.9 1], ...
    'EdgeColor','none','FaceAlpha',0.3);
text(11, ymax-1,'Cold Pressor Test','FontSize',12,'FontWeight','bold','HorizontalAlignment','center');

% Plot Vitalmap MAP
errorbar(MAP_time, MAP_vital_raw, map_err_vital, '-o','Color',[0 0.5 0],...
    'MarkerFaceColor','g','LineWidth',1.5,'DisplayName','Vitalmap MAP');

% Plot aligned Finapres MAP
errorbar(MAP_time, MAP_finap_shifted, map_err_finap, '-s','Color',[.85 .33 .10],...
    'MarkerFaceColor','y','LineWidth',1.5,'DisplayName','Finapres MAP (aligned)');

% Plot projected central MAP only at 12 min
errorbar(12, central_map_12, central_map_err, 'd', 'Color','k', ...
    'MarkerFaceColor','k', 'MarkerSize',8, 'LineWidth',1.5, ...
    'DisplayName','Projected Central MAP (Casey et al. 2008)');

xticks([10 11 12]);
xticklabels({'baseline (0–10?min)','11','12'});
xlabel('Time','FontSize',12);
ylabel('Mean Arterial Pressure (mmHg)','FontSize',12);
title('MAP: Vitalmap, Finapres, and Central Estimate','FontSize',14,'FontWeight','bold');
xlim([9 13]); ylim([ymin ymax]); grid on;
legend('Location','northwest');
hold off;
