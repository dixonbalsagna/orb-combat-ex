# planet-load: the planet's load step (parked)

Owner: Simulation and Engine. 2026-10-26, on the EP's brief after Performance's gen 2 bench (`docs/perf/gen2-bench-2026-10-26.md`). The page is `../../planet-load.md`.

## What it changes

- **`sim/core/planet_load.gd` (`SimPlanetLoad`, new):**
  - `begin(seed, gen)` and `beginFor(setup)` start a load;
  - `Job.step(units)` spends a bounded slice a frame. The steps are the plates, the climate grid, the flow field, the places and, for a match's setup, its ring;
  - `Job.progress()` (0 to 1) and `Job.phase` feed a loading screen;
  - `ready`, `mayStart`, `strict` and `refused`.
- **`sim/core/sim.gd`:** with `SimPlanetLoad.strict` on, `newMatch` refuses a setup whose gen 2 planet isn't made, and leaves the state as it was.
- **`sim/core/run.gd`:** the run's `GroundJob` loads its planet with `SimPlanetLoad`, and `GroundJob.progress()` reads it.
- **`sim/core/tools/parity.gd`:** "the planet's load" checks:
  - the cold refusal, and that a gen 1 planet is never refused;
  - the progress and the phases;
  - the match after the load is the cold one to the bit, on make's planet;
  - a named ring read in slices gives the same match, and is skipped the second time.
- `strict` is off unless a host sets it, and nothing here runs in a match: **the golden does not move.**

## Grants

- **`grant_world.py` (World's `sim/world/planet.gd`):**
  - `WorldPlanet.isMade(seed)`;
  - `WorldPlanet.ringRead(seed, ring)`;
  - `PlanetJob`'s flow field becomes a slice of its own when a frame's slice ends the grid. Today that slice also runs the carry and then the flow field. A whole budget (a `finishNow`) still goes on in one call.
  
  The planet is the same either way, and `make(seed)` doesn't use the job.

## Apply

On main (05121f65 or later), from the repo root, in one commit, in this order:

```
python docs/architecture/pending/planet-load/grant_world.py .
python docs/architecture/pending/planet-load/planet_load.py .
```

or `git -c core.autocrlf=false apply docs/architecture/pending/planet-load/planet-load.diff` (sha1 0ed2246d2058, 6 files, both). Applied to the base's files, it gives the proved copy, file for file.

## Results (scratch: an export of 05121f65)

- **The full gates on the first cut:**
  - parity on the committed golden (75 of 75) and **the golden byte-identical**;
  - npm's 5 stages, det, det_intro, seam, flash with the count check, QA's run-all, loader and the flash self-test;
  - validate (268, 0, 0) and its self-test (9140 of 9140);
  - **all 19 render gates** and `anim_check`, and the lint.
- **What that cut found, and the fixes:**
  - World's `host_check` failed one check: the run's `GroundJob.finishNow()` is one call, and the cut ended a call after the plates and before the flow field. Now a whole budget goes through every step, and World's flow field waits only after a frame's slice.
  - Parity's check hashed a sim before its first match (two script errors). It now checks the refusal against a match already running.
- **The fixed park:**
  - parity 75 of 75 with no script errors, and the golden byte-identical;
  - validate, its self-test and the lint;
  - World's checks that touch the planet, its job, the run's host and the match's planet, 13 tools with no failure: `host_check` (also with rivers on), `gen2_state_check`, `rivers_check`, `planet_check`, `planet_world_check`, `campaign_check`, `epoch_check`, `climate_check`, `land_check`, `b_check`, `switchon_check`, `demostart_check` and `ringpick_check`.
- **Measured** (the page's §4): a gen 2 load is 1.28 s here, 137 to 139 frames at the data's slice, and a match start after it is 9 to 17 ms. The pieces over a frame are World's: the flow field, a try-set, the places' last step, and a touch-down's ring.
