# flash-split-fix (park, Tools, 2026-11-21)

CI run 44885894433 (the first run of the split, on 1f51ed22): every set passed and the merge worked, but the merged recount FAILED with 8 problems: `mashdummy` did not show `launch` and `signaturedummy` did not show `building_fall`, in both modes, for both of their pairings.

## What it was (not the merge)

- The doubled rows are by design: `mashdummy`, `signaturedummy`, `ring` and `blastdummy` each play two runs (sources.json `slotsList`: PROTAGONIST v REFERENCE and RIVAL v REFERENCE, a ring of three and one of five). Their file names carry the pair, so there is no collision (the new self-test proves that for all five sets).
- The failure is the sim, not the split. On b20020b4 (the last green run) `signaturedummy` showed 5 buildings down in 1,800 ticks. On HEAD (energy on, GW1a) the same 1,800 ticks stage 43 building hits and none falls, and the heavy at the end of the mash cycle is planned as a KNOCK BACK (`launch_plan` 1 to 2, `knockback` 2 to 3, no `launch`). The cancelled run's own log already showed `building_fall 0` for signaturedummy.

## What the patch does (`flash-split-fix.patch`, sha1 1a357bd2054b70678b95c9a328b88c09bcb2a524, `git apply --check` passes on ed1591cb)

1. `mashdummy` taps its heavy every 45 ticks from tick 480 of the 600-tick cycle (was one 10-tick tap at 480): one `launch` in each pairing, in both modes. `tools/flash/flash_worst.gd` and the same line in `render/tools/flash_capture.gd` (the drift check in tools/flash/selftest.js compares `_mash_dummy` line for line).
2. `signaturedummy` plays 3,600 ticks (sources.json, was 1,800): `building_fall` 5 with PROTAGONIST and 6 with RIVAL. At 2,400 ticks it was 0 with PROTAGONIST and 3 with RIVAL, so 3,600 is the shortest round figure that works for both. The guards (`launch` 1, `building_fall` 1) are not loosened.
3. `tools/flash/split-merge-selftest.mjs` (new, a step of `flash-selftests`, no Godot, 16 checks): reads ci.yml's `flash-cases` matrix, writes a synthetic run file for every name each set's args make flash_worst.gd write, merges the five folders as `merge-multiple` does and runs the real check-log.js on the merge. It fails if a name is written by two sets, if the sets do not write exactly the one-job run's files, if the merged recount does not pass, if the recount does not fail with any one set missing, or if a `mashdummy` without a launch is not named by the recount.
4. `tools/ci-budgets.json`: the measured figures of run 44885894433 (self-tests 8.0; sets 8.6 to 11.3: ai-1 8.6, ai-2 8.9, ai-3 9.2, scenes-1 9.5, scenes-2 11.3; recount 0.6). `docs/tools/dummy-ring-scenes.md` says what changed in the two scenes.

## Checked here (scratch export of HEAD, headless, below-normal)

- Both scenes at full length, all runs (mashdummy 4 runs of 1,800 ticks, signaturedummy 4 of 3,600) through the real `check-log.js --allow-missing`: no PROBLEM, every run under the caps (reduced signaturedummy 3 of 3 in one window, at the cap, not over it), 234 s in all. Normal weights 1.78 to 2.12 of 2.5.
- `node tools/flash/selftest.js` (100 checks, the drift check included), the new self-test (16 of 16), check-workflows, check-workflow-shell, ci-budgets-check: ok.
- Expected cost: `scenes-2` plays signaturedummy at twice the length, about +2 minutes (11.3 to about 13), inside the budget of 20.

## Needs a grant (not Tools' file)

- `render/tools/flash_capture.gd`: line 450 (`_mash_dummy`, `(u >= 480 and u < 490)` to `(u >= 480 and u % 45 < 8)`) and its comment above. Rendering's export copy of the same staging; without it the drift check fails. It also changes the mashdummy web clip (the pixel reading of that clip sees the heavy three times, not once).

## Not proven

- Not run on a runner. The scenes read on this PC; the sim is deterministic but the first CI run decides.
- The flashes of the mashdummy clip's new heavies are counted by the register here; the pixel reading of that clip has not been redone.
- `docs/tools/pending/flash-split/` (landed as 1f51ed22) is deleted by this park's author: the EP commits the deletion with the patch.
