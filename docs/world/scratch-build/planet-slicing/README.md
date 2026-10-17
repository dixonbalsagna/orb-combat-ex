# Time-sliced planet loading (World, 2026-10-17): built in scratch on main's HEAD, parked, not applied

The EP's brief, from Performance's audit (`docs/perf/audit-2026-10-16.md` section 4.1: the strip read takes 0.7 to 1.4 s on this PC and 6.9 to 13.5 s at x8): time-slice it at about 4 ms a frame, the coarse variant (every 8th column) first and the full read filling in; a skipped intro must not skip generation; deterministic; the memo outside `S`. Built on main af5151b5 (planet window 1, 2154cd5e). **Not applied.** `sim/world/planet.gd` is mine; the patch touches nothing else.

## What it is

Three jobs and one wrapper in `WorldPlanet`, each stepped a few **work units** at a time by the host (a unit is about 0.12 ms native: a slice column, a place candidate, a pick candidate's counts, or one of its 96 surface samples). **The module owns no clock** (no `Time`, no `OS`: the source scan still passes): the host measures its own frame and decides how many units to give.

| Job | What | Unit |
| :--- | :--- | :--- |
| `PlaceJob(seed)` | The planet's places, the same candidate search as `make`, a candidate at a time; registers the planet in the memo when done | one candidate |
| `PickJob(P, touch, standing, relaxed, either)` | The pick (or the offers' strict-else-relaxed pick), a candidate's counts first and then its 96 samples a sample at a time | the counts, or one sample |
| `SliceJob(P, circle, T, standing)` | **Phase 0, coarse:** the planet function at every 8th column, nearest the touch-down first, the rest interpolated (heights on a line, the biome of the nearer): the provisional ground, ready after 608 units. **Phase 1, full:** every column, nearest first, the coarse ones only adding their fine relief; the held places; the memo store | one column |
| `beginLoad(seed, touch, standing, relaxed)` -> `LoadJob` | The three in order. `slice` is the provisional slice from the pick onward (`slice.provisional` is true until the full read ends), the final one when `done`; `ok` is false if no circle met the minimum; `progress()`, `stageName()`; **`finishNow()`** does what is left in one call | |

**The rules it keeps.** A job's result is **bit-identical to the whole call however it is stepped** (tested for chunks of 1 to 1,000,000 units): the heights and biomes hash (`d0f86ade`) equals `readSlice`'s, the places equal `make`'s, the picks equal `pick`'s and `pickEither`'s. The coarse values are provisional and replaced; the **sim starts only when `done`** (a headless run, a replay and a skipped intro call `finishNow()`: a skip cannot skip the load). The memo stays outside `S` (`sliceFor` and `LoadJob` share one key and one store). The refactor that makes this possible (`_candidate`, `_columnInto`, `_heldInto`, `_evalCounts`/`_evalSample`/`_evalFinish`) leaves every existing result unchanged: `planet_check.gd` and its vectors file pass untouched.

## Measured (`planet_job_measure.gd`, this PC with Orb's game running and the machine busy, below-normal priority: upper bounds)

| | Planet 7, touch 3 | Planet 7, touch 9 | Planet 11, touch 2 |
| :--- | ---: | ---: | ---: |
| Frames at a 4 ms budget | 325 | 334 | 518 |
| A frame: median / 99th / worst | 4.2 / 5.0 / 7.4 ms | 4.2 / 4.8 / 5.5 ms | 4.3 / 4.8 / 5.7 ms |
| The coarse ground is ready after | 0.76 s | 0.73 s | 1.4 s |
| A 4-unit call, 99th: places / pick / ground | 0.7 / 1.0 / 1.1 ms | 0.7 / 0.9 / 1.0 ms | 1.1 / 1.3 / 1.1 ms |

The whole calls on the same PC: places 0.63 s, pick 12 ms, slice 0.67 s. **No frame passes 8 ms** (the audit's hard cap) once the pick is sliced by sample (a first version that gave a whole 96-sample candidate to one step had a 12.6 ms call). Total work is the same as the whole calls (1.4 to 2.2 s here).

## Where it is not enough (honest)

- **Native and x1 (this PC) fit the intro:** about 320 frames at 4 ms is 5.4 s at 60 fps, inside the fall of 5 to 7.6 s, and the coarse ground is there after about 0.75 s.
- **On T3 (x6) and a slow phone (x8) it does not meet the audit's "within 5 s":** the work is 6 to 8 times more, so about 8 s of CPU for planet 7 and 13 s for planet 11 at x6 (11 s and 18 s at x8), which at 4 ms a frame is 30 to 45 s. Slicing keeps every frame under budget (no freeze), but the load outlasts the intro. The levers, with what each saves:
  1. **Do not place the planet at touch-down at all** for a canon or a stored planet: the places list is data (2 KB), which saves the 0.5 to 0.7 s of places (about 45%). For the run mode, the *next* stage's pick and read can start during the story beats and the offers screen (seconds of idle UI), so the load is hidden there, not behind the intro.
  2. **A bigger budget behind a loading card** (12 ms a frame while nothing else draws): a third of the time.
  3. **A coarser definition of the far ground** (the world is full detail within about 1,200 columns of the touch-down and the stride-8 read beyond it, on every machine): a design change to the world, not to the loader; about 40% less work and it is deterministic because it is the definition. Orb's and the EP's call; it changes how the far ground looks.
  4. **A worker thread** (the jobs are pure and touch no state): not assumed on the web, which needs cross-origin isolation.
- **Fidelity of the coarse ground** (what the player sees for the first seconds, never what the sim reads): over the whole strip the mean height error is 21 units (worst 113) and the biomes agree in 99.3% of columns (99.0% through both poles); the near 300 columns are final long before the rest.

## Files

| File | What |
| :--- | :--- |
| `planet-slicing.diff` | The patch on HEAD: `sim/world/planet.gd` and the two new tools. Verified with `git apply` on a clean export, byte for byte the scratch tree |
| `mk_slicejob.py` | The script that makes it |
| `planet_job_check.gd` (+ `.uid`) | 15 checks (order, places for three chunk sizes, picks of 14 touch-downs in three modes, the slice hash for four chunk sizes, the coarse stage and its fidelity, nearest-first, a polar slice, the load job, `finishNow`, a memoised load, a slice-less touch-down): 0 failed |
| `planet_job_measure.gd` (+ `.uid`), `measure.txt` | The frame costs above |

## Lines in files that are not World's

None. (`planet.gd`, its tools and this folder are World's.)
