# Water on the globe ground: a check, and a fault it finds on the GW1a stack (Animation, 2026-11-20, parked)

The EP's item after the step-up: a fighter standing on the sea on the globe ground, read against Rendering's ground (the tile field), and whether the stance reads right in play. Design, numbers and the in-play read: `docs/animation/water-tile-check.md` (inside `water-tile-check.patch`).

## Files

| File | What |
| :--- | :--- |
| `water-tile-check.patch` (sha1 6c8b2875) | new `render/anim/tools/water_tile_check.gd` (+ uid): on the planet ring (planet 7, gen 3), 240 places, the sim's floor against the tile field's drawn ground and water, the feet as the shared placement lifts them; gates sea, dry, wade; the lake line is a finding (`--strict` fails on it); `--verbose` lists every place beyond 6 units. `render/anim/tools/anim_check.gd`: `_test_water_stance_globe` (the globe twin of the water-stance row: a deep sea, a lake and a wade, floor on, grounded stance). New `docs/animation/water-tile-check.md`. Applies on HEAD 2402ab83 and on the GW1a stack (s422), checked. No data, schema or sim file touched; no grant needed |

## Results

| Where | `water_tile_check` | `_test_water_stance_globe` |
| :--- | :--- | :--- |
| **main (2402ab83)** | **passed**: sea 51 places on the drawn water (0.0 at worst), dry 149 (2.8), wade 23 (under the surface by 44.2 at most, under the 75 line); lake finding: 17 places, 14 beyond 6, up to 59.2 above the drawn surface and 35.6 below | green; `anim_check` 0 failed, 10,539 checks |
| **the GW1a stack** | **FAILED**: dry 5 beyond 6 (32.6 above), lake 17 of 17 beyond 6, **up to 681.5 above the drawn ground** | green (the stance is a ground stance on the floor it is given) |

## The fault (report; not Animation's to fix)

On the GW1a stack **the lakes have no drawn water and the fighters stand in the air over them.** Cause, bisected: GW1a's `data/biomes/field.json` (`everywhere` true) alone reproduces it on main's data; with it, the tile field's `water_top` finds no water at the 17 lake places (and 5 shallow-lake places), while the sim keeps its lake levels and the water floor stands a fighter on them: up to 681 units, nine body heights, over the drawn lake bed. Read in play (a hand-staged scene on the stack's real renderer): deep sea right, wade right, **both lakes: fighters in the air with nothing drawn under them.** On main's data the lakes are drawn, but the sim's one level and the tiles' per-node levels differ (59.2 above, 35.6 below): smaller, and the same two owners. Owners: World (lake levels) and Rendering (the tile field's water under `everywhere`). `records/`.

## What is not covered

- One planet and 240 places; other planets and sizes are not read (constants at the top of the script).
- The in-play read is of four hand-staged places, once; no picture is kept (no fighter picture goes in git).
- The check is not in CI (that list is not Animation's): `godot --headless --path . --script res://render/anim/tools/water_tile_check.gd`; on the stack today it exits 1.
