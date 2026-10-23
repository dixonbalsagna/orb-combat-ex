# first-ring-host: the run's first stage stepped like the others (parked)

Owner: Simulation and Engine. 2026-10-23, on the EP's brief. Game Design ruled that the first stage's ring turns toward land when it is under Close's minimum, keeping the home on it (`rulings-2026-10-23.md` 6), and World built it as a stepped job (`docs/world/scratch-build/first-ring/`: `beginFirstRing` and `FirstJob`). This switches run-ground's first stage to that job. The page is `../../run-core.md` section 11.

## What it changes

- **`sim/core/run.gd`:**
  - `beginGround`'s first stage calls `WorldRingPick.beginFirstRing(P, home, stream, {standing, damaged})`, in place of `firstRing`.
  - `GroundJob.step` reads its rings a read a frame (the data's Close pace). That is one read when the story's ring meets Close's minimum, and 13 when it is turned.
  - The job then reads the chosen ring once more, for its report (`ev`, `ok`).
  - The result says `turned`.
- **`sim/core/tools/run_ground.gd`:** the sample prints a turned ring and its land share.
- **`sim/core/tools/parity.gd`, "the run's ground":**
  - the first ring of run 00c0ffee0badf00d, which meets the minimum, is not turned;
  - run 0123456789abcdef's coastal home has its first ring turned, meeting the minimum and holding the home, a read a frame.

It is behind `data/fight/run.json` (off), as run-ground is. Nothing in a match's tick reads it, so **the golden does not move.**

## Apply

On 07876704 or later (run-ground, World's used rings and the pi swap are on main), in one commit with World's `first-ring` (sha 8081f098592f), from the repo root:

```
git -c core.autocrlf=false apply docs/world/scratch-build/first-ring/first-ring.diff
python docs/architecture/pending/first-ring-host/first_host.py .
```

The script refuses without `SimRun` or `beginFirstRing`. It needs no grant.

## Results (scratch, on 570c3113 with World's first-ring applied first)

- **Full:** apply and import were clean.
  - Parity on the committed golden: 72 of 72, with "the run's ground" ok, including the turned and unturned first rings. The golden was byte-identical.
  - These all passed: npm's 5 stages, det, det_intro, seam, flash with the count check, validate (246 files, 0 errors, 0 warnings), its self-test (8709 of 8709), QA's run-all, loader, the flash self-test and Rendering's 15 checks.
  - World's `ringpick_check` passed with 0 failed.
  - The determinism lint passed: none of the engine's math anywhere in the sim.
- **Three sample runs** (the same as run-ground's): every pick was the same stepped as at once, every stage played the same twice from its setup, there were 0 repeats, and every boss ring was waived.
  - **The first stage**, run by run:
    - 00c0ffee0badf00d and 5eed0000decade42: the story's ring meets Close's minimum, so it is unchanged (2 reads, 2 frames).
    - **0123456789abcdef:** the coastal home's ring (ocean 70%, land 30%) is **turned toward land: land 81%** (forest 63%, plains 18%, ocean 19%). It holds the home city 3 and towns 11 and 14, and it was picked in 14 frames, 14 reads, 18 ms natively in all.
  - The later stages are the same rings as before in the first two runs. In run 0123 they are the same too, though the first stage now holds two more towns, which go to the later picks as damaged.
