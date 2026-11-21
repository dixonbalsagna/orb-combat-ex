# GW1a: draft mapping from register rows to commits

**Status: section A confirmed by the EP on 2026-11-20 and applied to status.json (A-UI-09 stays reported; A-NET-05 stays landed; the unsure list unchanged).** Written 2026-11-20 by Production Operations from the EP's commit list for GW1a (b20020b4..b0e20f9a, 26 commits) and the commits' own subjects and file lists (read-only `git log` and `git show --name-only`; nothing was run). "On main" below means the commit is an ancestor of HEAD b0e20f9a (checked with `git merge-base --is-ancestor`).

Confidence: **placed** (subject and files match the row), **likely** (matches by subject, files not decisive), **unsure** (no commit clearly carries it). A row is proposed "landed" only when placed or likely.

## A. Rows GW1a closes (proposed landed)

| Row | Proposed commit | Basis | Confidence |
| --- | --- | --- | --- |
| A-CODE-03 | 9254c968 | "Tools: A-CODE-03 (planet entry and probe...)"; touches render/core/main.gd, sim_host.gd | placed |
| A-UI-02 | 9254c968 | same commit touches render/core/match_recorder.gd ("the report hook never prunes a player's saved match"); the re-cut 5963d224 is a park commit | likely |
| A-CODE-01 | 9254c968 (as the EP named it) | EP: golden equals the target and switch-diff reads 0 of 5 data rows. Also relevant: 490e610d (target golden), b0e20f9a (last pins) | placed on the EP's word |
| A-CODE-02 | 490e610d | "energy on with the target golden (a1-owed rows, gates shipped, the GW1a frame)": the golden record for the played configuration and gates run as shipped | placed |
| A-ENERGY-04 | 490e610d | "Simulation: energy on"; pins e4666d82 (Encounter), f733d704 (World), 88b51569 (Rendering) | placed |
| A-AI-05 | c3507bfc | "Encounter: director rows (AI, fight, ending)": touches data/director/ai.json, interrupts.json, launch.json, stick.json, swing.json | placed |
| A-MODES-07 | c3507bfc | "...and the match-end check": adds sim/director/tools/match_end_check.gd; the ending rows | likely |
| A-CONTROLS-02 | 7d232b6f | "Controls: pad group and GW1a pins": touches data/input/timing.json | placed |
| A-COMBAT-14 | e77ad69a | "Combat: GW1a rows": data/combat/mixed.json and phrases.json (the parked fd5c1895 is the patch this applies) | placed |
| A-CAMERA-01 | d83c38dd | "Camera: A-CAMERA-01 (matches the 9 Nov code path; ADR 0010)"; with 8ab87d98 (own pane, pins, chase measure), b77a59c2 (split sweep, pins), 89e7c1a7 (Tools camera swing cases) | placed |
| A-RENDER-01 | ae41bc06 | "Rendering: globe ground and crater look on by default, foot slice"; VFX fc0c0a12 (meteor default) | placed |
| A-RENDER-04 | ae41bc06 | same commit (crater look default) | placed |
| A-AUDIO-01 | c0eb9918 | "Audio: A1 sound sets and the range fix" (the parked patch 26fd27b0 is what it applies) | placed |
| A-MODES-01 | e5618ab3 | "UI: A1 menus (... start flow ...)": touches ui/core/ui_modes.gd, tools/schemas/ui-modes.schema.json | likely |
| A-MODES-06 | e5618ab3 | same (the fighter pick is part of the start flow) | likely |
| A-MODES-11 | e5618ab3 | same (the Quit row); confirm | likely |
| A-MODES-15 | e5618ab3 | "Rail by default" | placed |
| A-UI-01 | e5618ab3 | "pause clock" | placed |
| A-UI-04 | e5618ab3 | "Rail by default" | placed |
| A-UI-06 | e5618ab3 | "menu fixes" (the d-pad); confirm | likely |
| A-UI-09 | e5618ab3 | touches docs/ui/screen-sweep.md; whether the stills of every menu exist is not visible from the file list | unsure: proposed to hold, not landed, until the stills are confirmed |
| A-MODES-08 | e5618ab3 | touches tools/smoke/mode_smoke.gd, mode-smoke.mjs, mode-smoke-selftest.mjs and docs/tools/mode-smoke.md; the earlier park was e702e058 | likely |

