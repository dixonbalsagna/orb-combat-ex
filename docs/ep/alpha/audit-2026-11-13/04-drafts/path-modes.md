# Path to Alpha, draft: modes first

One planner's draft, written alone from the gap register (`03-gap-register.json`, 270 rows, baseline 8901d351). Two other drafts take other angles. Ids below drop the leading `A-` (so `MODES-01` is register row `A-MODES-01`).

## The angle, and the pace assumed

**Modes first.** Every milestone adds modes that can be started from the menu with a pad, played to a result, rematched and left, on a real desktop program and not a browser page. The fight those modes carry is, at first, exactly the fight of the 9 November build; it is deepened only once all eight modes stand (A4). The reason: six of the eight modes have no menu entry today, the mode shell is where the menu, the build, the smoke tests, the Steam Deck and the report route all meet, and every later change to the fight is then tried in every mode by the same automatic run. "Safety and the blockers first" is read here as: the safety gates and the blockers to making and handing out a build come first (A1); the blockers inside the fight (beams, signatures, the gravity well, stamina, the move table) are large, are designed on paper during A2 and A3, and are built in A4.

**Pace, in one line:** I assume about 60 points of the weekly meter go to this path (the rest to the Executive Producer, the stand-in and Orb's own asks), which is about 60M tokens on the cheaper model or about 38M on the largest; weeks are given from 80 points a week (low) to 45 (high), plus half a week or more per milestone for gates, the build and people. The record behind this is thin: one night planned at about 10% was about 13M tokens briefed, one week reached about 82%, and there are no clean weekly figures (PROCESS-08, closed in A1, starts the record so A2 onward can be re-estimated).

**Token budgets** are the rows' cost classes added up (S 0.25M, M 1.2M, L 4M, XL 8M, after the resizes proposed below), plus 20% held for rework and the Executive Producer's gate runs. These are size classes with no comparables, not quotes. Work by the directors on the largest model (Game Design, Combat, Encounter, Simulation, Netcode) costs about 1.6 meter points per 1M tokens, the others about 1.

**Tools and passes.** Where a measuring tool and its first reading land in the same milestone, that milestone's exit is "the tool exists and its reading is on file"; the pass is required from the next milestone on and again on the candidate.

| | Name | Modes startable from the menu at the end | Golden window | Tokens (with reserve) | Weeks |
| --- | --- | --- | --- | ---: | --- |
| A1 | Main is the game, safe to hand out | solo at three levels; two players on one PC | W1 | 48M | 1.5 to 2 |
| A2 | Six modes | + team match on one PC (2v2), LAN 1v1, LAN 2v2, a planet picked by seed | none | 38M | 1 to 1.5 |
| A3 | All eight | + horde for one or two; custom planet with its dials; the campaign answered | W2 | 25M | 1 to 1.5 |
| A4 | The whole fight | the same eight, with the full fight in each | W3 | 62M | 2 to 3 |
| A5 | The newcomer's path | the same eight, plus Practice | W4 | 13M | about 1 |
| A6 | The Alpha candidate | the same; nothing in the fight's rules changes | none | 7M | 1.5 to 2.5 |
| | **Total** | | 4 windows | **about 193M** | **8 to 11.5** |

Counted from 2026-11-13 that is a candidate between mid January and early February 2027, before any allowance for the year-end holidays. It is an estimate, not a target.

**People's time, counted in the weeks above:** Orb plays each milestone's build (about an hour each, two short looks inside A4) and answers the questions at the foot of this page; a friend with a Steam Deck gives 30 minutes after A2; at least two friends with Steam Decks give an evening each at A6 (the checklist, then two hours with the game left running by itself); the trusted second player joins Orb for the two-PC matches at A2 and A6.

---

## A1. Main is the game, safe to hand out

**Goal:** the game Orb played on 9 November becomes what a fresh copy of the project builds, as a Windows and a Linux program made by one command, with every safety gate recorded, and with solo and two-player matches started and ended from the new left-panel menu (the team calls it the Rail) with a pad alone.

**PLAY THIS (A1).** Start the Windows program, not the browser page. *New:* the left-panel menu is the menu; it has a list of modes (Solo and Two players work; the others are listed and greyed out), a fighter pick for each player, the computer's level, and a Quit row. Flight is at the speed Orb liked (3500) with no slider. *Try:* play a solo match at each level, then two pads on one PC; pause mid-match (the menu must be on screen); at the result, press Rematch, then leave to the menu, then Quit, all on the pad; unplug the second pad mid-match (the game should pause and say so); release a right-stick beam while it cannot start (nothing should fire late); press RT, wait a second, press B (no signature); look at a crater after a beam (no flat black fill).

**Exit criteria**
- X-29: one command makes the Windows and Linux programs from a commit, solo game included, with a version number the game shows and a changelog line (TOOLS-01, TOOLS-07).
- X-02: the list of gates "before an outside tester plays" exists, and each gate has a saved record on the A1 commit under `docs/*/runs/<sha>/`, including the flash reading on the globe ground in normal and reduced modes (LEGAL-03, LEGAL-01, LEGAL-08, CAMERA-02, SAVES-02, UI-03, ACCESS-01). The pass on every line is required before the A2 build goes to a friend.
- X-05 (first two modes): the mode smoke suite exists and its Solo and Two-players rows run menu to result to rematch to quit on Windows and on Linux with a scripted pad (MODES-08, MODES-01, MODES-06, MODES-11).
- X-07: each pad drives its own fighter, player one starts on the left, and a pulled pad pauses with a plain notice (CONTROLS-03).
- X-27 (ground work): the configuration Orb plays has its own golden record, and the A1 build's own replays verify on it (CODE-02).
- X-33: the change-control rule and the ideas log exist and the playbook points to them (PROCESS-01).
- A plain build from main and Orb's 9 November build show no difference in the switch table: 0 of 92 rows differ (CODE-01).

**Gaps closed (67: 64 required, 3 nice)**
- Executive Producer: CODE-01, PROCESS-02, PROCESS-03, PROCESS-06, PROCESS-07, PROCESS-08, PROCESS-09, PROCESS-10, PROCESS-11, PROCESS-13, PROCESS-14, PROCESS-15, PROCESS-16, RENDER-07, RENDER-11, ANIM-06, ACCESS-04; nice: PROCESS-12, LEGAL-15
- Production Operations: PROCESS-01, PROCESS-04, PROCESS-05
- Tools & Pipeline: TOOLS-01, CODE-03, LEGAL-02, LEGAL-08, TOOLS-07, TOOLS-09, TOOLS-10, TOOLS-15, MODES-08; nice: CODE-10
- UI & UX: MODES-01, MODES-06, MODES-11, MODES-15, UI-01, UI-04, UI-05, UI-06, SAVES-02
- Camera: LEGAL-01, CAMERA-01, CAMERA-02
- Rendering: RENDER-01, RENDER-04, UI-03, PERF-08
- Encounter Systems: AI-05, AI-10, MODES-07, COMBAT-05, COMBAT-11
- Simulation: CODE-02, ENERGY-04
- Controls: CONTROLS-02, CONTROLS-03
- Game Design: CONTROLS-04
- Combat: COMBAT-14
- World: WORLD-01
- Audio: AUDIO-01
- Legal: LEGAL-03, TOOLS-06
- Accessibility: ACCESS-01
- QA: QA-03, QA-07
- Orb: LEGAL-10 (the one-line licence choice)

**Golden window W1, "main becomes the played game".** Eleven rows change the sim's state hash: CODE-01, AI-05, CONTROLS-02, ENERGY-04, MODES-07, WORLD-01 (the switch rows), CONTROLS-04 (flight at 3500), COMBAT-05 and COMBAT-11 (the two stray-beam faults), COMBAT-14 (the mixed string read from main), AI-10 (the computer's perfect block). They land row by row but the golden records are re-made once, at the end, by CODE-02. No new feature rides this window.

