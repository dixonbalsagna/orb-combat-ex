# The calm-moment turn: World's side (window 3, 2026-10-22)

Owner: World and Environment. Orb: "I want this approach to work." Game Design's rules (`docs/design/rulings-2026-10-19b.md` §1, with 1e: a landing's settle is 30 ticks and "set" is under 60 u/s; a water landing counts once he surfaces set; the hero's pick may bring a city into view). Encounter's paper: `docs/director/calm-turn.md`. **Built and proved in scratch, parked behind a switch (off): `scratch-build/calm-turn/`.** The picture for Orb: `homework/31c-a-turn.svg` (from a real turn, below).

## What a turn is

At a calm moment the arena's ring turns about the pair: a new plane through the pair's point, **at most 10 degrees of bearing, at most 4 turns a fight, at least 60 s of fight time apart, at most 40 degrees of drift of the ring's axis in all** (the data: `rings.json` `turn`). The pair do not move: **column `pc`, the pair's column, is the same point of the planet before and after**, so every fighter's `x` is unchanged and nothing needs to be carried through a flight. The new ring is the same length (the size's columns), on the same side, with its touch-down placed so that column `pc` stays put.

## The calls (the interface Encounter's paper names)

| Call | Who | What |
| :--- | :--- | :--- |
| `WorldEpoch.ask(S, why, pivotX, side, due)` | Encounter's `DirCalm.ask` result | The candidates on a side: one for each bearing in the data (2.5, 5, 7.5, 10 degrees), each `{bearing, places: [{id, kind, owner, arc}], spec, drift}`. `places` are the places the turn brings into view (held by the new ring, not the old, within 16,000 units of the pivot), by place index only, **without reading the ring**. `[]` when the caps refuse (4 turns, 60 s) or a turn is already decided. Candidates that would pass the 40-degree drift cap are left out |
| `WorldEpoch.choose(S, i, k, fallbackDeg)` | Encounter's `DirCalm.pick` | The turn is decided: the next ring is recorded in the state, deterministic. `k`: the columns of each ring the **sim** reads a tick (Encounter's data, 16 to 32; 0 is the data's `warmCols`). `fallbackDeg`: the second ring's bearing (2.5 for a landing pick; 0 for a form pick, whose pivot is exact: one ring). A fallback not under the chosen bearing, or past the drift cap, is left out. `k` and `fb` are kept in `E.next` and hashed |
| `WorldEpoch.warmAngles(S)` | Encounter, tools | The bearings (signed, degrees) whose ring is read: the angles a swap may use. `[]` when no turn is decided |
| `WorldEpoch.tick(S, hold)` | `SimCore.step`, with Encounter's `DirCalm.hold(S)` | **The sim warms:** each tick it reads k more columns of each of the decided turn's rings (`WorldPlanet.RingJob`, bit-identical to `readSlice`); how far a ring is read is counted in the state (`cols`), so when it is warm is a function of the ticks since the pick. **No host calls anything** (the old `prewarm` is gone). Then, held and `calm(S)`: swap on the chosen angle if the pair's ground keeps within `moveMax` (450 units), else the fallback, else **wait**; **refuse** if even 2 degrees would not (below) |
| `WorldEpoch.cancel(S)` | Encounter's `DirCalm` | Drops a pending pick (and its warm reads); the director can ask again |
| `WorldEpoch.calm(S)` | World | No beam, shot, flight, rush, slide or interior chain, no open set piece, no water flowing, no catastrophe |

The director's part of calm (no exchange, approach, clinch, flip, queued press, finisher) is Encounter's `hold`; World's check is the world's part. With the switch off (`rings.json` `turn.on` 0 and no `setup.arena.turn`) `S.epoch` is null and nothing runs.

## The swap, and what is carried

