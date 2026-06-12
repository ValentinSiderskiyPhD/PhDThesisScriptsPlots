# VVA study chapter, scaffold (DRAFT for review)

Working scaffold for the VVA chapter, assembled from the analysis scripts and our notes.
The Methods and Limitations prose is drafted and meant to be edited in your voice. Every result
value is a `[PLACEHOLDER]`, nothing is invented. Vocabulary follows your conventions (no em-dashes,
avoid "corroborating" and "heterogeneous", prefer phrasing such as "VR scenes modified perception").

Structure follows the escalating-rigor approach: accepted basics first, then progressively more novel
layers, with the cerebral-blood-flow (CBF) ladder built to mirror the perception ladder.

---

## 1. Proposed chapter outline

1. **Introduction**
   - Vestibular contribution to self-motion perception and to cerebral blood-flow regulation.
   - The gap: how a virtual visual scene reshapes both, across stimulus frequency.
   - Aims: (A) does the VR scene modify motion perception, and how does it depend on frequency and on
     half-cycle direction; (B) does the same paradigm reveal a vestibular signature in CBF regulation.
2. **Methods**
   - Participants and protocol (DARK, TILT, TRANS scenes; 0.03, 0.1, 0.18 Hz; within-subject).
   - Apparatus and signals (chair tilt, Finometer Pro BP, transcranial Doppler MCA velocity, CO2, ECG).
   - Signal processing pipeline (section 3 below).
   - Perception-gain extraction (sinusoidal fit; full-cycle and half-cycle).
   - Statistical approach (perception ladder, section 4) and CBF approach (section 5).
3. **Results A, perception (the ladder)** , section 4.
4. **Results B, cerebral blood flow (the ladder)** , section 5.
5. **Discussion** , integrate perception and CBF; the TRANS directional asymmetry; CO2 vs vestibular.
6. **Limitations** , section 6.

---

## 2. Design and terminology (reference)

- **Conditions / VR scenes:** DARK, TILT, TRANS. DARK is the reference baseline for contrasts.
- **Frequencies:** 0.03, 0.1, 0.18 Hz, within-subject.
- **Participants:** complete cases who ran all three scenes, expected VVA012 to VVA019, n = 8
  `[CONFIRM final n and any exclusions]`.
- **Perception measures (per cycle, by sinusoidal least-squares fit, lsfit):**
  - **1H** full-cycle gain and phase (perceived vs actual).
  - **1H+** positive half-cycle, **1H-** negative half-cycle (the asymmetry layer). 1H+ is the
    adopted half-cycle measure.
  - **2H** two-hand measure (used in the hand-comparison layer).
  - **OCR** ocular counter-roll `[confirm role/where reported]`.

---

## 3. Methods, signal processing pipeline (drafted, factual)

Raw LabChart recordings were processed with a custom MATLAB pipeline (R2020b). The stages are:

1. **Cleaning and channel assignment (`cleandata_R2020b_VVA.m`).** Channels (ECG, MCA velocity, BP,
   CO2, chair tilt) were identified, optional calibration of BP and CO2 was checked, and the analysis
   window was selected. The one-beat Finometer Pro display delay between BP and the ECG was removed by
   a manual ECG-to-BP alignment. A hydrostatic-gradient correction (`RollTilt_HydrostatAdj.m`) was then
   applied to express BP at heart and head level, using per-participant finger-to-heart, finger-to-TCD,
   TCD-to-pivot and finger-to-midline distances `[from Participent_meta_data]`. Middle cerebral artery
   velocity was aligned to BP, beats were detected from the ECG (R waves), and BP and velocity were
   fine-aligned to the beat marks at three windows (beginning, middle, end). Per-beat mean, systolic
   and diastolic values were extracted, physiocal and servo-correction beats were removed, and end-tidal
   CO2 was detected. The cleaned, time-matched signals were saved to a `*_clean.mat` file. Time vectors
   were kept on a consistent clock (`t_cleandata_original/clean/zeroed/matched`) so the chair tilt could
   be aligned to the per-beat data by time.
2. **Oscillation segmentation (`oscillationFinder_VVA.m`).** The sinusoidal (or triangular) chair-tilt
   cycles were detected and the recording was segmented into individual oscillation cycles.
3. **Ensemble averaging (`oscillationAveraging_VVA.m`).** Cycles were stacked, interpolated to a common
   length (`aligned_stack`), and averaged to a mean cycle with its standard deviation (`slice`), with a
   variant restricted to data after 30 s of motion (`slice_after_30`). Fields include `tilt_zeroed`,
   `CVR`, `MBV`, `MBVcm`, `Cerebral_MBP`, `ETCO2`. Output `averaged_v2.mat`.
