# The path to Alpha

Judgment session, phase 4, 2026-11-13. Baseline 8901d351. Source: `03-gap-register.json` (270 rows; 174 required, 74 nice, 22 after Alpha).

**How this was made.** Three planners each drafted a full path from the register without seeing each other: risk first, modes first, newcomer first (`04-drafts/`). A fourth agent scored them against the specification's rules (`04-drafts/scores.md`): risk first 82 of 100, modes first 79, newcomer first 76. This page is the risk-first draft with the scorer's grafts from the other two, applied by the auditor:
- from modes first: the mode list, the fighter pick, the quit row and the mode smoke suite move into A1; a measuring tool is built and read in one milestone and must pass from the next; the last numbers window closes in A5 so the candidate is measured on numbers that no longer move;
- from newcomer first: the outside-tester safety gates are briefed on day one of A1; two friends, not one, take the first Steam Deck session, from a full draft of the guide and the real restricted page, and later builds reach them as real updates; the fight's decisions are asked of Orb at A1; the six-step change-control rule; a slower pace shown beside the planner's; a named fix reserve after each tester round;
- from the scorer's list of faults all three shared: the order of work inside A1 is given; the first desktop build is its own step with a look check; what happens when a milestone misses its exit is written; the criteria this audit proposes to change are listed in one place, not buried in milestone text; each director's load per milestone is counted; the year-end holidays are named.

Nothing here is decided. It is the audit's recommendation to Orb, and nothing is built until Orb approves it.

## What the adversarial review changed

Five reviewers attacked this plan, each through one lens, and a verifier checked every criticism against the files: 58 criticisms, 36 confirmed, 22 confirmed in part, none refuted (`06-adversarial.md` has each one, its verdict and what changed). The largest changes are written into the milestones, the tables and the briefs. The rest are the rules below. **Where a rule in this section and a line further down disagree, this section wins**, and each affected brief carries the same change under its own "Amendments" heading.

**Rules that hold for every milestone.**
1. **No build reaches an outside tester on a red gate.** No build is uploaded to a channel an outside tester holds a key to, or sent to one, unless every gate on the "before an outside tester plays" list (X-02) is green with saved records on that commit. This is an exit line of A2, A3, A4, A5 and A6. The update-and-roll-back rehearsals use a separate dummy channel no tester's key can see. Each re-run of the list is priced at about 0.6M (a gate pass and a look gate, from the project's own figures).
2. **Every upload is Orb's own action**, on Orb's page for that milestone. No session uses Orb's sign-in. The rehearsal's key is claimed by the trusted second player on an account they make themselves.
3. **A tester's raw files never go into the repository.** A friend's report and speed-test files live in a git-ignored folder; only the team's own reading of them (numbers, no quoted notes) is saved under `docs/*/runs/`. A tester's request to delete is carried out on that folder and on the report server, and the release page says who does it.
4. **A look change made to pass a safety reading goes to Orb as a look question.** If the ordinary look of the beam clash or of a cut is changed, Orb sees two clips and is asked only which looks better, or whether they look the same (ADR 0010, point 3). If Orb prefers the old look, the ordinary look stays as it is and Legal rules on what the testers' package does.
5. **No decision is taken by silence.** Every row of the decisions table needs Orb's yes. Ten need thought; the rest are likely a one-word answer. Work that depends on an unanswered row waits, and the Executive Producer lists what is waiting.
6. **Fixes from Orb's own plays** at A1, A3, A4 and A5 are paid from the 25% rework line, and that line is counted in the weeks.
7. **A desktop program that must draw a picture is started in CI or by Orb, never by a session.** Stills from the Windows and Linux builds come from CI (row A-TOOLS-13 and spike S5 are required, not optional). Until that exists, "Orb starts it once" is on Orb's page for the stills, the menu still and the press-to-picture record.
8. **The machine.** One PC is shared by every session and by Orb's own play. Each milestone's Executive Producer page lists its long runs with their hours (QA's batches overnight, the soak, the bands), the quiet window kept for frame readings, and which sessions pause while a reading is due. A reading taken on a busy machine is void, as today.

**Golden window GW1 is split in two.** GW1a: the golden record is made first, on the kept 9 November build's own data, as the target. The switch groups then land one at a time, and A-CODE-01 closes when main reproduces that record bit for bit. The first desktop build and its same-replay comparison with the 9 November build are made on that commit, where nothing is meant to differ and Orb's 9 November play files still verify. GW1b, straight after: the small rule changes that ride along (the backburnered meters set to zero, the computer's perfect-block fix, the two stray-beam fixes, flight at 3500), then one re-record. PLAY THIS for A1 says plainly that the old hero and villain meters no longer change the fight and asks whether matches feel easier, harder or flatter. Comparisons against a saved play file after a window use the scripted set plus play files saved on the current build. At A3, A4 and A5 Orb is asked to name that milestone's build as the new look reference.

**Testers.** The same two friends cannot be both the early testers and the newcomers. Orb is asked for two more Steam Deck owners who are held back and first see the game at A6, for the newcomer criteria (X-18, X-19). If only two exist, A6's reading of those criteria is a re-install by experienced testers and is said to be so. A third early tester is asked for so that two finish, and the first session is called 60 to 90 minutes, not 30. A friend with one Deck has one controller: the checklist's two-player rows are marked "if you have a second controller", and those modes are tested by Orb and the trusted second player. The tester's privacy line also names itch.io (an account is needed to claim a key, if the rehearsal confirms it) and says that reports are read with AI tools on Orb's PC. The words of the flashing notice and the safety settings are Legal's and are not on Orb's keep, rewrite or cut list. The roughly 150 lines of text a tester meets are marked by Orb in A2, before a friend plays, not in A5.

**The start menu in a tester's package** shows only modes a tester can use: each mode row carries a "shown in the testers' package" flag, and the campaign and LAN rows are off until Orb answers decisions 13 and 18, which are asked on day one of A1 with the others.

**The close-fight question and the stop rule.** The part of the gravity well that decides whether your stick moves only you up close is not built until Orb has answered from spike S2's clip; size and zones may start. The stop rule for the pull (if it is not playable at A3's midpoint, the snap moves to the next window) is asked of Orb in A1 as a standing yes; without that yes it is a question at the midpoint and nothing moves until the answer.

**The marks drawn on the fighters** during a dash and a press (a charge ring, a diamond, a double ring, a squeezing ring with brackets, a ring on the striking hand) are in the 9 November build today. They are read in the code in A1, shown to Orb as clips with one question, and listed among the known faults that are not part of the look reference.

**Order changes.** Tools' repair of the flash measuring chain (A-LEGAL-08) is sent as a day-one brief and does not wait on A1's landings. Decisions 11 to 14 are confirmed before A2's work-ahead starts, from the spike pages delivered with the A1 build. The seed-only Windows-against-Linux planet comparison is read in A1 beside spike S5 and extended to the dials in A4. In Tools' A1 work the CI jobs are split (A-TOOLS-08) before more checks are wired in (A-CODE-04), and the newly wired checks join CI on GW1's closing commit. The A5 build goes to the friends (after rule 1) with the five-minute speed-test ask, so the Deck's default picture level is read before the candidate. The team and horde bands and the horde's run length are named in the last numbers window (GW4), which gets at least three read-and-adjust rounds, each an overnight batch; if a band is still out after three, Orb chooses between another week and shipping with the band stated. X-15's "no fighter-specific code" is read at A3 and must be zero from A4. A2's rows may close before the friends' files arrive, with the Deck's first readings carried by name, and A3's fight work proceeds during the tester round. At A6 the outside-tester package carries X-01, X-18, X-19, X-21, X-24, X-32 and the Deck soak; the trusted-two package carries X-08 and the LAN rows of X-05; everything else is read on both, from the one candidate commit. Deck readings carry across A6's fix round only if the fixes touch no drawing or loading code; otherwise a second five-minute ask is made.

**Cost changes.** The three largest rows are carried above their size class until spikes S2 to S4 report, because the project's own packets say so: the gravity well at 12M, the smaller move table at 13M, the horde at 16M (13M more in all). Spikes S1 to S3 are 2M each; S3 measures up to five weak bodies and gives the cost of lifting the five-body limit as an estimate. The flash reading on the globe ground (A-LEGAL-01) is an XL shared by Camera, Rendering and VFX. Wiring the unrun checks into CI (A-CODE-04) is an L. The last numbers window is an L. Small rows land in batches that share a gate run, about twenty landings a milestone at most; the Executive Producer's landing time is in the third of each week kept for it. If Orb declines the smaller versions: the gravity well's full packet is about 20M more and one more golden window, and the full move table is unpriced until S4 reports. Orb's own time, never added up before: allow three to five hours a milestone for the play, the questions and the reports, and one sitting of one to two hours in A2 for the account, the page and the report server.

## The angle, the pace and the totals

**Risk first.** The order here is set by what is least known, not by what is quickest to finish. Six things could each turn out much bigger than their size class, or show that the Alpha as defined cannot be reached: the first real Steam Deck run; a desktop build of the game Orb actually plays (today that game exists only as a browser build made by patching a copy of main); the beam rework (a beam that travels through space and misses if you move off its line); the horde mode; the gravity well (the pull that draws two fighters into a close fight); and the move table. Every one of them is either built or sized by a throwaway trial ("spike") in A1 or A2, before the team commits weeks to anything that depends on it. The cost is that the early milestones are heavy and unglamorous, and the first build with new things to press arrives at A3. The gain is that by the end of A2 the path's length is known from evidence instead of from size classes.

**Pace, in one line:** the plan assumes about 35M tokens of finished director work a week (range 25M to 50M), which is roughly 60 to 80% of the weekly allowance with directors mostly on the cheaper models (about 1 meter point per 1M tokens, 1.6 on the largest model) and about a third of each week spent by the Executive Producer on briefs, reviews, gate runs and rework. The record behind this is thin: no clean weekly figures exist, one night planned at about 10% was about 13M tokens briefed, and the week that ended 2026-11-13 reached about 82%. Weeks are therefore given as ranges, and row A-PROCESS-08 (start a weekly token record) is in A1. **The basis, as measured in this audit:** the all-models weekly meter moved 11 points for 7.0M tokens on the largest model (about 1.6 points per 1M); the cheaper models, which most directors run on, cost less per token, and the audit's own reading on them was too small to give a clean figure. **The slower case:** if only 20 to 30M tokens of register work land in a week (the newcomer-first planner's assumption: a third of the allowance, the rest going to review, gates, rework and Orb's own asks), every range below sits at its upper end. **The date is re-estimated twice:** at the end of A1 from two weeks of real token figures, and at the end of A2 from the spikes and the first real Steam Deck readings.

**Token budgets are size classes, not quotes:** S about 0.25M, M about 1.2M, L about 4M, XL about 8M. Almost no row has a comparable piece of finished work behind its class.

**People's time is counted too.** Orb plays every milestone's build (allow two to four days for the play and for the reports to be read and sorted). Friends with Steam Decks test twice: two friends for 30 minutes each at A2, and the same two on the candidate at A6; in between, the A3 and A4 builds reach them as real updates through the itch.io page, with a five-minute bench file asked each time. Each round waits on people's free evenings: allow one to two weeks a round. **The year-end holidays fall inside every range below and are not counted:** if the team or the testers pause, add that time.

**Working ahead.** A milestone is defined by what closes in it. Directors with nothing to close in the current milestone start the next one's work behind a switch (finished work waiting outside main is called a "park" in this project) so that no session sits idle. Where that matters it is said below.

**Totals, after the adversarial review:** about 228M tokens (rows 184M at the register's size classes; 13M carried on top for the three largest rows until their spikes report; spikes 7.5M; gate re-runs and one extra golden re-record 2.2M; the last numbers window priced as an L; fix reserves after the two tester rounds 14M; the candidate's verification runs 5M). Plan on 25% on top for rework, which also pays for fixing what Orb's own plays find. **About 12 to 22 weeks** of work and waiting (the first tester round overlaps A3's work, so the sum of the ranges below is a little more), which puts the Alpha candidate between early February and mid-April 2027, before any holiday pause. The review's cost reviewer showed from the project's own history that the first draft's 9 to 16 weeks was too short at both ends. These are size classes added up, not a quote: treat it as "roughly 230M tokens, roughly three to five months at hobby pace".

