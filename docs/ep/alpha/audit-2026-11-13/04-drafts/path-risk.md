# Path to Alpha, draft: risk first

Planner draft for the judgment session, 2026-11-13. Baseline 8901d351. Source: `03-gap-register.json` (270 rows; 174 required, 74 nice, 22 after). One of three drafts written from different angles; this one has not seen the others.

## The angle, and the pace assumed

**Risk first.** The order here is set by what is least known, not by what is quickest to finish. Six things could each turn out much bigger than their size class, or show that the Alpha as defined cannot be reached: the first real Steam Deck run; a desktop build of the game Orb actually plays (today that game exists only as a browser build made by patching a copy of main); the beam rework (a beam that travels through space and misses if you move off its line); the horde mode; the gravity well (the pull that draws two fighters into a close fight); and the move table. Every one of them is either built or sized by a throwaway trial ("spike") in A1 or A2, before the team commits weeks to anything that depends on it. The cost is that the early milestones are heavy and unglamorous, and the first build with new things to press arrives at A3. The gain is that by the end of A2 the path's length is known from evidence instead of from size classes.

**Pace, in one line:** I assume about 35M tokens of finished director work a week (range 25M to 50M), which is roughly 60 to 80% of the weekly allowance with directors mostly on the cheaper models (about 1 meter point per 1M tokens, 1.6 on the largest model) and about a third of each week spent by the Executive Producer on briefs, reviews, gate runs and rework. The record behind this is thin: no clean weekly figures exist, one night planned at about 10% was about 13M tokens briefed, and the week that ended 2026-11-13 reached about 82%. Weeks are therefore given as ranges, and row A-PROCESS-08 (start a weekly token record) is in A1 so the ranges can be tightened after two weeks.

**Token budgets are size classes, not quotes:** S about 0.25M, M about 1.2M, L about 4M, XL about 8M. Almost no row has a comparable piece of finished work behind its class.

**People's time is counted too.** Orb plays every milestone's build (allow two to four days for the play and for the reports to be read and sorted). Friends with Steam Decks test twice: one friend for 30 minutes at A2, two friends on the candidate at A6. Each of those waits on a person's free evening, so each can add up to a week.

**Working ahead.** A milestone is defined by what closes in it. Directors with nothing to close in the current milestone start the next one's work behind a switch (finished work waiting outside main is called a "park" in this project) so that no session sits idle. Where that matters it is said below.

**Totals:** about 187M tokens at the register's size classes (rows 177.6M, spikes 4.5M, the candidate's verification runs 5M); about 168M if Orb accepts the resizes proposed below; plan on 25% on top for rework. **8 to 14 weeks**, which puts the Alpha candidate between mid-January and late February 2027.

| Milestone | What it proves | Rows | Tokens | Weeks | Golden window |
| --- | --- | ---: | ---: | --- | --- |
| A1 | Main is the game Orb plays, and it builds for the desktop | 72 | 43.3M | 1.5 to 2.5 | GW1 "Main is the game" |
| A2 | Safe to hand out; a real Steam Deck has run it | 41 | 24.5M | 1 to 2.5 | none |
| A3 | The fight's new rules; a menu that reaches every built mode; LAN inside the game | 30 | 52.0M | 2 to 3 | GW2 "The fight's rules" |
| A4 | Horde, teams, your own planet, the whole fighter | 20 | 48.7M | 2 to 3 | GW3 "Many bodies and the full fighter" |
| A5 | A newcomer on a Deck, alone | 14 | 12.0M | 1 | none |
| A6 | The Alpha candidate | 3 | 6.7M | 1.5 to 3 | GW4 "Numbers only" |

A "golden window" is a landing that changes the sim's state fingerprint: the saved reference matches ("golden records") are re-recorded and replays from earlier builds stop verifying. All 35 required rows that change the fingerprint sit in four windows; A2 and A5 have none, so a replay saved on the A1 build still plays on A2's, and A4's on A5's.

---

## A1. Main is the game Orb plays

**Goal.** A fresh copy of the repository, with one command, makes the Windows and Linux desktop builds of the game Orb played on 9 November, and the four biggest unknowns in the fight have each been tried small.

**Why first.** 72 of the 92 switch rows differ between main and the build Orb plays, and 14,805 paths are uncommitted. Until this closes, every test, every gate and every measurement describes a different game from the one being judged. Nothing later can be trusted, so nothing later starts landing.

**What Orb can play.** The first desktop build of their own game: a Windows program (no browser, no shortcut with special words) that opens on the menus with the panel down the left (the "Rail" menus Orb picked), on the round planet, with the pad as Orb plays it and flight at 3500.

**PLAY THIS would say.** New: this is the same game as your 9 November build, but made from main by one command, as a Windows program. Pause now opens its menu. The start menu's d-pad moves evenly. A stick beam you let go of no longer fires later on its own, and RT + B only counts just after RT. Try: play one full match and say whether anything is different from 9 November, because nothing is meant to be. Press the report button at the end and check a file appears. Then look at the four short trial clips (a beam you can sidestep, the pull into a close fight, six weak enemies at once, the map of which button presses do nothing) and answer the question under each.

**Spikes (trials on a scratch copy; nothing lands; 4.5M in total).**
- S1, beam: one beam that leaves the fighter, travels at a speed and misses a defender who steps off its line, run through the X-16 probe at three ranges. Says whether A-COMBAT-01 is an L, and what breaks in the beam struggle and in the computer's beam play.
- S2, gravity well: size, zones and the snap as a toy on the scratch copy, to see whether A-COMBAT-03 at "size, zones and the snap" is an XL or an L, and to put the "does your stick move only you up close" question to Orb with something to look at.
- S3, horde: does the parked one-against-many work still apply (A-AI-13); what six, eight and twelve weak bodies cost in frame time; does respawn fit the sim's five-body limit. Says whether A-MODES-02 and A-AI-01 are 12M or 20M.
- S4, move table: run the coverage count on the played build's own data, so the 18 dead cells and 65 repeats are confirmed on today's game, and Combat prices the smaller and the full table.
- S5, Linux picture: a CI job starts the Linux build under a virtual display and saves one still. This is the cheapest possible answer to "has a Linux build ever drawn a picture", weeks before a friend's Deck is involved.

