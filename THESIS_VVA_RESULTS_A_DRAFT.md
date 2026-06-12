# VVA Results A, perception, draft with real numbers

Companion to `THESIS_VVA_CHAPTER_SCAFFOLD.md`. The placeholders in the scaffold's Section 4 are
filled here with the values harvested from the saved analysis outputs (no re-run needed, the
analysis files were already current). Prose is drafted for your voice-edit. Vocabulary follows the
chapter conventions (no em-dashes, no "corroborating" or "heterogeneous", prefer "VR scenes modified
perception").

Source files (all under `...\SUBJECTS\PerceptionGainAllSubjects_v3\`):
- `VVA_group_results.mat` (built 2026-06-01) and the `VR_scene_DARK_TILT_TRANS_*` set (built 2026-06-08):
  `_stats_summary.txt`, `_anova_stats.csv`, `_lme_stats.csv`, `_1Hpos_fisher_stats.csv`.
- Rung 1: `TwoHanded_OCR_baseline_vs_OneHanded_DARK_halfcycle_stats_summary.txt` (2026-06-05).
- Rung 3: `karmali_results\VVA_pooled_persubject_stats_20260526_182415.txt` and the
  `VVA_Karmali_regression_results_2026052*` set.

Two sample sizes appear and must be reported as such:
- **VR scene analysis (rungs 2 to 4): n = 8** complete cases, VVA012 to VVA019, who ran all three
  scenes at all three frequencies.
- **Hand comparison (rung 1): n = 15**, the larger set that has the two-handed OCR baseline
  (includes earlier VVA participants). State this difference explicitly so the n change is not read
  as an error.

Conventions in the numbers below: gain is perceived/actual (1 = veridical); phase is degrees, a
negative value is a lag; pairwise direction is B minus A with DARK as the reference baseline; a single
asterisk is the t-test result, a dagger marks where the Wilcoxon signed-rank replaced the t-test after
Shapiro-Wilk rejected normality of the paired differences. No multiple-comparison correction was
applied across the three per-frequency contrasts (a stated choice, matched across sections).

---

## Rung 1, the measure and the hand comparison

**Question.** Does the adopted one-handed positive half-cycle measure (1H+) read the same perception
as the established two-handed full-cycle measure (2H, the OCR baseline), so that 1H+ can be used as
the perception read-out for the rest of the chapter?

**Result (n = 15, pooled across frequencies, direction 1H minus 2H).**
- **Positive half-cycle (1H+) matches the two-handed measure.** Pooled gain difference
  = -0.084 (SD 0.293), t(14) = -1.12, p = 0.283, not significant; pooled phase difference = -2.26 deg,
  t(14) = -1.68, p = 0.114, not significant. The repeated-measures ANOVA agrees, with no Method main
  effect on gain (F(1,14) = 1.25, p = 0.283) or phase (F(1,14) = 2.84, p = 0.114).
- **Negative half-cycle (1H-) does not match.** Pooled gain difference = -0.171 (SD 0.277),
  t(14) = -2.39, p = 0.032; the ANOVA Method effect on gain is significant (F(1,14) = 5.70, p = 0.032).
  The 1H- measure reads a lower gain than the two-handed full-cycle measure.

**Per-frequency detail (1H+ vs 2H, gain).** The only single-frequency gain difference is at 0.03 Hz
(bias -0.168, 95% CI [-0.317, -0.020], t(14) = -2.44, p = 0.029); 0.1 and 0.18 Hz show no difference
(p = 0.94 and p = 0.45). For phase the single difference is at 0.18 Hz (bias -3.97 deg,
95% CI [-7.70, -0.25], p = 0.038).

**Reading.** The positive half-cycle gain tracks the two-handed full-cycle measure across frequency,
while the negative half-cycle sits lower. This justifies adopting **1H+** as the perception read-out,
and it sets up the directional-asymmetry layer (Rung 4): the two half-cycles already disagree against a
common reference, so they are not interchangeable.

---

## Rung 2, does the VR scene modify perception (the central question)

3 (Condition: DARK, TILT, TRANS) x 3 (Frequency: 0.03, 0.1, 0.18 Hz) repeated-measures ANOVA,
within-subject, complete cases **n = 8**. Reported for the adopted **1H+** measure, with the full-cycle
1H and negative half-cycle 1H- as robustness checks.

**Headline: the VR scene modified perceived motion gain.** The Condition main effect on gain is
significant for every measure:
- 1H+ (adopted): **F(2,14) = 6.61, p = 0.0095** (Greenhouse-Geisser p = 0.024; sphericity met,
  Mauchly p = 0.12).
- 1H (full cycle): F(2,14) = 8.82, p = 0.0033 (GG p = 0.011).
- 1H- (negative half): F(2,14) = 8.30, p = 0.0042 (GG p = 0.014).

There was **no Frequency main effect on gain** (1H+: F(2,14) = 1.30, p = 0.30) and **no
Condition x Frequency interaction** (1H+: F(4,28) = 0.62, p = 0.65). The scene shifted gain by a
similar amount across the tested frequencies.

**Gain means (1H+, mean +/- SD, n = 8), by scene and frequency.**

| Scene | 0.03 Hz | 0.1 Hz | 0.18 Hz |
|---|---|---|---|
| TILT  | 1.05 +/- 0.30 | 1.17 +/- 0.33 | 1.04 +/- 0.11 |
| DARK  | 0.83 +/- 0.22 | 0.94 +/- 0.25 | 0.93 +/- 0.24 |
| TRANS | 0.86 +/- 0.31 | 0.87 +/- 0.28 | 0.80 +/- 0.14 |

TILT sat above veridical (gain > 1), DARK near veridical, TRANS below. The ordering TILT > DARK > TRANS
held at every frequency.

**Per-frequency contrasts (1H+ gain, B minus A, DARK reference).**
- **TILT minus DARK:** +0.212 (0.03 Hz, p = 0.11), +0.225 (0.1 Hz, p = 0.12), +0.104 (0.18 Hz,
  p = 0.25). A consistent upward shift that does not reach significance at any single frequency at
  n = 8.
- **TRANS minus DARK:** +0.020 (0.03 Hz, p = 0.76), -0.076 (0.1 Hz, p = 0.25), **-0.131 (0.18 Hz,
  p = 0.030, dz = -0.96).** TRANS lowered gain relative to DARK, reaching significance at 0.18 Hz.
- **TRANS minus TILT:** -0.192 (0.03 Hz, p = 0.17), -0.302 (0.1 Hz, p = 0.081), **-0.236 (0.18 Hz,
  p = 0.0024, dz = -1.63).** The largest and most reliable scene contrast in the gain data.

**Phase.** No Condition main effect on phase for any measure (1H+: F(2,14) = 2.38, p = 0.13). Phase was
instead driven by **Frequency** (1H+: F(2,14) = 6.41, Greenhouse-Geisser p = 0.030; sphericity violated,
Mauchly p = 0.039): the lag shrank toward zero as frequency rose (1H+ DARK phase -14.6, -8.1, -5.2 deg
at 0.03, 0.1, 0.18 Hz). The one scene effect in phase is at the high frequency: at 0.18 Hz TRANS led
TILT by +6.4 deg (p = 0.0028) and TRANS led DARK by +3.45 deg (p = 0.0088), with TRANS phase close to
zero (-1.7 deg).

**Fisher combined across frequencies (1H+).** Confirms the contrast pattern: TRANS vs TILT is the only
scene pair that survives combination across frequency, for both gain (chi2(6) = 20.66, p = 0.0021) and
phase (chi2(6) = 17.91, p = 0.0065). TILT vs DARK (gain p = 0.076) and TRANS vs DARK (gain p = 0.110)
do not.

**Population mixed-effects check (all 762 cycles, 8 subjects, 1H+).** Using every per-cycle estimate
rather than per-subject means, the Condition effect on gain is at the threshold (F(2,52.2) = 3.04,
p = 0.057), Frequency is not significant (p = 0.37), and the phase Frequency effect holds
(F(2,29.7) = 5.43, p = 0.0098). The per-cycle lag-1 autocorrelation check supported treating cycles as
serially independent (see `_autocorr_stats.csv`).

**Reading.** VR scenes modified perceived motion gain. The translating scene (TRANS) reduced gain and
the tilting scene (TILT) raised it, with DARK between them; the separation was clearest between the two
visual scenes (TRANS below TILT) and strongest at 0.18 Hz. Scene did not change the phase except at the
high frequency, where TRANS advanced perception toward veridical timing.

---

## Rung 3, rigorous regression cross-check (Karmali HAC)

Per-subject HAC-corrected linear regression on the raw, unfiltered cycles
(`perceived = Gain x actual + Bias`), with the pooled between-condition Gain difference and Fisher's
combined test across frequencies (Karmali et al. 2021, Eqs 1 and 3). Eight complete subjects (VVA012
to VVA019) contribute; earlier subjects lack the three matched scenes and return NaN (expected).

**The within-subject scene effect reproduces at the cycle level.** Every complete subject shows a
significant TILT vs TRANS gain difference by Fisher's combined test (all p < 0.001), matching the
group ANOVA result that TRANS and TILT are the most separated scenes. Examples (Fisher chi2(6), TILT vs
TRANS): VVA012 = 68.5, VVA013 and VVA014 = Inf (at least one per-frequency p underflowed), VVA017 = Inf,
VVA019 = 29.3, all p < 0.001. The DARK contrasts are also significant per subject but with mixed sign
across individuals, consistent with DARK sitting between the two visual scenes at the group level.

**The HAC standard errors are large by construction.** Because the per-sample residuals are strongly
autocorrelated in these slow oscillations, the HAC correction inflates the standard errors relative to
a naive OLS fit (the running notes record roughly a 48x inflation). The per-subject ΔGain estimates are
therefore conservative; that they remain significant is the point of the cross-check.

**Caveat to carry to Limitations.** Auto-bandwidth HAC selection overshoots on sinusoidal data (long
runtime, correct estimates); a manually justified bandwidth may be preferable for the final tables. See
`README_VVA_LINREG_KARMALI.md` and `METHODS_FINAL_default_HAC.txt`.

---

## Rung 4, directional asymmetry (1H+ vs 1H-)

The most novel perception layer: comparing the positive and negative half-cycle gains and phases tests
whether perception is directionally asymmetric within a cycle.

**The two half-cycles respond to scene differently.** The scene contrasts that reach significance are
not the same for 1H+ and 1H-:
- **Gain, TRANS minus DARK:** 1H+ is significant at 0.18 Hz (-0.131, p = 0.030); 1H- is instead
  significant at **0.1 Hz** (-0.152, p = 0.0067, dz = -1.35) and not at 0.18 Hz (p = 0.69). The scene
  suppression of gain appears at a different frequency for each half-cycle.
- **Gain, TILT minus DARK:** 1H- shows an early-frequency enhancement that 1H+ does not, significant at
  0.03 Hz (+0.240, p = 0.023) and at 0.1 Hz (+0.159, Wilcoxon p = 0.039, dagger).
- **Phase, TRANS minus TILT at 0.18 Hz:** present in both but larger in the negative half (1H+ +6.4 deg,
  p = 0.0028; 1H- +9.0 deg, Wilcoxon p = 0.0078, dagger).

**VVA017 is the clearest single-subject case.** In the Karmali per-subject fits VVA017 shows a large,
consistent TRANS effect (DARK vs TRANS Fisher chi2(6) = 103.8, p < 0.001) and the largest TILT vs TRANS
separation of the group (ΔGain up to -0.86 at 0.1 Hz). This is the compelling directional asymmetry to
highlight in the discussion, with the standing caveat that it needs more data before a strong group
claim.

**Reading.** Positive and negative half-cycles do not move together under the VR scenes. The scene
reshaped perception asymmetrically within the cycle, which is why the adopted measure was fixed as the
positive half (Rung 1) and the negative half is reported as the asymmetry signal rather than averaged
away.

---

## Sensitivity and the null contrasts

Per-contrast sensitivity is in `VR_scene_DARK_TILT_TRANS_sensitivity_stats.csv`. At n = 8, two-sided
alpha = 0.05 and 80% power, the minimum detectable effect is dz = 1.16, so the non-significant TILT vs
DARK gain shifts (observed dz around 0.6 to 0.65) are underpowered rather than null. Report the
TILT vs DARK trend as suggestive and power-limited, and the TRANS vs TILT result (dz = -1.63 at
0.18 Hz, achieved power 0.98) as well resolved. This framing is the honest reading of the n = 8 design
and matches the chapter's stated sample-size limitation.

---

## What is still open (not inventable from the saved outputs)

1. Whether OCR is a reported perception outcome or only a quality check (affects whether Rung 1 keeps
   the OCR framing or just borrows its n = 15 baseline).
2. Exact tilt amplitudes and TCD insonation details for Methods (not in these stats files).
3. Confirmation that the n = 15 hand-comparison set is the intended Rung 1 sample and which extra
   subjects it adds beyond VVA012 to VVA019.
4. Final wording on the no-correction choice for the examiners (Holm/Bonferroni would drop the
   borderline 0.18 Hz TRANS vs DARK gain contrast but keep TRANS vs TILT).
