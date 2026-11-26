# Park: the tile ground's marks take their own slope (Rendering, 2026-11-25)

Fix 1 of the steady-fill collapse attribution (`docs/rendering/runs/74c03fdb/steady-attribution.txt`). It lands after GW1c (the EP, 2026-11-25). Fix 2 (bowl rims in the foreground line) is withdrawn: with both, small's normal reading got worse (`docs/rendering/runs/31531cb2/tile-marks-collapse.txt`). It goes back to the bench, as an eased clamp at the plane instead of a raised line.

## The file

| File | What |
|---|---|
| `tile_marks.diff` (sha1 7641d955829c, 22 lines) | `render/shaders/tile_vertex.gdshaderinc`. Applies strict on main and on the EP's 29-piece final GW1c tree (main bc1e5558 + `docs/ep/reviews/GW1c-stack.txt`), after VFX's crater-refused. |

## What it does

The tile vertex took the marks' slope (craters, furrows, a groove, rubble) from `ground4`. That function returns the strip terrain's ground after the strip's own foreground cap (`fore_fall`). In front of the fighter line, wherever the line's height reached that camera-relative cap, the slope became the cap's slope less the column's base slope. So it changed from column to column and moved with the camera.

Inside store-held bowls, whose rims and aprons are spared from the fore tone, that slope drew a honeycomb that changed every frame. It showed on tiny's collapse clip with the cap on.

Now the vertex reads the marks' own offset and slope from `ground_offset4`. The offset is the same as before: it is `ground4`'s `.w`, and `far_weight` is 0 inside the band. It is also one fewer `far4` sample and no `fore_fall` per vertex.

## Proof

**The collapse clip.** Worst of 4 readings (960x540 and 1024x768, scale 1 and 2), both modes, one run each (the reel repeats on the steady fill). The before and after of each case are on the same tree.

| Case | Before (normal / reduced) | With the park |
|---|---|---|
| medium, the 29-piece final GW1c tree (what lands) | 1 / 2 | 1 / 1 |
| medium, the 22-piece final tree | 1 / 2 | 1 / 1 |
| medium, main 31531cb2 | 2 / 2 | 2 / 2 |
| small, cap off | 2 / 3 | 2 / 3 |
| big | 2 / 3 | 2 / 3 |
| tiny, cap off | 3.5 / 3.5 | 3.5 / 3.5 |
| tiny, cap on | 5 / 7 | 2.5 / 4.5 |
| small, cap on | 2 / 4 | 2 / 4 |

- No reading is worse. Medium's reduced reading and tiny's cap-on readings are better.
- Small and big still fail because of the merging split's camera (Camera's job).
- Tiny's opening is content at that scale.

Records: `docs/rendering/runs/bc1e5558/tile-marks-fix1-29.txt` (the 29-piece tree), `tile-marks-fix1-gates.txt` (the 22-piece tree), `docs/rendering/runs/31531cb2/tile-marks-fix1.txt` and `gw1c-medium-big.txt` (the stack's other sizes).

**Gates on the 29-piece final tree plus the park:**
- strict apply, import 0, export clean;
- golden byte-identical to the tree without it (the park writes no sim);
- the five ground checks pass (tile, lake water, cover water, sweep, ground);
- the render gates: 20 of 20, flash, flashreg and splitsweep included.

**The look gate.** Side-by-sides, git-ignored, in `docs/rendering/img/sizes/tile-marks/`:
- **`fix1-medium-29-*` (medium, reduced, ticks 120 to 200, on the 29-piece tree).** The worst second's events at ticks 144 and 146 go. The picture is nearly the same: a crater floor in the near ground reads a little calmer.
- **`fix1-tiny-cap-on-*` (tiny, cap on, ticks 760 to 830, on the earlier stack).** The honeycomb on the rock face is gone. The ridge just in front of the fighters keeps its sawtooth edge, now pale instead of dark, and a fighter's foot placement follows the drawn ground. Tiny is not offered in GW1c.

## Notes

- **Camera's drawn-ground sampler** (`drawn_at`, the drawn-at park) is unchanged: it reads the field without the marks, as before.
- **Bowl rims raise the ground near the fighter line, and the foreground line still cuts them at the plane.** That is the zigzag fix 2 was for, and it is back on the bench.
