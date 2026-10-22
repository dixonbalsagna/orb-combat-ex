# The calm-moment turn: World's side (window 3, 2026-10-22)

Owner: World and Environment. Orb: "I want this approach to work." Game Design's rules (`docs/design/rulings-2026-10-19b.md` §1, with 1e: a landing's settle is 30 ticks and "set" is under 60 u/s; a water landing counts once he surfaces set; the hero's pick may bring a city into view). Encounter's paper: `docs/director/calm-turn.md`. **Built and proved in scratch, parked behind a switch (off): `scratch-build/calm-turn/`.** The picture for Orb: `homework/31c-a-turn.svg` (from a real turn, below).

## What a turn is

At a calm moment the arena's ring turns about the pair: a new plane through the pair's point, **at most 10 degrees of bearing, at most 4 turns a fight, at least 60 s of fight time apart, at most 40 degrees of drift of the ring's axis in all** (the data: `rings.json` `turn`). The pair do not move: **column `pc`, the pair's column, is the same point of the planet before and after**, so every fighter's `x` is unchanged and nothing needs to be carried through a flight. The new ring is the same length (the size's columns), on the same side, with its touch-down placed so that column `pc` stays put.

## The calls (the interface Encounter's paper names)

| Call | Who | What |
| :--- | :--- | :--- |
| `WorldEpoch.ask(S, why, pivotX, side, due)` | Encounter's `DirCalm.ask` result | The candidates on a side: one for each bearing in the data (2.5, 5, 7.5, 10 degrees), each `{bearing, places: [{id, kind, owner, arc}], spec, drift}`. `places` are the places the turn brings into view (held by the new ring, not the old, within 16,000 units of the pivot), by place index only, **without reading the ring**. `[]` when the caps refuse (4 turns, 60 s) or a turn is already decided. Candidates that would pass the 40-degree drift cap are left out |
| `WorldEpoch.choose(S, i)` | Encounter's `DirCalm.pick` | The turn is decided: the next ring is recorded in the state, deterministic |
| `WorldEpoch.prewarm(S, n)` | the host | Reads n more columns of the chosen ring (`WorldPlanet.RingJob`, bit-identical to `readSlice`), memoised outside `S`. Optional: **the swap reads what is missing, on its own tick**, so a replay does not depend on how far the host got |
| `WorldEpoch.tick(S, hold)` | `SimCore.step`, with Encounter's `DirCalm.hold(S)` | Swap when a turn is decided, held and `calm(S)` |
| `WorldEpoch.calm(S)` | World | No beam, shot, flight, rush, slide or interior chain, no open set piece, no water flowing, no catastrophe |

The director's part of calm (no exchange, approach, clinch, flip, queued press, finisher) is Encounter's `hold`; World's check is the world's part. With the switch off (`rings.json` `turn.on` 0 and no `setup.arena.turn`) `S.epoch` is null and nothing runs.

## The swap, and what is carried

The new ring is read (0.15 to 0.7 s of work by size, warm or on the tick), then one step on the calm tick:

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

## The picture

`homework/31c-a-turn.svg` is from the game's own code: planet 7 (Everhold), touch 3, a Whole ring; at 100 s two buildings near the pair are felled or hurt and a crater is dug; then `ask`, `choose` (10 degrees) and `tick`. The strips are the biome of every 16th column before and after, with the buildings; the blue box is what carried over (133 buildings before, 96 after). The globe animates the turn.

## A bug this found in windows 0 and 1 (fixed on main, 79693404)

`WorldContact._colSurf` (each column's surface class: soil, sand, rock, paving) was built **once**, from the hand-made world's biome layout. On a planet world its biomes are the slice's, and on a smaller arena the table is shorter than the ring or longer than the one a Whole match built: matches read the wrong surface (a landing on soil that is rock) and, in the other order, **read past the end** (a script error when a 4,800-column match followed a 2,400-column one in one process). It is rebuilt for each world a match builds (keyed on `WorldBiomes.worldId`). The default world is unchanged (its layout is the same), so no golden moves; the arena check (descending sizes) never read past the end.

## Simulation's, Tools', Encounter's and the others' lines

| Who | Lines |
| :--- | :--- |
| **Simulation** | `state.gd`: `var epoch = null`. `hash.gd`: only while `S.epoch` is set (a match without it hashes as before): `n`, `lastT`, `drift`, 0 or 1 for a decided turn (and its bearing and pivot column), and the hash of the ring's slice (Simulation's conditions a and b, 2026-10-22); and the `arena_turn` event's fields. `view/fx.gd`: the event in the pass list. `sim.gd` `newMatch`: `S.epoch = null`; `step`: `WorldEpoch.tick(S)` after `S.T += dt` (with `DirCalm.hold(S)` as its second argument when Encounter's exists) |
| **Tools** | One case in `cases.json` (`rings-turn-bearing-over-10`) with the schema's `turn` block |
| **Encounter** | `DirCalm.ask`, `pick`, `hold` as in its paper; the candidates' `places` carry `{id, kind, owner, arc}` (kind `city` or `town`; there is no landmark or home on the planet yet: `owner` is -1) |
| **Rendering and Camera** | The `arena_turn` event `{n, x (the pivot), amount (the bearing, degrees), k (the drift)}`: the ground, the far land and the buildings are rebuilt at Camera's hard cut; the zone is `x` plus or minus 12,000 units |
| **Game Design** | The first values: carry 12,000 units, view 16,000 units, the bearings 2.5, 5, 7.5, 10 |

## What is not here

- **Steering** (the side from the brawl's drag and the last launch, the pick by combat alchemy's score) is Encounter's; World gives the candidates and applies the pick. The check stands in for Encounter with a scripted ask.
- **Depth rows** (`depthOn`) are not carried: a match with depth on does not turn (the data's switch would be off for it).
- **The wear list** (a run's persistent damage per place) is not written at a turn: a place that leaves the zone is forgotten within the fight (the run's stage end writes the whole match's marks).
- **A turn on a ring whose centre is on the right** of the way the columns run (`ringThrough` with side -1) does not start an epoch (the picker's rings and the great circle do).