**Exit criteria.**
- X-29 (must pass): one command and one CI run make the Windows and Linux builds from a commit, the solo game included; the build shows a version number; a changelog entry is written.
- X-17 (must pass on Orb's saved play files and the scripted set): beams started by any input other than the right stick or RT + B: 0. (The signature inputs change in A3.)
- X-27 (first held here): a replay carries its build id; a replay from another build is refused with a plain message.
- A golden record exists for the configuration Orb plays, and the gates run with the switches as shipped (A-CODE-02). The 92-row switch table is reduced to rows that still describe a choice.
- X-23 and X-26, first readings only: a frame record and loading times for the desktop build on Orb's PC. X-06, first readings: win rates at Easy, Medium and Hard for a scripted player on Orb's scheme, on the build's own packed data, with enough matches to tell bands apart.
- X-33 (must pass): the change-control rule and the ideas log exist and the playbook points to them. One backlog; the working tree is committed or deliberately ignored.
- The measuring tools for X-03, X-04, X-13 and X-16 exist and have each produced a first (failing) reading. The 1280 by 800 screen sweep exists and has produced stills of every menu.
- Spikes S1 to S5 each end in one page: what was tried, what it cost, the size class now believed, and the question for Orb if there is one.

**Gap ids closed, by owner.**
- **audio-music:** A-AUDIO-01
- **camera:** A-CAMERA-01
- **combat-choreography:** A-COMBAT-14
- **controls-feel:** A-CONTROLS-02
- **encounter-systems:** A-AI-05, A-AI-10, A-AI-13 (nice), A-COMBAT-05, A-COMBAT-11, A-MODES-07
- **ep:** A-ANIM-06, A-CODE-01, A-PROCESS-02, A-PROCESS-03, A-PROCESS-06, A-PROCESS-07, A-PROCESS-08, A-PROCESS-09, A-PROCESS-10, A-PROCESS-11, A-PROCESS-13, A-PROCESS-14, A-PROCESS-15, A-PROCESS-16, A-RENDER-07, A-RENDER-11
- **game-design:** A-COMBAT-15, A-CONTROLS-04, A-ENERGY-02
- **legal-ip:** A-LEGAL-09
- **orb:** A-LEGAL-10, A-WORLD-14
- **performance-platform:** A-PERF-04, A-PERF-06, A-PERF-07
- **production-ops:** A-PROCESS-01, A-PROCESS-04, A-PROCESS-05
- **qa-balance:** A-AI-03, A-AI-04, A-AI-11, A-COMBAT-08, A-QA-03, A-QA-04, A-QA-07, A-QA-09, A-SAVES-01
- **rendering-techart:** A-PERF-08, A-RENDER-01, A-RENDER-04
- **simulation-engine:** A-CODE-02, A-ENERGY-04, A-ENERGY-05, A-NET-05
- **tools-pipeline:** A-CODE-03, A-CODE-04, A-ENERGY-06, A-LEGAL-02, A-TOOLS-01, A-TOOLS-07, A-TOOLS-08, A-TOOLS-09, A-TOOLS-10, A-TOOLS-13 (nice), A-TOOLS-15, A-UI-02
- **ui-ux:** A-MODES-15, A-UI-01, A-UI-04, A-UI-06, A-UI-09
- **world-environment:** A-WORLD-01

**Golden window GW1, "Main is the game".** The defaults Orb plays become main's data (A-CODE-01 and the rows it needs), with the small input fixes and the backburnered meters set to zero riding in the same window: A-AI-05, A-AI-10, A-CODE-01, A-COMBAT-05, A-COMBAT-11, A-COMBAT-14, A-CONTROLS-02, A-CONTROLS-04, A-ENERGY-04, A-ENERGY-05, A-MODES-07, A-WORLD-01. A-NET-05 (the build id in a replay) lands before the window, so every replay made from here on is refused plainly by a later build instead of failing halfway.

**Tokens.** 43.3M (rows 38.8M: 2 L, 14 M, 56 S; spikes 4.5M). **Weeks.** 1.5 to 2.5.

**Directors active.** Tools & Pipeline, Simulation & Engine, Encounter Systems, World & Environment, Rendering, Camera, Controls & Game Feel, UI & UX, Audio, Game Design, Combat & Choreography (S4), QA & Balance, Performance & Platform, Netcode (the replay's build id), Legal (three rulings), Production Operations, and the Executive Producer (who carries most of the small process rows). Started early for A2: Camera, Rendering and VFX on the flashing measurements; Legal on the tester note.

---

## A2. Safe to hand out; a real Steam Deck has run it

**Goal.** Every gate on the "before an outside tester plays" list is green on a commit, and one friend has installed that build on a Steam Deck, played 30 minutes with the Deck's own controls, run the one-press bench and sent back two files.

**Why second.** The Deck is the single largest unknown that the team cannot study on its own: no Linux build has drawn a picture on real hardware, no shader has met the Deck's driver, and the frame rate is a guess. It is also the one test that needs a person outside the trusted two, so it cannot happen before the safety gates. Doing both now means that if the Deck needs a different picture quality, a different renderer setting or a lower target, that is learned with four milestones left instead of one.

**What Orb can play.** The same game as A1 (no rule changes, so A1 replays still play), now as the package a tester would get: the notice before play, the AI disclosure on the first screen, a quit row reachable by pad, a report that saves from the pad on any PC, and a crash file if the game dies. Orb also does the ten-minute listening pass on this build.

**PLAY THIS would say.** New: nothing in the fight. Everything around it: you can quit with the pad; the report panel works with the pad and saves one small file anywhere, not only on your PC; if the game crashes it leaves a file saying why; unplug a pad mid-match and the game pauses and says so. Try: install it on the old PC from the itch.io test page using only the draft guide; pull a pad out mid-match; force a crash from the hidden test row and send the report; listen for ten minutes and mark what sounds wrong. Your friend with the Deck gets a one-page sheet: install, play two matches, press the bench, post two files.

**Exit criteria.**
- X-02 (must pass): the list of gates exists and each has a saved record under `docs/*/runs/<sha>/` for this commit, including the measurements on the globe ground that every played build uses.
- X-28 (must pass): a forced crash on Windows and on Linux leaves a file, and the report folder picks it up.
- X-21 (must pass on Windows and Linux; on the Deck by the friend's file): one press saves a report under 10 MB with nothing sent automatically; the file has been checked for account names and file paths; the code read finds nothing that sends data.
- X-18 and X-19, first real reading: the friend's sheet comes back saying how long install took and where they got stuck. Not a pass yet; the guide is a draft.
- X-24 and X-26, first real reading: a frame record and loading times from a real Deck, made by the one-press bench. This number decides whether "30 held, 40 as the aim" stands.
- X-30 and X-31 (must pass as a rehearsal): a dummy build is pushed to a restricted itch.io page on a Windows and a Linux channel, a key is claimed, an update is applied, and the previous version is restored in one step.
- X-25, first reading: a two-hour soak on Windows and on Linux in CI, with memory growth recorded.
- X-07 (must pass): a pad unplugged mid-match pauses with a plain notice. X-20 (must pass on Windows and Linux): settings survive a real restart.
- X-34, started: the shot list is one data file; the render job has produced the first archive entry from the A1 and A2 builds.
- The three unexplained picture faults (fighters sinking into the ground, three humps in a crater, the black diagonal line) each have a still, a cause and an owner, or a written "cannot reproduce" with the replay used.

**Gap ids closed, by owner.**
- **accessibility-localization:** A-ACCESS-01
- **audio-music:** A-AUDIO-03, A-AUDIO-04
- **camera:** A-CAMERA-02, A-CAMERA-03, A-LEGAL-01
- **controls-feel:** A-CONTROLS-03, A-CONTROLS-07
- **ep:** A-ACCESS-04
- **legal-ip:** A-LEGAL-03, A-LEGAL-05, A-LEGAL-12, A-TOOLS-06
- **orb:** A-LEGAL-07
- **performance-platform:** A-CONTROLS-08, A-PERF-01, A-PERF-03
- **qa-balance:** A-QA-02, A-QA-11
- **rendering-techart:** A-PERF-05, A-RENDER-02, A-RENDER-03, A-RENDER-08, A-UI-03
- **tools-pipeline:** A-LEGAL-06, A-LEGAL-08, A-MARKET-01, A-MARKET-02, A-MARKET-03, A-MARKET-04, A-MARKET-07, A-TOOLS-02, A-TOOLS-03, A-TOOLS-04, A-TOOLS-05
- **ui-ux:** A-ACCESS-02, A-LEGAL-13 (nice), A-MODES-11, A-SAVES-02, A-UI-07, A-UI-10

**Golden window.** None.

**Tokens.** 24.5M (1 L, 11 M, 29 S). **Weeks.** 1 to 2.5; the top of the range is the wait for Orb's account actions and for the friend's evening.

**Directors active.** Camera, Rendering and VFX (the measurements on the globe ground), Legal, Accessibility & Localization, Tools & Pipeline, Performance & Platform, UI & UX, Controls & Game Feel, Audio, QA & Balance, Community & Marketing (the shot list with Tools). Working ahead for A3, behind switches: Encounter Systems (the beam and the signature inputs, from S1), Simulation & Engine (the gravity well's first cut, from S2), Game Design (the stamina, energy and body numbers), Netcode (LAN inside the game).

**Orb's actions in this milestone.** Create the itch.io account and restricted page and install its upload tool, in one sitting with Tools' checklist open. Set up the private report server. Ask one friend with a Deck. Record one line approving desktop test builds for named testers once the gates are green.

---

## A3. The fight's new rules, and LAN inside the game

**Goal.** In one normal match a player aims a beam with the stick and the other dodges it by moving off its line, both signatures fire from Orb's inputs, stamina, energy and body work as one loop, the pull into a close fight exists, and a second PC joins from a Host or Join row instead of a folder of shortcuts.

**Why third.** These are the blockers with the widest reach: the move table needs the signature inputs and the energy loop; transformations need the energy loop; the computer's play, the balance bands and every later measurement sit on these rules. They share one golden window so the fingerprints move once. They are attacked here, not later, because if the beam rework or the gravity well is twice its class, the Alpha's date moves, and it is better to know in week 5 than in week 10.

**What Orb can play.** The first build with new things to press. Solo and two players on one PC from a real mode list with a fighter pick; LAN 1v1 with Orb 2 started from the menu, with rematch and "back to menu".

**PLAY THIS would say.** New: hold the right stick to aim a beam; it now flies through space and you can get out of its way by moving. RT + RB + a flick of the right stick is the energy signature; RT + a flick is the martial one. There is a stamina number: plain face-button blows refill it, specials and signatures spend it, and low stamina makes injuries worse. Up close, the two fighters are drawn together. The start menu lists the modes, and you pick your fighter. On two PCs, one presses Host, the other Join. Try: dodge three beams by flying off the line at near, middle and far range; throw both signatures; fight with stamina empty and see what a hit does; get a transformation (the game now tells you the buttons); knock someone into a building and see whether they still bounce back like a ping-pong ball; play three LAN matches in a row without closing the game, then pull the network cable.

**Exit criteria.**
- X-16 (must pass): a scripted defender's sidestep makes the beam miss at three ranges.
- X-17 (must pass): beams and signatures from any input other than Orb's: 0, for the player and for the computer.
- X-15 (must pass, in the resized form below): one page states the model; every energy, stamina and body number is data per fighter; the corrected ratchet finds no fighter-specific code in those systems; no health bar; a still set shows health, energy and readiness can be read from the fighter at speed.
- X-13, partial (must pass for: a lap, each stance, a beam aimed and dodged, both signatures, a launch, the gravity well's pull, a crater, a building damaged, bystanders scattering). The transformation line is first required at A4.
- X-14, first reading with the new check: the crater-width ratio between the top and base tier, and the skid trench growing with tier. Must pass at A4.
- X-08 for LAN 1v1 (must pass, two Windows PCs, Orb and Orb 2): five full matches with no state mismatch, rematch and leave work, a pulled cable shows a plain notice on both PCs inside the agreed time, and every status is on screen and not in the window's title.
- X-05, partial: the mode smoke suite exists and passes for solo, two on one PC and LAN 1v1 on Windows, and for solo and two on one PC on Linux.
- X-03, reading only: the count of unanswered presses on this build, down from 30%.
- The gates on A2's list are re-run on this commit, because the new beam changes what is on screen.

**Gap ids closed, by owner.**
- **camera:** A-CAMERA-05
- **controls-feel:** A-COMBAT-07
- **encounter-systems:** A-AI-07, A-COMBAT-01, A-COMBAT-02, A-CONTROLS-05
- **game-design:** A-ENERGY-01
- **legal-ip:** A-LEGAL-04
- **netcode-online:** A-MODES-04, A-MODES-05, A-MODES-10, A-NET-01, A-NET-02, A-NET-03, A-NET-04, A-PERF-02
- **simulation-engine:** A-COMBAT-03, A-ENERGY-03, A-ENERGY-10
- **tools-pipeline:** A-MODES-08
- **ui-ux:** A-ENERGY-07, A-ENERGY-08, A-MODES-01, A-MODES-06
- **vfx:** A-RENDER-13
- **world-environment:** A-WORLD-03, A-WORLD-04, A-WORLD-06, A-WORLD-07, A-WORLD-10

**Golden window GW2, "The fight's rules".** A-COMBAT-01, A-COMBAT-02, A-COMBAT-03, A-CONTROLS-05, A-ENERGY-01, A-ENERGY-03, A-ENERGY-10, A-WORLD-03, A-WORLD-04, A-WORLD-07, A-WORLD-10. The terrain rows ride in this window because World and Rendering are free while the fight teams work, and one re-recording covers both.

**Tokens.** 52.0M (1 XL, 7 L, 11 M, 11 S). **Weeks.** 2 to 3. This is the milestone most likely to overrun; see the stop rule under the risks.

**Directors active.** Encounter Systems, Simulation & Engine, Game Design, Controls & Game Feel, World & Environment, Rendering, Camera, VFX, UI & UX, Netcode, Tools & Pipeline (the mode smoke suite), QA & Balance, Legal (the LAN ruling), Performance & Platform. Working ahead for A4: Combat & Choreography on the move table from the day the signature inputs are fixed; Game Design on the horde page from S3.

---

## A4. Horde, teams, your own planet, the whole fighter

**Goal.** All eight modes less the campaign can be started from the menu with a pad, played to a result, rematched and left; each fighter has a complete move table at the Alpha's bar and two forms beyond base.

**What Orb can play.** Horde for one or two players; couch 2v2 (two people as a team against two computer fighters) and 2v2 alone with a computer partner; LAN 2v2 where all four fighters are seen together when the fights are near; a planet set up from a seed and three dials; every button row doing its own thing.

**PLAY THIS would say.** New: a Horde mode, where weak enemies arrive in waves and come back, for one or two players, ending in a result screen. A computer partner, so you can play 2v2 alone. Custom planet: pick a seed, how many cities, the climate and how much water. Each fighter now changes body as well as aura when transforming, twice. Holding LB, RB, RT or LT with a face button now gives a different move from the plain press. Try: last eight minutes in Horde alone, then with a second pad; make a dry planet with one city and check the second PC gets the same planet; with each fighter press every held button with X, Y, B and A (tap, mash, hold) and write down any that feel the same or do nothing; reach both forms with both fighters.

**Exit criteria.**
- X-05 (must pass on Windows and Linux): the smoke suite starts, finishes, rematches and leaves every mode Alpha ships (LAN modes on Windows; on Linux by the two-program check in CI).
- X-10 (must pass on Orb's PC): a horde run of 5 to 10 minutes with waves, respawn and a result screen; the frame record at the largest wave holds 60. The Deck's reading of the same wave is asked for by bench file and judged at A6.
- X-09 (must pass): the supported line-ups are written down and each one is played from the menu.
- X-08 for LAN 2v2 (must pass): five full matches, both forms of 2v2, on two real PCs.
- X-04 (must pass): a scripted match reaches each form for each fighter; one still per form; a blow in flight when a transformation starts is handled the written way.
- X-03 (must pass at the Alpha's bar; see the resize): the pad-driven coverage probe finds no cell without an outcome, and no duplicate inside the rows the bar names.
- X-13 (must pass in full, on scripted matches).
- X-14 (must pass). X-11, the dials: the same seed and choices give the same planet on both LAN PCs; the Windows-against-Linux comparison is first required at A5, once its check has run in CI.
- X-15, the third-fighter line (must pass in the resized form): the count of places in the code that name exactly two fighters is recorded, cannot rise, and is zero in the energy, stamina, body and forms systems.

**Gap ids closed, by owner.**
- **animation:** A-ANIM-03
- **art:** A-ANIM-01, A-ANIM-02
- **combat-choreography:** A-COMBAT-04
- **controls-feel:** A-CONTROLS-01, A-CONTROLS-06
- **encounter-systems:** A-AI-01, A-AI-06 (nice), A-AI-08, A-AI-09
- **game-design:** A-COMBAT-06, A-MODES-02
- **netcode-online:** A-NET-06
- **qa-balance:** A-QA-06
- **rendering-techart:** A-MODES-03, A-MODES-09
- **simulation-engine:** A-CODE-05, A-COMBAT-12
- **world-environment:** A-WORLD-02, A-WORLD-09

**Golden window GW3, "Many bodies and the full fighter".** A-AI-01, A-AI-06 (nice), A-AI-08, A-AI-09, A-CODE-05, A-COMBAT-04, A-COMBAT-06, A-COMBAT-12, A-MODES-02, A-WORLD-02.

**Tokens.** 48.7M (2 XL, 6 L, 6 M, 6 S); about 38M with the resizes below. **Weeks.** 2 to 3.

**Directors active.** Game Design, Encounter Systems, Combat & Choreography, Simulation & Engine, Rendering, Camera, World & Environment, Controls & Game Feel, Art, Animation, Netcode, UI & UX, QA & Balance, Tools & Pipeline.

---

## A5. A newcomer on a Deck, alone

**Goal.** Someone who has never seen the game installs it from the itch.io page with a key, reads the notice, picks a mode, a fighter and a planet, plays, rematches, changes a setting that is still there next time, and sends a report, with only the tester guide and the Deck's own controls.

**Why here and not earlier.** The risky halves of the newcomer's path (does it install, does it run, can a pad work every screen, does the report leave the machine) were proven at A2. What is left is words, stills and one picture-quality picker, and those are best written once the menus stop changing at A4.

**What Orb can play.** The dress rehearsal: Orb installs on the second PC from the real itch.io page with a real key, following the guide and nothing else.

**PLAY THIS would say.** New: no rules have changed since the last build, so its replays still play. The tester guide and checklist are finished. How-to-play describes what is actually on screen. The match-over panel no longer covers your fighter's corner. A picture-quality setting that does something, with a Deck default. Craters and trenches are drawn where you stand. A quiet background sound, and sounds for buildings and menus. "(working title)" beside the name. Try: be the tester. Follow the guide from a blank PC and mark every place you had to guess. Mark the short list of about 150 lines of text a tester meets. Change the quality level and the controls, restart, and check they held.

**Exit criteria.**
- X-18 and X-19 (must pass as a rehearsal by Orb and Orb 2; the real pass is the two friends at A6): install and first match from the guide alone.
- X-22 (must pass): the 1280 by 800 sweep finds no clipped or overlapping text and nothing under 9 px; 12 px is the aim.
- X-20 (must pass, quality level included). X-21 and X-32 (must pass): Legal's sign-off row for each paper a tester meets; privacy words the same in the package, the game and the note.
- X-11 (must pass): the planet fingerprint matches between Windows and Linux in CI.
- X-12 (recorded): the campaign decision is written with its reason.
- X-31 (must pass with the real build): the A5 build is on the itch.io page on both channels and has been updated once and rolled back once.
- X-34: the shot list has rendered from A1 to A5 and the five sets sit side by side.

**Gap ids closed, by owner.**
- **audio-music:** A-AUDIO-02
- **community-marketing:** A-MARKET-08
- **legal-ip:** A-TEXT-04 (nice)
- **qa-balance:** A-QA-01
- **rendering-techart:** A-RENDER-05, A-RENDER-06, A-WORLD-05
- **tools-pipeline:** A-MARKET-05, A-MARKET-06, A-SAVES-08 (nice)
- **ui-ux:** A-TEXT-01, A-TEXT-03, A-UI-05, A-UI-08

**Golden window.** None.

**Tokens.** 12.0M (2 L, 1 M, 11 S). **Weeks.** 1.

**Directors active.** QA & Balance, UI & UX, Rendering, Audio, Tools & Pipeline, Legal, Narrative & Fighter Identity (the text Orb marks), Community & Marketing, Performance & Platform.

---

## A6. The Alpha candidate

**Goal.** One commit passes every criterion from X-01 to X-34, two friends complete the checklist on their Steam Decks, and the feature freeze begins.

**What Orb can play.** The candidate, exactly as the testers get it.

**PLAY THIS would say.** New: only numbers. Easy is easier for someone playing your way; a player who uses only the right stick can win; matches run 6 to 8 minutes. Try: one match at each difficulty and say whether Easy, Medium and Hard feel like three different things. Then nothing else new: this is the build your friends get. After this build, new ideas go in the ideas log.

**Exit criteria (all must pass on the candidate's commit).**
- X-01: two outside testers on Steam Decks return signed checklists.
- X-02: every gate green, records saved for this commit.
- X-06: win-rate bands at each difficulty for a scripted player on Orb's scheme (Easy 60 to 80%, Medium 35 to 55%, Hard 10 to 30%), with enough matches per cell to tell neighbouring bands apart; team and horde bands from QA's new scripts.
- X-23: 60 frames a second held on Orb's PC, no frame over 50 ms outside loading. X-24: the agreed Deck figure held, from a tester's bench file. X-26: loading under 15 s on Orb's PC and 30 s on the Deck.
- X-25: two hours of computer against computer on Windows and on Linux (and on one friend's Deck) with no crash, hang or script error and memory growth under 10%.
- X-27, X-28, X-29, X-30, X-31, X-32 re-read on the candidate. X-33: the freeze is recorded. X-34: the candidate's shots are in the archive.
- X-03, X-04, X-05, X-13, X-14, X-16, X-17 re-run after the numbers moved.

**Gap ids closed, by owner.**
- **game-design:** A-AI-02, A-QA-05
- **qa-balance:** A-QA-08

**Golden window GW4, "Numbers only".** A-AI-02, A-QA-05, A-QA-08. Data values only; no rule may change in this window. If a rule has to change, the candidate goes back to A5's state and the change is priced as a scope change.

**Tokens.** 6.7M (rows 1.7M; verification runs, the soak, the bands, the shot set and folding in two testers' reports, about 5M). **Weeks.** 1.5 to 3, set by people: two friends' time, and one round of fixes from what they find.

**Directors active.** QA & Balance, Game Design, Encounter Systems, Performance & Platform, Tools & Pipeline, Legal and Accessibility (the gate re-read), Production Operations (the freeze).

---

## Rows proposed smaller, or moved

None is dropped. Each stays in its milestone at a smaller size, with the remainder named as after Alpha. Budgets above use the register's classes; the saving if all are accepted is about 19M tokens (the gravity well and the horde keep their classes in the budget until spikes S2 and S3 report).

| Row | Register | Proposed for Alpha | Remainder, after Alpha | Reason | If Orb decides otherwise |
| --- | --- | --- | --- | --- | --- |
| A-COMBAT-04, the move table | XL | L: no dead cell anywhere; the martial and energy rows complete and distinct for each fighter; the LB, LT and RT rows may share entries where the design says so, written down | The full table (55 cells a fighter) at Beta | The full table is the largest single content job and sits last on the critical path; Orb called the mixed string "a long way from finished but right track", so quality per cell matters more than count | Full table: back to XL or more, A4 grows by about a week, and A6 moves with it |
| A-COMBAT-03, the gravity well | XL | Size, zones and the snap into a close fight | The far kit, the catch, the swat and the taunt | S2 sizes it; these three parts are what "the fighters step in and engage" needs | The whole packet: plan a second increment after A3 and one more golden window |
| A-MODES-02 with A-AI-01, the horde | XL + L | Waves of at most three weak bodies at a time inside today's five-body limit, with respawn, a timer and a result screen | Bigger waves, graded henchmen, the "domino" | Raising the body limit touches the sim, the camera and the Deck's frame rate at once; S3 says what it costs | Bigger waves at Alpha: add the body-limit work (L or more) to GW3, and X-10's Deck frame rate becomes the top risk |
| A-CODE-05, a third fighter without code | L | M: zero fighter-specific code in the energy, stamina, body and forms systems; the remaining count recorded and unable to rise | Clearing the other places (365 counted today) and the per-fighter look tables, as the first job of Beta | Four fighters is Beta's bar; clearing every place now risks the two fighters that work, for no gain a tester sees | Clear all at Alpha: L, in GW3, about 3M more |
| A-WORLD-02, custom planet | L | M: a seed and three dials (city count, climate, water) at today's one size; X-11 reworded to match | The size pick (A-WORLD-08, already nice) | Sizes need a frame-rate study that does not exist | Sizes at Alpha: A-WORLD-08 (L) joins GW3 and needs Deck readings per size |
| A-CONTROLS-01, four pads on one PC | M | S: couch 2v2 is two people as a team against two computer fighters; the two pad slots are confirmed and written as the supported line-up | Four pads | Orb has two players; no tester needs four | Four pads at Alpha: M, plus a four-way picture that does not exist |
| A-NET-02, LAN set-up for an outside tester | L | M: a Host and Join row in the game, the address shown and typed, no address baked into files, the firewall step written for Orb's two PCs | One-step set-up for strangers | LAN stays with Orb and the trusted second player at Alpha (recommended below) | LAN for outside testers: back to L, plus A-LEGAL-04 and A-PERF-02 at full size and a real-Deck LAN test; about 6M and one to two weeks |
| A-LEGAL-04, a ruling for outside testers on LAN | M | S: a written ruling that the outside testers' package has no LAN row, and the check that proves it | A full ruling when LAN is offered wider | Same decision | As above |
| A-PERF-02, LAN on Linux | M | S: the Linux build includes the network code and the two-program check passes on Linux in CI | A real two-Deck or Deck-and-PC session | Same decision; keeps X-05 honest on Linux without a Deck LAN test | As above |
| A-RENDER-06, the quality range | L | M: three working levels (low, the Deck's default, the PC's default) behind the existing "Effects quality" row | The ladder up to "maximum" (A-RENDER-10, already after) | The Deck's first reading at A2 decides what the Deck's default must switch off; more levels than that is polish | Full ladder at Alpha: L, in A5 |
| A-AUDIO-02, missing sounds | M | S: one quiet background bed, building damage and collapse, menu moves | Bystanders, the gravity well, music | Orb put the sound toolset in the queue for after the globe arena is settled | All of it: M |

One criterion is reworded, not a row moved: **X-08** is passed on two Windows PCs by Orb and the trusted second player; "a pulled cable shows a notice within 5 seconds" becomes "within 10", keeping today's 8-second rule (A-NET-03 then closes as a test on two real PCs, not a code change).

## The nice-to-have pool

Six nice rows are placed because they are small and sit in work already open: A-AI-13 (A1, part of spike S3), A-TOOLS-13 (A1), A-LEGAL-13 (A2), A-AI-06 (A4: the computer throws right-stick strikes, before the final difficulty tuning), A-TEXT-04 and A-SAVES-08 (A5).

The other 68 wait in the pool. A pool row is pulled only into a milestone that has finished its required rows with budget left, and a pool row that changes the fingerprint is pulled only into an open golden window (GW3 is the last one that takes rule changes). First to pull, in this order, because Orb has asked for each in play: A-COMBAT-10 (chain hits on a foe who is flying; GW3), A-MODES-12 (practice against the dummy), A-RENDER-09 (the re-entry heat trail), A-CAMERA-04 (a small window on your ally), A-TEXT-02 (the fighters' spoken lines), A-RENDER-16 (the clash's air distortion, if the Deck reading says it costs frames).

- A-ACCESS-03: Sounds are captioned for two cues only (the beam struggle and an opening), and that caption line is off by def...
- A-ACCESS-05: The Simple controller layout binds no brace button, so whether the 'Button only' brace style leaves a Simple-l...
- A-ANIM-04: The creative rulebook's held-pose rows still fail the animation check, which is a line of the EP's full gate...
- A-ANIM-05: The rulebook's three questions to Orb (which numbers move, a named-exception list, who signs a change) are una...
- A-ANIM-08: Animation's parked-work page still says Parked for patches the inventory found on main, and the wave files' ow...
- A-AUDIO-05: There is no music: no track has been handed back, the encoder install was not approved, and the pipeline has n...
- A-AUDIO-06: Stacked impacts overdrive the engine's limiter (peaks +1.1 to +9.3 dBFS before it) on the mixer path a desktop...
- A-AUDIO-07: The pad-only silent start in the browser is half fixed: the engine-side hook and the start-menu line that warn...
- A-AUDIO-08: Legal's ruling on the music tool rests on summaries of its terms read on 2026-10-04, and says so; no re-read i...
- A-CAMERA-04: No picture-in-picture for an ally exists: the only built inset is the slanted panel cut-in for the pair on scr...
- A-CAMERA-06: The written list of cuts is behind the code: the code's table has 13 reasons, and two of them (a cut the playe...
- A-CAMERA-07: How long the opponent is out of the picture after a launch is printed but never checked: the chase check limit...
- A-CAMERA-08: Nothing has been tried since Orb asked on 2026-11-09 for more stylised versions of the hard-line merge and fur...
- A-CAMERA-09: Camera pages and parks disagree with main: the split vision page still says today's merge has a dissolve thoug...
- A-CAMERA-12: The director's camera-intent feed is off in main's data and in Orb's build, so the rig's reader for planned be...
- A-CAMERA-13: The known-bugs row for the split-screen jolt on a knock-away is still open and says no measure exists, though...
- A-CODE-06: Code and data that nothing in the game reaches are still tracked: a keyboard class, a swing reader, two world...
- A-CODE-08: The export presets leave test and tool code inside every build: the input tests, the render and camera test fo...
- A-CODE-09: The saved record of the last gate keeps one summary line per check and no logs, so engine warnings cannot be r...
- A-CODE-10: Twelve switch rows are already at their on value on main and five are held off in every build, so 17 rows of t...
- A-COMBAT-09: Launches are not physics-based: the meteor is an authored curve and no attack has a force or any fighter a wei...
- A-COMBAT-10: Chaining hits on a flying foe is only the tap chase; the LT chase, a chain window after a knock-back and a mid...
- A-CONTROLS-09: The quick LT tap still carries the fighter further than the ruled step when far from the rival (9.9 body heigh...
- A-CONTROLS-10: Keyboard play is bound for every action on the solo layout but is unproven on the played build, and two player...
- A-ENERGY-09: Body marks only grow to the worst stage reached and never fade, so the fighter cannot show recovery or the eas...
- A-ENERGY-11: The old hit-point number is still tracked beside the wounds as a second health value, and QA's tools and three...
- A-ENERGY-12: Several damage numbers are code constants shared by all fighters: the stance table, combo growth, the charging...
- A-LEGAL-11: Three older Legal pages still recommend the permissive pairing that the current rundown says never to use....
- A-LEGAL-15: The public repository's safety net ordered on 2026-11-07 (CD-11: secret scanning, push protection, a protected...
- A-MARKET-09: The project's notes disagree with each other on Valve's waiting period and are stale on the licence: three rec...
- A-MARKET-10: Bystanders' run cycles follow the shader's clock, not the tick, so two renders of the same shot differ in the...
- A-MODES-12: There is no practice mode: the grey reference dummy is third in the roster file but nothing in the menu or hos...
- A-MODES-13: The time cap is a rules event at 11 minutes (14 in 2v2) with a pause, but no picture of the planet giving way...
- A-NET-07: The handshake refuses a proposed input wait above 8 ticks but not a negative one, which by the code leaves thi...
- A-NET-09: The corrective plan's row for hardening the LAN link has an empty status cell although the delay cap, the pack...
- A-NET-10: The determinism lint has no rule for the engine's pow, exp or log, so a future bare use in the sim would pass...
- A-NET-11: The Web export preset does not leave out the network folder, so the browser build's pack carries the unreached...
- A-PERF-09: The budget table and its build gate are stale: the Today column is the browser build of e6fa72ff (2026-10-16)...
- A-PERF-10: Whether stalls crackle the sound on a desktop build is not evidenced: the proven mechanism is the browser buil...
- A-PROCESS-12: The public test build's delegated decision lapses on 2026-11-15 with nothing written about who holds it afterw...
- A-PROCESS-17: The sprint loop's contract and report pages live in the git-ignored homework folder, so Orb's approval of a pl...
- A-PROCESS-18: Decisions since 2026-11-01 (the Alpha's scope, the sprint loop, the token order) are in vision.md only, not AD...
- A-PROCESS-20: Corrective item CD-18 is half done: Legal listed 69 process and engineering items to move out of the safety re...
- A-QA-10: QA's tools still measure the backburnered meters and biome signature variants and still use a placeholder name...
- A-QA-12: Orb's saved play files carry no checkpoints, so QA's replays of them are checked only by running without error...
- A-RENDER-09: The re-entry heat trail exists as a ribbon in the fighter's own energy colours, on only by a launch word; the...
- A-RENDER-12: Auras fall short of the taste page: the three-dimensional aura Orb asked for is parked and absent from main, a...
- A-RENDER-14: Seven effect modules keep their numbers in code because their data files do not exist (beam plays, glare, pres...
- A-RENDER-15: The crowd's drawing code still has a path and wording for casualties who 'are simply gone', written before the...
- A-RENDER-16: The beam clash's air distortion copies the whole frame while a clash is on, and its only frame-cost record is...
- A-SAVES-03: The settings file and the controls file are overwritten in place, so a write cut short leaves an unreadable fi...
- A-SAVES-04: Neither settings file can change shape between builds: the settings file has no version, and a controls file w...
- A-SAVES-05: Three loaders do not check the types of what they read (a replay's seed, ticks, toggles and checkpoints; a con...
- A-SAVES-06: The settings file is opened and parsed again on per-frame paths, as the safety audit of 2026-11-07 noted, and...
- A-SAVES-07: LAN match files and the LAN log grow without a cap, in a folder beside the program....
- A-TEXT-02: The fighters say nothing in a match: the approved lines are switched off on main and in the build Orb last pla...
- A-TEXT-06: A few how-to lines are not plain or not true for a desktop tester: the planet bar is called "the strip", the r...
- A-TOOLS-11: On main, a push that queues behind a running CI run is cancelled unrun when a newer push arrives (15 of the la...
- A-TOOLS-12: The local copy of the cloud checks always shows two failing flash-count lines, because it passes the cloud's t...
- A-TOOLS-14: The desktop workflow builds macOS in the same job as Windows and Linux, CI's world-check comment gives a stale...
- A-TOOLS-16: Corrective item CD-25 (one machine-read list of Legal's clip conditions that blocks a public pin) has no commi...
- A-TOOLS-17: Corrective item CD-26 (retire the prototype suites from the deploy gate, retire the flash pixels dry run, rena...
- A-UI-11: Settings lists two rows that do nothing in this build: Beat ring, which the minimal HUD never draws even when...
- A-UI-12: First-time help is the How to play card and one-line hints only; the guided first match is a proposal from Sep...
- A-UI-13: Leftovers of the backburnered hero and villain meters and of hiding remain in the UI code and words, switched...
- A-UI-14: Three UI pages or headers state a status the code has moved past: the minimal HUD page and the report page say...
- A-WORLD-08: World sizes (tiny to colossal) exist only as a plan: the planet is 4,800 columns round by a constant, and what...
- A-WORLD-11: The launch planner still weighs whether a building is lived in through a fighter's care number, and a comment...

## Deliberately after Alpha

Four fighters (Beta's bar). Online play. Mac. Mobile. Modding. The full campaign, and any campaign at all (X-12: none at Alpha; the horde carries co-op). The Steam page, fee and demo. Photo mode and a hide-the-HUD setting. Music. The sound toolset. The terrain overhaul with a tessellation engine. Physics-based launches (nice row A-COMBAT-09 stays in the pool but is not expected to be pulled). The "High Intensity" switch on RT, the taunt before a signature, walking into a beam, punching up a beam. World sizes. The full move table, the far half of the gravity well, bigger horde waves, four pads on one PC, LAN for outside testers and LAN on a Deck (the remainders in the resize table). Windows code signing.

The 22 register rows marked after:

- A-ACCESS-06: Nothing written says the Alpha is English only, the game has no language choice, and the translation tools and...
- A-ACCESS-07: There is no screen reader or menu narration: the area's own audit found no text-to-speech call, and a search o...
- A-AI-12: Some of the computer's numbers are constants in code, not data: how often an attack beat attacks, the share of...
- A-ANIM-07: The rival's four tail strikes sit in his live pools as waiting rows with no key set and no tail bones in the r...
- A-CAMERA-10: Rejected or backburnered looks are still in the camera code behind switches: the cut cross-dissolve, the feath...
- A-CAMERA-11: The camera's numbers live in code, not data: camera_params.gd holds about 500 constants while data/camera has...
- A-CODE-07: The JavaScript core is no longer compared with the GDScript sim: CI only checks that the frozen JavaScript sti...
- A-CODE-11: Change is riskiest in four files of 4,300 to 5,900 lines and a handful of functions of 250 to 670 lines, two o...
- A-CODE-12: Several file headers and comments say the opposite of what the code does (a live stick path described as off...
- A-COMBAT-13: Two planned-exchange templates have a single outcome, and all templates key on the retired four-stance states....
- A-ENERGY-13: Leftovers of hiding still sit in the energy and health code (faster regain and healing while hidden, x1.5 ambu...
- A-LEGAL-14: The content-rating records disagree with the game: the owner's early answer says graphic violence with a Matur...
- A-MARKET-11: A player cannot hide the HUD and there is no photo mode; both are absent from the game and neither is in Orb's...
- A-MODES-14: The campaign is sim groundwork only (about 1,180 lines across three files) with its switch off, no caller in t...
- A-NET-08: The LAN link is plain, unencrypted ENet, which is acceptable on a home network and must change before any inte...
- A-NET-12: Groundwork for online play (a spectator, a seat take-over proposal, a rollback bench that estimates a phone) s...
- A-PERF-11: ADR 0013 says minimum specs are set before launch with no date, owner or method....
- A-PROCESS-19: Corrective item CD-02's manual unpublish rehearsal is still owed: the take-down workflow exists and has run, b...
- A-RENDER-10: Nothing above today's picture exists for Orb's PC: the 'maximum' Orb liked was a research prototype's level, a...
- A-TEXT-05: The placeholder names KAI and VORR remain in data and code a player does not see: a placeholder line file no g...
- A-WORLD-12: Much of the world is built, switched off and never in a played build (craters by material, forest fire, beam a...
- A-WORLD-13: Orb's ask for a cheap tessellation engine with destructible, deformable terrain meshes has no design page; the...

## Change control

**During the push (A1 to A6).** Every new idea, whoever has it, is written in the ideas log the same day with one recommendation: now, at the next milestone, or after Alpha. Nothing is built silently, including by a director who thinks it is small. "Now" is allowed only if all three hold: it fits inside a row already open in the current milestone; it does not change the sim's fingerprint, or the current milestone has an open golden window that takes rule changes (GW2 in A3, GW3 in A4); and its cost is stated and comes out of that milestone's budget, with the row it displaces named. "At the next milestone" means the idea is priced as a size class and Orb sees the price beside the idea. Anything that is a new system goes to "after Alpha" unless Orb lifts it in, in which case the Executive Producer says which required row moves out or how many weeks are added. An idea already answered by Orb with "workshop this" gets a page, not a build, until it is placed.

A risk-first addition: **each spike's page counts as a change request.** If a spike says a row is a class bigger than the register thought, the Executive Producer brings Orb the choice (smaller version, later date, or something else moves out) before the row starts.

**After A4** no rule changes are taken at all; A5 is words and pictures, A6 is numbers.

**After the freeze (the day A6 passes).** A new idea is either logged for after launch, or brought to Orb as a scope change with its cost in tokens and weeks and what it would re-open. Only Orb lifts an idea in. Fixes to things that are broken are not ideas and carry on.

First entries the log should hold on day one, from Orb's answers of 2026-11-13: the absorb (hold LB, time RB), recommended at the next milestone only if the stamina loop's first measurement is in, otherwise after Alpha; flinging debris; the power-up contest as a mid-fight event; slipstream; a right-stick flick that sends a dashing attacker flying; the wind-up throw; synergy abilities for co-op. All recommended after Alpha except the first.

## The critical path, and the three risks

**The chain that sets the earliest Alpha.**

1. Commit or deliberately ignore the working tree (A-PROCESS-03), then move the played build's patches and ten groups of switches onto main (A-CODE-03 and the rows A-CODE-01 needs), then A-CODE-01 itself and a golden record for it (A-CODE-02). Nothing else can land with confidence before this.
2. The one-command desktop build (A-TOOLS-01, which also needs A-LEGAL-02).
3. The model page (A-ENERGY-02), then the stamina, energy and body loop (A-ENERGY-01) and the signature inputs (A-COMBAT-02), in GW2.
4. The move table (A-COMBAT-04), which needs both, with transformations (A-COMBAT-06) beside it, in GW3.
5. Tuning on the finished rules (A-AI-02, A-QA-05, A-QA-08), in GW4.
6. The candidate's long checks (the soak, the bands) and two friends' Deck sessions (X-01).

Two chains run beside it and are nearly as long: the build to the itch.io rehearsal to the tester guide to the testers (A-TOOLS-01, A-TOOLS-02, A-QA-01, X-01); and the mode list to the horde to its computer control to QA's team and horde bands (A-MODES-01, A-MODES-02, A-AI-01, A-QA-06). The safety chain (A-LEGAL-01 and A-LEGAL-08, then A-LEGAL-03, then A-PERF-01 on a real Deck) is not on the path to the candidate's date but is on the path to learning the Deck's answer, which is why it is second.

**The three risks most likely to move the date.**

1. **Main cannot simply be made into the game Orb plays.** 72 switch rows, patches that exist only in a preview tool, a golden record valid only with the switches off, and gates that have never run on the played configuration. Turning it all on is likely to turn checks red that nobody has looked at, and the measurements on the globe ground already fail. If this takes three weeks instead of one and a half, everything moves by the difference. Guard: land row by row, each with its own gate run; nothing from A3 lands until GW1 is closed; the Executive Producer reports the count of rows still differing every two days.
2. **The Steam Deck says no to something.** A shader the driver rejects, a frame rate well under 30, text too small at 1280 by 800, or the Deck's controls not arriving as a pad. Any one can add a milestone of rendering work or lower a target Orb has to agree to. Guard: S5 in A1, the real session in A2, a bench file asked of the same friend at A3 and A4 (five minutes each), and the Deck's default quality level built at A5 from real numbers.
3. **The fight rework is a class bigger than estimated.** The beam, the signature inputs, the stamina loop and the gravity well all change the same exchange code in the same window, and the beam struggle, the answers to a beam and the computer's beam play all hang off the old form. Guard: S1 and S2 before any of it starts; each lands behind its own switch with its own probe; and a stop rule: if the gravity well's first cut is not playable at the midpoint of A3, A3 ships its size and zones only and the snap moves to GW3, without holding the beam or the stamina loop.

Watched but not in the three: the horde on a Deck (sized by S3, bounded by the three-body resize), and the wait for people (two friends, twice).

## The decisions that are Orb's, most urgent first

Each has one recommendation. The first six are needed before A1 can close; the next four before A2 can.

| # | Decision | Recommendation | What it blocks |
| ---: | --- | --- | --- |
| 1 | May the team make the 9 November build the default game on main, row by row, before any new feature work? | Yes. | All of A1, and so everything |
| 2 | The default world: one fixed planet, or a new random planet each match? | A new random planet each quick match, the seed shown and saved in reports; one fixed planet for a newcomer's first match and for tests. | A-WORLD-01 and A-WORLD-14 in GW1 |
| 3 | Do the globe ground, the crater look with the black fill removed, and the meteor trail become the defaults? And is the terrain workshop of 2026-11-09 part of Alpha? | Yes to the defaults. The workshop is after Alpha; Alpha gets craters and trenches drawn where you stand. | A-RENDER-01 and A-RENDER-04 in A1; A-WORLD-05 in A5 |
| 4 | Which build do new looks get compared against? | The 2026-11-09 globe build, with its known picture faults listed as not part of the reference. | The look gate for every visible change from A1 on |
| 5 | Flight speed 3500 as the default in every mode, with the slider dropped until a real setting exists? | Yes. | A-CONTROLS-04 in GW1 |
| 6 | The backburnered hero and villain meters: off, folded in, or retired? | Keep the comeback as a rule for every fighter, set every other effect to zero in data now, remove the code after Alpha. | A-ENERGY-05 in GW1 |
| 7 | May the team make desktop test builds for named testers, and which friend with a Deck does a first 30-minute session? | Yes, Windows and Linux; ask one friend now. The one-line approval is recorded when the gates are green and not before. | A2's Deck session, the largest unknown |
| 8 | The report channel. | A new private server (not the converted one), a channel locked to a tester role, and keep the promise to delete a tester's reports on request. One small file per report, clips left out. | A-LEGAL-07, A-TOOLS-05 in A2 |
| 9 | The itch.io page: may a restricted, key-only page go up under the working title before the paid title search, and will Orb do the account, the page and the upload tool? | Yes if Legal writes that it is unlisted and unpromoted; one key per named friend; Orb does the three actions in one sitting. | A-LEGAL-09, A-TOOLS-02 and the A2 rehearsal |
| 10 | The licence line. | All rights reserved through Alpha with a short friendly permission page; decide about public code at Beta. | A-LEGAL-10 and the papers in the A2 package |
| 11 | How much of the stamina, energy and body loop is in Alpha, and is "body" a new number? | The whole loop as shared rules with per-fighter numbers in data, switched on after QA's comeback measurement. Reuse the old hidden health number as the deep number behind the body parts, with the core kept as its own most important part. | A-ENERGY-01 in A3 |
| 12 | How much gravity well, and does your stick move only you up close? | Size, zones and the snap. Answer the stick question after seeing spike S2, before the build starts. RT held stays the charge for Alpha. | A-COMBAT-03 in A3; A-COMBAT-15 |
| 13 | LAN at Alpha: for outside friends, or for Orb and the trusted second player? | Inside the game behind a Host and Join row, played only by the trusted two, Windows only; the outside testers' package has no LAN row. | The size of A-NET-02, A-LEGAL-04, A-PERF-02 in A3 (about 6M and one to two weeks either way) |
| 14 | Beam stages, and the other "workshop this" items: before or after Alpha? | Beam stages: decide from spike S1, build only if it fits inside the beam rework. Close fights: decided with the gravity well. Nice to have: re-entry trails, a window on your ally, planet dials beyond three. After Alpha: the terrain overhaul, High Intensity, the taunt, walking into a beam, the sound toolset. | A-COMBAT-15; what goes in GW2 |
| 15 | The move table's bar for Alpha. | The smaller table (see the resize); the full one at Beta. | A-COMBAT-04 in A4, the last big item on the critical path |
| 16 | The horde's first size; couch 2v2's line-up; a computer partner; the custom planet's dials. | Three weak bodies at a time; two people against two computers; yes, one line-up with a partner; a seed and three dials at one size. | A-MODES-02, A-MODES-03, A-AI-08, A-WORLD-02 in A4 |
| 17 | A transformation: aura only, or the body too? And the second copy of a fighter in 2v2? | One cheap body change per step carried by data; a second body colour per fighter, picked by team. | A-COMBAT-06, A-ANIM-01, A-ANIM-02 in A4 |
| 18 | The campaign at Alpha. | None; record it as the X-12 decision. | Nothing; it removes work |
| 19 | The frame-rate targets. | 60 on Orb's PC. For the Deck, wait for A2's real reading, then confirm 30 held with 40 as the aim. | X-23 and X-24 at A6; the Deck's default quality at A5 |
| 20 | A pad that drops out mid-match: pause with a notice? Keyboard: "works, a pad is recommended"? | Yes to both. | A-CONTROLS-03 in A2 |
| 21 | Sound: is a quiet fight with no music acceptable, and will Orb do a ten-minute listening pass? | One quiet background bed and the building and menu sounds; no music; yes to the pass, at A2. | A-AUDIO-02, A-AUDIO-03 |
| 22 | Will Orb mark about 150 lines of the text a tester meets? Do the fighters speak their approved lines? English only? | Yes; yes if pulled from the pool; yes, and say so in the guide. | A-TEXT-01 in A5 |
| 23 | After the freeze, does every new idea wait unless Orb lifts it in as a scope change? | Yes. | X-33 at A6 |

Can wait until after Alpha: the Steam fee and what "Beta in sight" means; code signing (not for Alpha; the guide explains the Windows warning); photo mode; where the progress archive's second copy lives (a second drive, soon, but it blocks nothing); turning on the repository's free safety settings (yes, any day).

## Self-check

Run against `03-gap-register.json` on 2026-11-13 with a script: 270 rows; 174 required, each in exactly one milestone (A1 72 rows of which 2 nice, A2 41 of which 1 nice, A3 30, A4 20 of which 1 nice, A5 14 of which 2 nice, A6 3; 180 placed = 174 required + 6 nice); 0 missing, 0 placed twice; 0 rows marked after are placed; all 67 "needs" links among placed rows point to the same or an earlier milestone (0 violations); all 35 required rows that change the fingerprint are in the four named windows (12, 11, 9, 3); 68 nice rows in the pool, 22 after. The seven rows on the one topic kept off Orb's page are planned like any other (six in A2, one in the pool) and no question about them appears in the decisions table.
