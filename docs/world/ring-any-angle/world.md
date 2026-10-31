# A bearing change at any time: what the world layer blocks (World, research only, 2026-10-30)

EP's ask for Orb's "push this idea to the limit": the angle the fighters fight along the planet's surface changes dynamically, fighters always on the same relative band. Nothing built, no tree edited. Read from `sim/world/epoch.gd`, `docs/world/calm-turn-world.md`, `gen2-read-speed.md`, `shifting-arena-design.md`, `small-circles.md`. Two throwaway probes in a scratch copy of HEAD d219a46c (not kept): `calm_freq` and `angle_probe`.

## 1. The answer in six lines

1. **The world stores everything by ring column (x), none of it by planet position.** A swap keeps every fighter's `x`, so the sim above the world (fighters, beams, AI, camera) never sees a turn. The turn already exists (`WorldEpoch`); the question is what it costs to do it on demand and at big angles.
2. **What blocks "any time" is the ring read, not the swap.** The swap tick is about 2.5 ms (2 ms on a rollback re-run). The ring it swaps to must be read ahead: a Half ring is 2,400 columns, about 130 ms of CPU; a Whole ring 260 to 285 ms. So the choreographer must name the angle 1.3 to 13 s ahead (table 3), or the world reads a fan of rings it may not use.
3. **The second block is the world's calm test: true on 57.7% of ticks** in 28,800 ticks of AI-vs-AI (section 4), with waits to the next calm tick of up to 38 s. That is the world's half only; Encounter's hold comes on top.
4. **A turn's loss does not grow with the angle.** What is kept is a zone round the pivot (`carryUnits` 12,000 each way, capped at a quarter of the loop), in ring coordinates; everything outside is replaced. The angle decides how different the replaced ground is, and how badly the blend across 3,000 to 12,000 units fits (table 5).
5. **The sim's own rule for the angle is wrong above about 10 degrees.** `tick()` gates on `s x sin(angle) <= moveMax`; the real shift of a point `s` along the old line is the chord `2 s sin(angle/2)`. They agree to 0.4% at 10 degrees, are 13% apart at 60, and at 180 the rule passes any `s` while the chord is `2 s`.
6. **The data stops the angle, not the code.** A fight's turn is at most 10 degrees, 4 a fight, 60 s apart, 40 degrees of drift (`rings.json` `turn`, schema-gated). The campaign's turn goes to 60 (`campaign.json`, off). The code takes any angle: I read rings at 2.5 to 180 and -90 (section 5). I did **not** run the swap itself above 10 (fight) or 60 (campaign).

## 2. What binds to columns

Every row is indexed by ring column or by `x`. "Today" is what `WorldEpoch.swap` does. The zone is `Z1 = min(carryUnits 12,000, W/4)`: Close 9,600 each way (50% of the ring kept), Half 12,000 (31%), Whole 12,000 (15.6%); the fully held core `Z0 = Z1/4` is 2,400 / 3,000 / 3,000.

