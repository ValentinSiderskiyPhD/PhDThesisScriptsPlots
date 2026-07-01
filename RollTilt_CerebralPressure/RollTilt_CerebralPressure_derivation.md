# Roll-Tilt Cerebral Pressure Correction

Roll-tilt analog of the "Pitch-Tilt Cerebral Pressure Correction" of the Siderskiy / Clark / Serrador
2009-data modelling paper, written in the same form and figure style for the VVA roll-tilt study. It estimates,
from the **real per-participant geometry** and the study tilt amplitude, the pressure terms relating the
finger-cuff pressure to head- and heart-level cerebral pressure during sinusoidal roll, and tests each against
the Finapres measurement precision to decide whether it must be corrected.

Geometry was available (complete vestibular-geometry row in the metadata) for **n = 9 participants** (VVA005,
VVA012–VVA019). Run `RollTilt_CerebralPressureCorrection.m` (MATLAB R2020b); figures and tables are written to
this folder.

---

## Cerebral Pressure: Hydrostatic contribution

Roll tilt is rotation about the naso-occipital (x) axis through the chair pivot O by angle θ(t), right-ear-down
positive. Working in the interaural–vertical (ξ, η) plane with η downward and the head as reference, the
finger, heart and head positions follow from the measured distances (d1 = TCD-to-pivot, d2 = finger-to-TCD,
d3 = finger-to-heart, ax = finger-to-midline):

```
p_head  = (0, d1)          (1)
p_fin   = (ax, d1 + d2)     (2)
p_heart = (0, d1 + d2 − d3) (3)
```

The gravitational (hydrostatic) pressure difference is `ΔP = ρ g Δη_lab`, where Δη_lab is the lab-frame vertical
separation, which changes as the body rolls. We evaluate it with `RollTilt_HydrostatAdj` (the validated
implementation used in cleandata), giving finger→head and finger→heart corrections. This term is independent of
frequency (it depends only on tilt angle and geometry); the finger trajectory and the per-participant geometry
are shown in **Figure (geometry)**.

We simulated ±25° roll for each participant. The finger→head hydrostatic swing was **10.3 ± 1.9 mmHg**
peak-to-peak (range 8.0–13.5), far above the Finapres precision, and is the correction applied in cleandata.

## Centripetal Contribution

The centrifugal field is `a_cf(p) = ω² p`. Integrating along the straight finger→b segment, with
`∫ p·dl = (r_b² − r_fin²)/2`, gives

```
ΔP_centr(finger→b) = ρ ω² (r_b² − r_fin²) / 2          (4)
```

where `r_fin = sqrt(ax² + (d1+d2)²)` and `r_head = d1`. For θ(t) = θ₀ sin(2πf t), ω² swings from 0 to
θ₀²(2πf)², so ΔP_centr oscillates at **2f** with peak-to-peak `ρ θ₀²(2πf)² |r_b² − r_fin²| / 2`.

We simulated ΔP_centr per participant (**Figure (centripetal)**). The largest finger→head peak-to-peak across
participants was **0.13 ± 0.03 mmHg at 0.18 Hz** (max 0.17), rising to only 0.97 ± 0.21 mmHg even at a
speculative 0.5 Hz (Table 1) — well below precision throughout, because the roll geometry keeps the finger close
to the rotation axis.

**Table 1.** Centripetal ΔP_head peak-to-peak (mmHg).

| f (Hz) | mean ± SD | max |
|---|---|---|
| 0.03 | 0.003 ± 0.001 | 0.005 |
| 0.10 | 0.039 ± 0.008 | 0.054 |
| 0.18 | 0.126 ± 0.027 | 0.170 |
| 0.50* | 0.970 ± 0.207 | 1.31 |

## Euler (Tangential) Contribution

The Euler field is `a_E(p) = −α x̂ × p`. With `∫ p×dl = p_fin × p_b`,

```
ΔP_euler(finger→b) = −ρ α (p_fin × p_b)_x ,   (p_fin × p_b)_x = ax·η_b      (5)
```

(head/heart on the midline, ξ_b = 0). Since α swings ±θ₀(2πf)², ΔP_euler oscillates at **f** with peak-to-peak
`ρ · 2θ₀(2πf)² |ax·η_b|`. We simulated ΔP_x per participant (**Figure (euler)**, which also shows the tangential
acceleration). The largest finger→head peak-to-peak was **0.005 ± 0.015 mmHg at 0.18 Hz** (max 0.046), and only
0.039 mmHg at 0.5 Hz (Table 2) — negligible, because the head sits near the pivot (small η_head = d1).

**Table 2.** Euler ΔP_head peak-to-peak (mmHg).

| f (Hz) | mean ± SD | max |
|---|---|---|
| 0.03 | 0.000 | 0.001 |
| 0.10 | 0.002 | 0.015 |
| 0.18 | 0.005 ± 0.015 | 0.046 |
| 0.50* | 0.039 ± 0.118 | 0.36 |

## Pressure Gradient (Bernoulli)

Applying Bernoulli along the carotid→MCA streamline adds a dynamic-pressure term

```
ΔP_bernoulli = ½ ρ (v_carotid² − v_MCA²)               (6)
```

with `v_carotid ≈ 0.6 m/s` and `v_MCA` the measured cerebral velocity. This is hemodynamic (velocity-driven),
not tilt-kinematic, so it does not scale with f². Computed from each participant's real per-beat mean MCA
velocity, the peak-to-peak modulation was **0.87 ± 0.44 mmHg at 0.18 Hz** (max 1.60). This is a conservative
bound (it includes all slow velocity modulation, not only the tilt-driven part) and is still below precision.

## Assessment for Inclusion (Finapres precision)

Following the modelling paper, the Finapres cannot resolve pressure changes below ~2 mmHg peak-to-peak (the
beat-to-beat direction is unreliable within ±2 mmHg, and the averaged-MAP precision is ~2 mmHg over ≥30 s
windows). A term whose peak-to-peak amplitude is below 2 mmHg therefore cannot be detected in these data and
need not be corrected.

**Conclusion.** In the VVA roll-tilt band (≤0.18 Hz, ±25°), only the **hydrostatic** term (~10.3 mmHg) exceeds
the Finapres precision and must be corrected; it is. The **centripetal** (≤0.13 mmHg at 0.18 Hz), **Euler**
(≤0.005 mmHg) and **Bernoulli** (≤0.9 mmHg) terms are all below the 2 mmHg precision, so the **static hydrostatic
correction is sufficient** and no frequency-dependent correction is applied. Unlike the variable-radius
centrifuge — where the long arm lifts the centripetal term to ~15 mmHg — the roll-tilt geometry keeps the finger
near the rotation axis, so even at a speculative 0.5 Hz the dynamic terms stay near or below precision.

\* 0.5 Hz is a speculative column outside the VVA stimulus band, included to show the f² growth.