| Milestone | What it proves | Rows | Tokens | Weeks | Golden window |
| --- | --- | ---: | ---: | --- | --- |
| A1 | Main is the game Orb plays, it builds for the desktop, and every built mode starts from a menu | 77 | 55M | 2 to 4 | GW1 "Main is the game" |
| A2 | Safe to hand out; two real Steam Decks have run it | 41 | 34M | 2 to 4 | none |
| A3 | The fight's new rules; LAN inside the game | 27 | 53M | 3 to 5 | GW2 "The fight's rules" |
| A4 | Horde, teams, your own planet, the whole fighter | 19 | 57M | 2 to 3 | GW3 "Many bodies and the full fighter" |
| A5 | A newcomer on a Deck, alone; the last numbers settle | 16 | 16M | 1.5 to 3 | GW4 "Numbers only" |
| A6 | The Alpha candidate, frozen | 0 | 13M | 2.5 to 5 | none |

A "golden window" is a landing that changes the sim's state fingerprint: the saved reference matches ("golden records") are re-recorded and replays from earlier builds stop verifying. All 35 required rows that change the fingerprint sit in four windows; A2 and A6 have none, so a replay saved on the A1 build still plays on A2's, and the candidate is measured on rules and numbers that no longer move.

**The tool rule (from the modes-first draft).** A criterion's measuring tool is built and gives its first reading in one milestone; the criterion must pass from the next. Where a line below says "first reading", a failing number is the expected result.

**If a milestone misses its exit.** A must-pass line that is a safety gate or a blocker holds the milestone open: the build is not handed on. Any other must-pass line that is missed goes to Orb within a day as one question with three choices (wait, ship the milestone short with the line carried forward by name, or cut something). Nothing ships short silently, and a carried line is the first exit line of the next milestone.

---

## A1. Main is the game Orb plays

**Goal.** A fresh copy of the repository, with one command, makes the Windows and Linux desktop builds of the game Orb played on 9 November; that build opens on a list of modes with a fighter pick and can be quit with the pad; and the four biggest unknowns in the fight have each been tried small.

