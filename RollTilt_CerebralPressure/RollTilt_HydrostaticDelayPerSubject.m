function RollTilt_HydrostaticDelayPerSubject
% RollTilt_HydrostaticDelayPerSubject
% --------------------------------------------------------------------------
% Optimal BP<->model delay PER SUBJECT and PER FREQUENCY (no collapsing to a
% single number, no assuming a frequency-independent delay).
%
% Two estimators, both signed so POSITIVE = finger BP LAGS the tilt-derived
% hydrostatic model:
%   phase  : tau = phi/(2*pi*f) from the LS sinusoidal fit at the fundamental.
%            Valid at low f (uses every cycle in the trial; a 1 s lag at
%            0.03 Hz is still 11 deg of phase). Unambiguous for |tau|<1/(2f).
%   R2sweep: tau that maximises R^2 of de-pulsed BP ~ model shifted by tau,
%            swept +/-3 s. Better at high f.
%
% The cardiac pulse (~1 Hz) is removed from BP and model by an identical 1 s
% centred moving average. The model is built from the recorded TILT ANGLE, so
% it is immune to the BP alignment and serves as an absolute timing reference.
%
% Reference: the Finometer Pro instrumentation delay is ~1.0 s and was removed
% by the cleandata ECG-align GUI; a per-subject residual near 0 confirms that,
% a residual near +1 s would mean the delay was NOT removed for that subject.
%
% Valentin Siderskiy, 2026

here = fileparts(mfilename('fullpath'));
addpath('C:\Users\sider\Documents\Old Computer Files\C\Users\ValentinSiderskiy\Documents\GitHub\Serrador_Lab');
BATCH = ['C:\Users\sider\Documents\Old Computer Files\C\Users\ValentinSiderskiy\Documents\' ...
         'Serrador_Lab\Projects\MURI\VVA Experiment\STUDY VVA Clone 2022_10_09\SUBJECTS_BATCH_CORRECTED'];
subs = {'VVA012','VVA013','VVA014','VVA015','VVA017','VVA018','VVA019'};
freqs = [0.03 0.10 0.18]; ftok = {'0_03','0_1','0_18'};
ns=numel(subs); nF=numel(freqs);
taus = -8:0.01:8;                   % wide enough to expose aliased neighbouring peaks
wrappi = @(a) mod(a+pi,2*pi)-pi;

tauPh = nan(ns,nF);                 % phase-derived delay (s)
opt1t=nan(ns,nF); opt1r=nan(ns,nF); % best  local optimum of R^2(lag): lag, R^2
opt2t=nan(ns,nF); opt2r=nan(ns,nF); % 2nd-best local optimum: lag, R^2
appShift=nan(ns,nF);                % delay the user dialled in (manual_shift_s)
pttResid=nan(ns,nF);               % saved residual PTT (ptt_resid_samp/SR)
R2curve03 = nan(ns,numel(taus));    % R^2-vs-lag at 0.03 Hz, per subject
R2curve18 = nan(ns,numel(taus));    % R^2-vs-lag at 0.18 Hz, per subject
nonBatch  = false(ns,1);            % flag: loaded from WORKING (NOT corrected batch pipeline)

