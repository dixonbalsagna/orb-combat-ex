# The fight at any angle: the turntable route, with the ribbon as fallback

Research & Prototyping, for the EP. Revised 2026-10-31 for Orb's pick ("the turntable approach in E and E2 seems to be closest to my vision") and for every director's section now in this folder. Part 1 is the turntable. Part 2 is the 2026-10-30 paper on the ribbon, kept as the fallback.

**Play it:** open `research/ring-any-angle/proto-v2.html` (one file, no install). **Reproduce the numbers:** `node research/ring-any-angle/cuts.mjs` (`cuts.json`, `cuts.txt`).

**How far to trust this.**

- **Measured by others, in GDScript or on a GPU:** Simulation's and Performance's timings, and World's gen 2 errors. Each is credited where it's used.
- **Counted by me in JS, on gen 1 ground:** reads, which don't depend on machine load. Milliseconds of mine are counts times World's cost of a read.
- **Never run:** nothing here has swung in the real sim or on the target laptop's GPU, and no human has reported on v2.

# Part 1: the turntable

## T1. The two answers

### Is it affordable at Game Design's rates?

**Yes on reads and on the sim, if the ground is baked at load. On the old laptop's GPU it holds at the median and not at p95, by an estimate nobody has run. It isn't affordable as E or E2 ran it.**

**The rate was never the cost. Flight is.** A swing in place reads nothing at any rate, and going from 60°/s to the 98°/s ceiling adds 3% to E2's reads in flight. So Game Design's rates can be set on look and flash alone. Orb has since played v2 and was comfortable at every speed up to 240°/s, too extreme only with the largest swing (`game-design.md` §10). That's one player on bars, not a clearance, and builds stay at 60 until the flash reading.

