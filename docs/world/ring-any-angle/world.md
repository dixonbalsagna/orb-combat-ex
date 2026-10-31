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

Orb picked the turntable: a planet-keyed field of ground round the pair, the strip re-laid from it, the world swinging round the fighters. Research's archField (`research/ring-any-angle/sim.js`) holds a cube-sphere grid of nodes at spacing G inside 12,000 units of the pair, bilinear look-ups, and the planet store. This section reads it against the gen 2 code. **The numbers in 8.1 were derived, before the probe; section 11 has the measured gen 2 figures and supersedes them where they differ (gen 2 error is 3 to 7 times gen 1's).** Where a number is derived I say from what. A probe that measures item 8.1 on the first quiet window is written and unrun, uncompiled: `docs/world/ring-any-angle/field_probe.gd.txt` (copy it to the project root as `field_probe.gd` to run).

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

## 10. Rendering's questions (`rendering.md` section 5) and Game Design's street query (`game-design.md` section 8) (World, 2026-10-31, no Godot run)

(This is the "short section 9" the EP asked for; the number 9 was already taken by the swing and strip answers above.)

### 10.1 Gen 2 reads in 2D at about 4 a tick, and sparse-read error: waiting on the probe

**What I can say now.** A node read is the same `surfAt` as a ring column's: 51 microseconds native on a quiet machine (window 20: 54 typical), of which 25 are the 28 octaves of noise and the rest the plate pairs, trig and the climate and biome arithmetic. A ring column also pays about 3 of bookkeeping the node does not, so **a node is 48 to 54 microseconds, and 4 a tick is 0.19 to 0.22 ms: Rendering's 0.2 ms a tick holds at x1, and the laptop (x4) sees 0.8 ms.** A tile of 289 nodes is 14 to 16 ms of CPU, 72 ticks at 4 a tick, as Rendering has it. These are window 20's numbers re-applied; I have not timed a node read.

Two things may make a read cheaper and I will measure them rather than claim them:
1. **Height only.** A tile's relief needs the continent, relief and surface-detail octaves, about half of the 28; the biome and climate half could come from the far map's 400-unit texels. A height-only node may be 25 to 30 microseconds, which would make the budget 7 or 8 a tick. Unmeasured.
2. **Neighbours share noise cells.** Nodes 128 apart sit in the same 375-unit cell of the finest octave, so the corner memo (99% hits on the ring already) should do at least as well in 2D. Already in the 51.

**Sparse-read error** is section 8.1's table: derived from gen 1's measured figures and the gen 2 constants, with the shoreline off about 14 units at 128, 32 at 256 and 94 at 512. At 128 the surface detail (finest cell 375) needs no extra detail term; platforms, river channels and crater rims are exact marks, not noise, and are layered on the tile anyway. **The measured gen 2 numbers come from `field_probe.gd.txt` when the EP lifts the no-Godot rule**, and I will replace the table then.

### 10.2 2D lakes and rivers, and places by plan: answered above

- Lakes and rivers: **8.1**. In short, a lake is a planet-keyed basin (a 2D flood at a coarse grid, level and extent cached per basin), and a node's water is `max(0, level - height)`; a river is a planet polyline with a width and a carve depth, and a node's depth is a profile of its distance to the polyline. Per-node depth and level, as Rendering asks, fall out of those two records and the heights. The one-in-3,000 river rule has to go or become a planet rule.
- Places by plan: **9.2**. Towns first (the small case), a pose per building from the frame, a bounding circle for the sim; cities frozen until they have plans.

### 10.3 The street query (Game Design's question 3: a street-alignment score inside places)

What the score needs: for a place and an arrival point, the bearings of its streets and how far the arrival lies from the nearest street centre line. Today a city's streets are three lanes behind the laying chord (`lanes.json`: the front street centred on the fighter plane, 375 wide; the mid street 1,012.5 behind it; the back street 2,025 behind it) and avenues across. Planned places will have one grid.

**The interface (World's, a pure function of the place's frame; no state):**

