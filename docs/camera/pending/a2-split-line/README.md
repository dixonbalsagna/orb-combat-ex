# Parked: the player's split line, later / standard / sooner (a2-split-line)

Camera, 2026-11-25, the EP's go (A2, row 2). Orb wants to see split-sooner in play, not in pictures, and a friend of Orb's once asked for the opposite (`docs/ep/vision.md`, playtest of 2026-09-29). So the split line is a setting Orb can change in Orb's build: **Split screen: later / standard / sooner**. UI's row is gated on a feature flag that is off on main. The EP turns it on in Orb's build.

**Apply on the GW1c stack**, before or after `../gw1c-door-holds/` and `../cd04/`: `git -c core.autocrlf=false apply split-line.patch` (sha1 c293c869, 149 lines).
- Files, mine: `render/camera/split_rig.gd`, `split_view.gd`, `camera_params.gd`, `tests/own_pane_check.gd`, `tests/split_sweep.gd`.
- **Grant, Rendering's:** `grant/grant-rendering-split-line.patch` (sha1 777fa747), one line in `render/core/main.gd` `_sync_split_options`: `split_view.set_split_line(String(o.get("camera_split_line", "standard")))`. Without it the setting does nothing and the game plays standard.
- **UI's part** (the EP briefs UI): option `camera_split_line`, a choice of `later`, `standard`, `sooner`, default `standard`, group `display`, on the Settings screen behind a features.json flag.

## What it does

| Setting | Split line (`R_SPLIT`) | Join line (`R_MERGE`) | In words |
| :--- | :--- | :--- | :--- |
| later | 0.040 | 0.0509 | one picture longer: a fighter down to about 1/25 of the screen's height before the split |
| standard | 0.055 | 0.070 | as now, to the bit |
| sooner | 0.077 | 0.098 | the split comes while a fighter is still at least about 1/13 of the height (Orb's "raise") |

- The join line moves by the same ratio as the split line, so the gap between them, which stops the screen flapping, is the same.
- The beam struggle's line and the small-screen pixel floor (`MIN_PX`) don't move.
- A new match takes the setting at once. A change mid-match moves the lines over `SPLIT_LINE_EASE` (2 s per unit of the factor), never in one step.
- **Later keeps one picture longer only while it holds both fighters.** If a fighter is off the drawn shared view, the split opens as it would at standard (the drawn-off rule uses the standard line, capped under the join line). Found by split_sweep at later: in the intro-resize row double_drop, the aimed size 0.0405 sat just above the later line 0.040, while the drawn view, whose zoom lags, had a fighter 94 px off the left edge.
- The camera is render-only: the sim, replays and online play are unchanged. Each player sees their own setting.
- `--split-line=later|sooner` on `split_sweep` and `own_pane_check` runs every rig at that setting (own_pane through main, as the game sets it).

## Proof

Trees: the GW1c stack (main 54474b97 + 28 pieces) + door-holds + cd04 (k2), against k2 + this park and the grant (k4). Records: `docs/camera/runs/54474b97/a2-split-line/`.

- **Standard is unchanged:** the collapse clip's digest is the same at all three planet sizes and both viewports; the golden is unchanged (989878d6d335).
- **Every check passes at standard:** all 15 camera checks (cut_register 73), split_sweep, and the pane, seam, determinism and HUD-words gates.
- **At later and at sooner:** split_sweep and own_pane_check (12) pass.
  - At later, the fault above was found and fixed. Before the fix, split_sweep failed that one row.
- **The collapse clip at medium**, worst of 4 (primary / area-15% / 2 s memory), in `readings.txt`:

| Setting | Reduce flashing (the default) | Full effects |
| :--- | :--- | :--- |
| standard | PASS 1 / 2 / 1.5 | PASS 1 / 1 / 1 |
| later | PASS 1 / 2 / 1 | PASS 1 / 1 / 1 |
| sooner | PASS 1 / 1 / 1.5 | PASS 2.5 / 2.5 / 1 |

Sooner with full effects reads at the gate (2.5) and passes. It splits during the collapse, where standard holds one picture, so the panes' pans count.

## Not in this park

- The opening's owned ceiling (`OPENING_PLANET_CEIL` 0.046, due 28 Nov) is still measured at standard. If Orb picks sooner as the default, the opening's smallest size rises with it, and the ceiling is re-measured then.
