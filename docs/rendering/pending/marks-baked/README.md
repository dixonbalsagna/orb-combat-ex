# The store's grooves drawn, and feet on the ground they stand on (A1 clipping, part 2)

Parked by Rendering on 2026-11-14, sprint A1's clipping item: terrain plan step 4, "feet on the ground you see", cut down to what's under the fighters (the stand-in's planet design, §5). **It stacks on `feet-ground` and `foot-slice`** (`foot-slice/` carries the `_tile_foot_slice` fix this park first had, for GW1a). Two files:
- **`marks_baked.diff`** (sha1 1e50522a, 422 lines; re-cut 2026-11-14 for the groove remainder): `render/core/tile_field.gd`, `tile_ground.gd`, `look.gd`, and the new gate `render/tools/feet_check.gd`;
- **`grant-world-store.patch`** (sha1 0e606aaa, 47 lines; **a grant**, World's file `sim/world/store.gd`): one new read-only function. It applies on main as it is.

Main 83a5b963 + `feet_ground.diff` + `foot_slice.diff` + `marks_baked.diff` applies in that order and gives the tree the gates ran on. No hash change, no state written.

## What it fixes

After feet-ground, 796 of the 875 samples left with feet under the drawn ground were fighters standing in a beam's groove or a slide's trench. The store digs those into the sim's ground (scorch and trench records), but the tile ground drew only crater bowls, so the fighter was drawn sunk by up to 216 units.

## The change

- **`WorldStore.parts`** (the grant): `heightDelta`'s two halves at a point, the craters' sum and the grooves' least, through the same index and arithmetic. Read only. `heightDelta` is `y < 0 ? min(x, y) : x`.
- **The tiles carry the grooves.**
  - On a field world, a tile at level 1 or finer takes `heightDelta` less the craters' sum at each node: the part the vertex stage's 16 bowls don't draw.
  - A new store record asks again for every tile its footprint crosses: points every half tile per level, along a trench from end to end and across to its reach, corners included. That covers a groove, a trench segment, or a crater (which changes the less-craters part).
  - The rebakes are filled before any new tile, into their own slot (`_store` reuses a present key's layer).
- **The lift's ground takes off only the craters' sum,** so a fighter's feet follow the drawn ground. On a groove not yet baked, he stands on the drawn, undug ground. A tile stored after the frame's lift reads gets the bodies' columns read again at the end of the fill.
- **A body's own column takes his own lift** (`_body_at`).
  - The lift is looked up by column, in `lift()` and in `globe_place`, and it was read at the column's middle. On a narrow trench's wall the drawn ground changes by tens of units across one column's 32 units.
  - Every frame, each body's column, and the neighbour he's nearest, take the lift read at his exact place, and the ground the lift's fade compares him with. A column he leaves is read at its middle again.
  - The table is uploaded only when a value changed.
- **The lift's fade** compares his height with the full stand ground, bowls included. Before, a fighter deep in a big crater lost his lift and sank: seed 3's 52-unit sink at a rim.
- **Bowls by the fighters:**
  - every bowl within its reach plus `BOWL_FEET_REACH` (300) of a body is drawn before the bowls nearest the camera;
  - a bowl under a body on the ground (within `BOWL_FEET_LIFT`, 30) opens at once, since the sim dug it at once;
  - the quarter-second opening stays everywhere else.

## Result

The feet probe and the gate: 10 seeds of 1,800 ticks on the tile ground, 4,014 standing samples.

| | main | feet-ground | first cut | **this cut** |
|---|---|---|---|---|
| feet off the drawn ground by over 8 units, either way (the gate's count) | 933 | 875 | 125 (3.1%) | **42 (1.0%)** |
| ... sunk / floating | 892 / 41 | 875 / 0 | 99 / 26 | **42 / 0** |
| the worst | 194.9 | 215.8 | 22.0 | **19.0** |
| seeds with nothing over 8 | 0 of 10 | 4 of 10 | 7 of 10 | **8 of 10** |

`docs/rendering/runs/83a5b963/marks-baked-2.txt`, on main 83a5b963 + feet-ground:
- it imports clean, and `golden.json` is byte-identical;
- the tile, lake water, cover water, sweep and ground checks pass, and the render gates pass 20 of 20;
- the feet gate passes at 3%.

How the remainder was found: `groove-remainder.txt` (the footprint ask), `-2` (per-frame reads: no change), `-3` (the body's own lift), `-4` (the fade's ground: no change).

What's left (42):
- **seed 1: 21 samples, up to 19 units, on one trench's lip.** The strip's rows draw a column's residual deform flat across the column (`offset_at` and `ground_offset4`'s `gf(i, 2)`), while the sim interpolates the deform between columns (`WorldTerrain.groundY`). Where the deform drops sharply from one column to the next (21.9 to about 0 here), the two disagree inside the column. The fix: draw the residual the sim's way, interpolated, in both. That changes what the rows draw, so it comes with its own look gate.
- **seed 7: 21 samples at 8.0 to 8.8.** These aren't on store marks; likely the same kind of small interpolation difference.

## The feet check as a gate

`render/tools/feet_check.gd` (the design page's §6): 10 seeds through the game's own main, every standing frame. It passes when no sample is more than 25 units off either way, and at most 3% are more than 8 off. It needs the tile ground (on by default with globe-default, else `--tiles`). It's a long gate, about 20 minutes, so run it below normal priority.

**The line is a ratchet** (the EP, 2026-11-14): 4% while feet stood on undrawn grooves, **3% with this cut** (it passes at 1.0%), then lower. The first cut failed 3% by a hair (`feet-check-gate.txt`, 3.1%) and passed at 4% (`feet-check-gate-4.txt`). The count can move by a few samples from run to run: the tiles are filled on a time budget, so a loaded machine moves when a rebake lands. The worst and the share hold.

## Owed before it lands

- **The grant** for `sim/world/store.gd` (`WorldStore.parts`); the EP has sent it to World.
- **The web rebake cost,** in a quiet window (Performance; terrain plan step 4's measure). The footprint ask queues more tiles per mark than the first cut did; the probe counts rebakes (`RenderTileField.rebakes`) but times nothing.
- **The look gate:** done on Orb's replay against the 9 November build (`docs/rendering/runs/6a30b4c9/feet-orb-side-by-side.txt`; pictures uncommitted). Also the flash readings on the tile ground (wave 2).
- **A look-gate item before the feet parks land (the EP, 2026-11-14):** in that side-by-side, a tower behind the fight shows dark gaps between floors for frames 108 to 111 (ticks 5,210 to 5,240), with the parks only.
  - The sim is the same: VFX's `hash_check` gives identical final hashes with and without the feet parks (`runs/f61eb8c2/feet-hash.txt`).
  - So it's drawing, unexplained so far. The likely cause is the beam's groove under the tower, now drawn, taking the tower's footing down with it ("a footing that moved sets its building again").
  - To settle: the tower's footing and drawn base read at those ticks, with and without the parks.
## The store-parts version (for when World's stack lands)

**`marks_baked.store-parts.diff`** (sha1 db211955, 421 lines): this park re-cut onto World's store-parts. Land it **in place of `marks_baked.diff` and without `grant-world-store.patch`** once World's GW1c stack is on main. That stack is `globe-step2` (+ its Simulation grant), `a-world-01` (+ grant), `planet-sizes` (+ Simulation's and the meteor grant), `gw1c-world` (+ fix), then `store-parts`.

- `WorldStore.parts` is now a `PackedFloat64Array` [sum, groove, lip], read in float64 throughout. The tiles carry `WorldStore.combine(sum, groove, lip) - sum`, World's one formula. The lift's ground takes off `parts[0]`.
- **Proof on that stack** (`docs/rendering/runs/fd5c1895/marks-baked-store-parts.txt`, main fd5c1895 + World's stack + feet-ground + foot-slice + this):
  - it imports clean, and `golden.json` is byte-identical to the stack without the feet parks;
  - World's `globe_check` fails 0; the five ground checks pass; the render gates pass 20 of 20;
  - **the feet gate passes at 3%: 21 of 3,236 (0.6%), the worst 16.6, all in seed 7.** That's without rows-interp. With `rows-interp/` added on the same stack, seed 7 is clean (0 of 359, the worst 0.9), and the other nine seeds were clean already (the worst 7.3).
- **A dependency:** with the shipped data the sum is crater bowls only, the vertex stage's share. Before `globe.flatten`, heaps, merges or `repeats` get producers, the split needs a fourth part from World (the crater bowls alone), or the vertex stage must draw the rest. World's own note says to flip the flatten only after my look gate and a bake read.
