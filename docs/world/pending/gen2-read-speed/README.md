# gen2-read-speed: the gen 2 ring read, and the planet's load in steps (parked, window 20 and its add-on)

World and Environment, 2026-10-26. The page is `docs/world/gen2-read-speed.md` (inside the diff). Everything is the same planet, ring and match to the last bit; no switch, the golden does not move.

## Apply

On main (2ba0a1d6 or later) **with Simulation's planet-load applied first** (`docs/architecture/pending/planet-load/`: `grant_world.py`, then `planet_load.py`), from the repo root, in one commit:

```
git -c core.autocrlf=false apply docs/world/pending/gen2-read-speed/gen2-read-speed.diff     # sha1 a6f23c3b3cf4, 28 files
python docs/world/pending/gen2-read-speed/grant_sim_load.py .                               # Simulation's sim/core/planet_load.gd, two small things (a grant)
```

The diff is World's: `sim/world/{planet,climate,land,rivers}.gd`, the new `docs/world/gen2-read-speed.md`, `rivers_check.gd` (3 rows), the new `step_check.gd` and tools (`ring_prof`, `epoch_prof`, `read_digest`, `planet_digest`, `job_prof`, `try_prof`, `flow_prof`, `touch_prof`, `step_prof`, `warm_ring_prof`) with their `.uid`s, `ring_bench` (`--gen=`). The makers (`mk_p20a/b/c.py`, `mk_p21.py` with `flow_steps.py`; `mk_wbc_lib.py`) rebuild the four sim files from the base byte for byte.

**The grant** (`grant_sim_load.py`, Simulation's `sim/core/planet_load.gd`): the load's steps spend the slice (`spent += u`: World's job goes on where it left off, so the try-set floor of `PLACE_COST` units is gone), and a touch-down's ring is read with `WorldPlanet.SliceJob` instead of one `sliceFor` call. Without it everything still works (the planet job is stepped; progress overshoots a little; a touch-down's ring is one piece).

## What it changes

1. **The ring read** (`mk_p20a/b/c`): the noise's octave loop written out, the climate data's numbers as typed statics, `readColumns` reading the planet's numbers once a call with the ordinary ground of `surfAt` inline, `_terms` over the plates that can pair. Bench ring 46.6 to 35-37 us a column; the calm turn's land rings 57 to 54. **Not the web target** (see the page).
2. **The load in steps** (`mk_p21`): `Grid.step` carries the moisture a row at a time; `WorldRivers.Flow` is made in ticks (`Flow.new(G, false)`, `step`); `_tryRun` resumes a place's try-set at its next try; `PlanetJob.step` spends the budget across all of them; `WorldPlanet.SliceJob` reads a touch-down's ring (pick a circle a step, columns a slice, held places) and memoises it where `sliceFor` finds it; `_planets` and `_slices` evict the oldest. `FLOW_COST` is now 7,400 units.

## Proof (scratch: an export of 2ba0a1d6 plus planet-load, plus this)

- **Same to the bit:** `read_digest` (24,000 float64 points, four planets, both generations) and `ring_bench` hashes for both generations identical to the base; `planet_digest` (places, grid, flow, two touch-down slices; both generations; rivers on and off) identical to HEAD plus planet-load; `step_check` (stepped equals whole at budgets 250, 37 and the whole, gen 2 with and without rivers and gen 1; `SliceJob` equals `sliceFor` on three touch-downs and is then the memo; the host's load then the match is the cold match; the eviction) and `rivers_check` (the stepped flow equals the whole at chunks of 1, 7, 1,000, 20,000).
- **Gates** (all on the scratch with the grant applied): every World check and both probes 0 failed; lint clean; validate self-test 9141 of 9141; `run-all` all 5 stages (unit, parity with planet-load's rows, soak, golden check passed, godot); `gen2_soak` 900 ticks, `--b` and `--rivers` 12 of 12 each, 0 not the same twice; the render gates `after`, `city`, `cue`, `depth`, `flash`, `flash_reg`, `flight`, `ground`, `hud_words`, `lane`, `open`, `pane`, `patch`, `shape`, `sky`, `stage` and Audio's 9 pass (`cull` and `outline` refuse to run under --headless, as before).

## Numbers (native, this PC, 35 to 40% busy with other sessions; before and after alternated)

| | Before | After |
| :--- | :--- | :--- |
| `ring_bench` gen 2, a mixed ring | 45.2 us a column | 35.2 |
| The calm turn's land rings (97% land) | 53 to 62 us a column; the warm 275 to 295 ms | 51 to 56; 285 |
| The planet job's longest call at a budget of 250 (rivers on) | 148.8 ms (the flow field after the grid) and 72 to 80 ms (a try-set) | **7.7** |
| The wind's carry; the flow field; a try-set | 17 to 26; 136 to 149; 72 to 80 ms in one call | steps of 5 ms (+ one row, one pop or one try) |
| A touch-down's ring | one call, 80 to 90 ms | 20 steps, the longest 7.9 ms |
| A touch-down's match start after the host's load | 135 to 165 ms | 5 ms |

## Not done, and for others

- Research's B plates `WorldPlateB.stateOf` (49 to 55 ms, one call) and a B planet's dearer tries (the weights are measured without B).
- The calm turn's worst tick (10 ms on this PC) is not the ring read (its longest call is 4.5 ms): it is most likely a swap-preparation step in `WorldEpoch._prep` (not profiled here).
- The web ring-read target needs a structural change (see the page), not a faster octave.
