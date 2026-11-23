# The shortest path to the first Alpha build

- **Who:** Orb's stand-in, the review specialist of sprint A1.
- **When:** 2026-11-23, about 07:50, against main at 0d21624b.
- **For:** the EP, on Orb's word of today: "use my stand-in effectively to sprint to our first alpha build" (`docs/ep/vision.md:1902`).
- **What "first Alpha build" means here:** the audit's sense. A1's exit is met, and then A2 has put a safe package in two friends' hands (`docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md`, lines 97 to 106 and 135 to 177, read with the rules at lines 16 to 38, which override the text below them).
- **How:** from the same evidence as `docs/ep/reviews/A1-exit-status.md` (nine readers and nine checkers on the cheaper model, one completeness reader, the stand-in's spot-checks). Blockers and majors only. Nothing here is decided: it is a recommendation to the EP, and the items marked for Orb are Orb's.

## The short version

1. **A1 is one landing and one sitting away, not many.** The planet work (GW1c) is the only large thing left to build. Almost everything else A1 lacks is a record, and nearly all of those records should be taken once, on the commit where GW1c lands.
2. **Do not prove things on today's commit.** GW1c changes the game's fingerprint, the golden, the menu and the main scene. A build, a still, a mode-test result or a frame reading taken now is taken twice. Build the proving tools now, try them once on today's main, and take the records that count after the landing.
3. **One click from Orb closes about ten parts.** The path's rule 7 says a session never starts a desktop program that draws a picture: Orb or CI does. So every proof that needs the window open (frames, loading, the menu stills, the version number on screen, a saved report) should be gathered into one small script Orb starts once, in a quiet window, for about five minutes.
4. **The same-match picture comparison with 9 November can only be made on the GW1a commit.** Main no longer plays the 9 November game exactly, by design (launch distance, top speed, the computer's answers). The one commit where "the same match, the same moments" is true is cb8d7934, and a build of it exists. That comparison should be made there, from the browser builds, and written down as the record; later builds are held to the ordinary look gate.
5. **A2's long poles do not depend on GW1c and should start today.** They are the tester-safety readings (Legal's gates G4, G5 and G21: the EP holds the detail), Tools' packaging chain, and three things only Orb can do: the private report server, the store page sitting, and asking the friends.
6. **Tools is the bottleneck on both chains,** with one capture at a time on a shared PC. The fastest single change the EP can make is to take work off Tools: the soak to QA, the bench to Performance, the stills to UI and Rendering, and, if Orb agrees to another session, a second Tools lane for packaging.

**A rough size, not a promise.** A1's exit: about 12M to 16M tokens of director work, one to two weeks if GW1c lands on the first gate run. A2 to the friends' hands: the audit's 34M and two to four weeks, of which one to two weeks is waiting on evenings (Orb's sittings and the friends'). So the package reaches two friends somewhere between mid-December and early January, with the holidays inside that range. The audit's own caution applies: these are size classes added up.

## The ranked list

Size classes are the audit's: S about 0.25M tokens, M about 1.2M, L about 4M, XL about 8M. "Now" means it can start today and does not wait on another job.

### For A1's exit

| # | Job | Owner | Size | Starts | What it unblocks |
| ---: | :--- | :--- | :--- | :--- | :--- |
| 1 | **Make CI green on main.** List the new check script (`sim/director/tools/hold_answer_check.gd`, in neither `tools/check-scripts.json` nor `ci.yml`), find the second red job, read the run on 0d21624b to its end, push ead18383 | Tools, with Encounter | S | Now | Every later landing's CI reading; the version-and-changelog step that the red step hides; the Linux records in jobs 7 and 11; Legal's gate G1 |
| 2 | **The GW1c ruling page.** One apply list across owners on today's main (from `docs/ep/reviews/GW1c-readiness.md:90-104` and World's stage list), and the six rulings under "The EP's own calls" below | EP | S | Now | Every re-cut in jobs 3 to 5 aims at one tree. Nothing else in GW1c can finish without it |
| 3 | **World's GW1c fixes.** Tiny and huge switched off in the size data; the check row that catches the ground-memory fault coming back (C-01); the saved-planet key carries the size (C-10); the crater park split so the beam-crater rule is behind a switch shipped off (C-02); the unlisted sixth size refused; then the stage re-run on today's main with a golden line | World, with Simulation | M | After 2 | "Sizes selectable" within the EP's rule; a stage that does not change your beam craters unnoticed |
| 4 | **Rendering's GW1c pieces.** The three feet parks re-cut on today's main; the sized feet check made a gate (the tower fault C-04 explained or owned); the cause of the one picture reading on small that is over the team's bar found and fixed; stills of small, medium and big named in a committed record. Camera re-runs its chase check on terrain step 2 | Rendering, Camera | M + M | After 2 | "Drawn"; "feet within 8 units"; "terrain step 2 landed" |
| 5 | **The other owners' size parks, then play the sizes.** The saved-match park with a row for a medium replay after a tiny match (Simulation), the computer's ranges by size (Encounter), the meteor grant (VFX), the menu row and the main-scene merge last (UI, Rendering), schema cases (Tools). Then each offered size played to a result, and one saved match replayed in a second process, per size | Simulation, Encounter, VFX, UI, Tools; then World, QA | M + M | After 3 | "Each generates and plays" |
| 6 | **Gate and land GW1c,** with the look gate, one re-recording of the golden, and the round-planet beam fault (`docs/director/pending/beam-standoff-planet`) riding the same re-recording | EP | M | After 3, 4, 5 | Six of the seven waiting parts; the commit every record below is taken on |
| 7 | **The "prove a build" kit.** Built and tried on today's main, run for the record on the GW1c commit: the mode test opens pause with the pad, chooses "Close the game" and sees the program close, and saves one result per mode and platform; the build is numbered and its changelog entry written; the Linux half of the one command (or the EP's ruling, below); the CI build run repeated and saved; the two existing build records cleaned of this PC's folder paths and filed | Tools | M | Now (kit); after 6 (records) | X-29, four parts; X-05, two parts; "quit with the pad" |
| 8 | **The one-click first run, for Orb.** One script that starts the built program, plays one fixed saved match, saves stills at fixed moments (the mode list, the fighter pick, pause, the version line, the match), records frames and loading times, saves a report, and closes. After GW1c it takes a size, so small, medium and big are measured in the same sitting. The Linux half runs in CI under the virtual display | Tools, Performance | M | Now (script); after 6 (the click) | X-23 and X-26; "measured" on the planet line; the menu, pause, version and report rows; the menu sweep's stills from the real game. About ten parts for five minutes of Orb's time |
| 9 | **The picture comparison with 9 November, made where it is true.** Browser builds of cb8d7934 and of the 9 November build, one of the golden's scripted matches, stills at the same moments through Tools' launcher, each difference named. This is the follow-up S-12 of the GW1a review, never done | Camera, Rendering, VFX; Tools' launcher | S | Now | "Compared by stills"; with the ruling below it closes the goal's first part |
| 10 | **QA's three.** The transformation probe with one reading (the only A1 tool with nothing built); one difficulty reading on the landed game's packed data, three levels, the full-scheme player, at the sample size QA's own page asks for; Controls re-checks and lands the button-press probe | QA, with Simulation and Encounter; Controls | M + S | Probe now; reading after 6 | The measuring-tools line; both X-06 parts; the last waiting part outside the planet |
| 11 | **The pin register and the three small proofs.** Every pin listed (34 that force the flat arena, 33 that force the older world, 12 picture checks on the strip ground, 4 that put launch distance back to 2.0), each classed fair or hiding, with a round-planet row for the ones that hide the shipped game: the launch-arc row (GS-2), Audio's world check (A-1), Camera's launch rows (C-3) and the bystander check. Beside it: the golden's passing run saved on main for Windows and Linux; the "saved by a different version" sentence shown on screen | EP (register); World, Simulation, Rendering, Camera, Audio; UI | M | Now | "The checks run with the switches as shipped"; "main reproduces the record"; X-27's message |
| 12 | **The EP's process batch.** Adopt one backlog; an ignore rule for the 5,145 loose pictures and the remaining loose code and data committed or dropped; landed park folders cleared after their records are moved out; the closing lines on the S3, S4 and S5 trial pages; the stale lines in `CLAUDE.md`, the look reference and the tracker | EP, Production, each owner | M | Now | X-33, two parts; the trials, three parts; fifteen of the audit's EP rows |

