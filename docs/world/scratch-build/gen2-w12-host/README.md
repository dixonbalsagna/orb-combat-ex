# A draft for Simulation: `SimRun.beginGround` makes a cold planet in steps (parked)

World and Environment, 2026-10-23. `gen2-w12-host.diff` (sha1 bd8cc8ad3175, 4 files) applies to main (checked against HEAD bf34d1d4's `sim/core/run.gd` and `parity.gd`). **Simulation's file:** this is a draft for its owner, not a change World makes.

**Why.** A gen 2 planet takes about a second to make (the climate grid, then the places). `beginGround` made it in one call (`WorldPlanet.make`), a one-second stall at the run's first stage. `WorldPlanet.makeJob(seed)` makes the same planet in steps.

**What it does.** `beginGround` starts a `PlanetJob`; if the planet is already made (every later stage, gen 1) the ground starts there as before. If not, `GroundJob.step(n)` spends `n * PLANET_UNITS_PER_READ` (250, about 5 ms) on the planet until it is whole, then starts the ground (`GroundJob.start()` holds what `beginGround` did) in the same call; `frame()`'s once-a-frame pace is unchanged, so a cold stage's first reads are the planet's. `finishNow()` finishes both.

**Proof** (`sim/world/tools/host_check.gd`, new, World's): cold, the planet is pending and the ground has not started; stepped to the end it took 136 reads and 1.03 s, the longest single read 69 to 76 ms (a place's try-set, which `PlanetJob` cannot split, on a busy machine; about 20 ms quiet); warm, the ground starts in `beginGround`; the cold and the warm result are the same JSON, and so is `finishNow` on a cold job.

**One test line (Simulation's `parity.gd`):** the coastal-home test asserts a read a frame on a planet it never made, so with the draft its first frames are the planet's. The diff makes the planet first (`WorldPlanet.make(SimRun.planetSeed(coast))`), as a later stage has it.

**Not needed: Rendering's `far_land.gd`.** Its `WorldPlanet.make(p)` (lines 42 and 105) always finds the planet in the memo: `begin` runs after `SimCore.newMatch`, which made it. Nothing to change there. The one remaining cold make inside a match start is `newMatch` itself (`WorldPlanetWorld`), which is a synchronous call by design.
