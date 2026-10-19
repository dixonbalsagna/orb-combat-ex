# Parked: the city arrays for Art's 20 tints and the balconied facade (Rendering, 2026-10-19)

**Base:** HEAD 71e577be. The diff was checked on a copy of that commit, never on the tree. **Land it with Art's `data/art/city-looks.json`** (in the tree, uncommitted). Without this park, that data fails `city_check`: 20 tints do not fit 12 slots.

**Apply** from the project root:

```
git -c core.autocrlf=false apply --check docs/rendering/pending/2026-10-19b/batch.diff
git -c core.autocrlf=false apply docs/rendering/pending/2026-10-19b/batch.diff
```

Then delete this folder.

## What it changes

- **20 tints:** building.gdshader's city arrays (`city_glass`, `city_hi`, `city_trim`, `city_k`) grow from 12 to 20 (`RenderShapes.CITY_SLOTS`).
- **A fourth facade type, balconied:** the facade arrays (`fac_a`, `fac_b`, `fac_c`) grow from 3 to 4, and a new per-tint array `city_k2` holds the balcony's spandrel and slab tones. As Art's concept draws it:
  - panes in pairs, each 0.34 of the cell, the pair's two panes close together;
  - a slab line, 0.12 of a floor, under every second floor;
  - a spandrel band, 0.25 of a floor, under the panes on the floors between.

  Every tone is held to the wall by the budget, as on the other facades.
- **The building's city code is re-packed**, because 20 tints overflowed it. The tint now has 5 bits and the facade 3 ("the look's own windows" is now 4, was 3). The lobby flag moves to 256 and the crown floor to 512 times. The texel is a 32-bit float.
- **`city_check`** covers the balconied facade's neighbours. With Art's new data the widest step is 0.026 of relative luminance, against a budget of 0.085.
- Both switches stay off (`CITY_TINTS`, `CITY_FACADES`), so the shipped picture does not change.

| File | Change |
| :--- | :--- |
| `render/core/look.gd` | `FACADE_PITCH` gains the balconied cell (2.0); `BALCONY_PAIR_GAP` (new) |
| `render/core/shapes.gd` | `FACADES` + balconied, `NO_FACADE` 4, `CITY_SLOTS` 20, `city_code`'s packing, `city_uniforms` (`city_k2`, the fourth facade), the pane grid VFX reads for a balconied tower |
| `render/shaders/building.gdshader` | the arrays, the decode, the balconied facade |
| `render/tools/city_check.gd` | the balconied facade's neighbours |
| `docs/rendering/city-variety.md`, `docs/rendering/README.md` | the arrays, the packing, the balconied facade |

**Before and after**, the mid-rise district from above with both switches on in a scratch build (main's 12 tints on the left, Art's 20 and the balconies on the right): `docs/rendering/img/city/tints20-before-after.png` (uncommitted).

## Checked

- With Art's new data: `gates9` (17 checks) and `cue_check` pass on a scratch copy of 71e577be with the diff, 0 script errors.
- With main's current data: `city_check` and `shape_check` pass.
- The web export renders the new arrays and the balconied facade with both switches on (the still above).
