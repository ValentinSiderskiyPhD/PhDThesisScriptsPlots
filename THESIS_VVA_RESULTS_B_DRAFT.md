# VVA Results B, cerebral blood flow, draft (Rung 1 first pass)

Companion to `THESIS_VVA_CHAPTER_SCAFFOLD.md` (Section 5) and to
`THESIS_VVA_RESULTS_A_DRAFT.md`. This draft covers **Rung 1 only**, the group
cycle-averaged CBF response, which is the accepted-physiology base of the CBF
ladder. The higher rungs (CVR separation, BP-to-CBFv dynamic autoregulation,
CO2 versus vestibular, perception-CBF alignment) are deferred until the primary
CBF endpoint is chosen.

Vocabulary follows the chapter conventions (no em-dashes, no "corroborating" or
"heterogeneous", prefer "VR scenes modified perception").

## Status and an important data-coverage caveat

The cycle averages come from the `slice` struct inside each `*averaged_v2.mat`. The
interactive averaging was replaced by a validated headless batch
(`oscillationAveraging_VVA_batch.m`, reproduces the original to <1% on the physiological
signals and the chair tilt), so the averages can be regenerated on the RED-correct data
without the GUI. The current figure is **RED-correct, n = 3 (VVA012, VVA013, VVA014)**, the
only subjects with RED-correct clean data today. This is the trustworthy Rung 1 base
(correct hydrostatic adjustment and sign convention), not the earlier n = 2 not_RED proof of
concept.

