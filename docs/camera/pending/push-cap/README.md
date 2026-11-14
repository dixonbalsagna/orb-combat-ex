# Parked: the blow push inside the zoom's comfort limit (push-cap)

Camera, 2026-11-09 overnight, for the EP's Monday 10:00 build. The batch (main 66b66796 plus tonight's parks) failed one split_sweep row:

> real match 10 pitch 49 full (rig sees two humans): pane 1 zoom rate 2.85 e-folds a second (limit 2.40) at t=248.42 mode opening

**Apply on main** (cut on 66b66796; `git apply --check --cached` passes there): `git -c core.autocrlf=false apply push-cap.patch` (sha1 bc92711f).
- One file: `render/camera/split_rig.gd` (mine), 10 lines.
- The two-fighter ratchet: no change from this park.
- It's independent of cd04, which still applies beside it.

Outputs (CD-22): `docs/camera/runs/66b66796/push-cap/`.

## The cause

The planner now reads structure mass rather than people, so the fight plays out differently. At t=248.40:
- **The slam.** A slam door closes the split (the slam is allowed its own faster zoom). The single view lasts one tick, and then "split out of frame" opens the split again.
- **Pane 1's zoom.** It had been left by the slam at 1.215, far from the single view's 1.41. As its pane opens it heads there on its comfort cap: 2.42 e-folds a second, the drawn-zoom limiter's `ZOOM_RATE_TRANS`.
- **The push.** On that same tick a landed blow starts a blow push (`_blow_mult`, Research's impact push, amplitude 0.021). It rises 0.75% on its first tick.
- **Why it isn't limited.** The push is applied after the limiter (`f.cam_z = _outs.z * _punch_mult()` in `_make_frame`, so it stays crisp). The zoom on the screen was the drawn zoom plus the push: 2.85.

## The fix

The limiter leaves room for the blow push's own change on each frame. Before it caps the drawn zoom, it takes the push's change since the last frame off the allowance in the same direction (`d_push`; `_bm_drawn` is the push the last frame drew). So the zoom on the screen keeps to the comfort limit:
- The push itself is unchanged (still after the filters, still crisp).
- The drawn zoom gives way by the push's share on the few frames both move.
- When nothing binds, nothing changes.
- No cut, no fade, nothing drawn.

The 6-tick punch (`_punch_only`) is left as it is: split_sweep already allows for it by name.

## Proof (`docs/camera/runs/66b66796/push-cap/`)

| Run, on the EP's batch tree plus this park | Result |
| :--- | :--- |
| split_sweep's failing row alone | passes (0 failures; was 2.85 against 2.40) |
| split_sweep, full | **passes** |
| chase_rush 130, flight_shots 803, launch_shots 1,029, split_share 26, split_vision 11, cross_ko 21, swing_shot 164, swing_places 33, swing_real 48 | all pass |
| swing_read | 14,420 pass |
| Content screen (tools/content-screen.mjs) | the working tree with this park: 0 failing hits |

## RISKS

- **The drawn zoom lags its target by the push's share** while a push rises or falls and the zoom is on its cap: at most 0.021 of a log unit over the push's 7-frame rise. It isn't visible.
- **The look gate:** nothing new is drawn and nothing is cut. The zoom moves no faster than before, only slower on those frames. So there's no side-by-side; the change is under a frame's worth of zoom. Said plainly so the EP can ask for one.
