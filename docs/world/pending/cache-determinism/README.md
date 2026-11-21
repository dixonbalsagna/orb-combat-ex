# Park: the field cache's read-back is bit for bit the fresh bake (World, 2026-11-14; EP URGENT, GW1a)

Page: `docs/world/field-cache-determinism.md` (the fault, the cause, the fix, the cost). Runs: `docs/world/runs/cache-determinism/`.

| File | What |
| :--- | :--- |
| `cache-determinism.diff` | **On HEAD.** `sim/world/plan.gd` (the geometry memo's key carries the shift's exact bits; `PLACES_REV` 2; `shiftBucketOverride`, a test switch), `sim/world/tools/cache_warm_check.gd` (new, `CACHEWARM`) and its line in `tools/world-checks.json` (a one-line hunk in the gap after `beam_grid_check`). World's files only: no grant. `git apply --check` is clean on HEAD; applied on a clean export of HEAD with the check run as a process: it passes |
| `cache-determinism.after-gw1c-fix.diff` | The same, for the stack where `gw1c-world/gw1c-world-fix.diff` has landed first (that fix edits the same key line to add the planet size) |

Land the first on HEAD with GW1a (it needs nothing else). If gw1c-world-fix has landed first, use the second.

## Result

| | |
| :--- | :--- |
| `CACHEWARM` fixed | 0 failed: 23,326 numbers, 0 differ, the warm run is the cold run |
| Negative control (old key) | 157 numbers differ, the largest 2.9e-11 (Simulation's 72 columns and the building positions) |
| `EVERYWHERE`, `PLACESCACHE`, `FIELDCACHE`, `FIELDPLAN`, `FIELDLOT`, `LOTREACH`, `STREETAXIS`, `PLANETWORLD`, `PLANETCACHE` | 0 failed each |
| golden | unchanged |

## NEEDS FROM EP

- **Simulation:** re-run `fork_check` planet 12 on the GW1a stack with this applied: the real and the predicted process should now agree whatever the cache's state. Anything recorded on an everywhere match where the first ring's aligned shift shared a bucket with a free place's is superseded (a replay of it will not verify): the golden is unchanged.
- **Everyone with a field cache:** the places blobs are rebuilt once (rev 2); the first match on each planet after the change lays its far places cold (about the cost of the first match with the cache empty).

## RISKS

- The memo is now keyed by the exact shift, so it holds more entries for the first ring (one per ring); it is cleared whole at 192 as before.
- `shiftBucketOverride` is a test switch in a sim file; it is false everywhere but the negative control.

**Status 2026-11-21: `cache-determinism.diff` LANDED in GW1a (b0e20f9a) and is removed; `cache-determinism.after-gw1c-fix.diff` (the GW1c form) stays.**
