# The fight at any angle: the turntable route, with the ribbon as fallback

Research & Prototyping, for the EP. Revised 2026-10-31 for Orb's pick: "the turntable approach in E and E2 seems to be closest to my vision." Part 1 is the turntable and replaces the old recommendation. Part 2 is the 2026-10-30 paper on the ribbon, kept as the fallback, with its section numbers unchanged.

**Play it:** open `research/ring-any-angle/proto-v2.html` (one file, no install). **Reproduce the numbers:** `node research/ring-any-angle/cuts.mjs` (`cuts.json`, `cuts.txt`).

**How far to trust this.** No Godot ran. Reads are counted, so they don't depend on machine load. Milliseconds are counts times other people's figures: 54 µs a gen 2 read native, 130 µs web, 0.8 ms at the laptop's x4 (`performance.md`). The ground is gen 1. Nothing has been drawn on the laptop's GPU, and nobody has played v2.

# Part 1: the turntable

## T1. The answer

**A turntable fits the read budget, but only if the ground is already resident. A live 2D field does not fit.** The swing and the flight then cost no noise reads at all.

| Against the budget | E today | The route below | Verdict |
| :--- | ---: | ---: | :--- |
| Reads, flat-out flight (0.2 ms a tick is 3.7 reads native, 1.5 web) | 156 a tick | **0** once the map is whole | Fits |
| Spike (8 ms) | 348 reads at p99, 278 ms on the laptop | No read spike. A dig stays what it is today | Fits |
| Sim re-lay on a turning tick | 669 columns, 1.7 to 3.6 ms | 47 to 74 columns: 0.12 to 0.40 ms native, 0.28 to 0.96 web | **Up to 2x over native and 5x over web,** on turning ticks only. T4 says what brings it down |
| Drawing a swing | 5.5 to 12 ms a tick if re-laid (`performance.md` 5.2) | One uniform a frame on the CPU; GPU +0.2 to 1 ms, low confidence | **Unmeasured.** It's the go or no-go |
| Loading the map | None | 1 s native, about 15 s on the laptop (far map's read, my conversion); 3.5 s and 52 s with full gen 2 reads | **A new bill, in no budget today** |

**What has to give:**

1. **Sharpness in flight.** The near ground comes from a map with texels 338 units apart, plus made-up detail. Today's columns are 32 units apart.
2. **Start-up.** The laptop either waits or starts on a coarser map.
3. **Water and rivers.** A 128-unit river isn't in a 338-unit map, so water becomes planet records (`world.md` 8.1).
4. **Brawl swings, if the sim can't carry them.** Game Design's order of cuts already says brawls go first. Launches only is about 12 s a match.
5. **Work.** The largest cost isn't frame time. It's a new ground renderer and moving buildings, props, crowd and water to planet terms.

## T2. The fork, ranked

| Rank | Fork | Reads in flight | Sim on a turning tick | Work | Verdict |
| ---: | :--- | :--- | :--- | :--- | :--- |
| **1** | **(b) Narrow sim strip, resident 2D ground the renderer turns** | 0 from the map | 47 to 74 columns | New ground renderer; the sim's `x`, `W`, `sdx` and `wrap` stay | **Recommended** |
| 2 | (a) The sim's 1D strip re-laid from the field across the view, as E does | 10 to 156 a tick if live, 0 if from the map | 669 columns: 8 to 18x over native, and Netcode's rollback fails at a 200 ms ping | Same renderer, since re-laid columns alone don't look like a swing (`rendering.md`, option A) | Rejected. Cutting its re-lay turns it into (b) |
| 3 | (c) A true 2D sim, 1,335 wrap sites | The same as (b) | No strip | A new game's world layer | Rejected. It costs the most and saves no reads, and a free 2D fight wasn't asked for |

**Your hypothesis holds on cost, with one correction.** A turn does rotate something resident, and it reads nothing. Whole-disc spin at 150°/s measured **0 reads a tick at every node size** (the `spin` table). But "the sim only needs the ground near the pair" is not yet shown. The launch planner scans up to 400 columns, beams run long, and 639 ground read sites are unaudited. Those far readers must read the map directly, and Simulation's count (T7) decides how many there are.

Fork (b) also matches what the others wrote on their own: Rendering's option C, Netcode's narrow strip with coarse far ground, and World's section 9.4.

## T3. The cost cuts, benched

Reads a tick, mean / p99 / max. The counting model reproduces `sim.js`'s own runs within 3%: E 44 / 348 / 438 against 43 / 337 / 449, and E2 2.9 / 59 / 95 against 2.8 / 58 / 97. `any` is 3 seeds of 2 minutes. Flat out is a 30 s first crossing at 10,200 u/s with a 60° swing every 4 s, because a longer run revisits ground and flatters every row.

| Field round the pair | Nodes at load | Fights (`any`) | Laptop p99, ms | Flat out | Laptop p99, ms | Flat-out mean against 3.7 native |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **E:** 128 u to 12,000 | 24,015 | 44 / 348 / 438 | **278** | 156 / 354 / 391 | 283 | 42x over |
| **E2:** 512 u to 12,000 | 1,597 | 2.9 / 59 / 95 | **47** | 10.1 / 65 / 88 | 52 | 2.7x over |
| Rings: 128 to 1,500, 256 to 4,000, 512 to 12,000 | 2,408 | 13 / 126 / 177 | 101 | 51 / 133 / 149 | 106 | 14x over |
| Rings (World's): 128 to 3,000, 512 to 12,000 | 3,015 | 17 / 133 / 188 | 106 | 67 / 147 / 160 | 118 | 18x over |
| 512 to 6,000, 1,024 to 12,000 | 728 | 2.2 / 48 / 80 | 38 | 7.9 / 60 / 70 | 48 | 2.1x over |
| **1,024 only, to 12,000** | 428 | 0.8 / 26 / 55 | 21 | **2.7 / 33 / 52** | 26 | **Fits native; 1.8x over web** |
| E2, half disc, r 8,300 (Camera's ask) | 430 | 1.7 / 25 / 48 | 20 | 5.7 / 34 / 50 | 27 | 1.5x over |
| E2, whole disc, r 8,300 | 755 | 2.4 / 46 / 85 | 37 | 8.4 / 52 / 64 | 42 | 2.3x over |
| **Resident map, once whole** | Whole planet | **0** | **0** | **0** | **0** | **Fits** |

**Spreading the bursts over ticks fixes the spike and nothing else.** At 4 reads a tick every row's spike falls to about 3.2 to 4 ms on the laptop, well under the 8 ms. But the reads are only moved:

| At 4 reads a tick, flat out for 30 s | Backlog at the end | Oldest read late by |
| :--- | ---: | ---: |
| E | 272,759 reads | 1,753 ticks (29 s) |
| Rings, 128 to 3,000 | 113,846 | 1,683 ticks |
| E2 | 11,072 | 1,338 ticks (22 s) |
| E2, half disc | 2,983 | 693 ticks (12 s) |
| 1,024 only | 0 | 87 ticks |

By then the pair are long past those nodes, so the disc just empties ahead of them.

**Coarser rings don't rescue it.** A fine inner ring dominates the sum, as `(2r/G)(v/G)` says: the rings above cost more than plain E2. The only live field that keeps up flat out is 1,024-unit nodes (error RMS 16, max 184), and only natively.

**Camera's half disc saves about 44% of E2's reads** but doesn't fit in flight (5.7 against 3.7). In a pure swing it does about what Camera's arithmetic said: at 150°/s it reads a mean of 3.3 nodes a tick over a whole turn (about 480 nodes), with bursts of up to 24 unless they're spread. That's under the native budget and over the web's. A whole disc reads nothing in a swing. **So the swing's rate was never the problem. Flight is.** With a resident map, Camera's 150°/s costs the same as 30°/s in reads.

**A whole-planet map beats any live field at flat-out speed.** A 256² map's texels are 338 units apart, finer than the 707 units Rendering's table says 4 reads a tick can hold at 10,000 u/s.

| Map | Texel spacing | Height error against exact, RMS / p99 / p99.9 / max | Height + colour, with mips | Reads | Build at full gen 2 read: native / web / laptop |
| ---: | ---: | :--- | ---: | ---: | :--- |
| 192² | 451 u | 12.5 / 42 / 194 / 433 | 0.4 MB | 36,864 | 2 s / 5 s / 29 s |
| **256²** | **338 u** | **10.1 / 26 / 175 / 389** | **0.7 MB** | **65,536** | **3.5 s / 8.5 s / 52 s** |
| 384² | 225 u | 7.7 / 11 / 125 / 399 | 1.5 MB | 147,456 | 8 s / 19 s / 118 s |
| 512² | 169 u | 6.6 / 5.9 / 105 / 324 | 2.7 MB | 262,144 | 14 s / 34 s / 210 s |
| 1,024² | 85 u | 4.2 / 1.2 / 41 / 241 | 10.7 MB | 1,048,576 | 57 s / 136 s / 839 s |

- **The tail is the polar ice edge.** The largest errors all sit at latitudes with `|y|` of 0.84 to 0.95, where gen 1's ground steps. RMS is inflated by it, so read p99 for ordinary land.
- **The cheaper read already exists.** `WorldFarMap`'s own note gives about 65,000 reads in a second or so native, without surface detail, built a few hundred texels a frame. At the same laptop ratio (x15) that is about 15 s, by my conversion.
- **v2's 120 ms build is not evidence.** That's gen 1 in JS at under 0.5 µs a read, about 100x cheaper than gen 2 in Godot.

## T4. How much of the 669-column re-lay the sim needs

The bench turns the line, re-lays columns in tiers round each fighter from a 256² map, and measures what a stale column holds against a full re-lay, over 40 swings of 60° from spread places. Milliseconds use 5.4 µs a look-up (the far map's) and 2.5 µs (World's low figure), both native. **My JS look-up is 7 ns, which says nothing about GDScript, so that cost is the bench's largest unknown** (`performance.md` 5.4, item 2, would measure it).

| Tiers round each fighter | Columns, gap 300 / 2,400+ | Native ms, at 5.4 µs | Native ms, at 2.5 µs | Worst stale at the feet, gap 300 | Worst stale at 12 columns' reach, 60°/s, gap 300 |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Every column in view (E) | 669 | 3.61 | 1.67 | 0 | 0 |
| ±75, every tick (Netcode's top) | 161 / 227 | 0.87 / 1.23 | 0.40 / 0.57 | 0 | 0 |
| ±40, every tick (World's window) | 91 / 157 | 0.49 / 0.85 | 0.23 / 0.39 | 0 | 0 |
| **±18, every tick** | **47 / 74** | **0.25 / 0.40** | **0.12 / 0.18** | **0** | **0** |
| ±8 every tick, ±40 every 4 | 43 / 65 | 0.23 / 0.35 | 0.11 / 0.16 | 0 | 42 u |
| ±8 every 2, ±40 every 8 | 22 / 32 | 0.12 / 0.17 | 0.05 / 0.08 | 0.7 u at 10°/s, 4.1 u at 60°/s | 92 u |

- **My answer: about 7 to 11% of it, with far reads going to the map on demand.** ±18 is exact out to 576 units from each fighter. World puts a melee's reach at hundreds of units, so that should cover it, and Simulation's count (T7) will confirm or widen it.
- **It's within Netcode's limit:** 74 columns x 7 re-simulated ticks at 5.4 µs is 2.8 ms of the 12.5.
- **It's over budget at the higher look-up figure and on the web.** The web is 2.4x native, so 47 to 74 columns cost 0.28 to 0.96 ms against 0.2. Performance also says the sim's average has nothing spare.
- **It's only on turning ticks,** Game Design's 10 to 15% of fight time, with no spike.

**The cuts, in order:**

1. **Read columns only when asked.** Stamp each column with the line's version, and `groundY` re-lays on a stale read. A launch's flier reads almost nothing, so the cost falls exactly when swings run most. This is the best cut and I couldn't bench it, because it depends on the real read count (T7). `S.base`'s 170 direct reads are the obstacle.
2. **Stagger the tiers** (the table's last rows), if a stale column of tens of units at reach is honest. **Combat's call:** I wouldn't let it touch a contact.
3. **Launches first.** Game Design's smallest version, about 12 s a match.

**Don't stagger by the pivot.** The first version of this bench centred its tiers on the midpoint, and at a 2,400 gap the feet went up to 93 units stale. Windows have to follow each fighter.

## T5. What proto v2 is, and what it can't say

A true sphere, 153,600 units round. A 512² height and colour map on the graphics card, a vertex shader, and one matrix. A swing and a flight are both one rotation of that matrix. It reads 3 map look-ups a tick and no noise, and costs about 1.5 µs of JS a tick. All five fire modes, three map sizes and the auto demo ran with no GL errors, and the rotation stayed exact over 22 laps. **No human has played it, no real pad has driven it, and its 14 ms frame is the RTX on a loaded machine.**

**It tests what makes a planet feel crossed, but only Orb can answer that.** Each candidate has a control, so Orb can switch one off and see if the feeling goes:

| Candidate | How to test it in v2 | What the others say |
| :--- | :--- | :--- |
| Speed read off the ground | The speed slider; ground detail on or off | Camera: parallax needs something close |
| Landmarks passing | Towers and landmarks on or off; aim with G | World: a place within a launch about 9 times in 10 |
| Far land and horizon moving | The globe, and the wide view in flight | Camera: "this is the read of crossing a planet" |
| Curvature | The curve slider, 100% is true | Camera: a planet that looks small is the point |
| The swing itself | The rate slider and when it fires | Game Design: far land wheeling past on a long flight |

**What v2 does differently from what we'd ship:**

- **Its ground mesh is a polar grid centred on the pair.** A swing is exactly rigid on it, but in flight its vertices slide over the land. Rendering rejected that for the game because faceted ground would crawl, and it's right: **use Rendering's planet-keyed tiles.** v2's smooth shading hides this, so v2 can't judge it.
- **It has no fighters, water, near-side rule or real settlements.** Towers in front of the bars sink out of the way, which stands in for Rendering's largest look risk (a mountain swinging into the foreground) without testing it.
- **Its ground is one height function** with made-up shading detail. Whether 338-unit ground reads as a world up close is Art's and Orb's call.

## T6. The route

Each stage ships behind a switch with the golden byte-identical while off. **Shared** means the ribbon needs it too, so it survives a change of mind. Sizes are my rough guess.

| # | Stage | Useful alone because | Owners | Shared with the ribbon? |
| ---: | :--- | :--- | :--- | :--- |
| **0** | **Measure, no game code.** Rendering's scratch scene (`rendering.md` section 5, the go or no-go), Performance's vertex fetch and re-lay timings, World's `field_probe`, Simulation's read count (T7), Orb's answers from v2 | Decides the route before anyone builds | Rendering, Performance, World, Simulation, Orb | Partly |
| **1** | **The far land reads a planet frame** and turns by a uniform; `FAR_MAP_ON` on; horizon moves at `v/R` in flight | **The crossing feel, soon, with no swing.** It may carry much of what Orb wants | Rendering, World | **Shared** |
| **2** | **The planet store.** Beams, slides and heaps become records | The world remembers across today's turns too | World, Simulation | **Shared** |
| **3** | **Places by plan, towns first** (`world.md` 9.2), with stable building slots | The same town on any line. Option A lands first (Game Design) | World, Simulation, Art | **Shared** |
| **4** | **Resident map as the one height source.** Height and colour, pure function of the planet, filled in the background near the pair first; a missing texel is a forced read and gives the same value. Water and rivers as planet records | Far readers and far land get right ground at any bearing | World, Simulation | Shared in part: the ribbon's far ring could use it |
| **5** | **The new ground renderer** (`rendering.md` option C), tiles keyed to the planet, one uniform a frame, `world_place()` | Drops ring copies and their churn | Rendering, Art | Turntable only |
| **6** | **The sim's window.** Line frame in the state, columns read on demand, far-reader audit, poses for town buildings | The sim stands on the turned ground; test 7 passes | Simulation, Encounter, World | Turntable only |
| **7** | **`DirSwing`, launches only.** Game Design's rules, Encounter's single line | **Orb's picture**, about 12 s a match | Encounter, Game Design, Camera, Netcode | Turntable only |
| **8** | **More of it:** chases, form pauses, brawls last, each against the budget | Game Design's 10 to 15% of fight time | Game Design, Performance, QA | Turntable only |

**Why this order.** Stage 0's scratch scene is the one test that can kill the route cheaply, at one window. Stages 1 to 3 pay off whichever route survives. Stage 5 is the big one and has no byte-identical oracle, since true 2D relief changes the look on purpose; only the plane row can be held to the strip.

**The fallback.** If stage 0's scene fails or Orb's look gate rejects the foreground, stages 1 to 3 already serve the ribbon (Part 2's stages 1 to 3). Stage 4 can feed its far ring. Only the ribbon's streaming stage is new work from there.

## T7. What's still needed

| From | What | Why |
| :--- | :--- | :--- |
| **Orb** | The three questions sent with v2: the swing as pictured, when it fires, and what reads as crossing | They hedged last time; v2's switches are for this |
| **Rendering** | The scratch scene, first | The GPU's headroom on the laptop is unknown, and everything rests on it |
| **Simulation** | **A count, on real AI fights: distinct columns read a tick, split by distance from the nearest fighter, separating `groundY` from direct `S.base`** | Replaces T4's windows with a fact and sizes the far readers |
| **Performance** | Look-up time in GDScript, native and web, plus the vertex-fetch microbench | T4's 2.5 to 5.4 µs is the difference between fitting and 2x over |
| **World** | `field_probe` for gen 2 error; cost of a height-only read; whether a 256² map holds ranges and rifts | All of T3's errors are gen 1 |
| **Combat** | Whether a stale column at reach is honest | T4's stagger |

**Risks I can name:**

- **Gen 2's creases may need a finer map than 256².** World can't yet say how often they occur.
- **The drawn ground must equal the sim's ground at the feet.** One map and one interpolation give that, but R16F's precision at a height of 2,000 is 1 to 2 units, so the map needs R32F with a hand bilinear, as Performance notes.
- **A background-filled map means a swing can show unread ground early in a match.** Filling near the pair first helps, but a flat-out flight in the first seconds can outrun it on the laptop.
- **An idea I didn't test: bake the view's map on the GPU.** A fragment shader running the noise could fill a 512² map in a few frames. It's float32 and not deterministic across GPUs, so the sim couldn't read it, and the feet problem above returns. Worth one spike only if the load bill turns out to be the blocker.

# Part 2: the ribbon (fallback; the paper of 2026-10-30)

**Orb's pick replaced this recommendation on 2026-10-31.** The numbers stand, and it stays the fallback. Its section 7 is answered by the pages now in this folder (`rendering.md`, `camera.md`, `encounter.md`, `simulation.md`) and is left as written.

## 1. The answer as it stood

**It recommended the ribbon: the fight's line becomes a curve the choreographer steers, laid just past the edge of what the camera can see, over a world whose marks are kept in planet coordinates.**

- **Any angle, any tick, nothing refused.** 236 asks in 2 minutes were all accepted, and none rewrote a column the camera could see.
- **It needs no swap.** Performance's 96 to 116 ms render rebuild, the 1.3 to 13 s read lead and World's calm test (true on 57.7% of ticks) are all things a swap needs, so they go.
- **The sim barely notices.** `x` still wraps, on the same 4,800 columns, so 1,335 wrap sites in 205 files stay as they are.
- **It holds "no walls".** A fight that isn't steered closes its lap exactly (0 units off). A steered one arrives somewhere new, and can be aimed at a place on demand (42 units off).

**The one honest limit.** A bend can't reach the pair until they fly to it, because nothing inside the camera's view ever changes. A 90° ask on a launch's first tick has fully turned after 14,100 units of flight: 2.3 s at launch speed, 1.4 s flat out. **Any route that shows the new angle sooner must rewrite what the camera shows.** That is route E, or a hard cut (stage 7).

**The question this put to Orb,** whether the fight heads somewhere new or the world visibly swings round the fighters, is answered: the world swings.

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