**Why first.** 72 of the 92 switch rows differ between main and the build Orb plays, and 14,805 paths are uncommitted. Until this closes, every test, every gate and every measurement describes a different game from the one being judged. Nothing later can be trusted, so nothing later starts landing.

**The order inside A1** (the first risk lives here, so the order is fixed):
1. Day one, in parallel with everything else: the outside-tester safety gates are briefed first (A-LEGAL-01, A-LEGAL-08, A-CAMERA-02, A-LEGAL-03). They close in A2, but they are the longest-running work a tester depends on, so they start now. Orb's first six decisions (below) are asked on day one too, with the fight's decisions (11, 12, 14 and 15) so the spikes know what to try.
2. The working tree is committed or deliberately ignored (A-PROCESS-03), so the repository holds the project's state.
3. The code that exists only as patches in the private build tool moves onto main (A-CODE-03): the planet entry, the report and replay hook (A-UI-02), the energy model's switch (A-ENERGY-04).
4. The switch groups become main's data one owner at a time, each with its own gate run and its own side-by-side against the 9 November build: the pad (A-CONTROLS-02), the computer opponent (A-AI-05), the match-ending rules (A-MODES-07), the round planet (A-WORLD-01), the camera (A-CAMERA-01), the look (A-RENDER-01, A-RENDER-04), the sound sets (A-AUDIO-01), the left-panel menus (A-MODES-15 with A-UI-01, A-UI-04, A-UI-06). The Executive Producer reports the count of rows still differing every two days.
5. A-CODE-01 closes when no row differs, and a golden record is made for the game as shipped (A-CODE-02). This is golden window GW1.
6. The first desktop build is its own step, not an assumption (A-TOOLS-01): Windows first, then Linux, each started once and compared by stills, at the same ticks of the same replay, with the browser build Orb played. A difference is a finding before it is a build.
7. Beside all of it, on scratch copies: the mode list, fighter pick, quit row and mode smoke suite; the measuring tools; and spikes S1 to S5.

**What Orb can play.** The first desktop build of their own game: a Windows program (no browser, no shortcut with special words) that opens on the menus with the panel down the left (the "Rail" menus Orb picked), on the round planet, with the pad as Orb plays it and flight at 3500. The start menu lists the modes that exist today (solo, two players on one PC) with the unbuilt ones shown as "coming", lets each player pick a fighter, and has a Quit row.

**PLAY THIS would say.** New: this is the same game as your 9 November build, but made from main by one command, as a Windows program. The start menu now lists modes and lets you pick your fighter, and you can quit with the pad. Pause now opens its menu. The start menu's d-pad moves evenly. A stick beam you let go of no longer fires later on its own, and RT + B only counts just after RT. The old hero and villain meters no longer change the fight. Try: play one full match and say whether anything else is different from 9 November, and whether matches feel easier, harder or flatter without the meters. Press the report button at the end and check a file appears. Then look at the four short trial clips (a beam you can sidestep, the pull into a close fight, six weak enemies at once, the map of which button presses do nothing) and answer the question under each.

**Spikes (trials on a scratch copy; nothing lands; about 7.5M in total: S1 to S3 about 2M each).**
- S1, beam: one beam that leaves the fighter, travels at a speed and misses a defender who steps off its line, run through the X-16 probe at three ranges. Says whether A-COMBAT-01 is an L, and what breaks in the beam struggle and in the computer's beam play.
- S2, gravity well: size, zones and the snap as a toy on the scratch copy, to see whether A-COMBAT-03 at "size, zones and the snap" is an XL or an L, and to put the "does your stick move only you up close" question to Orb with something to look at.
- S3, horde: does the parked one-against-many work still apply (A-AI-13); what up to five weak bodies cost in frame time; does respawn fit the sim's five-body limit; and, as an estimate only, what lifting that limit would cost. Says whether A-MODES-02 and A-AI-01 are 12M or 20M.
- S4, move table: run the coverage count on the played build's own data, so the 18 dead cells and 65 repeats are confirmed on today's game, and Combat prices the smaller and the full table.
- S5, Linux picture: a CI job starts the Linux build under a virtual display and saves one still. This is the cheapest possible answer to "has a Linux build ever drawn a picture", weeks before a friend's Deck is involved.

