# The stance on water on the globe ground (Animation, 2026-11-20, a check; re-parked with the finer tiles; lake and shore rows pinned to GW2, 2026-11-21)

The EP's item after GW1a: a fighter standing on the sea on the globe ground, read against Rendering's ground (the tile field), and whether the stance reads right in play.

## Why a new check

On the globe ground (`RenderTileGround.on`, the default since Orb's decision 3) a match is a planet slice and the sim's `S.water` is all zero: the sea lives in the tile field. `_test_water_stance` picks its water out of `S.water`, so it can only run on the strip ground (the GW1a pins say so). Nothing read the globe ground's own water.

## What was built

- **`render/anim/tools/water_tile_check.gd`** (standalone, headless, `--script`): on the planet ring (planet 7, gen 3, the globe ground's own) at 240 places 640 units apart, the sim's floor with the water floor on (`WorldWater.floorAt`) against the tile field's drawn ground and water (`height_at`, `water_top`), the fighter's feet taken as the shared placement lifts them (`lift`). **The tiles are asked for as the camera asks in play: levels 3 and 4 at each place and 64 units either side** (the first cut asked only for levels 1 and 2, 128-unit nodes, and read a steep lot ramp and a lake bed too coarsely; Rendering's finding, 2026-11-20). Gates: **sea** (the sim says sea at level 0): feet on the drawn water within 6 units; **dry** (no drawn water): feet on the drawn ground within 6; **wade** (the tiles draw water over what the sim calls dry): feet under the surface by less than `wade.below` (75) and never above it by more than 6. **GW2 pins** (the EP's ruling of 2026-11-21: the lake group is out of GW1b): **lake** (the sim holds a lake's level): the feet against the drawn lake surface, within 6; **shallow** (the sim says dry but the water floor's wade lift stands the body more than 6 over ground the tiles draw dry: a lake's margin, which the first cuts counted as `dry`); both are pins, printed and not gates by default, and gates under `--lakes` (`--strict` is the same flag). **shore**: along the whole ring at 16-unit steps, wherever the sim's water begins (`seaAt` flips), the first wet column's depth over its ground must stay under 150 (two body heights: the wade line plus a steep bank's step in one scan step; the sea's own steep coasts read 75 to 78); a pin, a gate under `--shore`; `--gw2` is `--lakes` and `--shore` together. `--verbose` lists every place beyond a tolerance.
- **`_test_water_stance_globe`** in `anim_check.gd` (the globe twin of `_test_water_stance`): the match is the planet slice, the pair is put at a deep sea place, a lake place and a wade place with the floor on, and the body must read as standing (no airborne weight, both grounded, within 8 units of the floor). It leaves the floor and the ground switch as it found them.

## What it found (planet 7, gen 3, 240 places; the finer tiles)

| Data | sea | dry | wade | lake | shore |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **the GW1a stack** (floor-rise grant on) | 51, 0.0 | **FAIL** 4 beyond 6 (31.9 above) | 11, under by 34.7 at most | **FAIL** 17 of 17 beyond 6, **up to 683.8 above the drawn ground** | 26 shores, 4 at or over 150 (up to 795.6) |
| **GW1b's 44-line list, lakes out** (docs/ep/reviews/GW1b-stack.txt minus its four lake lines; default flags **pass**) | 51, 0.0 | ok 157, 1.8 at worst | 11, under by 34.7 at most | **pin GW2**: 17 of 17 beyond 6 (up to 683.8 above), plus **4 shallow** (8.8 to 31.9 above) | **pin GW2**: 26 shores, 4 at or over 150 (up to 795.6) |
| **the lake group in** (the GW1a stack plus World's `lake-places` with `lakeMax` 8 and Rendering's `water-everywhere`) | 51, 0.0 | ok 149, 1.8 at worst | 23, under by 34.7 at most | **ok 17 of 17, 0.0 above or below** | the same 26 shores, the same 4 at or over 150 |

`--strict` **passes with the lake group in** (both places Rendering listed, x 32,000 and x 22,400, clear with levels 3 and 4: 1.8 and 0.0). Main's data (the earlier cut, coarse tiles) is in `pending/water-tile-check/records/`.

**The dry row's four places are the lake fault's margin, not a separate fault** (x 23,040, 48,640, 93,440, 97,280): the sim's floor is up to 31.9 over the ground, a wade lift at the edge of a lake the tile field draws no water for. They hold only with the lake group in (World's `lake-places` and Rendering's `water-everywhere`); without it they are the same fault at the lake's edge, so they are the `shallow` pin, and the `dry` gate (true dry ground, no floor lift) passes on 157 places at 1.8 worst.

**The lake fault** (on the GW1a stack): with `field.json` `plans.everywhere` on, the tile field drew no water at the 17 lake places while the sim kept its levels, so fighters stood in the air up to 684 units over a lake bed (the GW1a stack's `field.json` alone reproduces it on main's data). Read in play (a hand-staged scene on the stack's real renderer; no picture is kept in git): deep sea and wade right, both lakes empty sky. World's `lake-places` and Rendering's `water-everywhere` fix it: every lake draws at the sim's level and the feet are on it.

**The shore-level fault, still World's** (the shore rows): the sim's lake level is far above its shore at four places, so a lake's water begins above its own bank. The sim's ground climbs smoothly through each edge while the floor jumps to the lake level:

| shore x | first wet column | ground | the sim's floor | water above its shore |
| :--- | :--- | :--- | :--- | :--- |
| 21,824 | 21,824 | 533.3 | 989.5 | 456.2 |
| 24,000 | 24,000 | 1,266.9 | 2,062.5 | 795.6 |
| 27,904 | 27,888 | 1,561.3 | 1,807.5 | 246.2 |
| 93,216 | 93,200 | 1,899.6 | 2,323.8 | 424.2 |

Walking over the first of these edges (x 23,800 to 24,001 at 420 u/s) the floor-rise lifts a fighter 118, 184, 184, 184 and 169 units on five ticks, about 13 body heights, which the step-up (docs/animation/step-up.md) covers with a crouch but cannot make a cliff. A lake surface cannot sit above its shore: it is the lake's level or extent that is wrong there, not the ground.

**Does the stance read right in play?** On the sea and in a wade, yes; at a lake, once the two parks are in, yes (the feet are on the drawn water to 0.0). The animation's stance was never the fault: it is a ground stance on the floor it is given (`_test_water_stance_globe` is green on every build above).

## Not shown

- One planet (7, gen 3) and 240 places; other planets and sizes are not read. The check takes the planet, the step, the side and the tolerances as constants.
- Read from data, not from a picture of the fixed build (the lake picture above is of the unfixed stack).
- Not wired into CI (that list is not Animation's); `godot --headless --path . --script res://render/anim/tools/water_tile_check.gd` is the GW1b line (it passes without the lake group and with it); `-- --gw2` is the GW2 line, which fails until World's lake group and shore-level fault are in.
