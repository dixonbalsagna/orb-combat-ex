# Split vision: two parks (Camera, 2026-11-01)

What they are: `docs/camera/split-vision.md`. Each applies on main alone or after swing 1 to 11, in either order. Apply with `git -c core.autocrlf=false apply --ignore-whitespace --whitespace=nowarn`.

| Park | Sha | Files | What |
| :--- | :--- | :--- | :--- |
| `split-vision.patch` | 764e0118 | `render/camera/split_rig.gd`, `camera_params.gd`, `tests/split_vision_check.gd` (new) | `eased_merge` (no soft edge, whole line) and `split_ignores_power`. Both off |
| `cut-dissolve-gone.patch` | ddc9915d | `render/camera/split_view.gd`, `split_rig.gd` (comments), `camera_params.gd`; **`render/tools/flash_capture.gd`: 3 lines and a comment, a grant** (its `nodissolve` word called the removed `set_cut_dissolve`) | The unused cut dissolve removed: RL-229 withdrew the ask, and it was never on. Byte-identical |

**To turn the merge fix on,** once Orb has marked it: `var eased_merge: bool = true` in `split_rig.gd`. Tested on: `split_sweep` passes. Land it with the side-by-side, `img/split-vision/merge-close-up.jpg`.

**Left stale on purpose:** the comment "a cut is a dissolve in reduced motion" in `split_rig.gd`, where a swing patch sits on the same lines, and `split-screen.md` section 7, which should change when the merge fix goes on.

**Passed on main 66654335 + tile + Encounter's swing + swing 1 to 11 + both parks:** `split_vision_check` 11; `flight_shots_check` 499; `launch_shots_check` 549; `swing_real_check` 48; `swing_shot_check` 164; `peak_shot_check` 24; `swing_places_check` 33; `clip_digest` (48,600 lines) and `split_sweep` identical off; `determinism`, `pane_check`, `seam_sweep`, `flight_check`, `sky_check`, `depth_check`.