4. **Perception-gain extraction (`VVA_perception_gain_extraction.m`).** For each cycle, the gain and
   phase of perceived relative to actual motion were estimated by sinusoidal least-squares fit (lsfit,
   known frequency, 95% CI), for the full cycle and for the positive and negative half-cycles. Outlier
   cycles were auto-flagged and could be rejected interactively. Output `*_gains.mat`, with provenance
   to the raw file.

`[Add: participant recruitment, ethics, exact tilt amplitudes, TCD depth/insonation, sampling rate
(1000 Hz), VR scene rendering details.]`

---

## 4. Results A, perception ladder (accepted to novel)

Two-tier code: `VVA_perception_group_stats.m` builds `VVA_group_results.mat` (slow, run once); the
companion scripts run the published statistics in seconds.

**Rung 1, the measure and the hand comparison (Section 1).**
Establish the perception read-out and the two-hand vs one-hand relationship.
Scripts: `VVA_visualization_onehand_dark_vs_twohand_ocr.m` (2H vs 1H full),
`VVA_visualization_halfcycle_vs_twohand_ocr.m` (2H vs 1H+ / 1H-). Outcome: justify adopting the 1H+
measure. Result: `[PLACEHOLDER]`.

**Rung 2, does the VR scene modify perception (Section 2).**
The central question. `VVA_vr_scene_group_stats.m`: 3 (Condition) x 3 (Frequency) repeated-measures
ANOVA on gain and on phase, run for 1H, 1H+ and 1H-. Mauchly sphericity with Greenhouse-Geisser /
Huynh-Feldt correction; per-frequency pairwise contrasts against DARK (TILT - DARK, TRANS - DARK,
TRANS - TILT) with Shapiro-Wilk normality and Wilcoxon signed-rank substituted when normality is
rejected; per-contrast sensitivity (observed dz, achieved power, minimum detectable dz). No
multiple-comparison correction across the three contrasts (a stated, conscious choice). Result:
"VVA scenes modified perception" `[PLACEHOLDER: F, p, GG-p, dz per condition x frequency]`.

**Rung 3, rigorous regression cross-check (Karmali).**
`VVA_scripts/VVA_linreg_Karmali_*`: HAC-corrected linear regression on the raw (unfiltered) cycles,
`perceived = Gain x actual + Bias` per subject/condition/frequency (individual, Eq 1), and direct
pooled DeltaGain between condition pairs with Fisher's combined test across frequencies (Eq 3).
Complements the ANOVA; HAC inflates standard errors (~48x) to respect autocorrelation. Result:
`[PLACEHOLDER: Gain +/- HAC SE per condition; DeltaGain pairs; Fisher p]`. See
`README_VVA_LINREG_KARMALI.md`.

**Rung 4, directional asymmetry (1H+ vs 1H-).**
The most novel perception layer: positive vs negative half-cycle gain/phase, that is, directionally
asymmetric perception. Highlight the compelling TRANS asymmetry seen in VVA017 (note: needs more data
before strong claims). Result: `[PLACEHOLDER]`.

Supporting: `VVA_perception_power_analysis.m` (power / sensitivity / Deming),
`VVA_correction_candidate_*` (Deming / measurement-error handling).

---

## 5. Results B, cerebral blood flow ladder (mirrors perception)

Goal: use the same oscillatory paradigm to expose a vestibular contribution to CBF regulation, built
shallow to deep so the accepted physiology is shown before the novel claim. End goal is a dynamic model
of the BP-to-CBFv relationship, templated on Serrador 2009.

**Rung 1, the cycle-averaged CBF response.** Ensemble mean cycle (`slice`, `slice_after_30`) of MCA
velocity (`MBV`, `MBVcm`), cerebral BP (`Cerebral_MBP`), CVR and ETCO2 versus tilt. Establish that the
signals oscillate with the stimulus. Result: `[PLACEHOLDER]`.

**Rung 2, cerebrovascular resistance and the BP control.** CVR across the cycle; separate the
gravitational/hydrostatic BP swing from the regulated response.

**Rung 3, BP-to-CBFv transfer (dynamic autoregulation).** Gain and phase of CBFv relative to BP at the
stimulus frequency, across conditions and frequencies. This is where the cleandata fine-alignment and
the hydrostatic correction matter most (see Limitations).

**Rung 4, CO2 versus vestibular contribution.** Separate the end-tidal CO2 drive from the vestibular
drive. Note the standing disagreement with Jorge on the CO2 vs vestibular weighting; address explicitly.

**Rung 5, perception-CBF alignment.** Relate the perception findings (section 4) to the CBF findings on
the same participants and conditions, the integrative payoff of the chapter.

Scripts/inputs: `oscillationAveraging_VVA.m` -> `averaged_v2.mat`; CBF firstpass notes (VVA012, 0.18 Hz
triangular, CBFv silent in DARK). `[Add the group-level CBF stats script once written.]`

