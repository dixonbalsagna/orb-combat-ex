# Cars: scenery first, then throwable (World, plan, 2026-10-16)

Owner: World and Environment. Orb (homework 22): "scenery cars, and throwable cars too." **A plan; nothing built.** It extends the pitch in `crowd-cars-buildings.md` section 2 (options A and B) and `fight-lanes-world.md` sections 3 and 4. **Build A first, when briefed; B follows.**

## Option A: scenery cars (cosmetic, Rendering's)

| Step | What | Owner | Hash / golden |
| :--- | :--- | :--- | :--- |
| A1 | Data: a `traffic` density per district and a `vehicle_share` (the mix of car, van, bus, bike) in `settlements.json` (schema by Tools); the street polylines and carriageway widths are already in `lanes.json` | World | None (data nothing in the sim reads) |
| A2 | The vehicle layer: cars drive the front street's carriageway, turn at avenues, queue at crossings, stop at the kerb; parked cars line the kerb strips. Deterministic from the planet seed and `S.T`, one instanced draw like the crowd's (`crowd_mesh.gd`), about 150 to 250 visible, none off-screen. They scatter on `evacuate`, `crater`, `building_fall` and `launch_depth` events near them and never stop a fighter | Rendering | None |
| A3 | Four silhouettes (sedan, van, bus, bike) in the districts' tones and one wreck state each | Art | None |

- **Never counted, never hit.** Moving cars are dressing: a blast or a slide does not damage them (they scatter), so they imply no occupants harmed, add nothing to the casualty ledger and cost no menace or anguish (Legal c08/c09).
- **Flash:** small, dark, steady shapes; no bright lamps by day; a wreck smokes and does not flash. The flash set (collapse and crater clips) is checked with them on.
- **Cost:** one draw call; none in the sim. The same on the web as the crowd's.
- **With the planet:** the layout reads the lane table of a slice, so cities of any seed get traffic. A canon city can have a fixed look in data.

## Option B: throwable cars (props in the sim)

Orb wants cars a fighter can throw. A car that can be thrown is a body in the sim: it needs state, a hash, physics and hooks. The scenery cars of A stay dressing; **the parked ones become props** (the kerb strips' V1 props, `fight-lanes-world.md` section 4), a few dozen a city.

| Step | What | Owner | Golden |
| :--- | :--- | :--- | :--- |
| B1 | **Prop state.** `S.props`: each parked car a record (`x`, `y`, `z`, `vx`, `vy`, `vz`, `w`, `d`, `h`, `hp`, `state` standing / airborne / wreck, the last owner). Placed from the lane table's kerb slots by the seeded plan (a place id and plan index, as a building has), about 60 to 120 a city. In the hash (a standing car by its slot, an airborne one by its position) | World, with Simulation's hash | Yes: one regeneration |
| B2 | **Physics.** A thrown car is ballistic under the sim's gravity, lands on the ground (`WorldTerrain.groundY`), bounces and slides as a body does (`contact.gd`'s rules with its own restitution and friction), hits a building as a brunt does (a dent, windows, a small damage a hit, the owner the thrower), and is destroyed after a number of hits (a wreck: a heap, smoke). A collapse crushes the cars under it (removed) | World | With B1 |
| B3 | **The hooks.** What throws a car: a fighter's grab-and-throw (Combat's move), a blast's push, a launched body striking one, a beam's shove. A car hits a fighter as a blow: damage by speed times a mass, a stagger | Combat, Encounter, World | Combat's own |
| B4 | **Drawing.** The props are drawn from state (the A silhouettes with an airborne pose); a thrown car's trail and impact are VFX's, under the flash rules (the same no-flash wreck) | Rendering, VFX, Art | None |

- **People:** a car holds no one. A thrown car does not kill civilians (it is not a casualty source); it can damage a building, whose people die through the ordinary path with the thrower as the owner. This keeps B out of the collateral budget's numbers, and out of Legal's c08/c09 (no "run over" scenes).
- **Cost:** a few dozen to 120 records in the state; each tick only the airborne ones step (tens at most); the spatial index is the building buckets. The swept test (L3) already treats a prop as a blocker.
- **Risks:** the golden (B1); Combat's grab and throw is the long pole (a move with its animation); the flash rule on a thrown car's impact; a car in the middle of a lane blocks a fighter's flight (L3 treats props as blockers, so the director must route around it: `clearLane`).

## Order

1. **A1 to A3 first** (data, Rendering's layer, Art's four silhouettes), on the EP's brief to Rendering and Art; no golden, no budget change.
2. **B** after the planet windows and Combat's grab: B1 and B2 as one World window (with the golden), then Combat's hook, then B4.
3. **Look:** no real marques or designs: generic vehicles in the districts' palettes (Art's; Legal screens the look).
