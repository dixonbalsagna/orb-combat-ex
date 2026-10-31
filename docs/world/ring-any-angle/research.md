# The fight at any angle: routes compared, and a recommendation

Research & Prototyping, 2026-10-30, for the EP on Orb's words: "push this idea to the limit, the angle the fighters fight along the surface of the planet should be ready to dynamically adjust and change determined by the fight choreographer and any other necessary game system." Orb's rule: fighters always on the same relative band.

**Play it:** open `research/ring-any-angle/proto.html` (one file, no install). Press the world buttons to compare. Reproduce the numbers: `node research/ring-any-angle/bench.mjs` (about 30 s; `results.json`, `results.txt`).

This reads the answers from World, Game Design, Netcode and Performance in this folder. **Rendering, Camera, Encounter and Simulation had not answered when this was written**, so what the route asks of them is marked as an assumption (section 7).

## 1. The answer

**Recommend the ribbon: the fight's line becomes a curve the choreographer steers, laid just past the edge of what the camera can see, over a world whose marks are kept in planet coordinates.**

- **Any angle, any tick, nothing refused.** 236 asks in 2 minutes were all accepted, and none rewrote a column the camera could see.
- **It needs no swap.** Performance's 96 to 116 ms render rebuild, the 1.3 to 13 s read lead and World's calm test (true on 57.7% of ticks) are all things a swap needs, so they go.
- **The sim barely notices.** `x` still wraps, on the same 4,800 columns, so 1,335 wrap sites in 205 files stay as they are.
- **It holds "no walls".** A fight that isn't steered closes its lap exactly (0 units off). A steered one arrives somewhere new, and can be aimed at a place on demand (42 units off).

**The one honest limit.** A bend can't reach the pair until they fly to it, because nothing inside the camera's view ever changes. A 90° ask on a launch's first tick has fully turned after 14,100 units of flight: 2.3 s at launch speed, 1.4 s flat out. **Any route that shows the new angle sooner must rewrite what the camera shows.** That is route E, or a hard cut (stage 7).

**So there is one question for Orb,** best answered by trying D3 and E in the prototype: when the angle changes, do you picture the fight *heading somewhere new* (the ribbon), or the world *visibly swinging round the fighters* (the turntable)? Game Design asks the same thing. The first is affordable now. The second costs an order of magnitude more and needs a different renderer.

## 2. What was compared

