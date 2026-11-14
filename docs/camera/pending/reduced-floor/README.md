# Parked: under Reduce flashing, a fast pane may go below the readable size (reduced-floor)

Camera, 2026-11-14, the EP's go on option (i): the safety mode, where readability may give a little. Normal play never reads it.

**Apply after** reduced-pace (it uses `_rpace`), on the GW1a look stack: `git -c core.autocrlf=false apply reduced-floor.patch` (sha1 838fe0d7). It lands after GW1a.

| File | What |
| :--- | :--- |
| `render/camera/split_rig.gd` (mine) | the governor's floor for a fast pane (a free one, and a launched one under launch-wide) takes `reducedPace.floorR` when it's lower |
| `data/camera/swing.json` (mine, granted) | `reducedPace.floorR`: 0.032 (R_FLOOR: 23 px at 720p, against the readable 43) |
| `tools/schemas/camera-swing.schema.json` (Tools' grant) | the key, 0.032 to 0.06 |

## What it does

Under Reduce flashing, when a fighter flies so fast that his pane's scenery would stream past faster than the reduced limit (0.03 of the width a tick), the scroll governor may ease the pane out until he's 23 px tall, not 43. The ease is the governor's own (`GOV_TAU`). It never goes below R_FLOOR, the camera's hard floor, and nobody is lost: the escape and chase rows pass.

## Proof (`docs/camera/runs/611c1c2b/reduced-floor/`)

| Run | Result |
| :--- | :--- |
| Every camera check on the full stack with this park | **all pass**: split_sweep with its escape rows, chase_rush 130, flight_shots 803, launch_shots 1,029, cut_register 73 |
| Signature, reduced, the right pane (a fighter launched by the signature and chased; `native.txt`) | the pane eases out from 0.66 to 0.31 by tick 120. Once there, its scroll is about 0.03 to 0.027 of the width a tick, against 0.04 to 0.03 with reduced-pace alone. But the 40-tick pull-out and its first fast ticks are motion too, so whether it's a net gain for the analyser **needs the pixel reading** |
| Collapse, clash, reduced | unchanged: their fast panes aren't at the readable floor (the launch rule holds clash's; collapse's last second is a pull-out to fit) |

## Owed

The pixel reading, in the window after Rendering's tone change: signature, collapse and clash, both modes, on the full stack. If signature's reading doesn't improve, the park stays out.
