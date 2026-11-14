# The store's grooves drawn, and bowls by the fighters (A1 clipping, part 2)

Parked by Rendering on 2026-11-14, sprint A1's clipping item: terrain plan step 4, "feet on the ground you see", cut down to what's under the fighters (the stand-in's planet design, §5). **It stacks on `feet-ground`.** Cut on main 83a5b963 with feet-ground (4aa3ecc4) applied; every figure is in `docs/rendering/runs/83a5b963/marks-baked.txt`. Two files:
- **`marks_baked.diff`** (sha1 10a4a514, 373 lines): `render/core/tile_field.gd`, `tile_ground.gd`, `look.gd`, `planet_view.gd`, and the new gate `render/tools/feet_check.gd`;
- **`grant-world-store.patch`** (sha1 0e606aaa, 47 lines; **a grant**, World's file `sim/world/store.gd`): one new read-only function. It applies on main as it is.

No hash change, no state written.

## What it fixes

After feet-ground, 796 of the 875 samples left with feet under the drawn ground were fighters standing in a beam's groove or a slide's trench. The store digs those into the sim's ground (scorch and trench records), but the tile ground drew only crater bowls, so the fighter was drawn sunk by up to 216 units.

## The change

- **`WorldStore.parts`** (the grant): `heightDelta`'s two halves at a point, the craters' sum and the grooves' least, through the same index and arithmetic. Read only. `heightDelta` is `y < 0 ? min(x, y) : x`.
- **The tiles carry the grooves.**
  - On a field world, a tile at level 1 or finer takes `heightDelta` less the craters' sum at each node: the part the vertex stage's 16 bowls don't draw.
  - A new store record asks again for the tiles it reaches: a groove, a trench segment, or a crater (which changes the less-craters part). Those are read at its points and a half width either way, at levels 1 to 4.
  - The rebakes are filled before any new tile, into their own slot (`_store` reuses a present key's layer).
- **The lift's ground takes off only the craters' sum,** so a fighter's feet follow the drawn ground at every moment.
  - On a groove not yet baked, he stands on the drawn, undug ground.
  - A tile stored after the frame's lift reads gets the bodies' columns read again at the end of the fill, so the feet never lag a frame.
  - The lift's fade compares his height with the full stand ground, bowls included. Before, it compared with the ground without craters, so a fighter deep in a big crater lost his lift and sank: seed 3's 52-unit sink at a rim.
- **Bowls by the fighters:**
  - every bowl within its reach plus `BOWL_FEET_REACH` (300) of a body is drawn before the bowls nearest the camera;
  - a bowl under a body on the ground (within `BOWL_FEET_LIFT`, 30) opens at once, at first sight or the moment he stands in it, since the sim dug it at once;
  - the quarter-second opening stays everywhere else.
- **`PlanetView._tile_foot_slice`** returns on a second pane (`source != null`). It shares the first pane's foot arrays but not its seen list, so it read past the end: the "Out of bounds get index" Camera saw about 280 times a digest run, on main too.

## Result

The feet probe: 10 seeds of 1,800 ticks on the tile ground, 4,014 standing samples.

| | main | feet-ground | + this park |
|---|---|---|---|
| feet under the drawn ground by over 8 units | 892, worst 194.9 | 875, worst 215.8 | **99, worst 22.0** |
| ... in the first 600 frames | 170 | 153 | **0** |
| ... a bowl still opening / the lift not read | 17 / 147 | 17 / 43 | **0 / 0** |
| feet floating over 8 units | 41, worst 16.3 | 0 | 26, worst 21.8 |
| seeds with nothing sunk over 8 | 0 of 10 | 4 of 10 | **7 of 10** |

Proof on the same tree: it imports clean, `golden.json` is byte-identical, the tile, lake water, cover water, sweep and ground checks pass, and the render gates pass 20 of 20.

What's left, all on store marks the tiles don't draw yet (78 of the 99 by the probe's own sorting):
- seed 1: 73 samples, up to 22 units;
- seed 2: 5, up to 9.9;
- seed 7: 21, 8.0 to 8.7.

They're likely a rebake that hasn't landed yet, or a groove narrower than the tile's node spacing where no finer tile is loaded. The floating samples are mostly seed 1's too (21, up to 21.8).

## The feet check as a gate

`render/tools/feet_check.gd` (the design page's §6): 10 seeds through the game's own main, every standing frame. It passes when no sample is more than 25 units off either way, and at most 3% are more than 8 off. It needs the tile ground (on by default with globe-default, else `--tiles`). It's a long gate, about 20 minutes, so run it below normal priority. Its verdict on this park (`docs/rendering/runs/83a5b963/feet-check-gate.txt`): **fails by a hair.** 125 of 4,014 samples (3.1%) are more than 8 units off, against a line of 3%; the worst is 22.0, within 25. The 125 are seeds 1 (94), 2 (9) and 7 (21) and one sample in seed 9, the groove remainder above. Two ways to land it, for the EP:
- as a measurement that reports but doesn't block, until the groove remainder is fixed;
- at 4% now, ratcheting to 3% and then lower as the remainder goes.

I haven't changed the line to make this park pass.

## Owed before it lands

- **The grant** for `sim/world/store.gd` (`WorldStore.parts`).
- **The web rebake cost,** in a quiet window (Performance; terrain plan step 4's measure). The probe counts rebakes (`RenderTileField.rebakes`) but times nothing.
- **The look gate:** a side-by-side on Orb's replay where a groove or trench lies under a fighter, against the 9 November build. Also the flash readings on the tile ground (wave 2).
