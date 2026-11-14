# A big bowl brings down what stands in it (World, 2026-11-01)

Orb, first play: "an entire city block collapses into the resulting crater" at maximum power. Game Design's `docs/design/power-scale.md` asks World for the size of the bowl and the fall. Legal's read is RL-232 (`docs/legal/review-log.md`). **Built and parked, off. `COLLAPSE` 0 failed (2026-11-02); the world checks and sim gates are not re-run on it yet.** Park: `docs/world/pending/crater-collapse/`.

## What it does

`WorldCrater.dig` ends with `_collapse`. With `craters.json` `collapse.enabled` on, a dig of a kind in `collapse.kinds` (impact, powerup) whose bowl radius is at least `collapse.minR` (900) levels every standing building whose centre is within `collapse.reach` (0.8) of the radius: `WorldStructures.levelIn`, which is Encounter's meteor blast moved into World (twice the building's hp, the falls folded into one event past `IMPLODE_EVENT_CAP`, staggered by distance from the centre by `damageBuilding`'s own implode delay). Past the cap (the fighter's `beamLevelCapShare[3]` of the first ring, else `collapse.capShare`) the rest are left at `collapse.keep` (0.2) of their hp. From 0.8 radius out to the lip, `collapse.dent` (0 first) damages a building by that share of its hp, falling to nothing at the lip. A dig with `meteor` on skips it: the meteor's own blast stays Encounter's (there is no grant now: `DirArc._blast` keeps its own copy, so a barred landmark inside a meteor's blast is not spared; RL-232 speaks of the crater's block fall, which does spare it; a three-line grant on `_blast` would spare it in the meteor too, if Legal wants that).

## Legal (RL-232), how it is kept

- **From the energy spent, never a place chosen.** `_collapse` reads only the bowl's radius (energy), the kind and the data. No picker, AI or landing score reads a block's size, occupancy or population; `levelIn` reads no people.
- **The barred-landmark filter reaches it.** `levelIn` skips a building whose landmark is `WorldSettle.noTarget` (the chapel). 
- **The toll is the existing one.** The fall goes through `damageBuilding`, so it is the existing building rule (`structuresLost`, collateral) and no new count, line or reward. QA re-reads the civilian band at tier 4 with it on (RL-232).
- **No ceremony.** Nothing here adds a camera, hold, sting, popup or line. The fall is the existing `building_fall` events, at most `IMPLODE_EVENT_CAP` plus one folded, staggered by the implode delay: one event for the flash registry. The flash clips (both modes) and the look gate are Rendering's and QA's, before it ships on; the dust is the existing per-building dust, local.

## Sizes (not run; arithmetic)

A bowl's radius is `160 x sqrt(E)`: 900 is E 32, 1,244 is E 60 (Game Design's maximum into the ground). At 0.8 of 1,244 the fall radius is about 1,000: one block and its two rows (a row is 8.5 fighters deep, 640 units). `minR` 900 keeps a base crater (160) and an ordinary signature (480) from bringing anything down; a tier-3 ground power-up (927) just does.

## What I did not do

- **Not run.** `sim/world/tools/collapse_check.gd` (COLLAPSE, in the park, registered in `tools/world-checks.json`) tests: off by default; a bowl under minR levels nothing; on, the buildings within reach fall up to the cap and the rest keep `keep` of their hp; a barred landmark stands; none beyond the bowl is touched; the fall is the existing `structuresLost` and at most the event cap; a meteor dig and a beam dig level nothing; the same dig gives the same state twice; switched off again it leaves the old state. Run it, and the world checks, before it lands.
- **Cost not measured.** The sim cost is `near()` over the bowl plus `damageBuilding` for each building it levels (the first ring has 263 buildings; a block is a dozen or two).
- **Power.json is Game Design's and Simulation's.** The crater's own tier term (`IMPACT_TIER_E`) and ordinary cap (`ORD_R_MAX`) are still constants in `crater.gd`; making them data for `power.json` is a separate, small park once its numbers are read.
