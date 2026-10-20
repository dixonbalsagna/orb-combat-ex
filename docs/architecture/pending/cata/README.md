# cata: the blast cloud's cue and the ash (parked)

Owner: Simulation and Engine. 2026-10-19. VFX's ask (`docs/vfx/blast-cloud.md`): the `blast_cloud` cue (x, y, amount, n) and the world's ash, read-only. The ash is `S.cata`'s, as `../../run-core.md` section 6 lays it out (in thousandths, rising over at least 120 s: Legal c05). **Nothing calls it until the catastrophe tier is built,** so no match changes; `S.cata` is null until a blast cloud and hashed only once it is not.

## Apply

On a clean export of f91ad3c9 or later, from the repo root:

```
python docs/architecture/pending/cata/cata.py .
python docs/architecture/pending/grant_tools_fight.py .
```

`grant_tools_fight.py` is Tools': the schema for `data/fight/catastrophe.json` (with the 7,200-tick floor on the rise), its map rule, its fixtures and its virtual copy.

## What it changes

- New: `sim/core/cata.gd` (`SimCata`: `blastCloud`, the rise's `tick`, and `ash(S)`, 0 to 1, for the views), `data/fight/catastrophe.json`.
- `sim/core/state.gd`: `S.cata` and `CataState` (`ash`, `ashFrom`, `ashTo`, `ashLeft`).
- `sim/core/sim.gd`: cleared at a new match; the rise each live tick.
- `sim/core/hash.gd`: `S.cata` only when set; the event's fields.
- `sim/core/fx.gd`, `view/fx.gd`: the `blast_cloud` event.
- `sim/core/tools/parity.gd`: "the catastrophe's blast cloud and ash".
- `docs/architecture/fx-events.md`: the event's row.

**For VFX:** `hub.ash` reads `SimCata.ash(S)`. **For the tier-5 window (mine):** it calls `SimCata.blastCloud`, and folds `catastrophe.json` into a replay's data hash with the ceiling.

## Results (scratch, on f91ad3c9)

- Import clean (one new class). Parity on the committed golden: 64 of 64.
- The golden regenerates byte-identical.
- The check: the cue's fields, the rise even to a thousandth and never falling, two clouds to the cap, a cloud by no one, the rise run by the step, and the hash taking `S.cata` only once it is set.