| Call | Returns |
| :--- | :--- |
| `WorldStreets.frame(P, place)` | The place's street grid: centre, `a0` (the bearing of the along-street axis in the planet frame, our own atan2), `pitch` 1,012.5, `width` 375, `phase` (the lateral offset of the street nearest the centre) |
| `WorldStreets.bearings(P, place)` | The offered bearings: `a0`, `a0 + 90°`, `a0 + 180°`, `a0 + 270°` |
| `WorldStreets.align(P, place, q, bearing)` | `d_angle` (0 to 45°, the line's angle to the nearer axis) and `off` (0 to 506: the distance from the planet point `q` to the nearest street centre line along that axis) |
| `WorldStreets.rest(P, place, q, bearing)` | The signed lateral shift that puts a line at `bearing` through `q` onto the nearest street centre line (what Option A's ease needs to know) |

**Cost:** a few dozen operations a call, no scan; finding which place holds `q` is a loop over the planet's 56 places (`P.px/py/pz`, `P.rad`), or the ring's held list. Encounter's score can use `align` as `max(0, 1 - d_angle / 22.5°) x (1 - off / 506)`.

**Until places have plans (honest limit):** for a place laid on a chord, `a0` is the bearing of the chord it was laid on, which the code does not keep (`E.chords` stores columns only); World would record it with the chord (not hashed). Its three streets then lie behind that line at the pitches above, so a city is a **strip 2,400 deep, not a disc**: a line at 40° crosses the rows and clips the strip's ends, and `rest` is meaningful only within a few degrees of `a0`. For frozen cities the query answers "no street" for a line more than about 10° off the laying bearing. For towns on plans it answers fully at any bearing.

**What it needs from others:** Encounter's score and Game Design's weight; Simulation for a place's `a0` in the plan data once towns have plans; nothing in the state hash (derived).

## 11. The probes, run (World, 2026-10-31, HEAD 93102d14; raw output in `probe-results-2026-10-31.txt`)

Both probes compiled (`--check-only`) and ran in a scratch copy of HEAD at below-normal priority, two Godot jobs, no timing taken. **This section supersedes the derived numbers in 8.1 and 9.5 where they differ.**

### 11.1 Gen 2 relief error by node spacing (answers Rendering's sparse-read question)

Method: four planets (7, 3, 11, 25), a Half ring each (2,400 columns), the raw column height (`farColumn`, z = 0) against a straight line between every k-th column. This is interpolation **along the ring**; a 2D bilinear field at the same spacing is the same in kind and somewhat worse on the diagonal, so treat these as a floor. RMS pooled over the four planets, units:

| Node spacing | All columns RMS (per planet) | Max | Mountain RMS | Lake RMS | Shoreline displacement RMS / max | Crossings lost |
| ---: | :--- | ---: | ---: | ---: | :--- | ---: |
| 64 | **3.3** (1.2, 2.9, 1.1, 5.8) | 189 | 1.0 | 0.6 | 17 / 32 | 0 |
| 128 | **5.1** (3.9, 4.2, 3.9, 7.4) | 189 | 3.5 | 2.0 | 40 / 128 | 0 |
| 256 | **11.0** (10.9, 6.7, 10.6, 14.5) | 273 | 10.1 | 6.1 | 81 / 192 | 0 |
| 512 | **22.8** (18.1, 16.3, 24.7, 29.6) | 319 | 21.6 | 20.8 | 59 / 128 | 0 |
| 1,024 | **48.2** (38.6, 42.1, 54.2, 55.7) | 353 | 51.0 | 75.8 | 167 / 448 | 2 of 12 |

- **Gen 2 is 3 to 7 times gen 1's error at the same spacing** (gen 1 RMS, Research: 0.7 at 128, 4.7 at 512, 16 at 1,024; gen 2 is 5.1, 22.8 and 48.2). My 8.1 estimate used gen 1 as a floor and was too kind by that factor.
- **It scales about linearly with the spacing, not as its square** (128 to 1,024, 8 times the spacing, 9.5 times the RMS). That is the signature of creases (ranges, rifts, canyons) and steps rather than smooth relief, which is what I guessed gen 2 would add and could not size.
- **Maximum errors of 125 to 189 units at a spacing of only 64** (planets 3 and 25) mean gen 2 has near-vertical steps that no spacing of 64 or more reproduces. Planet 25's RMS is 5.8 at 64 while its mountain RMS is 0.7, so the steps are outside the mountains; I have not found which landform. At 512 the worst column is 4 body heights off (319).
- **The shoreline** (14 crossings in all, so a thin sample): within one column at 64 (max 32); at 128 usually within a column but once 4 (128); 256 and 512 are 2 to 4 columns; **1,024 is 5 columns RMS and loses a crossing in 2 of 12.** My 8.1 table said 14 units at 128 and 94 at 512. The probe says the 128 figure was optimistic and the 512 one a little pessimistic; both inside a factor of three.
- **Lakes** need 256 or finer to keep their basin: lake RMS 6 at 256, 21 at 512 (a lake is about 40 deep), 76 at 1,024.
- **The post-pass** (platforms, lake carve; rivers off) added at most 13 to 18 units on two of four planets and nothing on the others, so on these rings the exact-mark layer is small.

**What it means.**
1. **If the field defines the ground** (the sim, the render and the places all read it), the error is not an error: nothing else is compared with the exact planet. Cliffs and creases are smoothed, and the ground is a new, smoother planet. Everything planned on the exact heights (lakes, platforms, sites, the golden) must be planned on the field instead.
2. **If the field must match the exact planet** (so the golden, the far map and the old ring agree), it needs 64 near the pair to keep a shoreline to one column, and nothing under 64 fixes the steps.
3. **A near level of 128 is within 5 units RMS but not within a column of the shore on every planet; 512 is 23 RMS, which a player sees as ground that is slightly off, and 4 body heights at a step.** Rendering's "128 near, 512 far" is usable as a look and not as a shore; the shoreline would want a deterministic detail term (a shoreline snap to the threshold on the strip) rather than a finer grid.

### 11.2 A place worth arriving at: measured

Eight real planets, 2,000 evenly spread points each, the nearest city and town less their reach (`cityReach` x radius and `townReach` x radius), fraction of points with one inside the range (all points; land points differ by 1 to 8 points):

| Range | Any place | A city | A town |
| ---: | :--- | :--- | :--- |
| 6,400 (Close) | **81 to 89%** | 43 to 50% | 60 to 69% |
| 9,600 (a full launch) | **92 to 96%** | 64 to 73% | 78 to 89% |
| 12,800 (Half) | **97 to 99%** | 79 to 89% | 88 to 96% |
| 25,600 (Whole) | 100% | 99 to 100% | 100% |

My 9.5 arithmetic gave 82, 96 and 99% for any place and 41, 59 and 74% for a city; the real planets are a little richer in cities (places sit on land, where the fights are) and a little poorer in towns. **The answer stands: on a Half ring a place worth arriving at is in range at any bearing 97 to 99% of the time; on a Close ring 81 to 89% (about 5 times in 6); a town is the usual one (a city is a coin toss at Close, three times in four at a full launch).** The worst planet at a full launch is 92% (planets 7, 9 and 11). No planet is below 81% at the Close range.

### 11.3 The web build's budget: 130 us a column, so about 1.5 reads a tick

**Correction (EP, 2026-10-31; `research.md` T3, `performance.md` 6): 130 us and 1.5 reads a tick are right for ring columns. A plain field node is about 50 us on the web, so about 4 a tick, and the figures below that count nodes at 1.5 a tick are too pessimistic by about 2.7 times (the two-ring field in flight needs 7.9 nodes a tick at 1,032 u/s and 45.8 at a launch against a budget of about 4; the 512 bake is 28,650 nodes, about 1.4 s on the web; the inner 128 ring of 1,727 nodes is about 7 s at 4 a tick). The conclusion stands: the field cannot be fed at the inner spacing in flight, and the bake carries it.** Left as written otherwise.

Performance's change: on the web a read is 130 us, so a tick's read budget is about 1.5 nodes, not 4. What that does to the two-ring field while flying (arithmetic; a node read taken as a column read):

| Flight speed | Two-ring field needs (128 within 3,000, 512 out to 12,000) | Outer ring alone (512) | Budget |
| ---: | ---: | ---: | ---: |
| 1,032 u/s (a flat-out run) | 7.9 nodes a tick (5 times the budget) | 1.6 | 1.5 |
| 3,000 | 22.9 | 4.6 | 1.5 |
| 6,000 (a launch) | 45.8 (30 times) | 9.2 | 1.5 |
| 10,000 | 76.3 | 15.3 | 1.5 |

The spacing that 1.5 a tick can hold, for a disc of radius r in flight at v: at r 12,000 it is 525 units at 1,032 u/s, 894 at 3,000 and **1,265 at 6,000**; at r 6,000, 371, 632 and 894. At 1,024 the probe's error is 48 RMS with max 353 and lost shorelines, so **the field cannot be read as it is flown at launch speed on the web**.

**What does work:**
1. **Bake the planet once at a coarse spacing and read it for flight.** The whole sphere at 512 is 28,650 nodes (area 7.51e9 / 512 squared): 3.7 s on the web and about 1.5 s native, a loading-screen cost, then flight costs no reads. At 1,024 it is 7,160 nodes, 0.9 s. (Rendering's far map is already resident at 400-unit texels: this is the same idea with the sim's heights.) The error is the table's 512 row: 23 RMS.
2. **Refine only where the pair stands still.** The inner 128 ring is 1,727 nodes: **19 seconds at 1.5 a tick**. Too slow after a landing. A radius of 1,500 at 128 is 432 nodes, 4.8 s; at 256 inside 3,000 the same count. So the sharpening Rendering describes needs to start before the landing (a launch is planned: 96 ticks of flight reach 144 nodes) and cannot be a full disc on the web.
3. **A height-only node** (no climate) may be half the cost, taking 1.5 to 3 a tick. Unmeasured.
4. **The native build and the laptop are not the web build**: at 54 us 4 a tick holds there, and the table above is for the web only.

So on the web the turntable is a coarse-then-sharpen ground with a baked planet underneath; the two-ring field as I described it in 8.1 is a native design.

## 12. What a smoother generation would lose on screen (World, 2026-10-31, for Orb's look gate; HEAD 93102d14)

The EP's provisional decision: the field defines the ground, as a new, smoother generation, lakes, platforms and sites planned on its own heights, a whole-planet bake at 512 at load carrying flight. **No gen 3 is being built; this is what it would cost, in plain terms.** The picture is `img/field-profiles.svg` (three real places, drawn from the ring's own columns: black is today's ground, blue is the same ground read every 128 units, red every 512 units).

### What is lost, in words

1. **Cliffs on ice.** Today the edge of a polar ice sheet (and what looks like the edge of sea ice in open water) is a wall one column wide: **249 units in planet 3, 378 in planet 25, up to 433 elsewhere. That is 3 to 6 fighter heights**, a ledge a fighter can stand on the top of or be thrown off. Read every 128 units it becomes a steep slope of about 60 to 70 degrees over 128 units; read every 512 it becomes a ramp of about 25 to 35 degrees over 512 units, the same drop spread across about 16 columns. (Left and middle pictures.) They stop being walls.
2. **Mountain tops get rounded.** Peaks, ridges and the notches between them are up to about 2.5 fighter heights off at worst on a 512 read (192 units on planet 11's 6,000-unit mountain), and about half a fighter height at 128 (37). A mountain keeps its shape and loses its sharpness: the right picture shows a 512 line cutting the ripples of a slope and flattening a peak. On the whole ground, the typical error is 5 units at 128 and 23 at 512 (a fighter is 75 tall).
3. **Shorelines move** by 0 to 4 columns (0 to 128 units): within a column at 64, usually within a column at 128, up to 4 columns at 512. A beach is a little wider or narrower than today.
4. **Lakes keep their basin** at 256 and finer and blur at 512 (the lake's depth is about 40, the error is 21).
5. **What is not lost:** the broad shape of the land, the biomes (they are read, not interpolated), buildings, trees, marks (craters and the rest are laid on top at 32 units), and the sea. 

### How often it matters: measured on 16 rings

| | Columns with a step over 75 units | Over 150 | Largest |
| :--- | ---: | ---: | ---: |
| Per ring of 2,400 columns | 0 to 13 (mean 3.4, 6 of 16 rings have none) | 0 to 4 (15 in all, mean 0.9) | 433 |
| Where | Mountain sides 39%, ice-sheet and sea-ice edges 30%, plains edges 24%, desert 9% | Almost all ice edges | |

So **steps are rare** (at most 0.5% of a ring's columns, 0.14% on average). **The tall ones, over 150 units, are almost all ice edges; the 75 to 150 ones are mountain sides and plains edges.** A fight on a coast, a forest or a city meets none. A fight at the edge of an ice sheet meets one or two, 250 to 430 units tall, and loses them. Mountains are the common place the smoothing shows: they keep their height and lose their crispness.

### What a generation could keep, if Orb wants the walls

- **Ice edges as a mark.** The edge of an ice sheet or a floe is a threshold, like the coast. It could be stored as a planet cliff record (a line and a height) laid on the field like a crater, which keeps the wall at any spacing at the cost of one record per edge. About 3 a ring.
- **A finer near ring only where the pair stands.** A 64 read keeps the ice walls to within 125 to 190 units of today's: not a fix.
- **Or accept the smoother ground** and let the director not choose ice edges as places to fight. Ice is the one biome where the loss is large and the walls were the point.

Nothing here changes if the generation is not built: today's ground is unchanged.

## 13. Can a cheap pure detail term restore what a 512 ground loses? (World, 2026-10-31, measured: `detail_probe.gd.txt`)

The EP's question: at about 1 to 2 cheap operations a sample, how much of 512-unit ground does a detail term restore near a fighter, and how honest is the coastline. Eight rings (planets 7, 3, 11, 25 at touch 1; 9, 7, 1, 5 at touch 3), nodes every 16th column, candidates against the exact column. RMS in units; shoreline = crossings of `SHORE_WET`, 52 in all.

| Candidate | All RMS | Mountain RMS | Shoreline displacement RMS / max | Spurious extra shores |
| :--- | ---: | ---: | :--- | ---: |
| V0 the line between the nodes (a 512 bake) | 23.9 | 21.9 | 203 / 736 | 0 |
| V1 plus the exact surface detail (3 octaves of noise) | 23.6 | 21.7 | 187 / 736 | 0 |
| V1x as V1 with the exact land/sea gate at each column | 23.5 | 21.7 | **105 / 384** | 0 |
| V2 plus 2 octaves of the detail | 25.1 | 23.2 | 188 / 736 | 0 |
| V3 a cubic through four nodes | 22.5 | 19.0 | 152 / 576 | 0 |
| V4 plus a one-op hash noise of matching amplitude | 33.7 | 32.4 | 98 / 384 | 2 |

**The answer is no, for relief.**
1. **The surface detail is not what a 512 bake loses.** Adding the exact 3-octave noise (a few microseconds, about 100 operations, not 1 to 2) moves the error from 23.9 to 23.6. The loss is in `WorldLand.shape`: the ridged ranges (`abs` creases), the shoreline noise band, the plateau terraces (`floor` steps) and the canyons (`abs`), each of which acts on the running height. None has a closed-form residual a cheap term can add.
2. **A cubic helps a little** (22.5, mountains 21.9 to 19.0, 13%) at four nodes a sample, about 12 operations. It cannot make a crease or a terrace.
3. **A one-op hash noise makes the error worse** (23.9 to 33.7, as added uncorrelated variance must): it can give the ground texture, not truth, and it invents two shorelines that are not there. If the aim is only that smoothed ground not look smoothed, that is a Rendering look; the sim should not read it.
4. **The only term that does restore the creases is `shape()` itself** run per sample on a baked smooth height: the plate terms plus about five lattice noises, roughly half of a gen 2 column read (25 microseconds of 51 native, so about 60 on the web). Too dear per sample for a 162-column re-lay on re-simulated ticks (about 10 ms a tick on the web).

**Honest coastline: the gate is what matters, not noise.** The shoreline moves 203 units RMS (worst 736, 23 columns) on a bare 512 bake in these eight rings (ice rings included; the four plain rings were within 59 RMS, 128 max, in section 11). **Giving each column its exact land or sea answer (V1x) halves it: 105 RMS, worst 384.** So a land/sea mask at the column or 128-unit scale does more for the coast than any noise term. The honest answer is to store the **crossings** themselves: a coast is a line, and a field with a planet record per coast segment (like a crater, as section 12 suggested for ice edges) puts the shore exactly where today's is. About 3 to 6 crossings a ring, so a few records.

**What this means for the bake.** Bake cells of 326 to 652 units are the 256 and 512 rows of section 11: all-column RMS about 11 to 23, mountain crests up to 2.5 fighter heights off, shores about 100 to 200 units off without a mask. Near a fighter that is the look of a smoothed planet, which the EP's decision accepts; the three things worth adding are (a) a coast and ice-edge record layer (exact shores and walls, few records), (b) optionally a cubic reconstruction in place of the line (6% and 13% on mountains, free for the view, 12 operations for the sim), and (c) nothing noise-based in anything the sim reads.

## 14. With no laptop ceiling: how near today's planet can the sim's one ground stay, and how do edges and detail scale (World, 2026-10-31; ADR 0012; measured where marked, HEAD 93102d14)

ADR 0012 item 3 fixes the frame: **the sim is shared**, so every machine computes the same ground. The question is therefore not what a capable machine can afford per tick (that is the view's). It is what the shared ground may cost the oldest machine, and the answer moves a lot once you see where the cost sits.

### 14.1 The cost of fidelity is loading time and memory, not per-tick work

A bake is a pure function of the planet's seed, made once and read by lookup. A sim tick pays only the lookup (a bilinear read is about 12 operations, a cubic about 50). So **a finer bake costs the old laptop a longer load and a few megabytes, and nothing per tick.** The planet load is already a stepped job that gates the match start (`planet_load.gd`: 250 units a read, about 5 ms), so every machine finishes it before tick 0 and the result is identical whatever the speed.

Whole-planet bake (5 bytes a node: a float32 height and a biome byte). Load times use the EP's 50 us a node on the web and my estimate of 2.4 times faster native (the ratio of 54 to 130 us a column); the old laptop is the web column or slower:

| Spacing | Nodes | Memory | Load, web | Load, native (est.) | Sim ground vs today's exact (RMS along the ring; Simulation measured 8.5 in 2D at 128) |
| ---: | ---: | ---: | ---: | ---: | :--- |
| 512 | 28,650 | 143 KB | 1.4 s | 0.6 s | 23 (crests 2.5 fighter heights off) |
| 256 | 114,600 | 573 KB | 5.7 s | 2.3 s | 11 |
| **128** | 458,400 | 2.3 MB | **23 s** | 9 s | **5.1** (max 189 at steps) |
| 64 | 1,833,600 | 9.2 MB | 92 s | 37 s | 3.3 |
| 32 (today's ring columns) | 7.3 million | 37 MB | 6 min | 2.5 min | 0 |

Reading it: **256 is a loading screen on any machine. 128 is a lobby-time background job** (the planet is chosen before the match; 23 s on the web, 9 native) and 2.3 MB. 64 and below is not a load. So the shared ground can sit at about **5 units RMS from today's exact planet** at the price of a 23-second planet load on the weakest machine; at 11 for a 6-second one.

**Fidelity is then a match setting both players share** (like the arena's size: it goes in the match key and the replay header), not a per-player one. A performance mode that wants a 6-second load picks 256 for the planet; a maximum mode picks 128; a replay carries which. The view's quality stays a per-player setting.

**Adaptive refinement.** Measured on eight rings, nodes at 512: **26% of the 512-unit cells hold a column more than 20 units off, 13% more than 40, 5% more than 75; at 128 only 1.9%, 0.6% and 0.4%.** The loss is concentrated. Refining only the bad cells to 128 would cost 148,000 nodes for the 20-unit rule (a third of a full 128 bake), 90,000 for the 40 rule and 52,000 for the 75 rule. **The catch: picking the cells.** I tried the cheapest predictor from the 512 nodes alone (the larger second difference at a cell's two ends): catching 85 to 90% of the bad cells flags 44% of all cells, so it saves only about a half, 229,000 nodes. A better flag should be available from the generator itself (the plate-edge weights, the shoreline band, the plateau and canyon masks of `WorldLand.shape` are cheap compared with a whole column and are what makes the creases), but I have not measured that.

### 14.2 Keeping edges, by feature and view level

The sim's ground gets its edges from **records laid on the bake**, which cost almost nothing per tick and are exact at every view level, plus a finer bake where the relief is creased.

| Feature | What it is in gen 2 | How its edge is kept | Size |
| :--- | :--- | :--- | :--- |
| **Coast** | The crossing of `SHORE_WET` after the shoreline noise | A polyline of crossings, planet-keyed. Measured: halving the shore error needs the exact land/sea answer (section 13), and a record gives it exactly | About 1.0 million units of coast on the planet (from the 6.5 crossings a Half ring shows, by the line-crossing relation), so about **8,000 vertices at 128-unit spacing**, 64 KB; 2,000 at 512. The estimate may be off by 2 |
| **Cliffs and ice edges** | `floor` terraces and the ice edge: 250 to 430 unit walls (section 12) | A polyline with a top and a bottom height | About 140,000 units, **1,100 vertices at 128** (same caveat) |
| **Ranges and ridges** | `abs` creases of the ridged noise, riding on relief | **Not a threshold, so not a polyline.** Kept by refining the cell: mountain RMS is 3.5 at 128 against 21.6 at 512, and peaks by a record of the local maxima if wanted | Part of the adaptive nodes above |
| **Lakes** | Today a 1D valley on the ring's line (it flickers in a swing, 8.1) | A planet 2D basin: a seed node, a level and an extent from a flood on the bake; the outline is the contour of the level, exact at any view density | One record per lake, tens of bytes. Planned once |
| **Rivers** | Planet flow lines on a 192 x 96 grid (800 units a cell), carved on the ring | The same polylines as records with a width and carve depth, read through the bake; the one-in-3,000 rule becomes a planet rule | A few thousand vertices at most |
| **Marks** | Craters, scars, heaps, slides | Records (8.4) | 48 bytes a mark |

**By view level:** the **performance view** draws the sim's ground (bake plus records) and the records as lines; **middle levels** add off-plane ground from the bake with a cubic filter and, where the budget allows, exact reads; **maximum** adds exact reads in finer tiles. Every level draws the same edges from the same records, so a cliff or a coast is where it is at every level; what changes is only how smooth the ground between them is.

### 14.3 The ground at rest can be exactly today's, near the pair

The sim can sharpen its ground back to today's exact columns where it matters. **After a swing rests, read the exact columns for a window of plus and minus 40 columns round each fighter (162 columns) over the next 60 ticks**, as the calm turn's warm does: the count of columns read is in the state, so every machine agrees on it and a rollback replays it. That is 2.7 columns a tick: **0.15 ms a tick native, 0.35 ms on the web**, and the old laptop does it too. A fighter standing on ground that sharpens is raised at most 7.5 units a tick (row 9's rule for a waded body); a drop is a fall. While a swing runs, the window is re-laid from the bake by lookups (cheap), and when the swing starts the exact columns give way to the bake's. So **near the pair, at rest, the sim's ground is today's exact planet, and in motion it is within the table's error, with the records holding the cliffs and coasts so the change at a swing's start is small (a few units, not hundreds).** I have not run this; the rule is the calm turn's and the raise rule's.

### 14.4 Drawing above today's detail while staying planet-true

"Planet-true" has a limit: **the planet function has nothing finer than a 375-unit cell** of noise; its crisp parts are creases, which are exact at any sampling. So more detail means sampling the same function more densely, not inventing relief.

1. **Denser exact samples, view-only.** Beside the plane the view can read the planet function (`WorldPlanet.farField`, the ring's own arithmetic) at 8 to 16 units instead of 32 near the pair, in tiles cached outside the sim. Creases come out as true cliffs. The budget is reads a tick: about 4 a tick at 50 us on the web, many more on a capable machine, and that number is the granular setting. It touches nothing the sim computes.
2. **Feet agree by construction.** The drawn ground on the plane row is the sim's ground (the exact window at rest, 14.3). Off the plane the view may be exact; between them a band of about 2 body heights eases one into the other, so the ground a fighter stands on is the ground the sim has.
3. **The filter.** A cubic reconstruction of the bake for in-between samples is free on the GPU and removes the straight-edge look at 128 (the probe's cubic gave 22.5 against 23.9 at 512; it is the cheap view-only gain, not a sim one).
4. **Planet-keyed micro relief.** Anything finer than the planet's own detail is invention; it is honest only as a deterministic function of the planet position (a hash of the world point), small (a few units), zero on the plane band, and view-only, so it is the same on every machine and every replay without being in the sim. That is "consistent", not "true", and Art's to judge.
5. **Records drawn at full density.** Coast foam, cliff faces, river and lake outlines come from the records at any vertex density, so the edges are sharper at maximum than at performance without a single extra read.

**The rule that keeps this safe:** the sim reads the bake, the records and the exact window only; the view may read the planet function directly and may never write the sim. Both are pure functions of the same seed.

### 14.5 What I would measure next (nothing built)

1. The time of a 128 whole-planet bake as the stepped planet job, on this PC and at the laptop's x4: the table above uses the EP's 50 us a node and an estimate for native.
2. A generator-mask predictor for the cells to refine (14.1), against the measured 26, 13 and 5% of bad cells.
3. The coast and cliff totals from a real flood of the bake, to replace the line-crossing estimates (8,000 and 1,100 vertices).
4. Planet-wide error, not only rings that cross land (the sea is smooth, so the planet-wide figure should be better than the rings').
5. The exact-window sharpening on a swing's rest, with the raise rule.

## 15. The Cyborg's labs: how few, where, and how they sit under the swing (World, 2026-10-31; paper only, nothing built, nothing measured; arithmetic from the planet's radius 24,446 and circumference 153,600)

Orb's idea (vision.md, 2026-10-31): the Cyborg's fuel is tech components from ruined skyscrapers, and richer ones from secret labs scattered round the world, "including the antarctic lab". Skyscrapers already come with every city (11 a planet). The question here is the rare, rich source.

### 15.1 How few

A lab is a trip, not a pit stop, so it must be rare enough that the Cyborg leaves the fight to get one and common enough that a trip is never hopeless. A lab inside a given range of a fight is the cap-area fraction `(1 - cos(R/24,446))/2` per lab: **1.7% of the planet for a 6,400 reach (Close), 3.8% for 9,600 (a full launch), 6.7% for 12,800 (Half), 25% for 25,600 (Whole).**

| Labs a planet | Lab within Close / full launch / Half / Whole of a random point | Farthest any point can be, if evenly spread |
| ---: | :--- | :--- |
| 3 | 5% / 11% / 19% / 58% | 90 degrees from a lab at best: 38,400 u |
| **6** | **10% / 21% / 34% / 82%** | **54.7 degrees: 23,400 u** (3.9 s at launch speed 6,000 u/s; 23 s flat out at 1,032) |
| 10 | 16% / 32% / 50% / 94% | about 42 degrees: 18,000 u |

**Recommendation: six a planet, the antarctic one plus five.** Evenly spread, six is the octahedron: no point of the planet is more than 23,400 units from one, inside a Whole launch (25,600) and inside the 24,446 that any Half ring through the fight can reach (a Half ring is a circle of angular radius 0.5, and any point within 1.0 radian of the fight lies on one). So a lab is always reachable by one long flight and never by accident: about one fight in five has one within a full launch. The count is a data number (Orb: "balance it and see in the game"); fewer than 4 leaves tropical fights with a flight of 30,000+ units, more than 8 turns labs into towns.

### 15.2 Where

**The far south, always: yes.** The south sheet is part of every planet's function (a cap of about 14% of the surface, 24 degrees across), so a pinned site always has ground. Place it **about 7 degrees (3,000 u) from the pole**, on the dome, about 7,250 u inland of the coast, 1,900 to 2,500 u up. Not on the pole itself: a point on the pole has no north to orient a layout by (the swing and the street frame need one), and the dome there is a summit. It is the richest lab and the only one a player can learn the place of. From the equator it is 38,400 u away, beyond a Whole launch: the Cyborg needs two hops or a long flight, which is the point. A fight is within one Whole launch of it from about 22 degrees south poleward.

**The other five are found by a keyed pass, not pinned:** land only, at least 8,000 u from any city and 3,000 u from any town (secret means not in the Close view of a city), at least 24,000 u from another lab (best-candidate spacing), and a bias to remote ground: mountains, desert, forest fringe, small islands, the deepest inland. Outposts keep their own rule (polar, shelf, high and floe). The pass runs after cities, towns and outposts, so it moves nothing already placed. **I have not counted how many planets have five such sites**; the rule falls back to fewer labs (never to a city's edge), so the count is a maximum. A probe over eight planets would give it (a candidate scan of the kind the outposts dump did).

### 15.3 How they relate to outposts

An outpost is a public research station with people (three polar kinds, 700 u disc, lab block in its plan). A lab is **a role a place can carry, not a fourth kind**: the same disc, the same building plan family (the 700 x 520 lab block as anchor, tanks, mast, hall), the same ledger and wear rules, plus a fuel yield on its objects. The antarctic lab **is the high station promoted** (Rimewatch's rule, moved to the pole's dome and made certain); the shelf and floe stations stay plain outposts. One consequence: the five land labs sit in arenas that are not half ice, so they do not count toward the picker's relaxed minimum, and the antarctic one does (it is polar). For Legal: the Cyborg's meter takes objects only (RL-216); a lab's yield should be its objects (equipment, stores, the lab block's contents), with the staff evacuating as an outpost's people do. That is Legal's and Game Design's to confirm, not mine.

### 15.4 How they sit as planet-fixed places under the swing

- **Stored as a place record in the planet's places list:** id, role, a point on the sphere, a radius, a plan seed and a yaw fixed to the planet's north (not to the ring). Six records a planet (8.4's 48 bytes a mark order). The places list is part of the planet header, so adding labs changes a planet's header and its golden: new planets only if Orb wants old planets untouched.
- **On the strip they are bound pose arrays** (9.4): 6 to 9 buildings, indices fixed, positions re-laid from the planet frame at the current bearing. A swing keeps them; only the turn that swaps the ring re-lays them, as for any place.
- **A lab is small enough that the chord does not matter.** It spans about 2,500 u; the sphere's bend across that is a sagitta of 32 u (half a body height). Unlike a city (8.3), no re-plan is needed when the view swings: its layout is planet-frame, rotated rigidly. The one visible effect is that a swing turns the lab with the world: its depth rows (z) change, so a hall that stood on the fight's plane may stand behind it afterwards. Break that by planning the anchor and the tanks on the lab's long axis, and by the fight's bearing choosing the plane through the lab block when the pair are sent there.
- **The swing route can head for one.** A lab becomes a destination only if the route aims at it: the pair needs the lab within the carried zone (12,000 u) or one hop away. The data stops the angle (10 degrees a swing, 4 a fight, 40 drift; campaign 60), so a trip to a lab is mostly flight, and the swing's job is to bring the lab onto the ring in the last stretch. Nothing in the world blocks that; the choreographer's.
- **Ground:** the lab's site is planned on the ground the sim has (the field, under the provisional route), so it stands on the same ground at every view level. On ice the walls are the one place the smoother ground loses (12): the antarctic site should be on the dome, away from the sheet's edge, which it is.

### 15.5 What I would measure (nothing built)

1. A candidate scan on eight planets: how many land sites meet the rule for the five, and where the spacing fails.
2. The real cap geometry: the dome's height and flatness within 3,000 u of the 7-degree site, on gen 2, to confirm a lab block fits.
3. The distance from each fight start the picker would choose to the nearest lab, over a batch, to compare with the 21% (full launch) arithmetic above.
