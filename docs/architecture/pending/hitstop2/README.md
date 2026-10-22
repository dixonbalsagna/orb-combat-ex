# hitstop2: hit-stop by weight, re-cut (parked)

Owner: Simulation and Engine. 2026-10-22. Game Design's `rulings-2026-10-22.md` 5b (the table cut, the second step, an 18% budget) and 6 (a mash flows: `light_flow`, 0), and the core's whole-tick count, behind the hit-stop switch (`data/fight/hitstop.json`, off). The page is `../../feel-core.md` section 7.

## Apply

On a clean export of c847bf8f (main with the planet golden keys) or later, from the repo root, in one commit:

```
python docs/architecture/pending/hitstop2/hitstop2.py .
python docs/architecture/pending/hitstop2/grant_tools.py .
```

`grant_tools.py` is Tools': the hit-stop schema's `cutMul` and `cutFloor` in place of `mashFloor`, the ticks' `light_flow`, and the self-test's virtual copy of the data.

## What it changes

- `sim/core/hitstop.gd`: the second step (`cutMul`, `cutFloor`; decisive and the KO never cut), the 10 s window, and `frozen()` dropping the count-down's residue.
- `data/fight/hitstop.json`: the table (with `light_flow` 0), the cut, the budget (0.18 of 10 s).
- `sim/core/fx.gd`: `stopTicks(stop, whole)`.
- `sim/core/damage.gd`: the damage event's `stop`, whole with the switch on.
- `sim/core/tools/parity.gd`: the hit-stop check, re-cut; the curve check's replay test plays until a launch is paced.

## Results (scratch)

**On c847bf8f** (main's sim to 03427822):
- Alone: import clean, parity on the committed golden 68 of 68 (the hit-stop check re-cut; the curve's replay test made sturdy), golden byte-identical.
- With `ricochet/`: parity 69 of 69, golden byte-identical. The full gates pass: npm 5 of 5, determinism and its intro, seam, the flash count and its check-log, the validator 0 and 0, the self-test 8,590 of 8,590, QA's run-all, the loader and the flash self-test. All 15 of Rendering's checks pass.
- `hitstop2.py` also makes the curve check's replay test play on until a launch is paced (at most 3 minutes): with the new table, seed 11's first 60 s hold none.
