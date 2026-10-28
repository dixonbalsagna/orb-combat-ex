# What a beam leaves in the ground: the aftermaths (World, window 21, 2026-10-27)

Combat's nine aftermath kinds and the ocean's parted sea (`docs/combat/biomes.md` section 2, `sigvariants.json` `aftermath`), as one World module: `sim/world/after.gd` (`WorldAfter`), `data/biomes/after.json` (**`enabled` false**), checked by `sim/world/tools/after_check.gd`. With the switch off `lay()` does nothing, nothing is allocated and the state hash is the hash it was. With it on and nothing laid the hash vector is the same plus two zeros (Simulation's rule).

## The call

`WorldAfter.lay(S, a, x0, x1, fineId, z = 0.0, defX = NAN) -> columns worked on`

- `a`: the variant row's `aftermath` dictionary, as it stands in `sigvariants.json` (`{"kind": "fireLine", "spreadTicks": 15, ...}`). World never reads Combat's or the director's data: the director passes the row in.
- `x0`, `x1`: where the beam's path began (the firer's side) and ended; `fineId`: the variant's own fine biome (climate.json `F_*`); `defX`: where the defender stands (only split reads it).
- **One rule for all (biomes.md section 2):** the groove is the columns between the path's ends, padded 48 columns each side, **that the beam scorched** (`S.scorch` above 0) **and whose fine biome is `fineId`**. An aftermath is laid only there; where the beam carves on into the next biome the groove is plain.
- Call it once the beam has carved (the scorch marks are the groove). Gen 1 and the hand-made world never reach it.

Queries a caller can make: `kindAt(S, x)` (the code below), `hazardAt(S, x)`, `clearedAt(S, x)`, `lookAt(S, x)`, `trunksIn(S, x0, x1)`, `jobs(S)`.

## State

Three fields on `SimState` (a grant from Simulation, `grant_sim_after.py`): `aftermath` (a kind byte per terrain column), `aftermathT` (the `waterTick` a timed kind ends at, 0 for one that stays) and `aftermathJobs` (the timed kinds' work: each job an Array of plain numbers in a fixed order). They are sized to `SimConst.NC` and cleared **only with the switch on** (this one, or W4's `craters.json`, whose refill jobs, floe slots and flooded bowls are the same state: `craters-by-material.md`), where `S.scorch` is sized (`terrain.gd`, `planet_world.gd`); `hash.gd` hashes them behind one guard, `if S.aftermath.size() > 0`: a count, (column, kind, expiry) for every column where either is non-zero, then the jobs' count and each job's length and values. `WorldWater.step` runs the jobs every unfrozen tick on `S.waterTick` (a hit-stop freezes them with the water). Nothing draws a random number; no rendering state; no new statics beyond the data's constants.