### For the A2 package (start now; they do not wait on GW1c)

| # | Job | Owner | Size | Starts | What it unblocks |
| ---: | :--- | :--- | :--- | :--- | :--- |
| 13 | **The tester-safety readings.** Finish the measuring chain (one command, both modes, on the round planet, a record that holds for a commit); land Camera's parked safeguards (`docs/camera/pending/cd04`); name the cause of each reading over the line and fix it; a passing reading on the candidate; then the reading on the actual desktop package, by a method Legal rules on. This is A2's longest pole | Tools, then Camera, VFX, Rendering; Legal | XL | Now | Gates G4, G5 and G21. If a fix changes the ordinary look, it goes to Orb as two clips and one question (rule 4) |
| 14 | **The package's own pieces.** A crash file on Windows and Linux, then the two-hour soak; a size limit on the report and a scan of it for names and folder paths; the store-page checklist, upload script and one-step roll-back; a check that the testers' menu hides the modes they cannot use; the one-press bench; the pad-reachable report panel, the restart test, the AI line on the first screen and the unplug pause; the tester note made final and the guide and one-page sheet drafted; the accessibility checklist; the three unexplained picture faults | Tools; QA (soak, guide); Performance (bench); UI and Controls; Legal; Accessibility; Rendering | 8 to 10 jobs of S or M | Now | X-28, X-25, X-21, X-30 and X-31, X-24 and X-26 on a Deck, X-20, X-07, gates G9, G13, G14 and G20 |
| 15 | **The candidate.** One commit with all 22 of Legal's gates green and a saved record for each; then Orb's one line; then Orb's upload and the keys; then the friends' evening | EP, Legal, Tools; then Orb | M, then waiting | After 6, 13, 14 and Orb's sittings | The package in two friends' hands |

