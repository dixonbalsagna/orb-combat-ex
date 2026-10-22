# mash-flow: a mash's later blows carry no stop, and the budget's deep step (parked)

Owner: Simulation and Engine. 2026-10-23. Game Design's `rulings-2026-10-22.md` 6 and 7d, on hit-stop by weight as applied (83405d99), behind the hit-stop switch (`data/fight/hitstop.json`, off). The page is `../../feel-core.md` section 7.

## The rule as built

**A mash flows (6):**
- **A new weight, `light_flow`, holds no stop (0 ticks).** Encounter names it for a mash's later blows, each landing within 12 ticks of the fighter's last.
- **The mash's first blow** stays `light_mash`, 2 ticks.
- **The second step's floor never raises a 0.** Without the guard, the cut's "at least 2" would turn a flowing blow into a 2-tick stop over the budget.
- **The budget never counts a flowing blow,** since it freezes nothing.

**The deep step (7d):**
- **Over 40% of the window frozen** (`budget.deepShare` 0.4: 240 frozen ticks of the same rolling 10 live seconds), the step is ×0.5 (`cutDeepMul`, rounded, at least `cutFloor` 2) in place of ×0.75.
- Over the deep line the six weights from `light_mash` to `launch_full` hold 2, 2, 3, 4, 6 and 7 ticks. Decisive and the KO hold 20 and 24, never cut. A flowing blow stays 0.
- The 18% budget and its ×0.75 step stand.
- **The line is the window's own:** frozen ticks against 600 live ticks. That is the measure of Encounter's probe and of QA's ten-second blocks.
- **It can't promise that no block passes 40%.** A 2 can't be cut, decisive blows and the KO never are, and a block is fixed where the window rolls. The probe below reads how close it comes.
- The data refuses a `cutDeepMul` above `cutMul`, and a `deepShare` under `share`.

## Apply

On a clean export of 886a61d8 or later, from the repo root, in one commit:

```
python docs/architecture/pending/mash-flow/mash_flow.py .
python docs/architecture/pending/mash-flow/grant_tools.py .
```

`grant_tools.py` is Tools'. It adds the hit-stop schema's `ticks.light_flow`, `cutDeepMul` and `budget.deepShare` (each required), and the self-test's virtual copy of the data.

## What it changes

- `sim/core/hitstop.gd`:
  - `light_flow` in the weights;
  - `cutDeepMul`, `deepTicks` and `deep(S)`;
  - the cut only for a stop above 0, and ×`cutDeepMul` over the deep line.
- `data/fight/hitstop.json`: `ticks.light_flow` 0, `cutDeepMul` 0.5, `budget.deepShare` 0.4, and the notes.
- `sim/core/tools/parity.gd`, the hit-stop check:
  - `light_flow` holds 0 and stays 0 over the budget;
  - the deep line is 240;
  - a tick under it a heavy holds 6, and over it the deep values;
  - 10 s of fight later the budget is back;
  - a flowing blow leaves the clock running.

## For Encounter

Name a mash's later blows `{"weight": "light_flow"}` in the hit's options; the first blow stays `light_mash`. A hit that names it holds no stop. A stop already in force (an earlier blow's, a contact's) runs on, since stops merge by the longer one.

## Results (scratch)

- **Full, on 3c2e6808:** apply clean, import clean.
  - Parity on the committed golden: 70 of 70 ("hit-stop by weight" with the flow case and the deep step). The golden was byte-identical.
  - These all passed: npm's 5 stages, det, det_intro, seam, flash with the count check, validate (242 files, 0 errors, 0 warnings), its self-test (8663 of 8663), QA's run-all, loader, the flash self-test and Rendering's 15 checks.
- **Quick, on 243d4b57** (press-tick on main, which moved the golden): parity 70 of 70 on the new golden, golden byte-identical, validate 0 errors, self-test 8663 of 8663, det passed. 1605d73a changes only Rendering's files.
- **With the switch off, nothing moves.** `light_flow` only acts on a hit that names it, and no hit names one until Encounter's park lands.

**In play** (scratch probe: Encounter's `hwp.gd` with a count of blocks over 40%; 10 AI matches of 3 minutes, seed 1, hit-stop on). Blocks are 600 live ticks; over 18% is more than 108 frozen ticks, over 40% more than 240.

| | Hit-stop share | Blocks over 18% | Blocks over 40% | Worst block |
| :--- | :--- | :--- | :--- | :--- |
| No flow, ×0.75 only (as on main) | 21.3% | 99 of 133 | 20 | 297 ticks |
| No flow, with the deep step | 20.8% | 98 of 134 | 16 | 279 ticks |
| Flow emulated, ×0.75 only | 13.6% | 66 of 148 | **0** | 173 ticks |
| Flow emulated, with the deep step | 13.6% | 66 of 148 | **0** | 173 ticks (the deep line never reached) |

- **The mash flow is what keeps every block under 40%.** With it, the worst block is 173 frozen ticks (29%), and the deep step is a backstop that never fires.
- **Without the flow, the deep step can't hold the line.** The bulk is 2-tick mash blows, which no step can cut under its floor of 2. The deep step only trims the heavier stops: 20 blocks over 40% fall to 16.
- **The flow emulation was a scratch-only patch in the probe's copy.** It named a `light_mash` as `light_flow` when the same attacker's last `light_mash` was within 12 live ticks. Encounter's own emulation read 12.4%; its run definition may differ from mine.
