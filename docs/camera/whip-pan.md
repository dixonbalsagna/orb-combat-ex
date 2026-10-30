# The whip pan: signaturecity (2026-10-15)

Tools' signaturecity (seed 12345, the signature fired in the city) reads 4 / 5 / 4 normal and 4 / 4 / 4 reduced on HEAD, switches off. The camera is 9 of the 10 counted changes, ticks 738 to 748.

## What happens (reproduced: `render/camera/tests/clip_probe.gd --scenario=signaturecity --seed=12345 --from=725 --to=800`, which now writes what `flash_capture.gd` writes and prints both panes)

At tick 735 fighter 1 (the AI, the left pane, pane 1) starts a free flight toward P1 across 14,400 units: 7 units a tick at 735, 100 at 740, 144 at 746 (8,600 units a second), for about 100 ticks. The pane's focus takes his speed within ten ticks (the velocity lead, the lag bound), the picture's step going 0.0125, 0.024, 0.045, 0.055 to 0.084 of the width a tick (the metric of the other docs; a pane's pan plus half the zoom's log step). The scroll governor (SCROLL_MAX 0.045) is on its way out at the same time (zoom 0.66 to 0.41 over 25 ticks, at its rate cap of 1.2 e-folds a second; its target for that speed is 0.36). The re-frame limiter does not act: it arms after a velocity *step*, and this is a ramp. World's row-1 houses (about 400 units behind the plane) sweep the frame at 3.5 widths a second: 6 alternations in 10 ticks.

## What the camera can do, measured (scratch exports of HEAD d3cd19d5, Tools' capture path, 1,024 x 768; primary / area -15% / 2 s memory)

| Arm | Normal | Reduced | What it costs |
| :--- | :--- | :--- | :--- |
| Off (HEAD) | 4 / 5 / 4 | 4 / 4 / 4 | |
| A: every pane's focus capped at 0.025 of the width a tick (0.018 reduced) until he is 0.36 of the width from it; the governor aims at 0.03 and zooms out at 2.4 e-folds a second | 2.5 / 3 / 2.5 PASS | 2.5 / 2.5 / 2.5 PASS | he leaves his pane (a pane is 0.5 of the width; the cap lets him go to 0.36 from its centre): the sweep fails 21 rows (fighter out of its pane for 1.2 s; a slow drift binding the governor; the depth rows' size floors) |
| B: A plus the governor reading his speed 10 ticks ahead at his acceleration | 2.5 / 3 / 2.5 PASS | 2 / 2 / 2.5 PASS | the same |
| C: only for a whip (the picture would scroll 0.03 or more of the width a tick), room 0.18 (he stays in the pane) | 3.5 / 3.5 / 2.5 FAIL | 3.5 / 3.5 / 2.5 FAIL | sweep: 5 rows (3 real matches: out of pane; the slow-drift row) |
| C with a smaller floor for a whipped fighter (14 px at 720p, not 23) and the governor aiming at 0.022 to 0.025 | probe only: the picture's step stays 0.055 for 20 ticks | | |

## Why, and where the limit is

The picture moves by what the pane's camera moves plus half of what its zoom changes. To follow a body that goes from 7 to 144 units a tick in ten ticks, the pan must reach 144 x z / 1,280 of the width a tick; at the zoom that is on the screen when he starts (0.66) that is 0.074, and zooming out to take it down is itself 0.5 x the log step a tick (0.02 to 0.025 at 2.4 to 3 e-folds a second). So the sum is 0.05 to 0.06 for about twenty ticks whatever the order, and only when the zoom has reached its floor (0.31: 23 px) does it settle at 0.0345 (2 widths a second), still over the 1.5 asked. **The camera cannot hold the picture under the line and keep him in the pane**: arms A and B pass by letting him leave the pane for a second and a half, which is the cost the brief asked me to avoid.

## What I would do instead (not built)

1. **Rendering's whip-pan haze** (a look change, Orb turned off one on 2026-10-06): takes the contrast out of what sweeps, which is what counts.
2. **Encounter / Simulation: the AI's approach speed.** 8,600 units a second over 14,000 units, in a free flight toward a human who is standing, is the AI's choice. A flight at 4,000 units a second scrolls at 0.016 of the width a tick at the floor and is not a whip.
3. **A hold and a cut for a fast free flight** (the launch rule's behaviour: one counted change instead of ten): rejected for a fighter a human controls (his pane would freeze), possible for an AI's pane only when the human's own fighter is the other one. The cost is a second of the AI fighter off screen. Not built; say if you want it.

The experiment's patch was arm A/B/C (the switch `whip_cap`, `SplitView.set_whip_cap`, a `--whip-cap` sweep flag) on d3cd19d5. It is dead (2026-10-30): it never passed the sweep and it no longer applies. To measure it again, it is in git at 125296e5, docs/camera/pending/whip-cap-experiment.patch.
