function RollTilt_HydrostaticPlayground
% RollTilt_HydrostaticPlayground
% --------------------------------------------------------------------------
% Uses the real VVA roll-tilt data as a playground to probe the static
% hydrostatic model for unaccounted effects:
%   (A) DAMPING  - measured tilt-locked finger-BP modulation vs the predicted
%                  hydrostatic dP, as an amplitude ratio across frequency
%                  (ratio < 1 and falling => the hydrostatic effect is dampened).
%   (B) DELAY    - phase difference (effective lag) vs frequency, and a lag
%                  sweep that finds the timing that best aligns measured & predicted.
%   (C) GEOMETRY - sensitivity of the prediction to a +/-0.5 cm error in each
%                  measured distance.
%
% Measured  = BP_ecg_aligned (de-delayed finger BP, BEFORE hydrostatic correction).
% Predicted = -deltaPfin2heart from RollTilt_HydrostatAdj (the finger's own
%             hydrostatic pressure change). Both fit at the tilt frequency by
%             least squares over the steady-state motion window.
%
% Valentin Siderskiy, 2026

here = fileparts(mfilename('fullpath'));
addpath('C:\Users\sider\Documents\Old Computer Files\C\Users\ValentinSiderskiy\Documents\GitHub\Serrador_Lab');
BATCH = ['C:\Users\sider\Documents\Old Computer Files\C\Users\ValentinSiderskiy\Documents\' ...
         'Serrador_Lab\Projects\MURI\VVA Experiment\STUDY VVA Clone 2022_10_09\SUBJECTS_BATCH_CORRECTED'];
subs = {'VVA012','VVA013','VVA014','VVA015','VVA017','VVA018','VVA019'};
freqs = [0.03 0.10 0.18]; ftok = {'0_03','0_1','0_18'};
ns = numel(subs); nF = numel(freqs);

mAmp=nan(ns,nF); pAmp=nan(ns,nF); dPhase=nan(ns,nF);     % measured/predicted amp, phase diff (rad)
lags = -1.0:0.02:1.0; bestLag=nan(ns,nF);               % delay sweep (s)
R2lag = nan(ns,nF,numel(lags));

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
    pred = -dPh2heart(:);                                % finger's own hydrostatic pressure change

    f=freqs(k); win = t>=35 & t<=t(end)-5;               % steady-state motion window
    if nnz(win)<SR*10, win = t>=t(1)+5; end
    tw=t(win);
    [ma,mp]=fitfc(tw, bp(win),  f);                      % measured amp, phase
    [pa,pp]=fitfc(tw, pred(win),f);                      % predicted amp, phase
    mAmp(s,k)=ma; pAmp(s,k)=pa;
    dPhase(s,k)=wrapToPi(mp-pp);

    % --- (B) lag sweep: shift predicted, R^2 of measured ~ shifted predicted ---
    for li=1:numel(lags)
        sh=round(lags(li)*SR);
        ps=circshift(pred,sh);
        X=[ps(win), ones(nnz(win),1)]; b=X\bp(win); yh=X*b;
        R2lag(s,k,li)=1 - sum((bp(win)-yh).^2)/sum((bp(win)-mean(bp(win))).^2);
    end
    [~,bi]=max(squeeze(R2lag(s,k,:))); bestLag(s,k)=lags(bi);
  end
end

ratio = mAmp./pAmp;
delay_s = dPhase ./ (2*pi*repmat(freqs,ns,1));            % phase diff -> seconds

%% ---------------- (C) geometry sensitivity (+/-0.5 cm on each distance) ----------------
% mean over subjects of |d(pred amp)/pred amp| for a 0.5 cm change, per distance, at each freq.
S = load(fullfile(fileparts(BATCH),'SUBJECTS','VVA_Participent_meta_data.mat')); T=S.VVAParticipentmetadata; ids=string(T.ID);
dnames={'PivotTCD','FpcuffTCD','FpcuffHeart','FpcuffMidlin'};
mcols ={'VestibularTCDToPivotcm','VestibularFinToTCDcm','VestibularFinToHeartcm','VestibularFinToMidlinecm'};
sens=nan(numel(dnames),nF);
for di=1:numel(dnames)
  pct=nan(ns,nF);
  for s=1:ns
    r=ids==subs{s}; if ~any(r),continue; end
    g=[double(T.VestibularTCDToPivotcm(r)) double(T.VestibularFinToTCDcm(r)) double(T.VestibularFinToHeartcm(r)) double(T.VestibularFinToMidlinecm(r))];
    if any(isnan(g)),continue; end
    for k=1:nF
      f=freqs(k); t=0:0.01:max(3/f,20); ang=25*sin(2*pi*f*t);
      base=ppamp(ang,g); g2=g; g2(di)=g2(di)+0.5; pert=ppamp(ang,g2);
      pct(s,k)=100*abs(pert-base)/max(base,eps);
    end
  end
  sens(di,:)=mean(pct,1,'omitnan');
