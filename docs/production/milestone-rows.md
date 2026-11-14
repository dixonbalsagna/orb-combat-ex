# Milestone rows: the full table

_Built from status.json for 2026-11-13 by tools/build-tracker.mjs, with every row of milestones A1 to A6 (180 rows). This is the Executive Producer's table; milestones.md is the page for Orb and leaves out the rows marked †, which carry no question for Orb. Status words: not started, briefed, reported, landed (a landed row shows its commit). "Needs" lists the rows this row waits for. "Window" is the golden window the row lands in. Size: S about 0.25M tokens, M about 1.2M, L about 4M, XL about 8M (the register's classes)._

## A1. Main is the game Orb plays — 77 rows

**audio-music** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-AUDIO-01 | S | major |  |  | not started | wave 2, from Saturday 14 Nov | On main five sound sets are off, so a build made plainly from main has no beam, knock-out, launch, struggle or transformation sound; Orb's build has three of them on… |

**camera** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-CAMERA-01 | S | major |  |  | not started | wave 2, from Saturday 14 Nov | The camera Orb played (swing, peak launch shot, launch director, close brawl, readable size, 70/30 share, follow-through, flight reveal) switches on only when the game… |

**combat-choreography** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-COMBAT-14 | S | minor | GW1 |  | not started | wave 2, from Saturday 14 Nov | The mixed string's switch reads 'on' in the played build but no game code reads its data file; the feature comes from parked files outside main. |

**controls-feel** (2)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-CONTROLS-02 | M | major | GW1 |  | not started | wave 2, from Saturday 14 Nov | The pad as the owner plays it is not the default in data: eleven input switches are off on main and on in both played builds only through the private page's switch table. |
| A-CONTROLS-06 | M | major |  |  | not started | wave 2, from Saturday 14 Nov | No moveset coverage probe exists: the nearest tool presses each input alone for 90 ticks and its saved result is from a tree of 1 November. |

**encounter-systems** (6)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-AI-05 | S | major | GW1 |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | Main's computer-opponent data is not the played build's: Easy's pace matching, the beam pacing against a human, and the computer's hold-and-release beam are on in the… |
| A-AI-10 | S | minor | GW1 |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | The fix for Orb's remark that the computer perfect-blocks charged attacks too easily is parked and not on main: its data key is in the schema but in no data file and no… |
| A-AI-13 (nice) | S | minor |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | The parked one-versus-many work was last rebuilt on 2026-10-16 and applies by exact-text patches; whether it still applies to today's director code is not evidenced. |
| A-COMBAT-05 | S | major | GW1 |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | A released stick beam that cannot start waits up to 90 ticks and then fires into whatever the player is doing; open since Orb's last play. |
| A-COMBAT-11 | S | minor | GW1 |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | RT + B stays a signature for as long as the fighter is not channelling, not for 12 ticks, because the rule reads state and not time. |
| A-MODES-07 | S | major | GW1 |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | On main the rules that end a match as the last played build did (knockout only by a finishing move, wear for an idle player, the last event after the time cap) are… |

**ep** (16)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-ANIM-06 | S | minor |  |  | not started |  | The animation runtime, its tools and its data (render/anim, data/anim) are on no director's owns line; Animation owns only art/animation and docs/animation. |
| A-CODE-01 | L | blocker | GW1 | A-AI-05 A-AUDIO-01 A-CAMERA-01 A-CODE-03 A-CONTROLS-02 A-ENERGY-04 A-MODES-07 A-MODES-15 A-RENDER-01 A-WORLD-01 | not started |  | Main does not hold the game Orb plays: 72 of the 92 build switch rows differ between main and Orb's solo build, so a fresh clone, CI and any desktop build made from main… |
| A-PROCESS-02 | S | major |  |  | reported | EP row; Production Ops draft in docs/production/backlog-draft.md — Partial draft: the register and the corrective plan are in; it waits on the EP's owed list, QA's bug list and the parked-folders list. The EP owns and commits it. | There is no single backlog: open work sits in the corrective plan, the EP's messages and per-machine memory notes, parked folders, a git-ignored homework folder and… |
| A-PROCESS-03 | M | major |  |  | briefed | EP's own, under way (docs/ep/sprints/A1-sprint.md) — Tools' group landed in 191e5e30; one owner's group at a time, screened before each push. | The working tree carries 14,805 uncommitted paths, including run records, parked work, the terrain plan and three QA tool edits, so the repository does not hold the… |
| A-PROCESS-06 | S | major |  |  | not started |  | The P0 to P5 roadmap in CLAUDE.md no longer describes the project: no phase gate result is on record, P3 and P4 name systems Orb put on the backburner, and the… |
| A-PROCESS-07 | S | major |  |  | not started |  | The corrective plan of 2026-11-07 has not been kept: 13 of 27 rows have no closing entry, 8 items have neither a commit nor a record, and two wave-1 items due before… |
| A-PROCESS-08 | S | minor |  |  | reported | EP row; Production Ops draft in docs/production/token-record.md | No weekly token record exists: the EP has no clean figures for the last three weeks, so milestone lengths in weeks can only be estimated. |
| A-PROCESS-09 | S | minor |  |  | not started |  | The /sprint-plan and /sprint loop is installed but has never run, and its input, the audit's path-to-Alpha page, does not exist yet. |
| A-PROCESS-10 | S | minor |  |  | not started |  | The project's running state depends on one EP session: four commands hard-code its session id, and its handover notes live in per-machine memory rather than the… |
| A-PROCESS-11 | S | minor |  |  | not started |  | CLAUDE.md and ADR 0005 still tell every session the project is on a Pro plan with no workflows, against Orb's standing order of 2026-11-06. |
| A-PROCESS-13 | S | minor |  |  | not started |  | The director roster has no Alpha mapping and carries stale parts: charters list backburnered duties, one charter's model differs from the generator, and a director owns… |
| A-PROCESS-14 | S | minor |  |  | not started |  | The commands the sprint loop replaces are still live: /crunch is tracked with its 2026-11-01 priorities, /overnight is live but never committed, and the README lists… |
| A-PROCESS-15 | S | minor |  |  | not started |  | The standup command does not read CI first, although the corrective plan's CD-20 asks for that step in both the playbook and the standup. |
| A-PROCESS-16 | S | minor |  |  | reported | EP row; Production Ops draft in docs/production/done-tests.md | 'Done' exists only as one general rule; no page lists each Alpha feature with its own done test, and the exit criteria are not referenced from CLAUDE.md or the playbook. |
| A-RENDER-07 | S | major |  |  | not started |  | No record ties a visible landing to its side-by-side: landings arrive as batches, the gate records of the last five builds name no side-by-side, and 214 of the 229 files… |
| A-RENDER-11 | S | minor |  |  | not started |  | The look gate's reference build is still d3f1ca0e of 2026-10-15, which predates the globe ground and everything Orb plays now, so a same-tick side-by-side against it… |

