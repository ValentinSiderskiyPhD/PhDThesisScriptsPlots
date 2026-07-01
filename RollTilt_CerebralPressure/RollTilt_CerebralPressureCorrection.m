function RollTilt_CerebralPressureCorrection
% RollTilt_CerebralPressureCorrection
% --------------------------------------------------------------------------
% Roll-tilt analog of the "Pitch-Tilt Cerebral Pressure Correction" in the
% Siderskiy / Clark / Serrador modelling paper, in the SAME figure style:
% per correction term, columns = tilt frequencies, rows = chair position /
% (acceleration) / DeltaP average +/- SD / raw DeltaP per subject.
%
% Terms (finger -> head, the cerebral correction):
%   Hydrostatic (static)  : RollTilt_HydrostatAdj
%   Centripetal (at 2f)   : dP = rho * w^2 * (r_b^2 - r_fin^2)/2
%   Euler / tangential(f) : dP = -rho * alpha * (p_fin x p_b)_x
%   Bernoulli             : dP = 1/2 rho (v_carotid^2 - v_MCA^2)   (from real CFV)
%
% Geometry: ALL participants with a complete vestibular-geometry row in the
% metadata (matching how the paper simulated 14 subjects). Tilt simulated at the
% study amplitude (+/-25 deg). A speculative 0.5 Hz column shows where the
% dynamic terms grow above precision.
%
% Outputs (this folder): Fig_* PNGs, a results CSV, and a text summary.
% Valentin Siderskiy, 2026

%% ---------------- paths / constants ----------------
here = fileparts(mfilename('fullpath'));
addpath('C:\Users\sider\Documents\Old Computer Files\C\Users\ValentinSiderskiy\Documents\GitHub\Serrador_Lab');
DATA = ['C:\Users\sider\Documents\Old Computer Files\C\Users\ValentinSiderskiy\Documents\' ...
        'Serrador_Lab\Projects\MURI\VVA Experiment\STUDY VVA Clone 2022_10_09'];
META  = fullfile(DATA,'SUBJECTS','VVA_Participent_meta_data.mat');
BATCH = fullfile(DATA,'SUBJECTS_BATCH_CORRECTED');

rho = 1050; Pa2mmHg = 0.00750062; vcar = 0.6;
theta0 = 25;                                   % study tilt amplitude (deg)
PREC = 2.0;                                    % Finapres precision (mmHg p-p)
freqs = [0.03 0.10 0.18 0.50];                 % last column speculative
flab  = {'0.03 Hz','0.10 Hz','0.18 Hz','0.50 Hz*'};
nF = numel(freqs); npts = 240;

%% ---------------- ALL participants with geometry ----------------
S = load(META); T = S.VVAParticipentmetadata; ids = string(T.ID);
G = struct('subj',{},'d1',{},'d2',{},'d3',{},'ax',{});
for i = 1:height(T)
    d1=double(T.VestibularTCDToPivotcm(i)); d2=double(T.VestibularFinToTCDcm(i));
    d3=double(T.VestibularFinToHeartcm(i));  ax=double(T.VestibularFinToMidlinecm(i));
    if any(isnan([d1 d2 d3 ax])), continue; end
    if any(strcmp('Handedness',T.Properties.VariableNames)) && string(T.Handedness(i))=="L", ax=-ax; end
    G(end+1)=struct('subj',char(ids(i)),'d1',d1,'d2',d2,'d3',d3,'ax',ax); %#ok<AGROW>
end
ns = numel(G); subjIDs = {G.subj};
fprintf('Using geometry from %d participants: %s\n', ns, strjoin(subjIDs,', '));

% geometry-derived quantities (m)
for s=1:ns
    d1=G(s).d1/100; d2=G(s).d2/100; d3=G(s).d3/100; ax=G(s).ax/100;
    G(s).r_fin2 = ax^2 + (d1+d2)^2;  G(s).r_head2 = d1^2;
    G(s).cross_head = ax*d1;          G(s).head_eta = d1;
end

%% ---------------- simulate DeltaP(t) over one cycle, per freq ----------------
DP_hyd = cell(1,nF); DP_cen = cell(1,nF); DP_eul = cell(1,nF);
TILT   = cell(1,nF); ACC = cell(1,nF); TV = cell(1,nF);
for k=1:nF
    f=freqs(k); t=linspace(0,1/f,npts); w=2*pi*f; th0=deg2rad(theta0);
    th = theta0*sin(w*t);                          % deg
    om = th0*w*cos(w*t);                           % rad/s
    al = -th0*w^2*sin(w*t);                        % rad/s^2
    TV{k}=t; TILT{k}=th;
    dh=nan(ns,npts); dc=nan(ns,npts); de=nan(ns,npts); ac=nan(ns,npts);
    for s=1:ns
        [~,dPhead]=RollTilt_HydrostatAdj(th, G(s).d1,G(s).d2,G(s).d3,G(s).ax);
        dh(s,:)=dPhead - mean(dPhead);                                   % center (show modulation)
        dc(s,:)=rho*(om.^2).*(G(s).r_head2-G(s).r_fin2)/2 * Pa2mmHg;
        de(s,:)=-rho*al*G(s).cross_head * Pa2mmHg;
        ac(s,:)=al*sqrt(G(s).r_fin2);                                    % tangential accel at finger (m/s^2)
    end
    DP_hyd{k}=dh; DP_cen{k}=dc; DP_eul{k}=de; ACC{k}=ac;
