# Roll-Tilt Cerebral Pressure: Results and How to Reproduce

Summary of the roll-tilt cerebral-pressure work for the VVA thesis chapter. It answers one
question in two parts:

1. **Which pressure terms matter?** Port the Siderskiy / Clark / Serrador 2009-data modelling
   paper's pitch-tilt cerebral-pressure correction to roll tilt, using real per-subject geometry,
   and test each term against the Finapres measurement precision.
2. **Is the static hydrostatic correction enough, or is something unaccounted for?** Use the real
   VVA data as a playground to look for damping, residual delays, mis-aligned signals, geometry
   measurement error, and a low-pass effect at higher frequency.

The short answer: the **static hydrostatic correction is sufficient across the VVA band (<=0.18 Hz)**.
No other term reaches the Finapres precision, the gradient transmits to the finger cuff at near
unity with no frequency roll-off, and the cleandata alignment is sound for all but two trials.

---

## Environment

- MATLAB **R2020b**.
- Each script does `addpath` to the Serrador_Lab GitHub repo so it can call `RollTilt_HydrostatAdj.m`.
- Geometry is read from `...\SUBJECTS\VVA_Participent_meta_data.mat`; real tilt and BP from the DARK
  `*_clean.mat` files under `SUBJECTS_BATCH_CORRECTED` (the corrected batch pipeline).
- CBF cohort: VVA012, 013, 014, 015, 017, 018, 019 (VVA016 excluded). The closed-form analysis also
  uses VVA005 because geometry is available, giving n = 9 there.
- Run headless, e.g.:
  `"C:\Program Files\MATLAB\R2020b\bin\matlab.exe" -batch "RollTilt_CerebralPressureCorrection"`
- Every script writes its figures to this folder and prints its table to the console.

---

## 1. Closed-form pressure terms vs Finapres precision

**Script:** `RollTilt_CerebralPressureCorrection.m`
**Outputs:** `Fig_RollTilt_hydrostatic.png`, `Fig_RollTilt_centripetal.png`, `Fig_RollTilt_euler.png`,
`Fig_RollTilt_geometry.png`, `RollTilt_pressure_terms.csv`, `RollTilt_pressure_terms_summary.txt`
**Derivation:** `RollTilt_CerebralPressure_derivation.md` (numbered equations 1-6).

Each pressure term relating finger-cuff pressure to head- and heart-level cerebral pressure during
sinusoidal roll, simulated per subject (n = 9 with geometry, +-25 deg), finger->head peak-to-peak:

| Term | Scaling | 0.03 Hz | 0.10 Hz | 0.18 Hz | 0.50 Hz* |
|---|---|---|---|---|---|
| Hydrostatic | static, flat in f | **10.3 +/- 1.9 mmHg** (range 8.0-13.5) | same | same | same |
| Centripetal | 2f, omega^2 r | 0.003 | 0.039 | 0.126 | 0.970 |
| Euler (tangential) | f, alpha r | ~0.000 | 0.002 | 0.005 | 0.039 |
| Bernoulli | hemodynamic, not tilt-kinematic | ~0.77 | ~0.78 | 0.87 +/- 0.44 (max 1.60) | n/a |

\* 0.50 Hz is a speculative column outside the VVA band, shown only to display the f^2 growth.

**Inclusion bar:** the Finapres cannot resolve pressure changes below ~2 mmHg peak-to-peak.

**Result:** only the **hydrostatic** term (~10.3 mmHg) exceeds precision and must be corrected; it is.
Centripetal, Euler and Bernoulli are all below 2 mmHg across the whole VVA band, so no
frequency-dependent correction is applied. The roll geometry keeps the finger near the rotation
axis, so even at a speculative 0.5 Hz the dynamic terms stay near or below precision. This differs
from the variable-radius centrifuge, where the long arm lifts the centripetal term to ~15 mmHg.

---

## 2. Playground: damping, delay, geometry error

**Script:** `RollTilt_HydrostaticPlayground.m`
**Output:** `Fig_RollTilt_playground.png`

Compares the measured tilt-locked finger BP (`BP_ecg_aligned`, de-delayed, before hydrostatic
correction) against the predicted hydrostatic dP (`-deltaPfin2heart` from `RollTilt_HydrostatAdj`),
both fit at the tilt frequency by least squares. n = 7.

- **Damping (amplitude ratio measured/predicted):** 1.03 / 0.79 / 0.93 at 0.03 / 0.10 / 0.18 Hz.
  Not monotonic, so not damping. The 0.10 Hz dip sits in the Mayer-wave band and is fit
  contamination, not attenuation. The gradient is essentially fully transmitted.
- **Geometry sensitivity (% change in predicted amplitude per 0.5 cm error):** only the
  finger-to-midline lateral distance matters (3.3%); the vertical distances are ~0%. A half-cm
  measurement error is negligible (~0.3 mmHg on a 10 mmHg swing).
- **Delay:** the single-frequency phase and a raw lag-sweep disagreed, flagged as unreliable here and
  pursued properly in sections 4 and 5.

**Caveat:** a single-frequency sinusoidal fit captures only the fundamental Fourier component; it
underreports the triangular 0.18 Hz peak and leaks Mayer-wave power at 0.10 Hz. This motivated
sections 3-5.

---

## 3. Transmission: waveform regression + harmonic transfer

**Script:** `RollTilt_HydrostaticTransmission.m`
**Output:** `Fig_RollTilt_transmission.png`

Two non-sinusoidal tests aimed at the high-frequency end. n = 7.

