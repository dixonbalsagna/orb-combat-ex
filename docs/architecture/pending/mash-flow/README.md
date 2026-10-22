# mash-flow: a mash's later blows carry no stop (parked)

Owner: Simulation and Engine. 2026-10-23. Game Design's `rulings-2026-10-22.md` 6, on hit-stop by weight as applied (83405d99), behind the hit-stop switch (`data/fight/hitstop.json`, off). The page is `../../feel-core.md` section 7.

## The rule as built

- **A new weight, `light_flow`, holds no stop (0 ticks).** Encounter names it for a mash's later blows, each landing within 12 ticks of the fighter's last.
- **The mash's first blow** stays `light_mash`, 2 ticks.
- **The second step's floor never raises a 0.** Without the guard, the cut's "at least 2" would turn a flowing blow into a 2-tick stop over the budget.
- **The budget never counts a flowing blow,** since it freezes nothing.
- The 18% budget and its ×0.75 step stand.

## Apply

On a clean export of 83405d99 or later, from the repo root, in one commit:

```
python docs/architecture/pending/mash-flow/mash_flow.py .
python docs/architecture/pending/mash-flow/grant_tools.py .
```

`grant_tools.py` is Tools': the hit-stop schema's `ticks.light_flow`, and the self-test's virtual copy of the data.

## What it changes

- `sim/core/hitstop.gd`: `light_flow` in the weights; the cut only for a stop above 0.
- `data/fight/hitstop.json`: `ticks.light_flow` 0, and the note.
- `sim/core/tools/parity.gd`: the hit-stop check: `light_flow` holds 0 and stays 0 over the budget; a flowing blow leaves the clock running.

## For Encounter

Name a mash's later blows `{"weight": "light_flow"}` in the hit's options (the first blow stays `light_mash`). A hit that names it holds no stop. A stop already in force (an earlier blow's, a contact's) runs on: stops merge by the longer one.

## Results (scratch)

- **Full, on 886a61d8:** apply clean, import clean. Parity on the committed golden passed 70 of 70 ("hit-stop by weight" with the flow case) and the golden was byte-identical. npm's 5 stages, det, det_intro, seam, flash with the count check, validate (242 files, 0 errors, 0 warnings), its self-test (8662 of 8662), QA's run-all, loader, the flash self-test and Rendering's 15 checks all passed.
- **Quick, on 24a3bedc** (the shifting arena's window 3 on main): parity 70 of 70, golden byte-identical, validate 0 errors, self-test 8663 of 8663, det passed. b9e41bf6 adds only Encounter's parked docs.
- **With the switch off, nothing moves.** `light_flow` only acts on a hit that names it, and today no hit does until Encounter names one.