**game-design** (3)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-COMBAT-15 | S | minor |  |  | landed | 970d15a6 — The six workshop items placed (Game Design). The EP confirms the row closes. | Six of Orb's 'workshop this' combat items have no decision: beam stages, the timed swat, the catch, what RT held does, the taunt before a signature, and whose stick… |
| A-CONTROLS-04 | S | major | GW1 |  | reported | 970d15a6 — Game Design's paper on flight 3500 landed; the data default changes in GW1b. | The flight speed the owner preferred (3500) exists only as a slider on the private browser page; the data's default is 5000, the energy model that reads it is off on… |
| A-ENERGY-02 | S | major |  |  | landed | 970d15a6 — The model page (Game Design). The EP confirms the row closes. | No single written page states the model: it is spread over six design pages, the oldest still a proposal that disagrees with the code on the brink, and none covers… |

**legal-ip** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-LEGAL-09 | S | major |  |  | landed | ae01d434 — Legal's ruling on the itch.io page under the working title, on conditions (in RL-261 to RL-266). | Whether a restricted, key-only itch.io page may go up before the title search is not confirmed anywhere: Legal's own page and the audit directive both say the search… |

**orb** (2)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-LEGAL-10 | S | minor |  |  | landed | ae01d434 — Legal's permission page and contributor note (ae01d434) plus Orb's licence "GO" in vision.md; closed on the EP's word, 2026-11-13. | The owner's one-line licence choice is not on record, so the build says the licence is not chosen yet and no plain permission page exists. |
| A-WORLD-14 | S | minor |  |  | landed | 8d157e9a — Orb accepted decision 2 ("Go with recommendation on all", vision.md, 8d157e9a); closed on the EP's word. The default itself lands with A-WORLD-01 in GW1. | No default world is decided: Orb's solo copy opens on planet 7 through a shortcut's page word, LAN fixes planet 7, and main's menu matches play the hand-made arena,… |

**performance-platform** (3)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-PERF-04 | S | major |  | A-TOOLS-01 | not started | wave 2, from Saturday 14 Nov | Nothing about frame rate, loading or memory has been measured on the build Orb last played, and no windowed native frame record exists for any commit after d7647634… |
| A-PERF-06 | S | major |  | A-TOOLS-01 | not started | wave 2, from Saturday 14 Nov | No loading time is on file for the desktop game with menus, the tile ground and generated planets; the last native figure predates all three and was already 15 s on a… |
| A-PERF-07 | S | major |  | A-TOOLS-01 | not started | wave 2, from Saturday 14 Nov | Memory has never been measured on a desktop build, and growth over time is marked not measured, so the soak's 10% growth line has no baseline. |

**production-ops** (3)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-PROCESS-01 | S | major |  |  | landed | 3fe3d13e — change-control.md and ideas-log.md landed in 3fe3d13e. Logging and pricing are in force; the post-freeze half waits on Orb's decision 23 (asked at A6). | No written change-control rule for the feature freeze and no ideas log exist, and the EP's playbook points to neither. |
| A-PROCESS-04 | S | major |  |  | landed | 3fe3d13e — risk-register.md rewritten, landed in 3fe3d13e. | The risk register is the starting set of 2026-09-28, never updated, and lists none of the risks that have since happened. |
| A-PROCESS-05 | S | major |  |  | landed | 3fe3d13e — milestones.md, milestone-rows.md, status.json and tools/ landed in 3fe3d13e. | There is no milestone tracker or live roadmap, and the Production Operations director who owns them has no commit in the project's history. |