| Against the budget (0.2 ms a tick, which is 1.5 ring-column reads on the web, or about 4 plain node reads; 8 ms spike) | E, E2 as they ran | The route | Verdict |
| :--- | ---: | ---: | :--- |
| Reads, a swing in place, 60 or 98°/s | 0 | 0 | Fits |
| Reads, flat out with swings | E 156, E2 10.1 nodes a tick | **0 once baked** | Fits; E2 is about 2.5x over (see the correction in T3) |
| Read spike, web at x1, p99 | E 18 ms, E2 3 ms | None once baked | Fits; E was over the 8 ms |
| Sim, a swing tick | 3.6 ms, 18x the budget (Simulation) | **0.1 to 0.15 ms mean,** read-through (Simulation's sum, not yet a run) | Fits |
| Rollback frame at 200 ms ping, against 12.5 ms | 29 ms (Simulation) | 4.8 ms (Simulation) | Fits |
| Drawing a swing, each frame, against 0.5 to 1 ms | 5.5 to 12 ms if re-laid (Performance) | **+0.1 to 0.5 ms on a current Radeon iGPU** (measured); **on the old laptop, about the same at the median and up to +1 to 1.6 ms at p95** (estimate) | Fits at the median; **at p95 on the old laptop it doesn't** |
| Loading the bake | None | **1.25 to 1.31 s native, 1.59 to 1.92 s web (both measured), about 6 to 11 s on the laptop (arithmetic)** | Fits Performance's ruling, at the edge (below) |

**The go or no-go is the old laptop's GPU, and the answer so far is an estimate.** Rendering's scratch scene is running now. Performance's measure is on a current Radeon iGPU, and its model of ADR 0011's 2015 ultrabook comes from its memory of the parts: no such machine has been run, and the project doesn't have one.

| Rotated ground, 4 or 8 fetches a vertex (**estimate**, Performance 6.4) | Old iGPU at 2.5x | At 4x, a safe worst case |
| :--- | ---: | ---: |
| Median frame, 75k vertices | +0.1 to 0.5 ms | +0.15 to 0.8 ms |
| p95, 200k vertices, counting the water pass | up to +1 ms | up to +1.6 ms |

**So the 0.5 to 1 ms allowance holds at the median and is gone at p95.** There, the near ground needs fewer vertices (half the columns where it's now every one) or the game's step-down. That's a real cost on the target machine, though not a fatal one on this evidence. Rendering's existing scene is also over at p95 there without a step-down, so the swing isn't the only cause.

**What it costs, by how much of Game Design's plan ships.** A 7-minute match is 25,200 ticks. The first two columns are from Simulation; the split by cause is my arithmetic from Game Design's table and Camera's ramps, at each cause's largest swing.

| Version | Swing time a match | Sim added over a match | Per swing tick | Which problems it removes | What it doesn't remove |
| :--- | ---: | ---: | ---: | :--- | :--- |
| Game Design's whole plan | 36 to 72 s by its ruling; up to 52 s by my split (launches 12, chases 5, form pauses 10, slow brawl swings up to 25), plus small swings | 0.3 to 0.6 s | 0.1 to 0.15 ms | None | Everything below |
| **Small swings added** (§10: 20 to 40 a match, 2° to 15°) | Under 2% of fight time, by its ruling | Under 0.1 s | The same | | Reads nothing and needs no new machinery once swings exist. **The cost is flash:** only the analyser can say at 240 |
| **Slow brawl swings off** (Orb's question; §10 already makes jolts the first choice) | About 27 s | About half | The same | The standing ride, the backstop at a face for a standing fighter, the slowest and worst view of land sinking in front, and most of the wall cases | |
| **Launches only** (the smallest version) | **About 12 s, 720 ticks** | **About 0.1 s** | The same | All of the above, plus chases | |
| Any of these | | | | | **The bake, the new ground renderer, the planet store, planet-keyed lakes, rivers and trees, places by plan** |

**Launches only saves risk and design work, not the big build.** A swing tick costs the same in every version, so the renderer is needed for one swing as much as for twelve. It also doesn't rescue E: every one of its 720 ticks is still 18x the budget (Simulation).

### Is the ground the field or the exact planet?

**The field defines the ground, and I'd build your provisional call: Simulation's option A, one canonical spacing as a single data value, the bake, with zero noise reads in play.** Option A doesn't fail my numbers on gen 2 error. What it costs is look, and that's Orb's to judge on v2's real gen 2 ground.

**I withdraw my 256-over-512.** I'd proposed reading 256 near the fighters over a 512 bake. Simulation's feet conflict is against it: the sim and the drawn ground must match at his feet, and two levels only match if the view has already read the sim's nodes there. One level has no such case. Your stale-column point is right too: sim and mesh read the same ground, so nothing is stale at all under option A, and I've dropped that question for Combat.

**Why matching the exact planet fails.** World needs 64-unit nodes near the pair just to keep a shore within a column, and nothing fixes gen 2's steps at any spacing. True columns miss a 128-unit mesh by RMS 8.5, worst 239 (Simulation). At 64 units the strip alone reads 3.3 to 5.4 nodes a tick, 2 to 4x over.

**Option A's price, at each spacing.** Distinct nodes are Simulation's cube count, scaled from its 33,752 at the bake's size. RMS is against today's ground, along the ring, a floor (World 11.1).

| Canonical spacing (one data value) | Nodes | Native | Web | Laptop (arithmetic) | Memory, heights + biomes | Gen 2 RMS / worst | What it loses |
| ---: | ---: | ---: | ---: | ---: | ---: | :--- | :--- |
| 1,024 | 8,400 | 0.3 s | 0.4 s | 1.5 to 3 s | 42 KB | 48 / 353 | Lost shorelines, lakes. Not usable |
| **512 (the bake)** | **33,752** | **1.3 s, measured** | **1.6 to 1.9 s, measured** | **6 to 11 s** | **173 KB (132 KB gzipped)** | **23 / 319** | Crests off by up to 2.5 fighter heights, lakes blur, ice walls become ramps |
| 384 | 60,000 | 2.3 s | 2.8 s | 11 to 16 s | 300 KB | About 17 | Doesn't fit the ruling unless cached |
| **256** | **135,000** | **5.2 s** | **6.4 s** | **26 to 36 s** | **690 KB** | **11 / 273** | Basins kept. Crests off by about 1 fighter height. Only with a cache or shipped data |
| 128 | 540,000 | 21 s | 26 s | 100 to 140 s | 2.8 MB | 5.1 / 189 | About half a fighter height. Only with a cache or shipped data |

- **Memory isn't the constraint; first load is.** Each halving of the spacing is 4x the wait, and the bake must finish before tick 0 (`SimPlanetLoad.mayStart`; whether it's done is never a sim input). So a coarse-first bake can't help the sim.
- **Performance's ruling** (a judgement about patience, Orb's to overturn): up to 10 s added on the laptop to a cold planet, never as a frozen page. The bake runs in slices of at most 4 ms a frame, behind the intro, the menu and character select, which is about 13 s of wall time on the laptop. A cold planet's make plus bake is 13 to 22 s, so it can't be a blank wait. The bake needs the seed known early: a menu that picks the planet late leaves a bar.
- **After that:** a disk cache in the next cut, keyed by data hash, engine version, seed, generation and spacing, so a repeat visit costs at most 3 s. Shipped planets only as polish for the demo's default, 132 KB gzipped each, in a separate file. It does nothing for a random seed.
- **Levers that don't work or aren't ready:** no worker thread on the web. Heights first saves 43 to 52% only if biomes are proved unneeded before tick 0, which is Simulation's call.
- **If Orb's eye wants more than 512,** the honest ask is 256 with a cache: 26 to 36 s on the first play of each planet, on the laptop.

**Load time, reconciled.** Three figures were talking about three things:

| Figure | What it was |
| :--- | :--- |
| World's 3.7 s on the web | 28,650 nodes by area x 130 µs |
| Simulation's 4.4 s | 33,752 distinct nodes x 130 µs, the ring column's cost. **Corrected:** a bake node is a plain `surfAt`, not a column |
| **Performance's 1.59 to 1.92 s** | **34,656 nodes, measured on the web, 46 to 55 µs a node. This is the one to use;** native 1.25 to 1.31 s, the same as Simulation's measured 1.3 |
| My earlier 15 s on the laptop | A different job: the far map's 65,000 cheaper reads without surface detail. **Withdrawn** |

The laptop's 6 to 11 s is Performance's x4 to x5.6 of that. My earlier 18 to 27 s inherited the 130 µs and is withdrawn. Nobody has run it on a laptop. Rendering's far map already spends 65,000 reads on a similar job, so one bake serving both may be cheaper than today's.

**What can make 512 honest (World's section 13, measured).**

| Candidate | RMS | Shore off, RMS / max | Verdict |
| :--- | ---: | ---: | :--- |
| The bare bake | 23.9 | 203 / 736 | |
| Plus exact 3-octave surface detail | 23.6 | 187 / 736 | **No:** that isn't what a bake loses |
| Plus a one-op hash noise | 33.7 | 98 / 384, with 2 false shores | **No, not in anything the sim reads** |
| A cubic through four nodes | 22.5 (mountains 13% better) | 152 / 576 | Optional: 12 operations in the sim, free for the view |
| An exact land or sea gate at each column | 23.5 | **105 / 384** | Shows the shore is a gate problem, not a noise problem |

**So "sharper ground from a pure detail term on both sides" doesn't work for relief.** The term that would restore creases is half a column read, per sample. What goes in the route instead:

1. **Coast and ice-edge records:** a few planet records a ring, laid on the field like craters. They put shores and walls exactly where they are today.
2. **A drawn-only detail term** for texture, which the sim never reads. Feet differ from it only by its small amplitude, and it stays off near shores so it invents none. v2 has one, on a switch.

**What the narrow strip could afford if Orb wants a finer ground without the load.** New nodes a tick, counted in JS under the columns the sim asks for, against about 4 plain node reads a tick on the web:

| Moving, and reading | 128 u | 256 u | 512 u | 1,024 u |
| :--- | ---: | ---: | ---: | ---: |
| One flier at launch speed, feet only | 1.87 | 0.96 | 0.46 | 0.20 |
| A launch: flier plus launcher, swing at 60°/s, feet only | 3.04 | 1.57 | 0.77 | 0.35 |
| The same, ±18 columns round each | 6.38 | 2.38 | 0.93 | 0.38 |
| A chase, both flat out, swing at 45°/s, feet only | 3.26 | 1.63 | 0.75 | 0.33 |
| A chase, 3,000 apart, feet only | 2.91 | 1.56 | 0.74 | 0.32 |

This is Simulation's option B or C, kept addable because the sim's read is one data value. **At about 4 reads a tick the strip affords even 128 at launch speed.** A tile at landing costs about 4 ms on the web at 256 (81 nodes), inside the 8 ms, and about 13 ms at 128 (256 nodes, Simulation's 33 ms at the old cost). So option B or C is more reachable than Simulation's section 7 assumed. They're still two levels, with the mismatch at the feet to handle, so option A stays first.

**Can refining at rest stay deterministic, if it's added later? Yes, on Simulation's rule:** which level a read uses is fixed by the reader, never by what's ready. A missing node is read on the spot and gives the same value. What would break it is a sim that reads "the sharpest ground available".

**What smoothing costs, for Orb's look gate.** World's section 12: ice edges stop being walls unless they're records, and mountains lose crispness. Steps are rare (0.14% of a ring's columns over 75 units), and fights on coasts, in forests and in cities meet none.

## T2. The fork, ranked

| Rank | Fork | Test 7, a solid world | Sim, a swing tick | Rollback at 200 ms | Work | Verdict |
| ---: | :--- | :--- | ---: | ---: | :--- | :--- |
| **1** | **(b) Narrow sim strip read through the frame; resident 2D ground the renderer turns** | **Passes:** v2's full turn returns the same picture, 0 of 921,600 pixels different | 0.1 to 0.15 ms | 4.8 ms | Medium in the sim, a new ground renderer | **Recommended** |
| 2 | (a) The 1D strip re-laid across the view, as E does | **Fails as drawn:** columns re-laid from a field morph (Rendering's option A), and E's largest pop is 356 units. Fixing the look needs (b)'s renderer anyway | 3.6 ms, 18x | 29 ms | Same renderer | Rejected, even as launches only |
| 3 | (c) A true 2D sim | Passes with (b)'s renderer | 0.12 ms, on every tick | 4.6 ms | 1,335 wrap sites, 642 reads, every director plan | Rejected. Cheap to run, but it buys nothing play asked for, and Game Design keeps everything on the line |

Rendering, Netcode, World, Simulation and Performance each reach (b) on their own. **Your hypothesis holds:** a turn rotates something resident. Simulation adds the part I'd left open: 80% of the sim's ground reads land within 3,000 units of a fighter, and a mean of 10 distinct columns are read a tick, with a far-reader audit of 69 lines.

## T3. The cost cuts, benched

The counting model reproduces `sim.js`'s own runs within 3%. Flying rows are 30 s first crossings with a 60° swing every 4 s, because a longer run revisits ground and flatters every row. Laptop ms is reads x 0.8.

| Field round the pair | Nodes at load | Fights (`any`): mean / p99 | Flat out, 60°/s: mean / p99 | Launch speed, 60°/s: mean | Laptop p99, flat out | Flat-out mean against 1.5 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **E:** 128 to 12,000 | 24,015 | 44 / 348 | 156 / 354 | 132 | **283 ms** | 104x |
| **E2:** 512 to 12,000 | 1,597 | 2.9 / 59 | 10.1 / 65 | 8.8 | **52 ms** | 6.8x |
| Rings: 128 to 1,500, 256 to 4,000, 512 to 12,000 | 2,408 | 13 / 126 | 51 / 133 | 36 | 106 ms | 34x |
| Rings (World's): 128 to 3,000, 512 to 12,000 | 3,015 | 17 / 133 | 67 / 147 | 47 | 118 ms | 45x |
| 512 to 6,000, 1,024 to 12,000 | 728 | 2.2 / 48 | 7.9 / 60 | 6.4 | 48 ms | 5.3x |
| 1,024 to 12,000 | 428 | 0.8 / 26 | 2.7 / 33 | 2.4 | 26 ms | 1.8x |
| **E2, half disc of B, 8,300** (Camera, 16:9, close) | 430 | 1.7 / 25 | 5.7 / 34 | 4.2 | 27 ms | 3.8x |
| E2, half disc of B, 10,800 (Camera, any setting) | 753 | 2.1 / 32 | 6.7 / 41 | 5.4 | 33 ms | 4.5x |
| E2, whole disc, r 8,300 | 755 | 2.4 / 46 | 8.4 / 52 | 7.0 | 42 ms | 5.6x |
| 1,024, half disc of B, 10,800 | 204 | 0.6 / 14 | 1.8 / 19 | **1.5** | 15 ms | 1.2x |
| **Baked at load** | Whole planet | **0** | **0** | **0** | **0** | **Fits** |

**A correction to this table, from Performance's section 6.** The counts stand, but I priced them too high. A field node is a plain `surfAt`: 38 µs native and 46 to 55 µs on the web, not the ring column's 130 µs. So 0.2 ms buys about 4 node reads a tick on the web, not 1.5, and a laptop read is about 0.2 to 0.3 ms, not 0.8. Divide the laptop column by about 3 and read the last column against 4: E 39x over, World's rings 17x, E2 2.5x, **Camera's half disc at 8,300 about 1.4x, and about at budget at launch speed.** A height-only read, if it can be used, would bring that half disc inside the budget flat out.

**The conclusion holds, by a smaller margin.** No field at a usable spacing fits flat out at about 4 a tick, and E's 278 ms is about 90 ms. The bake still wins: zero reads in play, one level, nothing to prefetch. But a lazy or half-disc field is no longer absurd, and Performance lists a lazy bake as a real way to cut the load, with its cost moved to the ticks that read new nodes (8.6 ms at worst on the web, by Simulation's count). I'd keep it in reserve for the load, not as the design.

**Spreading bursts over ticks fixes the spike and nothing else.** Every row's spike falls under 8 ms, but the reads only move:

| Flat out for 30 s | Backlog at 3.7 a tick | At 1.5 a tick | Oldest read late by, at 1.5 |
| :--- | ---: | ---: | ---: |
| E | 273,299 | 277,257 | 1,780 ticks (30 s) |
| Rings, 128 to 3,000 | 114,386 | 118,344 | 1,743 ticks |
| E2 | 11,611 | 15,562 | 1,633 ticks (27 s) |
| E2, half disc, 8,300 | 3,522 | 7,473 | 1,371 ticks |
| 1,024 only | 0 | 2,133 | 1,171 ticks |
| 1,024, half disc, 10,800 | 0 | 624 | 572 ticks |

By then the pair are long past those nodes, so the disc just empties ahead of them.

**Coarser rings don't rescue it.** A fine inner ring dominates the sum, so the rings cost more than plain E2. The only live fields near 1.5 are 1,024-unit nodes, and on gen 2 those are RMS 48, max 353, with shorelines lost (World).

**Camera's half disc does what Camera's arithmetic said, in a swing.** At 60°/s in place it reads a mean of 1.3 a tick over a whole turn at B 8,300 and 2.2 at B 10,800, about 2.6 while it's first sweeping, against Camera's 2.3. Bursts reach 20 to 22 unspread. At 98°/s it's 2.2 and 3.6. **But it saves only 33% in flight against a whole disc of the same radius, and doesn't fit.** A whole disc reads nothing in a swing, and with a bake neither matters.

**The bake's cost by spacing is in T1.** Two more figures for the record:

- **The far map's 256² isn't the route's ground.** Its texels are 338 units apart, so on gen 2 it sits between World's 256 and 512 rows, about RMS 15 by interpolation. My first paper listed 10 from gen 1, too kind by the factor World found. The bake replaces it.
- **World's two-ring field** (128 within 3,000, 512 to 12,000): about 3,400 nodes, about 190 ms native to fill once by World's arithmetic (my count is 3,015), and hopeless to keep filled in flight: 67 reads a tick flat out against 1.5.

**Sharpening a disc at rest,** only if a finer near level is ever added (option B or C):

| Disc | Nodes | At 1.5 a tick | At 3.7 a tick |
| :--- | ---: | ---: | ---: |
| 256 to r 3,000 | 431 | 4.8 s | 1.9 s |
| 256 to r 6,000 | 1,726 | 19 s | 7.8 s |
| 128 to r 1,500 | 431 | 4.8 s | 1.9 s |
| 128 to r 3,000 | 1,726 | 19 s | 7.8 s |

**The re-lay, pinned for Netcode.** The JS can't pin it (my look-up is 7 ns), but GDScript now has:

- A re-laid column is **3.4 to 3.8 µs native** with its marks (Simulation), so 669 columns are 2.5 ms warm and 3.6 ms with derived tables.
- That's inside my old 1.7 to 3 ms for the array work and a little over it all-in, so Netcode's 170-column limit stands, and its "three times" case doesn't happen.
- A bare sample is 0.18 µs native and 0.4 µs on the web (Performance), which is why the read-through is so cheap.
- A window of ±18 round each fighter is exact at the feet and at reach: 47 to 74 columns, 0.17 to 0.27 ms if re-laid. The read-through's mean of 10 columns beats it, so it's the stepping stone, not the target.

## T4. Walls, and the two paths

Game Design's §8: once a line tilts, walls are real. Encounter's rough estimate is 10 to 26 strikes a match with a wall in the way, against 0 now.

| | **Rest on a street's bearing** (the fallback) | **The collision path with depth off** (World's L3 machinery) |
| :--- | :--- | :--- |
| **Frame cost** | Nothing per tick. A query is a few dozen operations (World 10.3) | About 5 µs a standing fighter a swing tick for the face (World 9.3); `_checkHitSwept` on a swung line per moving body. Poses and index within a window about 0.05 ms (Simulation) |
| **Build** | `WorldStreets` (World), one score term (Encounter). Needs a place's street bearing, which means towns by plan | L3's contact and swept test run with depth off, plus the plough-or-over-the-top rule (Combat, Game Design), and the planner reads it. About 1 to 2 windows by my guess; L3 is World's scratch and I haven't read its state |
| **Cost in play** | A swing inside a place may turn up to 45° more or less to reach a street. Within 15° a small swing does it in under half a second at 60°/s (§10), the cheapest case; past that it's up to 1 s more swing, which may not fit the flight. Cities are approached along their own grid | Collateral goes up, so QA's band must be re-read. Orb has already objected to fighting through walls |
| **What it leaves** | A cut through blocks while the swing runs, and a brawl that drifts off the street | Nothing, by design |
| **Frozen cities** | Only within about 10° of the laying bearing (World) | Works if buildings have poses |

**Do both, street first.** It's Game Design's order, and it's the cheap one. It's also the fallback by itself if the collision path costs too much. Launches only needs less of this: a flier meets walls only through his own flight.

## T5. What proto v2 is, and what it can't say

**What it is:** a true sphere, 153,600 units round, one map on the graphics card (up to 1,024² on gen 1, or real gen 2 at 256 and 512 units, read in Godot and inlined), and Rendering's shape: tiles keyed to the planet, drawn instanced, turned by one matrix. It runs Game Design's law (cause's rate, size ceiling, sweep limit), Camera's ramps and floors, the small class, Netcode's forced flip, and Rendering's softening and foreground rule, each on a switch. All rate sliders reach 240, because that's what Orb played; 60 is the build's value, and each is ticked at 98 and turns red past it. A switch caps drawing at 30 fps, because a 5° swing at 240°/s is about one frame there (Camera).

**Checked with scripted ticks in a real browser (RTX):**

| Check | Result |
| :--- | :--- |
| Test 7, a full 360° with a crater | **0 of 921,600 pixels differ;** 668,476 differ at 180°, the control |
| Gaps between tiles, magenta test, seven views including 60 frames flat out | 0 |
| A launch | First moves on the first live tick, peaks at 60.0°/s, at rest at least 21 ticks before contact |
| Big swings at 60°/s, limit off | 10° 0.5 s, 45° 1.0 s, 90° 1.75 s, 180° 3.27 s: Camera's table |
| Size ceiling, rate set to 240 | 60° peaks at 120, 90° at 98, 180° at 69: Game Design's table. **30° is the exception:** 120°/s, 0.5 s, against its 170 and 0.43 s, because 20 and 10-tick ramps can't peak higher on 30° |
| Small swings, 240 and 60 | 5° with a blow 8 and 15 ticks, without 12 and 12; 15° with a blow 12 and 45, without 12 and 29: Camera's floors |
| Small swing's allowance, standing | Gap 250 caps 15° at 13.75°, gap 600 at 5.73°, gap 2,000 doesn't fire: as ruled |
| A 90° launch, sweep limit on | 1.67 s, peak 60°/s, against Game Design's "about 2 s" at 6,000 |
| 180° asked, 6 s flight, the 10,000 limit | **All 180°, in 4.3 s, peak 60°/s,** past Game Design's estimate of about 165°. At 6,000 the same ask held to about 100° |
| Slow swing off, launches only, reduced motion, beam | As ruled: 0° added, 0° in a chase, peak 30, at rest within the 33-tick ease |

**The forced flip, for Netcode.** Its table holds on Camera's ramps. Off by, on a 90° swing:

| Kind | Depth 6 | 13 | 20 | Netcode's column |
| :--- | ---: | ---: | ---: | :--- |
| The swing taken back | 0.5° | 3.6° | 9.5° | Eased: 0.9°, 4.2°, 10° |
| The wrong way | 1.0° | 7.2° | 20° | "Doubles the eased column" |
| A rate jump at the peak | 5.3° | 12° | 19° | Instant: 6°, 13°, 20° |

The view never turns faster than the swing's peak: a correction waits if the sim is running away from it, as Netcode's rule asks. It uses a small swing's own rate too.

**The horizon.** On this full ring, 60 + 23 = 83°/s is under the 98 ceiling, so by Game Design's §9 rule it needn't give way. v2 doesn't ease it off, because far land and near land are one rigid sphere there: easing would need a shear, which fails test 7. In the game the far land is its own layer, so Game Design's rule can apply.

**It tests what makes a planet feel crossed, but only Orb can answer that.** Each candidate can be switched off to see if the feeling goes: speed read (speed, softening, detail), landmarks (towers), the far land and horizon, the curve (slider), and the swing itself.

**What it can't say:**

- **Laptop frame time.** It draws 188k to 340k triangles (92 to 164 tiles) by its own count, above Rendering's 100k to 150k target.
- **All of gen 2's look.** The real gen 2 settings show planet 7's heights at 256 and 512 units, without coast or ice-edge records, rivers or lakes, so they're harder on shores than a shipped bake. The gen 1 settings flatter: gen 1 at 512 is RMS 4.7, gen 2 is 23.
- **Softening's detail.** It uses the map's mip levels, a fair picture of soft ground but not of real node spacing.
- **Fighters, water and real settlements.** The bars stand in for fighters, and there's no water or lakes, no props or crowds.
- **Flash.** Rendering is concerned about 60°/s over a city, and that needs the analyser on the game's clip.

## T6. The route

Each stage ships behind a switch, with the golden byte-identical while it's off. **Shared** means the ribbon needs it too. **★ marks what must exist before Orb can see a swing with real ground.** Sizes are my rough guess.

| # | Stage | Holds | Useful alone because | Owners | Shared? |
| ---: | :--- | :--- | :--- | :--- | :--- |
| **0** | **Measure.** ★ Rendering's scratch scene (running). A run on a machine of the old laptop's class, if one can be had. Orb's answers from v2, on the real gen 2 ground | | The cheapest test that can kill the route | Rendering, Performance, Orb | Partly |
| **1** | ★ **Clear the ground.** Option A lands first. `hill_chapel` out and the bell tower renamed with the first swing data change (RL-214) | Game Design's and Encounter's first step | The plane is honest today | Encounter, Simulation, World | **Shared** |
| **2** | **The far land reads a planet frame.** `FAR_MAP_ON`; horizon at `v/R` | | **The crossing feel, soon, with no swing.** It may carry much of what Orb wants | Rendering, World | **Shared** |
| **3** | ★ **The field defines the ground (a new generation, behind a switch).** Simulation's option A: one canonical spacing as a data value, baked in 4 ms slices behind the intro, the menu and select, finished before tick 0 (`mayStart`), immutable and outside the state; its hash joins the match key; zero noise reads in play; the sim reads triangles of the same nodes. **Coast and ice-edge records** laid on the field; **lakes, platforms and sites planned on its heights; trees keyed by planet cell** (no re-rolls). Nothing noise-based in what the sim reads | Fill cost, trees, lakes' plan, coast records | Far readers and far land get right ground at any bearing. **Orb judges smoothing at the look gate here** | World, Simulation | Shared in part |
| **4** | ★ **The new ground renderer** (Rendering's C), tiles, `world_place()`, foreground rule, softening | Rendering's section | Drops ring copies and their churn. A dig touches a few layers, not 460 KB | Rendering, Art | Turntable only |
| **5** | ★ **The sim's read-through.** The frame in the state, `groundY` through it, poses and index near the fighters, the far-reader audit (69 lines), `frameAt(n)` | Encounter's `frameAt` | The sim stands on the turned ground | Simulation, Encounter | Turntable only |
| **6** | ★ **`DirSwing`, launches only, over open ground** with craters only, using today's swap's frozen places out of its way | Game Design's smallest version | **Orb sees a real swing here.** Camera's clips, flash reading, Legal's first look | Encounter, Game Design, Camera, Netcode, Legal | Turntable only |
| **7** | **Every mark a record** (the planet store): slides, beams, heaps, fills, flows; **broken props by planet point**, not by column | World's marks, Encounter's props | The world remembers across a swing, and across today's turn | World, Simulation | **Shared** |
| **8** | **Water as planet records:** lakes as 2D basins, rivers as polylines with a planet gap rule | World's rivers and lakes | No blinking lakes or rivers | World | **Shared** |
| **9** | **Towns by plan, then cities** (a city frozen on its chord holds only to about 10° of swing), with stable slots and street frames | World's cities | Swings go into places. Arrivals (Encounter's stage 5) | World, Simulation, Art, Encounter | **Shared** |
| **10** | **Walls:** rest on a street, then the collision path (T4) | Game Design's §8 | Fights in places stay honest with the line tilted | World, Encounter, Combat, QA | Turntable only |
| **11** | **More swings:** the small class first, at 60 (jolts, corrections, line-ups), then chases and form pauses, the slow brawl swing last if Orb wants it. Past 60 only on the flash reading | Game Design's plan and §10 | 10 to 15% of fight time, and the irregular path Orb enjoyed flying | Game Design, Performance, QA, Legal | Turntable only |

**What Orb can see at stage 6, and what it lacks.** Open ground with real terrain, craters, and trees that stay put. Rivers and lakes are off or left out of a swing's path, and swings steer round places. So it's the swing and the crossing without the cities. Orb likes buildings most, so stage 9 is when it becomes the full picture. **World's point stands:** height was never the blocker. Rivers and lakes are at stage 8, and without them a swing over real water would blink.

**Why this order.**

- Stage 0's scene can kill the route for one window of work.
- Stages 1 and 2 pay off whatever survives.
- Stage 3 is where Orb judges the smoother ground, before anything rests on it.
- Stages 4 and 5 are the big ones. Stage 4 has no byte-identical oracle, because true 2D relief changes the look on purpose; only the plane row can be held to the strip.

**The fallback.** If stage 0 or Orb's look gate fails, stages 1, 2, 7, 8 and 9 already serve the ribbon, and stage 3's bake can feed its far ring. The ribbon's streaming stage is the only new work from there.

## T7. What's still open

| From | What | Why |
| :--- | :--- | :--- |
| **Orb** | The swing as pictured; jolts, slow swings or neither up close; what reads as crossing; and whether real gen 2 at 512 units is enough | Each decides cost |
| **Rendering** | The scratch scene, running now | It's the go or no-go |
| **Performance** | One run on an old-laptop-class machine, or a GPU-limited emulation; the project has neither | The p95 figure is an estimate from the parts |
| **World** | A height-only read's cost; L3's state with depth off; 2D error (11.1 is along the ring, a floor) | 256's fit and T4's cost |
| **Simulation** | A read-through actually run, with a swing | 0.1 to 0.15 ms is a sum, not a run |
| **Combat, Game Design** | The plough or over-the-top rule | T4 |

**Risks I can name:**

- **Load time on the old laptop** is at the edge of Performance's ruling: 6 to 11 s at 512 by arithmetic, 13 to 22 s for a cold planet with its make, nobody has run it there, and 256 is four times the bake.
- **A mountain or tower coming round in front** is Rendering's largest look risk. v2's rule makes land sink, and Orb will see it. Only Orb can judge it.
- **Flash at 60°/s over a city** is unmeasured. The lever is a lower rate over tall places, and Legal sees the first readings.
- **Orb may want more than 512 gives.** Their still was on 1,024², four times finer than 256. They've now been asked to judge real gen 2 at 512. If it's short, the choices are 256 with a cache, or Simulation's option B or C, each with its cost above.
- **An idea I didn't test:** bake the view's far map on the GPU, a few frames for a 512² map. It's float32 and not deterministic across GPUs, so it could never feed the sim or the near ground. Worth one spike only if the load bill turns out to be the blocker.

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
