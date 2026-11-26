# The store's grooves drawn, and feet on the ground they stand on (A1 clipping, part 2)

Rendering parked this on 2026-11-14 for sprint A1's clipping item (terrain plan step 4, "feet on the ground you see"). It was re-cut on 2026-11-26 onto main, with World's store-parts landed.

## The file

| File | What |
|---|---|
| `marks_baked.diff` (sha1 00aaf9f85948, 454 lines) | Changes `render/core/tile_field.gd`, `tile_ground.gd` and `look.gd`, and adds the gate `render/tools/feet_check.gd`. |

- **What it stacks on:** `feet-ground`. Main + `feet_ground.diff` + `marks_baked.diff` applies in that order (checked on 663b7c45).
- **foot-slice** has already landed (GW1a).
- **No grant:** World's store-parts landed in GW1c (45bfa1af), so the old `grant-world-store.patch` and the separate store-parts form are retired. This file is the store-parts form.
- **Re-cut changes:** two lines inside `tile_field.gd`'s hunks now call `clock_us()` (main's steady capture clock, 0d9af28a). The feet check also takes `--size` and `--split`, below.
- **The sim:** nothing is written to it.

## What it fixes

After feet-ground, 796 of the 875 samples left with feet under the drawn ground were fighters standing in a beam's groove or a slide's trench. The store digs those into the sim's ground (scorch and trench records), but the tile ground drew only crater bowls, so a fighter was drawn sunk by up to 216 units.

## The change

- **The tiles carry the grooves.**
  - On a field world, a tile at level 1 or finer takes `WorldStore.combine(sum, groove, lip) - sum` at each node: the part the vertex stage's 16 bowls don't draw. `WorldStore.parts` is read in float64.
  - A new store record asks again for every tile its footprint crosses: points every half tile per level, along a trench from end to end and across to its reach, corners included.
  - The rebakes are filled before any new tile, into their own slot.
- **The lift's ground takes off only the craters' sum** (`parts[0]`), so a fighter's feet follow the drawn ground. A tile stored after the frame's lift reads gets the bodies' columns read again at the end of the fill.
- **A body's own column takes his own lift** (`_body_at`). Every frame, each body's column and the neighbour he's nearest take the lift read at his exact place, not at the column's middle. On a narrow trench's wall the drawn ground changes by tens of units across one column's 32 units. The table is uploaded only when a value changed.
- **The lift's fade** compares his height with the full stand ground, bowls included. Before, a fighter deep in a big crater lost his lift and sank.
- **Bowls by the fighters:**
  - every bowl within its reach plus `BOWL_FEET_REACH` (300) of a body is drawn before the bowls nearest the camera;
  - a bowl under a body on the ground (within `BOWL_FEET_LIFT`, 30) opens at once, since the sim dug it at once;
  - the quarter-second opening stays everywhere else.

## Proof of the re-cut

On main 663b7c45: mb0 = main + feet-ground, mb1 = mb0 + this. Record: `docs/rendering/runs/663b7c45/marks-baked-recut.txt`.
- import clean; `golden.json` byte-identical to mb0 and to main's committed file;
- the tile, lake water, cover water, sweep and ground checks pass, and drawn_check passes;
- the render gates pass 20 of 20;
- the feet gate at medium passes: 8 of 3,542 standing samples over 8 units (0.2%), the worst 14.9.

**On the un-hide candidate** (main 0d9af28a plus the split parks, sky-handover, feet-ground, this, rows-interp and fore-clamp, then Camera's rig line and `ground-link`), over ten matches in a row with the split:

| Size | Over 8 units | Worst |
|---|---|---|
| Medium | 0 of 3,511 | 4.2 |
| Small | 0 of 2,070 | 1.2 |
| Big | 21 of 3,623 (all seed 8) | 10.0 |

Records: `runs/0d9af28a/unhide-build.txt` and `gb010-feet.txt`.

**Earlier proofs, on the forms this replaces:**
- `runs/83a5b963/marks-baked-2.txt`: 1.0% against main's 933 samples off.
- `runs/fd5c1895/marks-baked-store-parts.txt`, on World's stack: 0.6%, and seed 7 clean with rows-interp.

## The feet check as a gate

`render/tools/feet_check.gd` runs ten seeds of 1,800 ticks through the game's own main and reads every standing frame. It passes when no sample is more than 25 units off either way, and at most 3% are more than 8 off. It needs the tile ground (on with globe-default, else `--tiles`).

- **`--size <name>`:** plays a planet size, setting `WorldPlanetSize.heldOverride` for a held size (World's `size_check` allows a tool under `/tools/`).
- **`--split`:** attaches the split screen, as the game has it.

It is a long gate, about 4 minutes at medium, so run it below normal priority. The line is a ratchet (the EP, 2026-11-14): 3% now, lower later. The count can move by a few samples from run to run, because the tiles are filled on a time budget; the worst and the share hold.

**The EP's feet gate group needs this park:** `feet_check.gd` is not on main until it lands.

## Owed before it lands

- **C-04, the tower:** in Orb's-replay side-by-side (`runs/6a30b4c9/feet-orb-side-by-side.txt`), a tower behind the fight shows dark gaps between floors for four frames (ticks 5,210 to 5,240), with the feet parks only. VFX's `hash_check` gives identical hashes with and without them, so it is drawing. The likely cause is the beam's groove under the tower, now drawn, taking the tower's footing down. To settle it: read the tower's footing and drawn base at those ticks, with and without.
- **C-18, a default-look side-by-side** of this form: this re-cut has none of its own.
- **The web rebake cost** in a quiet window (Performance). The footprint ask queues more tiles per mark. The big frame-bench (`runs/0d9af28a/frame-bench-big.txt`, with this park in the candidate) shows the pool at most 294 of 800, but the fill's time is not readable on a capture (it runs on the steady clock).
- **A dependency (World):** with the shipped data, the sum is crater bowls only, the vertex stage's share. Before `globe.flatten`, heaps, merges or `repeats` get producers, the split needs a fourth part from World (the crater bowls alone), or the vertex stage must draw the rest.