One seeded fight (3 seeds, 2 minutes each: brawls, sends, flights, craters) runs on each world, on the planet's real noise (planet 7, planet-gen's bit-exact port). Three steering rates: `calm` (today's rule), `any` (10 to 60° every 2 to 5 s) and `hard` (60° every half second).

| Key | Architecture |
| :--- | :--- |
| **A-today** | Today's calm turn: read the whole next ring, swap at a calm tick, caps on (K 12) |
| **A-fast** | The same with no caps and nine times the read rate (K 108, the ring-speed park's margin) |
| **B / B2** | Lazy plane: a new plane through the pair at any tick; a patch round the pair keeps its columns; the rest of the ring comes in lazily. B2 adds the planet store |
| **C** | Ribbon: a steered curve laid at the frontier, on a wrapped conveyor of columns |
| **D** | C with the planet store (marks in planet coordinates) |
| **D2** | D with a coarse far ring (right-country ground past the frontier for far readers) |
| **D3** | D2 with the frontier at a sim-side bound on the camera, and Netcode's 20-tick lead. **The recommendation** |
| **E / E2** | A 2D field round the pair (nodes keyed to the planet, 128 or 512 units), the strip re-laid from it, a turntable at up to 30°/s |

Killed without a prototype:

- **A fan of rings read ahead.** World: 1.6 to 3.1 s of CPU, and for one pivot only; when the pair move it is the wrong fan.
- **A GPU crossfade between two resident rings.** Performance's only rebuild-free step, but Orb has rejected dissolves and fades (ADR 0010).
- **A path per fighter.** It breaks Orb's rule: they would no longer share a band.
- **Forcing a steered path to close.** It costs the steering freedom and gains nothing (section 4).
- **Far-land drift as the whole answer.** Render-only, cheap, and it is stage 1, but it changes nothing about where the fight goes.

## 3. The numbers

Means over 3 seeds. **Reads** are noise reads a tick, counted, so they don't depend on machine load. "ms" converts them at World's measured 54 µs a gen 2 column (native) and Performance's 0.8 ms at the laptop's x4. Performance's limits: about 0.2 ms a tick for reads, no frame over 50 ms, an 8 ms spike allowance.

**Steering every 2 to 5 s (`any`):**

| World | Reads: mean / p99 / max | Native ms: p99 | Laptop ms: p99 | Asks taken | Turn reaches the pair (ticks, p50 / p90) | Pop ticks in view | Largest pop (u) | Columns changed while away |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| A-today | 0 / 0 / 0 | 0 | 0 | **0 of 34** | never | 0 | 0 | 0 |
| A-fast | 1.3 / 108 / 108 | 5.8 | **86** | **2 of 34** | 44 / 44 | 1 | 502 | 0 |
| B2 | 2.3 / 6 / 6 | 0.32 | 4.8 | 34 of 34 | 303 / 1,248 | **0** | 0 | **3,773** |
| D (ribbon + store) | 0.9 / 6 / 6 | 0.32 | 4.8 | 34 of 34 | 369 / 1,425 | **0** | 0 | **0** |
| **D3** | **1.5 / 6 / 7** | **0.32** | **4.8** | **34 of 34** | **318 / 1,450** | **0** | **0** | **0** |
| E | 43 / 337 / 449 | **18** | **270** | 34 of 34 | **32 / 55** | **2,347** | 356 | 4,505 |
| E2 | 2.8 / 58 / 97 | 3.1 | **46** | 34 of 34 | **32 / 55** | **2,347** | 115 | 4,504 |

**Reading the table:**

- **The ribbon's cost is its flight, not its steering.** It reads about 5.3 columns a tick flat out and nothing at rest. At 60° every half second (`hard`) D3's reads stay at a mean of 1.6 and a max of 7.
- **At flat-out flight the ribbon is over Performance's 0.2 ms (0.32 ms).** A read budget of 6 a tick holds with nothing forced; 4 starts forcing reads at the view's edge. Reading every second column would halve it, if World's gen 2 allows that (section 6, stage 0).
- **The long latencies aren't delay in the sim.** A turn only reaches the pair when they travel, and these fights spend much of their time brawling. In flight, see section 5.
- **"Changed while away" is the lazy plane's real weakness.** Fly off, come back, and the ground you saw is different, because the plane rotated rigidly about a later point. In D3 it is 0 at normal rates and 403 columns at the absurd `hard` rate, where the pair overrun the laid range and reverse.

**What stays of destruction.** Craters are the stand-in; what happens to other marks is section 4.

| World | Marks made (`any`) | Still on the strip | Found by a later pass | Crossing the crater at a new bearing shows it |
| :--- | ---: | ---: | ---: | :--- |
| A-today | 23 | 22 | 22 | yes, but only because it can't turn in flight |
| B | 23 | 2 | **2** | **no: depth 0** |
| B2 | 23 | 2 | **23** | **yes: -300** |
| C | 23 | 10 | **10** | **no: depth 0** |
| D, D2, D3 | 23 | 7 to 10 | **23** | **yes: -297 to -299** |
| E, E2 | 23 | 2 | **23** | yes: -300 |

The store is what makes the world remember, whichever geometry sits above it. It is cheap too: a log of about 48 bytes a mark, where a snapshot holds only its length and a rollback truncates it.

**Determinism and rollback (all ten worlds):** 90 rollbacks of 20 ticks each on the `any` fight, **0 mismatches**, and two runs of the same fight hash the same. Re-reads on a rollback: 0, because the read cache sits outside the state. This proves the logic in JS, not GDScript.

**The far ring (D2, D3).** One read every 16 columns, past each frontier, sharing the same read budget. It refills 15 to 58 ticks after a bend, and is 1.2 to 7.5 units RMS off the real ground on the same line.

**Relief against grid spacing (gen 1 noise, along one great circle), RMS and max error against the true column:** 64 u 0.5 / 11, 128 u 0.7 / 17, 256 u 1.6 / 27, 512 u 4.7 / 60, 1,024 u 16 / 184. **Gen 2 has rivers and shores that may do worse; World should measure it** before anyone reads sparsely.

## 4. Each route against the EP's questions

| | A: faster plane swaps | B2: lazy plane + store | **D3: ribbon + store** | E: 2D field or sim |
| :--- | :--- | :--- | :--- | :--- |
| **No walls, loop the planet** | Yes, always a closed plane | Yes, still a closed plane. Every plane through the pair shares its antipode, so a turn half way round still comes home (295 u off) | Yes. `x` wraps on a conveyor, so nothing ends. Unsteered: closes exactly (0 u). Steered: arrives elsewhere (17,569 u off after 90° at half way) | No strip to wrap; every wrap site goes. The planet itself is the loop |
| **A steered path that doesn't close** | n/a | n/a | **Fine: see below** | Fine |
| **Destruction across a change** | The carry zone (12,000 u); outside it the thin marks are lost | Everything, by the store | Everything, by the store, at any new bearing | Everything, by the store |
| **Determinism, rollback** | Works today. A flip can land a 122 to 274 ms read on a rollback frame | Same logic as D3; each plane needs the lead | State is two frontier frames and the remaining bends: no history (Netcode's rule). The lead makes a bend final before any column is laid from it | Clean, and a tiny snapshot, but every frame's view is derived work |
| **Reads, GDScript terms** | One ring: 130 to 285 ms of CPU a change | Up to 0.32 ms a tick | Up to 0.32 ms a tick while flying, nothing at rest | 18 to 24 ms native peak at 128 u, 3 to 5 ms at 512 u |
| **Memory** | About 141 KB snapshot (Netcode), plus a ring being read | About +24 KB a snapshot by my formula (one ground block, read flags) | About +13 KB a snapshot (peak 4 dirty chunks of 64 columns), or Netcode's +19 KB without chunks. Store under 20 KB at the 400-record cap. Frames: 230 KB at full size, about 14 KB if sparse | 4.8 MB of nodes at 128 u (more in a GDScript Dictionary), 0.5 MB at 512 u |
| **Migration from today** | Smallest: data caps, a gate fix, the rebuild cut | Stage 4's streaming, plus a plane rule | Stage 4's streaming, plus a steering rule | Largest: 1,335 wrap sites, 469 ground reads, 170 `S.base` reads, buildings, water, director, camera. A new game's world layer |
| **What a player sees** | A hard cut, the surroundings changed; about 100 ms of hitch, 3 to 6 frames at 60 Hz | Nothing near changes; ground far behind is different on return | Nothing in view ever changes. The fight runs on into new country, the far land turns, and what lies ahead is what the choreographer chose | The whole view swings round the pair, like a camera orbit |

**How a steered path holds "no walls".**

1. **The arithmetic never ends.** `x` wraps at `W` as it does today. The strip is a conveyor: the ground ahead is laid, and the slots it fills are those of ground a lap behind. The seam where the two ends meet is half a ring from the pair, and fighters are never more than that apart, so it can't be seen or crossed. In every run the frontier stayed at least 128 columns outside the view.
2. **Unsteered, it is a great circle.** Every straight stretch is a piece of a true lap, and it closes to 0 units.
3. **Steered, you come back somewhere else, and that is the point.** Game Design accepts this: "a player's map becomes a planet rather than a loop". Fly on forever and you cross your own path, at another bearing, and the craters are still there.
4. **Closing is available on demand.** The choreographer can aim the line at a place: 42 units off after 218 ticks in the test, 1,100 columns away. So "bring the fight home" is a steering decision, not a property the geometry must keep.
5. **Fly back and you retrace.** Within the laid range (up to 3,600 columns) the ground is exactly what you saw. Past it, the line is re-laid: the honest loss of a conveyor, seen only after flying most of a lap and reversing. Its marks still come back through the store.

## 5. What it does at a launch (Game Design's must-have)

Game Design finds that what play needs is **a large step at any angle at a launch's first tick**, 2 to 5 times a match, with no every-tick change. The ribbon does this with no read ahead, no calm test and no hitch: the ask costs nothing until the frontier reaches it.

Flight until the line has turned, with the ask on the launch's first tick (units flown at half the angle / at the full angle):

| Ask | D3 (frontier at the camera) | D2 (frontier at the widest view) | E (turntable, in view) |
| :--- | ---: | ---: | ---: |
| 45° | 11,400 / 12,300 | 15,800 / 16,600 | 4,600 / 8,600 |
| 90° | 12,300 / 14,100 | 16,700 / 18,400 | 9,100 / 17,600 |
| 180° | 14,200 / past the test | 18,600 / past the test | 18,600 / past the test |

**The conflict to settle with Game Design.** Its launch range is about 6,000 units, which is inside the camera's view, so **a 6,000-unit launch lands on the old line**. Three ways out:

1. **Destination launches fly further.** The launch rule already allows a sixth of the loop (25,600). This is what I recommend first: no new machinery, and it fits "it's flying somewhere new". The table below is what it costs.
2. **A tighter frontier while the camera is tight.** It can't go below the camera's view, so it only helps so far.
3. **A cut at the whip (stage 7).** Camera already whips at a launch. Under a hard cut with a cinematography reason, the columns in view could be rewritten: about a seventh of a ring. That needs Camera's and Orb's word, and it is the only route to the new angle inside 6,000 units without E.

Units of flight to reach a place, by its distance and bearing from the pair at the launch. This is arithmetic, not a run: straight to where the bend can start (8,930 units: the frontier at rest plus the lead), the tightest arc (radius 2,400), then straight to the place. **Bold** is over the launch rule's 25,600.

| Place at | 15° | 30° | 45° | 60° | 90° |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 6,000 u | 21,300 | 20,700 | 21,200 | 22,400 | 25,500 |
| 12,000 u | 13,400 | 16,400 | 19,500 | 22,400 | **27,800** |
| 20,000 u | 20,600 | 22,300 | 24,800 | **27,700** | **33,700** |
| 30,000 u | **30,500** | **31,800** | **33,900** | **36,600** | **42,600** |

So a place about 12,000 to 20,000 units off within about 45° is the ribbon's natural destination, close to a straight flight (at launch speed, 2.2 to 4 s). A place inside the camera's view at launch needs a loop back of 20,000 to 25,500 units, about 3.5 to 4 s, which may be spectacular or may be too long: **Game Design's call.** A place behind the pair is the same geometry on the other frontier: both ends are free.

**Game Design's hard tests, against D3:**

| Test | Result |
| :--- | :--- |
| 1. The rival stays on the same side of the screen | Yes: `x` order is untouched |
| 2. Everything in reach unchanged | Yes: no column in view is ever rewritten (0 pop ticks in every fight) |
| 3. Attacks close as before | Yes: the gap is along the strip, untouched |
| 4. A step has a visible cause | Its cause is the launch; the bend itself is never seen |
| 5. No marker, dissolve or fade, instant change justified | Yes: there is no instant change at all |
| 6. The world remembers | Marks: yes. **Buildings: not until places are laid by plan** (stage 3) |

Its geometry also checks out: a turn about the midpoint moves each fighter `s sin(θ/2)` for a gap `s`, which is World's chord `2 r sin(θ/2)` at `r = s/2`.

## 6. The route

Each stage is useful with nothing after it, and proves what the next one needs. Each ships behind a switch, with the golden byte-identical while it is off. Sizes are my rough guess, for the owners to correct.

| # | Stage | Useful alone because | Proves for the next | Owners | Size |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **0** | **Answers, no game code.** Orb plays the prototype and answers section 1's question. Performance re-measures the swap on a quiet machine. World measures sparse reads on gen 2. Game Design rules section 5's launch conflict | Settles the direction before anyone builds | Whether E is wanted at all, and the real read budget | Orb, Performance, World, Game Design | Days |
| **1** | **The far land reads a frame.** It takes a planet frame (point, heading), through `WorldFarMap`, so it turns when told to. World's window 2 | Today's turns and a curving flight look right. It may be all Orb pictured | The far land is independent of the strip | Rendering, World | 1 window |
| **2** | **A planet store for marks.** Beams, slides and heaps become records, in an append-only log. The swap re-applies them | The calm turn and the campaign stop losing marks. Game Design's test 6, for ground | Rollback by truncation; re-applying marks to any line | World, Simulation | 1 to 2 windows |
| **3** | **Places by plan** (planet window 3). A city generated from its own plan, with stable building ids | The same city on any chord; wear list exact; the turn stops cutting cities | Identity that survives any bearing | World, Art | Large; runs in parallel |
| **4** | **The streamed strip, unsteered.** Columns laid at the frontiers; far ring; `S.base` in shared chunks; lanes, index, props and ground field made incremental. No bends, so the same great circle: **the laid columns must equal today's ring to the bit** | No whole-ring read at match start. Performance's two largest swap pieces (props 30 to 44 ms, force refresh 28 ms) get patched, so even A's swap gets cheaper | The hard engineering, with today's ground as the oracle. An audit of every far reader | Simulation, World, Rendering, Encounter | The big one: several windows |
| **5** | **Bends.** The ask, the frontier at the camera's bound, the 20-tick lead, the turn radius. Game Design's launch-first rule and a score that falls with recency | **Orb's ask.** Any angle, any tick | Whether it reads as force, at the look gate | Encounter, World, Netcode (digest, `PROTO` 4, the lead in the setup, a forced-flip test), Camera | 2 windows |
| **6** | **Arrival.** The choreographer aims at places: the villain hunts, the hero leads away, home ground. Every step arrives at something | Fights go somewhere on purpose, which is QA's finding (most long trips unexamined) | QA's bands; a Legal read, since it takes fights toward people on purpose | Encounter, Combat, Legal, QA | 1 to 2 windows |
| **7** | **Optional, only if Orb asks.** A cut at the whip that rewrites the view's columns; a turntable for set pieces | The new angle inside 6,000 units, or a visible orbit | | Camera, Rendering | Unknown |

**The fallback.** If bends fail the look gate at stage 5, stage 4's streaming also carries B2 (the lazy plane) with one rule changed. Nothing is wasted.

**Why this order.** Stage 4 is the only risky one, and it has an oracle: today's ring. It can be wrong in a way a test catches, before any steering makes the ground unpredictable. Stages 1 and 2 are cheap and pay immediately, whatever Orb decides.

## 7. Risks and what this doesn't know

**Assumptions the other directors must confirm:**

- **Rendering (the largest risk).** Performance found that any dirty column costs a whole 403 KB texture set on dig frames, and 1.2 ms mean on those frames. The ribbon dirties about 5 columns on *every* flying frame, against a budget of 0.5 to 1 ms. It needs a ring-buffer ground texture with partial or chunked updates, and props and buildings added incrementally. I assume that can be done; **nothing here proves it.**
- **Far readers (Encounter, Simulation).** 469 ground reads and 170 `S.base` reads can look anywhere. Past the frontier they get the far ring: the right country at 512-unit resolution, 1 to 8 units RMS, and later steering can change it. Whatever plans a long way ahead (launch planner, lure, location tables) must accept that. Stage 4 audits every one.
- **The camera's bound (Camera).** D3 needs a sim-side bound on what the camera can show, as a function of the pair's gap; the sim must not read the camera (Netcode). My bound is a placeholder: half-width of 3,600 units or 0.7 × gap + 3,000.
- **`S.base` written in place (Simulation).** Today's rule is that it is shared and only replaced whole; an in-place write is a desync. Chunks with copy-on-write should keep the rule, at about +13 KB a snapshot. Not built.
- **Places on a curve (World).** Today a place is laid from its chord. Until stage 3, the rule would be: no bend starts inside a settlement's chord, and a place laid on one line is forgotten if the line later crosses it elsewhere.

**What the prototype leaves out:**

- It is JS, not GDScript. Reads are counted, so they convert well. The non-noise work (frames, store, re-lay) is only estimated: it is too small to see in the ribbon's JS timings, and E's re-lay comes to about 1.7 to 3 ms a tick if the 16× factor holds. **That factor was measured on noise code, not arrays.**
- The ground is gen 1 noise, with no water, lanes, props, biomes table or real settlements. Buildings are drawn from planet points only to show the idea, with no collision. Fighters are bars.
- Fights are scripted, not the director's. Depth rows and the band's `z` aren't modelled.
- **Timings:** the machine was loaded, so timings are not reported as absolutes. The counts are deterministic.
- **Not run in a real browser or with a real pad:** a stub DOM ran every world, watched and played (`smoke.cjs`), and the pictures come from the same drawing code.
- **No network run.** Rollback was exercised on a keep, run, restore and re-run loop, not over a connection.

**Bugs the prototype's checks found in itself, all fixed,** in case the port hits the same ones. The far ring's two ends share storage and must meet in the middle; a limit that retreats must take its read count back with it; and the conveyor must keep a gap of far ground each side, or the slot just past a frontier holds ground from nearly a lap behind.

## 8. Pictures

`docs/world/ring-any-angle/img/`: a 90° ask at a launch, four moments each, on `launch-90-D3.png` (the ground stays, the line bends on the globe), `launch-90-E.png` (it all swings, reads far over budget) and `launch-90-A-fast.png` (nothing happens in flight).
