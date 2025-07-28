%% step_response.m
% This script simulates an underdamped second‐order process with time delay.
% The process model is:
%      taus^2 * d²y/dt² + 2*zeta*taus*dy/dt + y = Kp * u(t - thetap)
%
% A step input is applied (starting at t = 1 sec) and the response is plotted.
% An annotation arrow is added to indicate where the input jumps to 1.

clear; clc; close all;

%% Define Process Model Parameters
Kp     = 2.0;   % process gain
taus   = 0.5;   % second order time constant
thetap = 2.0;   % time delay (seconds)
zeta   = 0.15;  % damping factor

%% Define Simulation Time and Input
ns   = 120;               % number of simulation steps
dt   = 0.1;               % time step (seconds)
t    = 0:dt:(ns*dt);      % time vector from 0 to 12 sec (121 points)

% Initialize controller output (step input) and process state.
op = zeros(length(t),1);
pv = zeros(length(t),2);  % each row: [y, dy/dt]

% Set step input: In MATLAB, t(11)==1.0 so the input becomes 1 at t>=1.0.
op(11:end) = 1.0;

% Calculate number of steps corresponding to the time delay.
ndelay = ceil(thetap / dt);

%% Simulation Loop
% At each time step, the process ODE is integrated over dt using ode45.
for i = 1:ns
    % Implement the time delay by using an input from ndelay steps earlier.
    % For i <= ndelay, use the first value (i.e. op(1)).
    iop = max(1, i - ndelay);
    u_val = op(iop);
    
    % Integrate the ODE over one time step [0, dt] with initial condition pv(i,:).
    [~, y_out] = ode45(@(t, x) process(t, x, u_val, Kp, taus, zeta), [0 dt], pv(i,:)');
    pv(i+1,:) = y_out(end,:)';
end

%% Compute Response Characteristics
tp    = pi * taus / sqrt(1 - zeta^2);                 % peak time
tr    = taus / sqrt(1 - zeta^2) * (pi - acos(zeta));    % rise time
os    = exp(-pi * zeta / sqrt(1 - zeta^2));             % overshoot ratio
dr    = os^2;                                         % decay ratio
p_val = 2 * pi * taus / sqrt(1 - zeta^2);               % period

% Display the summary
fprintf('Summary of response:\n');
fprintf('  Rise time:    %f seconds\n', tr);
fprintf('  Peak time:    %f seconds\n', tp);
fprintf('  Overshoot:    %f\n', os);
fprintf('  Decay ratio:  %f\n', dr);
fprintf('  Period:       %f seconds\n', p_val);

%% Plot the Results

% Create a figure with two subplots.
figure;

%% First Subplot: Process Output
subplot(2,1,1);
hold on;
plot(t, pv(:,1), 'b-', 'LineWidth', 3, 'DisplayName', 'Underdamped');
plot([0, max(t)], [2, 2], 'r--', 'DisplayName', 'Steady State');

% Additional lines to indicate key time instants and amplitude levels.
plot([1, 1], [0, 0.5], 'k-');
plot([3, 3], [0, 0.5], 'k-');
plot([3+tr, 3+tr], [0, 2], 'k-');
plot([3+tp, 3+tp], [0, 2], 'k-');
plot([3, 3+tr], [2, 2], 'g-', 'LineWidth', 2);
plot([3, 3+tp], [2*(1+os), 2*(1+os)], 'g-', 'LineWidth', 2);
plot([3+tp, 3+tp+p_val], [3, 3], 'k--', 'LineWidth', 2);
plot([3+tp, 3+tp], [2, 2*(1+os)], 'r-', 'LineWidth', 3);
plot([3+tp+p_val, 3+tp+p_val], [2, 2*(1+os*dr)], 'r-', 'LineWidth', 3);

%legend('Location', 'southwest');
ylabel('Process Output');
title('Underdamped Step Response');

% Add text annotations (using LaTeX formatting).
text(1.05, 0.2, '$Delay\,(\theta_p=2)$', 'Interpreter', 'latex');
text(2, 2.1, '$Rise\,Time\,(t_r)$', 'Interpreter', 'latex');
text(2, 3,   '$Peak\,Time\,(t_p)$', 'Interpreter', 'latex');
text(5, 3.1, '$Period\,(P)$', 'Interpreter', 'latex');
text(3+tp+0.05, 1.0, '$A$', 'Interpreter', 'latex');
text(3+tp+0.05, 2.1, '$B$', 'Interpreter', 'latex');
text(3+tp+p_val+0.05, 2.1, '$C$', 'Interpreter', 'latex');
text(6, 2.7, '$Decay\,Ratio\,(\frac{C}{B})$', 'Interpreter', 'latex');
text(5.5, 1.0, '$Overshoot\,Ratio\,(\frac{B}{A})$', 'Interpreter', 'latex');

%% Second Subplot: Process Input (Step Input)
subplot(2,1,2);
plot(t, op, 'k:', 'LineWidth', 3, 'DisplayName', 'Step Input');
ylim([-0.1 1.1]);
legend('Location', 'best');
ylabel('Process Input');
xlabel('Time');

% --- Updated Annotation Arrow ---
% We want the arrow to point to the point where the input steps to 1, i.e. at (1,1)
% We'll place the arrow tail at (1.5, 0.9) and the arrow tip at (1,1).
ax = gca;
ax_pos = ax.Position;         % Axes position in normalized units
x_limits = xlim(ax);
y_limits = ylim(ax);

% Define data coordinates for the tail and tip:
x_data = [1.5, 1];  % tail to tip
y_data = [0.9, 1];

% Convert these data coordinates to normalized figure coordinates.
x_norm = (x_data - x_limits(1)) / (diff(x_limits)) * ax_pos(3) + ax_pos(1);
y_norm = (y_data - y_limits(1)) / (diff(y_limits)) * ax_pos(4) + ax_pos(2);

annotation('textarrow', x_norm, y_norm, 'String', '$Step\,Input\,Starts$', 'Interpreter', 'latex');

% Save the figure as a PNG file.
saveas(gcf, 'output.png');

%% Local Function: Process Model
function dxdt = process(~, x, u, Kp, taus, zeta)
    % This function computes the derivatives for the process model.
    % x(1) = y (process output) and x(2) = dy/dt.
    %
    % The model is:
    %    taus^2 * d²y/dt² + 2*zeta*taus*dy/dt + y = Kp*u
    %
    % Therefore, the state-space equations are:
    %    dy/dt = x(2)
    %    d²y/dt² = (-2*zeta*taus*x(2) - x(1) + Kp*u) / (taus^2)
    
    dxdt = zeros(2,1);
    dxdt(1) = x(2);
    dxdt(2) = (-2*zeta*taus*x(2) - x(1) + Kp*u) / (taus^2);
end
