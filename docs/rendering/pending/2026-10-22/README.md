# Parked: the camera roll on climaxes (Rendering, 2026-10-22)

**Base:** HEAD b3a3aa74. The diff was checked on a copy of that commit, never on the tree.

**Apply** from the project root:

```
git -c core.autocrlf=false apply --check docs/rendering/pending/2026-10-22/batch.diff
git -c core.autocrlf=false apply docs/rendering/pending/2026-10-22/batch.diff
```

Then delete this folder.

## What it does

A dutch tilt on the fight's climaxes. The main panes' cameras roll about their view axis:
- **4 to 8 degrees:** 5 for a decisive launch, guard break or interrupt; 6 for a clash or a beam; 8 for a finisher's start or a KO.
- **Toward the loser's side.**
- **Timing:** in over 0.25 s, held 0.8 s, back over 0.9 s, eased.

It is **off by default** (`RenderLook.CAMERA_ROLL_ON`); `--roll`, or `?roll=1` on a page, turns it on. The HUD is never rotated, and Camera's inset strip stays level. CameraRig is not touched: the pane turns its camera after `CameraRig.frame`. The details are in `docs/rendering/camera-roll.md`.

| File | Change |
| :--- | :--- |
| `render/core/camera_roll.gd` + `.uid` (new) | `RenderCameraRoll`: reads the sim's `decisive`, `finisher_start` and `ko` events and the fighters' places; eases the angle |
| `render/core/look.gd` | `CAMERA_ROLL_ON` (false), `ROLL_DEG`, `ROLL_TIMES` |
| `render/core/pane_world.gd` | `render(..., roll)`: the roll about the view axis |
| `render/core/main.gd` | feeds the events, passes the angle to the main panes, `--roll`, `roll` among the URL arguments |
| `docs/rendering/camera-roll.md` (new), `docs/rendering/README.md` | what it does, and the side-by-sides |

**Against d3f1ca0e**, with the roll on in a scratch build (seed 4, Reduce flashing on as the demo has it, motion normal):
- `docs/rendering/img/roll-d3f1ca0e-1760.png`, mid-roll after the launch and beam at 1739;
- `docs/rendering/img/roll-d3f1ca0e-1850.png`, back to level.

Both uncommitted.

## Checked

`gates9` (17 checks) and `cue_check` on a scratch copy of b3a3aa74 with the diff (the roll off, as shipped). The roll-on export renders, with the HUD level.
