# Parked: the slow drift (Rendering, 2026-10-22)

**Base:** HEAD 278bb83c. Every check ran on copies of the commit, never on the tree.

**Apply** from the project root: `git -c core.autocrlf=false apply docs/rendering/pending/2026-10-22i/batch.diff`. Then delete this folder.

## What it changes

World's window 2, render only, behind a switch (off). Between turns the far land and the sky turn slowly round the fight:
- the far land shears sideways by its depth (the crater band never moves);
- the sky's clouds and stars turn their azimuth by the same angle.

The rate is a constant 3 degrees a minute of match time, up to 30. It starts from 0 at each match and again at World's turn, under its hard cut. Crisp: no fade or blur.

| File | Change |
| :--- | :--- |
| `render/core/look.gd` | `SLOW_DRIFT_ON` false, `DRIFT_DEG_PER_MIN` 3, `DRIFT_MAX_DEG` 30 |
| `render/shaders/ground.gdshaderinc` | `drift_tan`; `far_x` shears the far land by depth |
| `render/shaders/sky.gdshader` | `sky_turn` on the clouds' and stars' azimuth |
| `render/core/planet_view.gd` | `set_drift` |
| `render/core/pane_world.gd` | `drift`, sent to the ground and the sky each frame |
| `render/core/main.gd` | `drift_on` (`--drift`, `?drift=1`), `_drift`, the start at a match and at `arena_turn` |
| `docs/rendering/slow-drift.md` (new), `docs/rendering/README.md` | what it does and what was checked |

## Checked

- **Gates:** `gates9` (17 checks) and `cue_check` pass with it off, with 0 script errors. With it off nothing changes.
- **On, natively:** the angle grows at 3 degrees a minute of match time (2.66 degrees by tick 4,000).
- **Stills and GIFs** (seed 4, the AI match, reduced as the demo plays it; Tools' launcher):
  - `docs/rendering/img/drift-7200-d3f1ca0e.png` (uncommitted): d3f1ca0e, then tick 7,200 with the drift off and on;
  - `homework/progress-2026-10-22/slow-drift-time-lapse.gif` (0.94 MB): two minutes, off and on side by side, at 40 times speed;
  - `homework/progress-2026-10-22/slow-drift-real-speed.gif` (0.38 MB): four seconds at play speed, where it does not show as motion.
- **Not yet:** the far land is still the render's own. The planet's own far land (`WorldPlanet.farColumn`) waits on World's cheaper bulk read.