**Tokens:** 40.4M of rows, 48M with reserve. **Weeks:** 1.5 to 2. **Directors active:** Executive Producer, Production Operations, Tools, UI, Camera, Rendering, Encounter, Simulation, Controls, Game Design, Combat, World, Audio, Legal, Accessibility, QA (16). Game Design also starts the horde design page here so A3 does not wait for it (the row, MODES-02, closes in A3).

---

## A2. Six modes

**Goal:** four more modes start from the menu and end in a result and a rematch (a team match on one PC, LAN 1v1, LAN 2v2, and a match on a planet picked by seed), a Linux build draws a picture on a real Steam Deck for the first time, and one press saves a small report file on any PC.

**PLAY THIS (A2).** *New:* "Team match" (two pads as a team against two computer fighters, all four in one picture); "Host a LAN match" and "Join a LAN match" inside the game (no shortcut files, no closing windows: rematch or leave from both PCs), with the fighters and planet the host picks reaching both PCs; a Planet row (Random, a seed you can type on the pad, or the old planet as a preset) with the seed shown on the result screen; a report key that writes one file under 10 MB. *Try:* a team match with the second pad; five LAN 1v1 and five LAN 2v2 matches with the second player, then pull the network cable (both PCs should say so within 10 seconds); play the same seed twice (same planet); press the report key after a match and find the file; close the game from Task Manager mid-match and start it again (it should say it found a crash file).
*For the first Steam Deck friend (30 minutes):* unzip, start, play one solo match with the Deck's own controls, run the one-press bench, send back the bench file and one report file.

**Exit criteria**
- X-05: the smoke suite's rows for Team match, LAN 1v1, LAN 2v2 and Planet-by-seed run menu to result to rematch to leave (LAN rows on Windows; see the resize list), plus the two A1 rows still green.
- X-09: the supported line-up is written (two humans as a team against two computers; four pads after Alpha) and played on two pads (CONTROLS-01, MODES-03, ANIM-02: the two copies of a fighter differ by body colour, not by a marker).
- X-08: on two real PCs, five LAN 1v1 and five LAN 2v2 matches with no state mismatch on the A2 build, in both 2v2 forms; a pulled cable shows a plain notice on both PCs inside the agreed time; every LAN status is on screen, not in the title bar (NET-01, NET-03, NET-04, NET-06, MODES-04, MODES-05, MODES-10, MODES-09, CAMERA-05).
- X-27: a replay carries its build id; a replay from another build is refused with a plain message; an A2 replay verifies to its last tick on A2 (NET-05, SAVES-01).
- X-21 and X-28 (tools): one press writes a report under 10 MB on Windows and Linux with account names and file paths removed; a forced crash leaves a file the report picks up (UI-02, TOOLS-04, TOOLS-05, LEGAL-06).
- X-18, X-19, X-24, X-26 (first readings): a Linux build has started and drawn on a real Deck with its built-in controls and sound, and a bench file from that Deck is on file (PERF-01, PERF-03, CONTROLS-07, AUDIO-04); frame, loading and memory readings exist for Orb's PC on the desktop build (PERF-04, PERF-06, PERF-07).
- X-06 (tools): the scripted player that plays Orb's way lives in QA's folder, runs on the build's own packed data, with enough matches to tell the bands apart, and Easy, Medium and Hard each have a reading (QA-09, AI-04, AI-11, AI-03).
- X-34 (tools): the fixed shot list is one data file, a job renders it per milestone into a named archive folder with a line on what changed, the A1 build's shots are rendered from the kept A1 build, and every clip format gets the same safety check as a GIF (MARKET-01, MARKET-02, MARKET-04, MARKET-06, MARKET-07).
- X-02: every line of the gate list is green on the A2 commit before the build goes to the Deck friend.