for s=1:ns
  for k=1:nF
    [fp,isBatch]=resolveClean(BATCH,subs{s},ftok{k});
    if isempty(fp), continue; end
    if ~isBatch, nonBatch(s)=true; end
    D=load(fp,'BP_ecg_aligned','angle_deg','Tilt','t_before','SR','subject_data','manual_shift_s','ptt_resid_samp','BP_delay_shift');
    if ~isfield(D,'BP_ecg_aligned'), continue; end
    bp=D.BP_ecg_aligned(:); t=D.t_before(:); SR=D.SR;
    if isfield(D,'manual_shift_s'), appShift(s,k)=D.manual_shift_s;
    elseif isfield(D,'BP_delay_shift'), appShift(s,k)=abs(D.BP_delay_shift)/SR; end
    if isfield(D,'ptt_resid_samp'), pttResid(s,k)=D.ptt_resid_samp/SR; end
    ang=[]; if isfield(D,'angle_deg'),ang=D.angle_deg(:); elseif isfield(D,'Tilt'),ang=D.Tilt(:); end
    if isempty(ang)||numel(ang)~=numel(bp), continue; end
    sd=D.subject_data;
    [~,dPh2heart]=RollTilt_HydrostatAdj(ang.', sd.PivotTCD, sd.FpcuffTCD, sd.FpcuffHeart, sd.FpcuffMidlin);
    pred=-dPh2heart(:);

    L=round(1.0*SR); bps=movmean(bp,L); prs=movmean(pred,L);
    f=freqs(k); win=t>=35 & t<=t(end)-5;
    if nnz(win)<SR*10, win=t>=t(1)+5; end
    tw=t(win); bw=bps(win); prw=prs(win);

    % phase-derived delay (positive = BP lags model)
    [~,mp]=fitfc(tw,bw,f); [~,pp]=fitfc(tw,prw,f);
    tauPh(s,k)=wrappi(pp-mp)/(2*pi*f);

    % R^2-sweep delay (positive shift = model delayed = BP lags)
    R2v=nan(1,numel(taus));
    for it=1:numel(taus)
        ps=circshift(prs,round(taus(it)*SR)); ps=ps(win);
        X=[ps ones(numel(ps),1)]; b=X\bw; yh=X*b;
        R2v(it)=1-sum((bw-yh).^2)/sum((bw-mean(bw)).^2);
    end
    % top-2 LOCAL maxima of R^2(lag) (an aliased global peak cannot hide the real one)
    ismax=[false, R2v(2:end-1)>R2v(1:end-2) & R2v(2:end-1)>R2v(3:end), false];
    pk=find(ismax); [~,ord]=sort(R2v(pk),'descend'); pk=pk(ord);
    if ~isempty(pk), opt1t(s,k)=taus(pk(1)); opt1r(s,k)=R2v(pk(1)); end
    if numel(pk)>=2, opt2t(s,k)=taus(pk(2)); opt2r(s,k)=R2v(pk(2)); end
    if k==1, R2curve03(s,:)=R2v; elseif k==3, R2curve18(s,:)=R2v; end
  end
end

%% ---------------- console: per-subject matrices ----------------
fprintf('\nPositive = finger BP LAGS the tilt-derived model (s).  Finometer instr. delay ~1.0 s.\n');
if any(nonBatch)
    fprintf('NOTE: %s loaded from WORKING tree (NOT corrected batch pipeline) - marked * below.\n', strjoin(subs(nonBatch),', '));
end
fprintf('applied = delay you dialled in (manual_shift_s) ; pttres = saved residual PTT (ptt_resid_samp) ;\n');
fprintf('phase = phase-derived residual ; opt1/opt2 = best two LOCAL maxima of R^2(lag) and their R^2.\n');
fprintf('\n  sub         f     applied  pttres   phase     opt1_t (R2)     opt2_t (R2)\n');
for s=1:ns
  for k=1:nF
    if isnan(tauPh(s,k)) && isnan(opt1t(s,k)), continue; end
    fprintf('  %-7s %s  %.2f   %6.2f  %6.2f   %+6.2f    %+6.2f(%.2f)   %+6.2f(%.2f)\n', ...
        subs{s}, char('*'*nonBatch(s)+' '*~nonBatch(s)), freqs(k), ...
        appShift(s,k), pttResid(s,k), tauPh(s,k), opt1t(s,k),opt1r(s,k), opt2t(s,k),opt2r(s,k));
  end
end
fprintf('\nphase-derived delay  MEAN+/-SD by freq:  0.03 %.2f+/-%.2f   0.10 %.2f+/-%.2f   0.18 %.2f+/-%.2f\n', ...
    mean(tauPh(:,1),'omitnan'),std(tauPh(:,1),'omitnan'), mean(tauPh(:,2),'omitnan'),std(tauPh(:,2),'omitnan'), ...
    mean(tauPh(:,3),'omitnan'),std(tauPh(:,3),'omitnan'));

%% ---------------- figure ----------------
fig=figure('Color','w','Units','centimeters','Position',[1 1 24 16]);
cmap=lines(ns);

% (a) phase-derived delay per subject
subplot(2,2,1); hold on
for s=1:ns, plot(freqs,tauPh(s,:),'-o','Color',cmap(s,:),'LineWidth',1,'DisplayName',subs{s}); end
plot(freqs,mean(tauPh,1,'omitnan'),'k-s','LineWidth',2,'DisplayName','MEAN');
yline(0,'k:','HandleVisibility','off'); yline(1,'r--','1 s (instr.)','HandleVisibility','off');
xlim([0 .21]); grid on; xlabel('tilt frequency (Hz)'); ylabel('BP-lag delay (s)');
title('(a) Phase-derived delay per subject'); legend('Location','eastoutside','FontSize',7);

% (b) best two local R^2 optima per subject (opt1 filled, opt2 open)
subplot(2,2,2); hold on
for s=1:ns
    plot(freqs,opt1t(s,:),'o','Color',cmap(s,:),'MarkerFaceColor',cmap(s,:),'MarkerSize',5,'HandleVisibility','off');
    plot(freqs,opt2t(s,:),'o','Color',cmap(s,:),'MarkerSize',5,'HandleVisibility','off');
end
yline(0,'k:'); yline(1,'r--','1 s (instr.)'); yline(-1,'r--','HandleVisibility','off');
ylim([-3 3]); xlim([0 .21]); grid on; xlabel('tilt frequency (Hz)'); ylabel('local-optimum lag (s)');
title('(b) Two best R^2 optima (filled=1st, open=2nd)');

% (c) R^2-vs-lag at 0.18 Hz (peak sharpness, high freq)
subplot(2,2,3); hold on
for s=1:ns, plot(taus,R2curve18(s,:),'Color',cmap(s,:),'LineWidth',1); end
xline(0,'k:'); xlim([-6 6]); grid on; xlabel('imposed model delay (s)'); ylabel('R^2');
title('(c) R^2 vs lag @ 0.18 Hz (multiple aliased peaks)');

% (d) R^2-vs-lag at 0.03 Hz (peak sharpness, low freq)
subplot(2,2,4); hold on
for s=1:ns, plot(taus,R2curve03(s,:),'Color',cmap(s,:),'LineWidth',1); end
xline(0,'k:'); xlim([-8 8]); grid on; xlabel('imposed model delay (s)'); ylabel('R^2');
title('(d) R^2 vs lag @ 0.03 Hz (broad => use phase)');

sgtitle('Roll-tilt: per-subject optimal BP<->model delay','FontWeight','bold');
exportgraphics(fig, fullfile(here,'Fig_RollTilt_delay_persubject.png'),'Resolution',180);
fprintf('\nFigure: %s\n', fullfile(here,'Fig_RollTilt_delay_persubject.png'));
end

%% ---- resolve a DARK clean.mat, tolerant of folder-name variants ----
% Tries the corrected batch tree first (isBatch=true), then the older WORKING
% tree (isBatch=false). Token-exact so 0_1 never matches 0_18. Skips not_RED.
function [fp,isBatch]=resolveClean(BATCH,sub,tok)
    fp=''; isBatch=false;
    roots={fullfile(BATCH,sub), fullfile(fileparts(BATCH),'SUBJECTS',sub,'WORKING')};
    pat=['DARK' regexptranslate('escape',tok) '(_|v)'];   % token followed by _ or v (e.g. _v2)
    for r=1:numel(roots)
        d=dir(fullfile(roots{r},['*DARK' tok '*_VS'],'*clean.mat'));
        for i=1:numel(d)
            if ~isempty(regexp(d(i).folder,pat,'once'))
                fp=fullfile(d(i).folder,d(i).name); isBatch=(r==1); return;
            end
        end
    end
end

%% ---- least-squares amplitude/phase at frequency f (y ~ amp*sin(2*pi*f*t+ph)) ----
function [amp,ph]=fitfc(t,y,f)
    t=t(:); y=y(:); ok=~isnan(y); t=t(ok); y=y(ok);
    X=[sin(2*pi*f*t), cos(2*pi*f*t), ones(numel(t),1)];
    b=X\y; amp=hypot(b(1),b(2)); ph=atan2(b(2),b(1));
end