**The calm turn.** A live job does not hold the calm turn back (`epoch.calm` reads the water's flow windows only). The swap keeps the zone's strips and jobs (weight under 0.5, as the trees) and clears the rest: a job centred in replaced ground ends with it.

| code | name | what the column is |
| :--- | :--- | :--- |
| 1 | glaze | the strip reads `ice` for the match; contact's brake takes the ice profile's grip (sea_ice, 0.4) |
| 2 | cleared | no canopy cover (`WorldCover.coverAt`); the trees in it are felled |
| 3 | plates | a heave's step of plates, raised in `S.deform` |
| 4, 5 | burning, burnt | a fire line's grass (`aftermathT` is when it goes out); burnt reads `ash` |
| 6, 7 | ember, crust | a glowing strip (`aftermathT` is when it cools), then cooled; both read `crust` (Combat's `stripLooks`: ember reads crust; no new look class) |
| 8 | snow | the powder curtain while a snow dump refills the groove |
| 9 | flooded | water stands in `S.water` |
| 10 | scree | a rubble strip (`S.rubble`, so contact reads surface `rubble`: a slide over it tumbles) |
| 11 | wet | shore the parted sea's wave ran up (a look, and props knocked over) |
| 12 | split | a floe's slot, open water |
| 13 | open | the parted sea's trench while it stands |

## What each kind does

| Kind | The row's numbers | What World does |
| :--- | :--- | :--- |
| glaze | none | marks the groove; `lookAt` is `ice`, the brake is the ice profile's |
| split | `gapBh` | a floe is a run of groove columns above the water; each gets a slot `gapBh` × 75 units wide (2 columns for 1 bh), cut 40 below the sea and filled: a real gap in the ground. On the floe the defender stands on (`defX`) the slot is at his column, so the sea-ice HIT twist lands; every other floe takes its middle. The plates do not move after. The cut is `WorldCraters.breakThrough`, which a slam through a thin floe shares (W4, `craters-by-material.md`) |
| clearing | none | fells the trees in the strip (`alive` false, `burn` 0, as a beam leaves them), marks it cleared; the trunks (which lie across the cut) are `trunksIn` |
| fireLine | `spreadTicks`, `durTicks`, `reachCols` | the groove burns at once; the front runs out 1 column every `spreadTicks` to `reachCols` each side; **each column burns `durTicks` after it catches** (Combat: yes), then reads burnt. Grass of the variant's own biome only, never over water. `hazardAt` is true while a column burns |
| heave | `rimMul` | a steep step of plates, not the berm's slope: two columns each side raised by `rimMul` × 0.3 × the groove's depth, and never by less than 1.25 × the slide's wall rule (`WorldSlide.WALL` 0.8) across a column (32 units), so a push-back meets a wall and contact's skate and the slide stop against it |
| snowDump | `refill`, `durTicks` | the groove's depth falls by `refill` of itself over `durTicks` (the remaining depth is scaled step by step, with no stored depth) |
| flood | `source`, `seaCols` | `waterTable`: the groove fills to the biome's water table (water.json `table`: 6 below the original ground in a wetland). `sea`: the groove columns whose floor is below sea level and that have open water within `seaCols` fill to that water's level. At once |
| scree | `minSlope`, `reachCols`, `durTicks` | the groove columns steeper than `minSlope` shed rubble downhill; the run goes on only while each next column is still that steep the same way down, and stops where the slope flattens, even short of `reachCols`; it grows 1 column at a time over `durTicks`; the heap is 1.5 × contact's `rubbleMin` at the groove, 1 × at the run's end; it is surface `rubble` |
| ember | `durTicks` | the groove glows (`hazardAt`) for `durTicks`, then reads crust |
| part | `openTicks`, `pushBh`, `shoreCols` | the ocean's columns on the path are held at no water for `openTicks`; the water model then refills them and the `water_wave` cue is emitted; whatever is within 100 of the surface along the path is pushed `pushBh` × 75 units along the beam's line, away from the firer (the path's first end), over 12 ticks (the way water.json's slam wave moves bodies: a little each tick, never a hold or a lift, and nobody goes into the water); where the line meets land within `shoreCols` of the trench's ends, the first 12 land columns read `wet` for 240 ticks (a look, and props knocked over: no water rules) |

## Choices that are World's (all are in `after.json` or named here)

- A fire column burns `durTicks` after it ignites (Combat: yes).
- The usual berm is 0.3 of the groove's depth (`slide.gd` BERM); a heave is a 2-column step each side, never under 1.25 × the wall rule's rise.
- The flood's water table is water.json's, so wetland and beach already have one; `sea` uses the nearest open water (Combat: yes).
- Scree heap 1.5 × `rubbleMin`, falling to 1 × at the end of the run.
- A split floe's slot is cut to 40 units below the sea; the plates do not drift apart after.
- The wave's push is World's, as the slam wave's is; the shore stays wet 240 ticks, 12 columns.
- The hazard cap (3 fronts) and the Wounds' hazard wear are not here: `hazardAt` only says where the land is lit.

## For VFX and Rendering

Read `S.aftermath[column]` (or `WorldAfter.kindAt`) for the strips, `S.aftermathT` for when a burning, glowing or wet strip ends, `S.water` and `S.deform` for what they changed, and the `water_wave` event for the parted sea's release (`x`, `r`, `amount`, `n`, `dur`). Rendering needs the strips' kinds above; nothing new is emitted but that one event (the existing type). The look classes a strip reads as (`lookAt`, Combat's `stripLooks`): glaze `ice`, ember and crust `crust`, burnt grass `ash`, a flooded groove `water`; scree is surface `rubble`; `surfaceAt` makes glaze, ember and crust `rock`.

## Trees on a path (window 22)

`WorldStructures.damageArea(..., reachMul, treeMode = "area")`: the director passes the signature variant row's `trees` for each sample of the beam. `area` (the default) is what it always was: the trees in reach are felled, with the fire cue. `burn`: felled and charred (`burn` 1, which the tree view draws as a charred stump), with the fire cue. `fell`: felled, no fire. `snap`: felled, with a crown-drop debris cue at each tree. `none`: the trees stand. A tree is felled when it lies within 0.7 of the sample's radius, as before. Where the row also has the `clearing` aftermath, the strip is marked cleared and the trunks are `trunksIn`.

## Proof

`after_check.gd` stages every kind on a flat gen 2 world and shows it applied (the numbers above, and: off lays nothing; on with nothing laid has the same vector plus two zeros; a fire line twice is the same state; a 900-tick match with the switch on is the match with it off plus two zeros). Simulation's parity case "the aftermaths" covers the hash vector, a start in pieces, a job across the seam and a gen 2 turn. The park's report lists the gates.
