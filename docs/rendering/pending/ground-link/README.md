# Park: the shared ground keeps its tile field (QA's GB-010; Rendering, 2026-11-26)

## The file

| File | What |
|---|---|
| `ground_link.diff` (sha1 2e01b13c9993, 73 lines) | One condition in `render/core/planet_view.gd`, plus a new check, `render/tools/ground_link_check.gd`. It applies strict on main (checked on 3c95f5af). |

## What it does

In split screen, the second pane's `PlanetView` has a `source` (the first pane's view) and shares its `GroundField`: one ground for both panes.

Every build's `_bs_begin` cleared `ground.tile_field`. The first pane's build links it again once its tile copies are made. The second pane's build ran after that and cleared the shared ground's link, and nothing linked it back. So whenever a match was built with the split attached (in QA's soak, from the second match on), the ground had no tile field for the whole match:
- **Store craters drawn twice.** No store crater is held, so the rows and the store's bowl both draw each one.
- **Heights off the drawn ground.** `GroundField.ground_at` reads the strip's arena heights off the fighter plane, instead of the tile ground's heights. Crowds, feet and the panes then stand off the drawn ground.

Now a view with a source leaves the shared ground's link alone; its source's build has already set it this match.

- **The sim:** nothing is written to it.
- **Camera:** this is separate from Camera's rig line (`SplitRig.reset` re-sampling `_pl`, the tick-1 pop), which is Camera's to park.

## Proof

The record is `docs/rendering/runs/0d9af28a/gb010-feet.txt`. The trees are in Rendering's scratch:
- **u0:** main plus the un-hide candidate.
- **u2:** u0 plus Camera's rig line.
- **u3:** u2 plus this park.

**A scratch probe: three matches of 1800 ticks, through main, with the split attached.**

| Tree | Ground's tile field | Store craters drawn twice | `ground_at` against the tile ground |
|---|---|---|---|
| u2 (before) | none in every match | 3 of 5 in match 1 | max 579, 611 and 1,020 units off |
| u3 (after) | linked in every match | 0 | 0.0 |

**The feet check, ten matches one after another, the split attached.** It uses `render/tools/feet_check.gd` with `--size` and `--split`, from the marks-baked park. On u3:

| Size | Over 8 units | Worst |
|---|---|---|
| Medium | 0 of 3,511 | 4.2 |
| Small | 0 of 2,070 | 1.2 |
| Big | 21 of 3,623 (0.6%, all seed 8) | 10.0 |

All three pass (the limits are 3% and 25 units). On u0, without the rig line and this park, small failed (worst 37.6) and big failed (worst 42.4).

**The new check.** `ground_link_check` runs three matches (seeds 1 to 3) through main with the split attached. After each match's load plus 120 ticks, every pane's planet must have a tile field, and its ground must be linked to that field. `-- --negative-control` clears the link after the second match, as the old code did, and the check fails.

**The joint proof with the tick-0 craters on the current main:** `docs/rendering/runs/<HEAD>/ground-link.txt`. It covers golden, the five ground checks, drawn_check, ground_link_check and its negative control, the render gates, medium's collapse in both modes before and after, and the reel's side-by-side, in `docs/rendering/img/sizes/ground-link/`.

## NEEDS FROM EP

- **A gate line in the same landing:** `run ground_link_check` in `docs/ep/gate/render-gates.sh`. The check-scripts table's ratchet fails a new check that has no CI line, gate line or reason.
- **The order:** land with or before `tick0-craters`.