## B. Rows GW1a touches but does not close

| Row | Why | Commit(s) |
| --- | --- | --- |
| A-WORLD-01 | Lands first in GW1b (the planet flip is last), per the EP's plan; 6551a80d carries S-01 (travel 2.0) and the world switches, not the planet default | 3b6e89b5 is a park on main |
| A-ENERGY-05 | Meters-zero is GW1b | 69406d59 park on main |
| A-CONTROLS-04 | Flight 3500 is a GW1b rider | paper in 970d15a6 |
| A-COMBAT-05, A-COMBAT-11 | Stray-beam fixes ride in GW1b; no GW1a commit names them (c3507bfc and e0b45860 touch interrupts.json, so unsure) | QA acceptance 752c381f |
| A-AI-10 | The computer's perfect-block fix is a GW1b rider; unsure whether it is in c3507bfc's director rows | none placed |
| A-CONTROLS-06 | The coverage probe: ff078f12 is on main as a park commit; no GW1a commit visibly applies it | unsure |
| A-TOOLS-01 | CI part met (run 43589936940); the local build proof is on main; the same-replay stills comparison is still to do | db4f85a2, d3d5bd66 |
| A-TOOLS-07 | Version number: no GW1a commit visibly carries it | unsure |
| A-PERF-08 | The window row: UI's a1-window-row (49fa623e) is a park commit; not visibly applied | unsure |
| A-LEGAL-02 | No GW1a commit names it | unsure |
| ADD-A1-04 (clipping) | ae41bc06 carries the foot slice only; the clipping re-cut park (ff02e386) is not visibly applied | ae41bc06 part |
| ADD-A1-01 to 03 (sizes, terrain, destruction) | GW1c / later windows | none in GW1a |

Supporting commits with no row of their own: 2d092ae1 (CI sets and GW1a checks), 4b5d0683, 7edb724b, 887ff798 (Tools cases and retirement), f901ae9f (Rendering checks), 24920f05, 679002c3, f733d704, 88b51569, e4666d82, b0e20f9a (pins), 810ecd40 (Art biomes, S-02), b20020b4 (Animation check park, first in the range).

## C. A-NET-05: a conflict to settle

The EP says "A-NET-05 stays parked". The tracker holds it as **landed** from status 6 (batch B1: f068b697, 39f03a97, 30d5922d, f70afd08), and `git` shows f068b697 and f70afd08 are ancestors of HEAD. Proposed: keep it landed unless the EP means a different piece (Tools' report-hook piece, 5963d224) is what stays parked; say which and I will write the note.

## D. The eight parks from status 6, checked against main

| Park | Commit | On main? | Content applied by GW1a? |
| --- | --- | --- | --- |
| Combat gw1a-rows | fd5c1895 | yes (commit) | yes, by e77ad69a (same two data files) |
| World water re-cut | 31f6a8bd | yes (commit) | yes, by 6551a80d (touches data/biomes/water.json) |
| World bystanders-gw1b | bcb7e935 | yes (commit) | no: it is a GW1b park, still parked |
| Audio sound-sets patch | 26fd27b0 | yes (commit) | yes, by c0eb9918 |
| Rendering report 4 (feet parks pass on Orb's replay) | 30930158 | yes (commit) | partly: ae41bc06 carries the foot slice; the rest unsure |
| Camera READMEs | no id given | not checked | unsure: no id |
| Two more of the eight | not named in status 6 | not checked | unsure: only six were named |

A commit on main for a park is a document and a patch under docs/*/pending, not the change itself; "applied" means a GW1a commit changes the live files the patch targets.

## E. What happens when the EP confirms

Rows in section A become landed in status.json with the first commit as `ref` and the rest in the note (the tracker's check wants one commit id); sections B and C stay as they are. That moves A1 from 16 landed to 37 of 77 (the 21 placed or likely rows; A-UI-09 held as unsure). The first version of this draft said 22 and 38: a miscount, corrected 2026-11-20.
