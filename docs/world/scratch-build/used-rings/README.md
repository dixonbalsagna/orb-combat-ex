# The picker passes over rings a run has fought (World, 2026-10-23): parked, not applied

The EP's ruling (from Simulation's run-ground sample, where the Cyborg's stage took the ring the stage before had been fought on): **a run never fights the same ring twice.** `used-rings.diff` (4 files); `git apply --check` ok on e0454fff. Golden unchanged: a pick with no `used` is exactly what it was (checked).

## The option

`WorldRingPick.pick` and `beginPick` take **`opts.used`**: the rings the run has fought, an Array. Each entry is either
- **a ring**: a spec or a `setup.arena` (`{c, t, cols}`; the numbers or the exact-bit strings `arenaOf` writes, so what a stage header carries goes in as it is). Only the axis `c` and the length `cols` are read; or
- **a candidate's identity**: `{place, kind ("round" or "through"), cols}`, to pass over every ring round or through that place.

**The same ring** means the same circle: the same length and an axis within `usedCos` (data, 0.9976, about 4 degrees) of a candidate's. So the same circle with another touch-down is the same ring (a Close ring round a place, whatever the bearing), a Whole ring's axis counts either way round (it is one great circle), and a ring of another length is not the same ring (a Close and a Half ring round one place are different arenas, though they overlap).

**Passed over, and scored down only as a last resort.** In `PickJob._choose` the candidates the run has not fought are tried first (strict minimum, then relaxed). Only if none meets even the crude minimum are the repeats tried, with their score taken down by `usedPenalty` (0.5), and if nothing meets anything, the best-scoring candidate, repeats scored down too. The result carries `repeat` (true when the ring chosen is one the run fought), so Simulation can see it.

Data: `data/biomes/rings.json` `usedCos` and `usedPenalty` (schema in `tools/schemas/biomes-rings.schema.json`).

## Proof (clean export of e0454fff plus the patch)

`ringpick_check` 0 failed, with 8 new checks: over 5 planets x 4 claims x 3 sizes (60 picks) the second pick with the first in `used` is never a ring the first is (60 of 60); an empty `used` is no `used`; a used ring is passed over and a `setup.arena` that has been through JSON is the same entry as the spec; an entry naming a place and kind passes over all of that place's candidates; the same circle with another touch-down is the same ring; a Whole axis the other way round is the same circle and another length is not; with every candidate used the pick still returns a ring, flagged `repeat`, scored down; a stepped pick with `used` is the one made at once. World's other 13 checks 0 failed; `validate` 0 errors, `--self-test` 8,694 of 8,694; `run-all` 5 of 5 (golden unchanged); Rendering's 15 gates.