**Gaps closed (44: 42 required, 2 nice)**
- Netcode: MODES-04, MODES-05, MODES-10, NET-01, NET-02, NET-03, NET-04, NET-06; nice: NET-07
- Rendering: MODES-03, MODES-09
- Camera: CAMERA-05
- Controls: CONTROLS-01, CONTROLS-07
- Art: ANIM-02
- Simulation: NET-05
- Tools & Pipeline: UI-02, TOOLS-04, TOOLS-05, LEGAL-06, TOOLS-08, CODE-04, MARKET-01, MARKET-02, MARKET-04, MARKET-06, MARKET-07; nice: TOOLS-13
- Performance & Platform: PERF-01, PERF-03, PERF-04, PERF-06, PERF-07
- QA: SAVES-01, QA-09, AI-03, AI-04, AI-11
- Audio: AUDIO-03, AUDIO-04
- Legal: LEGAL-04, LEGAL-05
- Orb: LEGAL-07 (the report channel), WORLD-14 (the default world)

**Golden window:** none. Nothing in A2 changes the sim's state hash; a planet by seed uses today's generator, and a team match uses the line-up the LAN code already asks the sim for. A1's replays are still refused by build id, as X-27 wants.

**Tokens:** 31.8M of rows, 38M with reserve. **Weeks:** 1 to 1.5; the Deck friend's half hour runs alongside and does not hold A3. **Directors active:** Netcode, Rendering, Camera, Controls, Art, Simulation, Tools, Performance & Platform, QA, Audio, Legal, UI (menu rows for the new modes) (12). Game Design continues the horde page and writes the one page for energy, stamina and health (the row, ENERGY-02, closes in A3).

---

## A3. All eight

**Goal:** the horde mode exists for one or two players, the custom planet has its dials, a lone player can take a computer partner into a team match, the campaign's answer for Alpha is written down, and an update has been pushed to and rolled back on a private itch.io page with a dummy build.

**PLAY THIS (A3).** *New:* "Horde" (one or two players against waves of weak enemies that come back, a run of 5 to 10 minutes, a result screen with the wave reached); "Custom planet" with three dials (how many cities, climate, water) beside the seed; a team match with a computer partner on your side, with its own level; Easy tuned so a player using the right stick and LB wins about 7 in 10. *Try:* a horde run alone and one with the second pad; the largest wave near a city; a dry planet with one city and a wet one with many; dig a crater near the shore (it should not fill with sea unless the sea can reach it); a team match alone with a partner.

**Exit criteria**
- X-05: all eight modes are accounted for: seven start from the menu with a pad and run menu to result to rematch to leave in the smoke suite on Windows and Linux (LAN rows on Windows), and the eighth, the campaign, has its written decision.
- X-12: "minimal or none for Alpha" is decided and written with its reason (recommended: none; the row MODES-14 stays after Alpha).
- X-10: horde for one and for two players; waves arrive and come back; a run lasts 5 to 10 minutes and ends on a result screen; a frame-time record at the largest wave is on file for Orb's PC (MODES-02, AI-01, QA-06).
- X-09: the computer-partner line-up starts from the menu, and the computer's level is set per fighter (AI-08, AI-09).
- X-11: seed, city count, climate and water are match settings; the planet hash comparison prints a verdict, runs in CI, and a Windows-against-Linux comparison is on file (WORLD-02, WORLD-09).
- X-06 (first band): Easy reads at least 70% for the scripted player on the A3 build's packed data (AI-02).
- X-30, X-31: a dummy build has been pushed to a Windows and a Linux channel on a restricted page, a key claimed, an update applied, and the previous version restored in one step; the release checklist names the build to return to (TOOLS-02, TOOLS-03, LEGAL-09). The account, the page, the keys and installing the upload tool are Orb's actions, done in one sitting from Tools' checklist.
- X-13, X-16, X-17, X-04, X-15 (tools, before A4 must pass them): the probes for the pillars in one match, beam escape at three ranges, the count of beams from any other input, and forms reached exist and give today's readings; the two-fighter check really counts fighter-specific code; the one page stating the energy, stamina and health model is written (COMBAT-08, ENERGY-06, ENERGY-02).
- X-22 (tool): a sweep saves a still of every screen at 1280 by 800 (UI-09).
- X-34: the capture hook works in the desktop programs, at full size (MARKET-03, MARKET-05).
- The decisions that size A4 are written: how much gravity well, which "workshop this" items are in (COMBAT-15).

**Gaps closed (23: 22 required, 1 nice)**
- Game Design: MODES-02, AI-02, COMBAT-15, ENERGY-02
- Encounter Systems: AI-01, AI-08, AI-09; nice: AI-13
- World: WORLD-02, WORLD-03, WORLD-04, WORLD-09
- QA: QA-06, COMBAT-08
- Tools & Pipeline: TOOLS-02, TOOLS-03, ENERGY-06, MARKET-03, MARKET-05
- Legal: LEGAL-09, LEGAL-12
- UI & UX: UI-09
- Rendering: PERF-05