**qa-balance** (9)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-AI-03 | S | major |  | A-AI-04 | not started | wave 2, from Saturday 14 Nov | Medium and Hard have no win-rate record for Orb's scheme on any build since 2026-11-01; the only figures on a design page are 0 wins at each level from 10 matches. |
| A-AI-04 | S | major |  |  | not started | wave 2, from Saturday 14 Nov | No win rate has been measured on the played build's own packed data: every record was made on a scratch tree with patches laid on, by a Tools script that is not in QA's… |
| A-AI-11 | S | minor |  |  | not started | wave 2, from Saturday 14 Nov | Forty matches a cell cannot tell neighbouring bands apart (about 15 points either way), and the drop the EP flagged, 65% to 45% for Easy, is inside that noise and was… |
| A-COMBAT-08 | M | major |  |  | not started | wave 2, from Saturday 14 Nov | No tool measures X-03 (move coverage), X-04 (forms reached), X-13 (the pillars in one match) or X-16 (beam escape), and X-17's beam trace has no count. |
| A-QA-03 | S | major |  |  | not started | wave 2, from Saturday 14 Nov | The bug list holds 1 of the 52 problems Orb reported in play from 2026-11-01 to 2026-11-09, and its newest entry is dated 2026-10-03. |
| A-QA-04 | M | major |  |  | not started | wave 2, from Saturday 14 Nov | Balance between the two fighters is not measured on the build Orb plays: the last full reading (48.9%, in band) is from 3198301f on 2026-10-14 with main's data, which… |
| A-QA-07 | S | minor |  |  | not started | wave 2, from Saturday 14 Nov | The bug list has no severity field (it has a release horizon and a closing step), and its title still names the prototype. |
| A-QA-09 | S | minor |  |  | not started | wave 2, from Saturday 14 Nov | The scripted player that matches Orb's scheme lives in Tools' gauntlet, plays 40 matches in slot 0 only, and fired no beam in the recorded cells. |
| A-SAVES-01 | S | major |  |  | not started | wave 2, from Saturday 14 Nov | No record on file shows a replay saved by the baseline build verifying to its last tick on that build, and the first real LAN save has not been put through the report… |

**rendering-techart** (3)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-PERF-08 | S | major |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | The game sets no window: there is no display section in the project file and no fullscreen, resolution, vertical-sync or frame-cap setting in code or in the options. |
| A-RENDER-01 | M | major |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | The look Orb plays (globe ground, crater look, meteor trail, the swing camera that rides with it) is switched on only by launch words; on main the default is the older… |
| A-RENDER-04 | M | major |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | The black, flat-brown crater has a still and a proven cause (a beam's scorch filled per vertex on coarse tiles), but the fix is on only by a launch word, is parked for… |

**simulation-engine** (4)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-CODE-02 | M | major |  | A-CODE-01 | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | The golden record and five gates are valid only with the switches off, so the configuration Orb plays has no golden record and was verified by a pack read and a smoke… |
| A-ENERGY-04 | S | major | GW1 |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | The "one energy model" is off in the data on main and in both played builds, and is on in Orb's build only through a code patch the page tool writes, so main does not… |
| A-ENERGY-05 | M | major | GW1 |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) — Game Design's comeback numbers landed in 970d15a6; the data change (other effects set to zero) lands in GW1. | The backburnered hero and villain meters, hiding and ambush, and signature variants by biome still act in every match: they change damage, energy regain, beam contests… |
| A-NET-05 | S | major |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | A replay carries a hash of its data, its format and its input version but no build id, so a replay from a build with the same data and different code is run and fails at… |

**tools-pipeline** (13)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-CODE-03 | M | major |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | Orb's solo build carries code that is not on main: the preview patches a scratch copy of the main scene to add the planet entry and a state probe, and main's own menu… |
| A-CODE-04 | L | major |  | A-TOOLS-08 | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | CI runs 116 of the 262 check and test scripts: none of the input, audio or UI checks, one of 26 camera tests, 5 of 65 director checks, no animation or effects check, no… |
| A-ENERGY-06 | S | major |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | The tool X-15 names does not measure X-15: the two-fighter ratchet counts four spellings of "exactly two fighters" and says nothing about fighter-specific code. |
| A-LEGAL-02 | M | blocker |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | No desktop package for an outside tester can be made today: the build workflow needs a recorded approval file that does not exist, the package text step reads a notice… |
| A-MODES-08 | M | major |  | A-MODES-01 A-TOOLS-01 | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | No mode smoke suite exists: the one smoke check drives the browser build by clicking fixed screen points and failed once when the menu layout changed, and the desktop… |
| A-TOOLS-01 | L | blocker |  | A-CODE-01 A-CODE-03 A-LEGAL-02 | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | No one command or CI run makes the Windows and Linux desktop builds of the game as Orb plays it, the solo game included: the only desktop workflow has never run, would… |
| A-TOOLS-07 | S | major |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | A build carries a commit and a date but no version number, the Windows program's version fields are empty, no changelog file exists, and whether the game shows its build… |
| A-TOOLS-08 | S | major |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | The Godot check job's time swings from about 35 to 62 minutes on unchanged game code against a 75-minute limit, and the network job has reached 86% of its 60 minutes, so… |
| A-TOOLS-09 | S | major |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) — Production Ops wrote the tracker paragraph (milestones.md, "Orb's kept builds"); Orb's answer on where the second copy lives is still open. | The owner's builds, play files, reports and clips sit in one git-ignored folder of about 2.9 GB on one disk, with no backup plan written anywhere. |
| A-TOOLS-10 | S | minor |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | The playbook's build-verification rule cites a script that is not in the repository and a tool name that matches no file; the tracked check that exists reads browser… |
| A-TOOLS-13 | S | minor |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | No CI job ever starts a Windows build: every job runs on Linux, and the desktop workflow reads the Windows program's bytes without running it. |
| A-TOOLS-15 | S | minor |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | Corrective item CD-21 (stop silent passes: 'grandfathered', 'report only' and 'CHECK' lines that print as exceptions in the site builder and the clip kit) has no commit… |
| A-UI-02 | M | blocker |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | On main, and so in any plain desktop build, the one-press report and 'Save this match' save nothing: the hook that writes the match file is added only by the LAN kit and… |

