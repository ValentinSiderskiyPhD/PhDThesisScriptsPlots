function RollTilt_HydrostaticTransmission
% RollTilt_HydrostaticTransmission
% --------------------------------------------------------------------------
% Two waveform-based (non-sinusoidal) tests of how faithfully the predicted
% hydrostatic gradient shows up in the measured finger BP, aimed at the
% HIGH-frequency end:
%
%  (1) WAVEFORM-REGRESSION GAIN.  Regress measured BP on the *model* waveform
%      (the predicted hydrostatic dP, which already carries the true
%      triangular/asymmetric shape): BP = gain*pred + offset, at the best lag.
%      The slope is the transmission gain using the whole shape (no sine
%      assumption); R^2 is the fraction of BP the model explains.
%
%  (2) HARMONIC TRANSFER.  A triangular tilt at f carries energy at f, 3f, 5f...
%      The hydrostatic model passes the same harmonics. So from the existing
%      0.03/0.10/0.18 Hz trials we read the measured/predicted amplitude ratio
%      (and phase) at each harmonic and assemble a transmission curve up to
%      ~1 Hz WITHOUT a faster tilt. Per-bin Welch coherence (toolbox-free)
%      flags which harmonics to trust (low where the cardiac pulse dominates).
%
% Measured  = BP_ecg_aligned (de-delayed finger BP, BEFORE hydrostatic corr).
% Predicted = -deltaPfin2heart from RollTilt_HydrostatAdj.
%
% Valentin Siderskiy, 2026

here = fileparts(mfilename('fullpath'));
addpath('C:\Users\sider\Documents\Old Computer Files\C\Users\ValentinSiderskiy\Documents\GitHub\Serrador_Lab');
BATCH = ['C:\Users\sider\Documents\Old Computer Files\C\Users\ValentinSiderskiy\Documents\' ...
         'Serrador_Lab\Projects\MURI\VVA Experiment\STUDY VVA Clone 2022_10_09\SUBJECTS_BATCH_CORRECTED'];
subs = {'VVA012','VVA013','VVA014','VVA015','VVA017','VVA018','VVA019'};
freqs = [0.03 0.10 0.18]; ftok = {'0_03','0_1','0_18'};
ns = numel(subs); nF = numel(freqs);
nH = 6;                                   % harmonics 1..6
wrappi = @(a) mod(a+pi,2*pi)-pi;

gainW=nan(ns,nF); R2W=nan(ns,nF); lagW=nan(ns,nF);        % (1) waveform regression
Hf=nan(ns,nF,nH); Hg=nan(ns,nF,nH); Hc=nan(ns,nF,nH); Hd=nan(ns,nF,nH);  % (2) harmonics: freq, gain, coh, delay(s)
lags = -1.0:0.02:1.0;

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
    pred = -dPh2heart(:);

    f=freqs(k); win = t>=35 & t<=t(end)-5;
    if nnz(win)<SR*10, win = t>=t(1)+5; end
    bw=bp(win); pw=pred(win); tw=t(win);

    % ---- (1) best-lag waveform regression: gain = slope of BP on shifted model ----
    bestR2=-inf;
    for li=1:numel(lags)
        ps=circshift(pred,round(lags(li)*SR)); ps=ps(win);
        X=[ps, ones(numel(ps),1)]; b=X\bw; yh=X*b;
        R2=1-sum((bw-yh).^2)/sum((bw-mean(bw)).^2);
        if R2>bestR2, bestR2=R2; gainW(s,k)=b(1); R2W(s,k)=R2; lagW(s,k)=lags(li); end
    end

    % ---- (2) harmonic transfer: amp/phase at h*f by LS, coherence by Welch ----
    [C,fax]=welchcoh(pw,bw,SR);
    for h=1:nH
        fh=h*f;
        [ma,mp]=fitfc(tw,bw,fh); [pa,php]=fitfc(tw,pw,fh);
        Hf(s,k,h)=fh; Hg(s,k,h)=ma/pa;
        Hd(s,k,h)=wrappi(mp-php)/(2*pi*fh);                 % effective delay (s)
        if ~isempty(C), Hc(s,k,h)=interp1(fax,C,fh,'linear',NaN); end
    end
  end
end

%% ---------------- aggregate ----------------
% pooled harmonic points (mean over subjects), one per (trial-freq, harmonic)
pf = reshape(mean(Hf,1,'omitnan'),nF,nH);
pg = reshape(mean(Hg,1,'omitnan'),nF,nH);
pgs= reshape(std (Hg,0,1,'omitnan'),nF,nH);
pc = reshape(mean(Hc,1,'omitnan'),nF,nH);
pd = reshape(mean(Hd,1,'omitnan'),nF,nH);
pds= reshape(std (Hd,0,1,'omitnan'),nF,nH);
COH_OK = 0.5;

%% ---------------- figure ----------------
fig=figure('Color','w','Units','centimeters','Position',[1 1 24 16]);
cols=lines(nF);

% (a) waveform-regression gain vs tilt freq
subplot(2,2,1); hold on
errorbar(freqs, mean(gainW,1,'omitnan'), std(gainW,0,1,'omitnan'),'-o','LineWidth',1.5,'Color',[0 .45 .74]);
for s=1:ns, plot(freqs,gainW(s,:),'.','Color',[.6 .6 .6],'HandleVisibility','off'); end
yline(1,'k--'); xlim([0 .21]); grid on
for k=1:nF, text(freqs(k),0.55,sprintf('R^2=%.2f',mean(R2W(:,k),'omitnan')),'HorizontalAlignment','center','FontSize',8); end
xlabel('tilt frequency (Hz)'); ylabel('transmission gain (BP / model)'); title('(a) Waveform-regression gain'); ylim([0.4 1.4])

