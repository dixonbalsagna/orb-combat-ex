# Water on the globe ground: a check, re-parked with the finer tiles (Animation, 2026-11-20)

The EP's item after the step-up: a fighter standing on the sea on the globe ground, read against Rendering's ground (the tile field). Rendering's read of the first cut's two leftover places was right: the check asked only for tile levels 1 and 2 (128-unit nodes); with levels 3 and 4 loaded, as the camera does in play, they clear. This re-park asks for levels 3 and 4 at each place and 64 units either side and keeps World's shore-level rows. Design, numbers and the in-play read: `docs/animation/water-tile-check.md` (inside `water-tile-check.patch`).

## Files

| File | What |
| :--- | :--- |
| `water-tile-check.patch` (sha1 0f8ee10a; re-cut 2026-11-21: the doc `docs/animation/water-tile-check.md` is already tracked on main, so the patch no longer carries it) | new `render/anim/tools/water_tile_check.gd` (+ uid): 240 places on the planet ring (planet 7, gen 3), levels 3 and 4 asked at each place and 64 either side; gates sea, dry, wade; `--strict` makes the lake line a gate; the shore rows (every place the sim's water begins, over 16-unit steps; two body heights) are a finding, a gate under `--shore`; `--verbose` lists every place beyond a tolerance. `render/anim/tools/anim_check.gd`: `_test_water_stance_globe` (unchanged). New `docs/animation/water-tile-check.md`. Applies on HEAD ed1591cb and on World's GW1b stage-1 stack (checked). No data, schema or sim file touched; no grant |

## Result (`records/`)

| Data | `--strict` | shore |
| :--- | :--- | :--- |
| **GW1a stack** + floor-rise grant | **FAILED**: dry 4 beyond 6 (31.9), lake 17 of 17 beyond 6, **up to 683.8 above the drawn ground** | 26 shores, 4 at or over 150 |
| **GW1b's data** (that + World's `lake-places` with `lakeMax` 8 + Rendering's `water-everywhere`) | **passed**: sea 51 (0.0), dry 149 (1.8 at worst), wade 23 (34.7 under), lake 17 of 17 within 6 (0.0 above or below). Rendering's two places: x 32,000 now 1.8, x 22,400 now 0.0 | the same 26, the same 4 at or over 150 |

`_test_water_stance_globe` is green on every build (a deep sea, a lake and a wade: grounded stance, 0.0 off the floor); `anim_check` on main with the patch was 0 failed, 10,539 checks (records).

## The shore-level fault, World's (the rows kept)

`water_tile_check --shore` fails on GW1b's data: the sim's lake level sits far above its shore at four places: x 21,824 (ground 533.3, floor 989.5, 456.2 above), **x 24,000 (ground 1,266.9, floor 2,062.5, 795.6 above)**, x 27,904 (1,561.3, 1,807.5, 246.2), x 93,216 (1,899.6, 2,323.8, 424.2). The ground climbs smoothly through each edge; the floor jumps to the level. A lake surface cannot sit above its shore. `records/gw1b-data-strict-verbose.txt` (the `shore` lines). The step-up retake's real lift (x 23,800 to 24,001, 118 to 184 units a tick for five ticks) is this fault's x 24,000 edge.

## What is not covered

- One planet and 240 places; the constants are at the top of the script.
- Not in CI (Tools' question, once the shore fault is fixed: `--strict` alone is green on GW1b's data today, `--shore` is not).
