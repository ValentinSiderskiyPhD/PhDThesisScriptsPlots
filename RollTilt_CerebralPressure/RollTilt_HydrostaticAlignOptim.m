function RollTilt_HydrostaticAlignOptim
% RollTilt_HydrostaticAlignOptim
% --------------------------------------------------------------------------
% Does NOT trust the existing ECG alignment. Treats the BP<->model timing as a
% free parameter and asks two things:
%
%   (A) ALIGNMENT.  Sweep an explicit residual delay tau on the model and find
%       the tau that best matches the (de-pulsed) finger BP, per trial. If
%       tau* ~ 0 the cleandata alignment is already right; a consistent nonzero
%       tau* is a residual mis-alignment / extra delay. The model is built from
%       the RECORDED TILT ANGLE (immune to BP alignment), so it is an absolute
%       timing reference.
%
%   (B) DELAY vs LOW-PASS.  A pure delay = flat gain + phase linear in f.
%       A first-order low-pass = gain 1/sqrt(1+(f/fc)^2) + phase -atan(f/fc).
%       We fit both to the trustworthy fundamentals (0.03/0.10/0.18 Hz) and
%       report which the data support, and a corner-frequency estimate / bound.
%
% The cardiac pulse (~1 Hz) is removed from BOTH BP and model by an identical
% centred 1 s moving average, so the slow hydrostatic component is compared
% fairly (the average cancels in the gain ratio but kills the pulse that was
% wrecking R^2 before).
%
% Measured = BP_ecg_aligned ; Predicted = -deltaPfin2heart (RollTilt_HydrostatAdj).
%
% Valentin Siderskiy, 2026

here = fileparts(mfilename('fullpath'));
addpath('C:\Users\sider\Documents\Old Computer Files\C\Users\ValentinSiderskiy\Documents\GitHub\Serrador_Lab');
BATCH = ['C:\Users\sider\Documents\Old Computer Files\C\Users\ValentinSiderskiy\Documents\' ...
         'Serrador_Lab\Projects\MURI\VVA Experiment\STUDY VVA Clone 2022_10_09\SUBJECTS_BATCH_CORRECTED'];
subs = {'VVA012','VVA013','VVA014','VVA015','VVA017','VVA018','VVA019'};
freqs = [0.03 0.10 0.18]; ftok = {'0_03','0_1','0_18'};
ns=numel(subs); nF=numel(freqs);
taus = -2:0.01:2;                      % residual-delay sweep (s)
wrappi = @(a) mod(a+pi,2*pi)-pi;

gain0=nan(ns,nF); R20=nan(ns,nF);                  % as-aligned (tau=0)
gainS=nan(ns,nF); R2S=nan(ns,nF); tauS=nan(ns,nF); % delay-optimised (tau*)
phDelay=nan(ns,nF);                                % phase-derived effective delay (s)
ex = struct('t',[],'bp',[],'pr',[],'tau',[]);      % example trace for panel (d)

