# Runs: no-casualty-feed (World, 2026-11-07), tested on main 85e838b6 (the park applies on b875511e too: no file it touches moved between them)

CD-05 / CD-22. Park: `docs/world/pending/no-casualty-feed/`. Logs are the tail of each run, in a scratch export of 85e838b6 with the park applied.

| File | What |
| :--- | :--- |
| `casualty-feed-check-patched.txt` | `CASUALTYFEED: 0 check(s) failed`: 9 kills over 3 worlds, 81 people died, no menace or power rose |
| `casualty-feed-check-NEGATIVE-CONTROL-unpatched-files.txt` | the same check with the three unpatched files put back: **9 failed** (the villain gains menace 10.0 to 11.9 and power 10.0 to 10.2 from one kill, the 0.9 row is in his data, collateral.gd has three writes to menace or power). The old summary line at its foot is unconditional text; read the FAIL lines |
| `parity-unpatched-passes.txt` | golden check passed on main without the park |
| `parity-patched-moves-golden.txt` | golden check FAILED with the park: the roster data hash (data/fighters/ changed) and the villain's match vectors (swap-flip seed 2, first difference at tick 14640, and mirror-villain-flip seed 2): meant, Simulation regenerates |
| `parity-after-golden-regen-passes.txt` | golden regenerated in the scratch tree (`golden-regen.patch` in the park) and parity passed |
| `probe.txt`, `far_people.txt`, `cross.txt` | `probe: 0 check(s) failed`, `FARPEOPLE: 0`, `CROSS: 0` |
| `validate.txt`, `verify.txt` | `validate.js` 319 files 0 errors; `world-checks --verify` ok, 84 checks |
