# The store's craters drawn once, where they lie (the ripples, most likely)

Parked by Rendering on 2026-11-07, from Orb's morning look ("a patterned ground patch crawling left across the hillside over a match", homework/Files/orb-shots-1107/, shots 2 and 3). **It stacks third, after `crater-clock` and `fore-profile`.** `crater_store.diff` (sha1 e4cf8fbe, 132 lines, cut on main e1397e5c with crater-clock and fore-profile applied) touches `render/core/ground_field.gd`, `render/core/tile_ground.gd` (one line), `render/shaders/tile_read.gdshaderinc` and `render/shaders/tile_vertex.gdshaderinc`. Render only, and only on the tile ground of a field world.

## Why not the crater look

World suspected `crater_look`'s wall tones (`docs/world/orb-looks-1107.md`, look 2). But the crater look is a page word, `craterlook=1` (`tools/preview/switches.mjs`), and Orb's page ran without it (`?planet=7&meteor=loud&tiles=1&go=1&blackbox=1&audiolog=1`, the black box's `pageSearch`). That branch never ran in his play.

## The fault

On a field world a crater is a record in World's store, at a planet point, and the sim's deform doesn't carry its bowl. The tile ground draws those bowls from the store (`2026-11-01h-store-bowls`). But the dig also appends an `S.craters` entry at the strip x it was dug at, and `GroundField` kept putting it in the strip's rows. So the tile vertex drew every crater twice:

- **Off the line it was doubled,** and nearer the line the rows' residual left a ridge.
- **After a turn the second copy rode with the line.** An `S.craters` x never moves. So a ghost crater, with steep walls and ridges, slid across the planet's land with every launch or chase. The giant special crater (radius 2142, depth 556) was drawn 73 units off its bowl at tick 4,500, 4,103 at tick 9,000 and 5,577 at tick 10,500.

A rock-toned, ridged copy of a 2,142-unit crater sliding over hillsides as the match goes on fits "a patterned patch crawling across the hillside over a match". I couldn't get a picture of Orb's own framing (see the look).

## The change

- **`GroundField`:** on the tile ground of a field world, an entry the store holds is left out of the rows (`held`, `_store_holds`). It's matched to its record by time and radius, each record claimed once. A crater the store didn't take (at its cap) stays in the rows.
- **The colours keep their opening, where the bowl lies.** `bowl_new` (tile_read.gdshaderinc) is `crater_new`'s twin on the store's bowls, in both modes. That includes Reduce flashing's even 3 s fade (`CRATER_CALM_S`, a flash-safety rule). It reads `cb_now` and the bowls' `made`, so it follows crater-clock's render clock.
- **`crater_now` every frame** on the tile material (the strip records' `crater_new` read a copy that came every 30 frames).

## Proof

**Orb's 12:29 play,** replayed with `SimCore.step` and the recorded inputs, and checked against its checkpoints. The tree is a8bc66e2 with the kept build's sim and data (the four files are the same on main). Each 60 ticks, at every crater the store holds, I compared the store's bowl with the rows' term (`offset_at`, the CPU twin of the tile vertex's). Output: `docs/rendering/runs/a8bc66e2/crater-store-probe.txt`.

| | as built | crater-clock + this park |
|---|---|---|
| rows' term at the store's craters, largest of 2,745 samples | 533.9 units | 19.2 (the sim's own strip marks) |
| fresh craters carrying the bowl twice (at half a radius) | 58 of 80 | 0 of 80 |

**The look:** Orb's replay played by Tools' black box clip (`tools/preview/blackbox-clip.mjs`) on two builds of his tree (as built, and with this park). Uncommitted stills from Orb's private black box:
- `docs/rendering/img/lookgate/crater-store-orb-72s.png`: tick 4330, the moment of Orb's shot 2.
- `crater-store-orb-4250.gif` and `crater-store-orb-8300.gif`.

At 4250 to 4450 the ground around the fight changes by 10,000 to 50,000 pixels a frame. At 8300 to 8460 the clip's camera is mostly on the sky, so there's little to compare. **The clip's camera doesn't follow Orb's:** at 72.2 s it frames a coast where Orb saw houses and a hill. It runs at 960×540, Orb played at 2000×1125, and it steps a tick a frame. So no still shows Orb's patch itself.

**Gates on main e1397e5c** with crater-clock and fore-profile: `docs/rendering/runs/e1397e5c/sunday-stack.txt`. It imports clean, `golden.json` is byte-identical, the tile, lake water, cover water, sweep and ground checks pass, the render gates pass 20 of 20, and with no tile ground the off stills match main, 13 of 13.

## Limits

- `tile_bowls` draws the 16 bowls nearest the camera (`TILE_BOWLS`), and a store crater is now drawn only there. Orb's match had 14 in all. Raise it if a long match shows more.
- The sim's own strip marks still ride with the line in a turn (deform heaps, rubble, water: the 19.2 above). That's Simulation's documented limit.
- If Orb still sees a lattice after this, the next suspect is the facet and rock tones from the per-node slope on coarse tiles. That's a per-fragment bowl slope, after Sunday.
