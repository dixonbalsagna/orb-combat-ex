# The flash nightly judged against recorded values (Tools, parked 2026-11-21; the EP's decision, for the EP, not for Orb)

The EP's rule: the nightly stays red on any clip that reads **worse** than its recorded value, on any new clip and on any missing reading; it goes green only when every clip equals or beats its recorded value. The outside-tester gate (G21) and the release pass still read the absolute line, unchanged. The six-night values are the baseline.

`nightly-baseline.patch` (sha1 `338a3f2fff21f4d903a0cd49bb4b23544b4c899b`, applies to HEAD, six files):

| File | Change |
| :--- | :--- |
| `tools/flash/nightly-baseline.json` (new) | each clip's four recorded readings (primary, red, area-15%, two-second memory): **the worst of the six scheduled nights of 15 to 20 November** (clash-night normal: of five, 16 November was not read), over-the-line values recorded as they are; **collapse-normal is the exception: its five-night value, 2 / 2 / 2** (the EP, 2026-11-21: no allowance) |
| `tools/flash/nightly-ci.mjs` | `--baseline <file>`: exit 0 when every clip equals or beats its record (over the line as recorded is a note; better is a note), **4** when a clip reads worse on any of the four, **5** when a clip has no recorded value, **2** (as before) when a clip or one of its readings is missing. Without `--baseline` nothing changes: the old verdict, exits 0 to 3 |
| `tools/flash/nightly-ci-selftest.mjs` | 20 new checks (47 in all, 27 before): each reading one step worse, a new clip, a missing reading, equal, better, the real file, the command end to end |
| `.github/workflows/flash-nightly.yml` | the verdict step passes `--baseline tools/flash/nightly-baseline.json` and turns exits 1, 2, 4 and 5 red (3 is no longer produced in this mode) |
| `docs/tools/flash-nightly.md`, `docs/tools/runs/09aa0f44/flash-nightly-scheduled-2026-11-15-to-20.md` | a section saying how it works, and the record's closing bullet now says the six-night values are the baseline |

## Proof

- Self-test **47 checks, 0 failed**. **Negative control:** with the comparison loosened (a reading must be one step *more* worse to count), exactly the **eight** checks that ask for red on a worse reading fail (the one-step-worse checks on the four readings, the report, the real file, the command, and the new collapse-normal one); restored, 0.
- **The six real nights replayed through the new verdict** (each clip judged alone, as the workflow does, from the saved run logs): **46 of the 48 clip-nights are green; the two that are not are 16 November's clash-night normal (not read, exit 2) and 19 November's collapse-normal (3 / 3 / 4 against its recorded 2 / 2 / 2: red, exit 4, as ruled).** Every other clip is recorded at its worst of the six, so every other night reads at or under it.
- `check-workflows` ok (13 files), `check-workflow-shell` ok (258 run steps) on a scratch export with the patch. `check-workflow-paths` is clean once `tools/flash/nightly-baseline.json` is tracked (the patch adds it).

## What to know

- **collapse-normal is recorded at its five-night value, 2 / 2 / 2, with no allowance (the EP, 2026-11-21):** a noisy night going red is the tripwire doing its job and a slip from 2 to 3 must show. The cost to expect: the runner's noise moved this clip to 3 / 3 / 4 once in six nights (19 November), so about one night in six may go red on this clip alone with no change in the game; the replay above shows exactly that night turning red.
- Every other clip is recorded at the **worst** of its six nights, so the runner's noise inside that range cannot turn the nightly red; a clip has to read worse than anything it read in six nights. Every night's wall time (98 to 152 min) and the 960x540 software reading are unchanged.
- Not run on a runner (the nightly is a 2-hour job): the new flags are exercised by the self-test and by replaying the six real nights, not by a scheduled run. Read the first scheduled night after landing: all eight jobs should be green or red for a stated reason.
- Not touched: `tools/flash/verdict.js`, `run-pixels.mjs`, `signature-gate.mjs` and every G21 and release-pass path (nothing imports `nightly-ci.mjs`'s `judge` except the nightly and its self-test).