end

%% ---------------- Bernoulli from real MCA velocity (CBF subjects) ----------------
ftok={'0_03','0_1','0_18',''}; pp_bern=nan(ns,nF);
for s=1:ns, for k=1:3
    fp=fullfile(BATCH,G(s).subj,[G(s).subj '_DARK' ftok{k} '_VS'],[G(s).subj '_DARK' ftok{k} '_VS_clean.mat']);
    if exist(fp,'file')~=2, continue; end
    w=load(fp,'MBVicm','MBVcm','BVcm'); v=[];
    if isfield(w,'MBVicm'),v=w.MBVicm(:); elseif isfield(w,'MBVcm'),v=w.MBVcm(:); elseif isfield(w,'BVcm'),v=w.BVcm(:); end
    if isempty(v), continue; end
    v=v(~isnan(v))/100; b=0.5*rho*(vcar^2-v.^2)*Pa2mmHg;
    pp_bern(s,k)=pctl(b,99)-pctl(b,1);
end, end

%% ---------------- peak-to-peak summary ----------------
pp=@(M) max(M,[],2)-min(M,[],2);
PPh=cell2mat(cellfun(@(M) pp(M),DP_hyd,'uni',0)); % ns x nF
PPc=cell2mat(cellfun(@(M) pp(M),DP_cen,'uni',0));
PPe=cell2mat(cellfun(@(M) pp(M),DP_eul,'uni',0));
mns=@(x) sprintf('%6.3f +/- %5.3f',mean(x,'omitnan'),std(x,'omitnan'));
fid=fopen(fullfile(here,'RollTilt_pressure_terms_summary.txt'),'w'); pr=@(varargin) fprintf2(fid,varargin{:});
pr('Roll-tilt finger->head pressure terms, peak-to-peak (mmHg), n=%d (geometry); theta0=%d deg\n',ns,theta0);
pr('Finapres precision = %.1f mmHg.  (* 0.5 Hz is speculative, outside the VVA band)\n\n',PREC);
pr('%-9s | %-16s | %-16s | %-16s | %-16s\n','f (Hz)','Hydrostatic','Centripetal','Euler','Bernoulli');
pr('%s\n',repmat('-',1,80));
for k=1:nF
    pr('%-9s | %-16s | %-16s | %-16s | %-16s\n',flab{k},mns(PPh(:,k)),mns(PPc(:,k)),mns(PPe(:,k)),mns(pp_bern(:,k)));
end
pr('\nLargest p-p across subjects: centripetal %.3f, Euler %.3f, Bernoulli %.3f mmHg (in VVA band <=0.18 Hz)\n',...
   max(max(PPc(:,1:3))),max(max(PPe(:,1:3))),max(pp_bern(:,1:3),[],'all'));
pr('Hydrostatic p-p ~ %.1f mmHg.  Conclusion: only hydrostatic exceeds precision in the VVA band.\n',mean(PPh(:,1)));
fclose(fid); type(fullfile(here,'RollTilt_pressure_terms_summary.txt'));

%% ---------------- FIGURES (paper style) ----------------
panelfig('Centripetal', '\DeltaP_{centr} (mmHg)', DP_cen, [], TILT, TV, flab, subjIDs, PREC, fullfile(here,'Fig_RollTilt_centripetal.png'));
panelfig('Euler / tangential', '\DeltaP_{x} (mmHg)', DP_eul, ACC, TILT, TV, flab, subjIDs, PREC, fullfile(here,'Fig_RollTilt_euler.png'));
panelfig('Hydrostatic (centered)', '\DeltaP_{head} (mmHg)', DP_hyd, [], TILT, TV, flab, subjIDs, [], fullfile(here,'Fig_RollTilt_hydrostatic.png'));
trajfig(G, fullfile(here,'Fig_RollTilt_geometry.png'));

% CSV
C={'subject','freq_Hz','pp_hydrostatic','pp_centripetal','pp_euler','pp_bernoulli'};
for s=1:ns, for k=1:nF, C(end+1,:)={G(s).subj,freqs(k),PPh(s,k),PPc(s,k),PPe(s,k),pp_bern(s,k)}; end, end %#ok<AGROW>
writecell(C,fullfile(here,'RollTilt_pressure_terms.csv'));
fprintf('\nDone. Outputs in:\n  %s\n',here);
end