The new ring is read beforehand (0.15 to 0.7 s of work by size, a few columns a tick: `prewarm`), read by the sim in the ticks after the pick (0.15 to 0.7 s of work by size; about a ninth of that with the ring-read speed park, `scratch-build/ring-speed/`), then one step on the calm tick, **with no ring read on that tick**:

| State | How |
| :--- | :--- |
| **The ground** | Inside `carryUnits` (12,000 each way, at most a quarter of the loop) of the pair the columns keep; the first quarter of that is exactly as it was, then the old ground fades into the new ring's by a smooth weight; beyond it the ground is the new ring's. The platforms under every settlement are lifted again over the blended ground |
| **The marks** (`deform`, rubble, scorch, cracks) | Kept inside the zone and faded out across it; gone outside. **The thin marks beyond the zone are the honest loss** |
| **Craters and slides** (the records) | Kept when inside the zone |
| **Buildings** | Every building inside the zone stays as it is (hurt, fallen, its people). The places the new ring holds that had no building kept are laid fresh by the same generator, and only their buildings outside the zone are kept. Districts are renumbered and `WorldLanes.build` is run again |
| **People and the ledger** | `pop0`, `present`, casualties and the rolling budget are not touched; the lure's histogram is rebuilt; a place laid fresh has the people its weight gives it |
| **Fighters** | Their `x` and `z` do not move; `y` is raised if the new ground is above him |
| **Derived** | Water re-initialised from the new ground (the calm check has no water flowing); the biome table (`WorldBiomes.planetCols`, `S.planetCols`) is the new ring's outside the zone; `S.worldId` is claimed again, so the director's tables and the contact surface classes follow |

**Why the zone carries by place on the ground and not by plan index** (a finding): I expected the collateral window's `(place, plan)` identity to survive a turn and it does not. A settlement's layout is generated from its chord on the line, so the same place on a ring 10 degrees away is a different layout: laying the same city on four chords gave 12, 12, 8 and 16 buildings (Bellgate) and a per-index match of 15 of 32 (row, kind, floors, width), 18 of 37 for the village. So the buildings near the pair are carried as they stand, and a place is laid again only where no building of it was kept. **Until a city is generated from its own plan (planet window 3), a place whose chord moves across the zone's edge is cut there.** A plan index is its index in its settlement plus 1,000 for each turn, so `(place, plan)` stays unique.

## A landing turns less (Game Design 2026-10-22 5a)

The pivot is fixed at the ask, at where the pair are expected to rest, and a mispredicted landing leaves the pair `s` units from it (a median of 3,600 in Encounter's six matches). The ring turns about the pivot, so the ground under a fighter moves `s` x sin(angle), at most `moveMax` (450 units since 2026-10-23; 300 before). **No hitch (Executive Producer, 2026-10-22 on Game Design's "no hitch"): the swap never reads a ring.** Only the rings the sim has warmed can be swapped to: the chosen bearing (up to 10 degrees) and the fallback (2.5 for a landing pick; a form pick has none and waits instead). At the calm tick, with `s` the farthest fighter from the pivot:

| The pair | The swap |
| :--- | :--- |
| `s` x sin(chosen bearing) is within `moveMax` (450 since Game Design 2026-10-23 ruling 3; it was 300) | the chosen bearing |
| else `s` x sin(2.5) is within `moveMax` (`s` under about 10,300) | the 2.5 degree ring |
| else `s` x sin(2) is within `moveMax` (`s` about 10,300 to 12,900) | **waits**: the turn stays decided and the next calm tick looks again (the pair may be nearer); Encounter's `cancel` drops it at the end of the moment |
| else (`s` over about 12,900) | **refused**: the pick is dropped (`E.refused` counts it), so the director asks again at its next send. The `moveMax` rule wins over "never under 2 degrees" |