**Exit criteria.**
- X-29 (must pass): one command and one CI run make the Windows and Linux builds from a commit, the solo game included; the build shows a version number; a changelog entry is written.
- X-17 (first reading, with the count built here; must pass from A2): beams started by any input other than the right stick or RT + B, on Orb's saved play files and the scripted set. The aim is 0. (The signature inputs change in A3.)
- X-05 (first reading): the mode smoke suite exists and has run solo and two players on one PC on Windows and Linux, from the menu, with a pad alone, to a result, a rematch and a quit.
- X-27 (first held here): a replay carries its build id; a replay from another build is refused with a plain message.
- A golden record exists for the configuration Orb plays, and the gates run with the switches as shipped (A-CODE-02). The 92-row switch table is reduced to rows that still describe a choice.
- X-23 and X-26, first readings only: a frame record and loading times for the desktop build on Orb's PC. X-06, first readings: win rates at Easy, Medium and Hard for a scripted player on Orb's scheme, on the build's own packed data, with enough matches to tell bands apart.
- X-33 (must pass): the change-control rule and the ideas log exist and the playbook points to them. One backlog; the working tree is committed or deliberately ignored.
- The measuring tools for X-03 (the pad-driven coverage probe, written against today's move table), X-04, X-13 and X-16 exist and have each produced a first (failing) reading. The 1280 by 800 screen sweep exists and has produced stills of every menu.
- Spikes S1 to S5 each end in one page: what was tried, what it cost, the size class now believed, and the question for Orb if there is one.

**Gap ids closed, by owner.**
- **audio-music:** A-AUDIO-01
- **camera:** A-CAMERA-01
- **combat-choreography:** A-COMBAT-14
- **controls-feel:** A-CONTROLS-02, A-CONTROLS-06
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
- **tools-pipeline:** A-CODE-03, A-CODE-04, A-ENERGY-06, A-LEGAL-02, A-MODES-08, A-TOOLS-01, A-TOOLS-07, A-TOOLS-08, A-TOOLS-09, A-TOOLS-10, A-TOOLS-13, A-TOOLS-15, A-UI-02
- **ui-ux:** A-MODES-01, A-MODES-06, A-MODES-11, A-MODES-15, A-UI-01, A-UI-04, A-UI-06, A-UI-09
- **world-environment:** A-WORLD-01

**Golden window GW1, "Main is the game".** The defaults Orb plays become main's data (A-CODE-01 and the rows it needs), with the small input fixes and the backburnered meters set to zero riding in the same window: A-AI-05, A-AI-10, A-CODE-01, A-COMBAT-05, A-COMBAT-11, A-COMBAT-14, A-CONTROLS-02, A-CONTROLS-04, A-ENERGY-04, A-ENERGY-05, A-MODES-07, A-WORLD-01. A-NET-05 (the build id in a replay) lands before the window, so every replay made from here on is refused plainly by a later build instead of failing halfway.

**Tokens.** 55M (rows 46.6M: 3 L, 17 M, 57 S; spikes 4.5M). **Weeks.** 2 to 4.

**Directors active.** Tools & Pipeline, Simulation & Engine, Encounter Systems, World & Environment, Rendering, Camera, Controls & Game Feel, UI & UX, Audio, Game Design, Combat & Choreography (S4), QA & Balance, Performance & Platform, Netcode (the replay's build id), Legal (three rulings), Production Operations, and the Executive Producer (who carries most of the small process rows). Started early for A2: Camera, Rendering and VFX on the flashing measurements; Legal on the tester note.

---

## A2. Safe to hand out; two real Steam Decks have run it

**Goal.** Every gate on the "before an outside tester plays" list is green on a commit, and two friends have each installed that build on a Steam Deck from the real restricted itch.io page with a key and a full draft of the tester guide, played 30 minutes with the Deck's own controls, run the one-press bench and sent back two files.

**Why second.** The Deck is the single largest unknown that the team cannot study on its own: no Linux build has drawn a picture on real hardware, no shader has met the Deck's driver, and the frame rate is a guess. It is also the one test that needs a person outside the trusted two, so it cannot happen before the safety gates. Doing both now means that if the Deck needs a different picture quality, a different renderer setting or a lower target, that is learned with four milestones left instead of one.

**What Orb can play.** The same game as A1 (no rule changes, so A1 replays still play), now as the package a tester would get: the notice before play, the AI disclosure on the first screen, a report that saves from the pad on any PC, and a crash file if the game dies. Orb also does the ten-minute listening pass on this build.

**PLAY THIS would say.** New: nothing in the fight. Everything around it: the report panel works with the pad and saves one small file anywhere, not only on your PC; if the game crashes it leaves a file saying why; unplug a pad mid-match and the game pauses and says so. Try: install it on the old PC from the itch.io test page using only the draft guide; pull a pad out mid-match; listen for ten minutes and mark what sounds wrong. Each friend with a Deck gets the draft guide and a one-page sheet: install, play two matches, press the bench, post two files.

**Exit criteria.**
- X-02 (must pass): the list of gates exists and each has a saved record under `docs/*/runs/<sha>/` for this commit, including the measurements on the globe ground that every played build uses.
- X-28 (must pass): a forced crash on Windows and on Linux leaves a file, and the report folder picks it up.
- X-21 (must pass on Windows and Linux; on the Deck by the friend's file): one press saves a report under 10 MB with nothing sent automatically; the file has been checked for account names and file paths; the code read finds nothing that sends data.
- X-17 (must pass). X-18 and X-19, first real reading: each friend's sheet comes back saying how long install took and where they got stuck. Not a pass yet; the guide is a draft.
- X-24 and X-26, first real reading: a frame record and loading times from a real Deck, made by the one-press bench. This number decides whether "30 held, 40 as the aim" stands.
- X-30 and X-31 (must pass as a rehearsal, then used for real): a dummy build is pushed to a restricted itch.io page on a Windows and a Linux channel, a key is claimed, an update is applied, and the previous version is restored in one step; then the A2 build itself goes up, and A3's and A4's builds reach the two friends as updates.
- X-25, first reading: a two-hour soak on Windows and on Linux in CI, with memory growth recorded.
- X-07 (must pass in full): a pad unplugged mid-match pauses with a plain notice, and the existing two-pad checklist is run and signed (each pad drives its own fighter; player one starts on the left). X-20 (must pass on Windows and Linux): settings survive a real restart.
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
- **ui-ux:** A-ACCESS-02, A-LEGAL-13 (nice), A-SAVES-02, A-TEXT-01, A-UI-07, A-UI-10

**Golden window.** None.

**Tokens.** 34M (rows 28.4M: 1 XL, 11 M, 29 S; a fix reserve of 6M for what the first tester round finds). **Weeks.** 2 to 4; the top of the range is the wait for Orb's account actions and for two friends' evenings.

**Directors active.** Camera, Rendering and VFX (the measurements on the globe ground), Legal, Accessibility & Localization, Tools & Pipeline, Performance & Platform, UI & UX, Controls & Game Feel, Audio, QA & Balance, Community & Marketing (the shot list with Tools). Working ahead for A3, behind switches: Encounter Systems (the beam and the signature inputs, from S1), Simulation & Engine (the gravity well's first cut, from S2), Game Design (the stamina, energy and body numbers), Netcode (LAN inside the game).

**Orb's actions in this milestone.** Create the itch.io account and restricted page and install its upload tool, in one sitting with Tools' checklist open. Set up the private report server. Ask two friends with Decks. Record one line approving desktop test builds for named testers once the gates are green.

---

## A3. The fight's new rules, and LAN inside the game

**Goal.** In one normal match a player aims a beam with the stick and the other dodges it by moving off its line, both signatures fire from Orb's inputs, stamina, energy and body work as one loop, the pull into a close fight exists, and a second PC joins from a Host or Join row instead of a folder of shortcuts.

**Why third.** These are the blockers with the widest reach: the move table needs the signature inputs and the energy loop; transformations need the energy loop; the computer's play, the balance bands and every later measurement sit on these rules. They share one golden window so the fingerprints move once. They are attacked here, not later, because if the beam rework or the gravity well is twice its class, the Alpha's date moves, and it is better to know in week 5 than in week 10.

**What Orb can play.** The first build with new rules to press. Solo and two players on one PC as before; LAN 1v1 with Orb 2 started from the menu, with rematch and "back to menu".

**PLAY THIS would say.** New: hold the right stick to aim a beam; it now flies through space and you can get out of its way by moving. RT + RB + a flick of the right stick is the energy signature; RT + a flick is the martial one. There is a stamina number: plain face-button blows refill it, specials and signatures spend it, and low stamina makes injuries worse. Up close, the two fighters are drawn together. On two PCs, one presses Host, the other Join. Try: dodge three beams by flying off the line at near, middle and far range; throw both signatures; fight with stamina empty and see what a hit does; get a transformation (the game now tells you the buttons); knock someone into a building and see whether they still bounce back like a ping-pong ball; play three LAN matches in a row without closing the game, then pull the network cable.

**Exit criteria.**
- X-16 (must pass): a scripted defender's sidestep makes the beam miss at three ranges.
- X-17 (must pass): beams and signatures from any input other than Orb's: 0, for the player and for the computer, on the scripted set and on play files saved on this build.
- X-15 (must pass, in the resized form below): one page states the model; every energy, stamina and body number is data per fighter; the count of fighter-specific code in those systems is read here and must be zero from A4; no health bar; a still set shows health, energy and readiness can be read from the fighter at speed.
- X-13, partial (must pass for: a lap, each stance, a beam aimed and dodged, both signatures, a launch, the gravity well's pull, a crater, a building damaged, bystanders scattering). The transformation line is first required at A4.
- X-14, first reading with the new check: the crater-width ratio between the top and base tier, and the skid trench growing with tier. Must pass at A4.
- X-08 for LAN 1v1 (must pass, two Windows PCs, Orb and Orb 2): five full matches with no state mismatch, rematch and leave work, a pulled cable shows a plain notice on both PCs inside the agreed time, and every status is on screen and not in the window's title.
- X-05, partial (must pass): the mode smoke suite passes for solo, two on one PC and LAN 1v1 on Windows, and for solo and two on one PC on Linux.
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
- **ui-ux:** A-ENERGY-07, A-ENERGY-08
- **vfx:** A-RENDER-13
- **world-environment:** A-WORLD-03, A-WORLD-04, A-WORLD-06, A-WORLD-07, A-WORLD-10

**Golden window GW2, "The fight's rules".** A-COMBAT-01, A-COMBAT-02, A-COMBAT-03, A-CONTROLS-05, A-ENERGY-01, A-ENERGY-03, A-ENERGY-10, A-WORLD-03, A-WORLD-04, A-WORLD-07, A-WORLD-10. The terrain rows ride in this window because World and Rendering are free while the fight teams work, and one re-recording covers both.

**Tokens.** 53M (1 XL, 7 L, 8 M, 11 S). **Weeks.** 3 to 5. This is the milestone most likely to overrun; see the stop rule under the risks.

**Directors active.** Encounter Systems, Simulation & Engine, Game Design, Controls & Game Feel, World & Environment, Rendering, Camera, VFX, UI & UX, Netcode, QA & Balance, Legal (the LAN ruling), Performance & Platform. Working ahead for A4: Combat & Choreography on the move table from the day the signature inputs are fixed; Game Design on the horde page from S3.

---

## A4. Horde, teams, your own planet, the whole fighter

**Goal.** All eight modes less the campaign can be started from the menu with a pad, played to a result, rematched and left; each fighter has a complete move table at the Alpha's bar and two forms beyond base.

**What Orb can play.** Horde for one or two players; couch 2v2 (two people as a team against two computer fighters) and 2v2 alone with a computer partner; LAN 2v2 where all four fighters are seen together when the fights are near; a planet set up from a seed and three dials; every button row doing its own thing.

**PLAY THIS would say.** New: a Horde mode, where weak enemies arrive in waves and come back, for one or two players, ending in a result screen. A computer partner, so you can play 2v2 alone. Custom planet: pick a seed, how many cities, the climate and how much water. Each fighter now changes body as well as aura when transforming, twice. Holding LB, RB, RT or LT with a face button now gives a different move from the plain press. Try: last eight minutes in Horde alone, then with a second pad; make a dry planet with one city and check the second PC gets the same planet; with each fighter press every held button with X, Y, B and A (tap, mash, hold) and write down any that feel the same or do nothing; reach both forms with both fighters.

**Exit criteria.**
- X-05 (must pass on Windows and Linux): the smoke suite starts, finishes, rematches and leaves every mode Alpha ships (LAN modes on Windows; on Linux by the two-program check in CI).
- X-02 (must pass on this commit before the build reaches a friend), with a clip of the largest horde wave added to the standard clip set.
- X-10 (frame record must pass on Orb's PC; run length is a first reading here and must pass at A5): a horde run of 5 to 10 minutes with waves, respawn and a result screen; the frame record at the largest wave holds 60. The Deck's reading of the same wave is asked for by bench file and judged at A6.
- X-09 (must pass): the supported line-ups are written down and each one is played from the menu.
- X-08 for LAN 2v2 (must pass): five full matches, both forms of 2v2, on two real PCs.
- X-04 (must pass): a scripted match reaches each form for each fighter; one still per form; a blow in flight when a transformation starts is handled the written way.
- X-03 (must pass at the Alpha's bar; see the resize; its probe has existed since A1): the pad-driven coverage probe finds no cell without an outcome, and no duplicate inside the rows the bar names.
- X-13 (must pass in full, on scripted matches).
- X-14 (must pass). X-11, the dials: the same seed and choices give the same planet on both LAN PCs; the Windows-against-Linux comparison is first required at A5, once its check has run in CI.
- X-15, the third-fighter line (must pass in the resized form): the count of places in the code that name exactly two fighters is recorded, cannot rise, and is zero in the energy, stamina, body and forms systems.

**Gap ids closed, by owner.**
- **animation:** A-ANIM-03
- **art:** A-ANIM-01, A-ANIM-02
- **combat-choreography:** A-COMBAT-04
- **controls-feel:** A-CONTROLS-01
- **encounter-systems:** A-AI-01, A-AI-06 (nice), A-AI-08, A-AI-09
- **game-design:** A-COMBAT-06, A-MODES-02
- **netcode-online:** A-NET-06
- **qa-balance:** A-QA-06
- **rendering-techart:** A-MODES-03, A-MODES-09
- **simulation-engine:** A-CODE-05, A-COMBAT-12
- **world-environment:** A-WORLD-02, A-WORLD-09

**Golden window GW3, "Many bodies and the full fighter".** A-AI-01, A-AI-06 (nice), A-AI-08, A-AI-09, A-CODE-05, A-COMBAT-04, A-COMBAT-06, A-COMBAT-12, A-MODES-02, A-WORLD-02.

**Tokens.** 57M (2 XL, 6 L, 5 M, 6 S); about 10M less with the smaller versions below. **Weeks.** 2 to 3.

**Directors active.** Game Design, Encounter Systems, Combat & Choreography, Simulation & Engine, Rendering, Camera, World & Environment, Controls & Game Feel, Art, Animation, Netcode, UI & UX, QA & Balance, Tools & Pipeline.

---

## A5. A newcomer on a Deck, alone; the last numbers settle

**Goal.** Someone who has never seen the game installs it from the itch.io page with a key, reads the notice, picks a mode, a fighter and a planet, plays, rematches, changes a setting that is still there next time, and sends a report, with only the tester guide and the Deck's own controls. The last tuning of numbers (difficulty, a right-stick-only player, match length) lands at the end of this milestone, so the candidate that follows is frozen.

**Why here and not earlier.** The risky halves of the newcomer's path (does it install, does it run, can a pad work every screen, does the report leave the machine) were proven at A2. What is left is words, stills and one picture-quality picker, and those are best written once the menus stop changing at A4.

**What Orb can play.** The dress rehearsal: Orb installs on the second PC from the real itch.io page with a real key, following the guide and nothing else.

**PLAY THIS would say.** New: no rules have changed since the last build. Numbers have: Easy is easier for someone playing your way, a player who uses only the right stick can win, and matches run 6 to 8 minutes (so replays from the last build stop verifying, for the last time). The tester guide and checklist are finished. How-to-play describes what is actually on screen. The match-over panel no longer covers your fighter's corner. A picture-quality setting that does something, with a Deck default. Craters and trenches are drawn where you stand. A quiet background sound, and sounds for buildings and menus. "(working title)" beside the name. Try: be the tester. Follow the guide from a blank PC and mark every place you had to guess. Mark the short list of about 150 lines of text a tester meets. Change the quality level and the controls, restart, and check they held.

**Exit criteria.**
- X-02 (must pass on this commit before the build goes on a channel a friend holds a key to).
- X-18 and X-19 (must pass as a rehearsal by Orb and Orb 2; the real pass is at A6, by two held-back newcomers if Orb has them): install and first match from the guide alone.
- X-22 (must pass): the 1280 by 800 sweep finds no clipped or overlapping text and nothing under 9 px; 12 px is the aim.
- X-20 (must pass, quality level included). X-21 and X-32 (must pass): Legal's sign-off row for each paper a tester meets; privacy words the same in the package, the game and the note.
- X-11 (must pass): the planet fingerprint matches between Windows and Linux in CI.
- X-12 (recorded): the campaign decision is written with its reason.
- X-31 (must pass with the real build): the A5 build is on the itch.io page on both channels and has been updated once and rolled back once.
- X-34: the shot list has rendered from A1 to A5 and the five sets sit side by side.
- X-06 (must pass here, re-read on the candidate): win-rate bands at each difficulty for a scripted player on Orb's scheme, with enough matches per cell to tell neighbouring bands apart; the balance band between the two fighters re-read in the same window.

**Gap ids closed, by owner.**
- **audio-music:** A-AUDIO-02
- **community-marketing:** A-MARKET-08
- **game-design:** A-AI-02, A-QA-05
- **legal-ip:** A-TEXT-04 (nice)
- **qa-balance:** A-QA-01, A-QA-08
- **rendering-techart:** A-RENDER-05, A-RENDER-06, A-WORLD-05
- **tools-pipeline:** A-MARKET-05, A-MARKET-06, A-SAVES-08 (nice)
- **ui-ux:** A-TEXT-03, A-UI-05, A-UI-08

**Golden window GW4, "Numbers only".** A-AI-02, A-QA-05, A-QA-08, at the end of the milestone. Data values only; no rule may change in this window. If a rule has to change, it is priced as a scope change.

**Tokens.** 16M (2 L, 2 M, 12 S). **Weeks.** 1.5 to 3.

**Directors active.** QA & Balance, UI & UX, Rendering, Audio, Tools & Pipeline, Legal, Narrative & Fighter Identity (the text Orb marks), Community & Marketing, Performance & Platform, Game Design and Encounter Systems (the numbers window).

---

## A6. The Alpha candidate, frozen

**Goal.** One commit passes every criterion from X-01 to X-34, two friends complete the checklist on their Steam Decks, and the feature freeze begins.

**What Orb can play.** The candidate, exactly as the testers get it.

**PLAY THIS would say.** New: nothing. This is the A5 build with what the checks and your friends found fixed. Try: one match at each difficulty and say whether Easy, Medium and Hard feel like three different things; one run of each mode. This is the build your friends get. After this build, new ideas go in the ideas log.

**Exit criteria (all must pass on the candidate's commit).**
- X-01: two outside testers on Steam Decks return signed checklists. X-35 (proposed): no open bug of the top severity on the candidate, and every open bug of the next severity seen by Orb and carried by name.
- X-02: every gate green, records saved for this commit.
- X-06: win-rate bands at each difficulty for a scripted player on Orb's scheme (Easy 60 to 80%, Medium 35 to 55%, Hard 10 to 30%), with enough matches per cell to tell neighbouring bands apart; team and horde bands from QA's new scripts.
- X-23: 60 frames a second held on Orb's PC, no frame over 50 ms outside loading. X-24: the agreed Deck figure held, from a tester's bench file. X-26: loading under 15 s on Orb's PC and 30 s on the Deck.
- X-25: two hours of computer against computer on Windows and on Linux (and on one friend's Deck) with no crash, hang or script error and memory growth under 10%.
- X-27, X-28, X-29, X-30, X-31, X-32 re-read on the candidate; for X-27, a replay saved by the Linux build verifies on the Windows build. X-33: the freeze is recorded. X-34: the candidate's shots are in the archive.
- X-03, X-04, X-05, X-13, X-14, X-16, X-17 re-run on the candidate's commit (the numbers moved at the end of A5).

**Gap ids closed, by owner.**
- none: no register row closes here; the milestone is verification and people.

**Golden window.** None. Rules and numbers are frozen from the end of A5. A fix that would change the sim's fingerprint sends the candidate back to A5's window, and that is said out loud.

**Tokens.** 13M (verification runs, the soak, the bands, the shot set: about 5M; a fix reserve of 8M for what the candidate's checks and the second tester round find). **Weeks.** 2.5 to 5, set by people: two friends' time, and one round of fixes from what they find.

**Directors active.** QA & Balance, Game Design, Encounter Systems, Performance & Platform, Tools & Pipeline, Legal and Accessibility (the gate re-read), Production Operations (the freeze).

---

## Rows proposed smaller for Alpha

These are proposals to Orb, not decisions: the budgets above use the register's full classes, so the plan still holds if Orb declines every one (about 19M tokens and one to three weeks more than if all are accepted). None is dropped. Each stays in its milestone at a smaller size, with the remainder named as after Alpha. Budgets above use the register's classes; the saving if all are accepted is about 19M tokens (the gravity well and the horde keep their classes in the budget until spikes S2 and S3 report).

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

## Exit criteria this audit proposes to change

The specification marked several numbers "proposed" and asked the audit to confirm or change each from the records. These are the changes, in one place. Each is a proposal for Orb and the Executive Producer to confirm; until then the specification's wording stands.

| Criterion | The specification's wording | Proposed | Why |
| --- | --- | --- | --- |
| X-03 | A distinct, reachable outcome for every cell: five held buttons by four face buttons by three ways of pressing, plus the right stick | For Alpha: no cell without an outcome; the martial and energy rows complete and distinct for each fighter; the LB, LT and RT rows may share entries where the design page says so. The full table at Beta | 18 of 101 cells have no outcome and 65 repeat another (A-COMBAT-04); the full table is the largest content job on the critical path |
| X-05 | Each of the eight modes from the menu on Windows and Linux | Seven modes (no campaign, X-12); the two LAN modes on Windows by play and on Linux by the two-program check in CI | Follows the campaign and LAN recommendations |
| X-08 | A pulled cable shows a notice within 5 seconds; two PCs | Within 10 seconds, keeping today's 8-second rule; two Windows PCs, Orb and the trusted second player | The 5 was a starting point; 8 is built and tested in CI (A-NET-03) |
| X-10 | Weak enemies in waves, a run of 5 to 10 minutes | The same, with at most three weak bodies at a time inside today's five-body limit, unless spike S3 shows more is cheap | Raising the limit touches the sim, the camera and the Deck's frame rate at once |
| X-11 | The player picks size, city count, climate and water | A seed and three dials (city count, climate, water) at today's one size | Sizes need a frame-rate study that does not exist (A-WORLD-08) |
| X-15 | Energy, stamina and health; a third fighter needs data and art only | Read as including stamina and the body number (Orb, 2026-11-13). The third-fighter line: zero fighter-specific code in the energy, stamina, body and forms systems, and the count elsewhere recorded and unable to rise | 365 places name exactly two fighters today; four fighters is Beta's bar |
| X-21 | The report fits Discord's free upload limit | Under 10 MB, clips separate | Discord's own pages give 20 MB and 10 MB (`02-areas/web-checks.md`); 10 holds either way |
| X-22 | Smallest text 9 px at 1280 by 800 | 9 px is the floor that fails the sweep; 12 px is the aim | Valve's Deck guidance gives 9 as the minimum and recommends 12 (`02-areas/web-checks.md`) |
| X-24 | 30 frames a second held on the Deck, 40 as the aim | Unchanged for now; confirmed or changed by Orb after A2's real reading | Nothing has ever been measured on a Deck |
| X-04 | At least two forms beyond base each | Unchanged in number; what a form changes on the body is decision 17 | The area review found forms change only the aura today (A-ANIM-01) |
| X-14 | The same blow at the top tier makes at least 3 times the crater width | Decided on A3's reading, before golden window GW2 closes: keep 3 times, restate it as the WORLD review proposes (`02-areas/WORLD.md`), or tune; which two levels are compared is written down | The review's ratios were read with the energy model off; A1 turns it on |
| X-17 | No beam without the right stick, apart from the signature inputs Orb named | At A1 and A2 only, RT + B is allowed as the one interim signature input, because Orb's named inputs are built in A3; from A3, as written | A named, temporary reading, shown to Orb |
| X-23 | 60 frames a second held in a normal match on Orb's PC, no frame over 50 ms | As the PERF review proposes (`02-areas/PERF.md`): read on the desktop program over a whole match, with a limit on the slowest one in a hundred frames | The only frame records are of the browser build |
| X-26 | Loading under 15 s on Orb's PC and 30 s on the Deck | A first start after install: 30 s on Orb's PC and 60 s on the Deck; every later start: 15 s and 30 s | The PERF review found a first start cannot meet 15 s (`02-areas/PERF.md`) |
| X-35 (new) | none | No open bug of the top severity on the candidate; every open bug of the next severity seen by Orb and carried by name | No exit line read the bug list, so a candidate could pass with severe bugs open |

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

Four fighters (Beta's bar). Online play. Mac. Mobile. Modding. The full campaign, and any campaign at all (X-12: none at Alpha; the horde carries co-op). The Steam page, fee and demo. Photo mode and a hide-the-HUD setting. Music. The sound toolset. The terrain overhaul with a tessellation engine. The "High Intensity" switch on RT, the taunt before a signature, walking into a beam, punching up a beam. World sizes. The full move table, the far half of the gravity well, bigger horde waves, four pads on one PC, LAN for outside testers and LAN on a Deck (the remainders in the resize table). Windows code signing.

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

**During the push (A1 to A6).**
1. Every new idea, Orb's or anyone's, goes into the ideas log the day it is said, in the speaker's words, with a date.
2. Within one working day the Executive Producer adds one recommendation: **now**, **at the next milestone** (named), or **after Alpha**; with a size class and whether it changes the sim's fingerprint.
3. Nothing from the log is built until Orb has seen that line and said yes. Nothing is built silently, including by a director who thinks it is small. "Workshop this" means a page or a toy, not a change to the game.
4. "Now" is allowed only if all three hold: it fits inside a row already open in the current milestone; it does not change the fingerprint, or the milestone has an open golden window that takes rule changes (GW2 in A3, GW3 in A4); and its cost comes out of that milestone's budget, with the row it displaces named. After GW3 closes, an idea that changes a rule waits for after Alpha.
5. A milestone's row list changes only at its start. If something comes in mid-milestone, something of the same size goes out, and the PLAY THIS page says which.
6. Testers' findings follow the same rule, with one difference: a finding that stops a newcomer step (cannot install, cannot start, cannot finish a match, cannot report) is fixed in the current milestone without waiting.

**Each spike's page counts as a change request.** If a spike says a row is a class bigger than the register thought, the Executive Producer brings Orb the choice (the smaller version, a later date, or something else moves out) before the row starts.

**After A4** no rule changes are taken at all; A5 is words, pictures and a last numbers window; A6 is frozen.

**After the freeze (the day A6 passes).** A new idea is either logged for after launch, or brought to Orb as a scope change with its cost in tokens, weeks and golden windows, and what it would re-open. Only Orb lifts an idea in. Fixes to things that are broken, tuning inside the data's existing shape, and polish that passes the look gate are not scope changes and carry on.

**Standing exception.** Anything that touches a player-safety gate, a Legal flag, spending or something public stops and goes to Orb as one plain question, as today.

First entries the log should hold on day one, from Orb's answers of 2026-11-13: the absorb (hold LB, time RB), recommended at the next milestone only if the stamina loop's first measurement is in, otherwise after Alpha; flinging debris; the power-up contest as a mid-fight event; slipstream; a right-stick flick that sends a dashing attacker flying; the wind-up throw; synergy abilities for co-op. All recommended after Alpha except the first.

## The critical path, and the three risks

**The chain that sets the earliest Alpha.**

1. Commit or deliberately ignore the working tree (A-PROCESS-03), then move the played build's patches and ten groups of switches onto main (A-CODE-03 and the rows A-CODE-01 needs), then A-CODE-01 itself and a golden record for it (A-CODE-02). Nothing else can land with confidence before this.
2. The one-command desktop build (A-TOOLS-01, which also needs A-LEGAL-02).
3. The model page (A-ENERGY-02), then the stamina, energy and body loop (A-ENERGY-01) and the signature inputs (A-COMBAT-02), in GW2.
4. The move table (A-COMBAT-04), which needs both, with transformations (A-COMBAT-06) beside it, in GW3.
5. Tuning on the finished rules (A-AI-02, A-QA-05, A-QA-08), in GW4 at the end of A5.
6. The candidate's long checks (the soak, the bands) and two friends' Deck sessions (X-01).

Two chains run beside it and are nearly as long: the build to the itch.io rehearsal to the tester guide to the testers (A-TOOLS-01, A-TOOLS-02, A-QA-01, X-01); and the mode list to the horde to its computer control to QA's team and horde bands (A-MODES-01, A-MODES-02, A-AI-01, A-QA-06). The safety chain (A-LEGAL-01 and A-LEGAL-08, then A-LEGAL-03, then A-PERF-01 on a real Deck) is not on the path to the candidate's date but is on the path to learning the Deck's answer, which is why it is second.

**One director's queue sets the date.** Encounter Systems holds the computer opponent's switch rows in A1, the beam and the signatures in A3, and the horde's enemies and the computer partner in A4, and it serves the bands in A5: five links of the chain. If the Executive Producer can run only one thing at full attention, it is that queue (the load table below shows it).

**The three risks most likely to move the date.**

1. **Main cannot simply be made into the game Orb plays.** 72 switch rows, patches that exist only in a preview tool, a golden record valid only with the switches off, and gates that have never run on the played configuration. Turning it all on is likely to turn checks red that nobody has looked at, and the measurements on the globe ground already fail. If this takes three weeks instead of one and a half, everything moves by the difference. Guard: land row by row, each with its own gate run; nothing from A3 lands until GW1 is closed; the Executive Producer reports the count of rows still differing every two days.
2. **The Steam Deck says no to something.** A shader the driver rejects, a frame rate well under 30, text too small at 1280 by 800, or the Deck's controls not arriving as a pad. Any one can add a milestone of rendering work or lower a target Orb has to agree to. Guard: S5 in A1, the real session in A2, a bench file asked of the same friend at A3 and A4 (five minutes each), and the Deck's default quality level built at A5 from real numbers.
3. **The fight rework is a class bigger than estimated.** The beam, the signature inputs, the stamina loop and the gravity well all change the same exchange code in the same window, and the beam struggle, the answers to a beam and the computer's beam play all hang off the old form. Guard: S1 and S2 before any of it starts; each lands behind its own switch with its own probe; and a stop rule: if the gravity well's first cut is not playable at the midpoint of A3, A3 ships its size and zones only and the snap moves to GW3, without holding the beam or the stamina loop.

Watched but not in the three: the outside-tester gate list not going green on the globe ground that every played build uses (briefed on day one of A1 for that reason; if it is still red at the end of A2, the Deck session waits, and that is the one case where a tester's date moves for safety); the horde on a Deck (sized by S3, bounded by the three-body proposal); the wait for people (two friends, twice); and the year-end holidays.

## The decisions that are Orb's, most urgent first

Each has one recommendation. **Every row needs Orb's yes; none is taken by silence.** Ten need thought, and Orb's page leads with those; the rest are likely a one-word answer. The ten: 7 (desktop test builds, and which two friends), 8 (the report channel), 9 (the itch.io page), 10 (the licence line), 12 (does your stick move only you up close), 13 (who plays LAN at Alpha), 15 (the move table's bar), 16 (the horde's first size), 18 (no campaign at Alpha), 19 (the frame-rate targets). Added by the adversarial review, and on Orb's page: can Orb find two more Steam Deck owners to hold back as true newcomers for A6, and a third early tester; and may the stop rule for the pull into a close fight apply without asking again.

**By the milestone that needs each answer:** on day one of A1, 1 to 6, with 11 to 15 and 18 asked at the same time so the spikes and the menu know what to do; before A2 can close, 7 to 10; before A2's work-ahead starts, 11 to 14 confirmed from the spikes' pages; before A4 starts, 15 to 17; before A5, 18 to 22; at A6, 23.

| # | Decision | Recommendation | What it blocks |
| ---: | --- | --- | --- |
| 1 | May the team make the 9 November build the default game on main, row by row, before any new feature work? | Yes. | All of A1, and so everything |
| 2 | The default world: one fixed planet, or a new random planet each match? | A new random planet each quick match, the seed shown and saved in reports; one fixed planet for a newcomer's first match and for tests. | A-WORLD-01 and A-WORLD-14 in GW1 |
| 3 | Do the globe ground, the crater look with the black fill removed, and the meteor trail become the defaults? And is the terrain workshop of 2026-11-09 part of Alpha? | Yes to the defaults. The workshop is after Alpha; Alpha gets craters and trenches drawn where you stand. | A-RENDER-01 and A-RENDER-04 in A1; A-WORLD-05 in A5 |
| 4 | Which build do new looks get compared against? | The 2026-11-09 globe build, with its known picture faults listed as not part of the reference. | The look gate for every visible change from A1 on |
| 5 | Flight speed 3500 as the default in every mode, with the slider dropped until a real setting exists? | Yes. | A-CONTROLS-04 in GW1 |
| 6 | The backburnered hero and villain meters: off, folded in, or retired? | Keep the comeback as a rule for every fighter, set every other effect to zero in data now, remove the code after Alpha. | A-ENERGY-05 in GW1 |
| 7 | May the team make desktop test builds for named testers, and which two friends with Decks do a first 30-minute session? | Yes, Windows and Linux; ask two friends now. The one-line approval is recorded when the gates are green and not before. | A2's Deck session, the largest unknown |
| 8 | The report channel. | A new private server (not the converted one), a channel locked to a tester role, and keep the promise to delete a tester's reports on request. One small file per report, clips left out. | A-LEGAL-07, A-TOOLS-05 in A2 |
| 9 | The itch.io page: may a restricted, key-only page go up under the working title before the paid title search, and will Orb do the account, the page and the upload tool? | Yes if Legal writes that it is unlisted and unpromoted; one key per named friend; Orb does the three actions in one sitting. If Legal's ruling is no: the page goes up under a neutral placeholder name Legal screens, or Orb is asked about bringing the paid search forward. | A-LEGAL-09, A-TOOLS-02 and the A2 rehearsal |
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

## Each director's load, by milestone

Tokens of lead work at the register's size classes (supporting work on another director's row is not counted, and neither are spikes, gates or reviews). A director with more than about 10M in one milestone is unlikely to land it all in that milestone's weeks in one session: the Executive Producer either starts that work a milestone early behind a switch, as the milestones above say, or the milestone takes the top of its range.

| Director | A1 | A2 | A3 | A4 | A5 | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| tools-pipeline | 14.5M | 8.4M |  |  | 0.8M | 23.8M |
| rendering-techart | 2.6M | 3.1M |  | 8.0M | 8.2M | 22.1M |
| game-design | 0.8M |  | 4.0M | 12.0M | 1.4M | 18.2M |
| encounter-systems | 1.5M |  | 9.4M | 6.7M |  | 17.6M |
| simulation-engine | 2.9M |  | 9.4M | 4.2M |  | 16.6M |
| world-environment | 1.2M |  | 9.7M | 4.2M |  | 15.1M |
| netcode-online |  |  | 12.3M | 0.2M |  | 12.6M |
| camera | 0.2M | 8.5M | 1.2M |  |  | 9.9M |
| ep | 8.7M | 0.2M |  |  |  | 8.9M |
| combat-choreography | 0.2M |  |  | 8.0M |  | 8.2M |
| ui-ux | 4.9M | 1.5M | 0.5M |  | 0.8M | 7.6M |
| qa-balance | 4.2M | 1.4M |  | 1.2M | 0.5M | 7.3M |
| controls-feel | 2.4M | 0.5M | 0.2M | 1.2M |  | 4.3M |
| performance-platform | 0.8M | 2.6M |  |  |  | 3.4M |
| legal-ip | 0.2M | 1.0M | 1.2M |  | 0.2M | 2.7M |
| audio-music | 0.2M | 0.5M |  |  | 1.2M | 1.9M |
| art |  |  |  | 1.4M |  | 1.4M |
| orb | 0.5M | 0.2M |  |  |  | 0.8M |
| production-ops | 0.8M |  |  |  |  | 0.8M |
| accessibility-localization |  | 0.2M |  |  |  | 0.2M |
| vfx |  |  | 0.2M |  |  | 0.2M |
| animation |  |  |  | 0.2M |  | 0.2M |
| community-marketing |  |  |  |  | 0.2M | 0.2M |

Loads of 10M or more in one milestone: tools-pipeline in A1 (14.5M); netcode-online in A3 (12.3M); game-design in A4 (12.0M).

## Checks

Run by the auditor's script against `03-gap-register.json` after the grafts, 2026-11-13: 270 rows; 175 required, 175 of them in exactly one milestone (A1 77, A2 41, A3 27, A4 19, A5 16, A6 0); missing 0; placed twice 0; rows marked after Alpha that are placed: 0; rows placed before a row they need: 0; rows that need an unplaced row: 0; rows that change the fingerprint, by milestone: A1 12, A2 0, A3 11, A4 10, A5 3, A6 0 (all inside the four named windows; A2 and A6 hold none). 180 rows placed in all (5 nice). The rows on the one topic kept off Orb's page are planned like any other and no question about them appears in the decisions table.

One register link was removed while writing this page: A-CONTROLS-06 (the move coverage probe) no longer "needs" A-COMBAT-04 (the move table). The scorer pointed out that a probe which presses every cell can be written against today's table, and it must exist before the table is rebuilt to show the table getting better. The register row was edited to match.
