# Terrain step 2: no shafts, and water where it could come from (World, 2026-11-09)

Plan: `docs/ep/proposals/terrain-globe-plan.md` step 2 (sections 4.2, 4.3, 5). Park: `docs/world/pending/globe-step2/`. Check: `sim/world/tools/globe_check.gd` (`GLOBE`), soak: `sim/world/tools/globe_audit.gd` (`GLOBEAUDIT`). It changes the hash: the golden is in its own patch.

## What a player sees

Nothing changes with the shipped data. Every new rule that could change a picture is behind a switch that is off (`craters.json globe.repeats` 0, `water.json flood.enabled` false); the ones that are on (the shaft cap read from the planet's store, settling, the floor and ceiling) change a result only where a spot has been hit again and again, or where a bowl would stand on a wall steeper than loose ground can hold.

## The record list, fixed in code

`WorldStore` records are 16 numbers. The last five are the same on every kind (all folded into `storeHash`, so a rollback truncates them with the store):

| Slot | Name | Holds |
| :--- | :--- | :--- |
| 11 | `O_LIP` | a trench's or scar's lip height (the raised bank at its edge); 0 until step 3 |
| 12 | `O_MAT` | a crater's material class (a code into `WorldGround.LOOKS`); 0 until craters-by-material feeds it |
| 13 | `O_REP` | a crater's repeat count: 0 for a first blow, one more than the record it supersedes |
| 14 | `O_WATER` | the level its water stands at, `DRY` (-1e9) for none |
| 15 | `O_SUP` | the record it supersedes, -1 for none |

Kinds: CRATER 0, CRACK 1, SCORCH 2, TRENCH 3 (as before), and new SCAR 5 (a groove A to B, read like a trench), HEAP 6 (a cone, slope capped at 1 in 1), MERGE 7 (a bowl standing for older small marks, read as a crater). Nothing makes a SCAR, HEAP or MERGE yet: their readers and adders (`addScar`, `addHeap`, `addMerge`) are in so Rendering bakes once, on a list that does not change (steps 3, 5 and 6 are the producers). Kind 4 is left unused.

`heightDelta` reads the sum of bowls, a heap's cone, the deepest groove (trenches, scars, scorch: never summed), the highest lip, and holds the total between a floor (-2,080) and a ceiling (+960): the strip's -260 and +120 times the feature scale. A record another supersedes is not read (`ent.sup`, derived from the store like the grid). `heightDeltaX(S, q, skip)` reads it as if one record were not there.

## No shafts

A crater dug on the planet store (`WorldCrater._globeLive`: gen 3 with a frame) reads its relief from the store (`WorldGlobe.relief`): the mean ground on a ring of 1.2 R round its centre, eight fixed bearings, against the ground at the centre, both without the record it supersedes. Its depth is the treadmill's `min(0.22 R, 0.26 R - relief)`, and a dig under `MIN_DEPTH` is refused (returns null, supersedes nothing). The relief had been reading the old strip's two columns, which a globe match never writes: so the cap never saw a bowl.

Settling (`WorldGlobe.settle`): the wall of the proposed bowl plus the store's ground is sampled on eight bearings at ten radii; where the steepest drop is over `craters.json globe.repose` (1.25) the bowl widens by k = (s / 1.25)^(1/3) and shallows by k^2 (volume kept, `SimDetMath.pow`), is held to the radius cap again, and its depth to the shaft cap again (at the cap the bowl only gets shallower).

## Grooves settle and cross rims

A trench or a scar is stored settled (`WorldGlobe.settleGroove`): its wall is 1.54 of its depth over its half width, and where that is over the angle of repose (1.25) it is widened by k and shallowed by k, the cross-section kept (a 100-deep, 32-half-width trench is stored 51 deep and 63 wide). A groove is still never deeper than its target. The ground where a groove crosses a rim, an apron or a heap used to be the lower of the two, which left a cliff as high as the rim at the groove's edge (the groove is about 0 there and the rim up to 0.4 of a bowl's depth); it is now the groove cut down from the rim (`sum + groove`) wherever the marks stand above the original ground, and the lower of the two below it. The two are what took the audit from 637 steps over one body height in 40 matches (12 matches over 6) to none.

## Repeats

`craters.json globe.repeats`: how many times a blow within half a radius of a recent impact crater grows it instead of digging beside it. The new record is dug at the old centre, supersedes the old record (`O_SUP`, `O_REP`+1), and its radius is the larger of its own and 1.25 times the old (brunt.json `repeatCraterGrow`): a max, never a sum of energies. The store stays append-only. On the globe this replaces the strip's `_repeat` (which read `S.craters` by strip x and so followed the line, not the planet).

**Shipped off (0).** A superseded record is still in the render list of the newest bowls (`tile_ground.gd:263`), and a grown bowl opens from nothing on top of tile ground that already holds the old one: a pop at the hand-over. Rendering's two lines are listed in the README. With repeats off every blow digs its own crater, held by the shaft cap, and the second blow on a spot is refused once the spot is dented enough.

## Water where it could come from (B1)

`water.json flood` (off): when a crater, a trench or a groove is dug `minDug` (6) or more deep, `WorldFill.floodLevelFor` looks once for a source: the sea (the field's ground under the shore line), a lake (World's lake records), or the biome's water table at the hole's own point, at 4 radii and 8 bearings out to 1,150 beyond its own radius, reading the field and never the store. It also takes the level of a record that overlaps it and already holds water, so a trench cut on from the coast carries the level along its length and a bowl dug in a flooded crater fills. The lowest level found wins (water finds the lowest it is connected to; the plan said highest, which put a hilltop lake's level into a hole beside the sea). The level goes in the record's water slot; no source leaves it DRY and the hole dry. A hole above its level holds nothing: the pool is the level less the ground (`WorldFill.floodDepth`), inside the hole.

The read is `WorldField.recordWater` (so the field's memos and `WorldWater.depthOf` see it); the one Simulation line is the guard in `SimField.nativeDepth` (`grant-simulation-field.patch`). There is no front in the sim: the pool is there when the hole is. The run-in is a view cue (step 4). It never traps, slows or hurts.

## Measured

See the park README's table (docs/world/pending/globe-step2/README.md) and the records in docs/world/runs/globe-step2/. In short: 20 hits on one spot leave the centre 78.3 deep of 92.6 allowed (repeats off) or 122.4 of 144.6 (on); 10 base hits make craters of 356, 445 and 556; 0 steps over one body height in each of 40 AI matches (637 before the groove changes); an inland hole holds no water with the flood on, and reads as sea 46.8 deep with it off; two peers, one rolled back, read the same 4,800 columns; the golden does not move.
