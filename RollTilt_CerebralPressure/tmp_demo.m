S=load(['C:\Users\sider\Documents\Old Computer Files\C\Users\ValentinSiderskiy\Documents\' ...
        'Serrador_Lab\Projects\MURI\VVA Experiment\STUDY VVA Clone 2022_10_09\SUBJECTS\' ...
        'VVA_Participent_meta_data.mat']);
T=S.VVAParticipentmetadata; id=string(T.ID);
cbf={'VVA012','VVA013','VVA014','VVA015','VVA017','VVA018','VVA019'};
vr ={'VVA012','VVA013','VVA014','VVA015','VVA016','VVA017','VVA018','VVA019'};
att=setdiff(id, "VVA009");   % attended

num=@(x) double(x);
function pr(tag,T,id,grp,num) %#ok<*DEFNU>
  m=ismember(id, string(grp)); n=nnz(m);
  age=num(T.Age(m)); ht=num(T.Height(m)); wt=num(T.Weightlb(m));
  sx=string(T.Sex(m)); hd=string(T.Handedness(m));
  nF=sum(upper(sx)=="F"); nM=sum(upper(sx)=="M");
  nR=sum(upper(extractBefore(hd+" ",1))=="R"); nL=sum(upper(extractBefore(hd+" ",1))=="L");
  fprintf('%-10s n=%2d | Age %.0f+/-%.0f (%g-%g) | Ht %.0f+/-%.0f | Wt %.0f+/-%.0f lb | Sex %dF/%dM | Hand %dR/%dL\n',...
    tag,n, mean(age,'omitnan'),std(age,'omitnan'),min(age),max(age), ...
    mean(ht,'omitnan'),std(ht,'omitnan'), mean(wt,'omitnan'),std(wt,'omitnan'), nF,nM, nR,nL);
end
fprintf('--- demographics by cohort ---\n');
pr('Attended',T,id,att,num);
pr('VRscene n8',T,id,vr,num);
pr('CBF n7',T,id,cbf,num);

fprintf('\n--- CBF cohort per-subject geometry (cm) + MCA depth (mm) ---\n');
fprintf('%-8s  TCD2Piv  Fin2Heart  Fin2TCD  Fin2Midln  MCAdepth\n','ID');
m=ismember(id,string(cbf));
sub=id(m); g1=num(T.VestibularTCDToPivotcm(m)); g2=num(T.VestibularFinToHeartcm(m));
g3=num(T.VestibularFinToTCDcm(m)); g4=num(T.VestibularFinToMidlinecm(m)); md=num(T.MCADepth(m));
for i=1:numel(sub), fprintf('%-8s  %6.1f   %7.1f   %6.1f   %7.1f   %6.0f\n',sub(i),g1(i),g2(i),g3(i),g4(i),md(i)); end
fprintf('%-8s  %6.1f   %7.1f   %6.1f   %7.1f   %6.0f\n','MEAN',mean(g1,'omitnan'),mean(g2,'omitnan'),mean(g3,'omitnan'),mean(g4,'omitnan'),mean(md,'omitnan'));
fprintf('%-8s  %6.1f   %7.1f   %6.1f   %7.1f   %6.0f\n','SD',std(g1,'omitnan'),std(g2,'omitnan'),std(g3,'omitnan'),std(g4,'omitnan'),std(md,'omitnan'));
