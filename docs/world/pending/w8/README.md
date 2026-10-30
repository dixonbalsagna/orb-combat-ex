# w8: the replay header's helpers, and the swapped ring's job and preparation kept for 21 ticks (parked, World, 2026-10-30)

Applies on main 64148abf (checked in a scratch export; proved on the export before it, 7dc7ca2a/553ac274, with nothing else of these files changed in between). Nothing is switched on: the helpers add functions and no caller yet; the kept preparation changes no state (the swap's result is the same state hash, straight or re-run).

```
git -c core.autocrlf=false apply docs/world/pending/w8/w8.diff            # sha1 8d562f681c54, World's 10 files
git -c core.autocrlf=false apply docs/world/pending/w8/w8-grant.diff      # sha1 70ae30c0bf90, the grant: sim/core/sim.gd and net/snapshot.gd
```

`mk_p41.py` to `mk_p45.py` (with `mk_wbc_lib.py`) rebuild all of it from main, in that order, byte for byte.

## 1. Hash helpers (Simulation folds them in)
- `WorldDensity.enabled()` and `WorldDensity.dataHash()` (the parsed data without the `_` notes, made once).
- `WorldClimate.genFor(setup)`: the setup's `planetGen`, else climate.json's `gen`; never `genNow()`.
- `WorldPlanet.dataHash(gen = 0)`: keyed on the generation given (0 is `genNow()`, as every caller so far).
- `density_check` holds all three (the switch, the cache, `genFor` against a tool's generation in force, and the planet's hash by generation).

## 2. The swap's job and preparation, kept (Netcode's takeover report)
- `swap()` retires the ring job and the preparation under the world it leaves (`_retire`) for `KEEP_TICKS` 21 ticks instead of dropping them; `tick()` sweeps what has aged out; a swap run again renews the term.
- `cold` and `unprep` are process counters (`WorldEpoch.coldCount`, `unprepCount`), no longer in `S.epoch`.
- `WorldEpoch.release(S)` drops what a disposed sim owns (its world, the worlds it retired, whatever world id it has by then).
- **The grant (not World's):** `SimCore.dispose(S, keepWorld = false)` calls `WorldEpoch.release` unless told the state lives on, and `NetSnapshot.restore` passes `true` (it disposes to break cycles and then plays on; without the flag every restore would drop the kept preparation). Without the `net/snapshot.gd` line the change is still right, only the kept jobs would not survive a restore.
- Safe to use twice because the swap binds its structures `fresh` (the prepared buildings and trees stay pristine) and the kept buildings' districts are generation records a restore puts back (`docs/architecture/packed-structures.md`).

## Proof
Clean export with both diffs applied. Last lines are in the report to the EP; the cost reading is `sim/world/tools/rerun_cost.gd` (a swap tick re-run after a restore, same state hash): **about 60 ms before** (89 to 107 ms on a loaded machine), **about 2 ms after** (1.7 to 2.4 ms in six runs).
