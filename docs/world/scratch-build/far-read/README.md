# A cheaper far read for Rendering (World, 2026-10-22): parked, not applied

Rendering's need (window 2's slow drift, and the far land at a turn): `farColumn` costs 52 to 62 us a sample native, almost all `surfAt`; a turn's far field (300 columns x 10 depths) is 157 ms native and about 1 s on the web, and must be ready by the hard cut. Asked for: a render-only bulk read about ten times cheaper, a coarse read or a cached map, World's pick.

**Pick: the cached map (option 2), with an exact bulk read as the fallback.** Both are in `far-read.diff` (7 files; `git apply --check` ok on 278bb83c). Nothing in the sim reads either.

## What is in it

| | What | Per sample (this busy PC, native; farColumn read column by column = 1) |
| :--- | :--- | :--- |
| `WorldPlanet.farColumn` | as it was | 39 to 45 us (1) |
| `WorldPlanet.farField(P, ring, c0, ncols, stride, depths, coarseFrom)` | farColumn in bulk, depth by depth: consecutive samples share the noise's cell memo, a column's point and a depth's rotation are worked out once. **Bit for bit farColumn's heights and biomes** (checked on 3 planets x 3 ring sizes x 8 depths, z = 0 included). `coarseFrom` (default: never) makes samples past it coarse: one octave fewer in every noise, no surface detail | exact 16 to 21 us (about 2.3 times cheaper); coarse 8 to 13 us (about 4.5 times) |
| **`WorldFarMap`** (new `sim/world/farmap.gd`) | the planet's surface (no surface detail) read once at the texels of an **octahedral map** (256 x 256 by default), built a few hundred texels a frame by `step(count)` until `done`; any far field is then a bilinear height and a nearest biome. `field(ring, c0, ncols, stride, depths)` returns the same `{h, b}` block as farField | **2.2 to 3.2 us (about 13 times cheaper)**; the build is 65,000 texels, about 1 s native (15 us a texel) |

Also in the diff: `_fm`, the noise's hash, has `SimRng.imul` written out (one call, not three: **the same bits**, checked on 60,000 inputs), which made farColumn itself about twice as fast (83 to 40 us) and the ring read about 10 percent faster (15.8 to 14.3 us a column; the slice hashes are identical on all 12 rings); and `_fbm` can leave octaves out (`_octOff`, set and reset only inside `farField`'s coarse reads, 0 everywhere else, so every sim read is unchanged).

## Why the map and not the coarse read

`far_compare.png`: the far land beside a Half ring at depths -2,500, +4,000 and +9,000 units, exact (black), map (blue) and coarse (red), with each one's biome strip.
- **The map tracks the exact read**: mean height error 17 to 25 units (it has no surface detail, which is the 300-unit fine noise), at most 217 to 317 on a ridge; 0.4 to 0.9 percent of heights more than 100 units off; 0.8 to 2.2 percent of biomes different, at the edges of a biome. Over 7 rings on 3 planets (`farmap_check`): worst mean 25.3 units, worst biome share 2.2 percent. A 160 x 160 map is nearly as good (mean 19, 1.5 percent biomes), 360 x 360 a little better; 256 is the default.
- **The coarse read does not**: it shaves ridges and moves biome borders (mean 19 to 177 units off past 1,500 units, up to 1,400 in mountains; 0 to 30 percent of biomes different by depth). It is a look change at the near edge, not a hazed-far-land one, so I would not use it without Orb seeing it.
- No GIF: the map's difference from the exact read is the small blue-on-black wobble in the picture; at the haze it should not show. Rendering can see it in place by switching `field` against `farField`.

## What Rendering wires

- Build the map once a planet is known (`WorldFarMap.new(WorldPlanet.make(seed))`) and call `step(100)` or so a frame behind the notice and the intro, until `done` (65,000 texels: about 650 frames at 100 a frame, 1.5 ms native a frame; about 6 ms at x4). A turn's far field then costs about 3 us a sample: 3,000 samples is 10 ms native, which is a few frames' share at x4, not 157 ms.
- Until `done`, or for anything near the carry zone, `farField` (exact) is the fallback: 3,000 samples in about 50 ms native.
- The map is the planet's own (the same seed gives the same map): it is built once for a planet and serves every ring and every turn.

## Proof (clean export of 278bb83c plus the patch; below-normal priority)

- `farmap_check.gd`: 0 failed (7 checks: `_fm` against `SimRng.imul`; farField is farColumn bit for bit, and the coarse read inside its limit is the exact one and leaves no octave dropped; the coarse read past it; the map against the exact read over 7 rings; the octahedral decode and encode are inverses over both hemispheres; the same planet gives the same map; the lookup is continuous across the fold and the edge).
- World's other 14 checks (`noise_check`, `epoch_check`, `arena`, `ringpick`, `far`, `planet`, `planet_world`, `brunt`, `wall`, `collateral`, `interior`, `repeat`, `props`, `probe`): 0 failed. `sim/core/tools/run-all.js`: all 5 stages (the golden unchanged). Rendering's 15 gates: all passed.
- `far_bench.gd` (the numbers above; `bench.txt`), `far_dump.gd.txt` and `far_plot.py` (the picture).
