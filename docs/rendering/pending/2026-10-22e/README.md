# Parked: the boot warm-up draws in pane 0's own world (Rendering, 2026-10-22)

**Base:** HEAD 425e4be9. Every check ran on copies of the commit, never on the tree.

**Apply** from the project root: `git -c core.autocrlf=false apply docs/rendering/pending/2026-10-22e/batch.diff`. Then delete this folder.

## What it changes

| File | Change |
| :--- | :--- |
| `render/core/main.gd` | the warm-up starts after `split_view.attach`, with pane 0's own world |
| `render/core/beam_view.gd` | `BeamView.prism_mesh()`: the one source of the beam's prism (16 sides, 24 rings), for the view and for anything that warms its first draw |
| `docs/rendering/geometry-and-warmup.md`, `docs/rendering/README.md` | "The warm-up's world": the trace, the cause, the measurements |

**The cause it fixes.** The warm-up was started before the split view moved pane 0 into its own SubViewport (`own_world_3d`). So it drew into the world the pane had left, without the pane's environment, and compiled shader variants the game never draws with.

## Checked

- **Hitches** (Performance's web repro, `frame-bench --scene ai --reduced --ticks 400`; every run valid by the load rule):

  | Build | Strip | Hitches over 50 ms |
  | :--- | :--- | :--- |
  | HEAD | off | 131 (76 ms), 238 (164 ms) |
  | HEAD | on | 131 (110 ms), 238 (216 ms) (run invalid by load) |
  | this | off | none; none but one 59 ms frame at 143 in one run |
  | this | on | none (worst frame 12.8 ms, and 14.4 in a second run) |
  | this, Camera's inset warm-up reverted | on | none (worst frames 14.0 and 13.3 ms) |

- **So Camera's inset warm-up** (`split_view.gd` `_panel_warm`, 5fe08207) does nothing once this lands, on this repro. Its revert can ride along.
- **Gates:** `gates9` (17 checks) and `cue_check` pass, with 0 script errors.
- **The look:** the game starts as before. Nothing on screen changes, since the warm-up draws into a viewport no one shows.
- **Not measured here:** the old-laptop path (`--throttle`, `--igpu`), for Performance.