| State | Today | In planet coordinates |
| :--- | :--- | :--- |
| Ground `base` | Kept within Z0, smoothstep to the new ring's by Z1 | Not carried; the new ring's own read |
| Marks `deform`, `rubble`, `scorch`, `crack` | Faded out by the same weight; gone beyond Z1 | A bowl list (the wear list's `wearMarks` / `applyBowls`, already planet-framed) covers craters only: beams, slides and heaps write `deform` directly and are lost unless turned into records first |
| `aftermath`, `aftermathT`, jobs | Zeroed where the weight is 0.5 or more; jobs outside dropped | Needs records |
| Craters, slides (records, up to 400) | Kept within Z1 | Already points: re-project |
| Water `S.water`, `waterWin` | **Re-initialised from the new ground** (`WorldWater.init`: the sea and its laps), lakes of the kept core copied back. By my read a fill dug inland, outside a lake, is lost at a turn; I have not run it | Fills are not native (row 5), so they would need records |
| Buildings (hp, floors, fmask, fdmg, people) | Kept within Z1 as they stand; the list is **re-indexed** (`keep + made`) | Identity by (place, plan) is the wear list's key, but a place's layout is generated from its chord, so the same city 10 degrees away is a different layout (12, 12, 8, 16 buildings on four chords; 15 of 32 per-index match) |
| Trees, fires (`tBurn`) | Kept where the weight is under 0.5; a burning tree outside the zone is gone with its front | As buildings |
| Civilians | Counts in buildings (`popAlive`) and `popHist`; casualty ledger untouched. The street crowd is Rendering's | n/a |
| Props, lanes, platforms, biome table | Derived (props from base + biomes + lanes), rebuilt | n/a |
| Lakes, rivers (`planetRing`) | The kept core's stand, the new ring's are planted | Planned from the new ring |
| Anything holding a building index | `f.interior`, wreck ids, the `splashed` list, `lotAcc` go stale at the re-index | This is why the interior chain is in the calm test |
| Director tables | Follow `S.worldId`, claimed again | n/a |

Per-column state is about 35 bytes a column (seven float32 arrays, the biome bytes, 5 more with aftermath on): 84 KB on a Half ring. Carrying it is never the cost.

## 3. The read: what it costs and what lead it needs

Last valid measurement (quiet machine, native, window 20, 2026-10-26): **gen 2 51 to 57 us a column (54 typical), gen 1 14.4 to 16.5.** 28 octaves of lattice noise are 25 of those 51 us, and a bit-exact octave cannot be made much cheaper in GDScript. The whole warm of two Half rings was 285 ms, 59 us a column all in.

**Today I could not measure it:** the machine was at 100% CPU with 65 Godot and Chrome processes, and my probe read 66 to 200 us a column. Marked invalid, not reported.

| Plan | Columns | CPU (54 us) | Lead at k = 32 one ring | At the shipped shared k = 12 (two rings) |
| :--- | ---: | ---: | ---: | ---: |
| One Close ring | 1,200 | 65 ms | 38 ticks, 0.6 s | 200 ticks, 3.3 s |
| One Half ring | 2,400 | 130 ms | 75 ticks, 1.25 s | 400 ticks, 6.7 s |
| One Whole ring | 4,800 | 260 ms | 150 ticks, 2.5 s | 800 ticks, 13 s |
| Read in one tick (no host, no warm) | Half | 130 ms | 8 frames of hitch | the 2026-10-22 "no hitch" rule bans it |

Plus `prepTicks` 6 (0.1 s) after the read. A tick costs `k x 54 us` (k 32 is 1.7 ms, k 64 is 3.5 ms).

**A fan of rings.** Every extra angle is one more ring: the eight bearings of today's data (2.5 to 10, either side) are 1.0 s of CPU on Half. A fan of 15-degree steps over 180 degrees is 12 rings: 1.6 s Half, 3.1 s Whole, and it is **for one pivot**: the ring is through the pair's point, so when the pair move it is the wrong ring (the 3,600-unit median mispredict in Encounter's six matches). Sharing reads between angles does not work for the bit-exact ring; the union of every ring through a point is a disc of radius about 24,000 units, 1.8 million cells at 54 us, 99 s.

**A cheaper look-up exists, not bit-exact.** `WorldFarMap` is a planet-fixed 256 x 256 octahedral height map (65,000 reads, about a second, built over frames) giving any far field by bilinear look-up at about a tenth of the exact read. It is Rendering's far land today. Using it for a sim ring would make a different ground from `readSlice`, so it is a new planet generation (the JS parity oracle and every gen 2 hash move), not a patch.

**A continuous drift is out by design** (`shifting-arena-design.md`: a ring that moves every tick re-lays the per-column state every tick). A rolling turn is affordable in CPU: one Half ring per 5 s is 130 ms / 5 s = 2.6% of a core. What stops it is the caps in the data, and the thin marks lost at each swap.

## 4. The calm test, measured

`WorldEpoch.calm(S)`, the world's half only (no beam, shot, water window, catastrophe, event token, launched body, rush, slide or tower chain). 8 gen 2 Half-ring AI-vs-AI matches (planets 7, 3, 11, 25 at touch 1 and 3), 3,600 ticks each, 28,800 ticks.

| | |
| :--- | :--- |
| Calm ticks | **57.7%**; per match 3.0%, 28.0%, 54.7%, 61.2%, 75.6%, 76.2%, 77.6%, 85.6% |
| Wait from a random tick to the next calm tick | mean 204 ticks (3.4 s), median 0, p90 889 (14.8 s), p99 2,127 (35 s), max 2,313 (38.5 s) |
| Not-calm ticks by cause (a tick may count in several) | event token 3,484, rush 3,458, launched 3,238, slide 2,731, shot 2,609, water window 2,293, beam 865 |

Planet 25 touch 3 was calm on 107 of 3,600 ticks and planet 3 touch 3 on 1,007. I did not break those two down by cause, so I do not know what pinned them. Encounter's `hold` (no exchange, approach, clinch, flip, queued press or finisher) is **not** in these numbers; real availability is lower.

What a swap on a non-calm tick would break, from the code and not from a run: a beam carves and a slide records column ranges; a water window and every fill are wiped by `WorldWater.init`; the building re-index orphans tower chains, wreck ids and the `splashed` list. Each could be carried; the cheapest to lift are `launched`, `rush` and `shot` (they hold `x`, `y`, `z` and nothing column-indexed). The expensive ones are water and the tower chain.

## 5. What an angle does to the ground (measured)

Probe: planets 7, 3, 11, touch 1, Half ring, pivot at the pair's midpoint, 30 ticks in. The old ground against the new ring's read, by distance `s` from the pivot, mean over the three planets. A fighter is about 75 units tall.

| Angle | mean &#124;dh&#124; at s 0-3k (the kept core) | 3-6k | 6-12k | columns off by more than 75, 0-3k / 3-6k | biome differs, 3-6k |
| ---: | ---: | ---: | ---: | :--- | ---: |
| 2.5 | 12 | 43 | 66 | 0% / 17% | 17% |
| 10 | 41 | 114 | 271 | 18% / 53% | 27% |
| 30 | 86 | 240 | 594 | 38% / 71% | 39% |
| 60 | 123 | 340 | 576 | 47% / 91% | 47% |
| 90 | 155 | 358 | 779 | 57% / 69% | 53% |
| 135 | 209 | 738 | 1,748 | 61% / 88% | 65% |
| 180 | 219 | 964 | 2,153 | 67% / 98% | 72% |
| -90 | 153 | 842 | 1,889 | 62% / 90% | 74% |

Reading it: the 0-3k band is the ground we *keep*, so its number is how far the kept ground lies from the planet's true ground (the lie). Under one fighter height up to about 10 degrees (41); two thirds of a fighter by 30 (86), more than one past 60. The biome column includes the settled-ground overlay, so it is high wherever a city sits near the pivot (planet 3 shows 35% at 2.5 degrees for that reason). Across the blend the height changes by the number in the 6-12k column over 9,000 units, a slope of 2 to 14 degrees; the biome table flips at weight 0.5, a hard seam.

**What a fighter feels:** inside Z0 nothing under him changes. Beyond it the ground under him moves by the weight times the difference; at s = 6,000 (weight 0.26) that is 30 units at 10 degrees, 62 at 30, 93 at 90, 250 at 180. A pop only where the new ground is above him. The right gate is that number, read from the warm slice at the swap (the ring is already read then), not `s x sin(angle)`.

Places the new ring holds within 12,000 units of the pivot: 0 to 3 at every angle (a handful of fresh layouts, 0.7 to 2.3 ms each in the preparation). How many of the old ring's places a large turn drops I did not count.

### The smallest and largest angle

- **Smallest.** The data floor is `minDeg` 2.0 (candidates start at 2.5). The cost does not fall with the angle: a 0.5-degree turn reads the same 2,400 columns. The result would also be nothing you can see (12 units of difference in the core at 2.5). There is no cheaper small-angle path in the sim: skipping the carry zone's columns saves 8% and was refused (`gen2-read-speed.md` section 4.5).
- **Largest in the data:** 10 degrees a fight turn (schema), 40 degrees of drift in all, 60 on the campaign's between-columns turn (`campaign.json`, off, no caps). **Largest the code takes:** any. `turned()` is plain geometry and `sliceRing` read it at 2.5, 10, 30, 60, 90, 135, 180 and -90 degrees on three planets with no error. Same cost at every angle (about 130 ms of reads for a Half ring); the swap's preparation grows with the places to lay fresh, 0 to 3.

### At 90 degrees

1. The pair must sit within `moveMax / sin(90)` = **450 units** of the pivot, or the swap waits, and is refused when even 2 degrees fails. A brawl rarely holds that. The chord is 1.41 s, so the true limit is 318.
2. Kept ground is off by 155 on average in the core, 358 at 3-6k, and the biome table disagrees on 45 to 75%.
3. A planet-faithful carry keeps only what stays inside the playable depth band (z from +375 to -2,025, 2,400 deep): an item `s` along the old line is `s sin(a)` off the new one, so it stays in view for `s <= 2,000 / sin(a)`: all of Z1 at 10 degrees (11,500), 4,000 at 30, 2,300 at 60, **2,000 at 90**. Today's ring-coordinate carry keeps the whole zone and puts the old scene on the new ground; that is why a turn of any size works in the core and why the far land must turn to match (Rendering, cosmetic).
4. The 40-degree drift cap makes it unreachable in a fight.

### At 180 degrees

1. `turned(180)` makes the circle tangent to the old one at the pivot on the other side, run backwards. The centre is still on the left of the travel, so it is a legal ring (the epoch refuses only rings with the centre on the right, `side -1`).
2. It is the full-size read, no shortcut. The same circle reversed would be free (mirror the arrays about the pivot) but has its centre on the right, which the epoch does not start today; I have not worked out why that case was left out.
3. The `s sin(a)` rule is 0 at 180 and passes every pair. The chord is 2s: ground 3-6k from the pivot is 964 units off.
4. The screen turns around: what lay ahead on the right is now the old left. With the pair's `x` fixed and the core carried by `x`, nothing near them changes; the camera and the far land are what show it. Whether the controls and the camera mirror is Camera's and Controls'; the lane band (front kerb z +375, back -2,025) is not symmetric, so "the same relative band" has to mean the band stays put in `z` and the world is what turns.

## 6. What World could do next, in order of cost

1. **Fix the gate (small, mine).** Gate the swap on the real ground change under each fighter, `w(s) x dh`, read from the warm slice, and use the chord. Needed before any angle over 10 degrees. Moves nothing at 10 or under.
2. **Carry the water and the building indices (medium, mine, grant for any state field).** Lets the swap happen in a beam, a rush, a slide, a shot or a launch, and keeps inland fills. Raises the 57.7% calm figure toward the director's own hold. Not run, not sized beyond the above.
3. **A read-ahead fan (needs Encounter's data and Simulation's `k`).** Pre-read two or three angles round the current heading at low priority through `readAhead`. 130 ms a ring on Half; the pivot has to be re-aimed as the pair move.
4. **Choose the angle by the places it brings, not by degrees.** With ring-coordinate carry the angle only matters beyond Z1, so the choreographer's real lever is *which places lie along the new route*; `WorldEpoch.candidates` already returns those per bearing.
5. **A sim-visible ground from a planet-fixed cache (large, new gen).** Section 3's `WorldFarMap`-style lookup made exact would give any angle at near-zero read cost. It changes every gen 2 hash and the JS oracle. I do not recommend it before the above are tried.

## 7. What I could not measure

- The ring read on a quiet machine today (100% CPU); the figures in section 3 are window 20's.
- The swap itself above 10 degrees, and any turn in play (no host).
- What pinned planets 25 and 3 at touch 3 to 3% and 28% calm, and Encounter's hold on top of the world's.
- Whether an inland fill really is lost at a turn (read from `WorldWater.init`, not run).
- How many old-ring places a large turn drops; how a 60 to 180 degree blend looks (heights and biome table measured, not drawn).
- Anything about Camera, Rendering or the controls at a reversed heading.

## 8. The 2D field (the turntable, E and E2): what it costs and needs on real planet ground (World, 2026-10-31, no Godot run)

Orb picked the turntable: a planet-keyed field of ground round the pair, the strip re-laid from it, the world swinging round the fighters. Research's archField (`research/ring-any-angle/sim.js`) holds a cube-sphere grid of nodes at spacing G inside 12,000 units of the pair, bilinear look-ups, and the planet store. This section reads it against the gen 2 code. **Nothing here is measured on gen 2**: the EP's no-Godot rule stands. Where a number is derived I say from what. A probe that measures item 8.1 on the first quiet window is written and unrun, uncompiled: `docs/world/ring-any-angle/field_probe.gd.txt` (copy it to the project root as `field_probe.gd` to run).

### 8.1 Relief error by node spacing, and the shore

The gen 2 surface is the same lattice noise as gen 1 plus creased landforms. The finest smooth feature is the surface detail, scale 1,500 over 3 octaves: **375 units** a cell (`planet.json`); then rock 625, shelf 1,250, the ranges' ridges 1,600, canyons and rifts 6,000. Nothing smooth is finer than 375, so a node every 128 gives three nodes a cell.

**The floor is gen 1's table** (Research, along one great circle, RMS / max): 64 u 0.5 / 11, 128 u 0.7 / 17, 256 u 1.6 / 27, 512 u 4.7 / 60, 1,024 u 16 / 184. Above 256 it follows RMS of about 1.5e-5 x G squared. Gen 2 can only add to it, at **creases**: the plate-edge ranges (amplitude up to 6,500), rifts (1,500), canyons and the polar edge are `abs`-type and threshold shapes, where linear interpolation misses by about (change of slope) x G / 4 at the kink. I did not measure how often or how steep, and the data holds only amplitudes, so any number I put on it would be a guess.

**The shoreline is a threshold on height** (`SHORE_WET` -18.75, the sea at 0, the open sea below -240), so its position error is the height error over the beach slope. The beach is the shelf: noise amplitude 14 over 2,500 units, slopes of about 0.03 to 0.07. With the gen 1 RMS as the height error (a floor), the shoreline sits off by about:

| Node spacing | Height RMS (floor) | Shore off at slope 0.05 | at 0.03 |
| ---: | ---: | ---: | ---: |
| 64 | 0.5 | 10 u | 17 u |
| 128 | 0.7 | 14 u (under half a column) | 23 u |
| 256 | 1.6 | 32 u (one column) | 53 u |
| 512 | 4.7 | 94 u (3 columns) | 157 u |
| 1,024 | 16 | 320 u (10 columns) | 530 u |

**So the shoreline is honest near the pair (within one column, 32 units) at 128, or 256 on the steeper beaches; further out 512 holds it to about three columns (a fighter is 2.3 columns wide), which a camera 10 km away will not show.** A two-ring field does both: 128 within about 3,000 units of the pair, 512 out to 12,000. Nodes in a disc of 12,000: 110,447 at 64, **27,612 at 128**, 6,903 at 256, **1,726 at 512**, 431 at 1,024. The two-ring field is about 1,730 nodes at 128 (the inner 3,000) plus 1,700 at 512: **about 3,400 nodes, 190 ms to fill native** (54 us a node, my arithmetic from window 20's column cost; a bare surface read may be less).

**Cost of moving it** (arithmetic): a node is read when a re-laid strip column first needs it, then kept. Flying 1,032 units/s uncovers `24,000 / G` nodes every `G` units: 1,512 nodes/s at 128 (82 ms/s native, 8% of a core, 33% on the laptop at x4), 94 nodes/s at 512 (5 ms/s). A 30 degree swing sweeps `r^2 x angle / 2` = 3.0e7 square units at r 10,688: 1,823 new nodes at 128 (98 ms, over the 1 s the turn takes at 30 degrees a second) and 114 at 512 (6 ms). That agrees with Research's E: 43 reads a tick on average, p99 337.

**Rivers, shores and lakes, called out.**
- **Rivers** are cut 4 to 24 columns wide (128 to 768 units), the channel snapped to the lowest ground within `reach` of a geometric crossing, and at most one crossing in 3,000 units kept (`rivers.json`, `WorldRivers`). That cannot live in the nodes: a 128-wide channel is one node at 128 spacing and nothing at 512. The flow lines are already planet-keyed (a 192 x 96 grid, about 800 units a cell), so a river stays where it is as the view swings, but **the carve and the "one in 3,000" rule are properties of the strip's line**. They must be redone on the strip each relay from the planet's flow lines, and the gap rule must become a planet rule or go; otherwise a river blinks in and out as the line swings across a comb of crossings.
- **Lakes are planned on the ring's own height line** (`WorldLakes.plan`: a local minimum of `base` walled by a crest on each side along the line, flat at the lower crest, up to 480 columns). That is a 1D property. A valley walled on both sides along one bearing can be open along another, so a lake would appear and vanish as the world swings. A field world needs the lake as a 2D basin with one planet level (a priority flood, as the rivers already do on the 192 x 96 grid, but at node scale), planned once per basin and cached, the strip only reading it. Without that the turntable has flickering lakes.
- **Shores** are the threshold above: honest at the spacings in the table.
- **The common fix:** the field holds heights; water, rivers and lakes are planet-keyed records read through it, not things planned on whatever line is in view.

### 8.2 What the field holds beyond height

| Layer | Source today | In the field | Lazy? |
| :--- | :--- | :--- | :--- |
| Height | `surfAt` | Node value, bilinear | Yes: a node is read when a strip column first needs it |
| Biome (stored) and fine biome | The same `surfAt` call and the climate | A byte a node, nearest node, never interpolated; a border is off by up to G/2 | Yes, read with the height at no extra noise |
| Sea and shore water | `WorldWater.init`: the sea reservoir and its laps along the strip | Derived on the strip from the heights | Yes, each relay; needs a margin at the window's edge (the laps start at the sea) |
| Lakes, rivers | Planned on the ring's line (8.1) | A planet-keyed 2D basin and flow-line record | Planned once per basin and cached, read lazily |
| Lake floor | `WorldWater.floorAt`: surface less feet(depth), depth from the undug bed | The undug bed is exactly the field's value, so it gets simpler and truer | Yes |
| Trees | `WorldGround.layTrees`: placed by column index and the slice's hash | **Not planet-keyed**: the same grove would re-roll when the line swings. Needs a hash keyed by planet cell (a new gen: every gen 2 world's trees move) | Yes once cell-keyed |
| Props | `propsIn` from base, biomes, lanes, minus lake strips | Derived | Yes (render side) |
| Lanes, platforms | From each settlement's chord and district list | A city's pad is a planet disc flattened in the field (the place's centre and radius exist: `P.px/py/pz`, `P.rad`); lanes come with the plan (8.3) | The pad yes; lanes wait for the plan |
| Sites, outposts | Held places of the ring | Planet places by position, within the view | Yes: the place list is small and eager |
| Fires, hurt trees | `TreeState.tBurn` | Part of the object store (8.4) | State, not derived |

**State, not derived:** marks, fills and flows, buildings' hp and people, burning. The strip becomes a view; `S.base` changes on every relay, so the state hash folds the view frame and the store length instead (Research's E does this) and Simulation owns that line.

### 8.3 Places: a city laid along one chord when the view swings across it

Today a place's layout is generated from its chord (`WorldPlanetWorld.settle`) and a different chord makes a different layout: Bellgate came out as 12, 12, 8 and 16 buildings on four chords, with 15 of 32 per-index matches (`calm-turn-world.md`). The calm turn avoids this by carrying the zone's buildings as they stand and laying a place again only outside it, and the zone (12,000) is wider than the camera's half-view (10,667), so nothing the camera sees is re-laid. A turntable breaks that, because the view itself is what changes: the places that swing into view are new ones.

- **Re-laying a visible city while the view turns** pops buildings in and out in front of the player. Out.
- **Freezing it in strip coordinates** (what the swap does inside its zone) is stable and cheap, but the city then turns with the view instead of with the planet, and its pad does not follow the swing. A city of radius 6,500 has a chord half-length `sqrt(r^2 - d^2)` at lateral offset `d`: 6,500 at 0, 5,766 at 3,000, 4,153 at 5,000. A swing of `dtheta` moves the line's offset at a city `s` away by `s x dtheta`: **6 km away, 10 degrees is 1,040 units and 30 degrees 3,000.** So a frozen layout stays plausible to about 10 degrees; past that its buildings stand off the pad.
- **Shortest honest answer short of plans:** (1) make the pad planet-keyed now (flatten the field in each place's disc, cheap and independent of any layout); (2) lay a city when it first reaches the margin between the camera's half-view and the zone (about 1,300 units, 42 columns, 1.3 s of flight), on the chord of that moment; (3) keep it frozen in strip coordinates while the swing since it was laid is under about 10 degrees; (4) beyond that, re-lay it only while it is out of view or hidden by a cut, or cap the swing rate so the 10 degrees never builds up in view. That is honest for a swing of up to 10 degrees a place, and a slow turn or Camera's cut can hide the rest; it is not honest for a continuous 30 degrees a second round a city in the middle of the view.
- **The proper answer is stage 3's places by plan:** a city is a 2D plan (building positions in its own frame, planet-fixed) and the strip takes the buildings whose lateral offset falls inside the band, with `x` the arc and `z` the lane. Nothing is re-laid and nothing pops, and it gives the lanes too. It is the "generate a city from its own plan" that `calm-turn-world.md` already lists as owed.

### 8.4 The planet store: marks in planet coordinates

Research's store is a log of about 48 bytes a mark (a planet point, kind, radius, depth, id); the strip is re-laid from the field plus every mark within the view (`craterAt` of the arc distance). It works for craters. For the real ground every writer of a mark must become a record:

| Mark | Writer today | A record would be |
| :--- | :--- | :--- |
| Crater (up to 400, `LIST_MAX`) | `WorldCrater.dig` (x, energy, cause, kind) | Already a record: add the planet point (3 float64) and keep the radial profile as a function of arc distance |
| Slide (up to 200) | `WorldSlide` (x0, x1, profile) | A planet segment and a profile |
| Beam scar and `aftermath` | `after.gd` strips and timed jobs, `S.aftermath*` arrays | A polyline with width and kind, plus its timer; jobs keep running in planet time |
| Heaps | Rubble written per column when a building falls (`S.rubble`) | A record per fall: planet point, width, mass |
| Scorch, cracks | Per-column floats, permanent | Part of the crater and beam records, not arrays |
| Fills, flows | `S.water`, `waterWin` (calm-gated now) | A fill level on its crater record; flows as planet-cell state. **A turntable has no calm gate, so a flow in progress must survive a relay** |
| Buildings | `S.buildings` (x, z, place, district) | (place, plan index, planet point), with hp and people as state keyed by the plan index |

The readers are many: `S.craters` 15 files, `S.slides` 11, `S.deform` 14, `S.rubble` 10, `S.scorch` 10, `S.crack` 8, `S.aftermath` 7. They can keep reading the strip arrays if those are rebuilt from the store each relay (668 columns in view times the marks near each: thousands of evaluations a relay). Anything that writes an array directly (beams, slides, heaps) must write a record instead. The store itself is small (400 + 200 records is under 30 KB); a snapshot holds only its length and a rollback truncates it (Netcode's rule, in Research's E).

**Is the parked `cancel-keep` fix still needed on this route? Not by the field itself; yes while the swap stays.** The field has no pick and no ring job: a node is a memo of a pure function, held outside the state, and a lookup that misses reads one node, never a ring. What carries over is Netcode's rule, not my code: the node cache must be content-keyed and never discarded inside the rollback window, or a rollback re-reads nodes on the rollback frame (a dropped cache of 1,727 nodes is about 93 ms). The calm-turn swap is what the preview runs, so `cancel-keep` stays parked and needed there until the field replaces it.

### 8.5 What I could not measure, and what the next window should run

1. `field_probe.gd`: gen 2 relief error by spacing 64 to 1,024 on four planets, with the shore, mountains, lakes and the post-pass told apart, and the shoreline's displacement. It replaces 8.1's derived table.
2. Node read cost: a surface read per node (without the ring bookkeeping) against 54 us a column.
3. How many creases the ranges and rifts give per 1,000 units (decides whether 128 holds mountains).
4. Nothing on rivers, lakes or trees has been run with a swinging view; the claim that lakes flicker is from reading `WorldLakes.plan`, not from a run.

## 9. Against Game Design's swing rulings and Netcode's strip (World, 2026-10-31, no Godot run)

Read: `game-design.md` (rulings for the turntable) and `netcode.md` (the narrow sim strip). Every number here is arithmetic, a count from the code, or a figure from the earlier probe in section 5 (which was measured, gen 2, three planets). Nothing was timed.

### 9.1 Test 7: does the world turn as a solid thing?

The part that is World's is which layers of the strip are continuous in the swing angle and which jump. The ground profile at z = 0 is the planet cut by a line, so as the line turns, a far column's height changes because a different bit of planet is under it, not because anything pops. How fast, measured: the section 5 probe gave the mean change of height at the same column between rings turned by 10 degrees: **114 units at 3 to 6 km from the pivot, 271 at 6 to 12 km**. Over small angles that is linear (a point 4,500 away moves 79 units sideways in one degree, less than the 375-unit cell of the finest noise), so one degree a tick (the peak 60 degrees a second) changes the ground **about 11 units a tick at 4.5 km and 27 at 9 km** (0.15 and 0.36 body heights a tick), and the brawl rate of 10 degrees a second one sixth of that (2 and 4.5 units). A fighter standing within 1,500 units of the pivot sees under 4 units a tick at the peak.

| Layer | Continuous in the angle? | What to do |
| :--- | :--- | :--- |
| Height | **Yes**: bilinear in the nodes is continuous, and a mark is a function of distance. A crease (a ridge, a rift) is continuous but its slope jumps | Nothing |
| Marks (craters, scars, heaps) | Yes, evaluated from planet distance | Nothing, if every mark is a record (8.4) |
| Biome border | **No**: the nearest node's biome moves in steps of the node spacing (128 units, four columns) as the line sweeps | Take the biome of the heaviest bilinear weight and the border moves in smaller steps; or accept steps at the far spacing (512) where nobody looks |
| Lakes, rivers | **No**, as built (8.1) | Planet-keyed (8.1) |
| Trees, props | No, as built (a grove re-rolls, 8.2) | Planet-cell keyed |
| Buildings | Only if they have planet poses (9.2) | Poses from a plan |
| Water fills, flows | No: a column's water is lost when its column is re-laid | A record on the crater or a planet cell |

A solid turn also needs the ground *beside* the line to exist, because a side-on strip is only a cut. The near strip alone looks like a profile that morphs, whatever the numbers; it looks like a turn only if Rendering draws the ground off the line as rows of the same field (the field has them: it is the 2D object). So **World can supply a 2D read of the field to the view** (`WorldPlanet.farField` already reads a block of depths beside a ring), and the sim keeps the cut. That is where Rendering and World share test 7. Whether it reads as solid is the look gate's, not mine.

### 9.2 Towns: the shortest honest answer

Why towns first: a **town is small and a city is not**. A town's radius is 2,437 units (a chord of at most 4,875, 152 columns, well inside the camera's 21,333-unit view and the carried zone), a city's 6,500 (chord to 13,000). Their layouts are chord-dependent today (`WorldPlanetWorld.settle`; Bellgate laid as 12, 12, 8 and 16 buildings on four chords).

**Shortest honest answer: lay each town once from its own plan, planet-fixed, and give it a pose in the strip.**
1. **A plan, not a chord.** The town's buildings are generated in the town's own frame: a handful of rows and columns about a centre and one street axis, a pure function of (planet seed, place id), some tens of buildings for a town (`calm-turn-world.md` compared 32 and 37 per-index matches for a city and a village). The same function the layout uses, run on a fixed axis instead of the chord. This is stage 3's "places by plan", kept to the small case.
2. **A pose from the frame.** For a building at planet offset (u, v) in the town frame, the strip gives its arc `x` and its depth `z` by one rotation each (the line's direction and side at the town's centre). A building inside the band (z from -2,025 to +375) is in the sim; outside it, it is a Rendering object only, which is how the world stays solid at the band's back and front edge.
3. **A footprint that does not turn.** The strip uses the building's bounding circle (radius half the larger of its width and depth) for every contact, so a swing never changes what the sim thinks it hits; Rendering draws the box turned. This is the one simplification that stays honest at any angle, and it is lossy at the corners.
4. **No street lanes in a swing.** A turned street is not a lane. The lane table is rebuilt per layout today (`WorldLanes.build`, whole arrays); in a swing the clearance comes from the footprints instead (9.3).
5. **Cities stay as in 8.3** (frozen in strip coordinates, honest to about 10 degrees, re-laid out of view) until they have a plan, and the director steers swings over towns and open ground, which is Game Design's own rule ("honest only over open ground until places are by plan"). A town on a plan is the first place the swing can go through.

What this costs: a plan function for towns (a new generator, off in the data until built), a pose update for buildings in the strip each swing tick (9.4), and a data field on each building for the plan index (already `plan` in `BuildingGen`). The 44 towns of a planet are 44 small plans, computed lazily when first in view.

### 9.3 Standing fighters sweep at most 75 u/s: the arithmetic, and the face

**GD's table checks.** Rate = ground speed limit / distance from the pivot, in radians a second. Both standing, pivot the midpoint, so r is half the gap: gap 150 (r 75) gives 57.3 degrees a second, 300 gives 28.6, 1,000 gives 8.6, 3,000 gives 2.9, 6,000 gives 1.4. One standing, the pivot is that fighter and the other is airborne at the 6,000 limit: gap 5,700 gives 60.3 (capped 60), 15,000 gives 22.9, 30,000 gives 11.5. All as stated. **One slip:** the text says the chord over a whole turn is `s sin(theta/2)` for a pair turning about their midpoint; the chord is `2 s sin(theta/2)`, twice that. It does not touch the rates (an instantaneous speed is `r x omega`); it matters for how far the ground has moved in the whole turn (a 90-degree swing at r 150: 212 units, not 106).

**Why the face is not a separate speed.** A building that covers a standing fighter's `x` is at the same arc distance from the pivot as he is, so its face approaches the fighter's plane at the same speed as the ground under him, at most 75 units a second. The limit that protects his feet protects against the face for the buildings in his own `x`.

**Stopping 0.5 body heights short.** The clearance is 37.5 units. At 75 units a second the 20-tick ease takes `75 x (20/60) / 2` = 12.5 units, one tick 1.25. So the swing must be braking when the face is **about 50 units** from the clearance line, and a lookahead of a few ticks (about 5 units) beyond that.

**Finding the face cheaply.** Each tick of a swing, for each standing fighter:
1. Ask the spatial index (`S.bIdx`, buckets of W/128 = 600 units on a Half ring, built by `WorldStructures.buildIndex`) for the buildings whose centre is within the widest half-width of his `x`. That is one to five buildings.
2. For each, the gap in depth to the nearer face on the side the ground is moving from: `gap = |z_b - z_F| - d_b/2 - bodyRadius` (or with the bounding circle, `|z_b - z_F| - radius_b - bodyRadius`).
3. Cap the rate: `rate = min(rate, (gap - 37.5) / T_ease / r_F)` with `T_ease` 0.33 s. When `gap` is at most 37.5 the rate is 0 and the swing is at rest.
That is one bucket scan and a handful of operations per standing fighter: **about 5 microseconds a tick**, run only while a swing runs. It is the same query as `depth.md` section 2's clearance and the same index as the contact tests, so nothing new is stored. It reads the building's pose for this tick, which the pose update (9.4) has just written. The director should still steer the bearing off a face; this is the backstop, as GD says.

### 9.4 Netcode's 170 to 300 columns: does the sim strip fit, and how do buildings follow the frame?

**Columns.** Netcode: about 170 to 300 columns (5,400 to 9,800 units) re-laid on re-simulated ticks at a 200 ms ping.
- The sim reads ground at: each fighter's column, a melee's reach (hundreds of units), a flight's contact ground, a beam's carve path, the launch planner's candidates (up to a sixth of the loop each way: 400 columns on a Half ring) and the director's scans.
- **A window of plus or minus 40 columns (1,280 units) round each fighter is 81 columns each; two windows are 162, under 170.** In a brawl (gap under 600 units, 19 columns) the two overlap and the union is 99 to 110 columns. A window of plus or minus 75 columns (2,400 units) is 151 each, 300 for two, the top of the range, and about 170 in a brawl.
- **Fighters far apart** (a launch, a chase) are two separate windows that move; a window moving at 6,000 units a second takes in three new columns a tick, which is the existing conveyor and is not a re-lay.
- **What does not fit and must take coarse ground:** the launch planner's 400-column scan and any beam longer than the window. These are Netcode's "far readers" (469 ground reads and 170 `S.base` reads, unaudited). From the code, the ones that matter for correctness (a landing, a contact, a beam's carve) are within the windows; the ones that only score or look ahead (the planner, the director's lure, `popHist`) can accept coarse ground. I have not audited the 639 sites, and I would not trust my reading of that many without a pass by Simulation.
- A re-lay of a window is a bilinear look-up per column. Research's estimate is 1.7 to 3 ms for 669 columns, 2.5 to 4.5 microseconds a column, **unmeasured**. At that, 162 columns is 0.4 to 0.7 ms a tick.

**Buildings, the unknown.** They are not in Netcode's numbers. How they follow:
- A building needs its pose, `x` and `z`, from the frame: two rotations of its planet offset. In the sim that pose is now in `BuildingGen` (`x`, `z`, sealed records shared by snapshots). A frame-driven pose cannot live in sealed records rewritten each tick; it moves to **two bound arrays, `bX` and `bZ`**, written in place like `bHp`, with `BuildingGen` keeping the plan offset (u, v) instead. Readers of a building's `x` and `z`: 36 files read `S.buildings` and about 53 sites read a building's `x` or `z` in structures, collateral and brunt alone. That is the migration and it is Simulation's (a grant), not a small one.
- While a swing runs, a building's `x` changes too, not only `z`: a building at lateral offset `l` slides along the line by `l x omega`. At 1,000 units of depth and the peak rate that is 17 units a tick. The index needs a bucket update only when a building crosses a 600-unit bucket, about once in 35 ticks at that offset; rebuilding the whole index (`buildIndex`, every building) each swing tick is the simple version and costs microseconds for the 20 to 150 buildings a window holds.
- **Cost:** two rotations and two writes a building, about 2 microseconds in GDScript (an estimate, unmeasured). A window holds 10 to 40 buildings in open country or a town and 100 to 150 in a dense city stretch (about one building a 1,000 units on average per the W7 densities, four in a city). So **20 to 300 microseconds a swing tick, against 0.4 to 0.7 ms for the columns.** On Netcode's table that adds up to about 2 ms to the 7 re-simulated ticks of a 200 ms ping at the dense end: 10.2 to 12.6 ms becomes about 10.3 to 14.7. **So buildings fit at the low and middle of the estimates and break the 12.5 ms budget at the top, in a dense city only.** The fix for the dense case is the one already chosen for cities: buildings stay in strip coordinates inside a city and only towns have poses (9.2), which makes the dense case free.
- **State and the hash:** a pose is derived from the frame and the plan, so only the frame and the plan index go in the hash; the arrays themselves are rebuilt on a restore. Hit points and people stay in the arrays they are in (`bHp`, `bPopAlive`), keyed by the building's index, which no longer moves because the list is not re-ordered by a swing (a swap re-indexed it; a swing does not).
- **The index must not change in a swing.** The calm-turn swap rebuilt `S.buildings` (`keep + made`) and the index, which is why a tower chain and a wreck id needed calm. A swing that only moves poses keeps every index, so those readers survive it. A building that enters or leaves the window's band is a flag on the same record, not an insertion.

### 9.5 Is there a place worth arriving at within launch range, at any bearing?

Game Design's launch is at most a sixth of the loop (3d): Close 6,400, Half 12,800, Whole 25,600; a full launch (1.6 s at 6,000 units a second) is about 9,600. A place is "arrived at" when the launch's line passes within its reach (`cityReach` 0.6 x 6,500 = 3,900, `townReach` 0.7 x 2,437.5 = 1,706, the rule `WorldEpoch._held` uses), and the bearing is free, so a place counts if its centre lies within range plus reach of the pair, whichever side it is on. The planet has 12 cities and 44 towns (`planet.json`), so about one place to every 134 million square units, a mean spacing of 11,580.

**Average over the sphere** (arithmetic, places treated as uniform; the real ones sit on land with height 60 to 1,800 and latitude under 0.8, so near land the density is higher and over the sea lower):

| Range | A city within reach | A town | Any place |
| ---: | ---: | ---: | ---: |
| 6,400 (Close) | 41% (0.52 expected) | 70% (1.2) | **82%** (1.7) |
| 9,600 (a full launch) | 59% (0.89) | 90% (2.3) | **96%** (3.2) |
| 12,800 (Half) | 74% (1.4) | 98% (3.8) | **99%** (5.1) |
| 25,600 (Whole) | 98% (3.9) | 100% (12) | 100% (16) |

(The percentages are the chance of at least one, `1 - e^-expected`.) **So on average a place worth arriving at exists within a launch at any bearing about nine times in ten on a Half ring and four in five on a Close ring; a city is a coin toss at a full launch (59%) but a town is nearly always there.** That favours towns, which agrees with 9.2: the swing's usual destination is a town. Over open sea, a far pole or a lone continent it will be less, and I cannot say how much without the planet's actual places.

`place_reach_probe.gd.txt` (this folder, unrun and uncompiled) measures it on eight real planets: the share of 2,000 spread points with a city, a town or either inside each range, all points and land points. It replaces the table above.

### 9.6 What I could not check

- Everything in 9.4 about cost is arithmetic from Research's unmeasured 1.7 to 3 ms and my 2-microsecond-an-operation guess. A 3x miss takes Netcode's limit to 60 to 100 columns.
- The far-reader audit (639 sites).
- Whether Rendering can draw ground rows off the line from the field (test 7).
- Whether a bounding-circle footprint is acceptable to Combat for the building contacts.
