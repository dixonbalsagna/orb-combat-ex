# A field world and the turntable, in the sim

Simulation & Engine. Stage 5 of `docs/world/ring-any-angle/research.md` T6, on `simulation.md` section 9. Behind `setup.planetGen: 3` on a whole ring. Off a field world `S.frame`, `S.swing` and the pose arrays stay empty, nothing below runs, and the golden is byte-identical. The API for other directors is `simulation.md` section 11. World's half is `docs/world/gen3-field.md`.

## What it is

- **`sim/core/field.gd`, `SimField`:** the sim's line, `S.frame`, a great circle, and the read through it. `WorldField` holds the ground. `W`, `NC`, `sdx` and `wrap` stay, as a ring buffer of the circle.
- **`sim/core/swing.gd`, `SimSwing`:** Game Design's rate law. Camera's curve, a closed form with a clock the law can slow, turns the line about a pivot on it. Fighters, gaps and velocities don't change; only the ground under them moves. The director asks; this runs. No score, no draws.
- **`WorldTerrain.groundY`, `baseAt`** and the water's `depthOf` read through the frame. `S.base` is laid once, for the world's builders and the old renderer at rest; the sim doesn't read it. Every direct read of `S.base` outside the builders goes through `baseAt`.
- **The order of a read:** the field by the reader's level, World's records (`applyRecords`), the planet store (`heightDelta`), and the strip's `S.deform` on top.
- **Poses:** `S.bX`, `S.bZ`, bound arrays, read through `Building.x` and `.z`, so no reader changes. `bDir` holds each building's planet point, World's, where it was laid. A building's base is the ground at that point, not the line under its `x`.
- **A whole ring only.** A Half ring is a small circle, so it has no frame, and a gen 3 Half ring plays as World built it, on `S.base`, with no swing.

## The determinism rules

1. **Whether the bake is done is never a sim input.** World's load phase makes it before tick 0, and `mayStart` waits.
2. **Which level a read uses is fixed by the reader, never by what's ready.** Inside `SimField.far()` to `near()`, reads take the bake. Outside, the 128 ground and its records, computing a missing node on the spot.
3. **A memo never changes a value.** The column memo is a pure function of the frame and the store, and its key is those numbers themselves, so a restored or another state can't read the wrong columns, and a re-run reads no node.
4. **Three plain float64s,** never a `Vector3`. Trig through `SimDetMath`. Inverse trig through `WorldPlanet`'s own.
5. **The frame stays unit and square:** each turn re-normalises, or a long match's rounding would drift the line off the sphere.

## The hash, the header and the match key

- `hash.gd`: the frame's seven numbers, the swing's fields, the store's length and running hash in two lanes, only while the frame is set. Poses aren't hashed, because they derive from the frame and the plan.
- `SimReplay.dataHash` on a gen 3 setup folds `data/fight/swing.json`, the bake's hash and a hash of 64 seeded canonical nodes. The match key holds the data hash, so a build that computes the field differently is refused at the handshake.

## The forecasts' scopes

`roam`, `_search`, `predictFlight`, `_biomeCands`, `_cliff`, `_propOnPath`, `_skimAshore`, `flightTo`, `_flightToSwept`, `_landY`, `_building`, `_floor`, `lineOfSight`, `_swat`, `ignite`: each wraps itself in `far()`, so its helpers (`seaTop`, `baseY`) follow without a level argument. That's the fix for section 9's worst ticks. `SimCore.step` closes any scope a tick left open.

## After a rest

`SimSwing._layMarks` lays the strip's `S.crack` and `S.scorch` from the store, the same values World's `layCracks` and `layScorch` give, `layPerTick` columns a tick, outward from the pair. Those arrays are hashed, so every peer writes them on the same tick. It only runs if the store holds a crack or a scorch. During a swing those marks ride with the line, and they snap to their true place outward from the pair over the 7 to 48 ticks after the rest.

## What it doesn't do yet

See `simulation.md` section 11, "Known limits". The largest are: `DirSwing` is Encounter's, so nothing asks for a swing until it lands; a fight's strip marks and water stay at their column; trees stay at their strip `x`; `NetDesync.digest` doesn't fold the frame until Netcode's `PROTO` 4.
