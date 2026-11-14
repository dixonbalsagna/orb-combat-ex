# Path to Alpha, draft: newcomer first

Planner draft for the judgment session, 2026-11-13. Baseline 8901d351. Built from `03-gap-register.json` (270 rows: 174 required, 74 nice, 22 after). One of three drafts written from different angles; this one has not seen the others.

## The angle and the pace

**The angle.** The Alpha's hardest test is not Orb's: it is a friend with a Steam Deck who installs from a guide, starts the game, plays, and sends a report with nobody beside them. Nothing on that path has ever been tried: no Linux build has drawn a picture, no desktop build can be made from main, no tester guide exists, and a plain desktop build saves no report. So this path makes the game safe to hand out first (A1), then puts a real build in two outside testers' hands at the **second milestone of five** (A2) with one mode, solo against the computer, working end to end on the Deck. Every later milestone reaches the same testers as an update through the same page, so what they find shapes the modes (A3), the fight (A4) and the candidate (A5), and the update and roll-back routes are exercised four times before the candidate depends on them. The price is plain: the big fight work (beams, signatures, the gravity well, stamina) closes late, at A4. To keep that from setting the date, its design decisions are asked of Orb in A1 and its builders start behind switches while A2 and A3 land.

**Pace assumption (one line).** About 20 to 30 million tokens of register work land in a week: roughly a third of the weekly allowance at the meter rates this audit measured (about 1 point per 1M tokens on the cheaper models most directors use, 1.6 on the largest), with the rest going to the Executive Producer's review, the gates, rework and Orb's own asks. The record behind this is thin (one planned night of about 13M tokens; one week that reached about 82%), so every week count below is a range, and the first job of A1 is to start a weekly token record (A-PROCESS-08) so A2 onward can be re-planned on real figures.

**Token budgets** come from the rows' size classes: S about 0.25M, M about 1.2M, L about 4M, XL about 8M. These are size classes with no comparables, not quotes. Where this draft resizes a row, the new class is used and the row is marked.

**People time** is counted separately from tokens: Orb plays each milestone's build (allow 2 to 4 days for the play and the answers), and the two Deck friends test twice (allow 1 to 2 weeks each time; they are volunteers).

| Milestone | What it is | Required rows closed | Tokens | Weeks |
| --- | --- | ---: | ---: | --- |
| A1 | Safe to hand out, and the same game Orb plays | 62 | 37.2M | 2 to 3 |
| A2 | First Deck round: a friend installs, plays solo, reports | 51 | 23.8M | 1.5 to 2.5, then tester round 1 (1 to 2 weeks, overlapping A3) |
| A3 | Every mode starts and ends | 35 | 48.6M + 6M reserve for round-1 fixes | 2.5 to 4 |
| A4 | The whole fight | 23 | 53.2M | 3 to 4 |
| A5 | The Alpha candidate | 2 | 1.4M + 8M reserve for verification and round-2 fixes | 2 to 3, including tester round 2 |
| **Total** | | **173** (1 more proposed to move after Alpha) | **about 178M** (164.2M of rows + 14M reserve) | **11 to 16 weeks** |

Outside testers first play at the end of A2: about week 4 to 6.

---

## A1. Safe to hand out, and the same game

**Goal.** Main holds the game Orb played on 9 November as its default, one command makes Windows and Linux desktop builds of it, and every gate on the "before an outside tester plays" list is green on that commit.

**What Orb can play.** A Windows desktop build made by the build command from main, with no launch words and no private page.

**PLAY THIS would say.**
- New: this is the 9 November game, now the default (globe ground, the left-hand panel menus Orb picked, known as the Rail, the swing camera, the sounds). Flight speed is 3500 everywhere. The pause menu appears. The two stray beams are fixed. Easy is tuned for someone playing with right-stick attacks and LB guard. A version number shows on the menu. If the game dies it leaves a file saying why.
- Try: pause with Start and move through the menu with the pad. Brawl with the face buttons for a minute without touching the right stick; no beam should fire. Hold RT, wait two seconds, then press B. Play three matches on Easy. Look at one fresh crater: the black, flat-brown fill should be gone.

**Exit criteria.**
- X-02: the list of outside-tester gates exists (Legal, Accessibility, Tools) and every gate is green on the A1 commit, each with a saved record under `docs/*/runs/<sha>/`.
- X-29: one command (and one CI run) makes the Windows and Linux desktop builds, solo game included, stamps a version number the game shows, and writes a changelog entry.
- X-28: a forced-crash test on Windows and on the CI's Linux leaves a file that says why.
- X-27 (first half): a replay carries its build id; a replay from another build is refused with a plain message.
- X-17 (the two known cases): QA's replay of Orb's 9 November match fires no beam at ticks 5220 and 6617.
- X-06 (Easy only): the scripted player using Orb's scheme wins 60 to 80% of 40 matches on Easy, read from the build's own packed data.
- X-33: the change-control rule and the ideas log exist and the Executive Producer's playbook points to them.
- Main equals the played game: the switch table shows no row where main differs from the A1 build; a golden record (the saved match fingerprints the checks compare against) exists for that configuration.

