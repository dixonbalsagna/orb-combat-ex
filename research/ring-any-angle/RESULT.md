# Result: the fight at any angle

**Question.** How can the angle the fighters fight along the planet change at any moment, chosen by the choreographer? (Orb, 2026-10-30.) Orb then tried the worlds and picked the turntable: the world visibly swings round the fighters (2026-10-31).

**Recommendation.** A narrow sim strip read through the frame, and a resident planet ground the renderer turns with one uniform: fork (b). The field defines the ground, a new, smoother generation behind a switch: one sim ground at 128 units for every player, read on demand, over a 512 bake for forecasts and the lowest view, with coast and ice-edge records on it. A level changes only what's drawn. The ribbon (D3) stays as the fallback. Papers: [research.md](../../docs/world/ring-any-angle/research.md), [quality-range.md](../../docs/world/ring-any-angle/quality-range.md).

**The limit.** The bake costs load: 1.3 s native and 1.6 to 1.9 s on the web (measured), 6 to 11 s on the laptop by arithmetic. Nothing has run in Godot at any level but the middle one, and no human has played the levels.

**Run it.**

```
open research/ring-any-angle/proto-v2.html       # the turntable, true 3D, one file, from file://
node research/ring-any-angle/cuts.mjs            # the cost cuts: cuts.json, cuts.txt
node research/ring-any-angle/build2.mjs          # rebuilds proto-v2.html from page2.html
node research/ring-any-angle/levels.mjs <bin>    # drawn against sim ground on real gen 2: levels.json, and the pack
node research/ring-any-angle/level-bench.mjs     # each level and feature on this PC's GPUs (--igpu for the Radeon)
open research/ring-any-angle/proto.html          # the ten-world comparison of 2026-10-30
node research/ring-any-angle/bench.mjs           # its numbers: results.json, results.txt
node research/ring-any-angle/build.mjs           # rebuilds proto.html
node research/ring-any-angle/smoke.cjs           # proto.html under a stub DOM
node research/ring-any-angle/sheets.mjs          # the pictures, into docs/world/ring-any-angle/img
```

**Files.** v2: `page2.html`, `build2.mjs`, `cuts.mjs`, `levels.mjs`, `level-bench.mjs`, `gen2-p7.pack` (planet 7's gen 2 heights and biomes at 64 units, read by `gen2_dump.gd.txt` in a scratch copy). The 2026-10-30 worlds: `sim.js` (the worlds, the fight, the metrics; no DOM), `draw.js`, `page.html` and the tools above.

**Limits of the evidence.** JS, on gen 1 ground except v2's real gen 2 settings, with scripted fights and no water, props, real settlements or depth. Read counts convert well; milliseconds are counts times other directors' figures. v2 ran under scripted input with captures on the RTX: no human has played it and no real pad has driven it. Its map build is gen 1 in JS, about 100x cheaper than gen 2 in Godot. Throwaway spike code: nothing outside `research/` imports it.
