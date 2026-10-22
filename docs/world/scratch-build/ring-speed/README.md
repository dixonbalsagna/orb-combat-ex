# The ring read, 9 times cheaper and the same bit for bit (World, 2026-10-22): in scratch, parked, not applied

The EP's finding (Rendering's throttle-4 bench, `docs/rendering/arena.md`): reading a ring (`WorldPlanet.RingJob`) costs about 0.75 ms a column on an old laptop, so k32 is 24 ms a tick inside a form pause. The cost to fix was the read, not the rate. **After this park: 112 us a column becomes 12 us (9.3 times) on this busy PC, over 12 rings (4 planets, 3 sizes); the same read bit for bit.** On Rendering's bound that is about 0.08 ms a column, so **k32 of one ring is about 2.6 ms** (the 3 ms aim), and a landing pick's two rings at k32 are about 5 ms, or about 2.6 ms at k16. Whole ring: 450 ms becomes about 55 to 80 ms of work in all.

| File | What |
| :--- | :--- |
| `ring-read-speed.diff` (5 files) | `sim/world/planet.gd` (`_vn` and three helpers); `sim/world/tools/noise_check.gd` (+ `.uid`), `ring_bench.gd` (+ `.uid`). `mk_speed.py` makes it |
| `bench-before.txt`, `bench-after.txt` | `ring_bench.gd` on HEAD and with the park: the same slice hash on every line, the time a column costs |

## Where the time went (profile)

A column in the temperate band reads about 15 value-noise lookups (`_vn`): the continent's 4 octaves, the relief's 3, wetness 3, temperature 2, the surface detail 3. Each `_vn` hashed its 8 lattice corners as `_fm(_fm(_fm(seed ^ ix) ^ iy) ^ iz)`: 24 `_fm` calls, each with 2 `SimRng.imul` calls (48), 8 `_lat` calls, so **about 1,200 GDScript function calls a column**, all to answer "what is the number at this corner", which for a column 32 units from the last is nearly always a corner already hashed (a continent octave's cell is 937 columns wide; the finest detail octave's, 12).

## What changed (nothing it computes)

- `_vn` keeps the 8 corner values of the cell it last read at each seed (a slot a seed, in two packed arrays outside the sim state), and hashes again only when the cell changes. A pure memo of `_lat`: the same numbers.
- A new cell hashes 14 times, not 24: the shared prefixes (`s ^ ix`, then `^ iy`) are hashed once for the four corners that share them.
- The memo holds 4,096 seeds, then starts over.
- The arithmetic after the corners (smoothing, the three lerps) is untouched, in the same order, so the floats are the same bits.

## Proof

- `noise_check.gd`: 0 failed. 60,000 random points over 7 seeds, 4 scales, positive and negative; a 54,000-read walk along a line, again, and back, with three seeds interleaved; 5,000 seeds (past the memo's 4,096, so it restarts); 3 octaves of `_fbm` against a reference `_fbm`: every answer equals the reference corner-by-corner hash, as float64.
- `ring_bench.gd`: the slice hash (heights and biomes) and the places held are identical on all 12 rings (4 planets x 3 sizes) before and after; 111.9 us a column before, 12.0 after.
- World's 12 checks, `planet_check` and `planet_world_check` among them (the planet vectors), 0 failed; `sim/core/tools/run-all.js` all 5 stages (the golden unchanged); Rendering's 15 gates; the diff applies before or after window 3's.

## What is left, and what I did not do

- Left per column (about 12 us): the trig 1.1, the surface 6.6 (of which the ground 4.7), the detail octaves 4.0; one `_vn` is about 0.6 us. Another 20 to 30 percent is possible by reading the data dictionary into locals, which I have not done: the aim is met.
- **No coarse read.** The every-8th-column read is not used for ground the fight stands on, and nothing here changes a height or a biome. If a coarse read suits the far land past the carry zone I will propose it separately.
- A worker thread is still a later option: the read is pure, and its inputs are the planet and the ring.