**Gap rows closed (62 required).**
- **Executive Producer:** A-ACCESS-04 (S), A-ANIM-06 (S), A-CODE-01 (L), A-PROCESS-02 (S), A-PROCESS-03 (M), A-PROCESS-06 (S), A-PROCESS-07 (S), A-PROCESS-08 (S), A-PROCESS-09 (S), A-PROCESS-10 (S), A-PROCESS-11 (S), A-PROCESS-13 (S), A-PROCESS-14 (S), A-PROCESS-15 (S), A-PROCESS-16 (S), A-RENDER-07 (S), A-RENDER-11 (S)
- **Tools & Pipeline:** A-CODE-03 (M), A-LEGAL-02 (M), A-LEGAL-08 (M), A-MARKET-04 (S), A-TOOLS-01 (L), A-TOOLS-04 (M), A-TOOLS-07 (S), A-TOOLS-08 (S), A-TOOLS-10 (S), A-TOOLS-15 (S)
- **Encounter Systems:** A-AI-05 (S), A-COMBAT-05 (S), A-COMBAT-11 (S), A-MODES-07 (S)
- **Game Design:** A-AI-02 (S), A-COMBAT-15 (S), A-CONTROLS-04 (S), A-ENERGY-02 (S)
- **QA & Balance:** A-AI-04 (S), A-QA-03 (S), A-QA-07 (S), A-QA-09 (S)
- **Simulation & Engine:** A-CODE-02 (M), A-ENERGY-04 (S), A-ENERGY-05 (M), A-NET-05 (S)
- **Camera:** A-CAMERA-01 (S), A-CAMERA-02 (S), A-LEGAL-01 (L)
- **Production Operations:** A-PROCESS-01 (S), A-PROCESS-04 (S), A-PROCESS-05 (S)
- **Rendering:** A-RENDER-01 (M), A-RENDER-04 (M), A-UI-03 (S)
- **UI & UX:** A-MODES-15 (S), A-SAVES-02 (S), A-UI-01 (S)
- **Legal:** A-LEGAL-03 (S), A-TOOLS-06 (S)
- **Accessibility:** A-ACCESS-01 (S)
- **Audio:** A-AUDIO-01 (S)
- **Combat & Choreography:** A-COMBAT-14 (S)
- **Controls:** A-CONTROLS-02 (M)
- **World:** A-WORLD-01 (M)

**Golden window 1, "Orb's game is the default".** Opens when the switch rows flip and closes with new golden records at the A1 commit. Rows: A-CODE-01, A-AI-02, A-AI-05, A-CONTROLS-02, A-CONTROLS-04, A-ENERGY-04, A-ENERGY-05, A-MODES-07, A-WORLD-01, A-COMBAT-05, A-COMBAT-11, A-COMBAT-14. Replays saved before A1 stop verifying; from A1 on a foreign replay is refused in plain words (A-NET-05).

**Token budget.** 37.2M (3 L, 11 M, 48 S). Tools & Pipeline carries about 10M of it and is the director to watch.

**Weeks.** 2 to 3, including Orb's play.

**Directors active.** Accessibility, Audio, Camera, Combat & Choreography, Controls, Encounter Systems, Executive Producer, Game Design, Legal, Production Operations, QA & Balance, Rendering, Simulation & Engine, Tools & Pipeline, UI & UX, World.

**Started here, closed later.** With Orb's fight decisions in hand (see the decisions list, items 9 to 12), Game Design writes the stamina, energy and body page in A1 (A-ENERGY-02) so Simulation can begin the gravity well behind a switch during A2.

---

## A2. First Deck round

**Goal.** A friend with a Steam Deck installs the game from the tester guide alone, reads the notice, picks a mode, a fighter and a planet, plays a full solo match, changes a setting that is still there after a restart, and sends Orb a report in one press.

**What Orb can play.** The Windows and Linux builds downloaded from the restricted itch.io page with a key, exactly as a tester gets them. Two outside testers on Steam Decks get the same build (tester round 1).

**PLAY THIS would say.**
- New: a mode row on the start menu (solo against the computer at three levels; two players on one PC), a fighter select, a new random planet each match with its seed shown, a Quit row, fullscreen and window settings, a working effects-quality setting, the Deck's own controls, and one press that saves a single small report file.
- Try: install it the way the guide says, on a PC that has never had it. Pick Loupe. Change one control and one comfort setting, close the game, start it again. Unplug the pad mid-match: the game should pause with a plain notice. Press the report button and post the file to the reports channel. Hold the transform buttons when the hint appears.
- For the Deck testers: the checklist in the guide, and the one-click bench that saves a frame-rate file.

