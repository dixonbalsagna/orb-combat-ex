# Sprint A2: from GW1c's landing to a safe package in two friends' hands

- **Who:** Orb's stand-in, as review specialist.
- **When:** 2026-11-25, about 19:20, against main at 20a483d8, with GW1c (medium only, 29 pieces) in the EP's final gate.
- **For:** the EP, on Orb's words of today: "lets get going, I want that first alpha version" and "ok, keep working full power on the alpha build" (`docs/ep/vision.md:1913`, `:1919`).
- **Base:** `docs/ep/reviews/path-to-alpha-1.md` (23 November), brought up to date. A2's goal and exit rows are the audit's (`docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md:135-177`, read under its rules at `:16-38`).
- **Standing:** a recommendation. Nothing here is decided, and every item marked for Orb is Orb's.

## The short version

1. **A1 stands at 16 of 44 exit parts today and 21 when GW1c lands,** if five records are taken on the landing commit. Of the 23 left, 5 close on one click from Orb, 11 are session work that can start now, 2 are QA's after the landing, and 5 are the planet line, which waits on big and then small.
2. **Small is A1's long pole, and it should not hold up the friends.** The friends' build can be medium only; big and small reach them later as updates. That is one plain question for Orb, asked when the package is near, not now.
3. **A2's long pole is the tester-safety readings** (Legal's gates G4, G5 and G21; the EP holds the detail). Everything else in A2 is small or medium and most of it can start today.
4. **Settle the picture early.** Anything that changes what play looks like (Camera's fixes, Orb's answer on splitting sooner, the three picture faults) should land before the readings that count are taken. Otherwise they are taken twice. So Orb should see split-sooner in play within days, not after the package work.
5. **Camera and Tools are the two bottlenecks.** Camera holds the safety safeguards, big's return and all of Orb's split-screen asks. Tools holds the packaging chain and every capture. The order below is built round those two.
6. **Four of Orb's steps have no page of their own yet** (the report server, the Deck friends, the one click, the store page sitting). Two of them, the friends and the server, are the longest waits on the path and need no build. They can go to Orb today.

**A rough size, not a promise.** A2 was priced at 34M tokens and two to four weeks; perhaps 4M of it has landed already. If the safety readings pass on the first or second try, a candidate is possible in the second week of December and the friends' evening in the week after. The holidays sit right behind that.

## 1. A1's remaining exit rows after GW1c, in order

**At the landing (5 parts close, one record each, all on the landing commit):**

| Record | Who |
| :--- | :--- |
| The CI build run for Windows and Linux, saved | Tools |
| The build numbered (`tools/version.json` still reads build 0) and its changelog entry; Orb reads the players' line before it is used | Tools, EP |
| The mode test, one result per mode on Windows and on Linux. Today's Windows results sit in a park folder under an older commit, and Linux has none saved | Tools |
| The golden's passing run on Windows (the EP's gate) and on Linux (CI) | Simulation, EP |
| Camera's own chase check on the landed tree. Only World's run exists | Camera |

**After the landing (23 parts), in the order I would do them:**

| # | What | Parts | Owner | Size | Waits on |
| ---: | :--- | ---: | :--- | :--- | :--- |
| 1 | **Orb's one click** on the numbered GW1c build: version number on screen, frame record, loading times, stills of every menu, the mode list and fighter pick and Quit seen in the real game | 5 | Orb; Tools, Performance, UI read it | S | The numbered build; a quiet window |
| 2 | **The session batch,** none of it needing Orb or the landing: closing lines on trials S3, S4 and S5 (3); one backlog adopted; the working folder committed or ignored; the pin register; the switch table cut down; the button-press probe landed; the transformation probe built (nothing exists yet) | 9 | EP, Production; Encounter, Combat, Tools; Controls; QA with Simulation | 6 S, 3 M | Nothing |
| 3 | **"Saved by a different version" shown in the game.** The sentence has a writer and check rows, but nothing in the game calls it (`ui/widgets/ui_feedback.gd:94` has no caller outside the check). A call site, or the EP's ruling that the check row is enough | 1 | UI, Simulation | S | Nothing |
| 4 | **The picture comparison with 9 November,** on cb8d7934 where it is true. Never made | 1 | Camera, Rendering, VFX; Tools' launcher | S | Nothing |
| 5 | **QA's difficulty reading** on the landed build's packed data, three levels, full sample. Two cells are left for Orb's own hands | 2 | QA; Orb plays | M | The landing; Orb's play |
| 6 | **Big's window:** Camera's door fixes (parts 1 and 2) landed, big's look taken, big measured, and the six items under "Before any size is un-hidden" in `GW1c-medium-prelanding.md` | part of 4 | Camera, World, Simulation, Rendering, UI | M + M | Job 2 of the A2 list |
| 7 | **Feet within 8 units of the drawn ground.** The feet park is not in GW1c and was last cut on 14 November | 1 | Rendering | M | Its re-cut on the landed tree |
| 8 | **Small's window,** the long pole: the ground-marks fix finished (its park is still a draft), a new fix for crater rims in the foreground in place of the one withdrawn, and a camera answer in place of door-holds part 3, which failed Game Design's condition twice. Then a second click from Orb for small and big | rest of 4 | Rendering, Camera; Orb | L | Rows 6 and 7 |

