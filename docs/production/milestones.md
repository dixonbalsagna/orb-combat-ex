# Milestone tracker

_Live page. Last built from status.json for **2026-11-13**. It is rebuilt every two days when the Executive Producer sends status (tools/build-tracker.mjs; nothing on this page is typed by hand except the words in status.json). Production Operations keeps it; the Executive Producer is the only source of status._

**Nothing on this page decides anything.** The path to Alpha (docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md) is the audit's recommendation. Orb accepted the first group of the path's decisions on 2026-11-13 (table below); every other milestone, size and week range stays a recommendation until Orb approves it.

## Where the project is

**Milestone A1, "Main is the game Orb plays".** 77 rows: 29 not started, 36 briefed, 9 reported, 3 landed.

**Budget.** A1 runs on up to about 40% of this week's meter (the week reset Fri 13 Nov 19:00). The audit used about 26 points, so A1 pauses for Orb when the all-models meter reads about 66%. The path puts A1 at about 55M tokens over 2 to 4 weeks, plus about 12M for the planet scope the EP added.

**Waves.** From tonight: Tools, Simulation, UI, Encounter, World and Rendering build in scratch copies; Game Design, Production Ops and Legal write papers; the stand-in designs and reviews; the EP does the working tree. From Saturday 14 Nov: Camera and VFX (the safety readings, captures one at a time), Controls, Audio, Combat (spike S4), QA (first readings), Performance (desktop frame and load readings, quiet windows only) and Netcode.

| Milestone | What it proves | Rows | Not started | Briefed | Reported | Landed | Tokens (path) | Weeks (path) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A1 (now) | Main is the game Orb plays | 77 | 29 | 36 | 9 | 3 | 55M | 2 to 4 |
| A2 | Safe to hand out; two real Steam Decks have run it | 41 | 39 | 2 | 0 | 0 | 34M | 2 to 4 |
| A3 | The fight's new rules, and LAN inside the game | 27 | 27 | 0 | 0 | 0 | 53M | 3 to 5 |
| A4 | Horde, teams, your own planet, the whole fighter | 19 | 19 | 0 | 0 | 0 | 57M | 2 to 3 |
| A5 | A newcomer on a Deck, alone; the last numbers settle | 16 | 16 | 0 | 0 | 0 | 16M | 1.5 to 3 |
| A6 | The Alpha candidate, frozen | 0 | 0 | 0 | 0 | 0 | 13M | 2.5 to 5 |

**Switch rows still differing between main and the 9 November build: 72 of 92** (2026-11-13; audit baseline 8901d351, as the path reports it). The Executive Producer reports this count every 2 days; the next is due 2026-11-15. It must reach 0 for A-CODE-01 to close.

| Date | Still differing | Of | Note |
| --- | --- | --- | --- |
| 2026-11-13 | 72 | 92 | audit baseline 8901d351, as the path reports it |

## What could move the date

The three risks the path names (full list, owners, early signs and guards in risk-register.md):

1. **Main cannot simply be made into the game Orb plays.** 72 switch rows, patches that exist only in a preview tool and checks that have never run on the configuration Orb plays. If this takes three weeks instead of one and a half, everything moves by the difference. Watch: the count above, every two days.
2. **The Steam Deck says no to something** (a graphics driver, a frame rate under 30, text too small, controls not arriving as a pad). Watch: spike S5 in A1, the first real session in A2.
3. **The fight rework is a class bigger than estimated** (the beam, the signature inputs, the stamina loop and the gravity well all change the same code). Watch: spikes S1 and S2 in A1 and the stop rule at A3's midpoint.

Also watched: the wait for people (two friends, twice), the weekly token limit, one Executive Producer session holding the project's state, and the year-end holidays, which fall inside every range and are not counted.

## Orb's decisions, in the path's numbering