**ui-ux** (8)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-MODES-01 | M | blocker |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | The start menu has no list of modes: its rows are one or two players, each player's device, the computer's level, five comfort boxes and Start, so six of the eight Alpha… |
| A-MODES-06 | M | blocker |  | A-MODES-01 | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | There is no fighter select: a match's fighters default to the first two ids of the roster file, so player one is always the Protagonist and player two always the rival. |
| A-MODES-11 | S | major |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | With a pad alone a player can go back to the menu but cannot close the game: the pause and match-over lists have no quit row, and the only quit is the keyboard's Escape,… |
| A-MODES-15 | S | minor |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | The Rail menu the owner picked is switched off on main and on only in the played build, so a candidate built from main shows the older menu card. |
| A-UI-01 | S | blocker |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | With the Rail menus on (as in the build Orb played), the pause menu's slide-in is timed on a HUD clock that the game stops while paused, so by reading the code the rail… |
| A-UI-04 | M | major |  | A-UI-01 A-UI-06 | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | Making the Rail the default is unfinished: its switch is off on main, three older HUD checks fail with it on, Tools' smoke test clicked the wrong place on it, its checks… |
| A-UI-06 | S | major |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | The start menu's d-pad behaves unevenly, as Orb reported: Up from the top row jumps to Start while Down from the bottom row stops, and Left or Right on the Players row… |
| A-UI-09 | S | major |  |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | X-22 cannot be measured today: there is no still of any screen at 1280 by 800 and no tool that sweeps every screen at that size, only plan-level checks of the older… |

**world-environment** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-WORLD-01 | M | blocker | GW1 |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) | On main the round planet is not the game's world: a match with no planet setup key plays the old hand-made arena, the menu never sets that key, and Orb's globe build… |

**Added since the path, outside the register** (5 items; they have no register row, so they are listed apart and not counted in the 77 rows above). They land as window GW1c, after GW1b.

| Item | Owner | What | Status | Evidence | Where it came from |
| --- | --- | --- | --- | --- | --- |
| ADD-A1-01 | world-environment | Five selectable planet sizes (World, with Simulation and Performance): from World's six, five are picked; each generates, plays and holds the shipped quality on Orb's PC, and its frame cost is read in a quiet window. | not started | planned in docs/ep/sprints/A1-sprint.md; the stand-in's planet design comes first | Orb, 2026-11-13 night (ideas-log ID-22) |
| ADD-A1-02 | world-environment | Terrain (World, with Camera): terrain step 2 (globe-step2) re-cut so Camera's chase check passes, then the path's terrain rows. | not started | planned in docs/ep/sprints/A1-sprint.md | Orb, 2026-11-13 night (ideas-log ID-22) |
| ADD-A1-03 | world-environment | Destruction (World, with VFX): craters and trenches drawn where you stand, and buildings breaking at every tier without the rebound Orb saw. | not started | planned in docs/ep/sprints/A1-sprint.md | Orb, 2026-11-13 night (ideas-log ID-22) |
| ADD-A1-04 | rendering-techart | Clipping (Rendering, with Animation): fighters' feet meet the drawn ground, and no fighter sinks into a crater or a building. | not started | planned in docs/ep/sprints/A1-sprint.md | Orb, 2026-11-13 night (ideas-log ID-22) |
| ADD-A1-05 | encounter-systems | Launch rebound bug (Encounter Systems, with World): a fighter that bounces off something in the background must not ricochet on an unrealistic path. Done test: no launch rebound leaves a structure or terrain at an angle or speed the contact cannot explain, read over seeded launches, plus Orb's eye at A1. | not started | EP, 2026-11-14 (Orb's clarification in vision.md) | Orb, 2026-11-14 (ideas-log ID-24) |

## A2. Safe to hand out; two real Steam Decks have run it — 41 rows

**accessibility-localization** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-ACCESS-01 | S | major |  |  | not started |  | There is no accessibility pass or record newer than 2026-10-31 and no runs folder for the area, so the accessibility items of the 'before an outside tester plays' list… |

**audio-music** (2)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-AUDIO-03 | S | major |  |  | not started |  | Nothing in the area is proved by ear: Audio's pages say nobody has listened, and Orb's latest word (2026-11-09) is that the crackles sounded bad, with no record of… |
| A-AUDIO-04 | S | major |  | A-PERF-01 | not started |  | Sound on the Alpha's platforms (a Windows desktop build, Linux, the Steam Deck) is not evidenced: every proof is the browser build in Chrome, the only audio project… |

