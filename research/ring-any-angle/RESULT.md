# Result: the fight at any angle

**Question.** How can the angle the fighters fight along the planet change at any moment, chosen by the choreographer? (Orb, 2026-10-30.) Orb then tried the worlds and picked the turntable: the world visibly swings round the fighters (2026-10-31).

**Recommendation.** A narrow sim strip round the pair, and a resident planet map the renderer turns with one uniform: fork (b). A swing and a flight then cost no noise reads. The ribbon (D3) stays as the fallback. The paper, with the route in stages: [docs/world/ring-any-angle/research.md](../../docs/world/ring-any-angle/research.md).

**The limit.** No live 2D field keeps up flat out except 1,024-unit nodes. So the reads move to a map built at load: about 15 s on the laptop by my conversion. The sim's re-lay is 47 to 74 columns on a turning tick, up to 2x over budget native and 5x on the web. Drawing it on the laptop's GPU is unmeasured, and that is the go or no-go.

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

**Files.** v2: `page2.html`, `build2.mjs`, `cuts.mjs`. The 2026-10-30 worlds: `sim.js` (the worlds, the fight, the metrics; no DOM), `draw.js`, `page.html` and the tools above.

**Limits of the evidence.** JS, on gen 1 ground, with scripted fights and no water, props, real settlements or depth. Read counts convert well; milliseconds are counts times other directors' figures. v2 ran under scripted input with captures on the RTX: no human has played it and no real pad has driven it. Its 120 ms map build is gen 1 in JS, about 100x cheaper than gen 2 in Godot. Throwaway spike code: nothing outside `research/` imports it.