**Golden window W2, "the rules the modes need".** Eight rows: MODES-02 and AI-01 (waves, respawn, many weak bodies), AI-08 and AI-09 (a computer ally, a level per fighter), WORLD-02 (planet dials as match settings), WORLD-03 and WORLD-04 (terrain step 2 and the sea fix, which the planet dials and the horde's craters need), AI-02 (Easy). One re-make of the golden records at the end.

**Tokens:** 20.9M of rows, 25M with reserve. **Weeks:** 1 to 1.5. **Directors active:** Game Design, Encounter, World, QA, Tools, Legal, UI, Rendering, Simulation and Performance (as helpers on the horde), Camera (the chase check that held terrain step 2) (11).

---

## A4. The whole fight

**Goal:** every pillar shows up in one ordinary match, in every mode: beams that leave the fighter and can be side-stepped, both signatures on Orb's inputs, the gravity well, the stamina, energy and body loop, transformations that change the body, a move table with no dead cells, and ground and buildings that answer a blow by its power.

**PLAY THIS (A4).** *New:* hold the right stick to aim a beam and release; the beam is seen leaving and travelling, and moving off its line makes it miss. RT + RB + a flick of the right stick is the energy signature; RT + a flick is the martial one; RT + B does nothing special. Up close the two fighters are drawn together and blows snap to the rival; far apart you have the long-range kit. Plain face-button blows refill stamina; specials and signatures spend stamina and energy; being hit while out of stamina makes injuries worse, and a new form eases them. Each fighter has its own forms with a visible body change, and a hint shows the transform press. A body thrown into a building stays in it. The computer throws right-stick strikes at Medium and Hard. *Try:* side-step a beam at three distances; land both signatures; transform twice in one match; knock the rival away and hit him again in the air; slide the rival along the ground at base power and at top power and compare the trench; press every face button with LB, RB, RT and LT held.
Orb gets two short looks inside A4 (after beams and signatures; after the well and the stamina loop), each a preview build with that work switched on. No switch outlives the window: at A4's end every one is the default on main.

**Exit criteria**
- X-13: on scripted matches of 6 to 8 minutes and on one of Orb's saved play files, the checklist probe finds every pillar at least once.
- X-16: a scripted defender who moves off the line by more than the beam's width is missed at three ranges (COMBAT-01).
- X-17: 0 beams or signatures started by any input but the right stick and the two signature presses, the computer included (COMBAT-02, AI-07, with A1's COMBAT-05 and COMBAT-11).
- X-04: a scripted match reaches each designed form for each fighter (at least two beyond base), a still per form shows a body change, and a transformation in progress is not broken by a shot already in flight (COMBAT-06, COMBAT-07, COMBAT-12, ANIM-01).
- X-15: the two-fighter check passes; every energy, stamina and body number is per-fighter data; the grey reference dummy enters a match from data alone; no health bar is on screen and a record shows the player can read health and energy from the fighter at speed (ENERGY-01, ENERGY-03, ENERGY-05, ENERGY-10, ENERGY-07, ENERGY-08, CODE-05).
- X-03 (tool and first reading): the coverage probe presses every cell of the Alpha table in a live match and lists empty and duplicate cells; the count of presses with no answer is re-made on this build (CONTROLS-06, CONTROLS-05, COMBAT-04, ANIM-03). The pass (0 empty, 0 duplicate) is A5's.
- X-14 (check and first reading): a check asserts the crater and trench ratio between base and top tier (proposed: 3 times the width), and a base-tier match leaves the planet standing (WORLD-06, WORLD-07, WORLD-10).
- The ground drawn is the ground stood on: craters, trenches and beam scars near the fighters are drawn, and Orb's two look faults (clipping into the ground, three humps in a crater) and the black diagonal line each have a still, a cause and a fix or a written reason (WORLD-05, RENDER-02, RENDER-03).
- Each mark drawn on or round a fighter is either removed or kept on Orb's word (RENDER-13).
- X-05: all smoke rows still green with the new fight.

**Gaps closed (32: 27 required, 5 nice)**
- Encounter Systems: COMBAT-01, COMBAT-02, CONTROLS-05, AI-07; nice: AI-06, COMBAT-10
- Simulation: COMBAT-03, COMBAT-12, ENERGY-03, ENERGY-05, ENERGY-10, CODE-05; nice: ENERGY-11, ENERGY-12
- Game Design: ENERGY-01, COMBAT-06
- Combat: COMBAT-04
- Controls: COMBAT-07, CONTROLS-06
- World: WORLD-06, WORLD-07, WORLD-10
- Rendering: WORLD-05, RENDER-02, RENDER-03; nice: ENERGY-09
- Art: ANIM-01
- Animation: ANIM-03
- VFX: RENDER-13
- UI & UX: ENERGY-07, ENERGY-08, UI-10

**Golden window W3, "the whole fight".** Eighteen rows: COMBAT-01, COMBAT-02, COMBAT-03, COMBAT-04, COMBAT-06, COMBAT-12, ENERGY-01, ENERGY-03, ENERGY-05, ENERGY-10, CODE-05, CONTROLS-05, WORLD-07, WORLD-10, and the nice rows AI-06, COMBAT-10, ENERGY-11, ENERGY-12. Order inside it: ENERGY-01 (needs A3's page) and COMBAT-02, then COMBAT-04 (which needs both), then COMBAT-06 and ENERGY-03 (which need ENERGY-01). One re-make of the golden records at the end; the shot list is re-recorded from its scripts.

**Tokens:** 51.3M of rows (4.1M of it the five nice rows), 62M with reserve. **Weeks:** 2 to 3. **Directors active:** Encounter, Simulation, Game Design, Combat, Controls, World, Rendering, Art, Animation, VFX, UI, Camera, Audio and QA as helpers (14).

---

## A5. The newcomer's path

**Goal:** a person who has never seen the game can go from the notice to a finished match and a sent report with a pad alone, at the Steam Deck's screen size, with settings that stick, and the three difficulty levels sit in their bands.

**PLAY THIS (A5).** *New:* the first screen carries the notice and the AI line, and the title reads "(working title)"; "How to play" names pad buttons and describes only what is on screen; "Practice" against the grey dummy; a picture-quality setting that does something, with a Steam Deck default; the feedback panel works on a pad; quiet background sound, and sounds for buildings and menus; settings and remapped buttons survive a restart. *Try:* play as a newcomer would: read the notice, open How to play, change a button and the quality level, quit, start again (both remembered); one Practice round; a solo match at each level (Easy should be winnable, Hard should not be routine); send a report using only the pad.

**Exit criteria**
- X-19: the Linux smoke runs notice, menu, picks, a full match, result, rematch and leave with a pad alone; How to play and the hints name no keyboard key to a pad player (UI-07, UI-08, TEXT-03).
- X-20: a settings round trip across a real restart passes on Windows and Linux; the quality setting is read by the game (RENDER-05, with A4's UI-10 test).
- X-22: the 1280 by 800 sweep shows no clipped or overlapping text on any screen, smallest text at least 9 px (12 px the aim, from Valve's guidance), and the camera's tests run at 1280 by 800 (CAMERA-03).
- X-24 (setting): three quality levels and a Steam Deck default exist; the automatic step no longer pins a 30 frames-a-second machine at low (RENDER-06).
- X-06: the scripted player wins inside the band at each level on the A5 build's packed data (proposed: Easy 60 to 80%, Medium 35 to 55%, Hard 10 to 30%, with the match count QA set in A2), and a right-stick-only player is no longer shut out (QA-05).
- X-03: the coverage probe reports 0 empty and 0 duplicate cells for both fighters on the Alpha table.
- X-13: matches run 6 to 8 minutes on the scripted batch (QA-08); the two fighters are within the balance band on this build (QA-04).
- X-25 (tool): the soak script writes a result file (crashes, hangs, script errors, memory growth) on Windows and Linux (QA-02); a one-hour trial run is on file.
- X-01, X-18 (paperwork): the tester guide and the Deck checklist exist and name the key, the install, the update, what to try and how to post a report (QA-01).
- X-32: the text a tester meets (about 150 strings) carries Orb's marks (TEXT-01).
- X-14: the tier ratio check passes.

**Gaps closed (20: 14 required, 6 nice)**
- UI & UX: UI-07, UI-08, TEXT-01, TEXT-03, ACCESS-02; nice: LEGAL-13, SAVES-03
- Rendering: RENDER-05, RENDER-06
- Camera: CAMERA-03
- Audio: AUDIO-02
- QA: QA-01, QA-02, QA-04, QA-08
- Game Design: QA-05; nice: MODES-12
- Legal: nice: TEXT-04
- Narrative: nice: TEXT-06
- Tools & Pipeline: nice: SAVES-08

**Golden window W4, "final numbers".** Two rows, numbers in data only: QA-05 (the difficulty bands) and QA-08 (match length). This is the last change to the sim's state hash before Alpha. Anything QA-04 finds out of band is fixed inside this window or waits.

**Tokens:** 10.7M of rows (2.5M of it the six nice rows), 13M with reserve. **Weeks:** about 1. **Directors active:** UI, Rendering, Camera, Audio, QA, Game Design, Encounter (as helper on the bands), Legal, Narrative, Tools, Accessibility (11).

---

## A6. The Alpha candidate

**Goal:** the A5 game, with nothing in its rules changed, is measured, soaked, pushed to the private itch.io page and played through the checklist by at least two outside friends on Steam Decks; then the feature freeze begins.

**PLAY THIS (A6).** *New:* nothing in the game. This is the build a friend gets: installed from the itch.io page with a key, with the tester guide beside it. *Try:* install it the way the guide says on a second PC; play one match in each of the eight modes; put it beside the A1 build's shots in the archive.

**Exit criteria (every criterion, on the candidate's commit)**
- X-01: at least two outside testers on Steam Deck return a completed checklist.
- X-02: every line of the gate list green, with a saved record.
- X-05 to X-11, X-13 to X-17, X-03, X-04: the smoke suite, the probes and QA's batches re-run on the candidate's packed data, all passing. X-08 again on two real PCs.
- X-18, X-19: a tester installs and starts on a Deck from the guide alone in under 10 minutes, and plays notice to rematch with the Deck's controls.
- X-20, X-21, X-22: settings round trip on a Deck; a report made on a Deck, under 10 MB, posted to the private channel by the tester; nothing sent automatically (code read on file).
- X-23: 60 frames a second held in a normal match on Orb's PC, no frame over 50 ms outside loading (RENDER-08's first-draw record included). X-24: 30 held on a Deck at its default level, bench file from a real Deck. X-26: loading under 15 s on Orb's PC and 30 s on the Deck.
- X-25: two hours of computer-against-computer on each platform, no crash, hang or script error, memory growth under 10%; the Linux run is a friend's Deck left running.
- X-27, X-28: candidate replays verify on the candidate; a foreign replay is refused; a forced crash is captured on both platforms.
- X-29, X-30, X-31: the candidate is built by the one command, pushed once through itch's upload tool to both channels, and the rollback step is rehearsed on the real page.
- X-32: Legal's sign-off row per item (disclosure, what a tester agrees to, the privacy line, credits and notices inside the build).
- X-33: the freeze is declared in writing. X-34: the shot list is rendered from the candidate and sits beside A1 to A5.
- The press-to-picture delay is measured with a pad on the desktop build and on a Deck (CONTROLS-08); the five old bug entries are re-checked in play (QA-11); the marketing plan matches Orb's Alpha and counts back from the Steam demo (MARKET-08).

**Gaps closed (4 required):** Performance & Platform: CONTROLS-08. QA: QA-11. Rendering: RENDER-08. Community & Marketing: MARKET-08.

**Golden window:** none; the sim's rules and numbers are frozen from the end of A5. A fix that would change the state hash sends the candidate back to a short W4 re-run and a new candidate.

**Tokens:** 1M of rows plus a fixed 6M held for fixes from the soak and the testers: 7M. **Weeks:** 1.5 to 2.5, mostly other people's evenings. **Directors active:** QA, Performance & Platform, Tools, Rendering, Legal, Accessibility, Community & Marketing, Production Operations, Executive Producer (9).

---

## Rows I propose to make smaller or move

Each is a proposal for Orb and the audit; none is dropped. Costs in the budgets above already use the smaller size.

| Row | Register size | Proposal | Reason | If Orb decides otherwise |
| --- | --- | --- | --- | --- |
| MODES-02 (horde) | XL | L: one or two players against waves of at most three weak bodies at a time, on today's five-body limit; bigger waves after Alpha | The register's own recommendation; it keeps the horde off the frame-rate cliff before a Deck has been measured | Back to XL: +4M and about a week on A3, and a Deck frame reading before the wave size is fixed |
| COMBAT-03 (gravity well) | XL | L: the well's size, its zones and the snap; the far kit, the catch, the timed swat and the taunt after Alpha | COMBAT-15's recommendation; X-13 asks only for "the gravity well's pull" | Back to XL: +4M and up to a week on A4 |
| COMBAT-04 (move table) | XL | L: the plain and energy rows complete for each fighter, the other held-button rows shared between them; X-03 reworded to that table; the full table at Beta | The register's recommendation; the full table is 55 cells a fighter and the largest single piece of content | Back to XL: +4M, a week or more on A4, more Animation work |
| NET-02 (LAN set-up by an outsider) | L | S: Host and Join inside the game with the address shown or typed, the firewall step written in a note for Orb and the second player; set-up by an outside tester after Alpha | LAN stays with Orb and the trusted second player for the first Alpha round (see the decisions) | Back to L: +3.75M, and LEGAL-04 and PERF-02 return (below) |
| LEGAL-04 (ruling for outsiders on LAN) | M | S: a ruling that names Orb and the second player only, and a tester package built without the network code | Same decision | Back to M: +1M, and a tester package that carries the network code and its privacy words |
| PERF-02 (LAN on Linux) | M, required | **Move after Alpha.** LAN is Windows-only at Alpha; X-05 and X-08 are reworded so the two LAN modes are tested on Windows | Its own recommendation ("Windows-only first"); with LAN kept to two Windows PCs nobody at Alpha can use a Linux LAN build | Back in A2 at M: +1.2M, a Linux LAN package, and a two-Deck LAN test in one room |
| WORLD-02 (custom planet) | L | M: a seed and three dials (city count, climate, water) at today's one size; the size pick (WORLD-08) after Alpha; X-11 reworded without size | The register's recommendation; what each size costs in frame rate has not been measured | Back to L and WORLD-08 in: +7M, and a frame reading per size on a Deck |
| CONTROLS-01 (four pads) | M | S: write the supported line-up (two pads as a team against two computers) and prove it on two pads; four pads after Alpha | The register's recommendation under MODES-03; the input hub's two slots are enough for that line-up | Back to M: +1M in A2 |
| CODE-05 (a third fighter without code) | L | M: the per-fighter look tables move to data, the energy, stamina and body rules carry no fighter id, and the grey dummy enters a match from data alone; the rest of the 365 places go down under the count check through Beta | X-15's proof at Alpha is one extra body from data; four fighters are Beta's bar | Back to L: +2.8M in A4, inside W3 |
| RENDER-06 (quality range) | L | M: three working levels, a Steam Deck default, and the automatic step fixed; anything above today's picture after Alpha (as RENDER-10 already is) | X-24 needs a default that holds 30 on a Deck, not a maximum | Back to L: +2.8M in A5 |

Two rows are split in time but close once: WORLD-06 (the check is written at the start of A4, the row closes when the ratio is met) and QA-01 (the guide is drafted at A3 for the itch.io rehearsal, the row closes in A5).

## The nice-to-have pool

Seventeen nice rows are placed above because they are cheap where they sit or serve the angle: CODE-10, PROCESS-12, LEGAL-15 (A1); NET-07, TOOLS-13 (A2); AI-13 (A3); AI-06, COMBAT-10, ENERGY-09, ENERGY-11, ENERGY-12 (A4); MODES-12, LEGAL-13, TEXT-04, TEXT-06, SAVES-03, SAVES-08 (A5).

The other 57 wait in the pool. A pool row is lifted only by the change-control rule, and a pool row that changes the state hash may ride only a window that is already open:

- **Would ride W3 if lifted (state hash):** CONTROLS-09, MODES-13, WORLD-11, CAMERA-12. **Recommended after Alpha:** COMBAT-09 (physics launches), WORLD-08 (world sizes).
- **Look and camera:** RENDER-09 (re-entry trail), RENDER-12 (3D auras), RENDER-14, RENDER-15, RENDER-16, CAMERA-04 (an ally window), CAMERA-06, CAMERA-07, CAMERA-08, CAMERA-09, CAMERA-13, MARKET-10.
- **Menus, text, comfort:** UI-11, UI-12 (a guided first match; Practice is placed in its stead), UI-13, UI-14, TEXT-02 (the fighters' spoken lines), ACCESS-03, ACCESS-05, CONTROLS-10.
- **Sound:** AUDIO-05 (music), AUDIO-06, AUDIO-07, AUDIO-08, PERF-10.
- **Saves:** SAVES-04, SAVES-05, SAVES-06, SAVES-07, QA-12.
- **Tools, code, records:** TOOLS-11, TOOLS-12, TOOLS-14, TOOLS-16, TOOLS-17, CODE-06, CODE-08, CODE-09, NET-09, NET-10, NET-11, PERF-09, QA-10.
- **Paper:** ANIM-04, ANIM-05, ANIM-08, LEGAL-11, MARKET-09, PROCESS-17, PROCESS-18, PROCESS-20.

## Deliberately after Alpha

- Four fighters (Beta's bar), online play, Mac, mobile, modding, the full campaign.
- The campaign slice itself: none at Alpha (MODES-14); the horde carries its co-op stage.
- The register's 22 "after" rows: COMBAT-13, ENERGY-13, AI-12, MODES-14, WORLD-12, WORLD-13 (the tessellation engine), RENDER-10 (a level above today's picture), CAMERA-10, CAMERA-11, NET-08 (an encrypted link, needed before any internet play), NET-12, ANIM-07, TEXT-05, PERF-11, CODE-07, CODE-11, CODE-12, LEGAL-14 (the content-rating records, before a store page), ACCESS-06, ACCESS-07, MARKET-11 (photo mode), PROCESS-19.
- Moved out by this draft: PERF-02 (LAN on Linux), LAN for outside testers, four pads on one PC, bigger horde waves, the full move table, the gravity well's far kit with the catch, swat and taunt, world sizes, physics launches.
- Orb's "workshop this" items not placed before Alpha: the terrain and deformable-mesh overhaul, the "High Intensity" use of RT, the taunt before a signature, walking into a beam, punching up a beam, the audio toolset, music, 3D auras, the ally window, and the ideas from the feature workshop not named in a row (the timed absorb on LB then RB, debris as ammunition, the campaign beats).
- The Steam demo and everything on its timeline (the fee, the title search, the store page), which starts when Beta is in sight.

## The change-control rule

**During the push (A1 to A5).** Every new idea, from Orb or from a director, is written into one ideas log (`docs/production/`, made by PROCESS-01 in A1) the day it is said, in Orb's own words, with a size class, whether it changes the state hash, and one of three recommendations from the Executive Producer: *now* (it fits inside a row already in the open milestone and adds no window), *next milestone* (named), or *after Alpha*. Orb sees the recommendation and says yes or changes it. Nothing is built silently, and nothing is refused silently. Three limits hold whatever the answer: an idea that changes the state hash rides only an open window (W1 to W4); an idea that adds a mode or a screen comes with its smoke-suite row; and an idea never displaces a required row without that row appearing on the resize list with a reason.

**After the freeze (from the end of A6).** A new idea is either logged for after launch, or brought to Orb as a scope change with its cost in tokens and weeks and what it pushes out. Only Orb lifts one in. Fixes, tuning inside the written bands, and polish that changes no rule are not scope changes.

## The critical path, and the three risks

**The chain that sets the earliest Alpha:**
CODE-01 (main becomes the played game, with its ten switch rows) → TOOLS-01 (the one-command desktop build) → MODES-01 (the mode list) → MODES-02 (the horde's design and rules) → AI-01 (control of many weak enemies) → *Encounter Systems is then free for* COMBAT-02 (signatures on Orb's inputs), beside ENERGY-02 → ENERGY-01 (the stamina loop) → COMBAT-04 (the move table, which needs both) → CONTROLS-06 (the coverage probe) → QA-05 (the difficulty bands on the finished fight) → QA-02's two-hour soak and the two friends' Deck checklists (X-25, X-01).
One director, Encounter Systems, sits on five links of it (the switch rows, the horde's enemies, beams, signatures, the bands), so its queue, not the token meter, is what sets the date. The modes-first order makes this visible: the horde must be out of that queue before the fight can enter it.

**The three risks most likely to move it**
1. **W1 uncovers more than it lands.** The game Orb plays has never had a golden record or a full gate run of its own: 72 of 92 switch rows differ from main, three menu checks fail with the left-panel menu on, the camera's chase check fails with terrain step 2, and the safety reading on the globe ground last failed in both modes. If turning those on by default takes two rounds, A1 slips by a week and everything behind it. Early sign: the first full gate run with all rows on, in A1's first days.
2. **The fight window (W3) overruns.** It holds five large rows across the same three directors, three of them already cut down from the register's size; if any goes back to full size, or beams break the beam struggle and the computer's beam play (the register's own warning), A4 becomes 4 weeks or more. Early sign: the beam escape probe and the pillars checklist, built in A3, read on the first preview build.
3. **The Steam Deck and other people's evenings.** No Linux build has ever drawn a picture; the first Deck session is after A2, and if a shader fails on the Deck's driver or the frame rate is far under 30, Rendering gains work nobody has sized. The candidate also needs two friends' evenings and a two-hour run, which no budget can hurry. Early sign: the bench file from the first Deck session.

## The decisions that are Orb's

Most urgent first. Each has one recommendation and what it holds up. (One topic the Executive Producer handles is left off this list on purpose.)

**Needed to start A1**
1. **May the team make the 9 November build the default game on main, row by row, before any new feature?** Recommend yes. Holds up: all of A1 (CODE-01), and so everything.
2. **Should the globe ground, the crater look with the black fill removed, and the meteor trail be the defaults, and is the 9 November build the one new looks are compared against?** Recommend yes to both, with its known look faults listed as not part of the reference. Holds up: A1's look checks (RENDER-01, RENDER-04, RENDER-11).
3. **May the team make desktop test builds for named testers, with your one-line yes recorded once the gates are green?** Recommend yes, Windows and Linux. Holds up: the A1 build and the A2 hand-out (TOOLS-01, LEGAL-02).
4. **The licence line: all rights reserved through Alpha, with a short friendly permission page, deciding about public code at Beta?** Recommend yes. Holds up: the words inside the A1 build (LEGAL-10).
5. **Flight at 3500 for every mode, slider dropped; a pulled pad pauses the match; the public web page stays offline and its decision returns to you until after Alpha; the free repository protections switched on.** Recommend yes to each. Holds up: small A1 rows (CONTROLS-04, CONTROLS-03, PROCESS-12, LEGAL-15).

**Needed during A1, for A2**
6. **Are the LAN modes at Alpha for you and the trusted second player only, on Windows, inside the game behind Host and Join?** Recommend yes; outside testers get the solo, same-PC and horde modes. Holds up: A2's size. *If outside friends get LAN too:* about +6M tokens and a week, a Linux LAN build, a tester package carrying network code, and a two-Deck test in one room.
7. **Team match on one PC: two pads as a team against two computers, plus (A3) one player with a computer partner; four pads after Alpha?** Recommend yes. Holds up: A2 (MODES-03, CONTROLS-01), A3 (AI-08). Also: a second body colour per fighter, picked by team, to tell the copies apart (ANIM-02).
8. **Which friend with a Steam Deck gives 30 minutes after A2?** Recommend asking one now. Holds up: the first Deck reading, which is the plan's third risk.
9. **The report channel: a new private Discord server (or a new channel locked to a tester role), and the promise to delete a tester's reports on request?** Recommend a new private server and keeping the promise. Holds up: the Deck friend's report in A2, the tester guide (LEGAL-07).
10. **A new random planet each quick match, seed shown and saved in reports, the current planet kept as a preset and used for a newcomer's first match and for tests?** Recommend yes. Holds up: A2's Planet row (WORLD-14). Also: on two PCs in a 1v1, each screen favours its own player (CAMERA-05); "the other PC has gone" within 10 seconds (NET-03); a ten-minute listening pass on the desktop build before the friend gets it (AUDIO-03).

**Needed during A2, for A3**
11. **A first horde of at most three weak enemies at a time, and no campaign at Alpha?** Recommend yes to both. Holds up: A3 (MODES-02, X-12).
12. **Custom planet as a seed and three dials at one size, sizes after Alpha?** Recommend yes. Holds up: A3 (WORLD-02).
13. **May the private, key-only itch.io page go up under the working title before the paid title search, and will you make the account, the page and the keys in one sitting from Tools' checklist?** Recommend yes, marked "(working title)". Holds up: A3's rehearsal and so A6 (LEGAL-09, TOOLS-02). No spending is involved.
14. **A second copy of your builds and play files on a second drive after each play session.** Recommend yes. Holds up: nothing, but protects the archive (TOOLS-09, MARKET-02).

**Needed during A3, for A4 (the fight)**
15. **How much of the stamina, energy and body loop?** Recommend the whole loop as shared rules with per-fighter numbers in data, the old hidden health number reused as "body" behind the four body parts, the backburnered meters' effects set to zero with only the comeback kept as a rule for everyone. Holds up: A4's largest design row (ENERGY-01, ENERGY-05, ENERGY-11).
16. **How much gravity well, and which "workshop this" items before Alpha?** Recommend the well's size, zones and snap, with "your stick moves only you up close" settled first from the packet's default; beam stages decided inside the beam work; RT held stays the energy charge; everything else on the "after" list above. Holds up: A4 (COMBAT-03, COMBAT-15, COMBAT-02).
17. **The move table: the smaller table for Alpha?** Recommend yes. Holds up: A4 (COMBAT-04) and what X-03 measures.
18. **A transformation: one cheap body change per step (hair or accent colour and the fighter's own pose)?** Recommend yes. Holds up: A4 (ANIM-01). Also: should the computer throw right-stick strikes at Medium and Hard (recommend yes, AI-06), and which marks on the fighters stay (recommend one clip of each, decided per mark, RENDER-13).

**Can wait until A5**
19. **Frame-rate targets:** recommend 60 on your PC, 30 held on the Deck with 40 as the aim. Holds up: A6's pass lines (X-23, X-24).
20. **Text and sound:** will you mark about 150 strings a tester meets; is a quiet background bed with building and menu sounds, and no music, right for Alpha; do the fighters stay silent or speak their approved lines? Recommend yes, yes, and silent unless lifted from the pool. Holds up: A5 (TEXT-01, AUDIO-02).
21. **Practice against the dummy as a ninth mode?** Recommend yes; it is placed in A5. Holds up: nothing if declined (1.2M returns).

**Can wait until A6**
22. **The freeze rule as written above; what "Beta in sight" means (recommend: four fighters playable on Windows and Linux and the Alpha testers' reports folded in); the Steam fee (recommend: not before then, and not before the title is cleared); code signing for Windows (recommend: not for Alpha, the guide explains the warning).** Holds up: nothing before the candidate.

## Self-check

Run against `03-gap-register.json` on 2026-11-13 by script: 270 rows; 174 required. 173 required rows sit in exactly one milestone (A1 64, A2 42, A3 22, A4 27, A5 14, A6 4) and 1 (PERF-02) is on the resize-or-move list with its reason; 0 required rows unplaced, 0 placed twice. 17 nice rows are placed, 57 are in the pool, 22 "after" rows are listed. 0 rows sit before a row named in their "needs" field. Of the 50 rows that change the state hash, 39 are placed in four windows (W1 11, W2 8, W3 18, W4 2), 6 are in the pool and 5 are after Alpha; A2 and A6 hold none. The 7 rows kept off Orb's page are planned like any other (6 placed, 1 in the pool) and no question above concerns them.
