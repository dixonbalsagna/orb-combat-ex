# Runs: bystanders window 1 (World, 2026-11-07), on main ea8dc190 (no file the park touches moved to 0a3297b8) with no-casualty-feed applied

CD-22. Park: `docs/world/pending/bystanders/`. Logs are the tail of each run in a scratch export with both parks applied (the sweep of other checks ran before the rebase onto no-casualty-feed, on main with this park alone: the files they touch are the same).

| File | What |
| :--- | :--- |
| `bystanders-check-passes.txt` | `BYSTANDERS: 0 check(s) failed`: 81 people ran, none died, no meter rose |
| `bystanders-check-NEGATIVE-CONTROL-meter-gain-and-count-put-back-in-scatter.txt` | the same check with a menace gain, a power gain and a count put back inside `scatter`: **17 FAIL lines** (the count and the meters, per seed and cause) |
| `parity-before-golden-regen-FAILS-as-meant.txt` | golden check FAILED: the roster data hash, the intro phases, the matches' per-tick digests (the evacuate events), the replays: meant, Simulation regenerates |
| `parity-after-golden-regen-passes.txt` | golden regenerated in the scratch tree and parity passed |
| `wrecks_check.txt`, `collateral_check.txt`, `probe.txt`, `far_people_check.txt` | each 0 failed after the park (wrecks_check had 3 before its update: the flight is always on now) |
| `other-world-checks.txt` | the verdict lines of 20 other World checks: all 0 failed |
| `validate.txt`, `verify.txt` | `validate.js` 319 files 0 errors; `world-checks --verify` ok, 84 checks |

Not run: the whole World list (about 86 scripts; the machine was at 100% with 30 other Godot jobs, 14 finished in half an hour), the director and render gates (no render or director file is touched), `enet_check` (CI only).
