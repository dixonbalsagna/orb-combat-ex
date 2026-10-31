# Research and prototyping

Owner: Research & Prototyping director. Spikes are fast, throwaway experiments that answer one risky question each. Each spike folder ends with a one-page `RESULT.md` that gives a recommendation and its evidence.

## Rules for spike code
- Spike code is throwaway. Nothing outside `research/` imports it, and none of it is promoted to production without review (charter anti-goal). If an idea is worth keeping, the owning director re-implements it in their own paths.
- Spikes follow the project rules: deterministic sim (fixed step, seeded RNG), sim separate from rendering, original visuals, and no third-party code or assets without a licence-register row.
- Build outputs are gitignored (see each spike's `.gitignore`).

## Spikes

| Spike | Question | Status |
|---|---|---|
| [engine-spike](engine-spike/) | Godot 4.7.2 or the web stack for the real build (ADR 0001)? | Done 2026-09-29: [RESULT.md](engine-spike/RESULT.md) |
| [band-proto](band-proto/) | Option B: does a fighting ground with real depth (true collisions) feel and read better than the flat plane? | Built 2026-10-01: playable prototype and [README](band-proto/README.md); waiting for Orb to play it |
| [co-op brawler study](../docs/research/co-op-brawler.md) | How could today's versus systems carry two players against AI opponents, as part of a bigger game? | Part 1 committed; [part 2](../docs/research/co-op-brawler-part-2.md) written 2026-10-11 after Orb's answers (recommends "pair and satellite"; study only, nothing built) |
| [world catastrophe](../docs/research/world-catastrophe.md) | Can the engine and budgets do Orb's world-catastrophe boss fight (magma through the crust, a mushroom cloud darkening the sky, an exosphere fight, mass collapse)? | Written 2026-10-16: feasible for all four; prototypes and stills in docs/research/world-catastrophe/; flash clips pass; timings invalid (machine saturated) |
| [readable speed](../docs/research/readable-speed.md) | How can high-speed combat stay readable with nothing on, over or between the fighters? | Written 2026-10-18: 12 recommendations by owner; the beam struggle carried by the beams (Clash.mid) |
| [cinematic storytelling](../docs/research/cinematic-storytelling.md) | How can a directed, emergent camera tell the fight's story and stay readable at high speed, working with the choreographer? | Written 2026-10-19: film, anime, game-camera and perception research; a four-layer camera director (intent, pacing, editing, placement), a shot vocabulary, a variety rule and 19 testable recommendations by owner |
| [cuts and eases](../docs/research/cuts-and-eases.md) | When may the camera change instantly, and how long should each kind of move ease? | Written 2026-10-23: ease, cut or whip by the size of the change; five reasons for a hard cut plus conditions; ease durations at 60 fps; launches, supers and impacts in games |
| [planet-gen](planet-gen/) | Which planet-generation and biome techniques give the most believable, varied planets, and what they cost? | Built 2026-10-23: JS prototypes of a climate table (A), plate-lite (B) and erosion-lite (C) against today's planet, 6 seeds as maps, globes and fight rings; [study](../docs/research/planet-gen.md): port A first. Round 2 the same day: B tuned, A at 1.8 times today per column, C's rivers curved, floes on the north pack |
| [ring-any-angle](ring-any-angle/) | How can the angle of the fight along the planet change at any moment, and how does that scale from a performance mode to maximum graphics? | Orb picked the turntable, 2026-10-31. `proto-v2.html` is a true 3D planet of planet-keyed tiles swinging round two bars on real gen 2 ground, with five quality levels. Recommends one sim ground at 128 units read on demand, with the view free at each level. No level has run in Godot but the middle. Papers: `docs/world/ring-any-angle/research.md`, `quality-range.md` |
| [info-hiding](info-hiding/) | How can hiding work when both players share one screen: split-screen, fog of war or picture-in-picture? | **Parked** 2026-09-29 (lean-team directive, ADR 0005). See "Where info-hiding stopped" below. |

### Where info-hiding stopped
- **Plan.** The spike ran as workflow `wf_0016e7a5-2be`, which a usage limit cut short before any agent finished. The plan was:
  - a shared testbed in `info-hiding/core/`;
  - three prototypes: `split/`, `fog/` (variants still, creep and sense) and `pip/` (variants local, dimlocal and radar);
  - a seeded leak benchmark comparing an honest hunter with one that peeks at the hider's part of the screen, using a terrain-matching localiser to find a hider from a glimpse of their surroundings;
  - a judge panel.
- **On disk.** Partial, untested core modules only: `core/world.mjs`, `sim.mjs`, `camera.mjs`, `localize.mjs`. None of the three presentation modes was built.
- **To restart.** Resume the workflow from its journal once the director roster allows. Before resuming, update the scoring to the EP's amendment, which uses Camera's five criteria: fairness, readability, screen cost, netcode fit under rollback (both clients hold full state), and accessibility. Fold in Camera's hiding-camera-options.md and UI & UX's HUD notes if they exist by then.
- **Early observations** (not yet evidence):
  - Today's prototype leaks the hider completely: the hidden fighter is drawn at 22% opacity, and the minimap shows a "?" at its exact position.
  - Online after launch (Orb) removes the shared-screen problem for online play, since each client draws only its own view. The open question is local couch play.

## Open unknowns
This list should shrink every phase. Each item names the spike or owner expected to close it.

| # | Unknown | Closed by | Status |
|---|---|---|---|
| U1 | Engine: Godot 4 or the web stack | engine-spike, then ADR 0001 (Orb confirms) | Answered: Godot 4.7 with GDScript (engine-spike/RESULT.md); waiting for ADR 0001 |
| U2 | Can the worst-case effects scene hold 60 fps, and on what hardware? | engine-spike (frame times, including an integrated-GPU stand-in for minimum spec) | Answered for the spike's scene: at most 3.8 ms p95 on a 2-CU iGPU in every stack. Open for real old laptops and phones |
| U3 | Can a camera frame both fighters at any separation with no pop at the seam? | engine-spike (reference camera plus seam tests) | Answered: yes, except for a ≈0.5 s pan when the fighters pass half the planet apart (design call for Camera) |
| U4 | Can the sim be bit-identical across runtimes (JS, GDScript, C#, desktop, web)? | engine-spike (golden hashes) | Answered: yes, under the portability contract (JS, GDScript on desktop and wasm, .NET). Not checked on ARM or Apple |
| U5 | Can Godot C# export to the web in 4.7? | engine-spike/notes/csharp.md | Answered: no (tested; the .NET export templates contain no web template) |
| U6 | How does hiding work on one screen? | info-hiding | Open |
| U7 | Deformation cost at planet scale (heightfield updates, collision) | engine-spike (upload cost); deeper work later | Partly answered: height upload costs about 0.02 ms per tick. Collision and queries are still open |
| U8 | Rollback with a procedural director: re-simulation cost and hidden-information leaks | Later spike (P2), with Netcode | Not started. Projected GDScript re-simulation cost: 1 to 3 ms a frame on an old laptop (engine-spike RESULT) |
| U11 | Real GDScript tick cost for the full sim (4 fighters, minions, director) | Simulation's GDScript port, measured on a real old laptop | New |
| U9 | Presentation: 2D sprites, 2.5D or full 3D | Orb, with Art; engine-spike covers what each choice changes | Answered by Orb: 2.5D side-on (docs/ep/vision.md) |
| U10 | Planet-scale rendering: zoomed-out planet view, curvature, level of detail | Later spike (P1), with Camera and Performance | Not started |