**camera** (3)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-CAMERA-02 † | S | major |  |  | not started | wave 2, from Saturday 14 Nov — Briefed early for A2. | Two flash safeguards for the camera are parked and not on main: the scroll limit under reduced motion or reduced flashing equals the ordinary one (0.045), and no camera… |
| A-CAMERA-03 | S | major |  | A-UI-09 | not started |  | No camera test or saved record runs at the Steam Deck's 1280 by 800: every camera test fixes 1280 by 720, and UI's own paper says a plate crosses the 30% pane by 70 px… |
| A-LEGAL-01 † | XL | blocker |  | A-CAMERA-01 A-LEGAL-08 A-RENDER-01 A-RENDER-04 | not started | wave 2, from Saturday 14 Nov — Briefed early for A2 (Camera, Rendering, VFX). | On the globe (tile) ground that every build Orb plays uses, the last pixel flash reading failed in both normal and reduced modes (clash 5.5 and 6.5 a second against a… |

**controls-feel** (2)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-CONTROLS-03 | S | major |  |  | not started |  | A pad unplugged mid-match does not pause or show a notice: player two's fighter is handed to the computer and player one is moved to the keyboard while the match runs on. |
| A-CONTROLS-07 | S | major |  | A-PERF-01 | not started |  | The Steam Deck's built-in controls have never been tried: no run on a Deck or through Steam's pad layer is on record, and the project's own Deck page marks it untested. |

**ep** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-ACCESS-04 | S | minor |  |  | not started |  | Corrective item CD-14 has an empty progress cell and no commit or record names it since 2026-11-07, although one of its four parts (a brace button on pads) is in fact… |

**legal-ip** (4)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-LEGAL-03 | S | major |  | A-LEGAL-01 A-LEGAL-08 | briefed | day-one safety chain (docs/ep/sprints/A1-sprint.md) — Started early, in A1, as the path says. | The list of gates that must be green before an outside tester plays did not exist before this audit, and several of its gates have no saved record or no tool. |
| A-LEGAL-05 | S | major |  |  | not started |  | The tester note is a draft for the owner to send, its review row is still open on two conditions, and nothing records how a tester confirms being an adult or agrees to… |
| A-LEGAL-12 | S | minor |  |  | not started |  | The privacy words differ between the package README, the in-game About page and the tester note, and none of the words inside a build mention the two-PC link or the… |
| A-TOOLS-06 | S | major |  |  | not started |  | The desktop package rules were written for private test builds and conflict with an Alpha on itch.io: files are kept one day, the run is deleted after hand-over, no link… |

**orb** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-LEGAL-07 | S | major |  |  | not started |  | The report channel is undecided: the owner's words were to convert an existing server, Legal's first flag says not to, and no record settles the three items Legal wants… |

**performance-platform** (3)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-CONTROLS-08 | S | minor |  |  | not started |  | The press-to-picture latency record is not current: it measures the browser build with keyboard presses on 22 and 23 October, before the right-stick scheme, and nothing… |
| A-PERF-01 | M | blocker |  | A-LEGAL-03 A-TOOLS-01 | not started |  | No Linux build has ever drawn a picture or run on a Steam Deck, so whether it starts, whether every shader runs on the Deck's driver, and how it performs are all… |
| A-PERF-03 | M | blocker |  | A-TOOLS-01 | not started |  | There is no one-click bench a Deck tester can run that saves a file: the existing kits are Windows batch and PowerShell, and the game's own bench prints to the console… |

**qa-balance** (2)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-QA-02 | M | blocker |  | A-TOOLS-01 A-TOOLS-04 | not started |  | No soak test exists for the Godot game: nothing records crashes, hangs, script errors over hours or memory growth on Windows or Linux. |
| A-QA-11 | S | minor |  |  | not started |  | Five older bug entries (GB-002, GB-003, GB-005, GB-006, GB-007) are open or fixed but never re-checked in play since 2026-10-02. |

**rendering-techart** (5)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-PERF-05 | M | major |  |  | not started |  | The frame spikes Orb has felt since 2026-11-01 are still open: two causes were fixed on main but never re-measured, and the building sweep after a blow and the launch… |
| A-RENDER-02 | M | major |  |  | not started |  | Two look bugs from Orb's play of 6a30b4c9, fighters clipping into the ground and a row of three humps in a crater, have no still, no owner, no cause and no row in the… |
| A-RENDER-03 | S | major |  |  | not started |  | A thick black diagonal line across the whole picture, found when Tools replayed Orb's 'hump of ocean water' report, has stills but no cause and no owner, and the hump… |
| A-RENDER-08 | S | major |  |  | not started |  | The boot warm-up's list does not name the clash, meteor trail or blast-head shaders, the park that warms every first draw in the real pane has waited since 2026-10-22,… |
| A-UI-03 † | S | major |  |  | not started |  | Developer keys are live in every build with no switch: F8 brings back the flash shapes from before Legal's conditions, F2 swaps in the old grey-box HUD with a health bar… |

**tools-pipeline** (11)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-LEGAL-06 | M | major |  |  | not started |  | Legal asked that report files be checked for account names and file paths before a tester sends them, and no such check exists; the LAN folder's report script points at… |
| A-LEGAL-08 † | M | major |  |  | briefed | day-one safety chain (docs/ep/sprints/A1-sprint.md) — Part 1 landed in 191e5e30 and its nightly in 59c6b195 (Tools). Stays open until the first scheduled reading is recorded. | The repairs to the flash measuring chain ordered on 2026-11-07 (CD-09) have no commit: the analyser file is unchanged, no flash reading runs on a schedule, the last… |
| A-MARKET-01 | S | major |  |  | not started |  | There is no fixed shot list: the recipe file covers three of the six named shots and has no recipe for a transformation, a lap of the globe or a LAN 2v2 moment. |
| A-MARKET-02 | S | major |  | A-MARKET-01 | not started |  | No job renders the shots at a milestone and no archive exists: clips land in a git-ignored folder with no milestone name, no line on what changed and no backup. |
| A-MARKET-03 | M | major |  | A-TOOLS-01 | not started |  | The capture hook exists only in a browser build, so the Alpha candidate's own Windows and Linux programs cannot be filmed, and a LAN 2v2 shot depends on a replay route… |
| A-MARKET-04 † | S | major |  |  | not started |  | Only GIFs get the flash check; WebM video and PNG sequences leave the kit with no verdict, and no page says how a public video is screened. |
| A-MARKET-07 | S | minor |  |  | not started |  | No rule says what happens to a shot when an old replay stops playing: a replay is refused on different data, and the page word that plays a saved match is a scratch… |
| A-TOOLS-02 | M | blocker |  | A-LEGAL-09 A-TOOLS-01 | not started |  | Nothing for itch.io exists: no page set-up note, key procedure, channel names, upload script or rehearsal record. |
| A-TOOLS-03 | S | blocker |  | A-TOOLS-02 | not started |  | No rollback procedure or release checklist exists, so nothing says how testers are returned to the previous build or which earlier build is the one to return to. |
| A-TOOLS-04 | M | blocker |  |  | not started |  | Nothing captures a crash or a hang: no game code writes a file when the game dies, the project sets no logging option, and match files are saved only on pause, match end… |
| A-TOOLS-05 | M | blocker |  | A-UI-02 | not started |  | The one-press report folder works only on Orb's PC: its launcher is a Windows command file that runs Node against this PC's copy of the repository, has no size cap, and… |

**ui-ux** (6)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-ACCESS-02 | S | minor |  |  | not started |  | The Hit pause slider is still shown on the Accessibility page and still has no reader outside the user interface, so moving it changes nothing (corrective item CD-14,… |
| A-LEGAL-13 (nice) | S | minor |  |  | not started |  | In a desktop build the AI disclosure is not on the first screen: the start notice carries only the flashing words, and the AI line sits in README.txt and on the About… |
| A-SAVES-02 † | S | minor |  |  | not started |  | On main the lock that keeps Reduce flashing on is switched off, so a saved Off is read back at start-up, and every build shares one settings folder, so an Off saved in… |
| A-TEXT-01 | S | major |  |  | not started |  | No record shows that Orb has seen the menu, how-to, hint, notice or settings text: the strings list made for Orb's marks holds 1115 strings and its Mark column is empty… |
| A-UI-07 | S | major |  |  | not started |  | The feedback panel cannot be worked with a pad: a pad's only actions there are B or Start to close, so tags, Copy and Save need a mouse or a touch and the note needs a… |
| A-UI-10 | S | major |  |  | not started |  | Settings and remapped controls surviving a restart has never been tested across a real restart on Windows or Linux: the only tests rebuild the screen inside one process,… |

## A3. The fight's new rules, and LAN inside the game — 27 rows

**camera** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-CAMERA-05 | M | major |  |  | not started |  | The rig has no input naming this PC's player: the large pane goes to the one fighter of slots 0 and 1 with no computer driver, so the picture each PC shows in a LAN 1v1… |

**controls-feel** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-COMBAT-07 | S | major |  |  | not started |  | In Orb's last full match the player's fighter never left tier 1 while the computer reached tier 3; the transform chord has no hint. |

**encounter-systems** (4)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-AI-07 | S | major |  |  | not started |  | No standing check proves the computer uses only inputs a player has: on main its signature is still the old B request that locks its rival, the hold-and-release check is… |
| A-COMBAT-01 | L | blocker | GW2 |  | not started |  | Beam option A is not built: a beam is still an exchange that always reaches its target and is decided by a timed press, not by position. |
| A-COMBAT-02 | L | blocker | GW2 |  | not started |  | Signatures are not on Orb's inputs: RT + RB + a right-stick flick and RT + a flick cannot be pressed (the right stick is switched off in the input layer while RT is… |
| A-CONTROLS-05 | M | major | GW2 |  | not started |  | The latest count of unanswered presses is from an older build: 225 of 760 presses not honoured (30 percent), 97 of them with no word or buzz, and no count exists for the… |

**game-design** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-ENERGY-01 | L | blocker | GW2 | A-ENERGY-02 | not started |  | No stamina and no "body" number exist in any code or data, so the energy, stamina and health loop Orb defined for Alpha is a plan only. |

**legal-ip** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-LEGAL-04 | M | major |  | A-MODES-04 | not started |  | No ruling or package covers an outside tester playing the LAN modes: the locked package refuses any network code, and the LAN folder's terms name only the owner and the… |

**netcode-online** (8)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-MODES-04 | L | blocker |  | A-MODES-01 | not started |  | LAN play is not part of the game a tester would get: it reaches the game only through text patches the LAN kit makes to a scratch copy, and is started by Windows… |
| A-MODES-05 | M | blocker |  | A-MODES-04 | not started |  | A LAN match cannot be rematched or left to a menu: the program plays one match and tells both players to close both windows. |
| A-MODES-10 | M | major |  | A-MODES-04 A-MODES-06 | not started |  | Every LAN match is the same match: the seed, the planet and the fighters are constants in the LAN code, so nothing a player picks reaches a LAN game. |
| A-NET-01 | S | major |  | A-MODES-04 | not started |  | No LAN match on the played build (6a30b4c9) has a record from two real PCs: its only LAN records are nine rows with the second PC simulated inside one program, and the… |
| A-NET-02 | L | major |  | A-MODES-04 | not started |  | An outside tester could not set up LAN without help: the folder is built on the hosting PC with that PC's address written into the shortcuts, needs an administrator… |
| A-NET-03 | S | major |  |  | not started |  | A PC that falls silent is declared gone after 8 seconds, not the 5 seconds X-08 proposes, and no pulled-cable test on two real PCs is on record. |
| A-NET-04 | S | major |  |  | not started |  | Every LAN status except a dropped PC (waiting, could not connect, could not start, out of step, match over) is shown only in the window's title bar, and a detected state… |
| A-PERF-02 | M | blocker |  | A-MODES-04 A-TOOLS-01 | not started |  | LAN play has no Linux build path: the LAN kit exports the Windows preset only, the Linux preset excludes the network code, and the launchers are Windows scripts. |

**simulation-engine** (3)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-COMBAT-03 | XL | blocker | GW2 |  | not started |  | No gravity well exists in code: no well, zones, draw, snap or intent read, only two pieces of the LT speed ruling behind switches. |
| A-ENERGY-03 | M | major | GW2 | A-ENERGY-01 | not started |  | Energy's own numbers (start, cap, regain, charge rate, hit gain, guard drain and the older costs) are literals in code, shared by every fighter, not data. |
| A-ENERGY-10 | S | minor | GW2 |  | not started |  | A new kind of meter cannot be added as data: the loader accepts only the two backburnered meter names. |

**ui-ux** (2)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-ENERGY-07 | S | major |  |  | not started |  | No record shows that a player can read their own health, energy or readiness from the fighter at speed; the only energy readout found is the corner plate. |
| A-ENERGY-08 | S | minor |  |  | not started |  | The HUD's power pip is computed at 25 per tier while the data's thresholds are 35, 65 and 100, so it reads full before a transformation is ready. |

**vfx** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-RENDER-13 | S | minor |  |  | not started |  | The zip and press effects draw marks on and round the fighters (a charge ring, a diamond, a double ring, a squeezing ring with brackets, a ring on the striking hand),… |

**world-environment** (5)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-WORLD-03 | M | major | GW2 |  | not started |  | Terrain step 2 (no shafts, settling, the record list) is built and parked but not on main, held because the camera's chase check failed 4 of 130 rows with it; the jolt… |
| A-WORLD-04 | S | major | GW2 |  | not started |  | Any ground dug below the shore line reads as sea at once, wherever it is, because the sea is derived from ground height with no source test; the fix (the flood switch)… |
| A-WORLD-06 | S | major |  | A-WORLD-03 | not started |  | X-14's three times the crater width at the top tier is not met for the same blow and no check asserts any ratio: an impact gains 25% energy a tier (1.32 times the width… |
| A-WORLD-07 | L | major | GW2 | A-WORLD-03 | not started |  | A skid trench on the planet is cut at one fixed half width of 32 units (about one body height across) at every power, so the mark a slide leaves does not grow with tier. |
| A-WORLD-10 | L | major | GW2 |  | not started |  | A body that hits a building or an outcrop still bounces back like a ping-pong ball, which Orb reported on three dates; the settings that would hold it are one switch row… |

## A4. Horde, teams, your own planet, the whole fighter — 19 rows

**animation** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-ANIM-03 | S | minor |  |  | not started |  | The animation coverage table is of 2026-10-03, was built from Combat's then-parked files, still marks 180 of 228 rows parked, and its check runs in no gate. |

**art** (2)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-ANIM-01 | M | major |  | A-COMBAT-06 | not started |  | A transformation changes only the aura: both fighters play the same three placeholder poses for every form and no body look is keyed to a form. |
| A-ANIM-02 | S | major |  |  | not started |  | In a 2v2 the two copies of each fighter are drawn identically, and the mirror match is held off for the same missing second colour. |

**combat-choreography** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-COMBAT-04 | XL | blocker | GW3 | A-COMBAT-02 A-ENERGY-01 | not started |  | The move table is incomplete for both fighters: 18 of 101 cells have no outcome, 65 reach the same entry as another cell, and the LB, LT and RT rows of the face buttons… |

**controls-feel** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-CONTROLS-01 | M | major |  |  | not started |  | Couch 2v2 with four pads cannot be played: the input hub holds two human slots per PC and every pad routine loops over two. |

**encounter-systems** (4)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-AI-01 | L | blocker | GW3 | A-MODES-02 | not started |  | There is no computer control for many weak enemies: henchmen are paper only, the one-versus-many director (the ring) is parked and not on main, and a match holds five… |
| A-AI-06 (nice) | M | major | GW3 |  | not started |  | The computer never throws a right-stick strike, the main attack of Orb's scheme: the only right-stick input the computer writes is the beam's hold. |
| A-AI-08 | M | major | GW3 | A-MODES-03 | not started |  | There is no computer ally: the only 2v2 line-up puts both computers on the enemy team, and no menu or host can start a match with a computer on a human's side. |
| A-AI-09 | S | minor | GW3 |  | not started |  | The computer's level is one value for the whole match, not one per fighter, so an ally weaker or stronger than the enemy, or graded enemies, cannot be set. |

**game-design** (2)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-COMBAT-06 | L | major | GW3 | A-ENERGY-01 | not started |  | Transformations are the shared three-tier ladder for both fighters: the Protagonist's own forms are switched off, the rival has none, and the only per-tier look is an… |
| A-MODES-02 | XL | blocker | GW3 |  | not started |  | The co-op horde mode does not exist: there is no horde design page, the henchmen page says it is paper only, and the sim's many-body match holds at most five bodies with… |

**netcode-online** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-NET-06 | S | minor |  |  | not started |  | LAN 2v2 has been played on two real PCs only in its team form and only on the 2026-11-07 build; the apart form has no real two-PC record on any build. |

**qa-balance** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-QA-06 | M | major |  | A-MODES-02 | not started |  | QA has no script or band for team play or the horde, though the balance page sets 45 to 55% for every 2v2 team. |

**rendering-techart** (2)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-MODES-03 | L | blocker |  | A-CONTROLS-01 A-MODES-01 | not started |  | Couch 2v2 cannot be started: the game's host only ever starts a two-body match, the input hub has two player slots, and the only code that asks the sim for two fights is… |
| A-MODES-09 | L | major |  |  | not started |  | LAN 2v2 exists only as two humans, one on each PC, against two computer fighters, and each screen shows only its own fight; the owner reported never seeing all four… |

**simulation-engine** (2)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-CODE-05 | L | major | GW3 |  | not started |  | Adding a third fighter needs code today: 365 places in shipped code name exactly two fighters, and per-fighter look tables sit in render and UI code keyed by fighter id. |
| A-COMBAT-12 | S | minor | GW3 |  | not started |  | A live transformation blocks new exchanges but damage has no transformation guard, so 'respected' is not proven for shots already in flight. |

**world-environment** (2)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-WORLD-02 | L | blocker | GW3 | A-WORLD-01 | not started |  | Custom planet setup has nothing under it: the generator takes a seed only, the planet's size is a constant, and city count, climate and water are fixed numbers in data… |
| A-WORLD-09 | S | major |  |  | not started |  | The planet hash comparison X-11 asks for is not a check: the fingerprint tool prints lines with no verdict and is left out of CI, CI runs on Linux only, and no… |

## A5. A newcomer on a Deck, alone; the last numbers settle — 16 rows

**audio-music** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-AUDIO-02 | M | major |  |  | not started |  | No sound exists for a building being damaged or collapsing, bystanders scattering, the gravity well, or any menu action, and the fight has no ambience or music bed in… |

**community-marketing** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-MARKET-08 | S | minor |  |  | not started |  | The marketing plan predates Orb's Alpha definition: it stages a public browser build and public itch.io page, advises against Discord, still holds clips for the old… |

**game-design** (2)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-AI-02 | S | major | GW4 |  | not started |  | Easy is too hard for a scripted player using Orb's scheme: it won 19 of 40 (47.5%) on the tree that became the played build, against Game Design's band of at least 70%… |
| A-QA-05 | M | major | GW4 |  | not started |  | A right-stick-only pad loses almost every match in QA's latest reads: 0 of 60 against Medium on 2026-11-07 and 2 of 30 against Easy on the kept build of 2026-11-02. |

**legal-ip** (1)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-TEXT-04 (nice) | S | minor |  |  | not started |  | The title is shown and stamped as plain "Orb Combat EX" with no working-title mark, while Legal's page says the visible heading may keep "(working title)" until the… |

**qa-balance** (2)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-QA-01 | S | blocker |  | A-LEGAL-05 A-TOOLS-02 A-TOOLS-05 | not started |  | No tester guide, tester checklist, Deck checklist or playtest protocol exists: nothing tells a tester how to get a key, install on a Steam Deck, update, what to try, or… |
| A-QA-08 | S | minor | GW4 |  | not started |  | Match length is not measured on the current build against the 6 to 8 minute target; Orb's one finished match on 6a30b4c9 ran 19,388 ticks, about 5.4 minutes. |

**rendering-techart** (3)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-RENDER-05 | S | major |  |  | not started |  | The Settings screen offers 'Effects quality' (auto, high, medium, low) but no game code reads the choice, so changing it does nothing. |
| A-RENDER-06 | L | major |  |  | not started |  | The quality range Orb asked for (performance to maximum) is a paper ladder and a research prototype: the game has no level picker, no Steam Deck default level, and an… |
| A-WORLD-05 | L | major |  | A-WORLD-03 | not started |  | The ground drawn is not the ground stood on: the tile ground draws only the 16 nearest crater bowls, and the plan records that planet trenches and beam scars are not… |

**tools-pipeline** (3)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-MARKET-05 | S | minor |  |  | not started |  | Footage is made at 960 by 540, shrunk to 480 wide at 12 pictures a second, as GIF or browser-recorded WebM with no MP4, below what the project's own Steam note asks of… |
| A-MARKET-06 | S | minor |  |  | not started |  | The clips shared so far were staged on a private test copy with behaviour the game does not have (both at top power, a beam on a button, changed speeds, a scratch-only… |
| A-SAVES-08 (nice) | S | minor |  |  | not started |  | Where the game keeps its files is written nowhere a tester would read, and the folder is the engine default named after the working title, so a change of title would… |

**ui-ux** (3)

| Row | Size | Severity | Window | Needs | Status | Evidence | What it is |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A-TEXT-03 | S | minor |  |  | not started |  | The how-to card names keyboard keys to a pad player: its corner hint reads "Enter: next Esc: close" whenever touch is off, and its reopen line says "the pause menu or… |
| A-UI-05 | S | major |  |  | not started |  | The Rail's match-over screen is a full-height panel over the left 30% of the screen, which is where player one's plate, portrait and spoken lines sit; no still of it is… |
| A-UI-08 | S | major |  |  | not started |  | How to play's Reading the fight page describes things the minimal HUD no longer draws (a ring that flashes on a hurt body, finishing-move rings, the planet strip, a box… |

## A6. The Alpha candidate, frozen — 0 rows

_No register row closes here._
