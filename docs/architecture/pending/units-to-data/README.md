# units-to-data: the planet's pacing in the run's data (parked)

Owner: Simulation and Engine. 2026-10-25, on the EP's go (2026-10-23: "move PLANET_UNITS_PER_READ into data/fight/run.json ground with Tools' schema, as a small window of yours"). The page is `../../run-core.md` §11.

## What it changes

- **`sim/core/run.gd`:** World's host constant `PLANET_UNITS_PER_READ` (250) becomes `SimRun.planetUnitsPerRead`, read from the data by `SimRun`'s loader (a whole number from 1 to 100000). `GroundJob.step` spends it a read on a cold planet's make.
- **`data/fight/run.json`:** `ground.planetUnitsPerRead` 250, beside `framesPerRead`, with World's measure in its note (a climate cell about 20 µs, a place's try-set 1000: about 5 ms a read).

It is the same number, so nothing moves and **the golden does not.**

## Apply

On 4dc06456 or later (World's host on main), from the repo root, in one commit:

```
python docs/architecture/pending/units-to-data/units.py .
python docs/architecture/pending/units-to-data/grant_tools.py .
```

`grant_tools.py` is Tools'. It adds fight-run's `ground.planetUnitsPerRead` (required), a case, and the virtual copy. It applies before or after `docs/sim/pending/campaign-slice1/` by their scripts (checked both ways: validate 265 files, 0 errors; self-test 9098 of 9098). **If this lands first, apply the campaign by its scripts, not its patch:** the patch's `cases.json` context moves with this case.

## Results (scratch, on 4dc06456)

- Apply and import were clean.
- Parity on the committed golden: 73 of 73, and the golden was byte-identical.
- These all passed: npm's 5 stages, det, det_intro, seam, flash with the count check, validate (264 files, 0 errors, 0 warnings), its self-test (9083 of 9083), QA's run-all, loader and the flash self-test.
- All 19 render gates (Rendering's 15, the city check, VFX's effects and hash checks, Camera's split sweep) and `anim_check` passed: 20 runs, no failures.
