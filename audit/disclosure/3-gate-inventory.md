# 3. Gate inventory

Each entry gives what the check claims, and whether it runs on the real build or on a stand-in, to my knowledge. Where I'm unsure, I say so.

## CI (`.github/workflows/`)
| Job | What it claims | Real build or stand-in |
| :--- | :--- | :--- |
| `ci.yml` qa | QA harness self-tests (`qa/run-all.js`) | The JS prototype's harness, not the shipped GDScript game |
| `ci.yml` sim | The JS sim's tests (`npm test --prefix sim`) | The JS parity oracle, not the shipped game |
| `ci.yml` data | Data files against `tools/schemas/` (`tools/validate.js`); gates deploy | The real data files |
| `ci.yml` flash | Flash register count checks | Headless Godot worst-case scenarios (`tools/flash/flash_worst.gd`) on the real code; counts events, not pixels |
| `ci.yml` godot-parity | The GDScript sim against the golden file | The real sim, headless |
| `ci.yml` net | Rollback, desync, transport and LAN checks | The real net code, headless loopback; ENet only in CI |
| `ci.yml` world | `tools/world-checks.json` run list | The real world code, headless |
| `ci.yml` site | Exports Web, assembles the site, runs the site checks (template, offline, interim click-through, Reduce flashing default, expiry) | The real Web export of HEAD, plus the pinned commit's export when online |
| `ci.yml` deploy | Publishes the site | The assembled site |
| `web-parity.yml` | Web against native parity | The real Web export (schedule and push) |
| `flash-pixels-dryrun.yml` | The pixel half of the flash check | Manual dispatch. My notes say the pixel half was "proven on a mock page only" (`flash-check-tooling` note); I don't know its state today |
| `desktop-builds.yml`, `linux-export.yml`, `web-template.yml` | Builds | Manual dispatch |

## Local gates the EP runs before landing
- `docs/ep/gate/run-gate.sh` (calls `render-gates.sh`): about 100 to 170 rows of headless Godot checks on a scratch export of the batch. It includes world checks, input tests, parity with the golden regenerated, rollback and desync, `hud_check`, anim, split and seam sweeps, soaks, the desktop package self-test, and a CI mirror at the end. It runs the real code, headless, with no window and no GPU pixels.
- `tools/flash/release-pass.mjs` and `signature-gate.mjs`, `nightly-seeds.mjs`: the release pass and signature gate. I haven't run these myself this week, and I don't know when they last ran on main.
- `tools/validate.js --self-test`, `tools/lint-determinism.mjs`, `tools/ratchet-two-fighter.mjs`, `tools/world-checks.mjs --verify|--run`: real repo files.
- `ui/tools/hud_check.gd`: largely the HUD demo scene with a mock feed. That's a stand-in for the HUD's drawing; it doesn't play a real match.
- Look gate (ADR 0010; `tools/flash/side-by-side.mjs`): side-by-sides are made by each director per change. Several this week were demo or staged scenes, not real matches; each report says which.

## Tools' build checks before a hand-over
- Smoke check, moving minute, sound log, struggle and refusal stills (`tools/preview/`, reports in `docs/tools/img/morning-1107-*`). These run on the real kept build in headless Chrome. Headless Chrome can't judge sound (output peak reads 0).
- Switch list (`switch-list.txt`). This proved unreliable on 2026-11-07: held rows were flipped anyway (fixed in `808a83ab`). The packed-data read (Tools' `pck-proof`, the stand-in's `check_build.py`) is the real check.

## Feel and balance (stand-ins by design)
- `tools/feel/gauntlet.mjs`: scripted pads against the computer. On 2026-11-07 the timing and stick arms were found to be scripted unrealistically (fixed in `705caf4b`).
- `tools/feel/ledger.mjs`, `feel.mjs`: replays of Orb's saved matches. These are real matches, but a replay on a newer tree diverges.
- `qa/godot/*`: QA's scripted arms and reads.