---

## 6. Limitations and methodological considerations (drafted)

- **Hydrostatic correction and pulse transit time.** The BP-to-ECG synchronisation removes the Finometer
  Pro instrument delay together with the physiological pulse transit time (PTT, about 200 to 300 ms).
  Because the gravitational component of finger BP tracks chair tilt with negligible delay, advancing BP
  by the PTT leaves a residual oscillation in the hydrostatically corrected BP at the stimulus frequency,
  of magnitude 2A sin(pi f PTT) where A is the hydrostatic swing. As a fraction of A this is about 5% at
  0.03 Hz, 28% at 0.18 Hz, and 76% at 0.5 Hz (relevant to the higher-frequency centrifuge work). It is
  small for the slow VVA condition and larger at 0.18 Hz, and it biases the BP-to-CBFv phase at the
  stimulus frequency. A fixed one-second shift (instrument delay only, PTT preserved) would remove the
  residual if the Finometer Pro delay is confirmed at 1.000 s. Full derivation in
  `CLEANDATA_COMPARISON.md`. `[Quantify in mmHg and degrees for a representative participant.]`
- **Circular shift at alignment.** Alignment uses `circshift`, which wraps a slice of data from one
  temporal edge to the other; the first or last beat can therefore carry time-misplaced values. The
  effect is confined to the edge beats and bounded by the shift size.
- **Finger systolic pressure.** Finometer Pro systolic values are unreliable; mean and diastolic BP are
  used for analysis.
- **CO2 versus vestibular attribution.** Disentangling the CO2 drive from the vestibular drive is
  model-dependent; the chosen attribution is stated and contrasted with the alternative view.
- **Sample size.** n = 8 complete cases; per-contrast sensitivity is reported so null results are
  interpreted against the minimum detectable effect. No multiple-comparison correction across the three
  per-frequency contrasts (a stated choice, matched across sections).
- **HAC bandwidth.** Auto-bandwidth selection overshoots on the sinusoidal data (long runtime, correct
  estimates); a manual bandwidth with justification may be preferable.

---

## 7. Analysis inventory (script -> output -> chapter section)

| Script | Produces | Feeds section | Status |
|---|---|---|---|
| `cleandata_R2020b_VVA.m` | `*_clean.mat` (cleaned, aligned signals) | Methods 3 | active, being refined |
| `oscillationFinder_VVA.m` | `*_oscillations*.mat` (cycle segments) | Methods 3 | active |
| `oscillationAveraging_VVA.m` | `averaged_v2.mat` (ensemble cycle) | Results B (CBF) | active |
| `VVA_perception_gain_extraction.m` | `*_gains.mat` (per-cycle gain/phase) | Methods 3 / Results A | active |
| `VVA_perception_group_stats.m` | `VVA_group_results.mat` (group matrices) | Results A builder | active (slow) |
| `VVA_visualization_onehand_dark_vs_twohand_ocr.m` | 2H vs 1H full | Results A, rung 1 | done `[confirm]` |
| `VVA_visualization_halfcycle_vs_twohand_ocr.m` | 2H vs 1H+/1H- | Results A, rung 1 | done `[confirm]` |
| `VVA_vr_scene_group_stats.m` | scene CSVs + figure (DARK/TILT/TRANS) | Results A, rung 2 | done `[confirm]` |
| `VVA_scripts/VVA_linreg_Karmali_*` | HAC regression + pooled DeltaGain | Results A, rung 3 | done, runtime issue |
| `VVA_perception_power_analysis.m` | power / sensitivity / Deming | Results A support | done `[confirm]` |
| `VVA_correction_candidate_*` | Deming / measurement-error | Results A support | `[status]` |
| CBF group stats `[to write]` | group BP/CBFv/CVR/CO2 stats | Results B | not yet |

---

## 8. Open items / what I need from you to fill placeholders

1. Final n and any participant exclusions (VVA016 "poor TCD"? VVA019 eye issues?).
2. The actual perception results (or point me at the CSVs / `*_stats_summary.txt`) so I can draft
   Results A prose around real numbers.
3. Tilt amplitudes and TCD insonation details for Methods.
4. Whether OCR is a reported outcome or only a quality check.
5. The CBF group-level analysis plan (which is the primary CBF endpoint: cycle-average, CVR, or the
   dynamic BP-to-CBFv model) so Results B can be firmed up.
6. Confirm the escalating-rigor rung order matches how you want to present it.

---

*Scaffold prepared by Claude while you were out. Nothing here is a final claim; replace every
`[PLACEHOLDER]` with your data, and edit the prose into your voice. Companion reference for the
processing details and the open methodological issues: `CLEANDATA_COMPARISON.md`.*
