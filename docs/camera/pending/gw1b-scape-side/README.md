# Parked: the landscape shot keeps the side it leans to (gw1b-scape-side)

Camera, 2026-11-15, the EP's GW1b list: launch_shots' AI fight 2 jump. **Real, and fixed.** The look gate's side-by-side waits for a capture window.

**Apply after gw1a-pins** (cut on main b1d9444e + own-pane + gw1a-pins; `split_rig.gd` is s422's): `git -c core.autocrlf=false apply gw1b-scape-side.patch` (sha1 089fe5f4). Two files, mine.

| File | What |
| :--- | :--- |
| `render/camera/split_rig.gd` | `_scape_side`: the landscape shot's lean picks its side as the shot starts and keeps it to the end, as the swing's lean keeps `_sw_sign` |
| `render/camera/tests/launch_shots_check.gd` | fight 2's ceiling (0.263) is gone; fight 3's stays (0.111, below) |

## What it was (`docs/camera/runs/b1d9444e/gw1b-scape-side/runs.txt`)

AI fight 2 with the 9 November data, tick 3219. During the landscape shot on a landmark (the establishing frame that leans the one view toward a landmark and eases back), the view jumped 0.26 and then 0.19 of the width in two ticks, then eased back over about ten. Both fighters were free and at depth 0, so this was real camera motion, not a reading. The lean's direction was `signf(pair middle to the landmark)`. When the pair's middle walked past the landmark's x, the lean flipped sides in a tick. Now the side is set once, as the shot starts.

- Fight 2's largest jolt: **0.263 → 0.056** (limits 0.16, and 0.10 with the energy model).
- Every camera gate on the stack passes with it: chase_rush 130, flight_shots 539, launch_shots 843, cross_ko 21, peak_retry 1, peak_shot 24, split_share 26, split_vision 11, swing_places 33, swing_real 48, swing_shot 164, swing_read 14,420, own_pane 12. split_sweep's four are gw1a-pins-2's, the same with the rig before this.
- clip_digest in the default view, before against after: **only ai:106 changes** (139 of 3,600 ticks, between 151 and 1071). The other eight clips are identical.

## Still a ceiling: fight 3's 0.110 (limit 0.10 with the energy model)

Tick 2532: in a grapple lock the sim moves the rival 300 units down in one tick as the split opens, and the shared view's height follows on the opening's first tick (0.108 of the width). A different cause, and marginal; fix owed.

## Owed before landing

The look gate: ai:106 in the default view, before and after, ticks about 140 to 1080, and both flash modes, in a capture window.