end

%% ---------------- FIGURE ----------------
fig=figure('Color','w','Units','centimeters','Position',[1 1 24 16]);
% (a) measured vs predicted amplitude
subplot(2,2,1); hold on
plot(freqs, mean(mAmp,1,'omitnan'),'-o','LineWidth',1.5,'DisplayName','measured (finger BP)');
plot(freqs, mean(pAmp,1,'omitnan'),'-s','LineWidth',1.5,'DisplayName','predicted (hydrostatic)');
for s=1:ns, plot(freqs,mAmp(s,:),'-','Color',[0 .45 .74 .25],'HandleVisibility','off'); end
xlabel('tilt frequency (Hz)'); ylabel('tilt-locked amplitude (mmHg)'); title('(a) Measured vs predicted'); legend('Location','northwest'); grid on; xlim([0 .21])
% (b) damping ratio
subplot(2,2,2); hold on
errorbar(freqs, mean(ratio,1,'omitnan'), std(ratio,0,1,'omitnan'),'-o','LineWidth',1.5);
for s=1:ns, plot(freqs,ratio(s,:),'.','Color',[.6 .6 .6],'HandleVisibility','off'); end
yline(1,'k--','full transmission'); xlabel('tilt frequency (Hz)'); ylabel('measured / predicted'); title('(b) Damping check'); grid on; xlim([0 .21])
% (c) effective delay
subplot(2,2,3); hold on
errorbar(freqs, mean(delay_s,1,'omitnan'), std(delay_s,0,1,'omitnan'),'-o','LineWidth',1.5,'DisplayName','from phase');
errorbar(freqs, mean(bestLag,1,'omitnan'), std(bestLag,0,1,'omitnan'),'-s','LineWidth',1.5,'DisplayName','from lag sweep');
yline(0,'k:'); xlabel('tilt frequency (Hz)'); ylabel('effective delay (s)'); title('(c) Residual timing'); legend('Location','best'); grid on; xlim([0 .21])
% (d) geometry sensitivity
subplot(2,2,4);
bar(categorical(strrep(dnames,'Fpcuff','')), sens); ylabel('% change in pred. amp. per 0.5 cm');
title('(d) Geometry sensitivity'); legend(arrayfun(@(x)sprintf('%.2f Hz',x),freqs,'uni',0),'Location','best'); grid on
sgtitle('Roll-tilt hydrostatic: measured vs model (damping, delay, geometry)','FontWeight','bold');
exportgraphics(fig, fullfile(here,'Fig_RollTilt_playground.png'),'Resolution',180);

%% ---------------- console summary ----------------
fprintf('\nMeasured / predicted hydrostatic amplitude (mean +/- SD):\n');
for k=1:nF, fprintf('  %.2f Hz: %.2f +/- %.2f   (meas %.1f, pred %.1f mmHg)\n', freqs(k), ...
    mean(ratio(:,k),'omitnan'),std(ratio(:,k),'omitnan'), mean(mAmp(:,k),'omitnan'),mean(pAmp(:,k),'omitnan')); end
fprintf('\nEffective residual delay (phase / lag-sweep, s):\n');
for k=1:nF, fprintf('  %.2f Hz: %+.3f / %+.3f s\n', freqs(k), mean(delay_s(:,k),'omitnan'), mean(bestLag(:,k),'omitnan')); end
fprintf('\nGeometry sensitivity (%% change in pred amp per 0.5 cm, at 0.18 Hz):\n');
for di=1:numel(dnames), fprintf('  %-12s %.1f%%\n', dnames{di}, sens(di,3)); end
fprintf('\nFigure: %s\n', fullfile(here,'Fig_RollTilt_playground.png'));
end

%% ---- least-squares fit of a sinusoid at frequency f: returns amplitude, phase ----
function [amp,ph]=fitfc(t,y,f)
    t=t(:); y=y(:); ok=~isnan(y); t=t(ok); y=y(ok);
    X=[sin(2*pi*f*t), cos(2*pi*f*t), ones(numel(t),1)];
    b=X\y; amp=hypot(b(1),b(2)); ph=atan2(b(2),b(1));
end

%% ---- predicted finger-BP tilt amplitude for geometry g=[d1 d2 d3 ax] ----
function a=ppamp(ang,g)
    [~,dPh2heart]=RollTilt_HydrostatAdj(ang, g(1),g(2),g(3),g(4));
    p=-dPh2heart(:); a=(max(p)-min(p))/2;   % half peak-to-peak as the amplitude proxy
end
