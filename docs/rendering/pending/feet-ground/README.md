# Feet on the ground drawn: the lift and the start (A1 clipping, part 1)

Parked by Rendering on 2026-11-14 for sprint A1's clipping item. Orb: "the terrain doesn't quite match up with the character's hitboxes, when they first start it looks like they're clipping into the ground". `feet_ground.diff` (sha1 4aa3ecc4, 76 lines, cut on main 59c6b195) touches `render/core/tile_field.gd` and `render/core/planet_view.gd`. Render only, on the tile ground; no hash change. Every figure below is in `docs/rendering/runs/59c6b195/feet-ground.txt`.

## How it was measured

A probe (`feet_check.gd`, scratch): computer against computer on the tile ground, 10 seeds of 1,800 ticks, through the game's own main with its own setup. Every frame, for each fighter standing, it compares:
- **the ground drawn under him:** the finest tile, the strip rows' offset, and the store's bowls read from the tile material, opening included;
- **the ground he stands on:** the sim's `groundY`;
- **his feet as drawn:** the sim's height plus the shader's lift (`RenderTileField.lift`, its CPU twin).

Each gap over 8 units is put down to a cause.

## The three causes this park fixes

1. **The lift wasn't read for his column.** `keep_off` fills the lift table outward from the camera's middle, 24 columns a frame (12 while the line turns). The table is marked stale whenever a finer tile arrives and every 8 frames of a turn, and it starts as zeros. So at the start, and for a fighter away from the middle, his feet were drawn on the table's last value. **Now the columns under every body are read first, every frame, whatever the budget.**
2. **The lift's ground wasn't the one he stands on.** It subtracted a level-1 field read, while the sim stands a fighter on `SimField.col`, a finer read. That left a steady 8 to 16 units between feet and ground. **Now it's the sim's own column read, less the store's marks** (the tile ground draws those itself).
3. **A crater made before the first frame was drawn twice.** The rows are built (`_bs_share`) before the tile field is attached (`_bs_tiles`). So the opening's craters were never found to be the store's (`GroundField.held`, crater-store), and the rows drew each one again over the store's bowl: a rim under the fighter at the start. **Now the rows are built again once the tile field is on.**

## Result

10 seeds of 1,800 ticks, 4,014 standing samples, main against the park:

| | main | this park |
|---|---|---|
| seeds with no grooves or trenches (5, 6, 8, 10): samples over 8 units, worst | 2 each, 12.8 (the start) | **0**, worst 1.2 to 3.5 |
| feet drawn floating over 8 units above the ground | 41, worst 16.3 | **0**, worst 5.1 |
| a fighter on a column the lift hadn't read | 147 | 43 (a finer tile came after the read; that frame drew a current value) |
| feet under the drawn ground over 8 units, all seeds | 892, worst 194.9 | 875, worst 215.8: 796 of them stand in undrawn grooves and trenches (part 2) |

**Gates on main 59c6b195:**
- it imports clean;
- `golden.json` is byte-identical;
- the tile, lake water, cover water, sweep and ground checks pass;
- the render gates pass 20 of 20.

**Look gate:** where feet meet the ground is visible, so a side-by-side against the 9 November build is owed: Orb's replay of a match's start, on his build's tree with and without this park, at his window. The standard flash clips don't load the tile ground, where this park acts. The tile-ground flash readings are wave 2's.

## Not in this (part 2, the larger part)

**The store's beam grooves and slide trenches aren't drawn.** The tile ground draws only crater bowls, so a fighter standing in a beam's groove or a slide's trench is drawn sunk into undrawn ground, by up to about 200 units. That's 800 of the 875 samples left. It's terrain plan step 4, "feet on the ground you see": bake the store's marks into the tile heights, with the lift reading the same function. It's planned next.
