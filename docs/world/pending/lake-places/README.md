# Park: lakes undrawn and fighters standing in the air over them (World, 2026-11-20; EP order, from Animation's water_tile_check)

Finding (Animation, `docs/animation/pending/water-tile-check/`): with `field.json plans.everywhere` on, the tile field's `water_top` finds no water at 17 lake places and the sim holds the lake's level there, so fighters stand up to 681 units over a lake bed with nothing drawn under them. **Both sides are wrong, in three places.** Runs: `docs/world/runs/lake-places/`.

| # | Side | Cause (measured on the GW1a stack, planet 7 touch 3) | Fix |
| :--- | :--- | :--- | :--- |
| 1 | **Rendering** (`render/core/tile_field.gd`, the bake) | The tile reads a lake's water only where `place_w < 0.5`: away from any building's band. With everywhere on, every one of the 3,835 buildings is in the strip's reach, `_place` is 1.0 at every lake column probed, and **no lake in reach of a town draws water**. The gate was for the first ring's settlement standing on the line; with World's lots (`_has_pads`) a place's ground is in the records and `recordWater` reads it, so there is nothing to keep the water out of | `(place_w < 0.5 or _has_pads)`: `grant-rendering-tile-water.patch`, line 542 |
| 2 | **Rendering** (`water_top`) | The water's top was the ground **at the point** plus the depth **of the node's cell**: where the ground slopes inside a cell the top is off the lake's level by up to 59.2 above and 35.6 below (the finding on main's data as well). The sheet draws a node's own ground plus its own depth | `water_top` returns the layer's own height at that texel plus its depth: the lake's level exactly (989.5 of 989.5 on the lake at x 22,400): same patch, line 613 |
| 3 | **World** (`sim/world/plan.gd` `layFree`) | With everywhere on the planet's free places are laid on it and the lakes are records laid on the ring's plan: **34 of the 3,835 buildings stand under a lake's water over their base, up to 611 units deep** (a town on a lake's bed). Nothing trimmed them (`TRIM_G` trims the sea, not the records' lakes) | `plans.lakeMax` (units; -1 or no key: off, today): a building whose base is under more lake or river water than that is not laid. Shipped -1; the GW1b row sets **8**. `lake-places.diff` + `lake-places-data.diff` |

## Files

| File | What |
| :--- | :--- |
| `lake-places.diff` | World's: `sim/world/plan.gd` (`lakeMax`, the trim in `layFree`, `lakeMaxOverride` for tests; it returns a `drowned` count), `data/biomes/field.json` (`lakeMax` -1), its schema, `sim/world/tools/lake_places_check.gd` (new, `LAKEPLACES`, in CI) and its line in `tools/world-checks.json`. Applies strictly on HEAD |
| `lake-places-data.diff` | The GW1b data row: `plans.lakeMax` 8. It changes which buildings are laid (the hash), so it flips in the window with the field-cache and floor-rise work; the places cache is keyed by the field data's hash, so a flip makes it lay cold once |
| `grant-rendering-tile-water.patch` | **Rendering's file** `render/core/tile_field.gd` (two lines, 542 and 613). Applies strictly on HEAD |

## Result (the GW1a stack, `water_tile_check --verbose`)

| Run | sea | dry | wade | lake finding |
| :--- | :--- | :--- | :--- | :--- |
| before (the stack) | ok | 5 beyond 6 (32.6) | ok | **17 of 17 beyond 6, up to 681.5 above the drawn ground** |
| `lakeMax` 8 alone | ok | 5 beyond 6 | ok | unchanged: **the water is still undrawn**; no building stands in water (0 of 3,800), the lakes are as empty as they were of water (Rendering's gate hides it) |
| + the gate (#1) | ok | 1 beyond 6 (12.5) | ok | 14 beyond 6, **up to 59.2 above, 35.6 below** (main's finding): the water is drawn, off the level |
| + the level (#2) | ok | 1 beyond 6 (12.5) | ok | **1 beyond 6, up to 0.0 above and 12.9 below**: every lake's water is at the sim's level to the unit |

`LAKEPLACES`: off, 34 buildings stand in water over 1, the deepest 611; `lakeMax` 8: 0 in water, 3,800 of 3,835 buildings laid (35 dropped). `validate`: 0 errors.

## What is left (not water, not World's)

`--strict` still fails on **one dry place and one lake place, both at a lot pad's edge**: x 32,000 (the sim's ground 563.5, the tile's mesh 557.2, 6.3 lower) and x 22,400 (865.4 against 839.9, 25.5 lower, the feet then 12.9 under the lake's surface). The raw field read plus the records at the point gives the sim's number; the tile's mesh is lower at a pad's blend edge: a mesh resolution against a pad's steep blend, Rendering's or Animation's call (a finer tile there, or the check's tolerance of 6 at a pad's edge). I tried widening `_records_reach` to a lot's true reach (`(r + blend + bs) x 1.3 + 400`): no change, so it is not the records' reach, and I did not keep it.

## NEEDS FROM EP

- **Rendering** (`render/core/tile_field.gd`): the two lines of `grant-rendering-tile-water.patch`; and the pad-edge ground difference above.
- **Simulation / the window**: `lake-places-data.diff` (GW1b with the other data rows); GW1a lands as is, bug included, as you said.
- **Animation**: `water_tile_check --strict` passes the sea, wade and (with the two fixes) lake rows; the two edge places remain.

## RISKS

- The lakes' towns are not laid with `lakeMax` 8: 35 buildings of 3,835 on planet 7 touch 3 (0.9 percent); other planets not counted (the check takes `--planet` and `--touch`).
- With the gate off for pad worlds, water now draws where `recordWater` says over places on lake shores: the shore towns stand beside drawn water as a lake is, which is the picture the sim already stands fighters on.

**Re-cut 2026-11-20 (GW1b review): lake-places.diff now stacks after cache-determinism** (the GW1a tree: both edit the statics at plan.gd line 38; this one is cut on HEAD plus cache-determinism, the field.json and schema hunks with one line of context). Order tested from a clean HEAD export: data-switches-gw1a, cache-determinism, floor-rise, lake-places, memory-under-model, lake-shore, then the data rows. The `world-checks.json` lines of these parks each sit in their own gap.
