# calm-k: the calm turn's slower read on a gen 2 planet (parked)

Owner: Simulation and Engine. 2026-10-26 and 27, on the EP's brief after Game Design's `rulings-2026-10-26.md` item 28. The page is `../../calm-turn-read.md` (§6 is this park). It uses World's `gen2-read-speed-b` (`turn.warmTotal`, `readTo`, `readAhead`, `warmPlan`), on main since cb42a242.

## What it changes

- **On a gen 2 planet, a calm turn's rings are read K = 12 columns a tick in all,** whatever the lead, and K is held in the state (`E.next.k`, the total under World's `warmTotal`).
  - A form pick's Half ring takes 3.3 s, a launch pick's two rings 6.7 s.
  - A form step's warm begins at its ready tell. A launch's begins at its throw, as before.
  - A warm not done by its moment takes the next one (Encounter's waiting rule).
- **On a gen 1 planet nothing changes, its hash included.**

| File | Whose | What |
| :--- | :--- | :--- |
| `data/biomes/rings.json` | World (`grant_world.py`) | `turn.warmTotal` 1 |
| `sim/world/epoch.gd` | World (`grant_world.py`) | `_share` shares `k` on gen 2 only |
| `sim/director/calm.gd` | Encounter (`grant_encounter.py`) | `gen2`, `gen2Cols`, `totalK`; the pick's `k` on gen 2; `warmRate`; the pause's check on gen 2; `atReady` |
| `data/director/interrupts.json` | Encounter (`grant_encounter.py`) | `calmTurn.warmColsGen2` 12 |
| `sim/core/fx.gd` | mine (`calm_k.py`) | the ready tell calls `DirCalm.atReady` |
| `sim/core/tools/parity.gd` | mine (`calm_k.py`) | "the calm turn on gen 2" |
| `tools/schemas/director-interrupts.schema.json`, `biomes-rings.schema.json` | Tools (`grant_tools.py`) | the two keys |

## Apply

On main (6de9aeb7 or later), from the repo root, in one commit and in this order:

```
python docs/architecture/pending/calm-k/grant_world.py .
python docs/architecture/pending/calm-k/grant_encounter.py .
python docs/architecture/pending/calm-k/calm_k.py .
python docs/architecture/pending/calm-k/grant_tools.py .
```

or `git -c core.autocrlf=false apply docs/architecture/pending/calm-k/calm-k.diff`.

## Results

The full proof ran on a `git archive` export of 9490ac21 with the four scripts. The scripts apply unchanged on 6de9aeb7, which has match-start. There they were run again: parity 77 of 77 (with "the match's start in pieces"), the golden byte-identical, determinism and the lint. `calm-k.diff` was cut on 6de9aeb7: 8 files, sha1 0c54c5b442e0. Applied to the base's files, it gives the proved copy, 0 files differ.

- **Golden byte-identical** to HEAD's. Parity 76 of 76 on 9490ac21, with "the calm turn on gen 2": gen 1's ready tell asks nothing; gen 2's asks "ready" at 12 columns a tick in all, its rings sharing them; none with the turn off.
- npm 5 of 5, determinism and determinism `--intro`, the seam sweep, flash count, validate 269, self-test 9154, QA 7 of 7, the loader, flash self-test 95, lint.
- **All 19 render gates** and anim_check: no FAIL, no script errors. **World's 38 checks** in `sim/world/tools/`: none fails.
- **Gen 1 does not change, its hash included:**
  - four AI matches of 7,200 ticks with the calm turn on (asks at k 32, 16 and 26, two turns) hash as the base does, every 600 ticks and at the end;
  - World's `calm_digest` gives the same lines as the base, and with `--total` (`warmTotal` 1) its gen 1 lines are the base's to the hash.
- **Gen 2** (QA's calm probe, 4 AI matches of 10,800 ticks on a Half ring, base and park):
  - 3 turns each, none bad, none cold, none refused;
  - every ask at 12 (base: seven at 32, one at 16);
  - one turn now asked from a ready tell, 600 ticks before its landing;
  - the worst tick while warming 4.6 ms (base 5.0), the mean 0.45 ms (0.44);
  - the ticks held for warming 1,435 (643).