| # | Decision | Needed before | Status | Orb's words |
| --- | --- | --- | --- | --- |
| 1 | Make the 9 November build the default game on main, row by row, before any new feature work | day one of A1 | answered | GO |
| 2 | Default world: a new random planet each quick match (seed shown and saved); one fixed planet for a newcomer's first match and for tests | day one of A1 | accepted | Go with recommendation on all |
| 3 | Globe ground, the crater look without the black fill and the meteor trail become the defaults; the terrain workshop of 9 November is after Alpha | day one of A1 | accepted | Go with recommendation on all |
| 4 | The look reference for every visible change: the 9 November globe build | day one of A1 | accepted | Go with recommendation on all |
| 5 | Flight speed 3500 as the default in every mode | day one of A1 | accepted | Go with recommendation on all |
| 6 | The old hero and villain meters: keep the comeback rule for every fighter, zero the rest now, remove the code after Alpha | day one of A1 | accepted | Go with recommendation on all |
| 7 | Desktop test builds for named testers (Windows, Linux); two friends with Decks for a first 30-minute session | A2 can close | answered | GO (two Deck friends now, a spare, two held back; no names in the answer as recorded) |
| 8 | The report channel: a new private server, a tester-only channel, delete on request | A2 can close | answered | I WILL MAKE THE DISCORD SOON (not made yet) |
| 9 | A restricted, key-only itch.io page under the working title, if Legal agrees; Orb does the account, page and upload tool | A2 can close | answered | GO |
| 10 | Licence: all rights reserved through Alpha with a short permission page; public code decided at Beta | A2 can close | answered | GO |
| 11 | How much of the stamina, energy and body loop is in Alpha (the whole loop as shared rules, numbers per fighter in data) | A2's work-ahead starts (asked day one) | accepted | Go with recommendation on all |
| 12 | How much gravity well, and does your stick move only you up close (asked after spike S2's clip) | A2's work-ahead starts (asked day one) | open | KEEP WORKSHOPPING, PLAYER AGENCY MUST BE RESPECTED (no standing yes; ask after spike S2's clip) |
| 13 | LAN at Alpha: for Orb and the trusted second player only, Windows only | A2's work-ahead starts (asked day one) | answered | GO |
| 14 | Beam stages and the other "workshop this" items: before or after Alpha (the split) | A2's work-ahead starts (asked day one) | accepted | Go with recommendation on all |
| 15 | The move table's bar for Alpha (the smaller table; the full one at Beta) | A4 starts (asked day one) | answered | FULL TABLE ON BETA, KEEP ITERATING WHAT WE HAVE. |
| 16 | Horde first size; couch 2v2 line-up; a computer partner; the custom planet's dials | A4 starts | partly | GO on the horde's first size (three weak enemies at a time); couch line-up, computer partner and planet dials still open |
| 17 | A transformation: aura only or the body too; a second body colour per fighter in 2v2 | A4 starts | open | (not answered yet) |
| 18 | The campaign at Alpha: none (recorded as X-12) | A5 starts (asked day one) | answered | GO |
| 19 | The frame-rate targets: 60 on Orb's PC; the Deck's confirmed after A2's real reading | A5 (the Deck's default quality) and A6 | direction | KEEP IMPROVING PERFORMANCE ON ALL LEVELS (the targets stay working targets) |
| 20 | A pad that drops out mid-match pauses with a notice; keyboard "works, a pad is recommended" | A5 starts | open | (not answered yet) |
| 21 | Sound: a quiet fight with no music is acceptable; Orb does a ten-minute listening pass at A2 | A5 starts | open | (not answered yet) |
| 22 | Orb marks about 150 lines of tester-facing text; the fighters speak their approved lines; English only | A5 starts | open | (not answered yet) |
| 23 | After the freeze, every new idea waits unless Orb lifts it in as a scope change | A6 | open | (not answered yet) |

## Words used on this page

- **park:** finished work waiting outside main (the project's main line of code) until the Executive Producer lands it.
- **gate:** the Executive Producer's check before anything lands on main: the saved test results plus, for anything you can see, a side-by-side picture against the 9 November build.
- **golden window:** a landing that changes the simulation's fingerprint; the saved reference matches are re-recorded and replays from earlier builds stop verifying. There are four (GW1 to GW4).
- **fingerprint:** a short number the simulation produces from a match; if a change moves it, the game plays differently.
- **switch row:** one on/off setting in the build's switch list; 72 of 92 differ between main and the build Orb played on 9 November.
- **spike:** a small throwaway trial on a scratch copy that answers "how big is this really?" before anyone commits weeks to it; nothing from a spike lands.
- **row:** one line of the audit's gap register (270 lines); a row is closed when its work is on main with a saved record.
- **X-nn:** an exit criterion, such as X-29; "must pass" means the milestone cannot close without it, "first reading" means a failing number is the expected result this time.

**Status words.** _not started_: no brief has gone out. _briefed_: the director has the brief (or the Executive Producer is doing it). _reported_: the director has reported and the work is parked or the paper written, not yet on main. _landed_: on main, with the commit id shown. A status can be traced to a commit or a report: the Evidence column says which.

## Orb's kept builds: the second copy

The builds, play files, reports and clips Orb keeps are about 2.9 GB in one git-ignored folder on one disk (register row A-TOOLS-09); they are the only copies of what Orb played and the only way back to an earlier build, so a disk fault would lose them. Where the second copy lives: not decided. The recommendation is a second drive first, copied by one command after each play session; Orb has not yet said where the second copy should live. Last copy made: none yet. (Row A-TOOLS-09, Tools' row; this paragraph is updated when Orb answers and each time a copy is made.)

# The milestones

## A1. Main is the game Orb plays — the milestone the project is in

**Goal.** A fresh copy of the repository, with one command, makes the Windows and Linux desktop builds of the game Orb played on 9 November; that build opens on a list of modes with a fighter pick and can be quit with the pad; and the biggest unknowns in the fight have each been tried small.

**Why here.** 72 of the 92 switch rows differ between main and the build Orb plays, and 14,805 paths were uncommitted. Until this closes, every test describes a different game from the one being judged, so nothing later starts landing.

**What Orb can play.** The first desktop build of their own game: a Windows program that opens on the left-panel menus, on the round planet, with the pad as Orb plays it and flight at 3500. The start menu lists the modes that exist today, lets each player pick a fighter, and has a Quit row.

**Size (the path's estimate).** 55M (the sprint adds about 12M for the planet, terrain, destruction and clipping scope); 2 to 4 weeks. **Rows:** 77: 29 not started, 36 briefed, 9 reported, 3 landed.

**Golden window.** GW1 "Main is the game" (12 rows: A-AI-05, A-AI-10, A-CODE-01, A-COMBAT-05, A-COMBAT-11, A-COMBAT-14, A-CONTROLS-02, A-CONTROLS-04, A-ENERGY-04, A-ENERGY-05, A-MODES-07, A-WORLD-01). GW1a: the golden record is made first on the kept 9 November build's own data as the target; the switch groups land one owner at a time (pad, computer opponent, match-ending rules, round planet, camera, look, sound sets, left-panel menus), each with its own gate run and side-by-side; A-CODE-01 closes when main reproduces the target bit for bit. GW1b, straight after: the riders (backburnered meters set to zero, the two stray-beam fixes, the computer's perfect-block fix, flight 3500), then one re-record. A-NET-05 (the build id in a replay) lands before the window.

**Directors active.** Tools & Pipeline, Simulation & Engine, Encounter Systems, World & Environment, Rendering, Camera, Controls & Game Feel, UI & UX, Audio, Game Design, Combat & Choreography (spike S4), QA & Balance, Performance & Platform, Netcode (the replay's build id), Legal, Production Operations, the Executive Producer

**Exit lines**

| Line | Kind | What passes |
| --- | --- | --- |
| X-29 | must pass | One command and one CI run make the Windows and Linux builds from a commit, the solo game included; the build shows a version number; a changelog entry is written. |
| X-33 | must pass | The change-control rule and the ideas log exist and the playbook points to them; there is one backlog; the working tree is committed or deliberately ignored. |
| X-27 | first held here | A replay carries its build id; a replay from another build is refused with a plain message. |
| Golden record | must pass | A golden record exists for the configuration Orb plays and the gates run with the switches as shipped (A-CODE-02); the 92-row switch table is reduced to rows that still describe a choice. |
| X-17 | first reading | Beams started by any input other than the right stick or RT + B, counted on Orb's saved play files and the scripted set. The aim is 0; the count is built here and must pass from A2. |
| X-05 | first reading | The mode smoke suite exists and has run solo and two players on one PC on Windows and Linux, from the menu, with a pad alone, to a result, a rematch and a quit. |
| X-23, X-26, X-06 | first readings | A frame record and loading times for the desktop build on Orb's PC; win rates at Easy, Medium and Hard for a scripted player on Orb's scheme, on the build's own packed data. |
| Measuring tools | first (failing) readings | The tools for X-03 (move coverage), X-04, X-13 and X-16 exist and have each produced a first reading; the 1280 by 800 screen sweep exists and has produced stills of every menu. |
| Spikes S1 to S5 | one page each | Each ends in one page: what was tried, what it cost, the size class now believed, and the question for Orb if there is one. S1 beam, S2 gravity well, S3 horde, S4 move table, S5 Linux picture. |

**Decisions still open that this milestone needs**

_None open that this milestone needs._

**Rows by owner**

| Owner | Rows | Not started | Briefed | Reported | Landed |
| --- | --- | --- | --- | --- | --- |
| audio-music | 1 | 1 | 0 | 0 | 0 |
| camera | 1 | 1 | 0 | 0 | 0 |
| combat-choreography | 1 | 1 | 0 | 0 | 0 |
| controls-feel | 2 | 2 | 0 | 0 | 0 |
| encounter-systems | 6 | 0 | 6 | 0 | 0 |
| ep | 16 | 12 | 1 | 3 | 0 |
| game-design | 3 | 0 | 0 | 1 | 2 |
| legal-ip | 1 | 0 | 0 | 0 | 1 |
| orb | 2 | 0 | 0 | 2 | 0 |
| performance-platform | 3 | 3 | 0 | 0 | 0 |
| production-ops | 3 | 0 | 0 | 3 | 0 |
| qa-balance | 9 | 9 | 0 | 0 | 0 |
| rendering-techart | 3 | 0 | 3 | 0 | 0 |
| simulation-engine | 4 | 0 | 4 | 0 | 0 |
| tools-pipeline | 13 | 0 | 13 | 0 | 0 |
| ui-ux | 8 | 0 | 8 | 0 | 0 |
| world-environment | 1 | 0 | 1 | 0 | 0 |

**audio-music** (1)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-AUDIO-01 | On main five sound sets are off, so a build made plainly from main has no beam, knock-out, launch, struggle or… | S |  | not started | wave 2, from Saturday 14 Nov |

**camera** (1)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-CAMERA-01 | The camera Orb played (swing, peak launch shot, launch director, close brawl, readable size, 70/30 share,… | S |  | not started | wave 2, from Saturday 14 Nov |

**combat-choreography** (1)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-COMBAT-14 | The mixed string's switch reads 'on' in the played build but no game code reads its data file; the feature comes from… | S | GW1 | not started | wave 2, from Saturday 14 Nov |

**controls-feel** (2)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-CONTROLS-02 | The pad as the owner plays it is not the default in data: eleven input switches are off on main and on in both played… | M | GW1 | not started | wave 2, from Saturday 14 Nov |
| A-CONTROLS-06 | No moveset coverage probe exists: the nearest tool presses each input alone for 90 ticks and its saved result is from a… | M |  | not started | wave 2, from Saturday 14 Nov |

**encounter-systems** (6)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-AI-05 | Main's computer-opponent data is not the played build's: Easy's pace matching, the beam pacing against a human, and the… | S | GW1 | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-AI-10 | The fix for Orb's remark that the computer perfect-blocks charged attacks too easily is parked and not on main: its… | S | GW1 | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-AI-13 (nice) | The parked one-versus-many work was last rebuilt on 2026-10-16 and applies by exact-text patches; whether it still… | S |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-COMBAT-05 | A released stick beam that cannot start waits up to 90 ticks and then fires into whatever the player is doing; open… | S | GW1 | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-COMBAT-11 | RT + B stays a signature for as long as the fighter is not channelling, not for 12 ticks, because the rule reads state… | S | GW1 | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-MODES-07 | On main the rules that end a match as the last played build did (knockout only by a finishing move, wear for an idle… | S | GW1 | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |

**ep** (16)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-ANIM-06 | The animation runtime, its tools and its data (render/anim, data/anim) are on no director's owns line; Animation owns… | S |  | not started |  |
| A-CODE-01 | Main does not hold the game Orb plays: 72 of the 92 build switch rows differ between main and Orb's solo build, so a… | L | GW1 | not started |  |
| A-PROCESS-02 | There is no single backlog: open work sits in the corrective plan, the EP's messages and per-machine memory notes,… | S |  | reported | EP row; Production Ops draft in docs/production/backlog-draft.md — Partial draft: the register and the corrective plan are in; it waits on the EP's owed list, QA's bug list and the parked-folders list. The EP owns and commits it. |
| A-PROCESS-03 | The working tree carries 14,805 uncommitted paths, including run records, parked work, the terrain plan and three QA… | M |  | briefed | EP's own, under way (docs/ep/sprints/A1-sprint.md) — Tools' group landed in 191e5e30; one owner's group at a time, screened before each push. |
| A-PROCESS-06 | The P0 to P5 roadmap in CLAUDE.md no longer describes the project: no phase gate result is on record, P3 and P4 name… | S |  | not started |  |
| A-PROCESS-07 | The corrective plan of 2026-11-07 has not been kept: 13 of 27 rows have no closing entry, 8 items have neither a commit… | S |  | not started |  |
| A-PROCESS-08 | No weekly token record exists: the EP has no clean figures for the last three weeks, so milestone lengths in weeks can… | S |  | reported | EP row; Production Ops draft in docs/production/token-record.md |
| A-PROCESS-09 | The /sprint-plan and /sprint loop is installed but has never run, and its input, the audit's path-to-Alpha page, does… | S |  | not started |  |
| A-PROCESS-10 | The project's running state depends on one EP session: four commands hard-code its session id, and its handover notes… | S |  | not started |  |
| A-PROCESS-11 | CLAUDE.md and ADR 0005 still tell every session the project is on a Pro plan with no workflows, against Orb's standing… | S |  | not started |  |
| A-PROCESS-13 | The director roster has no Alpha mapping and carries stale parts: charters list backburnered duties, one charter's… | S |  | not started |  |
| A-PROCESS-14 | The commands the sprint loop replaces are still live: /crunch is tracked with its 2026-11-01 priorities, /overnight is… | S |  | not started |  |
| A-PROCESS-15 | The standup command does not read CI first, although the corrective plan's CD-20 asks for that step in both the… | S |  | not started |  |
| A-PROCESS-16 | 'Done' exists only as one general rule; no page lists each Alpha feature with its own done test, and the exit criteria… | S |  | reported | EP row; Production Ops draft in docs/production/done-tests.md |
| A-RENDER-07 | No record ties a visible landing to its side-by-side: landings arrive as batches, the gate records of the last five… | S |  | not started |  |
| A-RENDER-11 | The look gate's reference build is still d3f1ca0e of 2026-10-15, which predates the globe ground and everything Orb… | S |  | not started |  |

**game-design** (3)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-COMBAT-15 | Six of Orb's 'workshop this' combat items have no decision: beam stages, the timed swat, the catch, what RT held does,… | S |  | landed | 970d15a6 — The six workshop items placed (Game Design). The EP confirms the row closes. |
| A-CONTROLS-04 | The flight speed the owner preferred (3500) exists only as a slider on the private browser page; the data's default is… | S | GW1 | reported | 970d15a6 — Game Design's paper on flight 3500 landed; the data default changes in GW1b. |
| A-ENERGY-02 | No single written page states the model: it is spread over six design pages, the oldest still a proposal that disagrees… | S |  | landed | 970d15a6 — The model page (Game Design). The EP confirms the row closes. |

**legal-ip** (1)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-LEGAL-09 | Whether a restricted, key-only itch.io page may go up before the title search is not confirmed anywhere: Legal's own… | S |  | landed | ae01d434 — Legal's ruling on the itch.io page under the working title, on conditions (in RL-261 to RL-266). |

**orb** (2)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-LEGAL-10 | The owner's one-line licence choice is not on record, so the build says the licence is not chosen yet and no plain… | S |  | reported | Orb's answer, vision.md 2026-11-13 night; Legal's ruling in ae01d434 — The permission page itself is still to be made; the EP confirms what closes the row. |
| A-WORLD-14 | No default world is decided: Orb's solo copy opens on planet 7 through a shortcut's page word, LAN fixes planet 7, and… | S |  | reported | Orb's answer, vision.md 2026-11-13 night (accepted the recommendation) — The default itself lands with A-WORLD-01 in GW1. |

**performance-platform** (3)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-PERF-04 | Nothing about frame rate, loading or memory has been measured on the build Orb last played, and no windowed native… | S |  | not started | wave 2, from Saturday 14 Nov |
| A-PERF-06 | No loading time is on file for the desktop game with menus, the tile ground and generated planets; the last native… | S |  | not started | wave 2, from Saturday 14 Nov |
| A-PERF-07 | Memory has never been measured on a desktop build, and growth over time is marked not measured, so the soak's 10%… | S |  | not started | wave 2, from Saturday 14 Nov |

**production-ops** (3)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-PROCESS-01 | No written change-control rule for the feature freeze and no ideas log exist, and the EP's playbook points to neither. | S |  | reported | Production Ops report to the EP, 2026-11-13: change-control.md and ideas-log.md parked in docs/production/ — Needs Orb's yes to the rule and the playbook pointer (the EP's). |
| A-PROCESS-04 | The risk register is the starting set of 2026-09-28, never updated, and lists none of the risks that have since… | S |  | reported | Production Ops report to the EP, 2026-11-13: risk-register.md rewritten in docs/production/ |
| A-PROCESS-05 | There is no milestone tracker or live roadmap, and the Production Operations director who owns them has no commit in… | S |  | reported | Production Ops report to the EP, 2026-11-13: milestones.md and milestone-rows.md parked in docs/production/ |

**qa-balance** (9)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-AI-03 | Medium and Hard have no win-rate record for Orb's scheme on any build since 2026-11-01; the only figures on a design… | S |  | not started | wave 2, from Saturday 14 Nov |
| A-AI-04 | No win rate has been measured on the played build's own packed data: every record was made on a scratch tree with… | S |  | not started | wave 2, from Saturday 14 Nov |
| A-AI-11 | Forty matches a cell cannot tell neighbouring bands apart (about 15 points either way), and the drop the EP flagged,… | S |  | not started | wave 2, from Saturday 14 Nov |
| A-COMBAT-08 | No tool measures X-03 (move coverage), X-04 (forms reached), X-13 (the pillars in one match) or X-16 (beam escape), and… | M |  | not started | wave 2, from Saturday 14 Nov |
| A-QA-03 | The bug list holds 1 of the 52 problems Orb reported in play from 2026-11-01 to 2026-11-09, and its newest entry is… | S |  | not started | wave 2, from Saturday 14 Nov |
| A-QA-04 | Balance between the two fighters is not measured on the build Orb plays: the last full reading (48.9%, in band) is from… | M |  | not started | wave 2, from Saturday 14 Nov |
| A-QA-07 | The bug list has no severity field (it has a release horizon and a closing step), and its title still names the… | S |  | not started | wave 2, from Saturday 14 Nov |
| A-QA-09 | The scripted player that matches Orb's scheme lives in Tools' gauntlet, plays 40 matches in slot 0 only, and fired no… | S |  | not started | wave 2, from Saturday 14 Nov |
| A-SAVES-01 | No record on file shows a replay saved by the baseline build verifying to its last tick on that build, and the first… | S |  | not started | wave 2, from Saturday 14 Nov |

**rendering-techart** (3)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-PERF-08 | The game sets no window: there is no display section in the project file and no fullscreen, resolution, vertical-sync… | S |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-RENDER-01 | The look Orb plays (globe ground, crater look, meteor trail, the swing camera that rides with it) is switched on only… | M |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-RENDER-04 | (see the full table) | M |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |

**simulation-engine** (4)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-CODE-02 | The golden record and five gates are valid only with the switches off, so the configuration Orb plays has no golden… | M |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-ENERGY-04 | The "one energy model" is off in the data on main and in both played builds, and is on in Orb's build only through a… | S | GW1 | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-ENERGY-05 | The backburnered hero and villain meters, hiding and ambush, and signature variants by biome still act in every match:… | M | GW1 | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) — Game Design's comeback numbers landed in 970d15a6; the data change (other effects set to zero) lands in GW1. |
| A-NET-05 | A replay carries a hash of its data, its format and its input version but no build id, so a replay from a build with… | S |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |

**tools-pipeline** (13)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-CODE-03 | Orb's solo build carries code that is not on main: the preview patches a scratch copy of the main scene to add the… | M |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-CODE-04 | CI runs 116 of the 262 check and test scripts: none of the input, audio or UI checks, one of 26 camera tests, 5 of 65… | L |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-ENERGY-06 | The tool X-15 names does not measure X-15: the two-fighter ratchet counts four spellings of "exactly two fighters" and… | S |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-LEGAL-02 | No desktop package for an outside tester can be made today: the build workflow needs a recorded approval file that does… | M |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-MODES-08 | No mode smoke suite exists: the one smoke check drives the browser build by clicking fixed screen points and failed… | M |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-TOOLS-01 | No one command or CI run makes the Windows and Linux desktop builds of the game as Orb plays it, the solo game… | L |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-TOOLS-07 | A build carries a commit and a date but no version number, the Windows program's version fields are empty, no changelog… | S |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-TOOLS-08 | The Godot check job's time swings from about 35 to 62 minutes on unchanged game code against a 75-minute limit, and the… | S |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-TOOLS-09 | The owner's builds, play files, reports and clips sit in one git-ignored folder of about 2.9 GB on one disk, with no… | S |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) — Production Ops wrote the tracker paragraph (milestones.md, "Orb's kept builds"); Orb's answer on where the second copy lives is still open. |
| A-TOOLS-10 | The playbook's build-verification rule cites a script that is not in the repository and a tool name that matches no… | S |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-TOOLS-13 | No CI job ever starts a Windows build: every job runs on Linux, and the desktop workflow reads the Windows program's… | S |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-TOOLS-15 | Corrective item CD-21 (stop silent passes: 'grandfathered', 'report only' and 'CHECK' lines that print as exceptions in… | S |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-UI-02 | On main, and so in any plain desktop build, the one-press report and 'Save this match' save nothing: the hook that… | M |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |

**ui-ux** (8)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-MODES-01 | The start menu has no list of modes: its rows are one or two players, each player's device, the computer's level, five… | M |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-MODES-06 | There is no fighter select: a match's fighters default to the first two ids of the roster file, so player one is always… | M |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-MODES-11 | With a pad alone a player can go back to the menu but cannot close the game: the pause and match-over lists have no… | S |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-MODES-15 | The Rail menu the owner picked is switched off on main and on only in the played build, so a candidate built from main… | S |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-UI-01 | With the Rail menus on (as in the build Orb played), the pause menu's slide-in is timed on a HUD clock that the game… | S |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-UI-04 | Making the Rail the default is unfinished: its switch is off on main, three older HUD checks fail with it on, Tools'… | M |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-UI-06 | The start menu's d-pad behaves unevenly, as Orb reported: Up from the top row jumps to Start while Down from the bottom… | S |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |
| A-UI-09 | X-22 cannot be measured today: there is no still of any screen at 1280 by 800 and no tool that sweeps every screen at… | S |  | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |

**world-environment** (1)

| Row | What it is | Size | Window | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| A-WORLD-01 | On main the round planet is not the game's world: a match with no planet setup key plays the old hand-made arena, the… | M | GW1 | briefed | wave 1 brief (docs/ep/sprints/A1-sprint.md) |

**Added since the path, outside the register** (4 items; they have no register row, so they are listed apart and not counted in the 77 rows above). They land after GW1a is proven, as their own windows.

| Item | Owner | What | Status | Evidence | Where it came from |
| --- | --- | --- | --- | --- | --- |
| ADD-A1-01 | world-environment | Five selectable planet sizes (World, with Simulation and Performance): from World's six, five are picked; each generates, plays and holds the shipped quality on Orb's PC, and its frame cost is read in a quiet window. | not started | planned in docs/ep/sprints/A1-sprint.md; the stand-in's planet design comes first | Orb, 2026-11-13 night (ideas-log ID-22) |
| ADD-A1-02 | world-environment | Terrain (World, with Camera): terrain step 2 (globe-step2) re-cut so Camera's chase check passes, then the path's terrain rows. | not started | planned in docs/ep/sprints/A1-sprint.md | Orb, 2026-11-13 night (ideas-log ID-22) |
| ADD-A1-03 | world-environment | Destruction (World, with VFX): craters and trenches drawn where you stand, and buildings breaking at every tier without the rebound Orb saw. | not started | planned in docs/ep/sprints/A1-sprint.md | Orb, 2026-11-13 night (ideas-log ID-22) |
| ADD-A1-04 | rendering-techart | Clipping (Rendering, with Animation): fighters' feet meet the drawn ground, and no fighter sinks into a crater or a building. | not started | planned in docs/ep/sprints/A1-sprint.md | Orb, 2026-11-13 night (ideas-log ID-22) |

## A2. Safe to hand out; two real Steam Decks have run it

**Goal.** Every gate on the "before an outside tester plays" list is green on a commit, and two friends have each installed that build on a Steam Deck from the real restricted itch.io page with a key and a full draft of the tester guide, played 30 minutes with the Deck's own controls, run the one-press bench and sent back two files.

**Why here.** The Deck is the largest unknown the team cannot study alone: no Linux build has drawn a picture on real hardware and the frame rate is a guess. Learning it with four milestones left costs far less than learning it with one.

**What Orb can play.** The same game as A1 (no rule changes, so A1 replays still play), now as the package a tester would get: a notice before play, the AI disclosure on the first screen, a report that saves from the pad on any PC, and a crash file if the game dies. Orb also does the ten-minute listening pass.

**Size (the path's estimate).** 34M (includes a 6M fix reserve for what the first tester round finds); 2 to 4 (the top of the range is the wait for Orb's account actions and two friends' evenings) weeks. **Rows:** 41: 39 not started, 2 briefed, 0 reported, 0 landed.

**Golden window.** none. No rule changes: a replay saved on the A1 build still plays on A2's.

**Directors active.** Camera, Rendering and VFX, Legal, Accessibility & Localization, Tools & Pipeline, Performance & Platform, UI & UX, Controls & Game Feel, Audio, QA & Balance, Community & Marketing. Working ahead for A3 behind switches: Encounter Systems, Simulation & Engine, Game Design, Netcode.

**Exit lines**

| Line | Kind | What passes |
| --- | --- | --- |
| X-02 | must pass | The list of gates exists and each has a saved record under docs/*/runs/<sha>/ for this commit, including the measurements on the globe ground that every played build uses. |
| X-28 | must pass | A forced crash on Windows and on Linux leaves a file, and the report folder picks it up. |
| X-21 | must pass | One press saves a report under 10 MB with nothing sent automatically; the file has been checked for account names and file paths; the code read finds nothing that sends data. (On the Deck, by the friend's file.) |
| X-17 | must pass | No beam started by anything other than the allowed inputs, on the saved play files and the scripted set. |
| X-18, X-19 | first real reading | Each friend's sheet comes back saying how long install took and where they got stuck. Not a pass yet; the guide is a draft. |
| X-24, X-26 | first real reading | A frame record and loading times from a real Deck, made by the one-press bench. This number decides whether "30 held, 40 as the aim" stands. |
| X-30, X-31 | must pass as a rehearsal | A dummy build is pushed to a restricted itch.io page on a Windows and a Linux channel, a key is claimed, an update is applied and the previous version is restored in one step; then the A2 build goes up, and A3's and A4's builds reach the two friends as updates. |
| X-25 | first reading | A two-hour soak on Windows and on Linux in CI, with memory growth recorded. |
| X-07, X-20 | must pass | A pad unplugged mid-match pauses with a plain notice and the two-pad checklist is signed; settings survive a real restart on Windows and Linux. |
| X-34 | started | The shot list is one data file; the render job has produced the first archive entry from the A1 and A2 builds. |
| Three picture faults | each explained | Fighters sinking into the ground, three humps in a crater and the black diagonal line each have a still, a cause and an owner, or a written "cannot reproduce" with the replay used. |

**Decisions still open that this milestone needs**

- **12.** How much gravity well, and does your stick move only you up close (asked after spike S2's clip) (needed before A2's work-ahead starts (asked day one)) — open: KEEP WORKSHOPPING, PLAYER AGENCY MUST BE RESPECTED (no standing yes; ask after spike S2's clip)

**Rows by owner** (status in brackets once past "not started"; the full table has each row's text)

- **accessibility-localization** (1): A-ACCESS-01
- **audio-music** (2): A-AUDIO-03, A-AUDIO-04
- **camera** (1): A-CAMERA-03
- **controls-feel** (2): A-CONTROLS-03, A-CONTROLS-07
- **ep** (1): A-ACCESS-04
- **legal-ip** (4): A-LEGAL-03 [briefed], A-LEGAL-05, A-LEGAL-12, A-TOOLS-06
- **orb** (1): A-LEGAL-07
- **performance-platform** (3): A-CONTROLS-08, A-PERF-01, A-PERF-03
- **qa-balance** (2): A-QA-02, A-QA-11
- **rendering-techart** (4): A-PERF-05, A-RENDER-02, A-RENDER-03, A-RENDER-08
- **tools-pipeline** (9): A-LEGAL-06, A-MARKET-01, A-MARKET-02, A-MARKET-03, A-MARKET-07, A-TOOLS-02, A-TOOLS-03, A-TOOLS-04, A-TOOLS-05
- **ui-ux** (5): A-ACCESS-02, A-LEGAL-13, A-TEXT-01, A-UI-07, A-UI-10

_6 more rows of this milestone are listed only on the full table (milestone-rows.md); they carry no question for Orb._

## A3. The fight's new rules, and LAN inside the game

**Goal.** In one normal match a player aims a beam with the stick and the other dodges it by moving off its line, both signatures fire from Orb's inputs, stamina, energy and body work as one loop, the pull into a close fight exists, and a second PC joins from a Host or Join row instead of a folder of shortcuts.

**Why here.** These are the blockers with the widest reach: the move table, transformations, the computer's play and every balance band sit on these rules. They share one golden window so the fingerprint moves once, and they are attacked early so that a beam rework or gravity well twice its class is known in week 5, not week 10.

**What Orb can play.** The first build with new rules to press. Solo and two players on one PC as before; LAN 1v1 with the second PC started from the menu, with rematch and back to menu.

**Size (the path's estimate).** 53M; 3 to 5 (the milestone most likely to overrun) weeks. **Rows:** 27: 27 not started, 0 briefed, 0 reported, 0 landed.

**Golden window.** GW2 "The fight's rules" (11 rows: A-COMBAT-01, A-COMBAT-02, A-COMBAT-03, A-CONTROLS-05, A-ENERGY-01, A-ENERGY-03, A-ENERGY-10, A-WORLD-03, A-WORLD-04, A-WORLD-07, A-WORLD-10). The terrain rows ride in this window because World and Rendering are free while the fight teams work. Stop rule: if the gravity well's first cut is not playable at A3's midpoint, A3 ships its size and zones only and the snap moves to GW3, without holding the beam or the stamina loop.

**Directors active.** Encounter Systems, Simulation & Engine, Game Design, Controls & Game Feel, World & Environment, Rendering, Camera, VFX, UI & UX, Netcode, QA & Balance, Legal (the LAN ruling), Performance & Platform. Working ahead for A4: Combat & Choreography (move table), Game Design (horde page).

**Exit lines**

| Line | Kind | What passes |
| --- | --- | --- |
| X-16 | must pass | A scripted defender's sidestep makes the beam miss at three ranges. |
| X-17 | must pass | Beams and signatures from any input other than Orb's: 0, for the player and the computer, on the scripted set and on play files saved on this build. |
| X-15 | must pass (resized) | One page states the model; every energy, stamina and body number is data per fighter; the count of fighter-specific code in those systems is read here and must be zero from A4; no health bar; a still set shows health, energy and readiness can be read from the fighter at speed. |
| X-13 | partial, must pass | For: a lap, each stance, a beam aimed and dodged, both signatures, a launch, the gravity well's pull, a crater, a building damaged, bystanders scattering. The transformation line is first required at A4. |
| X-14 | first reading | The crater-width ratio between the top and base tier, and the skid trench growing with tier. Must pass at A4. |
| X-08 (LAN 1v1) | must pass | Two Windows PCs: five full matches with no state mismatch; rematch and leave work; a pulled cable shows a plain notice on both PCs inside the agreed time; every status is on screen and not in the window's title. |
| X-05 | partial, must pass | The mode smoke suite passes for solo, two on one PC and LAN 1v1 on Windows, and for solo and two on one PC on Linux. |
| X-03 | reading only | The count of unanswered presses on this build, down from 30%. |
| Gate list re-run | must pass | The gates on A2's list are re-run on this commit, because the new beam changes what is on screen. |

**Decisions still open that this milestone needs**

- **16.** Horde first size; couch 2v2 line-up; a computer partner; the custom planet's dials (needed before A4 starts) — partly: GO on the horde's first size (three weak enemies at a time); couch line-up, computer partner and planet dials still open
- **17.** A transformation: aura only or the body too; a second body colour per fighter in 2v2 (needed before A4 starts) — open

**Rows by owner** (status in brackets once past "not started"; the full table has each row's text)

- **camera** (1): A-CAMERA-05
- **controls-feel** (1): A-COMBAT-07
- **encounter-systems** (4): A-AI-07, A-COMBAT-01, A-COMBAT-02, A-CONTROLS-05
- **game-design** (1): A-ENERGY-01
- **legal-ip** (1): A-LEGAL-04
- **netcode-online** (8): A-MODES-04, A-MODES-05, A-MODES-10, A-NET-01, A-NET-02, A-NET-03, A-NET-04, A-PERF-02
- **simulation-engine** (3): A-COMBAT-03, A-ENERGY-03, A-ENERGY-10
- **ui-ux** (2): A-ENERGY-07, A-ENERGY-08
- **vfx** (1): A-RENDER-13
- **world-environment** (5): A-WORLD-03, A-WORLD-04, A-WORLD-06, A-WORLD-07, A-WORLD-10

## A4. Horde, teams, your own planet, the whole fighter

**Goal.** All eight modes less the campaign can be started from the menu with a pad, played to a result, rematched and left; each fighter has a complete move table at the Alpha's bar and two forms beyond base.

**Why here.** This is where the game gets its breadth. The move table is the last big item on the critical path, so it starts as soon as the signature inputs are fixed.

**What Orb can play.** Horde for one or two players; couch 2v2 and 2v2 alone with a computer partner; LAN 2v2; a planet set up from a seed and three dials; every held-button row doing its own thing.

**Size (the path's estimate).** 57M (about 10M less with the smaller versions proposed); 2 to 3 weeks. **Rows:** 19: 19 not started, 0 briefed, 0 reported, 0 landed.

**Golden window.** GW3 "Many bodies and the full fighter" (10 rows: A-AI-01, A-AI-06, A-AI-08, A-AI-09, A-CODE-05, A-COMBAT-04, A-COMBAT-06, A-COMBAT-12, A-MODES-02, A-WORLD-02). The last window that takes rule changes. After it closes, an idea that changes a rule waits for after Alpha.

**Directors active.** Game Design, Encounter Systems, Combat & Choreography, Simulation & Engine, Rendering, Camera, World & Environment, Controls & Game Feel, Art, Animation, Netcode, UI & UX, QA & Balance, Tools & Pipeline.

**Exit lines**

| Line | Kind | What passes |
| --- | --- | --- |
| X-05 | must pass | The smoke suite starts, finishes, rematches and leaves every mode Alpha ships (LAN on Windows; on Linux by the two-program check in CI). |
| X-02 | must pass | On this commit before the build reaches a friend, with a clip of the largest horde wave added to the standard clip set. |
| X-10 | frame record must pass; run length first reading | A horde run of 5 to 10 minutes with waves, respawn and a result screen; the frame record at the largest wave holds 60 on Orb's PC. The Deck's reading comes by bench file and is judged at A6. |
| X-09 | must pass | The supported line-ups are written down and each one is played from the menu. |
| X-08 (LAN 2v2) | must pass | Five full matches, both forms of 2v2, on two real PCs. |
| X-04 | must pass | A scripted match reaches each form for each fighter; one still per form; a blow in flight when a transformation starts is handled the written way. |
| X-03 | must pass (the Alpha's bar) | The pad-driven coverage probe finds no cell without an outcome, and no duplicate inside the rows the bar names. |
| X-13, X-14 | must pass | All the pillars in one scripted match; the crater and trench ratios. |
| X-11 | must pass (the dials) | The same seed and choices give the same planet on both LAN PCs. The Windows-against-Linux comparison is first required at A5. |
| X-15 (third fighter) | must pass (resized) | The count of places in the code that name exactly two fighters is recorded, cannot rise, and is zero in the energy, stamina, body and forms systems. |

**Decisions still open that this milestone needs**

- **20.** A pad that drops out mid-match pauses with a notice; keyboard "works, a pad is recommended" (needed before A5 starts) — open
- **21.** Sound: a quiet fight with no music is acceptable; Orb does a ten-minute listening pass at A2 (needed before A5 starts) — open
- **22.** Orb marks about 150 lines of tester-facing text; the fighters speak their approved lines; English only (needed before A5 starts) — open

**Rows by owner** (status in brackets once past "not started"; the full table has each row's text)

- **animation** (1): A-ANIM-03
- **art** (2): A-ANIM-01, A-ANIM-02
- **combat-choreography** (1): A-COMBAT-04
- **controls-feel** (1): A-CONTROLS-01
- **encounter-systems** (4): A-AI-01, A-AI-06, A-AI-08, A-AI-09
- **game-design** (2): A-COMBAT-06, A-MODES-02
- **netcode-online** (1): A-NET-06
- **qa-balance** (1): A-QA-06
- **rendering-techart** (2): A-MODES-03, A-MODES-09
- **simulation-engine** (2): A-CODE-05, A-COMBAT-12
- **world-environment** (2): A-WORLD-02, A-WORLD-09

## A5. A newcomer on a Deck, alone; the last numbers settle

**Goal.** Someone who has never seen the game installs it from the itch.io page with a key, reads the notice, picks a mode, a fighter and a planet, plays, rematches, changes a setting that is still there next time, and sends a report, with only the tester guide and the Deck's own controls. The last tuning of numbers lands at the end, so the candidate that follows is frozen.

**Why here.** The risky halves of the newcomer's path were proven at A2. What is left is words, stills and one picture-quality picker, best written once the menus stop changing at A4.

**What Orb can play.** The dress rehearsal: Orb installs on the second PC from the real itch.io page with a real key, following the guide and nothing else.

**Size (the path's estimate).** 16M; 1.5 to 3 weeks. **Rows:** 16: 16 not started, 0 briefed, 0 reported, 0 landed.

**Golden window.** GW4 "Numbers only" (3 rows: A-AI-02, A-QA-05, A-QA-08). At the end of the milestone. Data values only; no rule may change in this window. If a rule has to change it is priced as a scope change. At least three read-and-adjust rounds, each an overnight batch.

**Directors active.** QA & Balance, UI & UX, Rendering, Audio, Tools & Pipeline, Legal, Narrative & Fighter Identity, Community & Marketing, Performance & Platform, Game Design, Encounter Systems.

**Exit lines**

| Line | Kind | What passes |
| --- | --- | --- |
| X-02 | must pass | On this commit before the build goes on a channel a friend holds a key to. |
| X-18, X-19 | must pass as a rehearsal | Install and first match from the guide alone, by Orb and the trusted second player; the real pass is at A6. |
| X-22 | must pass | The 1280 by 800 sweep finds no clipped or overlapping text and nothing under 9 px; 12 px is the aim. |
| X-20 | must pass | Settings survive a restart, quality level included. |
| X-21, X-32 | must pass | Legal's sign-off row for each paper a tester meets; privacy words the same in the package, the game and the note. |
| X-11 | must pass | The planet fingerprint matches between Windows and Linux in CI. |
| X-12 | recorded | The campaign decision is written with its reason. |
| X-31 | must pass | The A5 build is on the itch.io page on both channels and has been updated once and rolled back once. |
| X-34 | must pass | The shot list has rendered from A1 to A5 and the five sets sit side by side. |
| X-06 | must pass | Win-rate bands at each difficulty for a scripted player on Orb's scheme, with enough matches per cell to tell neighbouring bands apart; the balance between the two fighters re-read in the same window. |

**Decisions still open that this milestone needs**

_None open that this milestone needs._

**Rows by owner** (status in brackets once past "not started"; the full table has each row's text)

- **audio-music** (1): A-AUDIO-02
- **community-marketing** (1): A-MARKET-08
- **game-design** (2): A-AI-02, A-QA-05
- **legal-ip** (1): A-TEXT-04
- **qa-balance** (2): A-QA-01, A-QA-08
- **rendering-techart** (3): A-RENDER-05, A-RENDER-06, A-WORLD-05
- **tools-pipeline** (3): A-MARKET-05, A-MARKET-06, A-SAVES-08
- **ui-ux** (3): A-TEXT-03, A-UI-05, A-UI-08

## A6. The Alpha candidate, frozen

**Goal.** One commit passes every criterion from X-01 to X-34, two friends complete the checklist on their Steam Decks, and the feature freeze begins.

**Why here.** Nothing new is built here: this milestone is verification and people. After A6 passes, a new idea goes in the ideas log or comes to Orb as a scope change.

**What Orb can play.** The candidate, exactly as the testers get it.

**Size (the path's estimate).** 13M (about 5M of checks and an 8M fix reserve); 2.5 to 5, set by people: two friends' time and one round of fixes weeks. **Rows:** 0: 0 not started, 0 briefed, 0 reported, 0 landed.

**Golden window.** none. Rules and numbers are frozen from the end of A5. A fix that would change the fingerprint sends the candidate back to A5's window, and that is said out loud.

**Directors active.** QA & Balance, Game Design, Encounter Systems, Performance & Platform, Tools & Pipeline, Legal and Accessibility (the gate re-read), Production Operations (the freeze).

**Exit lines**

| Line | Kind | What passes |
| --- | --- | --- |
| X-01, X-35 (proposed) | must pass | Two outside testers on Steam Decks return signed checklists; no open bug of the top severity, and every open bug of the next severity seen by Orb and carried by name. |
| X-02 | must pass | Every gate green, records saved for this commit. |
| X-06 | must pass | Win-rate bands at each difficulty (Easy 60 to 80%, Medium 35 to 55%, Hard 10 to 30%), plus team and horde bands. |
| X-23, X-24, X-26 | must pass | 60 frames a second held on Orb's PC with no frame over 50 ms outside loading; the agreed Deck figure held, from a tester's bench file; loading under 15 s on Orb's PC and 30 s on the Deck. |
| X-25 | must pass | Two hours of computer against computer on Windows and Linux (and one friend's Deck) with no crash, hang or script error and memory growth under 10%. |
| X-27 to X-34 | re-read | Re-read on the candidate; for X-27 a replay saved by the Linux build verifies on the Windows build; X-33: the freeze is recorded; X-34: the candidate's shots are in the archive. |
| X-03, X-04, X-05, X-13, X-14, X-16, X-17 | re-run | Re-run on the candidate's commit, because the numbers moved at the end of A5. |

**Decisions still open that this milestone needs**

- **23.** After the freeze, every new idea waits unless Orb lifts it in as a scope change (needed before A6) — open

**Rows.** None: no register row closes here. The milestone is verification and people.

---
_Source files: 03-gap-register.json and 04-milestone-rows.json in docs/ep/alpha/audit-2026-11-13/, status.json and tools/ here. The full table, every row of every milestone with what each needs, is milestone-rows.md. Method and the checks run: runs/ (the newest folder)._
