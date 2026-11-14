# Alpha audit: baseline (phase 0)

Recorded by the reading session on 2026-11-13 at 20:05 PST. Every finding in this audit is measured against this baseline. Work landed later is noted beside a finding, never re-audited.

## Commit

- `HEAD` = `origin/main` = `8901d351e3d9c749bea53a2d63b167997136da0a` (2026-11-13 19:59 PST, "EP: Orb confirms specials and signatures cost stamina as well as energy (vision.md, verbatim)").
- Tracked files: 8,214 (`git ls-files`). GDScript files: 989. Data files under `data/` (`*.json`): 286.
- Code drift from the build Orb last played (6a30b4c9) to the baseline, over `sim render ui net data audio tools project.godot export_presets.cfg`: 3 files, all tools (`tools/clips/mms-scan.mjs`, `tools/preview/smoke.mjs` and one more; `git diff --stat 6a30b4c9 HEAD`). The 23 commits since 6a30b4c9 are otherwise docs and records. So the game code at the baseline is the game code Orb played.

## Working tree

`git status --porcelain -uall` saved to `baseline-status.txt`: **14,805 paths** (75 modified, 27 deleted, 14,703 untracked). Untracked paths are mostly saved run output: `docs/tools` 8,610, `docs/rendering` 5,086, `docs/director` 225, `art/animation` 112, `research/planet-gen` 96. A path listed there is cited "(uncommitted)".

## CI at the baseline (`gh run list`, read 20:05 PST)

| Workflow | Latest run | Commit | Result |
| --- | --- | --- | --- |
| CI | 43554356718 | 8901d351 | **pending** at baseline time; the run on 35cc89e9 (43553420852) still in progress; the three runs between were cancelled by newer pushes |
| CI, last completed green | 42866500996 | 3a03e03f | success (2026-11-10) |
| Content screen | 43554356728 | 8901d351 | success |
| Workflow lint | 43554356732 | 8901d351 | success |
| Player watch | 43505870115 | 3a03e03f | success (scheduled, 2026-11-13) |
| Web parity | 43414223230 | 3a03e03f | success (scheduled, 2026-11-13) |
| Takedown | 42440408155 | 29ad8082 | success (2026-11-08) |
| Web template | 40624057612 | a08b8fa9 | success (2026-10-28); run before it failed |
| Flash pixels dry-run | 37520705360 | a451a94c | success (2026-10-06) |
| Desktop builds | none | none | **no run on record** (`gh run list --workflow desktop-builds.yml` returns nothing) |

Nine workflows exist in `.github/workflows/`. The judgment session should re-read CI for 8901d351 before citing it (`gh run view 43554356718`).

## Orb's two builds

| Build | Folder | What it is |
| --- | --- | --- |
| Solo | `homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d/` (62 MB, made 2026-11-09 14:48) | A **browser build** served from a folder (`serve.cmd` / `serve.mjs`, `web/index.pck`, `web/index.wasm`). `tree/` holds the build's own `sim/`, `data/` (page switches flipped), `net/`, `project.godot`. Its README names commit 6a30b4c9 and the switch stack `ug+soundMoments+soundCarry`, and opens with page words `planet=7&meteor=loud&tiles=1&go=1&blackbox=1`. |
| LAN | `homework/Files/builds/orb-lan-6a30b4c9/` (129 MB, made 2026-11-09 15:46) | A **Windows desktop program** (`orb-combat-lan.exe`), with host/join scripts for 1v1 and 2v2, firewall scripts, `Make my report folder.cmd`, `saved/` and `tree/`. |

These are the newest builds in `homework/Files/builds/` by date. Tools' pack check records for both are asked of the EP (AQ-05).

## Meters (first reading, 20:05 PST)

- Weekly, all models: **2%** (resets 2026-11-20 19:00 PST). Stop guard at 30%.
- Weekly, Fable: 3%.
- This session's own context at baseline: about 0.13M tokens.