% (b) harmonic transmission gain vs absolute frequency, sized/coloured by coherence
subplot(2,2,2); hold on
for k=1:nF
  for h=1:nH
    if isnan(pf(k,h)), continue; end
    trust = pc(k,h)>=COH_OK;
    ms = 4+18*max(pc(k,h),0);
    plot(pf(k,h),pg(k,h),'o','MarkerSize',ms/2,'MarkerFaceColor',cols(k,:).*[1 1 1]*(trust)+[1 1 1]*(~trust)*0.85, ...
         'MarkerEdgeColor',cols(k,:),'LineWidth',1);
  end
end
% trend through trusted points only
xa=pf(:); ga=pg(:); ca=pc(:); ok=~isnan(xa)&ca>=COH_OK;
[xs,si]=sort(xa(ok)); gs=ga(ok); gs=gs(si);
plot(xs,gs,'-','Color',[.3 .3 .3],'LineWidth',1.2,'HandleVisibility','off');
yline(1,'k--','full transmission'); xlim([0 1.05]); ylim([0 1.6]); grid on
xlabel('frequency (Hz)  [tilt fundamental + harmonics]'); ylabel('transmission gain (BP / model)');
title('(b) Harmonic transmission  (marker \propto coherence)');
text(0.5,0.12,'faded = coherence < 0.5 (untrustworthy)','FontSize',8,'Color',[.4 .4 .4]);

% (c) effective delay vs frequency (trusted harmonics)
subplot(2,2,3); hold on
for k=1:nF
  for h=1:nH
    if isnan(pf(k,h))||pc(k,h)<COH_OK, continue; end
    errorbar(pf(k,h),pd(k,h),pds(k,h),'o','Color',cols(k,:),'MarkerFaceColor',cols(k,:),'CapSize',3);
  end
end
yline(0,'k:'); xlim([0 1.05]); grid on
xlabel('frequency (Hz)'); ylabel('effective delay (s)'); title('(c) Residual timing (trusted harmonics)');

% (d) coherence vs frequency
subplot(2,2,4); hold on
for k=1:nF
  m=~isnan(pf(k,:));
  plot(pf(k,m),pc(k,m),'-o','Color',cols(k,:),'LineWidth',1.2,'DisplayName',sprintf('%.2f Hz tilt',freqs(k)));
end
yline(COH_OK,'k--','trust threshold'); xlim([0 1.05]); ylim([0 1]); grid on
xlabel('frequency (Hz)'); ylabel('coherence (model vs BP)'); title('(d) Coherence'); legend('Location','northeast','FontSize',8);

sgtitle('Roll-tilt hydrostatic transmission: waveform regression + harmonic transfer','FontWeight','bold');
exportgraphics(fig, fullfile(here,'Fig_RollTilt_transmission.png'),'Resolution',180);

%% ---------------- console ----------------
fprintf('\n(1) Waveform-regression transmission gain (slope of BP on model, best lag):\n');
for k=1:nF, fprintf('  %.2f Hz: gain %.2f +/- %.2f   R^2 %.2f   lag %+.2f s\n', freqs(k), ...
    mean(gainW(:,k),'omitnan'),std(gainW(:,k),'omitnan'),mean(R2W(:,k),'omitnan'),mean(lagW(:,k),'omitnan')); end
fprintf('\n(2) Harmonic transmission (freq Hz : gain +/- SD , coherence):\n');
for k=1:nF
  fprintf('  tilt %.2f Hz\n',freqs(k));
  for h=1:nH
    if isnan(pf(k,h)), continue; end
    flag=''; if pc(k,h)<COH_OK, flag='  (low coh)'; end
    fprintf('    %5.3f Hz : %.2f +/- %.2f , coh %.2f%s\n', pf(k,h), pg(k,h), pgs(k,h), pc(k,h), flag);
  end
end
fprintf('\nFigure: %s\n', fullfile(here,'Fig_RollTilt_transmission.png'));
end

%% ---- least-squares amplitude/phase at frequency f ----
function [amp,ph]=fitfc(t,y,f)
    t=t(:); y=y(:); ok=~isnan(y); t=t(ok); y=y(ok);
    X=[sin(2*pi*f*t), cos(2*pi*f*t), ones(numel(t),1)];
    b=X\y; amp=hypot(b(1),b(2)); ph=atan2(b(2),b(1));
end

%% ---- toolbox-free Welch magnitude-squared coherence (Hann, 50% overlap) ----
function [C,fax]=welchcoh(x,y,SR)
    x=x(:); y=y(:); ok=~isnan(x)&~isnan(y); x=x(ok); y=y(ok);
    N=numel(x); K=6; L=floor(2*N/(K+1)); if mod(L,2), L=L-1; end
    if L<32, C=[]; fax=[]; return; end
    w=0.5-0.5*cos(2*pi*(0:L-1).'/(L-1)); step=floor(L/2);
    Sxx=zeros(L,1); Syy=zeros(L,1); Sxy=zeros(L,1); i=1;
    while i+L-1<=N
        xi=detrend(x(i:i+L-1)).*w; yi=detrend(y(i:i+L-1)).*w;
        Xi=fft(xi); Yi=fft(yi);
        Sxx=Sxx+abs(Xi).^2; Syy=Syy+abs(Yi).^2; Sxy=Sxy+conj(Xi).*Yi;
        i=i+step;
    end
    C=abs(Sxy).^2./(Sxx.*Syy);
    fax=(0:L-1).'*SR/L; half=1:floor(L/2);
    C=C(half); fax=fax(half);
end
