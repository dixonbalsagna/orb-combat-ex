# run-ground: each stage's ring, picked from its opponent's claim (parked)

Owner: Simulation and Engine. 2026-10-23, on the EP's brief: Orb wants the opponents' stages assigned programmatically in story mode. World's ring picker (`WorldRingPick`, window 4, on main) picks a ring from Narrative's claims (`data/narrative/opponent_grounds.json`); the run hosts it, stepped across the previous stage's beats. Behind `data/fight/run.json`'s `ground.enabled` (off). The page is `../../run-core.md` section 11.

## What it adds

- **`sim/core/run.gd` (`SimRun`)** contains:
  - the run's keyed hash `H` (run-core.md section 4), with `planetSeed` and `stageSeed`;
  - the stand-in homes;
  - `beginGround(run, chapter, opponent, opts)`, which returns a `GroundJob`.
- **`GroundJob`** has these calls:
  - `frame()`: called once a frame during the beats; it reads a candidate every `framesPerRead` frames for the ring's size;
  - `step(n)`;
  - `finishNow()`: what is left, at once;
  - `setup()`: the next stage's `{planet, arena}`, with the ring as exact bits;
  - `matchSeed()`.
- **`sim/core/tools/run_ground.gd`**: a sample run's grounds, stage by stage. Each stage's pick is checked against one made at once, and each stage's match is built from its setup alone and played twice.
- **`data/fight/run.json`**: the switch (off), `framesPerRead` (Close 1, Half 1, Whole 3: World's costs, a Whole read is about four Close ones), `stagesBeforeBoss` 3, `phases` early, early, mid, and `provingSize` close.
- **`sim/core/tools/parity.gd`**, a new check, "the run's ground":
  - H's known answers, pinned;
  - the first stage is Close round the player's home;
  - a stage between, stepped a candidate a frame, is the pick made at once, and its setup, read back from JSON, builds a match of the ring's columns;
  - the boss is on the Whole circle through his home, and on his claim when nothing else stands;
  - the data ships off.

Nothing in a match's tick reads any of it, and nothing is hashed, so **the golden does not move.**

## Apply

On a clean export of 52eefa5e or later, from the repo root, in one commit:

```
python docs/architecture/pending/run-ground/run_ground.py .
python docs/architecture/pending/run-ground/grant_tools.py .
```

`grant_tools.py` is Tools'. It adds:
- `tools/schemas/fight-run.schema.json` (closed);
- its rule in `map.json`, after boons';
- 7 cases in `cases.json`, after boons';
- the self-test's virtual copy of the data.

It needs nothing of World's: the picker, `arenaOf` and the planet match on an arena are all on main.

## Results (scratch, on 52eefa5e)

- **Full:** apply and import were clean.
  - Parity on the committed golden: 71 of 71, with "the run's ground" ok. The golden was byte-identical.
  - These all passed: npm's 5 stages, det, det_intro, seam, flash with the count check, validate (246 files, 0 errors, 0 warnings), its self-test (8709 of 8709, with Tools' 7 cases), QA's run-all, loader, the flash self-test and Rendering's 15 checks.
  - The determinism lint finds nothing in `run.gd`.
- **Sample runs** (`run_ground.gd`, the Protagonist against the Rival, the Empress, the Cyborg, then the Rival as the boss; places held by earlier stages stand in for the run's wear). Every pick was the same stepped as at once, and every stage built from its setup alone played the same twice.

| Run 00c0ffee0badf00d | Ring | Holds | ok, must, score |
| :--- | :--- | :--- | :--- |
| 1, Rival | first: Close round the player's home (city 3) | plains 66%, desert 18%, forest 16%; city 3 | yes, no, 0.34 |
| 2, Empress | her claim at Half: round town 22 | plains 42%, ocean 26%; her home city 1, city 10, 2 towns | yes, yes, 0.93 |
| 3, Cyborg | his claim at Half: through town 30 | desert 22%, ocean 29%; cities 1 and 10 (damaged at stage 2), 2 towns | yes, yes, 0.34 |
| 4, Rival (boss) | the Whole circle through his home (city 0) and city 1 | forest 38%, ocean 30%, ice 13%, mountains 8%; 2 cities, 2 towns | **no**, yes, 0.20 |

| Run 5eed0000decade42 | Ring | Holds | ok, must, score |
| :--- | :--- | :--- | :--- |
| 1, Rival | first: Close round city 3 | forest 69%, ocean 31%; city 3 | yes, no, -0.02 |
| 2, Empress | round town 30 | ocean 49%, plains 28%; city 2, 2 towns | yes, yes, 0.46 |
| 3, Cyborg | **round town 30 again: stage 2's ring** | the same | yes, yes, 0.69 |
| 4, Rival (boss) | Whole, through city 0 and city 1 | ocean 37%, forest 23%, ice 15%; 2 cities, 0 towns | **no**, no, 0.11 |

- **Cost (native):** a Half pick takes 48 frames, 180 to 221 ms in all, the worst frame 6 to 9 ms. The first ring and the boss's ring are one read each (2 and 9 ms).
- **Findings for the EP:**
  - **The same ring twice in a row.** In run 5eed, the Cyborg's claim (wreckage, damaged places) takes the ring the stage before was fought on. The picker has no input for the rings a run has used. That is World's option (rings to pass over or score down) and Game Design's or Narrative's call (is a revisit the Crossing's, never the same ring?).
  - **The boss's Whole circle can miss Whole's minimum** (2 cities, 3 towns, 3 biomes): it is fixed by Game Design's 2c rule, so the minimum is not applied. Both samples hold fewer than 3 towns.