A ring counts as warm only when all its columns have been read by the sim's ticks, so a part-read ring never swaps. A waiting pick keeps its warm work and its pivot: the swap looks again each calm tick, so a new send or pause that brings the pair back within the 300-unit rule swaps it; Encounter's `cancel` drops it. No host is involved: a headless replay, a determinism run or a tool with no host warms and swaps on the same ticks as play. The number of warm rings, `k` and the fallback are in the state hash. `E.cold` counts a swap that had to read (a state carried into a process that never warmed it: the same ring, so the same result, and a hitch); in play it stays 0.

## The picture

`homework/31c-a-turn.svg` is from the game's own code: planet 7 (Everhold), touch 3, a Whole ring; at 100 s two buildings near the pair are felled or hurt and a crater is dug; then `ask`, `choose` (10 degrees) and `tick`. The strips are the biome of every 16th column before and after, with the buildings; the blue box is what carried over (133 buildings before, 96 after). The globe animates the turn.

## A bug this found in windows 0 and 1 (fixed on main, 79693404)

`WorldContact._colSurf` (each column's surface class: soil, sand, rock, paving) was built **once**, from the hand-made world's biome layout. On a planet world its biomes are the slice's, and on a smaller arena the table is shorter than the ring or longer than the one a Whole match built: matches read the wrong surface (a landing on soil that is rock) and, in the other order, **read past the end** (a script error when a 4,800-column match followed a 2,400-column one in one process). It is rebuilt for each world a match builds (keyed on `WorldBiomes.worldId`). The default world is unchanged (its layout is the same), so no golden moves; the arena check (descending sizes) never read past the end.

## Simulation's, Tools', Encounter's and the others' lines

| Who | Lines |
| :--- | :--- |
| **Simulation** | `state.gd`: `var epoch = null`. `hash.gd`: only while `S.epoch` is set (a match without it hashes as before): `n`, `lastT`, `drift`, 0 or 1 for a decided turn (and its bearing, pivot column, how many of its rings are read, `k` and the fallback bearing), and the hash of the ring's slice (Simulation's conditions a and b, 2026-10-22); and the `arena_turn` event's fields. `view/fx.gd`: the event in the pass list. `sim.gd` `newMatch`: `S.epoch = null`; `step`: `WorldEpoch.tick(S)` after `S.T += dt` (with `DirCalm.hold(S)` as its second argument when Encounter's exists) |
| **Tools** | One case in `cases.json` (`rings-turn-bearing-over-10`) with the schema's `turn` block |
| **Encounter** | `DirCalm.ask`, `pick`, `hold` as in its paper, `cancel`, and `choose(S, i, k, fallbackDeg)`: the sim warms the rings itself in `tick`, no host calls anything (a Whole ring is 4,800 columns: k 32 reads one in 150 ticks, 2.5 s), and `warmAngles(S)`; a refused turn (`E.refused`) just re-asks at the next send, and a waiting one is cancelled at the end of its moment; the candidates' `places` carry `{id, kind, owner, arc}` (kind `city` or `town`; there is no landmark or home on the planet yet: `owner` is -1) |
| **Rendering and Camera** | The `arena_turn` event `{n, x (the pivot), amount (the bearing, degrees), k (the drift)}`: the ground, the far land and the buildings are rebuilt at Camera's hard cut; the zone is `x` plus or minus 12,000 units |
| **Game Design** | The first values: carry 12,000 units, view 16,000 units, the bearings 2.5, 5, 7.5, 10 |

## What is not here

- **Steering** (the side from the brawl's drag and the last launch, the pick by combat alchemy's score) is Encounter's; World gives the candidates and applies the pick. The check stands in for Encounter with a scripted ask.
- **Depth rows** (`depthOn`) are not carried: a match with depth on does not turn (the data's switch would be off for it).
- **The wear list** (a run's persistent damage per place) is not written at a turn: a place that leaves the zone is forgotten within the fight (the run's stage end writes the whole match's marks).
- **A turn on a ring whose centre is on the right** of the way the columns run (`ringThrough` with side -1) does not start an epoch (the picker's rings and the great circle do).
