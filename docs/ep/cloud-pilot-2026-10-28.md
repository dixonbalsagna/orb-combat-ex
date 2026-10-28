# Cloud pilot: headless gates on a cloud machine (2026-10-28)

Verdict: yes, this machine runs every headless gate, all green. The full set took about 31 minutes run back to back (about 1,850 s of check time).

## Machine
- Linux 6.18.44-fc-v180 x86_64 VM, 4 cores, 15 GB RAM (no swap), 252 GB disk (30 GB free). Node v22.22.0, Python 3.11.17.
- Branch `main` at HEAD `811134ef673b1faff2c45b3d484bd0a7c3c0b6d8`. No game code or data changed.

## Godot
- `https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip` (download took 3 s through the proxy). No export templates.
- SHA-512 matches the pin in `.github/actions/setup-godot/action.yml`: **yes**. `--version` reports `4.7.2.stable.official.ed1daf0bf`.
- `GODOT=/tmp/godot-dl/godot` is all the sim runner needs (`sim/core/tools/run-all.js` reads `GODOT`; its default is a Windows path).

## Checks (run one at a time, so timings are not contended)
| Check | Time | Exit | Last line |
|---|---|---|---|
| `--import` | 12 s | 0 | editor layout loaded |
| `node tools/validate.js` | 0 s | 0 | 277 files checked, 0 errors, 0 warnings |
| `validate.js --self-test` | 61 s | 0 | parser 282 files + 7 text cases; engine 46 cases + 6 unsupported; schemas 169; data cases 8149 |
| `lint-determinism.mjs` | 1 s | 0 | determinism lint ok |
| `npm test --prefix sim` | 538 s | 0 | all 5 stages passed (unit 14.6 s, parity 104.2 s, soak 25.2 s, golden 0.7 s, godot 392.7 s) |
| `anim_check.gd` | 384 s | 0 | anim check passed (9537 checks) |
| 39 World `*_check.gd` | 581 s total (2 to 114 s each; slowest ringpick 114 s, epoch 70 s, campaign 53 s, switchon 45 s) | all 0 | each prints `<NAME>: 0 check(s) failed` |

## Notes
- `lane_check.gd` exits 0 but prints no "check(s) failed" line. Its last line is `LANES Bellgate: 10 avenues, ... across an avenue: 0`.
- `anim_check.gd` ends with Godot's usual exit warnings (270 leaked ObjectDB instances, 7 resources in use) after "anim check passed"; the exit code is 0.
- Nothing failed, was skipped or exceeded 15 minutes. Godot runs were sequential, one process at a time.
- With 4 cores, running the World checks 3 at a time would cut that part to about 4 minutes, and `npm test`'s godot stage is the longest single item (about 6.5 min).
