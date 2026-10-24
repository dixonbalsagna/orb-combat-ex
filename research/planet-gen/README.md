# Planet generation prototypes

Research & Prototyping, 2026-10-23. Fast JS prototypes that compare planet-generation and biome techniques as pictures, for World. The study is [docs/research/planet-gen.md](../../docs/research/planet-gen.md), and its tables are [planet-gen-tables.md](../../docs/research/planet-gen-tables.md). Throwaway spike code: nothing outside `research/` imports it.

## Run it (Node 18 or later, no dependencies)

```
node research/planet-gen/check-base.mjs         # the toolkit reads WorldPlanet's bits: 128 of 128 golden points
node research/planet-gen/check-pure.mjs         # every approach reads the same cold, warm and fresh (300 points each)
node research/planet-gen/check-lean.mjs         # the climate's lean path gives the full path's height and biome
node research/planet-gen/bench-ring.mjs A       # per-column cost against today (median of 7 alternating pairs) and ring fingerprints
node research/planet-gen/bench-js.mjs           # today's surface in JS (the checksums match gdbench/surf_bench.gd)
node research/planet-gen/run.mjs base           # then A, B, C, Cb: pictures and stats for the six seeds (about 15 s each)
node research/planet-gen/sheets.mjs             # comparison sheets, approach sheets, ring stacks, the legend
node research/planet-gen/tables.mjs > docs/research/planet-gen-tables.md
node research/planet-gen/costs.mjs 7            # approach C's grid cost against its size
```

## Files

| Path | What |
| :--- | :--- |
| `lib/det.mjs` | The deterministic toolkit: WorldPlanet's hash (`_fm`), value noise and fbm (the same expressions), keyed draws, the series atan, sphere helpers. It uses `sim/core/detmath.js` for sin, cos and pow |
| `gen/base.mjs` | Today's planet, ported line for line (`ground`, `_plainBiome`, `surfAt` with the ice). It is bit-identical (`check-base.mjs`) |
| `gen/climate.mjs` | **A.** The temperature and moisture table, with winds, a rain shadow and a moisture lattice |
| `gen/plates.mjs` | **B.** Plate-lite: a warped Voronoi of plates, landforms decided by relative motion, hotspot chains |
| `gen/erosion.mjs` | **C.** Erosion-lite on a cube-sphere grid: priority flood, routing, flow, implicit stream power, talus |
| `gen/poles.mjs` | The polar design as a noisy bias on the ground, in place of today's straight-edged blend; the far north always ends in sea |
| `gen/floes.mjs` | Today's floes, leads and bergs on the climate's sea ice (round 2) |
| `gen/index.mjs` | The approaches as `init(seed)` and `sample(x, y, z)` |
| `lib/render.mjs`, `lib/img.mjs`, `lib/biomes.mjs` | Maps, globes, the ring strip, the picker, the stats, the PNG writer and 5x7 font, the biome palette |
| `run.mjs`, `sheets.mjs`, `tables.mjs`, `costs.mjs` | The runs |
| `img/` | Per approach (`base`, `A`, `B`, `C`, `Cb`) and per seed: `-map.png` (equirect), `-globe.png` (centred on the fight ring's touch-down) and `-ring.png` (the 4,800 columns side on). Also `compare-s<seed>.png`, `sheet-<approach>.png`, `rings-s<seed>.png` and `legend.png` |
| `stats/` | Each approach's numbers, per seed: shares, the fight read, costs and its parameters |

The GDScript side of the speed ratio is a scratch script run once, from the Research session's scratchpad. It ran `WorldPlanet.surfAt` over the same 4,800 points as `bench-js.mjs`, best of 3. Results: 10.4 µs a column for seed 7 and 11.4 for seed 11, with checksums 2450021.215 and 25877850.853, the same as JS.
