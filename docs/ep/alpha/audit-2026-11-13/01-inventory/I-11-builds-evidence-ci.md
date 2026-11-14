# I-11 Builds, evidence and CI (inventory)

- **Slice:** I-11 builds-evidence-ci
- **Covers:** `homework/Files/builds/*` (Orb's kept builds), every `docs/*/runs/` folder (counted, not read), `.github/workflows/*.yml` and their last 30 runs on GitHub.
- **Tracked files:** 1051 (`git ls-files`: 0 under `homework/Files/builds` because `homework/` is git-ignored; 1042 under `docs/*/runs/`; 9 workflow files).
- **Total lines (tracked):** 71,184 (`docs/*/runs` + workflows; workflows alone 1,060).
- **Uncommitted paths (baseline-status.txt):** 260, all `??` (untracked); 0 modified, 0 deleted. By area: director 135, sim 43, ui 36, world 25, camera 7, vfx 7, rendering 5, controls 2. None under `.github/workflows`. `homework/` is ignored so not in the status.
- **Taken at:** HEAD 8901d351 (2026-11-13 19:59 -0800). GitHub data read 2026-11-13 via `gh run list` / `gh run view`.

## 1. Builds in `homework/Files/builds/` (18 folders, untracked, git-ignored)

Browser builds (`orb-first-play-<commit>-<stack>`): each has `README.txt`, `serve.cmd`, `serve.mjs`, `tree/`, `web/` (9 web export files: index.html/js/wasm/pck and worklets). Desktop builds (`orb-lan-<commit>`): `orb-combat-lan.exe`, Host/Join `.cmd` launchers, firewall allow/remove `.ps1`, `READ ME FIRST.txt`, `tree/` (except 3d997381). All ten build commits are ancestors of HEAD (`git merge-base --is-ancestor`).

| Folder | Kind | Commit (README line 1) | Made (README line 2 / folder mtime) | Parks stacked | Switches named in README |
|---|---|---|---|---|---|
| orb-first-play-018b4edf-fc994af8 | browser | 018b4edf | 2026-11-01T19:05Z | 57 | cache tag `ug+soundMoments+soundCarry`; URL `planet=7&meteor=loud&tiles=1&go=1&blackbox=1` (README:5) |
| orb-first-play-018b4edf-fddd34b4 | browser | 018b4edf | 2026-11-01T19:05Z | 58 | same tag and URL |
| orb-first-play-3d997381-7e2d88ff | browser | 3d997381 | 2026-11-02T07:13Z | 92 | same |
| orb-first-play-ad13b776-3345c90c | browser | ad13b776 | 2026-11-02T08:20Z | 102 | same |
| orb-first-play-18852c72-72c49cb5 | browser | 18852c72 | 2026-11-02T08:48Z | 107 | same |
| orb-first-play-18852c72-4bd5caca | browser | 18852c72 | 2026-11-02T08:55Z | 114 | same |
| orb-first-play-10d8b8cf-68ee07cc | browser | 10d8b8cf | 2026-11-02T10:45Z | 120 | same |
| orb-first-play-a8bc66e2-e80b8e3d | browser | a8bc66e2 | 2026-11-07T16:55Z | 1 | same; commit line names "Controls' and UI's switches on" |
| orb-first-play-1931a0f8-7a5a2d2c | browser | 1931a0f8 | 2026-11-08T11:54Z | 1 | same |
| orb-first-play-091dfac9-a34be195 | browser | 091dfac9 | 2026-11-08T15:02Z | 1 | same |
| orb-first-play-6eec6a75-62e1fea3 | browser | 6eec6a75 | 2026-11-09T13:58Z | 1 | same |
| orb-first-play-6a30b4c9-6627cb9d | browser | 6a30b4c9 | 2026-11-09T22:48Z | 1 | same; commit line names "Rail menus (switch)", `chargeLostCue` |
| orb-lan-3d997381 | desktop (LAN exe) | 3d997381 (folder name) | mtime 2026-11-01 23:44 | n/a | Host/Join launch flags `--lan-host`, `--lan-log`, `--tiles=1`; "input wait 2/3 ticks" (README:23,29); no 2v2-together launcher, no `tree/` |
| orb-lan-a8bc66e2-c | desktop | a8bc66e2 (tree/README.txt:1-3: page e80b8e3d, "the held switches off", main's net/ laid over) | mtime 2026-11-07 13:39 | n/a | same flags; LAN kit edits `ui/data/features.json` (tree/README.txt:4) |
| orb-lan-1931a0f8 | desktop | 1931a0f8 (tree/README.txt:1) | mtime 2026-11-08 04:02 | n/a | same |
| orb-lan-091dfac9 | desktop | 091dfac9 (tree/README.txt:1) | mtime 2026-11-08 17:57 | n/a | same |
| orb-lan-6eec6a75 | desktop | 6eec6a75 (tree/README.txt:1) | mtime 2026-11-09 06:05 | n/a | same; adds "Make my report folder.cmd", `saved/`, F9 report (README:47) |
| orb-lan-6a30b4c9 | desktop | 6a30b4c9 (tree/README.txt:1, the page's replay-tree README, stack 9d499ff0315f) | mtime 2026-11-09 15:46 | n/a | same as 6eec6a75 |

Newest browser and desktop builds are both 6a30b4c9 (2026-11-09); HEAD is 23 commits later (`git log 6a30b4c9..HEAD`), all docs/process commits by subject line.

## 2. Run records in `docs/*/runs/` (counted on disk, not read)

Disk count includes untracked. "Newest" = sha folder whose commit has the latest commit time (`git log -1 --format=%ct <sha>`).

| Area | Tracked | Untracked (status lines) | On disk | Records per sha folder | Newest sha |
|---|---|---|---|---|---|
| animation | 10 | 0 | 10 | 85e838b6:10 | 85e838b6 (11-07) |
| camera | 4 | 7 | 11 | d41ce393:5, b34e32e1:4, 66b66796:2 | 66b66796 (11-09) |
| controls | 64 | 2 | 66 | c974e451:15, cb477edf:10, 3aaf0df3:9, 4890bdd9:9, c7b0414b:6, 66b1d269:5, cc958c18:5, 592a807b:3, 090264d7:2, d240cef1:2 | cc958c18 (11-09) |
| director | 606 | 135 | 741 | eb170778:186, 665f58d6:183, ba87218e:178, 397a7adf:135, 20713b02:51, 6eec6a75:8 | 20713b02 (11-09) |
| ep | 18 | 0 | 19 | 6a30b4c9:7, 6eec6a75:4, 091dfac9:2, 1931a0f8:2, 4890bdd9:2, 238bb9e0:1, e9216c1a:1 | 6a30b4c9 (11-09) |
| net | 152 | 0 | 152 | d41ce393:54, 4890bdd9:24, 9dfea2a3:19, c7b0414b:12, 1931a0f8:10, 578e819e:8, ba87218e:7, 3a372e6b:5, ea398601:4, 091dfac9:3, 6a30b4c9:3, 6eec6a75:3 | 6a30b4c9 (11-09) |
| perf | 4 | 0 | 4 | a8bc66e2:2, d41ce393:2 | d41ce393 (11-07) |
| qa | 19 | 0 | 19 | 1931a0f8:11, 6a30b4c9:4, c974e451:3, 091dfac9:1 | 6a30b4c9 (11-09) |
| rendering | 2 | 5 | 7 | a8bc66e2:3, 1931a0f8:1, d985eb15:1, e0d33c4d:1, e1397e5c:1 | d985eb15 (11-08) |
| sim | 87 | 43 | 130 | b34e32e1:24, ba87218e:22, 592a807b:12, c7b0414b:12, 3d628d7b:11, eb170778:11, 665f58d6:8, c974e451:8, b345ba1b:7, d6e28824:7, 1931a0f8:4, 578e819e:4 | 578e819e (11-09) |
| tools | 42 | 0 | 42 | 1931a0f8:12, 85e838b6:8, 6eec6a75:5, ba87218e:5, 091dfac9:3, 6a30b4c9:3, mms-2026-11-10:3 (not a sha), 3eca67eb:1, e1397e5c:1, ea398601:1 | 6a30b4c9 (11-09) |
| ui | 2 | 36 | 47 | 397a7adf:27, 592a807b:9, 85e838b6:2, b345ba1b:2, bf29f9ba:2, 090264d7:1, b34e32e1:1, e1397e5c:1, ea8dc190:1, f24029fb:1 | 592a807b (11-09) |
| vfx | 0 | 7 | 7 | 94774fc6:7 | 94774fc6 (11-07) |
| world | 32 | 25 | 58 | c7b0414b:13, ea8dc190:12, globe-step2:12 (not a sha, untracked), 85e838b6:11, b345ba1b:9, 66b66796:1 | 66b66796 (11-09) |

File types on disk: 1212 txt, 38 md, 37 png, 11 log, 10 json, 2 patch, 2 gif, 1 csv. No run record names any commit after 6a30b4c9 (2026-11-09 14:41 -0800).

## 3. CI workflows (last 30 runs each)

| Workflow (lines) | Trigger | Runs found | Tally | Latest |
|---|---|---|---|---|
| ci.yml (504) | push, PR, dispatch (ci.yml:15-18) | 30 (2026-11-09 to 11-14Z) | 13 success, 15 cancelled, 0 failure, 2 not finished | 43554356718 on 8901d351 pending; 43553420852 on 35cc89e9 in progress (5 jobs green, flash/net/godot-parity running). Last success 42866500996 on 3a03e03f (2026-11-10) |
| content-screen.yml (30) | push, PR, dispatch | 30 | 29 success, 1 failure (42673850903, b874138f, 11-09) | 43554356728 on 8901d351 success |
| desktop-builds.yml (179) | dispatch only (desktop-builds.yml:15-16) | 0 | none | never run |
| flash-pixels-dryrun.yml (77) | dispatch only | 1 | 1 success | 37520705360 on a451a94c, 2026-10-06 |
| player-watch.yml (36) | cron `17 14 * * *` + dispatch | 7 | 7 success | 43505870115 on 3a03e03f, 2026-11-13 |
| takedown.yml (39) | dispatch only | 2 | 2 success | 42440408155 on 29ad8082, 2026-11-08 |
| web-parity.yml (59) | push, PR, cron `17 3 * * *`, dispatch | 30 | 27 success, 3 failure (42477588363 1931a0f8, 42471561658 b345ba1b schedule, 42470640835 4890bdd9; all 11-08) | 43414223230 on 3a03e03f (schedule) success, 2026-11-13 |
| web-template.yml (104) | dispatch only (web-template.yml:8-9) | 2 | 1 success, 1 failure (40623974568, 2acfc4cd) | 40624057612 on a08b8fa9 success, 2026-10-28 |
| workflow-lint.yml (32) | push, PR, dispatch | 30 | 30 success | 43554356732 on 8901d351 success |

**ci.yml latest successful run 42866500996 (3a03e03f):** 17:35:22Z to deploy end 18:25:26Z, about 50 min wall. Jobs (start to end, against `timeout-minutes`):

| Job | Time | Timeout (ci.yml line) |
|---|---|---|
| Network checks (net) | 49m40s | 60 (:285) — longest, 83% of limit |
| Godot headless checks (godot-parity) | 48m45s | 75 (:181) |
| World checks (world) | 33m12s | 45 (:390) |
| Flash count (flash) | 23m51s | 45 (:109) |
| Frozen JS core (sim) | 2m05s | 20 (:50) |
| QA regression (qa) | 1m43s | 15 (:33) |
| Data validation (data) | 1m29s | 15 (:68) |
| Build site (site) | 1m06s | 20 (:412) |
| Deploy to GitHub Pages | 16s | 10 (:494); needs all eight (:491) |

## Systems table

| System | What it does | Files (lines) | Data/schemas | Switches | Tests / CI job | Reached? | Leftovers | Owner |
|---|---|---|---|---|---|---|---|---|
| CI main pipeline | 8 check jobs + Pages deploy on push/PR; deploy only on main (ci.yml:489-494) | .github/workflows/ci.yml (504) | validates data via tools/validate.js (:81) | concurrency cancel-in-progress off on main (:25-27) | runs qa/run-all.js (:43), npm test sim (:59), godot gates via tools/gate.mjs (:165-214) | yes: 30 runs | 15/30 cancelled with 0 jobs (e.g. 43554229393, 42759757056): queued main runs superseded despite the "every run finishes" comment (:23-24) | tools-pipeline |
| Content screen | runs content-screen self-test then screen on push | content-screen.yml (30) | not evidenced | none | tools/content-screen-selftest.mjs, tools/content-screen.mjs (:28-30) | yes: 30 runs | 1 failure 11-09 | tools-pipeline |
| Desktop builds | dispatch: builds desktop packages, verifies lock/routes/astc/notices | desktop-builds.yml (179) | tools/desktop-package.mjs (:78-86), write-build-info.mjs (:91) | none | self-test runs in ci.yml flash job (:133) | unreached: 0 runs; LAN exes built elsewhere (tree/README.txt names net/tools/lan_kit.mjs) | never exercised on GitHub | tools-pipeline |
| Flash pixels dry run | dispatch: pixel flash run, 120 min limit | flash-pixels-dryrun.yml (77) | none read | none | itself | 1 run, 2026-10-06 | stale (5 weeks) | tools-pipeline |
| Player watch | daily cron self-test + watch | player-watch.yml (36) | not read | cron 14:17 UTC | tools/player-watch-selftest.mjs (:28) | yes: 7 runs | none | tools-pipeline |
| Takedown | dispatch: builds offline-notice site and checks it | takedown.yml (39) | none | none | tools/site-takedown.mjs, check-site-offline.mjs (:30-32) | 2 runs 11-08 | none | tools-pipeline |
| Web parity | Godot web vs native parity, nightly + push | web-parity.yml (59) | none | `--time-limit 2400` (:59) | sim/core/tools/web_parity.mjs (:59) | yes: 30 runs | 3 failures 11-08 | tools-pipeline |
| Web template | dispatch: custom web template build, 180 min | web-template.yml (104) | not read | none | itself | 2 runs 10-28 | stale | tools-pipeline |
| Workflow lint | parses workflow files on push | workflow-lint.yml (32) | none | none | tools/check-workflows(-selftest).mjs (:30-32); also in ci.yml data job (:93-96) | yes: 30/30 green | duplicated in ci.yml | tools-pipeline |
| Kept browser builds | frozen web exports + replay tree per Orb play | 12 folders, 9 web files each; README 10-11 lines | tree/data "page switches flipped" (tree/README.txt) | URL args and cache tag above | replay via tools/preview/blackbox-verify.mjs (README:7) | reached by README instructions only | 018b4edf pair have a rebuilt tree, not the original (README:10) | unplaced (homework/) |
| Kept LAN builds | Windows exe + launchers for two-PC LAN play | 6 folders; READMEs 42-47 lines | tree/ (5 of 6) | `--lan-host`, `--lan-log`, `--tiles=1`; input wait 2 or 3 | none in CI (lan_kit not run in CI: not evidenced) | reached by README | host address hard-coded in Host .cmd; orb-lan-3d997381 has no tree; orb-lan-6a30b4c9 tree README is the page's, not a LAN note; LAN logs kept in 091dfac9 and a8bc66e2-c | unplaced (homework/) |
| Run records | saved gate/test output per area and commit | 1042 tracked + 260 untracked status lines, 1307 files on disk | n/a | n/a | n/a (evidence) | cited, e.g. tools/preview/switches.mjs:197 cites docs/director/runs/397a7adf | 2 non-sha folders (tools/mms-2026-11-10, world/globe-step2); nothing newer than 6a30b4c9 | per area: animation, camera, controls-feel, encounter-systems, ep, netcode-online, performance-platform, rendering-techart, ui-ux, vfx, world-environment; docs/qa, docs/sim, docs/tools unplaced |

## Notable

1. ci.yml has no completed run on any commit after 3a03e03f: four of the five 2026-11-13/14 pushes were cancelled before starting (0 jobs) and one is still running (`gh run list`, run 43553420852).
2. The comment at .github/workflows/ci.yml:23-24 says every main run finishes, but 15 of the last 30 main push runs show `cancelled` with 0 jobs (43554229393, 42759757056). These are queued runs replaced by newer ones in the same concurrency group (ci.yml:26), so only the newest queued commit gets checked.
3. The longest CI job (net, 49m40s) is at 83% of its 60-minute limit (.github/workflows/ci.yml:285); timeouts were all raised on 2026-11-08 (ci.yml:109,181,285,390 comments).
4. desktop-builds.yml (.github/workflows/desktop-builds.yml:15-16) has never run; the desktop builds Orb plays come from the LAN kit (homework/Files/builds/orb-lan-091dfac9/tree/README.txt:3).
5. web-template.yml (latest 2026-10-28) and flash-pixels-dryrun.yml (2026-10-06) haven't run in weeks.
6. Newest kept builds (browser and LAN) are 6a30b4c9 (homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d/README.txt:1); HEAD is 23 commits later.
7. orb-lan-a8bc66e2-c is built with "the held switches off" and main's net/ laid over the page tree (orb-lan-a8bc66e2-c/tree/README.txt:2-3), so its tree is not a byte copy of the page.
8. The two 018b4edf browser builds carry a replay tree rebuilt on 2026-11-02, not the original (orb-first-play-018b4edf-fc994af8/README.txt:10).
9. The LAN Host launchers hard-code a home-network host address (orb-lan-*/Host (main PC).cmd:3); that's a private detail in a kept, untracked folder.
10. docs/director/runs holds 741 files on disk (57% of all run records); 135 untracked (baseline-status.txt).
11. Run folders under docs/qa, docs/sim and docs/tools have no owner in DIRECTORS.md: QA owns qa/ (DIRECTORS.md:447), Simulation owns sim/core/ and docs/architecture/ (:170), Tools owns tools/ (:472).
12. Two run folders aren't named for a commit: docs/tools/runs/mms-2026-11-10 (tracked) and docs/world/runs/globe-step2 (untracked).
13. Workflow lint runs twice per push: workflow-lint.yml:30-32 and ci.yml:93-96.
14. No KAI/VORR, "strip", TODO or FIXME found in .github/workflows/*.yml (grep).

## Not covered

- Run record contents: counted only, by rule.
- The contents of `web/` and `orb-combat-lan.exe` (binaries), and of `tree/` beyond its README.
- Job-level detail for failed runs (content-screen 42673850903, web-parity failures, web-template 40623974568): logs not opened.
- Step lists of ci.yml lines 216-281 and 286-488 (net, world, site steps) were scanned only for job names and timeouts.
- What switches each build's `tree/data` actually flips: READMEs say "page switches flipped" but don't list them; the packed data wasn't read.
