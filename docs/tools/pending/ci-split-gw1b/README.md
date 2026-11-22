# ci-split-gw1b (park, Tools, 2026-11-22; the EP's order: main's CI cannot go green without the first patch)

CI run 45053322332 on bce578a7 (GW1b landed, the planet is the default world): two jobs were cancelled at their limits, and four more finished with almost nothing to spare. Same job as the flash split: measure, then split.

## What the run says (every figure is that run's own step times, read with `gh run view --json jobs`; the last green run is 44893744108 on d168a518)

| Job | Limit | Took | Why |
| :--- | :--- | :--- | :--- |
| `godot-audio-vfx` | 30 | **cancelled at 30.2** | the VFX hash check ran 21.0 minutes and was not done (18.2 on the last green run); the audio checks and the effects check are 9 |
| `net-2` | 45 | **cancelled at 45.2** | 14 steps took 40.3 minutes, the kick and ENet steps never ran: about 57 in all (25.3 on the last green run). LAN game side 2.3 to 11.4, its control 1.0 to 4.8, second word 2.1 to 4.3 and 3.1 to 6.2 |
| `godot-parity` | 45 | 42.6 | GDScript parity 6.7 to 13.2, two states 3.4 and 5.8 to 4.5 and 7.2 |
| `godot-roll-render` | 45 | 42.5 | bark reads 9.0 to 18.6, render determinism 10.6 to 8.3 (faster) |
| `net` | 45 | 35.9 | 16 steps of 1 to 4 minutes |
| `world` | 45 | 33.9 | one step, 90 checks, 32.2 minutes |

The same step takes up to twice as long, or half as long, from one runner to the next (render determinism got faster while the bark reads doubled), so a job at 42 of 45 minutes is a job that is cancelled by the next slow runner. The set-up of a job is only about half a minute (checkout, Godot, import), so splitting costs almost nothing.

## Two patches, in this order

**1. `ci-critical.patch`** (sha1 `11f3be085311ffaa7f624b229c350f5f1426ed37`; applies to bce578a7; `ci.yml` and `ci-budgets.json`): the two cancelled jobs.

- `godot-audio-vfx` keeps the 13 audio checks and the effects check (9 minutes, budget 20, limit 30). **`godot-vfx-hash`** is the VFX hash check alone: **limit 60, budget 40**, not measured to the end on a runner (18.2 before GW1b, over 21 after; 590 to 847 s locally on the planet). One process, one aggregate verdict (`hash_check.gd` requires that the effects ran in at least one of its four seeds), so it cannot be cut by seed from CI without a change in the check itself. **If the first run needs more than 40 minutes, VFX (its owner) is asked, through the EP, to let it run per seed or fewer ticks: that is the owner's call, not CI's.**
- `net-2` becomes three jobs, in the original order of the steps: `net-2` (second word and its control, right stick, two-PC pair: 14.3 minutes measured), `net-3` (LAN game side pair 16.2 measured, the field rollback control 1.0, the four kick steps), `net-4` (the field desync pair 11.5 measured, the three ENet steps). The kick and ENet steps never ran on GW1b: their share (about 6 and 7) is an estimate, twice their time on the last green run, until the first run.
- `deploy` waits for the new jobs; `tools/ci-budgets.json` has a written row for each (45 limit, 30 budget; 60 and 40 for the hash).

**2. `ci-preventive.patch`** (sha1 `6a552ec32cd70387d2bd5bc23161de4d9dad74fc`; four files: `ci.yml`, `ci-budgets.json`, `tools/world-checks.mjs`, the new `tools/world-checks-selftest.mjs`; applies after the first; the jobs that finished too close to their limits):

- `godot-parity` in three (`godot-parity`: GDScript parity, load split, places 14.4; `-b`: two states pair, kick, replays 15.6; `-c`: fork, memo, chase, the 13 camera checks about 13).
- `godot-roll-render` in three (rollback and field checks 10.9; render determinism, sweeps, mode smoke 14.0; bark reads alone 19.0).
- `net` in two (desync, spectator, delay, transport, rollback AIs and depth about 18; takeover, dropped peer, calm turn, swing about 17).
- `world` as a matrix of three shards: **`tools/world-checks.mjs --run --shard K/3`** (new: every third check of the list; `--list` takes it too), the floorlift and plane steps in shard 1 only, a new self-test `tools/world-checks-selftest.mjs` (16 checks: every shard count from 1 to 7 runs every check exactly once, sizes differ by at most one, a bad shard is refused; a mutant that drops a shard's checks fails 13 of them). Per-check times from that run's log: shards of 12.6, 10.6 and 8.9 minutes of checks. Limit 30, budget 20.
- Same `deploy` and budget rows. Every part of every split has limit 45 and budget 30 except the world shards (30 and 20), because a runner twice as slow as the last one must not cancel it.

## Checked here

- A scratch git of bce578a7: patch 1 applies; patch 2 applies after it (and, as it names patch 1's deploy line, not alone). `check-workflows` ok (13 files), `check-workflow-shell` ok (278 run steps after patch 1, 284 after both), `ci-budgets-check` ok (every job has a row, every budget at most two thirds of its limit), the world self-test ok.
- The splitter asserts that every step of a cut job lands in exactly one part, that the common steps (checkout, Godot, import) are in every part, and that a comment above a step stays with it. The diff shows no step added, removed or edited, only moved, plus the new job headers, comments and the world matrix.
- `check-scripts-table` adds nothing unreviewed for the new self-test (it is wired by the world job).

## Not proven

- Nothing here ran on a runner: the first run of the split jobs decides the figures. The measured time of `godot-vfx-hash` and the estimates for the kick, ENet and the net halves are to be recorded from it, as with the flash split.
- Total runner minutes go up by about half a minute a new job (about 12 more jobs); wall time falls from about 57 minutes to the longest part (about 24).
- The names of the jobs changed ("Network checks 3 of 5"...). Nothing in the repository reads a CI job name except `tools/ci-budgets-check.mjs --runs`, which takes the titles from ci.yml and matches GitHub's job names exactly: a matrix job's title (the world shards, as the flash cases already) has `${{ }}` in it and does not match its expanded name, so that by-hand check skips those. If branch protection lists required checks by name, those names need updating by hand on GitHub.
