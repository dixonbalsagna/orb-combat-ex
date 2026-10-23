# The first ring turns toward land (World, 2026-10-23): parked, not applied

Game Design's ruling (rulings-2026-10-23 section 6): the first stage's ring (Close, round the player's home) can miss Close's minimum (a coastal home gave a ring 70% ocean). **When it does, `firstRing` turns the ring toward land, keeping the home on it; if no bearing meets the minimum, the story's ring stands as it is** (as the boss's does). `first-ring.diff` (4 files). **It applies after `pi-tau/pi-tau.diff` and `used-rings/used-rings.diff`** (all three touch `ringpick.gd`; this one is made on a copy with both applied, so its context has `SimMathx.PI`). Golden unchanged.

## What it does

- `WorldRingPick.firstRing(P, homeId, stream, opts)` keeps its signature (the new `opts` is optional: `standing`, `damaged`) and **its answer when the ring round the home already meets Close's minimum: the same ring to the bit** (checked). The new result keys are `kind` ("round" or "through"), `turned` and `land` beside `c`, `t`, `cols`, so `arenaOf` and every caller take it as before.
- Otherwise it reads the rings **through the home** (the home stays on the ring, the touch-down at the home) at `first.bearings` evenly spaced bearings (data, 12, starting from the story's own seeded bearing) and takes the one that **meets Close's minimum with the most land** (then the most biomes). If none does, the story's ring stands.
- Why a through ring: the ring round a home has the home at its centre and reads the same land whatever the bearing (it is one circle), so "turning the bearing" is a through ring: the circle moved so the home sits on it, the direction chosen toward land.
- **A stepped form for the run host**: `beginFirstRing(P, homeId, stream, opts)` returns a `FirstJob` with `step(n)` (true when made), `spec`, `total` (1 + bearings reads at most). The story's ring is read first and if it meets the minimum the job is done in one step (about 2.6 ms native); a turned ring is at most 13 reads (about 35 ms).

Data: `data/biomes/rings.json` `first.bearings` (schema included).

## What the scan found

On planets 1 to 30, 34 of the cities' first rings were under Close's minimum, 24 of them on land share (under 40%, the coastal case), the rest on biomes; **all 34 had a bearing that met it** (1 to 11 of the 12 bearings did), the best bearing's land share 41% to 100% (planet 3, city 8: 26% to 58%; planet 19, city 8: 15% to 77%; planet 24, city 43: 11% to 41%).

## Proof (clean export of HEAD plus pi-tau and used-rings, then the patch)

`ringpick_check` 0 failed, with 6 new checks: a coastal home (planet 3, city 8) turns to a through ring that meets the minimum with more land, the home on it; a first ring that already meets the minimum is the ring it was, to the bit; every place fallen (no bearing meets it): the story's ring stands; over 8 planets' cities every first ring that missed the minimum (9) is turned to one that meets it; a stepped first ring is the one made at once; the turned first ring plays in a match. World's other 14 checks 0 failed; `validate` 0 errors; the lint reads 0 hits in sim/world; `run-all` 5 of 5 (golden unchanged); Rendering's 15 gates.
