# Parked, paused: the other fight in the frame (others-frame)

Camera, 2026-11-07, for the EP's 2v2 brief, job 2 (RL-249's drawn case): when the other pair is near, frame all four in a wider shot, or put the other pair at the frame's edge. Eased, no cuts. Behind `draw_others`.

**Paused at Orb's word before the look gate.** It isn't ready to land: the side-by-side and the flash run on the clip are still owed.

**Apply on main** (cut on e20ea172; `git apply --check --cached` passes on c5b42dc1): `git -c core.autocrlf=false apply others-frame.patch` (sha1 7858afea).
- Files: `render/camera/split_rig.gd`, `render/camera/camera_params.gd` and a new `render/camera/tests/others_frame_check.gd`, all mine.
- **One line in `render/core/main.gd`, not mine (needs a grant):** `split_rig.frame_others = SimHost.draw_others`, under the line that sets `draw_others`.
- The two-fighter ratchet is unchanged (365). vkeep still applies beside it.

## What it does

`SplitRig.frame_others` is off. main.gd turns it on with `draw_others` (`?others=1`, `--others`). With it on, in the single view of a 2v2:
- **Near: all four.** Each standing body of the other fights counts by a weight that moves 0.025 a tick (`MANY_RATE`), so a join or a leave takes 40 ticks and steps nothing. This is one-versus-many's rule (docs/camera/one-v-many.md section 3), with its own allowance for another team's fight:
  - the weight is 1 while the zoom that fits him stays above `OTHERS_ZKEEP` (0.55) of the pair's own, and nobody is smaller than `OTHERS_R_MIN` (0.06 of the height, 43 px at 720p);
  - one-versus-many's guards keep 0.75.
- **Too far to join, near enough to show: the edge.** The nearest other body not in the set leans the focus toward him until he stands 0.44 of the width from the centre (`OTHERS_EDGE`), while the pair stays inside 0.42 (`OTHERS_KEEP`). The lean moves at most 0.005 of the width a tick, and the camera eases on top. It fades where the room left can't bring him in.
- **Counts for nothing:** a body that's out, one more than 8 body heights over the pair, or one deeper than 600 units.
- **The fight held changes** (a LAN PC whose player is out shows his partner's fight): the weights start again.
- **The split's own rules are unchanged:** they still read the pair only.

## Proof (on the code before the last edit; see RISKS)

| Run | Result |
| :--- | :--- |
| `others_frame_check` (new), the other pair brought from 6,000 to 1,000 units, held, taken away | 10 of 10. All four in the picture on 130 of 130 held ticks; weight 0 far off; no cuts; jolt 0.0175 (before the approach, the pair's own); zoom jolt 0.0085; the pair never off the view |
| `others_frame_check` on main's rig (negative control) | 3 fail: none of the others in the picture, weight never set |
| With the other pair far: frames against the switch off | 0 of 300 differ |
| `clip_digest`, 1v1 | byte-identical |
| `split_sweep`, `cross_ko_check` 21, `launch_shots_check` 635, `peak_shot_check` 24, `split_vision_check` 11, `split_share_check` 26, `swing_shot_check` 164, `swing_places_check` 33, `swing_real_check` 48 | all pass |
| `chase_rush_check` | the same 3 as main until vkeep lands |

**Distance scan** (pair 900 apart, the other pair held at a distance from their middle):

| Held at | All four in the picture | The nearer other, with the pair | Main |
| :--- | :--- | :--- | :--- |
| 600 | all ticks | all ticks | the nearer other only |
| 800 | all ticks | all ticks | none |
| 1,000 | all ticks | all ticks | none |
| 1,300 | none (weight about 0.58, the ease band) | none | none |
| 1,700 and more | none (let go) | none | none |

## RISKS and what's owed

- **The last edit isn't re-proved.** `_others_set` now takes the pair from `S.fighters.slice(0, 2)` instead of naming `fighters[0]` and `[1]`, for the ratchet. It's the same code; re-run `others_frame_check`, `split_sweep` and the digest before landing.
- **The look gate is owed.** A scratch scene (`near2v2` in the capture hook: two fights, cross on, all four standing, the other pair brought to 1,000 units and back; `?others=1&tiles=1`) was being captured when the pause came. Nothing was kept. Then the flash run in both modes.
- **The band around 1,300 units:** a weight held partway frames neither all four nor the edge. Widening the ease band, or letting the edge lean work while the weight is under 1, is the next refinement.
- **Taste calls for Orb, through the EP:** how small the pair may get for all four (0.55 of their size, at least 43 px), and the edge lean.