Two notes for the EP:
- Camera's page for the door fixes cites a record folder that is not on disk (`docs/camera/runs/54474b97/gw1c-door-holds-12/`). Its proof is unconfirmed until that folder is saved.
- The tracker is behind: `docs/production/status.json` has nothing from 25 November and line 418 still reads "Five selectable planet sizes".

## 2. A2's jobs, ranked

Sizes: S about 0.25M tokens, M 1.2M, L 4M, XL 8M. **Now** means it can start today beside the others.

| # | Job | Owner | Size | Starts | What it unblocks |
| ---: | :--- | :--- | :--- | :--- | :--- |
| 1 | **Land GW1c and take the five records above** | EP; Tools, Simulation, Camera | M | In the gate | The commit everything else is measured on; Orb's next build |
| 2 | **Camera's picture window.** The parked safeguards un-paused (`docs/camera/pending/cd04`, paused at the EP's word); the door fixes, parts 1 and 2; a switch in Orb's build only that splits the screen sooner, so Orb can compare both in play | Camera; Rendering for the sky change and the blast at a join | M | Re-cut now; lands straight after 1 | The first fixes for job 3; three of Orb's four split-screen asks; big's return |
| 3 | **The tester-safety readings.** The measuring chain as one command on the round planet; each reading over the line given a cause and a fix; a passing reading on the candidate; then the reading on the desktop package itself, by the method Legal rules on | Tools, then Camera, VFX, Rendering; Legal | XL | Method now; the reading that counts after job 2 | Gates G4, G5, G21. The longest pole |
| 4 | **The package chain.** The testers' details file and the check that refuses a package while the report-channel line is a placeholder (neither exists: no `tools/site-tester.json`, no check in `tools/desktop-package.mjs`); the upload script and one-step roll-back (planned only: no `tools/store/`); then the rehearsal on a spare page | Tools | S + M + S | Check and script now; rehearsal after Orb's store sitting | G9; X-30 and X-31 |
| 5 | **The two-hour soak, in CI,** Windows and Linux, memory growth recorded. No script exists yet | QA; Tools reviews the workflow | M | Now | X-25. Takes no time on this PC |
| 6 | **The one-press bench** a friend runs on a Deck | Performance | M | Now | X-24, X-26; decides whether "30 held, 40 as the aim" stands |
| 7 | **UI's package batch.** The report panel reachable with the pad; settings surviving a real restart; the AI line on the first screen; the sheet of about 150 lines for Orb to mark. Then the parked "a controller feels best" line lands | UI; Legal for the AI line's words | 4 S | Now; the parked line after 1 | X-21, X-20, Orb's reading |
| 8 | **The tester guide, the one-page sheet and the final note.** The sheet carries one row a person has to prove: pause, then close the game from the menu, on a real Deck | QA, Legal | S | Now | X-18, X-19, G9, G14 |
| 9 | **The friends' sound set:** a quiet background bed, building and menu sounds, loudness, a sheet for Orb's ten-minute listen. No music | Audio; UI for the menu sound calls | about 2M | Started | Orb's listen; Orb's "modern and accommodating" |
| 10 | **The three unexplained picture faults:** a still, a cause and an owner each, or "cannot reproduce" with the replay named | Rendering | M | Now | An A2 exit row. Any fix that changes the picture lands before job 3's reading |
| 11 | **The accessibility checklist,** then its record on the candidate | Accessibility | S | Now | G20 |
| 12 | **Legal's gate page brought up to date and the candidate's record folder laid out.** The page's lines for G5, G13 and G22 date from 13 November; the report scan and the file screen have been built since | Legal, EP | S | Now | X-02; no gate found red on candidate day |
| 13 | **The two-pad checklist run and signed** | Controls; Orb and Orb 2 play it | S | After 1 | X-07 |
| 14 | **The shot list as one data file** and its first archive entry | Community, Tools | S | Now | X-34 |
| 15 | **The candidate:** one commit, all 22 gates green, a saved record for each. About 0.6M for each re-run | EP, Legal, Tools | M | After 1 to 13 | Orb's one line |
| 16 | **Orb's line, the upload, the keys, the friends' evening** | Orb | waiting | After 15 and Orb's sittings | The package in two friends' hands |