%% ============ multi-panel figure: rows = tilt / [accel] / dP avg+/-SD / raw ============
function panelfig(ttl, ylab, DP, ACC, TILT, TV, flab, subjIDs, PREC, outpng)
    nF=numel(DP); ns=size(DP{1},1); haveAcc=~isempty(ACC);
    nrow=3+haveAcc;
    f=figure('Color','w','Units','centimeters','Position',[1 1 24 4+3*nrow]);
    cmap=lines(ns);
    for k=1:nF
        t=TV{k};
        % row 1: tilt position
        subplot(nrow,nF,k); plot(t,TILT{k},'k','LineWidth',1.2); yline(0,'k:'); axis tight
        if k==1, ylabel({'Tilt','(\circ)'}); end; title(flab{k},'FontWeight','bold'); set(gca,'XTickLabel',[])
        r=1;
        if haveAcc
            r=r+1; subplot(nrow,nF,k+(r-1)*nF);
            plot(t,mean(ACC{k},1),'Color',[0 0 .8],'LineWidth',1.2); yline(0,'k:'); axis tight
            if k==1, ylabel({'a_x','(m/s^2)'}); end; set(gca,'XTickLabel',[])
        end
        % row: avg +/- SD band
        r=r+1; subplot(nrow,nF,k+(r-1)*nF); hold on
        m=mean(DP{k},1,'omitnan'); sd=std(DP{k},0,1,'omitnan');
        fill([t fliplr(t)],[m+sd fliplr(m-sd)],[.8 .8 .8],'EdgeColor','none');
        plot(t,m,'k','LineWidth',1.4); yline(0,'k:');
        if ~isempty(PREC), yline(PREC/2,'r:'); yline(-PREC/2,'r:'); end
        axis tight; if k==1, ylabel(ylab); end; set(gca,'XTickLabel',[])
        % row: raw per subject
        r=r+1; subplot(nrow,nF,k+(r-1)*nF); hold on
        for s=1:ns, plot(t,DP{k}(s,:),'Color',cmap(s,:),'LineWidth',.6); end
        yline(0,'k:'); axis tight; if k==1, ylabel({'Raw',ylab}); end; xlabel('time (s)')
    end
    sgtitle(sprintf('%s: chair position and \\DeltaP (average and raw)',ttl),'FontWeight','bold');
    lg=legend(subjIDs,'Orientation','vertical','FontSize',7); lg.Position=[0.915 0.25 0.075 0.55];
    exportgraphics(f,outpng,'Resolution',180);
end

%% ============ finger trajectory + geometry ============
function trajfig(G, outpng)
    f=figure('Color','w','Units','centimeters','Position',[2 2 16 8]);
    g=mean([[G.d1];[G.d2];[G.d3];[G.ax]],2)/100; d1=g(1);d2=g(2);d3=g(3);ax=g(4);
    P=[0 d1; ax d1+d2; 0 d1+d2-d3]; names={'head','finger','heart'}; mk={'r^','bs','mv'};
    subplot(1,2,1); hold on
    for th=linspace(-25,25,9)
        R=[cosd(th) -sind(th);sind(th) cosd(th)]; fp=R*P(2,:)'; plot(fp(1),-fp(2),'o','Color',[.7 .7 .7]);
    end
    for j=1:3, plot(P(j,1),-P(j,2),mk{j},'MarkerFaceColor',mk{j}(1)); text(P(j,1)+.01,-P(j,2),names{j}); end
    plot(0,0,'k+'); text(.01,.01,'roll axis'); axis equal; grid on
    xlabel('interaural (m)'); ylabel('vertical (m)'); title('Finger trajectory, \pm25\circ roll (mean geometry)');
    subplot(1,2,2); hold on   % per-subject finger radius
    rfin=arrayfun(@(s) sqrt(s.r_fin2),G); bar(categorical({G.subj}),rfin);
    ylabel('finger radius r_{fin} (m)'); title('Finger distance from roll axis'); grid on; xtickangle(45)
    exportgraphics(f,outpng,'Resolution',180);
end

%% ============ helpers ============
function fprintf2(fid,varargin), fprintf(fid,varargin{:}); fprintf(1,varargin{:}); end
function v=pctl(x,p)
    x=sort(x(~isnan(x))); n=numel(x); if n==0,v=NaN;return; end; if n==1,v=x(1);return; end
    r=max(1,min(n,p/100*(n-1)+1)); lo=floor(r); hi=ceil(r); v=x(lo)+(r-lo)*(x(hi)-x(lo));
end
