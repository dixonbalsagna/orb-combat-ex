# run-ground: each stage's ring, picked from its opponent's claim (parked)

Owner: Simulation and Engine. 2026-10-23, on the EP's brief: Orb wants the opponents' stages assigned programmatically in story mode. Re-cut the same day for the EP's ruling (a run never fights the same ring twice: World's `opts.used`) and Game Design's (`rulings-2026-10-23.md` 4: the boss's ring wins over Whole's minimum). World's ring picker (`WorldRingPick`, window 4, on main) picks a ring from Narrative's claims (`data/narrative/opponent_grounds.json`); the run hosts it, stepped across the previous stage's beats. Behind `data/fight/run.json`'s `ground.enabled` (off). The page is `../../run-core.md` section 11.

## What it adds

- **`sim/core/run.gd` (`SimRun`)** contains:
  - the run's keyed hash `H` (run-core.md section 4), with `planetSeed` and `stageSeed`;
  - the stand-in homes;
  - `beginGround(run, chapter, opponent, opts)`, which returns a `GroundJob`. `opts.used` is the rings the run has fought: each stage's `setup.arena`, passed to World's picker, which passes them over. The result says `repeat` if it had to take one, and `waived` for a boss ring under Whole's minimum that holds his home and a standing city;
  - `bossWaived(ev, home)`: Game Design's waiver.
- **`GroundJob`** has these calls:
  - `frame()`: called once a frame during the beats; it reads a candidate every `framesPerRead` frames for the ring's size;
  - `step(n)`;
  - `finishNow()`: what is left, at once;
  - `setup()`: the next stage's `{planet, arena}`, with the ring as exact bits;
  - `matchSeed()`.
- **`sim/core/tools/run_ground.gd`**: a sample run's grounds, stage by stage.
  - Each stage's arena goes into the later picks' `used`.
  - Each pick is checked against one made at once.
  - Each stage's match is built from its setup alone and played twice.
  - A repeat is printed; a boss ring under the minimum without the waiver fails.
- **`data/fight/run.json`**: the switch (off), `framesPerRead` (Close 1, Half 1, Whole 3: World's costs, a Whole read is about four Close ones), `stagesBeforeBoss` 3, `phases` early, early, mid, and `provingSize` close.
- **`sim/core/tools/parity.gd`**, a new check, "the run's ground":
  - H's known answers, pinned;
  - the first stage is Close round the player's home;
  - a stage between, stepped a candidate a frame, is the pick made at once, and its setup, read back from JSON, builds a match of the ring's columns;
  - with that arena in `used`, the same chapter picks another ring, with no repeat;
  - the boss is on the Whole circle through his home, under Game Design's waiver when it misses Whole's minimum, and on his claim when nothing else stands;
  - the data ships off.

Nothing in a match's tick reads any of it, and nothing is hashed, so **the golden does not move.**

## Apply

On a clean export of b60d1913 or later, from the repo root, in one commit. **World's `used-rings` goes first:** the script refuses without `WorldRingPick.usedList`.

```
git -c core.autocrlf=false apply docs/world/scratch-build/used-rings/used-rings.diff
python docs/architecture/pending/run-ground/run_ground.py .
python docs/architecture/pending/run-ground/grant_tools.py .
```

`grant_tools.py` is Tools'. It adds:
- `tools/schemas/fight-run.schema.json` (closed);
- its rule in `map.json`, after boons';
- 7 cases in `cases.json`, after boons';
- the self-test's virtual copy of the data.

Besides `used-rings`, it needs nothing of World's: the picker, `arenaOf` and the planet match on an arena are all on main.

## Results (scratch, on b60d1913 with World's used-rings applied first)

- **Full:** apply and import were clean.
  - Parity on the committed golden: 72 of 72, with "the run's ground" ok, including the used-ring and waiver cases. The golden was byte-identical.
  - These all passed: npm's 5 stages, det, det_intro, seam, flash with the count check, validate (246 files, 0 errors, 0 warnings), its self-test (8709 of 8709, with Tools' 7 cases), QA's run-all, loader, the flash self-test and Rendering's 15 checks.
  - World's `ringpick_check` passed with 0 failed.
  - The determinism lint finds nothing in `run.gd`.
- **Three sample runs** (`run_ground.gd`, the Protagonist against the Rival, the Empress, the Cyborg, then the Rival as the boss; places held by earlier stages stand in for the run's wear; each stage's arena goes into the later picks' `used`):
  - every pick was the same stepped as at once;
  - every stage built from its setup alone played the same twice;
  - **no ring repeated** (0 repeats in 12 stages);
  - every boss ring under Whole's minimum held Game Design's waiver.

| Stage | 00c0ffee0badf00d | 5eed0000decade42 | 0123456789abcdef |
| :--- | :--- | :--- | :--- |
| 1, Rival (first) | Close round the player's home, city 3: plains 66% | Close round city 3: forest 69%, ocean 31% | Close round city 3: **ocean 70%, land 30%: under Close's minimum (land 40%)** |
| 2, Empress (claim, Half) | round town 22: her home city 1, city 10, 2 towns; score 0.93 | round town 30: city 2, 2 towns; 0.46 | through town 18: city 6, 2 towns; 0.66 |
| 3, Cyborg (claim, Half) | through town 30: cities 1 and 10 (damaged); 0.34 | **through town 33 (it took stage 2's ring before `used`)**: his home city 2, city 5, 2 towns; 0.32 | round town 7: cities 0 and 6, 2 towns; 0.50 |
| 4, Rival (boss, Whole) | through his home city 0 and city 1: 2 towns, waived | through city 0 and city 1: 0 towns, waived | through city 0 and city 1: 1 town, waived |

- **Cost (native):** a Half pick takes 48 frames, 156 to 221 ms in all, the worst frame 6 to 9 ms. The first and boss rings are one read each (2 and 9 ms).
- **A question for Game Design:** the first stage's ring, round the player's own home (`rulings-2026-10-19b.md` §2c), can miss Close's minimum too. Run 0123's stand-in home is a coastal city, and the ring round it is 70% ocean. Does the boss ring's waiver extend to it (the story's ring wins), or should World turn its bearing toward land?