**In parallel today:** 3 (the method), 4 (check and script), 5, 6, 7, 8, 9, 10, 11, 12 and 14, with rows 2, 3 and 4 of A1's list. These are mostly code and pages, so they share the PC as long as short gates keep to three Godot processes.

**Orders that are easy to miss:**
- **Camera's queue:** the safeguards first, then the split-sooner switch (Orb is waiting to see it), then the door fixes, then the zoom jumps.
- **Zoom jumps have no fix parked for the ordinary look.** The door fixes remove the step at a join; the rest is new work: play back Orb's latest saved match, find each jump, then decide. Camera, about M.
- **"Losing a fighter"** is partly in GW1c (the falling player stays in frame) and partly Orb's own answer on the split line.
- **Splitting sooner is a number in code** (`render/camera/camera_params.gd:7`), not a data switch. A friend of Orb's once asked for the opposite, a later split (`docs/ep/vision.md:237`), so the build should let Orb try both.
- **The report server comes before any outside package,** and the store sitting before the rehearsal.

## 3. Orb's own steps

In the order they shorten the path. Each is written the way I would put it to Orb. None has a page of its own in the homework folder yet except where noted.

1. **Ask your friends with Steam Decks.** (No build needed. Can be today.)
   Ask two, and a third as a spare. If you know two more, keep them for later so they meet the finished game fresh. Tell them the first session is 60 to 90 minutes: install it, play two matches, press one button that tests speed, send back two files. They need a free itch.io account to claim their key. Tell the EP only how many said yes. Their names never go in the project.
2. **Make the private report server.** (About 20 minutes. No build needed.)
   A new Discord server, private: no public invite, not listed anywhere, members cannot invite others, one channel for testers. This is where a friend posts their report file. Then answer one question: may we promise a friend that their reports are deleted if they ask? The friends' package cannot be made until this exists. A step-by-step page is still owed to you, with Legal's settings on it.
3. **Play the new build and do the one click.** (About 25 minutes in one sitting, when the EP says the build is ready.)
   Play a match on Easy and one on Medium, and slam someone into the same spot a few times. Then, with nothing else running on the PC, double-click `FIRST-RUN.cmd`. The game opens on its opening notice: read it and press Enter. Then keep your hands off the keyboard and mouse for about two minutes while it plays by itself, pauses, and closes. That one run proves about five things we can only prove with the real game on your screen.
