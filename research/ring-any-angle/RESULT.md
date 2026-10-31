# Result: the fight at any angle

**Status: UNFINISHED (paused for quiet time, 2026-10-30).** The paper still waits on four directors' answers.

**Question.** How can the angle the fighters fight along the planet change at any moment, chosen by the choreographer? (Orb, 2026-10-30.)

**Recommendation.** The ribbon (D3): the fight's line is a curve steered at a frontier just past what the camera can see, on the same wrapped columns, over marks kept in planet coordinates. Any angle at any tick, with no swap, no pops and a peak of 6 to 7 noise reads a tick. The paper, with the route in stages: [docs/world/ring-any-angle/research.md](../../docs/world/ring-any-angle/research.md).

**The limit.** A bend reaches the pair only when they fly to it: 14,100 units for a 90° ask at a launch. Showing it sooner means rewriting what the camera shows, which is route E (43 reads a tick on average, 449 at peak, the view changing on every tick of the turn) or a hard cut. Orb decides which they picture.

**Run it.**

```
open research/ring-any-angle/proto.html          # the playable page, one file, from file://
node research/ring-any-angle/bench.mjs           # the comparison, about 30 s: results.json, results.txt
node research/ring-any-angle/build.mjs           # rebuilds proto.html
node research/ring-any-angle/smoke.cjs           # the page under a stub DOM
node research/ring-any-angle/sheets.mjs          # the pictures, into docs/world/ring-any-angle/img
```

**Files.** `sim.js` (the worlds, the fight, the metrics; no DOM), `draw.js`, `page.html`, and the tools above.

**Limits of the evidence.** JS, on gen 1 noise, with scripted fights and no water, props, real settlements or depth. Read counts convert well; other costs are estimates. Never run in a real browser or with a real pad. Throwaway spike code: nothing outside `research/` imports it.
