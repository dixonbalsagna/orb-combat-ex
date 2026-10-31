# Result: the fight at any angle

**Question.** How can the angle the fighters fight along the planet change at any moment, chosen by the choreographer? (Orb, 2026-10-30.) Orb then tried the worlds and picked the turntable: the world visibly swings round the fighters (2026-10-31).

**Recommendation.** A narrow sim strip read through the frame, and a resident planet ground the renderer turns with one uniform: fork (b). The field defines the ground, a new, smoother generation behind a switch: one canonical spacing as a data value, baked before tick 0, with zero noise reads in play and coast and ice-edge records laid on it. A swing and a flight then cost no noise reads, and the swing's rate costs nothing in reads. The ribbon (D3) stays as the fallback. The paper, with the route in stages: [docs/world/ring-any-angle/research.md](../../docs/world/ring-any-angle/research.md).

**The limit.** No live 2D field keeps up flat out at the laptop's 1.5 reads a tick, so the reads move to the load: at 512 units, 1.3 s native, 4.4 s on the web, 18 to 27 s on the laptop by conversion; four times that at 256. Drawing it measures +0.1 to 0.5 ms a frame on a current iGPU, not on ADR 0011's old laptop, and that is the go or no-go.

**Run it.**

```
open research/ring-any-angle/proto-v2.html       # the turntable, true 3D, one file, from file://
node research/ring-any-angle/cuts.mjs            # the cost cuts: cuts.json, cuts.txt
node research/ring-any-angle/build2.mjs          # rebuilds proto-v2.html from page2.html
open research/ring-any-angle/proto.html          # the ten-world comparison of 2026-10-30
node research/ring-any-angle/bench.mjs           # its numbers: results.json, results.txt
node research/ring-any-angle/build.mjs           # rebuilds proto.html
node research/ring-any-angle/smoke.cjs           # proto.html under a stub DOM
node research/ring-any-angle/sheets.mjs          # the pictures, into docs/world/ring-any-angle/img
```

**Files.** v2: `page2.html`, `build2.mjs`, `cuts.mjs`, `gen2-p7-340.bin` and `gen2-p7-170.bin` (planet 7's gen 2 heights and biomes, read by `gen2_dump.gd.txt` in a scratch copy). The 2026-10-30 worlds: `sim.js` (the worlds, the fight, the metrics; no DOM), `draw.js`, `page.html` and the tools above.

**Limits of the evidence.** JS, on gen 1 ground except v2's real gen 2 settings, with scripted fights and no water, props, real settlements or depth. Read counts convert well; milliseconds are counts times other directors' figures. v2 ran under scripted input with captures on the RTX: no human has played it and no real pad has driven it. Its map build is gen 1 in JS, about 100x cheaper than gen 2 in Godot. Throwaway spike code: nothing outside `research/` imports it.