4. **Try splitting the screen sooner, in play.** (About 10 minutes, when Camera's build is ready.)
   A build with a switch: play with the split as it is, then with it sooner, and say which you want. This is worth doing early, because your answer changes the picture your friends will see.
5. **The store page sitting.** (About 30 minutes, with Tools' checklist open: `docs/tools/store-page-checklist.md`.)
   Create the itch.io account with nothing personal in its name, make the restricted page that only key-holders can see, install its upload tool, and check the settings the list says must stay off. Two approvals are yours alone and are asked for separately: one for the page, one for desktop test builds going to the friends you chose.
6. **A practice upload with Orb 2,** who claims a key on an account of their own. Every upload is your own action; no session uses your sign-in.
7. **Read and listen.** Mark the roughly 150 lines of words a friend will meet, read the note and the guide, and listen to the build for ten minutes with Audio's sheet.
8. **One line saying yes,** asked only when every gate is green. Then the real upload, and the keys sent by your own hand.

One question to add when the package is near: **"The friends' first build has the medium planet only. Big and small come to them as updates. Is that all right?"** I think Orb would say yes; it is Orb's to say.

## 4. The quiet-window schedule

No schedule page exists today, though the path's rule 8 asks for one. "L" is the day GW1c lands.

**Three kinds of time:**
- **Quiet window.** For anything that measures speed. Every session stops its Godot and capture work and starts nothing. The EP announces it ten minutes ahead and Tools' guard confirms nothing is running. A reading counts only if Performance's rule holds before and after (all processors at 60% or under, `docs/perf/audit-2026-10-16.md:54`); otherwise it is void and taken again.
- **Overnight block.** One long run a night, at below-normal priority. Nothing else heavy beside it.
- **Daytime.** Short gates only, three Godot processes a session while a long run is going. A QA batch (six processes, about 25 minutes) never runs beside the EP's gate.

| When | Run | Owner | About | Kind | Who pauses |
| :--- | :--- | :--- | :--- | :--- | :--- |
| L, day | The EP's final gate and the landing | EP | no time on record; allow an hour | Daytime, up to 6 Godot | QA batches wait |
| L, evening | The numbered desktop build; the CI build run and Linux first run | Tools | CI does the long part | Daytime | Nobody |
| L, night | The clash clips re-recorded (they no longer hold a clash), then QA's difficulty batch, one after the other | Tools, then QA | 1.7 h, then 25 min a batch | Overnight | Nothing else heavy |
| L+1, when Orb is at the PC | **Quiet window 1:** Orb's play and one click; straight after, Performance's frame comparison and hitch table on the same build | Orb; Performance | 25 min, then about 45 min | Quiet | Every session |
| L+1 to L+3, days | Camera's window: side-by-sides for the door fixes and the split-sooner build | Camera; Tools' launcher | about 11 min a clip | Daytime, one capture | Nobody |
| L+1 to L+3, nights | The safety method's trial sets | Tools | about 3.9 h a set | Overnight | QA's long stages |
| After Camera's window lands | **Quiet window 2:** Orb tries split-sooner | Orb | 10 min | Quiet enough to play | Captures and batches |
| Big's window | Gate run, big's look, then **quiet window 3** for big's speed reading | EP, Camera, Performance | an hour, then 30 min | Daytime, then quiet | Every session for the reading |
| Candidate night | The full safety set on the candidate; nothing else | Tools; Camera, VFX, Rendering on call | 3.9 h | Overnight | QA; all captures |
| Candidate + 1 night | The reading on the desktop package itself | Tools, Legal's method | not known yet | Overnight | QA; all captures |
| Candidate + 1, when Orb is at the PC | **Quiet window 4:** Orb's click on the candidate; Performance's reading on it | Orb; Performance | 45 min | Quiet | Every session |
| Any time | The two-hour soak; the nightly window readings; the network check | QA, Tools, Netcode | 2 h a platform | CI | Nobody: no time on this PC |
| The friends' evening | Install, two matches, the bench, two files | The friends | 60 to 90 min each | Their Decks | Nobody |

QA's four-hour batches are not on this schedule: nothing in A2 changes the fight's numbers. If a fix does, it takes a night of its own.

## The EP's calls

| Call | My recommendation |
| :--- | :--- |
| Does A2 wait for A1 to close? | No. A1's page says Orb plays the A1 build before A2 starts landing; A2's package work has been landing since Monday, and small may take weeks. Rule that the candidate may be medium only, and put the one question in part 3 to Orb |
| What does X-17 mean for A2? | A2's exit list says X-17 must pass, but none of the gaps tagged X-17 is in A2's own list. My read: a saved check that the computer uses only inputs a player has, on the candidate. Rule it now so it is not found on candidate day |
| Camera's paused safeguards | Un-pause them today. They are the first known fix for job 3 |
| When to ask Orb about the friends and the server | Today. Both pages are small and neither needs a build |
| Rendering's order | The three picture faults before small's fixes: the first is on the friends' path, the second on A1's |

## Risks

| Risk | What it costs | The guard |
| :--- | :--- | :--- |
| The safety readings do not pass on the round planet | The friends' date moves | Start the method today; Camera's window first; no candidate until it passes |
| A picture change lands after the reading that counts | The night's reading is taken again | Job 2 and Orb's split answer before job 3's reading |
| Orb's sittings and the friends' evenings | A week or two that tokens cannot buy | Steps 1 and 2 go to Orb today |
| Camera is asked for four things at once | Everything behind Camera slips | The order under "Orders that are easy to miss" |
| A gate is red on the day because its page was stale | A day | Job 12 |
| The first-run click has never been run in a real window | Orb's sitting gives a broken record | UI confirms the keys on the first click; a step that fails is a line in the report and the numbers are still saved |

## How this was done

Three Opus readers (A1's open rows; the A2 package and Legal's gates; the long runs and the camera parks), about 0.45M tokens, with no second readers. My own checks: Orb's words in the vision page; the missing caller for the "different version" sentence; the missing store folder, testers' file and channel check; the version file; the first-run sizes file; the split number; Camera's missing record folder. Not read: the CI results on GitHub, most run records, and QA's sample-size page. Durations marked "about" come from the nearest record, not from a run of the same thing.
