# Parked: split_sweep's two pins for the energy model on (split-sweep-energy-pins)

Camera, 2026-11-14, for GW1a: the EP's brief on Rendering's gate. With Simulation's energy-on park (`docs/architecture/pending/energy-on/`), split_sweep failed 7 rows (`docs/rendering/runs/611c1c2b/split-sweep-energy-on.txt`). Both pins are rows off the game's path.

**Apply on main** (cut on 4f06e7a3; it applies before or after energy-on): `git -c core.autocrlf=false apply split-sweep-energy-pins.patch` (sha1 f6afb157). One file, mine: `render/camera/tests/split_sweep.gd`. Records: `docs/camera/runs/4f06e7a3/split-sweep-energy-on/sweep.txt`.

## The two pins

| Rows | Pin | Why |
| :--- | :--- | :--- |
| crossing start, crossing start staredown 72 (6 failures: a dip, a fighter past the edge, the camera off the avenue) | the row's setup: `"power": false` | A demo start that no build opens on (`sim.gd:209`, default off). The rows test a rush to a collision. With the model on, the computer's opening dash passes through the other fighter and runs 2,000 units on at up to 6,000 a second, which the start's own rules (one view for 100 ticks, both on screen through the rush) can't hold. It fails with the travel budget off too |
| real match 10, pitch 49, full, two humans (a fighter out of his pane for 1.2 s) | that row: `"dash": false` (the model stays on) | The sweep runs with the travel budget on, its own switch; the game ships it off. A fighter in free flight at 9,500 units a second outruns the budget's travel cap: three travel cuts in a quarter of a second as the split opens, then the budget's one-second cooldown leaves him out of his pane until the next cut. With the budget off the loss doesn't happen |

**Neither is in Orb's 9 November game:** his builds use neither the crossing start nor the travel budget.

## Proof

| Run | Result |
| :--- | :--- |
| split_sweep, main + energy-on + these pins | **passes** |
| split_sweep, main + these pins | **passes** |

## Owed after GW1a

The travel budget's handling of a flier faster than its cap (it should give way rather than lose him for a cooldown), and its triple cut as a split opens. The budget is off in the game; this is for whenever it's measured for shipping.