for s=1:ns
  for k=1:nF
    fp=fullfile(BATCH,subs{s},[subs{s} '_DARK' ftok{k} '_VS'],[subs{s} '_DARK' ftok{k} '_VS_clean.mat']);
    if exist(fp,'file')~=2, continue; end
    D=load(fp,'BP_ecg_aligned','angle_deg','Tilt','t_before','SR','subject_data');
    if ~isfield(D,'BP_ecg_aligned'), continue; end
    bp=D.BP_ecg_aligned(:); t=D.t_before(:); SR=D.SR;
    ang=[]; if isfield(D,'angle_deg'),ang=D.angle_deg(:); elseif isfield(D,'Tilt'),ang=D.Tilt(:); end
    if isempty(ang)||numel(ang)~=numel(bp), continue; end
    sd=D.subject_data;
    [~,dPh2heart]=RollTilt_HydrostatAdj(ang.', sd.PivotTCD, sd.FpcuffTCD, sd.FpcuffHeart, sd.FpcuffMidlin);
    pred=-dPh2heart(:);

    L=round(1.0*SR);                                % de-pulse: 1 s centred moving average (both signals)
    bps=movmean(bp,L); prs=movmean(pred,L);

    f=freqs(k); win=t>=35 & t<=t(end)-5;
    if nnz(win)<SR*10, win=t>=t(1)+5; end
    bw=bps(win);

    % (A) sweep residual delay, maximise R^2 of de-pulsed BP ~ shifted de-pulsed model
    bestR2=-inf;
    for it=1:numel(taus)
        ps=circshift(prs,round(taus(it)*SR)); ps=ps(win);
        X=[ps ones(numel(ps),1)]; b=X\bw; yh=X*b;
        R2=1-sum((bw-yh).^2)/sum((bw-mean(bw)).^2);
        if abs(taus(it))<1e-9, gain0(s,k)=b(1); R20(s,k)=R2; end
        if R2>bestR2, bestR2=R2; gainS(s,k)=b(1); R2S(s,k)=R2; tauS(s,k)=taus(it); end
    end

    % (B) phase-derived effective delay at the fundamental (de-pulsed)
    tw=t(win); prw=prs(win);
    [~,mp]=fitfc(tw,bw,f); [~,pp]=fitfc(tw,prw,f);
    phDelay(s,k)=wrappi(mp-pp)/(2*pi*f);

    if s==5 && k==3                                 % VVA017, 0.18 Hz : example overlay
        ps=circshift(prs,round(tauS(s,k)*SR));
        ex.t=tw-tw(1); ex.bp=bw; ex.pr=ps(win); ex.tau=tauS(s,k);
    end
  end
end

%% ---------------- delay vs low-pass on the fundamentals ----------------
mgain=mean(gainS,1,'omitnan'); sgain=std(gainS,0,1,'omitnan');
mtau =mean(tauS ,1,'omitnan');
mphd =mean(phDelay,1,'omitnan');
% pure-delay fit of phase: delay constant across f  ->  mean of phase delays
tau_pure=mean(mphd,'omitnan');
% first-order low-pass fit of GAIN: G=A/sqrt(1+(f/fc)^2), grid search
As=0.7:0.005:1.1; fcs=0.05:0.01:5; bestE=inf; Afit=NaN; fcfit=NaN;
for A=As, for fc=fcs
    g=A./sqrt(1+(freqs/fc).^2); e=sum((g-mgain).^2);
    if e<bestE, bestE=e; Afit=A; fcfit=fc; end
end, end
% flat-gain (no low-pass) reference error
flatA=mean(mgain,'omitnan'); flatE=sum((flatA-mgain).^2);

%% ---------------- figure ----------------
fig=figure('Color','w','Units','centimeters','Position',[1 1 24 16]);

% (a) gain: as-aligned vs delay-optimised, with low-pass fit
subplot(2,2,1); hold on
errorbar(freqs, mean(gain0,1,'omitnan'), std(gain0,0,1,'omitnan'),'-o','LineWidth',1.4,'DisplayName','as-aligned (\tau=0)');
errorbar(freqs, mgain, sgain,'-s','LineWidth',1.4,'DisplayName','delay-optimised (\tau^*)');
ff=linspace(0.01,0.21,100);
plot(ff, Afit./sqrt(1+(ff/fcfit).^2),'k--','DisplayName',sprintf('LP fit f_c=%.2f Hz',fcfit));
yline(1,'k:','HandleVisibility','off'); xlim([0 .21]); ylim([0.4 1.3]); grid on
xlabel('tilt frequency (Hz)'); ylabel('transmission gain (BP/model)'); title('(a) Gain: alignment & low-pass'); legend('Location','south','FontSize',8);

% (b) optimised residual delay vs freq + phase-derived delay
subplot(2,2,2); hold on
errorbar(freqs, mtau, std(tauS,0,1,'omitnan'),'-o','LineWidth',1.4,'DisplayName','\tau^* (R^2 sweep)');
errorbar(freqs, mphd, std(phDelay,0,1,'omitnan'),'-s','LineWidth',1.4,'DisplayName','phase-derived');
yline(0,'k:','HandleVisibility','off'); yline(tau_pure,'r--',sprintf('pure-delay %.2f s',tau_pure),'HandleVisibility','off');
xlim([0 .21]); grid on; xlabel('tilt frequency (Hz)'); ylabel('residual delay (s)');
title('(b) Optimised alignment / residual delay'); legend('Location','best','FontSize',8);

% (c) R^2 before vs after optimising the delay
subplot(2,2,3); hold on
plot(freqs, mean(R20,1,'omitnan'),'-o','LineWidth',1.4,'DisplayName','R^2 as-aligned');
plot(freqs, mean(R2S,1,'omitnan'),'-s','LineWidth',1.4,'DisplayName','R^2 delay-optimised');
xlim([0 .21]); ylim([0 1]); grid on; xlabel('tilt frequency (Hz)'); ylabel('R^2 (de-pulsed BP vs model)');
title('(c) Fit quality (pulse removed)'); legend('Location','best','FontSize',8);

% (d) example overlay at tau* (VVA017, 0.18 Hz)
subplot(2,2,4); hold on
if ~isempty(ex.t)
    yyaxis left;  plot(ex.t, ex.bp,'LineWidth',1.2); ylabel('de-pulsed finger BP (mmHg)');
    yyaxis right; plot(ex.t, ex.pr,'LineWidth',1.2); ylabel('model -\DeltaP_{fin\rightarrowheart} (mmHg)');
    xlim([0 min(40,ex.t(end))]); xlabel('time (s)');
    title(sprintf('(d) VVA017 0.18 Hz overlay at \\tau^*=%.2f s',ex.tau));
end
sgtitle('Roll-tilt: optimise alignment, test pure-delay vs low-pass','FontWeight','bold');
exportgraphics(fig, fullfile(here,'Fig_RollTilt_alignoptim.png'),'Resolution',180);

%% ---------------- console ----------------
fprintf('\n(A) Alignment optimisation (de-pulsed BP vs tilt-derived model):\n');
fprintf('   f(Hz)   tau*(s)     gain(tau0->tau*)    R^2(tau0->tau*)\n');
for k=1:nF
    fprintf('   %.2f   %+5.2f      %.2f -> %.2f          %.2f -> %.2f\n', freqs(k), ...
        mtau(k), mean(gain0(:,k),'omitnan'), mgain(k), mean(R20(:,k),'omitnan'), mean(R2S(:,k),'omitnan'));
end
fprintf('\n   phase-derived effective delay (s): %s\n', mat2str(round(mphd,3)));
fprintf('   single pure-delay that fits all freqs: %.2f s\n', tau_pure);

fprintf('\n(B) Delay vs low-pass:\n');
fprintf('   first-order low-pass gain fit : A=%.2f, fc=%.2f Hz (SSE %.4f)\n', Afit, fcfit, bestE);
fprintf('   flat-gain (no low-pass) ref   : A=%.2f          (SSE %.4f)\n', flatA, flatE);
if fcfit>=max(fcs)-0.02
    fprintf('   -> best fc at search ceiling: gain is flat, NO low-pass corner in/just-above band.\n');
elseif flatE<=bestE*1.1
    fprintf('   -> flat fit ~ as good as low-pass: data do not require a low-pass.\n');
else
    fprintf('   -> low-pass improves fit: apparent corner near %.2f Hz (3 points, weak).\n', fcfit);
end
fprintf('\nFigure: %s\n', fullfile(here,'Fig_RollTilt_alignoptim.png'));
end

%% ---- least-squares amplitude/phase at frequency f ----
function [amp,ph]=fitfc(t,y,f)
    t=t(:); y=y(:); ok=~isnan(y); t=t(ok); y=y(ok);
    X=[sin(2*pi*f*t), cos(2*pi*f*t), ones(numel(t),1)];
    b=X\y; amp=hypot(b(1),b(2)); ph=atan2(b(2),b(1));
end