**Reading (RED-correct, n = 3).** The cerebral signals oscillate with the stimulus. Group
cycle peak-to-trough amplitudes (`VVA_cbf_cycle_average_group_amplitude_stats.csv`):
- **Chair tilt:** ~52 deg (+/-26 deg) at every frequency, consistent (the validated `Tilt`
  channel in degrees; matches Serrador's +/-25 deg protocol).
- **MCA velocity:** swing largest at **0.03 Hz** (~6 to 8 cm/s, ~9 to 12% of baseline),
  smaller at 0.1 and 0.18 Hz (~2 to 4%). The low-frequency dominance is consistent with
  Serrador's position-coupling at slow frequencies.
- **Cerebral MBP:** also largest at 0.03 Hz (~6 to 7 mmHg), ~2 to 3.5 mmHg at higher
  frequencies.
- **CVR:** ~0.6 level, swing ~0.02 to 0.07. **ETCO2:** ~38 to 42 mmHg but erratic (a visible
  rectangular detection glitch at 0.18 Hz DARK), the respiratory/CO2 detection problem.

To reach the full **n = 7** ceiling (VVA012 to VVA018), VVA015 to VVA018 still need RED
re-cleaning (see below); VVA019 has no TCD. The n = 3 figure stands as the correct base now.

**Trust caveat (binding):** the `not_RED` copy of the data has scrambled perception and
a suspect hydrostatic adjustment, so only the RED-correct (non `not_RED`) clean files
should feed CBF analysis. A data audit (`VVA_CBF_DATA_AUDIT_FINDINGS.md`) shows that
**RED-correct CBF clean data currently exists only for VVA012, VVA013 and VVA014.**
VVA015 to VVA018 have been processed only in `not_RED`, and VVA019 has no TCD at all.

So the realistic path to the CBF ladder is:
1. **Re-clean VVA015 to VVA018 with the RED convention** (`cleandata_R2020b_VVA.m`) so
   the hydrostatic adjustment and sign convention are correct. This is the binding
   upstream step; without it only n = 3 (VVA012 to VVA014) is usable.
2. Run `oscillationAveraging_VVA.m` for the RED-correct subjects x scenes x frequencies.
   That script is interactive (`clear` + `uigetfile`/`inputdlg`), so it was not driven
   headless here.
3. Re-run `VVA_cbf_cycle_average_group.m` on the RED-correct averages.

The CBF ceiling is **n = 7 (VVA012 to VVA018)**, with VVA019 excluded and an unbalanced
TRANS 0.18 Hz cell (VVA016 has no TCD there). Report the perception (n = 8) versus CBF
(n = 7) sample split explicitly.

## Tooling

New standalone script `VVA_cbf_cycle_average_group.m` (repo root). It auto-discovers
every per-subject `*averaged_v2.mat` under the SUBJECTS tree (excluding the pooled
`CollaplseSubjects` duplicates), parses subject/scene/frequency from the filename,
dedupes (preferring the `_v2` re-segmentation where two exist), stacks each subject's
ensemble-mean cycle, and plots the group mean +/- SD cycle. It writes
`VVA_cbf_cycle_average_group_figure.{fig,png}` and
`VVA_cbf_cycle_average_group_amplitude_stats.csv`. No existing tracked script was
edited.

## Rung 1, the cycle-averaged CBF response

Layout: five rows (stimulus tilt, MCA velocity, cerebral MBP, CVR, end-tidal CO2) by
three columns (0.03, 0.1, 0.18 Hz), with the three VR scenes overlaid (DARK dark grey,
TILT blue, TRANS orange), group mean as a solid line and +/- SD as a shaded band, x-axis
one normalised oscillation cycle (0 to 100%).

**Reading (n = 2 proof of concept).** The cerebrovascular signals oscillate with the
stimulus, which is all Rung 1 needs to establish. Group cycle peak-to-trough amplitudes
(real units, from `VVA_cbf_cycle_average_group_amplitude_stats.csv`):

- **MCA velocity:** about 1.2 to 3.9 cm/s of swing on a roughly 45 to 52 cm/s baseline
  (around 2 to 8% modulation), e.g. DARK 0.03 Hz = 3.71, TILT 0.1 Hz = 1.24,
  TRANS 0.18 Hz = 2.93 cm/s.
- **Cerebral MBP:** about 6.8 to 9.9 mmHg of swing across the cycle (largest at 0.1 Hz),
  the gravitational/hydrostatic component that Rung 2 will separate from the regulated
  response.
- **CVR (MBP/MBV):** about 0.03 to 0.09 of swing, tracking the BP and velocity together.
- **End-tidal CO2:** erratic and not orderly across frequency (DARK 0.03 Hz = 4.24 but
  DARK 0.1 Hz = 0.20), see the CO2 caveat below.

Two honest qualifications at n = 2:
1. **Cross-subject phase anchoring is not yet guaranteed.** The 0.1 Hz stimulus averages
   to a clean single sinusoid, but at 0.18 Hz (triangular) the TILT and TRANS stimulus
   means flatten toward zero, which means the two subjects' cycles are not phase-locked to
   each other. Before the n = 8 build the cycle-average needs a fixed phase anchor (for
   example, align each subject's cycle to the first upward zero-crossing of the stimulus)
   so the ensemble does not cancel.
2. The SD bands are wide because n = 2; they are shown for completeness, not inference.

### CO2 caveat carried into Rung 1 and Rung 4

The erratic ETCO2 amplitudes are not noise to average away, they reflect a real measurement
and physiology problem flagged for this study:

- **Respiratory-rate detection in cleandata is unreliable**, so measured ETCO2 (and any
  respiratory rate derived from it) is a weak input.
- **CO2 changes through two confounded paths during the oscillation:** motion can entrain
  and raise respiratory rate (which lowers ETCO2), and tilt can change CO2 directly. Both
  move at the stimulus frequency, so a CO2 change cannot be cleanly assigned to one path.
- **Both CO2 and the vestibular/tilt drive change cerebral blood flow,** so the two are
  partially collinear at the stimulus frequency. This is the core of the CO2-versus-
  vestibular question (Rung 4).
- **The CO2 to CBF effect is not instantaneous;** there is a transport lag / low-pass
  filtering between an ETCO2 change and the CBFv response. ETCO2 must therefore be modelled
  with a delay or low-pass term against CBFv, not aligned sample-for-sample.

## Rungs mapped to Serrador 2009, then pushed to 2026

Serrador 2009 is the accepted-physiology template (the lower rungs). The chapter must then
push the techniques to what is advanced and acceptable in 2026 and explicitly **model** the
effects, not just describe waveforms. The ladder:

- **Rung 1 = Serrador Figure 3** (built). Cycle-average rows Chair tilt / CFV / CVR /
  brain-level BP / ETCO2 x frequency. Add CFV as **% of baseline** (`MBV` slice field) to
  match his CFV_MCA(%) panel. Test his headline: **CFV opposes BP** and is not fully
  explained by BP or ETCO2.
- **Rung 2, CVR and the BP control.** Cycle-averaged CVR = brain-level BP / CFV. Serrador's
  argument: if CVR were purely autoregulatory, CFV would stay constant; because CFV keeps
  changing, a non-autoregulatory (vestibular) component is acting. Separate the hydrostatic
  BP swing from the regulated response.
- **Rung 3, position versus velocity (Serrador Figure 4).** Correlate cycle CFV with chair
  **position** and **velocity** at each frequency; expect position dominance at our low
  frequencies, velocity rising toward 0.18 Hz.
- **Rung 4, CO2 versus vestibular.** Serrador fit CFV to ETCO2 after a **known 6 s delay**
  (Poulin and Robbins 1996), reactivity ~2.6 %/mmHg. Use that lag (or a fitted lag /
  low-pass), not same-sample regression; treat ETCO2 as noisy; state the
  respiratory-entrainment vs direct-tilt CO2 confound.
- **Rung 5, perception-CBF alignment (the VVA twist).** Serrador's direction-dependent
  (pitch forward vs backward) asymmetry maps onto the perception 1H+/1H- asymmetry and the
  VVA017 TRANS finding. Relate perception (TILT raised gain, TRANS lowered it, clearest at
  0.18 Hz) to CBF on the same participants.

## Rung 6, the 2026 modelling layer (the contribution beyond Serrador)

Serrador 2009 used cycle-averaging, correlations, and a repeated-measures GLM. To be current
and to actually model the effects, add a dynamic, multi-input system-identification layer:

- **Frequency-domain dynamic cerebral autoregulation (transfer-function analysis).** Gain,
  phase and coherence of the BP -> CFV relationship, reported per the 2016 CARNet white
  paper conventions (Claassen et al.). Our three stimulus frequencies give clean
  single-frequency probes of the autoregulation high-pass.
- **Multi-input model partitioning the CFV response.** A parametric model (ARX / state-space
  / transfer function via system identification) with inputs BP (autoregulation), ETCO2
  (with the ~6 s lag / low-pass), and the vestibular/tilt drive (position and velocity),
  fitting CFV. The vestibular term is the residual not explained by BP and CO2, which
  quantifies the Serrador hypothesis directly instead of by visual disparity. Report each
  input's contribution and the model fit per scene and frequency.
- **Hierarchical / mixed-effects estimation** across the n = 7 subjects (random intercepts
  and slopes), so group inference respects the within-subject design and the unbalanced
  cells, rather than averaging per-subject point estimates.
- **Uncertainty and identifiability.** Report confidence intervals on the model parameters
  and check collinearity of the BP, CO2 and vestibular inputs at the stimulus frequency
  (they partly co-vary), so the partition is honest about what the data can and cannot
  separate.

This Rung 6 is the dynamic model that is the stated end goal: a modern, modelled account of
the BP / CO2 / vestibular drives on CBF, with the perception link as the integrative payoff.

## Open decision needed from you

Two choices set the next build:
1. **Primary CBF endpoint:** cycle-average (Rung 1), CVR (Rung 2), the position/velocity
   correlation (Rung 3), or the Rung 6 dynamic multi-input model as the headline.
2. **Modelling form for Rung 6:** transfer-function (CARNet) first, or go straight to the
   parametric multi-input system-identification model.