- **Waveform-regression gain:** regress measured BP on the model waveform (which already carries the
  real triangular shape). Gain (slope) 0.93 / 0.75 / 0.79 at 0.03 / 0.10 / 0.18 Hz. Flat near unity,
  no roll-off. R^2 is low (0.03-0.05) only because `BP_ecg_aligned` is the full pulsatile waveform and
  the ~1 Hz heartbeat dominates total variance; the slope is still valid because the tilt-frequency
  fit is orthogonal to the pulse.
- **Harmonic transfer:** a triangular tilt at f carries energy at f, 3f, 5f... so the harmonics
  probe higher frequencies from the same trial. Toolbox-free Welch coherence flags which bins to
  trust. **Only the three fundamentals pass** (coherence 0.88 / 0.74 / 0.90); every harmonic above
  collapses below 0.5 and the gain blows up, because the predicted hydrostatic content at 0.5-1 Hz is
  tiny (triangle harmonics fall as 1/k^2) while the measured BP there is spontaneous noise and the
  cardiac pulse. So transmission above 0.18 Hz cannot be measured from these data.

**Result:** within the resolvable band (<=0.18 Hz) the gradient transmits at ~unity with no roll-off.
Above it the dynamic content is too small to even measure, which is itself the evidence that there is
nothing to correct.

---

## 4. Alignment optimisation and delay-vs-low-pass

**Script:** `RollTilt_HydrostaticAlignOptim.m`
**Output:** `Fig_RollTilt_alignoptim.png`

Does not trust the existing alignment. The cardiac pulse is removed from BOTH BP and model by an
identical 1 s centred moving average (it cancels in the gain ratio but removes the pulse that wrecked
R^2). The BP-to-model delay is then a free parameter. n = 7.

- **Alignment:** optimising a free residual delay recovers almost nothing. The single delay that best
  fits all frequencies at once is **0.05 s** (essentially zero); R^2 and gain barely move
  (0.45->0.47, 0.36->0.38, 0.27->0.31). The cleandata ECG-align is not hiding a delay at the group
  level.
- **Delay vs low-pass:** a first-order low-pass fits the gain only marginally better than a flat line
  (apparent corner ~0.36 Hz), and the gain is **non-monotonic** (0.93 -> 0.74 -> 0.81), which a real
  low-pass cannot produce. So the data do not support an in-band low-pass; if one exists its corner is
  >=0.36 Hz, above the stimulus band.
- **Real limit:** even de-pulsed and delay-optimised, the model explains only ~30-47% of the slow BP
  variance. The rest is spontaneous BP physiology (Mayer waves, autoregulation, breathing) that is not
  tilt-locked. That noise floor, not damping or mis-alignment, sets the ceiling on certainty.

---

## 5. Per-subject optimal delay (the alignment check)

**Script:** `RollTilt_HydrostaticDelayPerSubject.m`
**Output:** `Fig_RollTilt_delay_persubject.png`

Per-subject, per-frequency delay with no collapsing to a mean. Two estimators, both signed so
positive = BP lags the tilt-derived model: phase-derived (valid at low f) and the R^2-lag sweep
(+-8 s, reporting the top two LOCAL optima so an aliased global peak cannot hide the real one). The
table also prints the delay actually dialled in during cleandata (`manual_shift_s`) and the saved
residual PTT (`ptt_resid_samp`). The file lookup tolerates folder-name variants (VVA015 `_v2`) and
falls back to the WORKING tree for VVA019, which is flagged because it did not go through the
corrected batch pipeline.

- **Your applied alignment is consistent:** `manual_shift_s` = 1.17-1.25 s and `ptt_resid_samp` =
  0.18-0.25 s for every subject and trial (~1.0 s instrument delay + ~0.2 s PTT).
- **Phase-derived residual at 0.18 Hz matches it:** VVA012/013/015/017 are -0.16 to -0.30 s
  (~200-300 ms), agreeing with the saved PTT and with each other.
- **Aliasing confirmed:** at 0.18 Hz the R^2-vs-lag curve peaks every ~2.78 s (half the tilt period)
  at near-equal R^2, so the global argmax was landing on aliases. Phase is the anchor at high f.
- **0.03 Hz is unreliable for everyone** (one broad hump, peak wanders 0.1-2.0 s): the low-frequency
  precision floor, not a real per-subject delay. Do not read delay from the 0.03 Hz trials.
- **Two genuine outliers:** VVA014 (~0 s) and VVA018 (-0.78 s) at 0.18 Hz are not aliases and remain
  the two trials to re-check at the ECG-align step.
- **VVA019** loads only from the WORKING tree (no corrected-batch version, lacks `ptt_resid_samp`);
  keep it separate when drawing conclusions.

---

## Bottom line

- Only the static hydrostatic term needs correcting in the VVA band, and it is corrected.
- The gradient transmits to the finger cuff at ~unity with no measurable frequency roll-off; any
  low-pass corner sits above the stimulus band.
- The cleandata alignment is sound (group residual ~0; consistent ~200-300 ms PTT), with VVA014 and
  VVA018 the only trials worth re-checking.
- The limit on precision is spontaneous BP variability, not an unmodelled physical effect.

## Run order

```
RollTilt_CerebralPressureCorrection   % section 1: pressure terms + derivation figures/CSV
RollTilt_HydrostaticPlayground        % section 2: damping / geometry / first-pass delay
RollTilt_HydrostaticTransmission      % section 3: waveform-regression + harmonic transfer
RollTilt_HydrostaticAlignOptim        % section 4: free-delay alignment + delay-vs-low-pass
RollTilt_HydrostaticDelayPerSubject   % section 5: per-subject delay table + two optima
```

Each is independent and can be run on its own.