**Exit criteria.**
- X-18: one Deck tester goes from the guide to a running game in under 10 minutes, with no help.
- X-19 (solo mode): notice, menu, picks, a full match, the result, rematch and leave, on the Deck's built-in controls with no keyboard.
- X-20: control and comfort settings survive a real restart on Windows and on the Deck.
- X-21: one press saves one report file under 10 MB (the lower of Discord's two published limits, read 2026-11-13); the guide says how to post it; a read of the code finds nothing that sends data.
- X-22: stills of every screen at 1280 by 800 show no clipped or overlapping text and no text under 9 px (12 px is the aim, from Valve's guidance read 2026-11-13).
- X-07: two pads on one PC each drive their own fighter; a pad unplugged mid-match pauses with a plain notice.
- X-24 and X-26 (a first number, not yet a pass): a frame record and loading times from a real Deck are on file.
- X-30 and X-31: a rehearsal with a dummy build on the restricted page: a key claimed, a Windows and a Linux channel, one update applied through the upload tool, one roll-back.
- X-32: the AI disclosure, the tester's agreement, the privacy line and the credits are inside the build, each with Legal's sign-off row.
- X-23 and X-26 on Orb's PC: measured on this build and on file.
- Round 1 returned: two Deck checklists and two report files posted to Orb (a rehearsal of X-01, not X-01 itself).

**Gap rows closed (51 required).**
- **UI & UX:** A-ACCESS-02 (S), A-ENERGY-08 (S), A-MODES-01 (M), A-MODES-06 (M), A-MODES-11 (S), A-TEXT-01 (S), A-TEXT-03 (S), A-UI-04 (M), A-UI-05 (S), A-UI-06 (S), A-UI-07 (S), A-UI-08 (S), A-UI-09 (S), A-UI-10 (S)
- **Tools & Pipeline:** A-LEGAL-06 (M), A-MARKET-01 (S), A-MARKET-02 (S), A-TOOLS-02 (M), A-TOOLS-03 (S), A-TOOLS-05 (M), A-TOOLS-09 (S), A-UI-02 (M)
- **Performance & Platform:** A-CONTROLS-08 (S), A-PERF-01 (M), A-PERF-03 (M), A-PERF-04 (S), A-PERF-06 (S), A-PERF-07 (S)
- **QA & Balance:** A-AI-03 (S), A-AI-11 (S), A-QA-01 (S), A-QA-11 (S), A-SAVES-01 (S)
- **Rendering:** A-PERF-08 (S), A-RENDER-02 (M), A-RENDER-03 (S), A-RENDER-05 (S), A-RENDER-08 (S)
- **Controls:** A-COMBAT-07 (S), A-CONTROLS-03 (S), A-CONTROLS-07 (S)
- **Legal:** A-LEGAL-05 (S), A-LEGAL-09 (S), A-LEGAL-12 (S)
- **Orb:** A-LEGAL-07 (S), A-LEGAL-10 (S), A-WORLD-14 (S)
- **Audio:** A-AUDIO-03 (S), A-AUDIO-04 (S)
- **Camera:** A-CAMERA-03 (S)
- **VFX:** A-RENDER-13 (S)

Nice-to-have rows placed here because a newcomer meets them and each is small: A-LEGAL-13 (S), A-TEXT-04 (S), A-TEXT-06 (S), A-SAVES-03 (S), A-SAVES-08 (S), A-UI-11 (S).

**Golden window.** None. Nothing in A2 changes the sim's state hash, so testers' replays from A2 keep verifying on A2.

**Token budget.** 23.8M (10 M, 47 S). UI & UX carries about 7M and Tools & Pipeline about 6M.

**Weeks.** 1.5 to 2.5 to build; then tester round 1 takes 1 to 2 weeks of the friends' own time while A3 is under way.

**Directors active.** Audio, Camera, Controls, Legal, Narrative, Performance & Platform, QA & Balance, Rendering, Tools & Pipeline, UI & UX, VFX; Accessibility for the checks on the X-02 list; the Executive Producer throughout.

**Orb's own actions here** (an account, something public-facing, a download): create the itch.io account and restricted page, generate one key per named friend, install the upload tool, and set up the reports channel on Discord. Tools writes a checklist for one sitting.

---

## A3. Every mode starts and ends

**Goal.** Every Alpha mode can be started from the menu with a pad, played to a result, rematched and left.

**What Orb can play.** All seven modes this draft plans for Alpha (campaign is recommended as none): solo, two players on one PC, couch 2v2, horde, custom planet in the tester build; LAN 1v1 and LAN 2v2 in the LAN flavour of the Windows build for Orb and the trusted second player. Testers receive the tester build as an update.

**PLAY THIS would say.**
- New: horde mode (one or two players against waves of up to three weak enemies that keep coming, 5 to 10 minutes, a result screen). Couch 2v2 (two pads as a team against two computer fighters, or one pad with a computer partner). Host and Join rows for LAN, with rematch and back-to-menu. Custom planet: seed, city count, climate and water. Each fighter has a second colour when two copies are on screen. Menu and building sounds, and a quiet ambience bed. A body that hits a building no longer bounces back like a ball. Practice against the dummy.
- Try: a horde run alone, then with a second pad. Couch 2v2 with a friend. With the second PC: five LAN 1v1 matches and five LAN 2v2, rematching from the menu; pull the cable once. Set the same seed and dials on both PCs and compare the planets. Knock the rival into a building.
- Also in this build: fixes for what the two Deck testers reported in round 1.

**Exit criteria.**
- X-05: one scripted smoke run per mode on Windows and on Linux, saved with the build. The LAN modes run on Windows only (see the resize list).
- X-08: on two PCs, five full LAN 1v1 and five LAN 2v2 matches with no state mismatch; a pulled cable shows a plain notice on both PCs within 10 seconds (this draft plans on the recommendation to keep today's 8-second rule).
- X-09: the supported couch line-ups are written and each passes the mode smoke.
- X-10: a horde run of 5 to 10 minutes ends in a result screen; a frame-time record at the largest wave is on file.
- X-11: the same seed and dials give the same planet hash on Windows, on Linux and on both LAN PCs.
- X-12: the campaign decision (minimal or none) is recorded with its reason.
- X-25 (the tool, first run): the soak script runs two hours on Orb's PC and writes a result file.
- X-34 (first archive): the fixed shot list renders from the A1, A2 and A3 builds, without debug text, and the three sets sit side by side.
- Tools ready before A4 must pass them: the probes for move coverage (X-03 in part), forms reached (X-04), the pillars in one match (X-13), beam escape (X-16) and the stray-beam count (X-17); the check that says whether a third fighter needs code (X-15).

**Gap rows closed (35 required).**
- **Netcode:** A-MODES-04 (L), A-MODES-05 (M), A-MODES-10 (M), A-NET-01 (S), A-NET-02 (S, resized), A-NET-03 (S), A-NET-04 (S), A-NET-06 (S)
- **Tools & Pipeline:** A-CODE-04 (M), A-ENERGY-06 (S), A-MARKET-03 (M), A-MARKET-05 (S), A-MARKET-06 (S), A-MARKET-07 (S), A-MODES-08 (M)
- **World:** A-WORLD-02 (L), A-WORLD-03 (M), A-WORLD-04 (S), A-WORLD-09 (S), A-WORLD-10 (L)
- **Encounter Systems:** A-AI-01 (L), A-AI-08 (M), A-AI-09 (S)
- **QA & Balance:** A-COMBAT-08 (M), A-QA-02 (M), A-QA-06 (M)
- **Rendering:** A-MODES-03 (L), A-MODES-09 (L), A-PERF-05 (M)
- **Art:** A-ANIM-02 (S)
- **Audio:** A-AUDIO-02 (M)
- **Camera:** A-CAMERA-05 (M)
- **Controls:** A-CONTROLS-01 (S, resized)
- **Game Design:** A-MODES-02 (L, resized)
- **Legal:** A-LEGAL-04 (S, resized)

Nice-to-have row placed here: A-MODES-12 (M) (Practice, the cheapest way to teach a newcomer once the mode row and fighter select exist).

**Golden window 2, "modes and worlds".** One window for the horde and its computer control, the computer partner, a level per fighter, the planet dials, terrain step 2 with the sea fix, and bodies that stop at buildings. Rows: A-MODES-02, A-AI-01, A-AI-08, A-AI-09, A-WORLD-02, A-WORLD-03, A-WORLD-04, A-WORLD-10.

**Token budget.** 48.6M of rows (7 L, 14 M, 15 S), plus a 6M reserve for fixes the round-1 testers ask for. World (about 10M), Rendering (about 9M) and Netcode (about 8M) carry most of it.

**Weeks.** 2.5 to 4.

**Directors active.** Art, Audio, Camera, Controls, Encounter Systems, Game Design, Legal, Netcode, QA & Balance, Rendering, Tools & Pipeline, World; UI & UX for the menu rows each mode needs; Simulation & Engine on the gravity well behind a switch; the Executive Producer throughout.

---

## A4. The whole fight

**Goal.** In one normal match every pillar shows up and works with the others: beams that can be dodged by moving off their line, both signatures on Orb's inputs, the gravity well, stamina with energy and body, transformations a player can see, and destruction that grows with power.

**What Orb can play.** The fight as defined for Alpha, in every mode built in A3. Testers receive it as an update.

**PLAY THIS would say.**
- New: a beam is seen leaving the fighter and can be side-stepped. RT + RB + a flick of the right stick is the energy signature; RT + a flick is the martial one. Up close the fighters are drawn together and blows snap to the target; far apart the long-range kit applies. Stamina: plain blows refill it, specials and signatures cost it and energy; being hit while tired makes injuries worse; a new form eases them. Each fighter has their own forms, with a change you can see on the body. Every button in the move table does something. A slide or a blow at the top form leaves a mark at least three times as wide as at base. Craters and trenches are drawn where you stand. A quality setting from performance to full, with a Deck default.
- Try: have the computer fire a beam and fly off its line. Fire both signatures. Fight until you are out of stamina, then recover with plain blows. Reach every form with both fighters. Hit the ground with the same blow at base and at the top form and compare the marks. Play with the right stick only for a match.

**Exit criteria.**
- X-03: the scripted pad presses every cell of the Alpha move table for both fighters; no cell without an outcome; the martial and energy rows have no duplicates.
- X-04: a scripted match reaches every designed form for each fighter; one side-by-side still per form; a transformation in progress is not interrupted by a shot already in flight.
- X-13: the Alpha match checklist reads every pillar from the event feed of one 6 to 8 minute scripted match and of one of Orb's saved play files.
- X-14: the same blow at the top form makes a crater at least 3 times as wide as at base; no base-form fight wrecks the planet.
- X-15: one page states the stamina, energy and body model; every number is in data per fighter; the third-fighter check passes; no health bar is on screen.
- X-16: a scripted defender side-steps a beam at three ranges.
- X-17: beams started by any input other than the right stick or the two signature inputs, over scripted and saved matches: 0. The computer uses only inputs a player has.
- X-06 (pre-read): the three difficulty bands and the match length are read on this window's data before the window closes, so A5 only confirms.
- X-24 groundwork: the quality level picker exists with a Deck default chosen from round 1's frame record.

**Gap rows closed (23 required).**
- **Encounter Systems:** A-AI-07 (S), A-AI-10 (S), A-COMBAT-01 (L), A-COMBAT-02 (L), A-CONTROLS-05 (M)
- **Simulation & Engine:** A-CODE-05 (L), A-COMBAT-03 (XL), A-COMBAT-12 (S), A-ENERGY-03 (M), A-ENERGY-10 (S)
- **Game Design:** A-COMBAT-06 (L), A-ENERGY-01 (L), A-QA-05 (M)
- **Rendering:** A-RENDER-06 (L), A-WORLD-05 (L)
- **World:** A-WORLD-06 (S), A-WORLD-07 (L)
- **Animation:** A-ANIM-03 (S)
- **Art:** A-ANIM-01 (M)
- **Combat & Choreography:** A-COMBAT-04 (L, resized)
- **Controls:** A-CONTROLS-06 (M)
- **QA & Balance:** A-QA-08 (S)
- **UI & UX:** A-ENERGY-07 (S)

Nice-to-have row placed here: A-AI-06 (M) (the computer uses right-stick strikes at Medium and Hard; it belongs in this window because it must precede the final difficulty tuning).

**Golden window 3, "the whole fight".** Everything that changes how a fight plays lands in one window and the tuning is done inside it. Rows: A-COMBAT-01, A-COMBAT-02, A-COMBAT-03, A-COMBAT-04, A-COMBAT-06, A-COMBAT-12, A-ENERGY-01, A-ENERGY-03, A-ENERGY-10, A-CODE-05, A-CONTROLS-05, A-WORLD-07, A-AI-10, A-QA-05, A-QA-08, A-AI-06. A fourth, numbers-only window is held in reserve at A5 and used only if a difficulty band or the match length fails on the candidate.

**Token budget.** 53.2M (1 XL, 9 L, 6 M, 8 S). Simulation & Engine (about 14M), Encounter Systems (about 11M), Game Design (about 9M) and Rendering (8M) carry it. This is the largest milestone and the least certain: its big rows have no comparables.

**Weeks.** 3 to 4, on the assumption that the gravity well, the stamina loop and the beam rewrite were begun behind switches during A2 and A3. If they start cold at A4, add 2 weeks.

**Directors active.** Animation, Art, Combat & Choreography, Controls, Encounter Systems, Game Design, QA & Balance, Rendering, Simulation & Engine, UI & UX, World; Camera, VFX and Audio for the beam, the well and the forms; the Executive Producer throughout.

---

## A5. The Alpha candidate

**Goal.** Nothing new: the candidate is measured against every criterion, two outside testers on Steam Decks complete the checklist on it, and the feature freeze begins.

**What Orb can play.** The Alpha candidate, from the itch.io page, as a tester gets it.

**PLAY THIS would say.**
- New: nothing to play that A4 did not have. Frame rate, loading, the two-hour soak, balance and difficulty are measured and on file; the marketing shots are rendered for all five milestones.
- Try: the tester checklist from start to finish, on the Deck if one is to hand. Then say yes or no to the freeze.

**Exit criteria.**
- X-01: at least two outside testers on Steam Deck return the completed checklist for the candidate (tester round 2).
- X-02: every outside-tester gate is green on the candidate's commit.
- X-05: the mode smoke passes for every mode on the candidate (LAN on Windows).
- X-06: Easy 60 to 80%, Medium 35 to 55%, Hard 10 to 30%, with enough matches a cell to tell the bands apart; the two fighters within the balance band on the candidate's packed data.
- X-18 to X-22: re-run on the candidate by the Deck testers.
- X-23: 60 frames a second held on Orb's PC in a normal match, no frame over 50 ms outside loading.
- X-24: 30 frames a second held on a real Deck at the Deck's default quality level (40 is the aim), from the testers' bench files.
- X-25: two hours of computer-against-computer on Windows and on a Deck with no crash, hang or script error and memory growth under 10%.
- X-26: start to menu and start-match to control under 15 seconds on Orb's PC and 30 on the Deck.
- X-27: every replay saved by the candidate verifies on it; a foreign replay is refused in plain words.
- X-28, X-29, X-30, X-31, X-32: re-run on the candidate's commit.
- X-33: the freeze is declared; the ideas log is the only door for new ideas.
- X-34: the shot list is rendered from the candidate and sits beside the same shots from A1 to A4.

**Gap rows closed (2 required).**
- **Community & Marketing:** A-MARKET-08 (S)
- **QA & Balance:** A-QA-04 (M)

**Golden window.** None planned. The reserve numbers-only window is used only if a band fails.

**Token budget.** 1.4M of rows plus an 8M reserve for the verification runs and for fixes from tester round 2.

**Weeks.** 2 to 3, set mostly by the testers' time and the soak.

**Directors active.** QA & Balance, Tools & Pipeline, Performance & Platform, Community & Marketing, Legal, Accessibility, UI & UX, and whichever director owns a failing criterion; the Executive Producer throughout.

---

## Rows this draft proposes to resize or move

| Row | Register size | Proposal | Reason |
| --- | --- | --- | --- |
| A-PERF-02 (LAN on Linux) | M, required | **Move after Alpha.** LAN at Alpha is Windows only. | LAN is recommended for Orb and the trusted second player only, on two Windows PCs. No tester on a Deck would use it. X-05 and X-08 are then measured for the LAN modes on Windows only. |
| A-NET-02 (LAN set-up without help) | L, required | **Resize to S**, stays in A3: a two-PC set-up page for Orb and the trusted second player using the Host and Join rows. | Making LAN set-up safe for an outsider (a firewall step, an unsigned program, a typed address) is large and no newcomer step needs it. |
| A-LEGAL-04 (LAN and outside testers) | M, required | **Resize to S**, stays in A3: one Legal ruling that the tester package carries no network code and the LAN flavour is for the two named players. | Follows from the line above. |
| A-CONTROLS-01 (four pads) | M, required | **Resize to S**, stays in A3: state the supported couch line-ups; keep two human slots; four pads after Alpha. | X-09 asks for the supported line-ups to be stated. Two friends on a couch is the newcomer's case. |
| A-MODES-02 (horde) | XL, required | **Resize to L**, stays in A3: a first horde inside today's five-body limit, waves of at most three weak bodies. | A small horde proves the mode end to end and lets testers say what it lacks before the body limit is raised. |
| A-COMBAT-04 (move table) | XL, required | **Resize to L**, stays in A4: martial and energy rows complete and distinct, other held-button rows shared; every cell gives an outcome. | A newcomer needs every press to do something visible; distinct outcomes for all 55 cells a fighter is depth for Beta. |

Together the resizes take about 15M tokens out of the path. **If Orb decides otherwise:** LAN for outside testers brings back A-PERF-02 (M), A-NET-02 at L and A-LEGAL-04 at M, about 6M tokens and 1 to 2 weeks in A3, plus a third tester round with two PCs on one network. Four pads adds about 1M in A3. A larger horde adds about 4M and a frame-rate risk on the Deck. The full move table adds about 4M and about a week in A4.

One note on order. The specification's order is safety and blockers, then modes, then the newcomer's path, then polish. This draft finishes the newcomer's path for **one** mode at A2, ahead of the other modes. It can do so without breaking the rule because the rows that make that path are themselves blockers (A-PERF-01, A-PERF-03, A-TOOLS-02, A-TOOLS-03, A-TOOLS-05, A-UI-02, A-MODES-01, A-MODES-06, A-QA-01), and no row in A2 needs a row placed later.

## The nice-to-have pool

66 rows, about 35.6M tokens if all were done. None is scheduled. A row leaves the pool only through the change-control rule below, or when its owner is already in the same file for a required row and the Executive Producer agrees it adds no gate run. First picks if a milestone runs under budget, because testers would notice them: A-TOOLS-13 (CI starts a Windows build), A-SAVES-04 (settings survive a change of build), A-ACCESS-03 (captions for more sounds), A-UI-12 (a guided first match), A-TEXT-02 (the fighters' spoken lines), A-COMBAT-10 (chaining hits on a flying rival, which Orb asked for on 9 November).

- **ACCESS:** A-ACCESS-03 (M), A-ACCESS-05 (S)
- **AI:** A-AI-13 (S)
- **ANIM:** A-ANIM-04 (S), A-ANIM-05 (S), A-ANIM-08 (S)
- **AUDIO:** A-AUDIO-05 (M), A-AUDIO-06 (S), A-AUDIO-07 (S), A-AUDIO-08 (S)
- **CAMERA:** A-CAMERA-04 (M), A-CAMERA-06 (S), A-CAMERA-07 (S), A-CAMERA-08 (S), A-CAMERA-09 (S), A-CAMERA-12 (S), A-CAMERA-13 (S)
- **CODE:** A-CODE-06 (S), A-CODE-08 (S), A-CODE-09 (S), A-CODE-10 (S)
- **COMBAT:** A-COMBAT-09 (XL), A-COMBAT-10 (M)
- **CONTROLS:** A-CONTROLS-09 (S), A-CONTROLS-10 (S)
- **ENERGY:** A-ENERGY-09 (S), A-ENERGY-11 (M), A-ENERGY-12 (S)
- **LEGAL:** A-LEGAL-11 (S), A-LEGAL-15 (S)
- **MARKET:** A-MARKET-09 (S), A-MARKET-10 (S)
- **MODES:** A-MODES-13 (S)
- **NET:** A-NET-07 (S), A-NET-09 (S), A-NET-10 (S), A-NET-11 (S)
- **PERF:** A-PERF-09 (S), A-PERF-10 (S)
- **PROCESS:** A-PROCESS-12 (S), A-PROCESS-17 (S), A-PROCESS-18 (S), A-PROCESS-20 (S)
- **QA:** A-QA-10 (S), A-QA-12 (S)
- **RENDER:** A-RENDER-09 (M), A-RENDER-12 (M), A-RENDER-14 (S), A-RENDER-15 (S), A-RENDER-16 (S)
- **SAVES:** A-SAVES-04 (S), A-SAVES-05 (S), A-SAVES-06 (S), A-SAVES-07 (S)
- **TEXT:** A-TEXT-02 (S)
- **TOOLS:** A-TOOLS-11 (S), A-TOOLS-12 (S), A-TOOLS-13 (S), A-TOOLS-14 (S), A-TOOLS-16 (S), A-TOOLS-17 (S)
- **UI:** A-UI-12 (M), A-UI-13 (S), A-UI-14 (S)
- **WORLD:** A-WORLD-08 (L), A-WORLD-11 (S)

## Deliberately after Alpha

- **Four fighters** (the bar for Beta), **online play**, **Mac**, **mobile**, **modding**, **the full campaign** (and, on this draft's recommendation, any campaign at all: A-MODES-14).
- **LAN for outside testers and LAN on Linux or the Deck** (A-PERF-02, moved by this draft).
- **Four pads on one PC; a horde above five bodies; the full 55-cell move table per fighter; planet sizes** (A-WORLD-08, in the pool).
- **Orb's workshop items placed after Alpha by recommendation:** physics-based launches, the terrain and tessellation overhaul, High Intensity on RT, the taunt before a signature, walking into a beam and punching up it, the catch and the timed swat, re-entry heat trails, the ally window (picture-in-picture), 3D auras, music and the audio toolset, photo mode. The 2026-11-13 brainstorm ideas wait in the ideas log.
- **The hero and villain meters and signature variants by biome:** zeroed in data at A1, code removed after Alpha.
- **Steam:** the fee, the store page, the demo and the Deck compatibility review belong to Beta.
- **Register rows marked after (A-COMBAT-13, A-ENERGY-13, A-AI-12, A-MODES-14, A-WORLD-12, A-WORLD-13, A-RENDER-10, A-CAMERA-10, A-CAMERA-11, A-NET-08, A-NET-12, A-ANIM-07, A-TEXT-05, A-PERF-11, A-CODE-07, A-CODE-11, A-CODE-12, A-LEGAL-14, A-ACCESS-06, A-ACCESS-07, A-MARKET-11, A-PROCESS-19).**

## Change control

**During the push (A1 to A5).**
1. Every new idea from Orb goes into the ideas log the day it is said, in Orb's words, with a date.
2. Within one working day the Executive Producer adds a recommendation: **now** (it replaces or reshapes a row already in the current milestone, at no extra golden window), **next milestone** (named), or **after Alpha**; with a size class and whether it changes the state hash.
3. Nothing from the log is built until Orb has seen that line and said yes. Nothing is built silently, and "workshop this" means a page or a toy, not a change to the game.
4. An idea that changes the state hash can only join the next golden window (2 at A3, 3 at A4). After window 3 closes, hash-changing ideas wait for after Alpha.
5. A milestone's row list changes only at its start. If something comes in mid-milestone, something of the same size goes out, and the page says which.
6. Tester findings follow the same rule, with one difference: a finding that blocks a newcomer step (cannot install, cannot start, cannot finish a match, cannot report) is fixed in the current milestone without waiting.

**After the freeze (from A5's sign-off).** A new idea is either logged for after launch, or brought to Orb as a scope change with its cost in tokens, weeks and golden windows, and what it displaces. Fixes, tuning inside the data's existing shape, and polish that passes the look gate are not scope changes.

**Standing exception.** Anything that touches a player-safety gate, a Legal flag, spending or something public stops and goes to Orb as one plain question, as today.

## The critical path and the three risks

**Two chains set the earliest Alpha; the longer one wins.**

1. **The fight chain (tokens).** A-CODE-01 (main becomes the played game, golden window 1) -> A-ENERGY-02 (the model page) -> A-ENERGY-01 (the stamina, energy and body loop) and A-COMBAT-02 (signatures on Orb's inputs) -> A-COMBAT-04 (the move table) -> A-CONTROLS-06 (the coverage probe that proves X-03) -> tuning inside golden window 3 -> the candidate. Beside it, with no row waiting on it but the largest single row in the register: A-COMBAT-03, the gravity well, which needs Orb's answer on whose stick moves whom up close before it is built.
2. **The newcomer chain (people).** A-LEGAL-01 and A-LEGAL-08 (the last two outside-tester gates) -> A-LEGAL-03 (the gate list, green) -> A-LEGAL-02 and A-TOOLS-01 (a desktop build can be made) -> A-PERF-01 (a Linux build draws on a real Deck) -> A-TOOLS-02, A-TOOLS-05, A-LEGAL-05 -> A-QA-01 (the guide and checklist) -> tester round 1 -> tester round 2 on the candidate (X-01).

On this draft's figures the fight chain is the longer: about 8 to 11 weeks of work from today if started at A1's close, which is why its decisions are asked first. The newcomer chain is shorter in tokens but has two waits on volunteers that no budget can shorten.

**The three risks most likely to move the date.**
1. **The outside-tester gate list does not go green on the globe ground in A1** (A-LEGAL-01, A-LEGAL-08, with A-CAMERA-02). Until it does, no outside tester may play anything, and A2 cannot hand out a build. It is the first thing briefed, and A1 does not close without it.
2. **The Linux build does not hold up on a real Deck** (A-PERF-01): it has never drawn a picture, the Deck's driver has never run the shaders, and the frame rate is unknown. This draft meets the risk early on purpose, at A2 instead of A4, so that a bad answer costs weeks of Rendering and Performance work in the middle of the path and not a slipped candidate.
3. **The fight window grows.** Golden window 3 holds the gravity well, the beam rewrite, the stamina loop, the signatures and the move table: 1 XL and 7 L rows with no comparables, in the area where Orb's workshop ideas arrive fastest. The guards are the change-control rule, the early decisions, and starting behind switches during A2 and A3.

A fourth, smaller: the weekly pace is an estimate. If the token record kept from A1 shows half the assumed pace, every range above doubles except the testers' time.

## Decisions that are Orb's, most urgent first

Each has one recommendation. This draft plans on the recommendation.

**Blocking A1 (needed this week).**
1. **May the team make the build you played on 9 November the default game on main, row by row, before any new feature work?** Recommendation: yes. Blocks: everything; a desktop build made from main today is a different, mostly switched-off game (A-CODE-01).
2. **Which build is the one new looks are compared against?** Recommendation: the 9 November globe build, with its open look bugs listed as not part of the reference. Blocks: the look gate for every visible change from A1 on (A-RENDER-11). With it: globe ground, crater look and meteor trail become defaults (A-RENDER-01), and Alpha ships today's craters with the black fill removed while the terrain workshop waits until after Alpha (A-RENDER-04).
3. **The backburnered hero and villain meters: switch off, fold in, or retire?** Recommendation: keep the comeback as a rule for every fighter, zero every other effect in data now, remove the code after Alpha. Blocks: golden window 1 (A-ENERGY-05).
4. **Flight speed 3500 as the default in every mode?** Recommendation: yes, with the slider dropped. Blocks: golden window 1 (A-CONTROLS-04).
5. **How hard should Easy be for someone playing your way?** Recommendation: at least 7 wins in 10. Blocks: golden window 1 and what the first testers meet (A-AI-02).
6. **May the Executive Producer turn on the repository's free protections (secret scanning, push protection, a protected main)?** Recommendation: yes. Blocks: closing the corrective plan (A-PROCESS-07).
7. **The change-control rule above: agreed?** Recommendation: yes. Blocks: X-33 and how every later idea is handled (A-PROCESS-01).
8. **When the gates are green, will you record one line saying yes to desktop test builds for named outside testers?** Recommendation: yes, at that point and not before. Blocks: the build pipeline and A2 (A-LEGAL-02, A-TOOLS-01).

**Needed by the end of A1, because the fight's builders start on them.**
9. **How much of the stamina, energy and body loop is in Alpha?** Recommendation: the whole loop you described on 13 November as shared rules with per-fighter numbers in data, switched on after QA's comeback measurement; "body" reuses the old hidden health number behind the four body parts. Blocks: the model page and the longest chain (A-ENERGY-01, A-ENERGY-02). If smaller (energy and stamina only, body after): A4 loses about 2M tokens and X-15's page says so.
10. **How much gravity well is enough, and up close does your stick move only your own fighter?** Recommendation: the well's size, its zones and the snap for Alpha, starting from the packet's default for the stick; the far kit, the catch, the swat and the taunt after Alpha. Blocks: the largest row in the register (A-COMBAT-03, A-COMBAT-15).
11. **The move table's bar, and what RT held does once signatures are on RT + flick.** Recommendation: the smaller table for Alpha (see the resize list); RT held stays the ki charge for Alpha. Blocks: A-COMBAT-02, A-COMBAT-04.
12. **Your open "workshop this" items, before or after Alpha.** Recommendation: before Alpha only close fights (item 10) and beam stages as far as option A needs them; everything else after Alpha or in the pool, as listed under "Deliberately after Alpha". Blocks: the size of A4.

**Blocking A2 (the first Deck round).**
13. **Which friend with a Deck will do a first 30-minute session?** Recommendation: ask both now, so they expect a key in about a month. Blocks: A-PERF-01, round 1.
14. **The itch.io page:** will you create the account and a restricted, key-only page under the working title before the paid title search, and install the upload tool, in one sitting with Tools' checklist? Recommendation: yes, marked as a working title, one key per named friend. Blocks: A-TOOLS-02, A-LEGAL-09, X-30, X-31. If no: testers get a zip by hand, and the update and roll-back criteria cannot be met.
15. **The reports channel:** a new private Discord server (or a new channel locked to a tester role), and the promise to delete a tester's reports on request? Recommendation: a new private server, and keep the promise. Blocks: A-LEGAL-07, the tester guide.
16. **The licence line:** all rights reserved through Alpha, with a short friendly permission page, and public code decided at Beta? Recommendation: yes (Legal's rundown, version 2). Blocks: the words inside the build (A-LEGAL-10, X-32).
17. **The default world:** a new random planet each quick match, with the seed shown and saved in reports, and the current planet kept as one preset for a first match and for tests? Recommendation: yes. Blocks: A-WORLD-14 and what a tester picks at "planet".
18. **A handful of small yes-or-no answers for the tester build,** each recommended yes: every desktop match keeps its replay on the player's PC (the last 20, nothing sent); a report is one file under 10 MB with clips left out; the Rail menus are Alpha's menus; the result panel stays off the winner's corner; a dropped pad pauses the game; one checklist per tester is the sign-off; a second drive holds the copy of your builds and play files. And three short sittings: mark about 150 strings of tester-facing text, one ten-minute listening pass on a desktop build, and one clip of each mark drawn round the fighters to keep or remove.

**Blocking A3.**
19. **LAN at Alpha: for you and the trusted second player only, on Windows, from Host and Join rows?** Recommendation: yes. Blocks: A-MODES-04, A-NET-02, A-LEGAL-04, A-PERF-02. What changes otherwise is under the resize list.
20. **The campaign: none at Alpha?** Recommendation: none; the horde carries co-op. Blocks: X-12 only.
21. **The first horde's size, the couch 2v2 line-ups, and a computer partner.** Recommendation: waves of at most three weak bodies; two pads as a team against two computer fighters, plus one pad with a computer partner; four pads after Alpha. Blocks: A-MODES-02, A-MODES-03, A-AI-08.
22. **Smaller A3 answers,** each recommended yes: custom planet is a seed plus three dials at today's one size; a second body colour tells two copies of a fighter apart; in LAN 1v1 each screen favours its own player; "the other PC has gone" within 10 seconds; one quiet ambience bed with building and menu sounds, music after Alpha.

**Can wait until A4 or A5.**
23. **A transformation's look:** one cheap body change per form carried by data, bulked-up bodies after Alpha. Recommendation: yes (A-ANIM-01).
24. **Frame rate targets:** 60 on your PC; 30 held on the Deck with 40 as the aim. Recommendation: confirm after round 1's bench files exist.
25. **Will a Deck friend leave the game running for two hours and send the result file?** Recommendation: yes, ask one at round 2 (A-QA-02).
26. **What "Beta in sight" means, the point where the Steam clock starts.** Recommendation: four fighters playable on the Windows and Linux builds and the Alpha testers' reports folded in. No Steam fee, no code signing and no video encoder install before then; the tester guide explains Windows' warning on an unsigned program.

## Self-check

Run against `03-gap-register.json` by script on 2026-11-13: required rows 174; in exactly one milestone 173; proposed to move after Alpha 1 (A-PERF-02); missing 0; placed twice or both placed and moved 0; resized in place 5; nice rows placed 8, in the pool 66; after-Alpha rows listed 22; order violations against the needs field 0; hash rows by milestone A1 12, A2 0, A3 8, A4 16, A5 0; other problems 0.
