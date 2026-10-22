# boons: the run's rare boons (parked)

Owner: Simulation and Engine. 2026-10-19. Game Design's three rare boons (`rulings-2026-10-18b.md` section 4), run-only: a match's setup names them (`"boons": {slot: id}`), and versus never does. The page is `../../boons-core.md`.

## Apply

On a clean export of f91ad3c9 or later, from the repo root:

```
python docs/architecture/pending/boons/boons.py .
python docs/architecture/pending/grant_tools_fight.py .
```

`grant_tools_fight.py` is Tools': the schema for `data/fight/boons.json`, its map rule, its fixtures and its copy in the self-test's virtual folder (same commit, or the validator warns "no-schema").

## What it changes

- New: `sim/core/boons.gd` (`SimBoons`), `data/fight/boons.json`.
- `sim/core/state.gd`: `Fighter.boon`.
- `sim/core/sim.gd`: a new match applies the setup's boons.
- `sim/core/hash.gd`: the boon, only when named.
- `sim/core/replay.gd`: `boons.json` in the data hash, only for a setup that names one.
- `sim/core/wounds.gd`: the borrowed form's price.
- `sim/core/tools/parity.gd`: "the run's rare boons".

## Results (scratch, on f91ad3c9)

- Import clean (one new class). Parity on the committed golden: 64 of 64.
- The golden regenerates byte-identical.
- Re-proved on 4d2f568b (2026-10-22): import clean, parity on the committed golden 67 of 67, golden byte-identical.
