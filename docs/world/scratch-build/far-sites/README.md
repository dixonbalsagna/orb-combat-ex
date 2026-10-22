# The far land's two follow-ups (World, 2026-10-22): parked, not applied

Rendering's two optional follow-ups after the far map (`docs/world/scratch-build/far-read/`, on main). Golden unchanged; nothing here is hashed. Apply `far-sites.diff` (8 files) from the project root; `git apply --check` is ok on 5595363e. It needs World's far read (`WorldFarMap`), which is on main.

## 1. The match's ring in unhashed state

`S.planetRing = {seed, c, t, cols}` for every planet match, the turn on or not: the axis, the touch-down point and the columns, as `WorldRingPick.ringFrom` takes them (the same values a turning match keeps in `S.epoch.ring`). It is set when the world is built (`planet_world.gd`) and again at each turn (`WorldEpoch.swap`), and `{}` for the hand-made world. A renderer reads it instead of `S.epoch.ring`, so a planet match without the turn gets the planet's far land too.

**Simulation's two lines** (the grant): `state.gd` `var planetRing = {}` (unhashed, with a comment like planetCols's), and `sim.gd` `newMatch`: `S.planetRing = {}` before the world is built. The hash does not read it (checked).

## 2. Settlements in the map

- `WorldFarMap.sites` (a byte a texel, whole from the start, so it is there before the map is built): 0 none, 1 a town's ground, 2 a city's. A texel is marked when its centre lies within a place's radius (a town 2,437 units, a city 6,500) of its centre, and the texel holding a centre is always marked; a city over a town. `site(qx, qy, qz)` reads it at a unit vector; `field()` returns it as `"s"` beside `"h"` and `"b"` (same layout), so Rendering can upload it as one more channel.
- `WorldPlanet.farPlaces(P, ring, maxLateral)` (and `WorldFarMap.places`): the places themselves, for drawing a distant town where it stands: `{id, kind (KIND_CITY 0 or KIND_TOWN 1), col (a float column along the ring), z (farColumn's z: the place is at farColumn(ring, col, z)), rad, dir (the unit vector), people}`.

## Proof (HEAD plus the far read, then the patch; below-normal priority)

`farsites_check` (new; 7 checks): farPlaces lists every place of 3 planets x 3 rings and each stands where (column, z) says (worst miss 58.8 units: the column rounded to a whole one fans out with the lateral offset); the settlement layer marks the texel under every centre and only texels inside a radius; `field` returns `"s"`; a planet match with the turn off keeps the ring a turning match keeps; `S.planetRing` is not hashed; a Whole ring's and the hand-made world's; and after a turn it is the new ring. World's other 15 checks 0 failed; `sim/core/tools/run-all.js` all 5 stages (the golden unchanged); Rendering's 15 gates all passed.
