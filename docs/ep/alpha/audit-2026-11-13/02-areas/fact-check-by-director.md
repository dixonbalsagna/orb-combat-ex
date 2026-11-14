# Phase 2 fact check: blockers and majors by owning director

Judgment session, 2026-11-13. From the 22 area files in this folder (`<CODE>.md`, with `<CODE>.findings.json` for the evidence and `<CODE>.verify-<n>.md` for the independent check). Severity is after verification. Each line is one sentence; the evidence is in the area file under the same id.

**For each director:** correct facts only. A correction changes a finding only if it comes with evidence (a `path:line`, a record, a commit, a CI run). Nothing here is a brief; point, don't fix.

Totals after verification: 35 blockers, 142 majors, 166 minors; 160 things recorded as working. No finding was refuted outright; 9 were downgraded and 47 corrected on a fact (the correction is in the verify file).

## tools-pipeline (9 blockers, 20 majors)

- **F-LEGAL-02** blocker, checked, cost M: No desktop package for an outside tester can be made today: the build workflow needs a recorded approval file that does not exist, the package text step reads a notice file still marked draft, and the workflow has never run.
- **F-MARKET-01** blocker, checked, cost M: Nothing for itch.io exists: no page set-up note, key procedure, channel names, upload script or rehearsal record (the same hole as TOOLS F-TOOLS-02, seen from the distribution side).
- **F-PERF-01** blocker, checked, cost M: No desktop build of the solo game as Orb plays it exists, and the one workflow that builds desktop programs has never run, would refuse today, and would build main's switched-off data without LAN play.
- **F-TOOLS-01** blocker, checked, cost L: No one command or CI run makes the Windows and Linux desktop builds of the game as the owner plays it: the only desktop workflow has never run, refuses today for want of its approval file, builds main's data unchanged, and refuses any package that carries the LAN code.
- **F-TOOLS-02** blocker, checked, cost M: No itch.io upload pipeline exists: nothing under tools/, .github/, net/ or docs/tools/ names itch.io or its upload tool, and there is no channel list, page set-up note or rehearsal record.
- **F-TOOLS-03** blocker, checked, cost S: No rollback procedure or release checklist exists, so nothing says how testers are returned to the previous build or which earlier build is the one to return to.
- **F-TOOLS-04** blocker, checked, a fact corrected, cost M: Nothing captures a crash or a hang: no game code writes a file when the game dies, the project sets no logging option, and match files are saved only on pause, match end and a pressed report.
- **F-TOOLS-05** blocker, checked, cost M: The one-press report folder works only on the owner's PC: its launcher is a Windows command file that runs Node against this PC's copy of the repository, so an outside tester or a Steam Deck cannot use it.
- **F-UI-02** blocker, checked, cost M: On main, and so in any plain desktop build, the one-press report and Save this match save nothing and say the build can't: the hook that writes the file is added only by the LAN kit to a patched scratch copy.
- **F-CODE-03** major, checked, cost M: Orb's solo build carries code that is not on main: the preview patches a scratch copy of the main scene to add the planet entry and a state probe, and main's own menu cannot name a generated planet.
- **F-CODE-04** major, checked, cost M: CI runs 116 of the 262 check and test scripts outside docs: none of the 45 input tests, none of the 14 audio checks, none of the 7 UI checks (the 11,033-line HUD check included), none of the animation or effects checks, and 5 of 43 director checks.
- **F-ENERGY-06** major, checked, cost S: The tool X-15 names does not measure X-15: the two-fighter ratchet counts four spellings of "exactly two fighters" and says nothing about fighter-specific code.
- **F-LEGAL-06** major, checked, a fact corrected, cost M: Legal asked that report files be checked for account names and file paths before a tester sends them, and no such check exists; the LAN folder's report script points at the owner's own project folder and needs Node.
- **F-LEGAL-08** major, checked, cost M (off Orb's page): The repairs to the flash measuring chain ordered on 2026-11-07 (CD-09) have no commit: the analyser file is unchanged, no flash reading runs on a schedule, the last nightly is from 2026-10-30 on an old commit, and the recorded release pass is for a commit of 2026-10-15.
- **F-MARKET-02** major, checked, cost S: There is no fixed shot list: the recipe file covers three of the six named shots and has no recipe for a transformation, a lap of the globe or a LAN 2v2 moment.
- **F-MARKET-03** major, checked, cost S: No job renders the shots at a milestone and no archive exists: clips land in a git-ignored folder with no milestone name, no line on what changed and no backup.
- **F-MARKET-04** major, checked, cost M: The capture hook exists only in a browser build, so the Alpha candidate's own Windows and Linux programs cannot be filmed, and a LAN 2v2 shot depends on a replay route whose self-test is in no workflow and which has not yet read a real LAN save.
- **F-MARKET-06** major, checked, cost S (off Orb's page): Only GIFs get the flash check; WebM video and PNG sequences leave the kit with no verdict, and no page says how a public video is screened.
- **F-MODES-09** major, checked, a fact corrected, cost M: No mode smoke suite exists: the one smoke check drives the browser build by clicking fixed screen points and failed once when the menu layout changed, and the desktop workflow only plays a computer-against-computer bench on Linux with no run on record.
- **F-NET-06** major, checked, cost S: The report folder from both PCs has never been made from a real LAN save, and its shortcut needs Node and this repository at a fixed path on the main PC plus a hand copy of the second PC's files.
- **F-PERF-10** major, checked, cost S: A build carries a commit and a date but no version number, the Windows program has no icon or version text, and no changelog exists.
- **F-QA-13** major, checked, a fact corrected, cost M: The way a report comes back is proven only on Orb's PC: the report-folder tool needs the repository's copy, and the in-game feedback panel opens from a pause menu Orb found missing on 6a30b4c9.
- **F-RENDER-17** major, checked, cost S: The globe ground that Orb plays on has no check in CI: the tile check's CI step is still parked, and the large effects and animation checks run only by hand.
- **F-SAVES-01** major, checked, cost S: A match played in the solo, couch or any other non-LAN desktop game saves no replay: the only recorder outside LAN is a patch the private browser page applies to a scratch copy of the host.
- **F-TOOLS-07** major, checked, cost S: A build carries a commit and a date but no version number, the Windows program's version fields are empty, no changelog file exists, and whether the game shows its build stamp on screen outside the report is not evidenced.
- **F-TOOLS-08** major, checked, a fact corrected, cost S: The Godot check job's time swings from about 35 to 62 minutes on unchanged game code against a 75-minute limit, and the network job has reached 86% of its 60 minutes, so a slow runner or a few new checks turns a clean commit red and blocks the deploy.
- **F-TOOLS-09** major, checked, cost S: The owner's builds, play files, reports and clips sit in one git-ignored folder of about 2.9 GB on one disk, with no backup plan written anywhere.
- **F-UI-08** major, checked, a fact corrected, cost M: The tool that makes a report folder is the owner's own Windows tool: it needs this repository and Node, writes a .cmd shortcut only and has no size cap, and nothing packs a tester's report on Linux or tells them where the file is.
- **F-UI-14** major, checked, cost S: No UI check runs in CI: the 8,288-check HUD suite, the text-size check and the overflow check are run by hand only, so a menu regression can reach a build unseen.

## ui-ux (3 blockers, 13 majors)

- **F-MODES-01** blocker, checked, cost M: The start menu has no list of modes: its rows are one or two players, each player's device, the computer's level, five comfort boxes and Start, so six of the eight Alpha modes have no menu entry.
- **F-MODES-06** blocker, checked, cost M: There is no fighter select: a match's fighters default to the first two ids of the roster file, so player one is always the Protagonist and player two always the rival.
- **F-UI-01** blocker, checked, cost S: With the Rail menus on (as in the build Orb played), the pause menu's slide-in is timed on a HUD clock that the game stops while paused, so by reading the code the rail and its detail card stay drawn off the screen: a pause with no visible menu (not reproduced; no run allowed).
- **F-ACCESS-01** major, checked, cost S: Settings and remapped controls are written to two files in the player's folder, but no test restarts the game on Windows or on a Steam Deck to show they survive, and a failed write is silently ignored.
- **F-ACCESS-02** major, checked, a fact corrected, cost S: The checks that plan every screen at 1280 by 800 exist but run in no CI job, and no saved record or set of stills shows the menus free of clipped or overlapping text at the Deck's size.
- **F-ENERGY-08** major, checked, a fact corrected, cost S: No record shows that a player can read their own health, energy or readiness from the fighter at speed; the only energy readout found is the corner plate.
- **F-MODES-13** major, checked, cost S: With a pad alone a player can go back to the menu but cannot close the game: the pause and match-over lists have no quit row, and the only quit is the keyboard's Escape, which closes the game at once with no question.
- **F-SAVES-04** major, checked, cost S: Settings surviving a restart has never been tested across a real restart on Windows or Linux: the only tests rebuild the screen inside one process and run in the local gate, not in CI.
- **F-TEXT-01** major, checked, a fact corrected, cost S: No record shows that Orb has seen the menu, how-to, hint, notice or settings text: the strings list made for Orb's marks holds 1115 strings and its Mark column is empty in every row.
- **F-UI-04** major, checked, a fact corrected, cost M: Making the Rail the default is unfinished: its switch is off on main, three older HUD checks fail with it on, Tools' smoke test clicked the wrong place on it, its checks leave out 1280 by 800, and only its Start screen has a saved still.
- **F-UI-05** major, checked, cost S: The Rail's match-over screen is a full-height panel over the left 30% of the screen, which is where player one's plate, portrait and spoken lines sit; no still of it is on file.
- **F-UI-06** major, checked, cost S: The start menu's d-pad behaves unevenly, as Orb reported: Up from the top row jumps to Start while Down from the bottom row stops, and Left or Right on the Players row swaps the row two below it between the computer's level and player two's device (by reading; not reproduced).
- **F-UI-07** major, checked, cost S: The feedback panel cannot be worked with a pad: a pad's only actions there are B or Start to close, so tags, Copy and Save need a mouse or a touch and the note needs a keyboard.
- **F-UI-11** major, checked, cost S: How to play's Reading the fight page describes things the minimal HUD no longer draws (a ring that flashes on a hurt body, finishing-move rings, the planet strip, a box at the top that counts damage), and nothing filters those lines out.
- **F-UI-12** major, checked, cost S: X-22 cannot be measured today: there is no still of any screen at 1280 by 800 and no tool that sweeps every screen at that size, only plan-level checks of the older layout.
- **F-UI-13** major, checked, cost S: X-20 has no test of its own: saving and loading are checked only inside one headless process, never across a restart or on Linux, a failed write is silent, and no page says where the two files live on each platform.

## world-environment (3 blockers, 10 majors)

- **F-MODES-07** blocker, checked, cost L: Custom planet setup does not exist: the menu has no planet row, and the planet generator takes a seed only, with no input for size, city count, climate or water.
- **F-WORLD-01** blocker, checked, cost M: On main the round planet is not the game's world: a match with no planet setup key plays the old hand-made arena, the menu never sets that key, and Orb's globe build gets it from a preview patch plus world data switches that main ships off.
- **F-WORLD-02** blocker, checked, cost L: Custom planet setup has nothing under it: the generator takes a seed only, the planet's size is a constant, and city count, climate and water are fixed numbers in data files, not match settings (same gap as F-MODES-07).
- **F-CAMERA-02** major, checked, cost M: The jolt that held terrain step 2 back has no written cause: the record shows only that the chase check fails 4 of 130 rows (0.137 to 0.153 against a 0.10 limit at the tick 96 split) with step 2 alone, where the same rows read 0.053 to 0.068 two builds earlier.
- **F-COMBAT-10** major, checked, cost M: A body that hits a building still bounces back; the settings that would hold it are one switch row held off waiting on a QA read.
- **F-MODES-12** major, checked, cost S: X-11's planet hash comparison is not a check yet: the planet fingerprint tool prints hashes with no verdict and is left out of the world checks, and every CI job runs on Linux only.
- **F-WORLD-03** major, checked, cost M: Terrain step 2 (no shafts, settling, the record list) is built and parked but not on main, held because Camera's chase check failed 4 of 130 rows with it applied; in the played build repeated hits on a planet spot are not held by the shaft cap.
- **F-WORLD-04** major, checked, cost S: Any ground dug below the shore line reads as sea at once, wherever it is, because the sea is derived from ground height with no source test; the fix (the flood switch) exists only in the held step 2 park and ships off there.
- **F-WORLD-06** major, checked, a fact corrected, cost S: X-14's three times the crater width at the top tier is not met for the same blow and no check asserts any ratio: an impact gains 25% energy a tier (1.32 times the width at tier 4), a shot 2.2 times the energy (1.48 times), and with the energy model on the tier term is gone.
- **F-WORLD-07** major, checked, a fact corrected, cost L: A skid trench on the planet is cut at one fixed half width of 32 units (about one body height across) at every power, so the mark a slide leaves does not grow with tier.
- **F-WORLD-08** major, checked, cost L: World sizes (tiny to colossal) exist only as a plan: the planet is 4,800 columns round by a constant, and what each size costs in frame rate has not been measured.
- **F-WORLD-09** major, checked, a fact corrected, cost S: The planet hash comparison X-11 asks for is not a check: the fingerprint tool prints lines with no verdict and is left out of CI, CI runs on Linux only, and no Windows-against-Linux comparison of a generated planet is on file (same gap as F-MODES-12).
- **F-WORLD-16** major, checked, a fact corrected, cost L: Repeated bounces off an outcrop and the ping-pong rebound off buildings, which Orb reported on three dates, are still open; the plan ties them to bodies feeling slope only along the fight's line and buildings always facing it square on (step 7).

## encounter-systems (3 blockers, 10 majors)

- **F-AI-01** blocker, checked, cost L: There is no computer control for many weak enemies: henchmen are paper only, the one-versus-many director (the ring) is parked and not on main, and a match holds five bodies at most with no waves or respawn.
- **F-COMBAT-01** blocker, checked, a fact corrected, cost L: Beam option A is not built: a beam is still an exchange that always reaches its target and is decided by a timed press, not by position.
- **F-COMBAT-02** blocker, checked, cost L: Signatures are not on Orb's inputs: RT + RB + flick and RT + flick do not exist, RT + B is the only input, and no martial signature exists for either fighter.
- **F-AI-05** major, checked, cost S: Main's computer-opponent data is not the played build's: Easy's pace matching, the beam pacing against a human, and the computer's hold-and-release beam are on in the build and off on main.
- **F-AI-06** major, checked, cost M: The computer never throws a right-stick strike, the main attack of Orb's scheme: the only right-stick input the computer writes is the beam's hold.
- **F-AI-07** major, checked, cost S: No standing check proves the computer uses only inputs a player has: on main its signature is still the old B request that locks its rival, the hold-and-release check is local only, and no record of it exists for the played build.
- **F-AI-08** major, checked, cost M: There is no computer ally: the only 2v2 line-up puts both computers on the enemy team, and no menu or host can start a match with a computer on a human's side.
- **F-COMBAT-06** major, checked, cost S: A released stick beam that cannot start waits up to 90 ticks and then fires into whatever the player is doing; open since Orb's last play.
- **F-COMBAT-13** major, checked, cost M: Chaining hits on a flying foe is only the tap chase; the LT chase, a chain window after a knock-back and a midair flurry are off or absent.
- **F-CONTROLS-04** major, checked, cost S: A right-stick beam that is refused at release waits and fires by itself up to 90 ticks later, and did so in the owner's last match 33 ticks after the stick was let go, during a brawl started with a face button.
- **F-CONTROLS-08** major, checked, cost M: The latest count of unanswered presses is from an older build: 225 of 760 presses not honoured (30 percent), 97 of them with no word or buzz, and no count exists for the build the owner last played.
- **F-MODES-08** major, checked, cost S: On main the rules that end a match as the last played build did (knockout only by a finishing move, wear for an idle player, the last event after the time cap) are switched off, and on only in the two kept builds.
- **F-QA-07** major, checked, a fact corrected, cost S: Easy is below the proposed band for Orb's scheme on the nearest record: 19 of 40 (47.5%) on the final-patches tree and 18 of 40 (45%) on 6eec6a75, against 60 to 80%.

## netcode-online (3 blockers, 8 majors)

- **F-MODES-04** blocker, checked, cost L: LAN play is not part of the game a tester would get: it is started by Windows shortcut files on a private program made by patching a scratch copy with the host PC's address baked in, and the desktop export presets leave the network code out.
- **F-MODES-05** blocker, checked, cost M: A LAN match cannot be rematched or left to a menu: the program plays one match and tells both players to close both windows.
- **F-PERF-03** blocker, checked, cost M: LAN play has no Linux build path: the LAN kit exports the Windows preset only, the Linux preset excludes the network code, and the launchers are Windows scripts.
- **F-MODES-11** major, checked, a fact corrected, cost M: Every LAN match is the same match: the seed, the planet and the fighters are constants in the LAN code, so nothing a player picks reaches a LAN game.
- **F-NET-01** major, checked, cost S: No LAN match on the played build (6a30b4c9) has a record from two real PCs: its only LAN records are nine rows with the second PC simulated inside one program, and the real two-PC logs kept are from two older builds.
- **F-NET-02** major, checked, cost L: An outside tester could not set up LAN without help: the folder is built on the hosting PC with that PC's address written into the shortcuts, needs an administrator firewall step, runs an unsigned Windows program, and its own words allow only Orb and Orb 2 to play.
- **F-NET-03** major, checked, cost M: There is no LAN build for Linux or the Steam Deck and no Windows-against-Linux match has ever been run, so cross-platform LAN at Alpha is unproven and today impossible.
- **F-NET-04** major, checked, cost S: A PC that falls silent is declared gone after 8 seconds, not the 5 seconds X-08 proposes, and no pulled-cable test on two real PCs is on record.
- **F-NET-05** major, checked, a fact corrected, cost S: Every LAN status except a dropped PC (waiting, could not connect, could not start, out of step, match over) is shown only in the window's title bar, and a detected state mismatch writes no report of its own.
- **F-NET-07** major, checked, a fact corrected, cost M: LAN play reaches the game only through text patches the kit makes to a scratch copy of two game files, and neither the kit nor the patched game's real window, menu and pads are run by CI.
- **F-WORLD-10** major, checked, cost M: Every LAN match is on the same planet: the LAN code fixes planet 7, touch-down 3 and generation 3 as constants, so a chosen planet cannot reach a second PC (same gap as F-MODES-11).

## rendering-techart (2 blockers, 16 majors)

- **F-MODES-03** blocker, checked, a fact corrected, cost L: Couch 2v2 cannot be started: the game's host only ever starts a two-body match, the input hub has two player slots, and the only code that asks the sim for two fights is the LAN program.
- **F-RENDER-01** blocker, checked, cost M (off Orb's page): On the globe (tile) ground that every build Orb plays uses, the last pixel flash reading failed in both normal and reduced modes, the standard clips never run with that ground, and no reading exists for 6a30b4c9.
- **F-MODES-10** major, checked, cost L: LAN 2v2 exists only as two humans, one on each PC, against two computer fighters, and each screen shows only its own fight; the owner reported never seeing all four fighters together.
- **F-PERF-06** major, checked, a fact corrected, cost M: The frame spikes Orb has felt since 2026-11-01 are still open: two causes were fixed on main but never re-measured, and the building sweep after a blow and the launch tick's slow loops are recorded as not tried.
- **F-PERF-09** major, checked, cost S: The game sets no window: there is no display section in the project file and no fullscreen, resolution, vertical-sync or frame-cap setting in code or in the options.
- **F-RENDER-02** major, checked, a fact corrected, cost M: The look Orb plays (globe ground, crater look, meteor trail, the swing camera that rides with it) is switched on only by launch words; on main the default is the older ground, so a plain export shows a different game.
- **F-RENDER-03** major, checked, cost M: Two look bugs from Orb's play of 6a30b4c9, fighters clipping into the ground and a row of three humps in a crater, have no still, no owner, no cause and no row in the bug list.
- **F-RENDER-04** major, checked, cost S: A thick black diagonal line across the whole picture, found when Tools replayed Orb's 'hump of ocean water' report, has stills but no cause and no owner, and the hump itself was not identified.
- **F-RENDER-05** major, checked, a fact corrected, cost M: The black, flat-brown crater has a still and a proven cause (a beam's scorch filled per vertex on coarse tiles), but the fix is on only by a launch word, is parked for main awaiting Orb's yes, and raises the collapse flash reading from 3 to 4.
- **F-RENDER-07** major, checked, cost S: The Settings screen offers 'Effects quality' (auto, high, medium, low) but no game code reads the choice, so changing it does nothing.
- **F-RENDER-08** major, checked, cost L: The quality range Orb asked for (performance to maximum) is a paper ladder and a research prototype: the game has no level picker, no Steam Deck default level, and an automatic step whose 42 frames-a-second threshold pins a 30 frames-a-second machine at low.
- **F-RENDER-12** major, checked, cost L: In a 2v2 the other fight is not drawn unless a launch word is passed, the LAN kit's 2v2 launchers do not pass it, and the park that makes it safe to pass is not on main.
- **F-RENDER-13** major, checked, a fact corrected, cost S: Nothing has been drawn on Linux or on a Steam Deck, so whether every shader runs on its driver is not evidenced; the reading of the code finds no feature the Compatibility renderer lacks.
- **F-RENDER-14** major, checked, a fact corrected, cost S: The boot warm-up's list does not name the clash, meteor trail or blast-head shaders, the park that warms every first draw in the real pane has waited since 2026-10-22, and no first-draw record exists for 6a30b4c9.
- **F-UI-03** major, checked, lowered from blocker, cost S (off Orb's page): Developer keys are live in every build with no switch, and three change flashing: F8 brings back the flash shapes from before Legal's conditions unless a lock flag that is off on main is on, Alt with a key fires any registered flash on demand, and F7 toggles the fighters' flashes.
- **F-UI-09** major, checked, cost S: Other developer keys reach a tester too: F2 swaps in the grey-box HUD with MENACE and ANGUISH bars, seed and tick text and a plain pause with no menu, F3 shows a performance overlay, F4 the debug feed and F6 turns effects off.
- **F-UI-10** major, checked, cost S: Two keyboard keys do something a tester won't expect: F9, which the game teaches as the report key, also switches the split screen on or off in the host, and Escape during play closes the desktop game at once with no question.
- **F-WORLD-05** major, checked, cost L: The ground drawn is not the ground stood on: the tile ground draws only the 16 nearest crater bowls, and the plan records that planet trenches and beam scars are not drawn at all, which fits Orb's reports of clipping, humps in a crater and a flat brown crater.

## qa-balance (2 blockers, 10 majors)

- **F-QA-01** blocker, checked, cost S: No tester checklist, tester guide or playtest protocol exists; the only tester-facing page is Legal's one-page note.
- **F-QA-02** blocker, checked, cost M: No soak test exists for the Godot game: nothing records crashes, hangs, script errors over hours or memory growth on Windows or Linux.
- **F-AI-03** major, checked, a fact corrected, cost S: Medium and Hard have no win-rate record for Orb's scheme on any build since 2026-11-01; the only figures on a design page are 0 wins at each level from 10 matches.
- **F-AI-04** major, checked, a fact corrected, cost S: No win rate has been measured on the played build's own packed data: every record was made on a scratch tree with patches laid on, by a Tools script that is not in QA's folder or in CI.
- **F-COMBAT-11** major, checked, cost M: No tool measures X-03, X-04, X-13 or X-16, and X-17's trace tool has no count.
- **F-QA-03** major, checked, cost S: The bug list holds 1 of the 52 problems Orb reported in play from 2026-11-01 to 2026-11-09, and its newest entry is dated 2026-10-03.
- **F-QA-05** major, checked, a fact corrected, cost M: Balance between the two fighters is not measured on the build Orb plays: the last full reading (48.9%, in band) is from 3198301f on 2026-10-14 with main's data, which differs from Orb's build on 72 of 92 switch rows.
- **F-QA-06** major, checked, a fact corrected, cost S: Solo difficulty is measured only at Easy for a scripted player using Orb's scheme; no win-rate record exists against Medium or Hard from 2026-11-01 on.
- **F-QA-09** major, checked, cost M: No Alpha match checklist probe exists: nothing reads a match's event feed and ticks off the pillars.
- **F-QA-11** major, checked, cost S: CI's QA job runs only the legacy prototype suite; the Godot QA batch, its scripted players and its self-test run in no workflow.
- **F-QA-12** major, checked, cost M: QA has no script or band for team play or the horde, though the balance page sets 45 to 55% for every 2v2 team.
- **F-SAVES-03** major, checked, cost S: No record on file shows a replay saved by the baseline build verifying to its last tick on that build, and the first real LAN save has not been put through the report tool.

## game-design (2 blockers, 8 majors)

- **F-ENERGY-01** blocker, checked, cost L: No stamina and no "body" number exist in any code or data, so the energy, stamina and health loop Orb defined for Alpha is a plan only.
- **F-MODES-02** blocker, checked, cost XL: The co-op horde mode does not exist: there is no horde design page, the henchmen page says it is paper only, and the sim's many-body match holds at most five bodies with no waves and no respawn.
- **F-AI-02** major, checked, cost S: Easy is too hard for a scripted player using Orb's scheme: it won 19 of 40 (47.5%) on the tree that became the played build, against Game Design's band of at least 70% and the criterion's proposed 60 to 80%.
- **F-CODE-06** major, checked, a fact corrected, cost L: The sim has no stamina at all, and the built energy model, forms, flight curve, hit-stop by weight, ricochet and cross mail are off on main and off in the build Orb played.
- **F-CODE-07** major, checked, a fact corrected, cost S: No single written page states the energy, stamina and health model: three design pages cover energy and wounds and none of them mentions stamina, which exists only in the proposals of 2026-11-13.
- **F-COMBAT-08** major, checked, cost L: Transformations are the shared three-tier ladder for both fighters: the Protagonist's own forms are switched off, the rival has none, and the only per-tier look is an aura with placeholder poses.
- **F-COMBAT-12** major, checked, a fact corrected, cost XL: Launches are not physics-based: the meteor is an authored curve and no attack has a force or any fighter a weight.
- **F-CONTROLS-07** major, checked, cost S: The flight speed the owner preferred (3500) exists only as a slider on the private browser page; the data's default is 5000, the energy model that reads it is off on main, and the LAN setup sends no flight speed.
- **F-ENERGY-02** major, checked, a fact corrected, cost S: No single written page states the model: it is spread over six design pages, the oldest still a proposal that disagrees with the code on the brink, and none covers stamina.
- **F-QA-08** major, checked, cost M: A right-stick-only pad loses almost every match in QA's latest reads: 0 of 60 against Medium on 2026-11-07 and 2 of 30 against Easy on the kept build of 2026-11-02.

## performance-platform (2 blockers, 4 majors)

- **F-PERF-02** blocker, checked, cost M: No Linux build has ever drawn a picture or run on a Steam Deck; the only Linux run on file is a headless one in a cloud container on 9631fc7.
- **F-PERF-04** blocker, checked, cost M: There is no one-click bench a Deck tester can run that saves a file: the existing kits are Windows batch and PowerShell, and the game's own bench prints to the console only.
- **F-PERF-05** major, checked, a fact corrected, cost S: Nothing about frame rate, loading or memory has been measured on the build Orb last played, and no windowed native frame record exists for any commit after d7647634 (2026-10-27).
- **F-PERF-07** major, checked, cost S: No loading time is on file for the desktop game with menus, the tile ground and generated planets; the last native figure predates all three and was already 15 s on a first start.
- **F-PERF-08** major, checked, cost S: Memory has never been measured on a desktop build, and growth over time is marked not measured, so the soak's 10% growth line has no baseline.
- **F-PERF-11** major, checked, a fact corrected, cost S: No tester guide or Deck checklist exists, and the only Deck words (one README line) point to an unpack-and-chmod route a newcomer without a keyboard is unlikely to finish.

## combat-choreography (2 blockers, 0 majors)

- **F-COMBAT-04** blocker, checked, a fact corrected, cost XL: The move table is incomplete for both fighters: RT + X, Y and A are the plain blow, several A and B cells have no outcome, and the LB, LT and RB rows are shared code with no per-fighter content.
- **F-CONTROLS-03** blocker, checked, cost L: Each fighter's move table has no outcome for 18 of 101 cells and 65 cells reach the same entry as another cell; the LB, LT and RT rows of the face buttons mostly repeat the no-stance row.

## simulation-engine (1 blockers, 7 majors)

- **F-COMBAT-03** blocker, checked, cost XL: No gravity well exists in code: no well, zones, draw, snap or intent read, only two pieces of the LT speed ruling behind switches.
- **F-CODE-02** major, checked, cost M: The golden record and five gates are valid only with the switches off, so the configuration Orb plays has no golden record and was verified by a pack read and a smoke run that only shows ticks advancing.
- **F-CODE-05** major, checked, cost L: Adding a third fighter needs code today: 365 places in shipped code name exactly two fighters, and per-fighter look tables sit in render and UI code keyed by fighter id.
- **F-ENERGY-03** major, checked, cost M: Energy's own numbers (start, cap, regain, charge rate, hit gain, guard drain and the older costs) are literals in code, shared by every fighter, not data.
- **F-ENERGY-04** major, checked, cost S: The "one energy model" is off in the data on main and in both played builds, and is on in Orb's build only through a code patch the page tool writes, so main does not describe the game Orb played.
- **F-ENERGY-05** major, checked, cost M: The backburnered hero and villain meters still change damage, energy regain, beam contests and where the computer leads the fight in every match, with no readout in the normal HUD.
- **F-NET-08** major, checked, a fact corrected, cost S: A replay carries a hash of its data, its format and its input version but no build id, so a replay from a build with the same data and different code is run and fails at a checkpoint instead of being refused with a plain message.
- **F-SAVES-02** major, checked, cost S: The replay itself names no build, so a replay from a build with the same data but different code is not refused up front and only fails later as a state mismatch.

## camera (1 blockers, 6 majors)

- **F-LEGAL-01** blocker, checked, cost L (off Orb's page): On the tile ground that the played build shows, main's beam-clash clip reads 6.5 flashes a second with Reduce flashing on and 5.5 with it off, against a limit of 3, and no pixel reading exists for the played commit 6a30b4c9.
- **F-CAMERA-01** major, checked, cost S: The camera Orb played (swing, peak launch shot, launch director, close brawl, readable size, 70/30 share, follow-through, flight reveal) switches on only when the game is started with the tile-ground word, and the share is 0.0 in main's data against 0.7 in both of Orb's builds, so a plain start from main gives a different camera.
- **F-CAMERA-03** major, checked, a fact corrected, cost S (off Orb's page): Two flash safeguards for the camera are parked and not on main: the scroll limit under reduced motion or reduced flashing equals the ordinary one (0.045), and no camera cut asks the flash register although the register has the call.
- **F-CAMERA-04** major, checked, a fact corrected, cost S: No camera test or saved record runs at the Steam Deck's 1280 by 800: every camera test fixes 1280 by 720, and UI's own paper says a plate crosses the 30% pane by 70 px at that size when the line leans most.
- **F-CAMERA-05** major, checked, cost M: No picture-in-picture for an ally exists: the only built inset is the slanted panel cut-in for the pair on screen, the damage inset is parked and absent from main, the wider four-fighter frame is parked and paused before its look gate, and Camera's own page argues against an ally window.
- **F-CAMERA-06** major, checked, a fact corrected, cost M: The rig has no input naming this PC's player: the large pane goes to the one fighter of slots 0 and 1 with no computer driver, so the picture each PC shows in a LAN 1v1 is not evidenced by any saved record, and in LAN 2v2 each PC shows only its own fight until its player is out.
- **F-CAMERA-07** major, checked, cost S: Only one of 26 camera test files runs in CI; the big sweep and the check that fails a cut with no written reason run by hand, and the last gate record names the sweep but not the cut-reason check.

## ep (1 blockers, 6 majors)

- **F-CODE-01** blocker, checked, cost L: Main does not hold the game Orb plays: at least 72 of the 92 switch rows differ between main and Orb's solo build, so a fresh clone, CI and the desktop workflow all build a different, mostly switched-off game.
- **F-COMBAT-05** major, checked, cost M: Most of the combat Orb played is off in main's data and on only through the build page's switch rows, so no committed data set is the Alpha's combat.
- **F-PROCESS-02** major, checked, cost S: There is no single backlog: open work sits in the corrective plan, the EP's messages and per-machine memory notes, parked folders, a git-ignored homework folder and Legal's re-homing index.
- **F-PROCESS-03** major, checked, cost M: The working tree carries 14,805 uncommitted paths (75 modified, 27 deleted, 14,703 untracked), including run records and parked work, so the repository at a commit is not the project.
- **F-PROCESS-06** major, checked, cost S: The P0 to P5 roadmap in CLAUDE.md no longer describes the project: no phase gate result is on record, P3 and P4 name systems Orb put on the backburner, and the activation schedule keyed to those phases does not match who works.
- **F-PROCESS-09** major, checked, cost S: The corrective plan of 2026-11-07 has not been kept: 13 of 27 rows have no closing entry, 8 items have neither a commit nor a record, and two wave-1 items due before 2026-11-15 are not closed.
- **F-RENDER-10** major, checked, a fact corrected, cost S: No record ties a visible landing to its side-by-side: landings arrive as batches, the gate records of the last five builds name no side-by-side, and 214 of the 229 files in the look-gate picture folder are uncommitted.

## controls-feel (1 blockers, 6 majors)

- **F-CONTROLS-01** blocker, checked, cost M: The owner's two signature inputs (RT + RB + a right-stick flick, RT + a right-stick flick) cannot be pressed: with RT held the right stick is switched off in the input layer, and the only signature input is RT + B.
- **F-COMBAT-09** major, checked, cost S: In Orb's last full match the player's fighter never left tier 1 while the computer reached tier 3; the transform chord has no hint.
- **F-CONTROLS-02** major, checked, lowered from blocker, cost M: Couch 2v2 with four pads cannot be played: the input hub holds two human slots per PC and every pad routine loops over two.
- **F-CONTROLS-05** major, checked, cost M: The pad as the owner plays it is not the default in data: eleven input switches are off on main and on in both played builds only through the private page's switch table.
- **F-CONTROLS-06** major, checked, a fact corrected, cost S: A pad unplugged mid-match does not pause or show a notice: player two's fighter is handed to the computer and player one is moved to the keyboard while the match runs on.
- **F-CONTROLS-09** major, checked, a fact corrected, cost M: No moveset coverage probe exists: the nearest tool presses each input alone for 90 ticks and its saved result is from a tree of 1 November.
- **F-CONTROLS-10** major, checked, cost S: The Steam Deck's built-in controls have never been tried: no run on a Deck or through Steam's pad layer is on record, and the project's own Deck page marks it untested.

## legal-ip (0 blockers, 6 majors)

- **F-LEGAL-03** major, checked, lowered from blocker, cost S: The list of gates that must be green before an outside tester plays did not exist before this audit, and several of its gates have no saved record or no tool.
- **F-LEGAL-04** major, checked, cost M: No ruling or package covers an outside tester playing the LAN modes: the locked package refuses any network code, and the LAN folder's terms name only the owner and the trusted second player.
- **F-LEGAL-05** major, checked, cost S: The tester note is a draft for the owner to send, its review row is still open on two conditions, and nothing records how a tester confirms being an adult or agrees to the terms.
- **F-LEGAL-09** major, checked, cost S: Whether a restricted, key-only itch.io page may go up before the title search is not confirmed anywhere: Legal's own page and the audit directive both say the search comes before any itch.io page, and the plan row is empty.
- **F-MARKET-08** major, checked, cost S: Legal's own page puts the formal title search before any itch.io page, the title row is still open, and nothing excuses a key-only page (the same point as LEGAL F-LEGAL-09).
- **F-TOOLS-06** major, checked, cost S: The desktop package rules were written for private test builds and conflict with an Alpha on itch.io: files are kept one day, the run is deleted after hand-over, no link or mention is allowed, the approval must be under 30 days old, and network play must be absent.

## audio-music (0 blockers, 4 majors)

- **F-AUDIO-01** major, checked, cost S: On main five sound sets are off, so a build made plainly from main has no beam, knock-out, launch, struggle or transformation sound; Orb's build has three of them on only through build switches.
- **F-AUDIO-02** major, checked, cost M: No sound exists for a building being damaged or collapsing, bystanders scattering, the gravity well, or any menu action, and the fight has no ambience or music bed in any build.
- **F-AUDIO-03** major, checked, a fact corrected, cost S: Nothing in the area is proved by ear: Audio's pages say nobody has listened, and Orb's latest word (2026-11-09) is that the crackles sounded bad, with no record of whether that was the fixed build.
- **F-AUDIO-04** major, checked, a fact corrected, cost S: Sound on the Alpha's platforms (a Windows desktop build, Linux, the Steam Deck) is not evidenced: every proof is the browser build in Chrome, the only audio project setting is web-only, and no CI job runs an audio check.

## production-ops (0 blockers, 3 majors)

- **F-PROCESS-01** major, checked, cost S: No written change-control rule for the feature freeze and no ideas log exist, and the EP's playbook points to neither.
- **F-PROCESS-04** major, checked, a fact corrected, cost S: The risk register is the starting set of 2026-09-28, never updated, and lists none of the risks that have since happened.
- **F-PROCESS-05** major, checked, cost S: There is no milestone tracker or live roadmap, and the Production Operations director who owns them has no commit in the project's history.

## art (0 blockers, 2 majors)

- **F-ANIM-01** major, checked, cost M: A transformation changes only the aura: both fighters play the same three placeholder poses for every form and no body look is keyed to a form.
- **F-ANIM-02** major, checked, cost S: In a 2v2 the two copies of each fighter are drawn identically, and the mirror match is held off for the same missing second colour.

## orb (0 blockers, 1 majors)

- **F-LEGAL-07** major, checked, cost S: The report channel is undecided: the owner's words were to convert an existing server, Legal's first flag says not to, and no record settles the three items Legal wants settled before the first tester.

## accessibility-localization (0 blockers, 1 majors)

- **F-ACCESS-03** major, checked, cost S: There is no accessibility pass or record newer than 2026-10-31 and no runs folder for the area, so the accessibility items of the 'before an outside tester plays' list do not exist as a list.

## community-marketing (0 blockers, 1 majors)

- **F-MARKET-07** major, checked, a fact corrected, cost S: No tester guide says how a tester gets a key, installs on a Steam Deck, updates, or posts a report; the only tester page is Legal's note, which does not mention itch.io.