Three orderings inside these jobs that are easy to miss:
- **Three parks touch the same two files.** The crash file, the window park (`docs/rendering/pending/window-display`) and GW1c's menu merge all change `project.godot` or the main scene. The EP orders them; whichever lands second is re-cut.
- **The report server comes before the package.** The package check refuses a tester's notes file while its report-channel line is still a placeholder, so no outside package can be made until Orb's server exists.
- **The PC's quiet time is a shared resource nobody has scheduled.** Performance's readings, the safety captures, the size stills and QA's long batches all need it. Rule 8 of the path asks for a page that lists the long runs, the quiet window and who pauses. There is none for A1's end or for A2.

## The EP's own calls (no question for Orb needed)

| Call | My recommendation | Why |
| :--- | :--- | :--- |
| Does starting the CI build count as the "one command"? | Add the Linux export to the local tool instead | The sprint report already tells Orb one command makes the desktop build; a ruling would leave that sentence half true |
| Where is "compared by stills" proven? | On cb8d7934, from the browser builds (job 9), written into the sprint page as the record | It is the only commit where nothing is meant to differ |
| The crater park in GW1c | Split it: the tier tables land, the beam-crater rule ships behind a switch that is off | Otherwise GW1c changes a thing Orb sees with no look taken |
| The cap on small planets' height, and the snow lines that follow it | Hold both data rows out of GW1c unless job 4's cause turns out to need them | It is a look change on a size A1 offers, with stills owed first |
| The lakes | One named window straight after GW1c for all three lake parks, and the feet check written to leave lake ground out until then | Drawing the water without digging the bowls shows walls of water; Game Design has already ruled the dig |
| Is the wall-hold window (fighters stopping against a tower, not bouncing off) part of A1's exit? | No: a private build for Orb as soon as Tools is free, landing when Orb says so | The exit line at `docs/ep/sprints/A1-sprint.md:50` does not name it, and Orb said "Wait until I play it" |
| Decisions 20 and 21 | Ask them now, not before A5 as the sprint page has it | The path's own table says they block A2 work (line 544, line 545) |
| A page for A2 | Start `docs/ep/sprints/A2-sprint.md` now with the quiet-window schedule | Jobs 13 and 14 are already A2 work |

## What needs Orb

Plain words, one at a time, in the order they shorten the path. The first five are already written on a page in the homework folder or are a single line from the EP.

**On the path now**

