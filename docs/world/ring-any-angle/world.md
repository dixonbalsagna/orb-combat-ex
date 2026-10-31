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