1. **Play the newest build.** Open it, play one match against the computer on Easy and one on Medium, pause, press "Save this match", and close the game from the menu. Say whether it feels like your game and whether each level is too easy, right or too hard. *Unblocks:* the two difficulty numbers the team left for a person's hands; the first proof that the program starts and saves on your PC.
2. **Are the words in the new menus right?** *Unblocks:* the words your friends will read.
3. **Is A1 done with small, medium and big planets, with tiny and huge polished after?** The recommendation on your sprint report is yes. Huge cannot fill its ground yet. *Unblocks:* nothing stops meanwhile; it settles what GW1c must hold.
4. **Make the private report server,** a new one, and say whether we may promise a friend that their reports are deleted if they ask. *Unblocks:* the testers' package cannot be made without it.
5. **Ask your friends with Steam Decks.** Two now and a spare; two more held back for later so they come to the finished game fresh. The first session is 60 to 90 minutes, not 30. Only tell the EP how many said yes; their names never go in the project. *Unblocks:* the longest wait on the whole path, so it is worth starting first.
6. **If a controller is unplugged in the middle of a match, should the game pause and say so?** And will you listen to the test build for ten minutes and mark what sounds wrong? (There is no music yet.) *Unblocks:* two A2 jobs. The recommendation on both is yes.
7. **One click, when Tools has the script:** start the first-run test once while nothing else is running on the PC, about five minutes. *Unblocks:* about ten parts of A1 at once.

**Later in A2, when each is ready**

8. One sitting of about half an hour with Tools' checklist open: the store account, the private key-only page, and its upload tool.
9. A practice upload with Orb 2, who claims a key on an account of their own.
10. Read the words a friend will meet (the note, the notices, the AI line, the guide) and mark the roughly 150 lines of in-game text.
11. One line saying yes to desktop test builds for the friends you named. This is asked only when every safety gate is green.
12. The upload itself and the keys. Every upload is your own action; no session uses your sign-in.

**Not on this path** (each has a page or a place already; they shape A3 and A4): the close fight; the camera on a fast launch; splitting the screen sooner (a default holds; the page asks by 28 November); LB + A; the weak-enemies questions; how fast a beam flies; the signature and stamina checks on the sprint report.

**Only if the EP rules the wall-hold window into A1:** play a private build with it on, and say whether a fighter driven into a tower should stop there, and whether they end up inside the tower or at the hole when the wall gives.

## What I would not do before the first Alpha build

- **Re-read the stray-beam count for A1.** A1 asks for a first reading and has it. The reading that must pass is taken on A2's candidate.
- **Rebuild all 12 picture checks for the round planet.** A classed register with round-planet rows for the checks that hide the shipped game meets the criterion's words. The seam check is the one I would do first, afterwards.
- **Cut the missing trial clips.** The exit asks for one page per trial. The clips and their questions decide A3 and A4, not this build.
- **Draw or measure tiny and huge,** unless Orb answers no to question 3.
- **The lake dig, the chase-camera park and the wall-hold window** as part of A1.

## Risks to this path

| Risk | What it would cost | The guard |
| :--- | :--- | :--- |
| GW1c fails its first gate run on today's main. World's stage has never been run with the latest golden: its newest base (74c03fdb) is 13 commits back and from before the X-06 re-recording | Days: every record in jobs 7 to 11 waits on it | Job 3's re-run on today's main comes before anyone else re-cuts on top of it |
| The safety readings do not pass on the round planet | The friends' date moves. The audit names this as the one case where a tester's date moves for safety | Start job 13 today; the candidate is not named until it passes |
| The picture reading on small has a cause outside the size work | Small cannot be offered, and A1 would then offer two sizes | The EP's rule already allows fewer sizes; ask Orb only if it comes to that |
| Tools' queue | Both chains | Move the soak, the bench and the stills to other owners now; a second Tools lane if Orb agrees |
| Orb's sittings and the friends' evenings | One to two weeks that tokens cannot buy | Questions 4 and 5 go to Orb this week, before the work that needs them |
| The check that proves no bystander dies has not been read on the world players now get (`sim/world/tools/bystanders_check.gd:146` runs under the older-world pin) | Legal's gate G11 would be green on a narrower proof than its words | It is in job 11's register; Legal should know before the candidate |

## How this was done

The same run as the status page: nine readers, nine checkers and one completeness reader on the cheaper model (about 2.3M tokens in all), then the stand-in's own spot-checks of the claims this page leans on: CI's state and the unlisted check script, the mode test's keyboard pause and "Stay", the golden's checksum, the pin counts, the missing sizes data, the build records, Legal's gate list, and Orb's recorded answers in the vision page. The order and the recommendations are the stand-in's judgment, not the readers'.
