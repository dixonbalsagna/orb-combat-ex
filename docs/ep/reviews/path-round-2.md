# The path to Alpha: second adversarial round

From Orb's stand-in, for the Executive Producer (EP). 2026-11-14, on HEAD 8fee3caa. Read-only: no repo file was changed except this one, nothing ran in Godot or a browser, and no git state was changed.

**What was attacked:** the amended path (`docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md`, called "the path" below), its 100 briefs (`05-directives/<milestone>/<role>.md`, called "A1/ep.md" and so on), the sprint plan (`docs/ep/sprints/A1-sprint.md`, "the sprint"), Production's tracker (`docs/production/`), and what has been written since: the spike pages, the planet design, the parks.

**Words used here.**
- **Golden record:** the saved reference matches. A **golden window** (GW1 to GW4) is a landing that changes them; replays from before it stop verifying. GW1 is split into **GW1a** (main becomes the 9 November game, bit for bit) and **GW1b** (small rule changes, the "riders").
- **Park:** finished work waiting outside main for the EP's gate.
- **X-nn:** an exit criterion from the Alpha specification. **A-XXX-nn:** a row of the audit's gap register. **ADD-A1-nn:** a row the EP added to the tracker for Orb's planet scope.
- **Spike S1 to S5:** throwaway trials (beam, gravity well, horde, move table, Linux picture).
- **Stamp / build id:** the id a build writes into its replays (row A-NET-05), so another build refuses them.

Orb is quoted only from `docs/ep/vision.md`, word for word, with the line number. Lines there that the EP wrote as a summary are called the EP's reading.

---

## 1. In short

What must change before more of A1 lands, and before A2 starts:

1. **Rule where the round planet's default goes.** GW1a cannot close as written: its target record plays the old arena, and the round-planet group changes that default inside the same window (R2-01). Then land every value that moves the golden record as one stacked batch shown equal to the target (R2-05).
2. **Put one stop line in the files and ask Orb which it is.** The sprint holds a 66% pause and an 85% rule at once, and the newer one is labelled "(Orb)" though Orb's recorded words do not contain it (R2-02).
3. **Correct the records that say Orb decided things the files do not show.** Sprint line 3, the quoted "decision 5" in flight-3500.md, the tracker's rows 11, 12 and 14, and the stop rule written as fact. Write down what Orb was shown when they said "Go with recommendation on all" (R2-03, R2-16).
4. **Agree the beam-escape test's wording (X-16) before QA builds its probe**, and put the open beam-speed question to Orb with the S1 clip (R2-04).
5. **Break the desktop-build approval loop the right way.** A1's own exit needs a CI run that today refuses without an approval the path schedules for A2. Legal rules, Tools codes an owner-only route. Nobody records Orb's yes early (R2-06).
6. **Fix the sprint's steps 6 and 7 and say how Orb's 9 November play files are replayed.** The first desktop build belongs on GW1a's commit, and a stamped build refuses those files by design (R2-07).
7. **Give Orb's added planet scope a home.** One owner and one row per item, rows moved not duplicated, named windows, a done test each, an A1 exit block, and Orb's private play of the building fix on the schedule (R2-12 to R2-15).
8. **Before A2 is briefed:** the tester-file rule goes into four more briefs, the privacy wording is corrected before Orb reads it, decisions 20 to 22 move up, and A3, A4 and A5 are re-priced with Orb's A4 page corrected from 48M to 57M (R2-08, R2-10, R2-17 to R2-20, R2-24).

---

## 2. Blockers

### R2-01. GW1a cannot close with the round planet's default in it

*From R2-AM-01 and L2-01. Both checkers: holds.*

**What is wrong.** GW1a closes only when main reproduces the target record bit for bit. The target's matches name no planet, so they play the old arena. The round-planet row (A-WORLD-01) sits fourth in GW1a's order and makes a match with no planet key play the round planet. Both tests cannot pass on one commit, and nothing later may land until GW1 closes. World's park also switches on the random planet per quick match in GW1a, where the path says "nothing is meant to differ". Separately, the target does not test the game Orb plays on the planet: no golden recipe digs on a generation-3 planet.

**Evidence.**
- path:26 "A-CODE-01 closes when main reproduces that record bit for bit"; path:81 lists "the round planet (A-WORLD-01)" among the groups.
- sprint:24 keeps "round planet" in GW1a's order.
- A1/world-environment.md:26 "A check starts a match with no planet setup key and reads back a generated planet, not the arena"; :34 A-WORLD-01 "lands only in golden window GW1". Its amendments (:44-48) do not move the flip.
- `docs/sim/runs/6a30b4c9/gw1a-target/README.md`:28 "main's default-arena matches move and can't reproduce this record"; :30 "That's the EP's and World's call".
- `docs/world/pending/a-world-01/data-switches-gw1a.diff`:85-89 sets `"mode": "planet"` and `"random": { "enabled": true`.
- `docs/world/pending/globe-step2/README.md`:26 "no golden recipe digs on a gen 3 planet"; path:102 asks for "A golden record ... for the configuration Orb plays".
- No EP ruling found in docs/ep, docs/production or the sprint.

**The fix.** The EP picks one of the two routes Simulation's own page names (README:29) and writes it into the sprint and A1/ep.md:

| Route | What it means |
| --- | --- |
| A. Move the flip | World's data switches stay in GW1a. The default flip and the random draw become named GW1b riders, re-recorded once after GW1b. World re-cuts its park in two. |
| B. Name the arena | The golden recipes and the arena-only checks add an explicit arena key, so the default does not reach them. The bit-for-bit match can then close inside GW1a. The random draw still has to leave GW1a. |

Either way Simulation adds, to GW1b's one re-record, at least one recipe on planet 7 at generation 3 with a crater and a slide.

**Who.** EP (ruling); World (park re-cut); Simulation (recipes); Production Ops (GW1 row list).

**If left.** A1's first exit cannot pass, and every later landing waits behind it.

**Checker's corrections.** "Only flight 3500 moved to GW1b" was wrong: five riders moved (A1/ep.md:55). "Can never be reproduced" was too strong: route B exists.

### R2-02. A1 has two stop lines, and the newer one is labelled Orb's without Orb's words

*From COST-01 (holds), with the parts of COST-02 and COST-07 that survived checking.*

**What is wrong.** The sprint says A1 pauses for Orb at 66% on the all-models meter. Further down it says that share "is replaced" by "press a reset at about 85% or Fable about 90%", under "Updated 2026-11-14 (Orb)". Orb's recorded words that day give a fact about resets and no new rule. Three other files still carry the old line. A third, older reset rule sits just below. Nobody following the files can tell which binds, and the gap is about 19 meter points.

**Evidence.**
- sprint:9 "A1 runs until the all-models meter reads about 66%, then pauses for Orb."
- sprint:98 "**Updated 2026-11-14 (Orb):** ... press one when all-models reaches about 85% or Fable about 90% ... The 40% share above is replaced by this rule."
- sprint:103 (kept "for the record") "about 90% while the all-models meter is under about 60%".
- Orb, vision.md:1887: "I just found out the fable token reset also resets the tokens used from the normal weekly pool, so that's more incentive to give my stand-in more specialist workflow. keep everything going according to plan." No 85%, no word on the 40% share. vision.md has no "85%" anywhere.
- vision.md:1813 ("It also accepts the EP's A1 budget of up to about 40% of this week") is the EP's reading; Orb's words at :1804 are "Go with recommendation on all".
- `docs/production/token-record.md`:13 and :41, `milestones.md`:11 and `status.json`:233 still say 66% and the old reset rule.
- The last meter reading in any file is 22:07 on 13 November (`progress.md`:24).

**The fix.** The EP relabels sprint:98 as the EP's proposed rule built on Orb's fact, and asks Orb one plain question (see section 4, item 1). Until Orb answers, the EP says in the sprint which line holds. Production Ops then makes the four files say one thing, and logs both meters at each check-in.

**Who.** EP; Production Ops for the tracker and token record.

**If left.** A week's allowance is spent past the point Orb was told A1 would pause, on a rule attributed to Orb. The choice is Orb's: it is their allowance and their resets.

### R2-03. Several records state as Orb's decision what the files do not show

*From L4-02. Checker: parts (a), (b), (d), (g) hold; (c) holds for decision 14 only; (e) and (f) are wording about a future step, not false records.*

**What is wrong, part by part.**

| Part | Record | What the files show |
| --- | --- | --- |
| a | sprint:3 "Orb accepted every recommendation in the path's decisions table" | The sprint itself lists rows 16 (rest), 17 and 20 to 23 as "Still open" (:80-83). The EP's reading at vision.md:1805 limits it to rows 2 to 6, 11 and 14. |
| b | The scope of "Go with recommendation on all" (vision.md:1804) | No file records what Orb was shown. `08-orb-answers.md`:27 says rows 2 to 6, 11 and 14 "were not on Orb's page ... None is taken by silence." A1/orb.md does list those questions (:11-15, :20, :22), but nothing says that was the page. |
| c | Tracker rows 11 and 14 "accepted" (`milestones.md`:54, :57) | Decision 14's own recommendation is "decide from spike S1" (path:538). path:36 says 11 to 14 are "confirmed ... from the spike pages". |
| d | "the terrain-mesh overhaul itself after Alpha" recorded as accepted (vision.md:1807, the EP's reading) | In the same message Orb asked: "I do want the planet, terrain, destruction, clipping all worked on heading towards the A1" (vision.md:1804). No file reconciles the two. |
| g | `docs/design/flight-3500.md`:3 puts quotation marks round "flight 3500 as the default in every mode, with the slider dropped." as "Orb's decision 5" | Those are the path's words (path:529), not Orb's. |
| e, f | A5 and A6 Performance briefs say "the figure Orb confirmed"; path:365 says the RT + B reading is "shown to Orb" | Both describe steps not yet taken. No Orb page carries the RT + B line. |

**The fix.**
1. The EP writes into `docs/ep/reviews/` the exact text Orb was answering on 13 November night, as was done for the stand-in's four questions.
2. sprint:3 becomes "decisions 2 to 6, 11 and 14, on the EP's reading of 'Go with recommendation on all'".
3. The terrain line goes to Orb as one question (section 4, item 2).
4. Production Ops marks rows 11 and 14 "accepted as a direction; confirmed from the S1 and S2 pages".
5. Game Design removes the quotation marks at flight-3500.md:3.
6. The EP rewords the two Performance briefs to "the figure Orb confirms after A2's reading (not confirmed yet)", and either puts the RT + B interim on Orb's A1 page or strikes "shown to Orb".

**Who.** EP; Production Ops (tracker); Game Design (one line).

**If left.** Builders start work on answers Orb has not given. The path's own rule 5 says "No decision is taken by silence" (path:21).

### R2-04. The beam-escape test (X-16) has no agreed wording, and its numbers hang on an open question

*From L4-01 (checker: holds, high confidence) and L2-10 (checker: "cannot pass" is overstated, medium confidence). The corrected statement is used.*

**What is wrong.** X-16 must pass at A3: a sidestep makes the beam miss at three ranges. The A3 briefs add "each time". The S1 trial shows a defender who starts moving after the fire, at 20 body heights, is hit even by the smallest beam, and bigger beams arrive before anyone can leave the line. A defender already moving is missed at every range tried. So the test passes or fails depending on a reading nobody has fixed. Game Design proposed a wording by range and beam stage and asked for it to be agreed. It is in no path table, no done test and no QA brief. The beam's speed, which moves every row, is still open with Orb. QA's probe for X-16 is an A1 item, so the wording is needed now.

**Evidence.**
- path:192 "a scripted defender's sidestep makes the beam miss at three ranges"; A3/qa-balance.md:24 "the beam misses each time (exit X-16, must pass)".
- `docs/director/s1-beam-in-space-trial.md`:51 "Up close, stages 3 and 6 arrive before anyone can leave the line"; :31-33 stage-1 misses for a moving defender.
- `docs/design/beam-physics.md`:110 "Both: slow the bottom of the curve, and agree X-16's wording".
- path:352-368 (the changed-criteria table) has no X-16 row; `docs/production/done-tests.md`:26 still reads "at three ranges".
- `docs/ep/reviews/stand-in-questions-2026-11-14.md`:23 beam speed: "No. There was no recommendation to accept".

**The fix.** The EP adds an X-16 row to the path's changed-criteria table and to done-tests.md with Game Design's rows as a working target, and amends the two A3 briefs and QA's A1 probe brief to match. The wording goes to Orb under the S1 clip with the beam-speed question. Game Design fixes the speeds before GW2 opens.

**Who.** EP, with Game Design, QA and Production Ops.

**If left.** QA builds the probe to one reading and A3 is judged on another, or speeds are re-tuned inside GW2.

---

## 3. Majors

Safety, Legal and tester matters first, then A1's windows, then the added planet scope, then decisions, then cost.

### R2-05. Inside GW1a, a group landed alone has no test it can pass, and most of the fight is in no group

*From L2-02 and R2-AM-06 part (b). Both hold.*

**What is wrong.** Each of the eight groups owes "its own gate run and its own side-by-side". But the target needs every kept data file at once, so the golden check is red from the first group that carries a golden-moving value to the last. No brief says what a mid-window gate run is compared with. And 33 of Encounter's 37 values, Simulation's fight rows and the two energy words in power.json belong to no named group. The pad Orb plays is split between Controls' file and Encounter's stick rows.

**Evidence.**
- path:81 "one owner at a time, each with its own gate run and its own side-by-side"; sprint:24.
- gw1a-target/README.md:25 "The kept build's data, every file"; :34 the energy words "move every match".
- `docs/director/pending/director-rows/README.md`:16 "no group is named for them in the path"; :42 "Parity: the golden check fails, as it must".
- `docs/controls/pending/pad-group/README.md`:40 "Until those land, a build from main is not the game Orb played".
- A method exists only in a park: commit ac0ae1f7 "golden byte-identical alone and with the kept data equals GW1a's target".

**The fix.** The EP changes sprint step 5: every golden-moving value is stacked in one scratch tree, shown equal to the target, and landed as one batch with one gate run and one side-by-side. Groups that do not move the golden (camera, look, sound, menus) still land one owner at a time. Or, if one-at-a-time is kept, each group's gate run is made on a scratch copy of main plus the kept build's remaining data and must equal the target.

**Who.** EP, with Simulation.

**If left.** Main sits red for the whole window and "read CI after every push" tells nobody anything.

**Checker's note.** "Red from group 2" was not measured; nobody ran the computer opponent's three rows alone.

### R2-06. A1's desktop build needs a CI run that refuses without an approval the path schedules for A2

*From R2-AM-02 and L2-04. Both hold, high confidence.*

**What is wrong.** A1's exit X-29 needs "one CI run" that makes both desktop builds, and rule 7 takes the first stills from CI. The desktop workflow's first step refuses unless Orb's approval file is in the commit. That approval is recorded only when the outside-tester gates are green, which is A2's goal, and the flash gate is red today. Legal's ruling does give an owner-only route with no approval, but it is not coded, and it forbids keeping the program as a run file, which is how the Windows bench and still jobs get the game. Second, the loop from round one is intact: Legal still wants the approval inside the commit being built, so recording it makes a new commit with no gate records.

**Evidence.**
- path:98 X-29; path:23 "Stills from the Windows and Linux builds come from CI"; path:531 the approval "is recorded when the gates are green and not before".
- `.github/workflows/desktop-builds.yml` (working copy):55-66 "Refuse without Orb's recorded yes"; :193 and :226 `needs: desktop`.
- `docs/legal/desktop-build-rulings.md`:23 "No upload at all for an owner-private build"; :34 and :56 "in the commit being built".
- `docs/legal/outside-tester-gates.md`:16 G8 asked "only when G1 to G7 and G9 to G19 are green".
- A2/ep.md:40 "Do not record the yes early to break the loop."
- `docs/tools/s5-linux-still.md`:24 a run refused "as designed".

**The fix.** Legal rules how the approval names the gated commit so that recording it does not orphan the gate records. Tools codes Legal's "audience" input before sprint step 7: an owner-only run needs no approval, keeps no program, and builds the Windows program on the Windows runner so bench, hash and still run in one job. X-29 at A1 is read on that run. The outside-testers run keeps today's lock. Rule 7 already gives the fallback "Orb starts it once"; the EP says on Orb's A1 page that this is how A1's stills are made until the route exists.

**Who.** Legal (ruling); Tools (workflow); EP (order, Orb's page).

**If left.** Pressure to record Orb's yes early. That yes is a safety approval and only Orb gives it, on green gates.

### R2-07. The first desktop build is in the wrong step, and Orb's 9 November play files are refused by any stamped build

*From L2-05 and R2-AM-06 parts (a) and (c). Both hold.*

**What is wrong.** The amendment puts the first desktop build and its same-replay comparison on GW1a's closing commit, before the riders, because nothing is meant to differ there. The sprint builds it after GW1b. Separately, the path says Orb's 9 November play files "still verify" on that commit. The build id lands before the window, and a stamped build refuses a file with no build field by design. That also blocks Camera's planned flash reading of a real match replayed from Orb's save.

**Evidence.**
- path:26; A1/tools-pipeline.md:60 "on GW1a's closing commit, before the riders land".
- sprint:26 "6. GW1b: the riders", :27 "7. The first desktop build".
- `docs/ep/reviews/B1-replay-build.md`:20 "An old save on any *new* stamped build is refused, by design".
- `docs/camera/a1-flash-readings-plan.md`:33.
- `tools/preview/blackbox.mjs`:201: the existing `--home` override cannot name an unstamped save.

**The fix.** The EP restores the order in the sprint. Simulation and Tools extend the existing tools-only override so it can mean "an unstamped save", and add it to `blackbox-verify.mjs`; the game itself keeps refusing. path:26 is reworded to "verify through the tools' replay path". B1's three fixes land before step 7.

**Who.** EP (order); Simulation and Tools (override).

**If left.** The one comparison that proves "main is the game Orb plays" is made on a commit where things are meant to differ, or cannot be made.

### R2-08. Four briefs still tell directors to save testers' files in tracked folders

*From R2-AM-03. Holds, high confidence.*

**What is wrong.** Rule 3 says a tester's raw files never go into the repository. Only four briefs carry it. Four others still save friends' answers or bench files under tracked `docs/*/runs/` folders of a repository the path calls public. Legal's tester wording promises deletion on request, which a commit cannot honour.

**Evidence.**
- path:19 rule 3; path:14 "each affected brief carries the same change".
- A2/audio-music.md:22 "saved under `docs/audio/runs/<sha>/deck/`"; A2/controls-feel.md:22; A4/performance-platform.md:24 "the bench files returned by testers are saved under `docs/perf/runs/<sha>/`"; A5/rendering-techart.md:21.
- `docs/legal/tester-folder-notices.md`:30 "If you want your reports deleted, tell Orb."

**The fix.** Append the rule-3 amendment to those four briefs. Name the one git-ignored folder in A1/ep.md's ignore-line amendment. Tools' content screen refuses a staged tester file under those paths.

**Who.** EP (briefs, ignore line); Tools (screen).

**If left.** A friend's material is committed and pushed, and the delete promise is broken. Privacy and Legal.

### R2-09. The flash safety gate reads the browser build; friends get the Linux desktop program

*From R2-AM-04. Checker: holds in corrected form.*

**What is wrong.** The flash gate (G4) is the one gate Legal calls a risk to a person. Its release pass is keyed to the browser export. The capture of desktop frames is an A2 Tools row (A-MARKET-03), but the brief's order lets it land after the hand-out, no A2 exit line requires a desktop reading, and G4 can pass on a record that only names which build was read. The "Deck's default picture level" part cannot be met before A5, and A5/tools-pipeline.md has no G4 line.

**Evidence.**
- A2/tools-pipeline.md:60 "Once a desktop capture exists ... until then gate G4's record says which build it was read on"; :53 criteria 8 to 11 "beside all of it".
- `tools/flash/release-pass.mjs`:10.
- `docs/legal/outside-tester-gates.md`:30 "it is the only gate where a person could be hurt."

**The fix.** Legal adds to G4, before A2's hand-out: either the clips are read on the Linux desktop build's own frames at 1280 by 800, or a written ruling that the browser reading stands for the desktop package and on what evidence. The EP makes it an A2 exit line and adds a re-read at the Deck's default level to A5.

**Who.** Legal (G4's definition); Tools (capture); EP (exit lines).

**If left.** A friend plays a build whose own picture was never read for flashing. Player safety.

**Checker's correction.** The capture does have a row, an owner and a milestone; what is missing is anything that makes the reading happen before the first session.

### R2-10. The tester privacy wording says reports are read "on Orb's PC"

*From R2-AM-11. Holds, high confidence.*

**What is wrong.** The amendment's wording says a tester's report is "read with AI tools on Orb's PC". Every role here is a Claude Code session, so a report's contents go to an outside AI service. The phrase tells a tester the opposite of what the first review asked for. The wording Legal has closed names only the report channel: no itch.io account, no AI reading. If Orb is shown it now, the A2 fix changes it and Orb reads it twice.

**Evidence.**
- A2/legal-ip.md:46 "what a tester posts is read with AI tools on Orb's PC. You choose the words."; path:28.
- CLAUDE.md:9 "every role runs as its own Claude Code session".
- `docs/legal/tester-folder-notices.md`:30; `docs/legal/review-log.md`:293 (RL-264) "Closed on the wording; open until Orb has seen it".
- The phrase came from the first review's own proposed fix (`06-adversarial/pc-safety-legal.md`:19).

**The fix.** Before Orb is shown RL-264's wording, Legal adds two sentences: an itch.io account is needed to download (if the rehearsal confirms it), and reports are read with the help of AI services run by another company. The EP corrects path:28.

**Who.** Legal (wording); EP (path text).

**If left.** A privacy statement that is not accurate goes to friends. Legal.

### R2-11. A5's exit still rolls back the real build on the channels friends use

*From R2-AM-05. Holds, with one sub-claim struck.*

**What is wrong.** Rule 1 and the A5 Tools amendment move the update-and-roll-back rehearsal to a dummy channel no tester's key can see. A5's exit line, A5/ep.md, Production's tracker and Orb's own A5 page still do it on the real channels. The audit's platform notes also say a key gives full download access, so a channel hidden from key holders is not shown to exist.

**Evidence.**
- path:17 against path:280 "X-31 (must pass with the real build) ... updated once and rolled back once".
- A5/orb.md:12 "put the A5 build up, apply it as an update, go back to the previous build, come forward again".
- A5/ep.md:25; `docs/production/milestones.md`:484.
- `02-areas/web-checks.md`:12 "gives one person full download access".

**The fix.** Reword X-31 at A5 everywhere: the build is pushed once to each real channel after rule 1; update and roll-back are rehearsed on a second restricted page with no tester keys. Amend A5/orb.md action 3. Tools confirms in the A2 rehearsal whether a channel can be hidden from a key.

**Who.** EP; Tools; Production Ops.

**If left.** Orb follows their own page and does on the live page what the path's rule says not to.

**Struck by the checker.** "Serves friends a build outside the gate rule": the A4 build a roll-back restores had passed the gate on its own commit.

### R2-12. Orb's added planet scope has no windows, no exit line, and is booked twice

*From L2-03 (corrected), COST-05 and L4-07 (both hold).*

**What is wrong.** Orb asked for the planet, terrain, destruction and clipping toward A1, with five sizes (vision.md:1804). Five things follow that the plan has not absorbed.

| # | Gap | Evidence |
| --- | --- | --- |
| 1 | A1's stop line is the path's exit list, which names none of the added items. A1 can close without them, or stay open with no test of when they are done. | sprint:12; path:97-106. |
| 2 | The scope adds two or three hash-changing landings after GW1b. The path says there are four windows and that A1 replays still play on A2. | sprint:38; `docs/ep/proposals/planet-a1-design.md`:253 "Three hash windows for this scope beside the sprint's own"; path:63; `docs/production/change-control.md`:12 and :40. |
| 3 | The same work is scheduled twice under different ids and owners. | ADD-A1-02 against A-WORLD-03 and -04 (GW2, A3); ADD-A1-03 (World) against A-WORLD-05 (Rendering, A5); ADD-A1-01 against A-WORLD-08. `milestones.md`:307-309, :374; path:290. |
| 4 | Later briefs still assume terrain step 2 lands in A3. | A3/ep.md:40; A3/tools-pipeline.md:43; A5/rendering-techart.md:39. |
| 5 | The tracker adds "about 12M" on top of the path while A3 still shows 53M and A5 16M. No displaced row is named, which change control asks for. | `milestones.md`:11, :19, :21; path:480 "with the row it displaces named". |

Done tests for terrain, destruction and clipping "still need the EP's confirmation" (`done-tests.md`:49). The design says what A1 can reach "is short of the sprint's own line" (planet-a1-design.md:242).

**The fix.** Production Ops moves the register rows to A1 and deletes the ADD duplicates, so A3 and A5 drop by what moved. The EP names the extra windows in the path, says they close before the A1 build is cut for Orb (or what waits for GW2), and corrects change-control's A1 row. The EP adds an "added by Orb" block to A1's stop line with one countable test per item, each marked must-pass or "carried by name on Orb's answer".

**Who.** EP; Production Ops; World, Rendering, Camera for the re-homed rows.

**If left.** A hash change slides into A2 and breaks "A1 replays still play", or A1 never has a moment it is done.

**Checker's corrections.** The overlap in tokens cannot be shown line by line, because the 12M has no breakdown. "Camera re-tunes twice" is inference. The sprint and the design do not disagree on the start: after GW1b is also after GW1a.

### R2-13. Five planet sizes: no pass number, no Deck reading, no size named on any exit line

*From L2-07 (holds), L4-03 and COST-10 (both corrected).*

**What is wrong.** Orb's words: "Five different planet sizes should be achieved along with this." (vision.md:1804). The path still says one size and lists world sizes as after Alpha.

| Gap | Evidence |
| --- | --- |
| The path's own condition for sizes at Alpha was Deck readings per size. None is planned. | path:340 "needs Deck readings per size"; A2/performance-platform.md:21 names no size. |
| The size done test has no pass number and no same-planet check per size across platforms or LAN PCs. | `done-tests.md`:19; planet-a1-design.md:109 "has no number in the sprint". |
| No exit line says which size it is read on (frame rate, loading, soak, bands, the lap). | `done-tests.md`:23, :28, :30, :36-39. |
| LAN is fixed to planet 7 with no size key. | `net/lan.gd`:29-30. |
| "Selectable" needs a menu row; the start menu shows Custom planet as "Coming". | `docs/ui/pending/a1-start-flow/README.md`:13; A4/ui-ux.md:24. |
| Nobody has ruled how a random quick match picks its size, or three distances that do not scale. | planet-a1-design.md:122, :134-137. |
| A random planet per quick match means a first bake every match: 6 to 9 s at big and huge. | planet-a1-design.md:94, :99. |
| A lap takes 12 s on tiny and 176 s on huge; nothing says at which size the balance bands hold. | planet-a1-design.md:47. |
| The path, X-11's rewording and A-WORLD-08 ("nice") were never updated. | path:358, :447; `03-gap-register.md`:76. |

**The fix.** The EP writes one size rule: every exit line is read on medium unless it names a size; a size goes into a tester's package only after a Deck bench file exists for it. X-11 is rewritten with the five sizes and a planet fingerprint per size. Game Design rules the quick-match pick, the three distances and which sizes the bands are held on. Performance's bench names its size. Netcode says whether Alpha LAN is medium only. UI's size row is briefed for A1, or "selectable" is restated as "by setup key" and put to Orb with the open tiny-and-huge question. The design's planet pool per size (planet-a1-design.md:100) goes into a brief.

**Who.** EP; Game Design; Performance; World with Tools; Netcode; UI.

**If left.** Four of five sizes ship unmeasured, or the sizes' test is argued at the end of A1.

**Struck by the checkers.** The Deck was not the path's reason for deferring sizes (the reason given was "a frame-rate study that does not exist"). Five five-minute benches do fit a 60 to 90 minute session.

### R2-14. The building rebound is booked three times, and its only fix bundles a setting Orb said to hold

*From L2-08 (holds), COST-09 (corrected) and part of L4-07.*

**What is wrong.** Orb wants the ricochet off background objects "squashed as we head to A1" (vision.md:1881). It is A-WORLD-10 in GW2 (World), ADD-A1-03's second half in A1 (World with VFX), and ADD-A1-05 in A1 (Encounter, unpriced). Its done test, "an angle or speed the contact cannot explain", cannot be counted. The fix already exists as one switch row of five values in World's data. One of the five changes what the other fighter does while one is lodged in a building. On that, Orb's recorded answer is "[x] Wait until I play it" (vision.md:1862). The row is held for a QA city read that is not on file. No page schedules Orb's play.

**Evidence.**
- `milestones.md`:309, :311; path:214; A3/qa-balance.md:44.
- `tools/preview/switches.mjs`:165-166 (lodgeHold, wallRebound, wallStop, wallDepthHold, repeatMarks; held "waiting on QA city read").
- planet-a1-design.md:213 "The fix exists"; :215 "So this is not the team's to switch on."; :218 a countable read ("pass: 0").

**The fix.** One row, one owner (World, with QA). World splits the row: the rebound, stop and depth values as the bug fix; the lodge value left as today. QA runs the 40-match city read on a scratch copy. Tools cuts a private build with the full row for Orb, and the sprint gains a step for that play. The fix half lands on QA's read; the lodge half lands only on Orb's word. Whatever of A-WORLD-10 covers outcrops and terrain stays a row in GW2.

**Who.** EP; World; QA; Production Ops.

**If left.** Either a setting Orb asked to play first lands unplayed, or the bug Orb wants gone before A1 waits on a session nobody booked.

**Checker's corrections.** The rows cover outcrops and terrain as well as buildings, so merging all three into the one switch would drop half. The design gives no price. "Orb's to play first" applies to the lodge value, not to the rebound value as such.

### R2-15. Rendering carries unpriced A1 work, and the flash readings are planned before a look change

*From L2-09. Checker: holds in corrected form.*

**What is wrong.** Drawing craters, trenches and grooves is code in `render/core` and `render/shaders`, which neither World nor VFX owns. The sprint and tracker give it to World with VFX. The picture per size has no owner in any brief and the design calls it the largest piece. Rendering's A1 figure (2.6M) includes neither. Separately, the flash readings briefed on day one are planned on a stack that leaves out the marks drawn under the fighters, so a reading taken before that lands is not the record A2's gate list needs.

**Evidence.**
- sprint:48; `milestones.md`:309; planet-a1-design.md:172-181, :189, :246.
- `docs/world/pending/planet-sizes/README.md`:36 "`render/core/tile_field.gd` hard-codes the medium planet".
- `docs/camera/a1-flash-readings-plan.md`:17-21.

**The fix.** The EP re-briefs the drawing half and the per-size ground to Rendering as named, priced A1 items; Production Ops corrects ADD-A1-03's owner. The sprint says: readings now are diagnostic; the reading that counts is taken on the commit after the last A1 look change.

**Who.** EP; Rendering; Production Ops.

**If left.** The largest unbuilt piece of the sizes has nobody building it.

**Struck by the checker.** VFX does own `render/vfx/`. The readings were briefed on day one, not started. Sizes do not change the medium planet's look.

### R2-16. Four records disagree on whether the close fight is decided, and the stop rule is written as fact

*From L2-11 and L4-06. Both hold, high confidence.*

**What is wrong.** Decision 12 has two halves. On "whose stick moves whom", Orb answered in words before any clip: "I very slightly lean towards the 'magnetic' feel of both players moving with one stick but the new system sounds a lot better" (vision.md:1887). The stand-in's record says "Yes: B." The sprint and tracker say open, ask after S2's clip. Three A3 amendments say that part is not built until Orb answers from the clip. On "how much gravity well", Orb has never been asked. The stop rule (the snap moves to GW3 if not playable at A3's midpoint) is written as plain fact in the tracker and two A3 briefs, though the standing yes was not given: Orb's answer was "KEEP WORKSHOPPING, PLAYER AGENCY MUST BE RESPECTED" (vision.md:1800). Last, X-13's "the gravity well's pull" must pass at A3 but names no event a probe can read, and the stop rule would move the snap out of A3.

**Evidence.**
- `stand-in-questions-2026-11-14.md`:21; sprint:79; `milestones.md`:55, :374.
- A3/simulation-engine.md:49 "build size and zones only"; A3/ep.md:48; A3/encounter-systems.md:51.
- `08-orb-answers.md`:16 "The standing yes was NOT given".
- path:195; path:513; `docs/design/gravity-well-reading.md`:62 "The draw acts only in silence".

**The fix.** The EP writes one status line into the sprint and Production Ops regenerates the tracker from it (the source is `docs/production/tools/milestone-data.mjs`:80): the new close fight is the working default on Orb's words of 2026-11-14, given before any clip; S2 builds both; Orb confirms under S2's clips before the close-fight part lands; how much well is not yet asked; the stop rule has no standing yes. The EP defines X-13's pull as an event in the match feed; Simulation adds it and QA reads it.

**Who.** EP; Production Ops; Simulation; QA; Game Design (workshop page).

**If left.** A builder reading one page starts the new mode now; a builder reading another builds size and zones only.

### R2-17. A3's weight has moved onto the one queue that sets the date, and nothing was re-priced

*From L2-06 and COST-04. Both hold, medium to high confidence.*

**What is wrong.** The path says Encounter's queue sets the date. Since the spikes: the beam (carried as an L, 4M) is "large at least, extra-large if every answer is kept", with two rulings that add work; the gravity well itself is "large, not extra-large" against 12M carried under Simulation; and the new close-fight mode is "not sized", sits in Encounter's 4,305-line brawl file, and has no row of its own. The load table counts lead rows only, so Encounter shows 9.4M in A3 and is absent from the over-10M list. A2's work-ahead names Simulation for the well, when the piece that needs the head start is Encounter's. The stop rule guards the snap, which the design suggests is the small part.

**Evidence.**
- path:507, :553, :560, :581, :175, :513.
- s1-beam-in-space-trial.md:61; beam-physics.md:114-115.
- `docs/ep/proposals/gravity-well-trial-design.html`:505, :535, :537, :539-540.
- path:484 "Each spike's page counts as a change request."

**The fix.** Before A2's work-ahead is briefed, the EP and Production Ops redo A3's load by builder; carry A-COMBAT-01 at XL; add a row for the close-fight mode owned by Encounter, sized after S2's step 1. Encounter, which has no A2 rows, works ahead in A2. Game Design lists which beam answers stay for Alpha. If Encounter's A3 total passes about 15M, the EP brings Orb the path's three-way choice (smaller version, later date, or something moves out).

**Who.** EP; Production Ops; Game Design.

**If left.** A3, already "the milestone most likely to overrun" (path:216), overruns on the one queue with no slack.

**Checker's note.** The roughly 20M figure for Encounter is the reviewer's estimate; no file states it.

### R2-18. A5 gained three pieces of work and kept its weeks and exit list

*From R2-AM-07. Holds, high confidence.*

**What is wrong.** Amendments put the numbers window ("one to two weeks of its own"), a friends' round on the A5 build (one to two weeks) and three read-and-adjust rounds into A5. Its range is still 1.5 to 3 weeks. The window is last and the build must be gate-green before it is sent, so the friends' round follows it. Rendering's row closes on a Deck bench file per level; Orb is told to ask for one five-minute test. X-10's run length "must pass at A5" has no A5 exit line.

**Evidence.** path:60; path:48; path:233 against path:273-282; A5/ep.md:24, :39, :46-47; A5/encounter-systems.md:19 "as one change set"; A5/rendering-techart.md:21; A5/orb.md:41.

**The fix.** Re-state A5 as about 3 to 5 weeks, or send the picture build to the friends before the numbers window with its own priced gate run. Say the three rounds run on a scratch copy and land once. Make the Deck ask one run per level. Add X-10's run length to A5's exit lines.

**Who.** EP; Production Ops.

**If left.** The date is short by two weeks or more at A5 alone.

### R2-19. A4 is the largest milestone with the shortest range, and Orb's page gives its cost about 9M low

*From R2-AM-08 (holds) and COST-08 (corrected).*

**What is wrong.**

| Item | What the files say |
| --- | --- |
| A4's price and weeks | 57M in 2 to 3 weeks (path:59). A1 is 55M in 2 to 4; A3 is 53M in 3 to 5. |
| Orb's A4 page and A4/ep.md | "about 48M ... about 10M less" (A4/orb.md:48; A4/ep.md:27). |
| The smaller move table | Already inside the 57M (path:38 "the smaller move table at 13M"), so it cannot be saved again. |
| The lead brief for the move table | Still "about 8M ... about 4M (L) for the smaller version" (A4/combat-choreography.md:32). The 13M line was appended to Game Design's brief, which does not lead that row. |
| Over-10M list | Leaves out Combat in A4 (13M with the carry) and Simulation in A3 (13.4M) (path:581). |

By the checker's arithmetic, A4 with the smaller versions is about 50.5M (about 53M if the custom planet's saving is also dropped, which the files do not settle), and the path's "about 19M" saving is about 15M.

Orb's answer on the table is vision.md:1799: "FULL TABLE ON BETA, KEEP ITERATING WHAT WE HAVE." Reading that as the smaller table for Alpha is the audit's inference.

**The fix.** The EP corrects A4/orb.md:48, A4/ep.md:27, path:257 and :332; re-states A4's weeks or writes why not; appends the carry lines to the two lead briefs; adds the two loads to the over-10M list. Production Ops carries the same figures (`milestones.md`:418). Done before Orb is asked the rest of decisions 16 and 17. Re-price again when S3 and S4 report.

**Who.** EP; Production Ops.

**If left.** Orb answers A4's questions against a cost that is wrong.

### R2-20. The 150 lines Orb marks moved to A2; their redraft, their decision and Orb's time did not

*From R2-AM-09. Holds, high confidence.*

**What is wrong.** Row A-TEXT-01 moved from A5 to A2. Narrative's redraft of every line Orb marks "rewrite" is still briefed only in A5, and A2 has no Narrative brief. Decision 22 is still due "before A5" in the path, the sprint and Orb's A5 page. In A2 the marking, the redrafts, Orb's second look and UI's change must all finish before a friend plays and before the final gate reading. A2/ui-ux.md's token line and Orb's A2 hours were not updated.

**Evidence.** A2/ui-ux.md:45, :30 against :3; A5/narrative-identity.md:17-18; path:175, :521, :546; sprint:82; A5/orb.md:11; path:38.

**The fix.** Add an A2 Narrative brief. Move decision 22's first part to "before A2 can close". Strike action 2 on A5/orb.md except for lines changed since. Order the chain in A2/ep.md. Add Orb's reading time to A2.

**Who.** EP; Production Ops.

**If left.** A2's hand-out waits on a chain nobody ordered, or friends read lines Orb marked for rewrite.

### R2-21. Nothing re-makes the look reference after each golden window

*From R2-AM-10. Checker: holds in corrected form.*

**What is wrong.** The first review asked for a new reference and a budget line at each window. The answer was one sentence on Orb's A3, A4 and A5 pages asking Orb to name the build. No A3 to A5 brief gives a method or a price for re-making the reference. Thirty briefs there require a side-by-side; three require the same scene and ticks. `side-by-side.mjs` accepts two clips that share a seed, so across a window it would compare two different matches without complaint.

**Evidence.** A3/orb.md:40; A1/ep.md:34 (A-RENDER-11, an S, closes in A1); `tools/flash/side-by-side.mjs`:18; A5/rendering-techart.md:26.

**The fix.** Add to A3, A4 and A5 EP briefs: the last pre-window build is kept; cross-window side-by-sides are made from staged scenes, not a shared seed; after Orb names a build, the reference in `docs/ep/taste.md` is re-pointed. Price it per window. The row is the EP's (path:114).

**Who.** EP; Tools for the staged scenes.

**If left.** The look gate (ADR 0010) silently compares different matches from A3 on.

**Struck by the checker.** "Some 25 briefs" require the same scene and ticks (it is 3). The tool does not replay anything, so "the old build refuses the new build's replays" is not the mechanism.

### R2-22. The frame-rate and loading criteria get their first real pass-or-fail at the one milestone with no window to fix them

*From L4-04. Checker: holds in corrected form.*

**What is wrong.** Orb's answer on frame rate was "KEEP IMPROVING PERFORMANCE ON ALL LEVELS" (vision.md:1801): a direction, not a number. X-23 (60 held, no frame over 50 ms) is read first at A1 and must pass only at A6. No line from A2 to A5 re-reads the whole-match record or requires it to be no worse. The project's own records say the 50 ms line fails on every whole-match record today. The resized X-23 has no figure in the path, and the A6 brief still checks the old form. X-25 (the two-hour soak) is "must pass from A3" in QA's brief and in no A3, A4 or A5 exit list. A6 has no golden window, so a fix that changes the fingerprint sends the candidate back.

**Evidence.** path:65, :103, :314, :322, :366; `02-areas/PERF.md`:58; A6/performance-platform.md:16; A2/qa-balance.md:20; `08-orb-answers.md`:17.

**The fix.** One exit line in each of A2 to A5: X-23 and X-26 re-read on that milestone's desktop build in a quiet window, no worse than the last record. X-25 as must-pass in CI from A3. The 50 ms line and the slowest-in-a-hundred limit are put to Orb in plain words with A1's first frame record.

**Who.** EP; Performance; Production Ops.

**If left.** The candidate fails a must-pass line with no window left.

**Struck by the checker.** "Only the Deck figure is ever put back to Orb": A5/orb.md:26 also asks about 60 on the PC. A4 and A5 do carry some frame checks (path:233; A5/performance-platform.md:21). X-26 is also read at A2 on a real Deck.

### R2-23. Changed exit criteria are used as must-pass before anyone has confirmed them

*From L4-05 (corrected) and minor R2-AM-13 (checked by me; holds).*

**What is wrong.** Orb's words on the specification: "I briefly read through the specification, I approve it" (vision.md:1744). The path proposes changes and says "until then the specification's wording stands" (path:350). The exit lines already apply some of them as must-pass. No decisions row asks for the table to be confirmed. Decisions 13, 15, 16, 18 and 19 and Orb's pages do cover X-03, X-05, X-08 (Windows only), X-10, X-11 and X-24. Not covered anywhere:

| Criterion | Change in use | Where |
| --- | --- | --- |
| X-17 | RT + B allowed as an interim input at A1 and A2 | path:99, :149, :365 |
| X-15 | "the resized form" | path:194, :240 |
| X-23 | A new rule with no figure | path:366 |
| X-26 | First start 30 s and 60 s | path:367, while A6 still checks 15 s (path:314; A6/performance-platform.md:18) |
| X-35 | New | path:311; A6/ep.md:17 still lists "X-01 to X-34" |
| X-06, X-13, X-25, X-27 | Edited in the exit lines, absent from the table | path:313, :238, :315, :316 |
| X-14 | "Decided on A3's reading" with no decider named | path:364 |

A6/ep.md:9 says "use the wording Orb confirmed" for nine criteria, which assumes a step not yet taken.

**The fix.** The EP completes the table, adds one decisions row for it, and puts the uncovered lines on an Orb page in plain words (X-17's interim input first, since it is on the build friends get at A2). Production Ops marks each done-test line "confirmed" or "proposed".

**Who.** EP; Production Ops.

**If left.** Milestones close on criteria nobody with the authority has confirmed.

**Struck by the checker.** "Only three changes appear on any Orb page": more do (A1/orb.md:23; A4/orb.md:12-20; A5/orb.md:25-26).

### R2-24. The list of what Orb still has to decide is stale and in the wrong order

*From L4-08. Holds, medium confidence.*

**What is wrong.** The sprint and tracker put decisions 20, 21 and 22 "before A5". Each blocks an A2 row. The tracker's A2 section lists only decision 12. Questions opened since the audit (beam speed; tiny and huge; the private build of the building fix) are in no list. Orb's answers on the report server and the marks left parts unsaid. Questions 12, 14, 16 and 17 on Orb's A1 page have no recorded answer.

**Evidence.** sprint:82; `milestones.md`:63-65, :343-345; path:544-546 against path:28; `08-orb-answers.md`:9, :18; A1/orb.md:27-32.

**The fix.** The EP replaces the three lists with the one in section 4 below, and Production Ops regenerates the tracker from it.

**Who.** EP; Production Ops.

**If left.** A2 reaches its hand-out with three answers it needed not yet asked.

**Checker's corrections.** The quote "Questions 3 and 5 are still open" is not in the stand-in's record; the line is "Question 4, and the second part of question 2, are still open." planet-a1-design.md:122 is a team task, not a question for Orb.

### R2-25. Orb's own time is undercounted at A1 and A4

*From COST-06. Holds, medium confidence.*

**What is wrong.** The path allows "three to five hours a milestone". A4's own play list adds up to about 2.7 to 3.3 hours of hands on the pad before any question, word list, side-by-side or report. A1 was sized on one match and "four short trial clips"; it now also asks for about 14 clips of the marks, up to 7 trial clips, up to three trial builds to play if Tools can make them, the private build of the building fix, and a sprint-command session at the PC. No page counts Orb 2's time (about 1 to 2 hours in A4).

**Evidence.** path:38; A1/orb.md:39; A4/orb.md:37-42; `docs/vfx/marks-on-fighters.md`:69 "About 14 clips"; gravity-well-trial-design.html:530-531; A1/ep.md:38.

**The fix.** Minutes per item and a total on each milestone's Orb page, with Orb 2's beside them. Stage A1's clips over two or three sittings. Let the coverage probe carry A4's 120-cell survey with Orb sampling.

**Who.** EP.

**If left.** Orb's sittings become the slowest link at A1 and A4.

**Struck by the checker.** "Five planet sizes" is not on Orb's play list. The trial builds are conditional.

### R2-26. The stand-in's design and review work is in no token total

*From COST-03. Checker: holds in corrected form.*

**What is wrong.** Four stand-in documents cost about 9.5M: 5.3M, 2.0M, 1.9M and 0.3M. That work is in neither the path's 228M nor the sprint's 55M plus 12M. The path prices spikes as trials only at about 2M each; with its design page S2 is at least 7.3M and S1 at least 4M. Five more jobs are queued and a landing review is now due before each batch. None is priced.

**Evidence.** gravity-well-trial-design.html:603; beam-in-space-trial-design.html:509; planet-a1-design.md:288; B1-replay-build.md:9; path:52, :90; sprint:94, :98.

**The fix.** A "specialist design and review" line in the sprint and tracker; a ceiling per design page; reviews sized by batch; each stand-in job recorded with its own tally.

**Who.** EP; the stand-in for the ceiling; Production Ops for the record.

**If left.** The largest unbudgeted spend on the path stays invisible. This finding is about the stand-in's own work; the EP should weigh it as such.

**Struck by the checker.** The comparison to a "40-point allowance" (that share was replaced, see R2-02); "in about three hours"; the 1 to 1.3 points per 1M rate. The 25M, 17M and 30M projections are the reviewer's own.

### R2-27. The reset rule no longer holds a reset for A3, and no file says what a reset does to the week's clock

*From COST-07. Checker: holds in corrected form.*

**What is wrong.** The rule at sprint:98 drops the earlier guard and no longer holds reset 2 for A3; that plan is now only "kept for the record" (sprint:100-104). Orb's recorded words never dropped it: "lets just stick to the plan." (vision.md:1731) and "keep everything going according to plan." (vision.md:1887). No file says whether a reset moves the Friday 19:00 clock. `token-record.md`:41 still states the old rule. Both resets expire on 8 March 2027.

**The fix.** The EP asks Orb the plain fact (after a reset, does the next weekly reset stay Friday or move?) and writes it down. The EP proposes, for Orb's yes, when a reset is asked for and whether reset 2 stays held for A3. Production Ops replaces token-record.md:41.

**Who.** EP; Production Ops. The resets are Orb's to press.

**If left.** Both resets could go inside A1, against a plan Orb said to keep.

**Struck by the checker.** "The stand-in spent 9.5M in its first three hours" as a Fable-meter fact: the only 9.5M in the meter records is the audit's own tally. The rate of 3 Fable points per 1M is an estimate.

### R2-28. The token record divides by estimates, has no rework line, and has no reading since 13 November

*From COST-11 and COST-02. Both corrected.*

**What is wrong.** The record meant to replace the pace guess computes its rate from "tokens briefed", the EP's estimate at briefing time. Directors' pages already report their own spend. The weeks table has no 25% rework line. No meter reading is on file after 22:07 on 13 November. The record asks for one "every two days", which is too sparse for a stop line set in meter points (R2-02).

**Evidence.** `docs/production/token-record.md`:7, :25-28, :34, :37; `progress.md`:24.

**The fix.** A "tokens reported spent" column fed by one line in each director's report; the rate computed from it; the rework line added; both meters logged at each check-in.

**Who.** Production Ops, from figures the EP collects.

**If left.** The end-of-A1 date re-estimate (path:44) rests on estimates.

**Struck by the checkers.** Week one's rate is not divided by the 67M (it used the audit's measured 18.5M). The claims built on a 40-point cap fall with R2-02.

---

## 4. What Orb still has to decide, in the order it blocks work

One line each. **[Only Orb]** marks safety, Legal, spend or public matters that nobody may approve for Orb. Nothing here is recommended on Orb's behalf.

**Now: blocking A1.**

| # | The question, in plain words | Why now | Mark |
| ---: | --- | --- | --- |
| 1 | This week, does A1 still pause for you at 66% on the meter, or run to about 85% and then ask you to press a reset? | R2-02 | **[Only Orb]** spend of the plan's allowance; the resets are Orb's |
| 2 | You asked for terrain work toward A1. Does "the big terrain overhaul waits until after Alpha" still stand beside that? | R2-03 (d) | scope |
| 3 | If the tiny and huge planets cannot be drawn well and measured in time, do they still count for A1? | Open since the stand-in's question 4 | scope |
| 4 | The building-bounce fix comes with a setting you said to hold until you had played it. Will you play a private build with it on, and then say whether it goes in? | R2-14 | Orb's earlier answer stands until then |
| 5 | May the repository's free safety settings be turned on (question 14 on your A1 page, waiting since 7 November)? | Before more working-tree pushes | **[Only Orb]** security setting on a public repository |
| 6 | Questions 12, 16 and 17 on your A1 page: keeping the last 20 replays on the player's PC; updating the project's standing instructions; the change-control rule. | No recorded answer | **[Only Orb]** for 16: it changes the instructions every session reads |
| 7 | After you press a reset, does the weekly reset stay on Friday or move? And is the second reset still held for A3? | R2-27 | **[Only Orb]** |

**With the spike clips: blocking A2's work-ahead and GW2.**

| # | The question | Why | Mark |
| ---: | --- | --- | --- |
| 8 | How fast should a beam fly? And the wording of the beam-escape test that follows from it. | R2-04 | |
| 9 | The close fight: confirm, with the pad in hand, the choice you gave in words. How much of the pull is in Alpha. If the pull is not playable halfway through A3, may the snap move to the next window. | R2-16 | scope if the snap moves |
| 10 | Which effect replaces each of the marks drawn on the fighters, and may the placeholder marks be in the builds friends get until then? | `08-orb-answers.md`:18 | public-facing look |
| 11 | The changed pass lines (R2-23): RT + B as a temporary beam input on the friends' A2 build first, then the frame-rate rule, first-start loading times, the new bug line, the third-fighter line. | R2-23 | |
| 12 | Where the in-air chain you want "explored and enhanced" (vision.md:1881) goes: GW2, GW3, or after Alpha, with its price. | Minor M-6 | scope |
| 13 | If A3's load on one team passes what fits: a smaller version, a later date, or something moves out. | R2-17 | scope and date |

**Before A2 can close.**

| # | The question | Why | Mark |
| ---: | --- | --- | --- |
| 14 | A pad that drops mid-match pauses with a notice? Keyboard "works, a pad is recommended"? (decision 20) | Blocks an A2 row | |
| 15 | A quiet fight with no music, and a ten-minute listening pass at A2? (decision 21) | Blocks an A2 row | |
| 16 | Will you mark about 150 lines of text before a friend plays? English only? (decision 22) | R2-20 | |
| 17 | The report server: a new one or the existing one, and the promise to delete a tester's reports on request. | Orb's words so far: "I WILL MAKE THE DISCORD SOON" (vision.md:1793) | **[Only Orb]** Legal, privacy |
| 18 | The tester privacy wording, once it names itch.io and the outside AI service. | R2-10 | **[Only Orb]** Legal, public-facing |
| 19 | How many friends with Decks there are: two early, a third, and two held back as true newcomers. Names stay private. | path:28 | people |
| 20 | The one-line approval for desktop test builds for named testers, asked only when every safety gate is green on that commit. | R2-06 | **[Only Orb]** safety, public |
| 21 | The itch.io account, the restricted page, the upload tool, and every upload. | path:18, :177 | **[Only Orb]** public; Orb's own action |
| 22 | If a safety reading forces a change to the look of the beam clash or a cut: which of two clips looks better. | path:20 | **[Only Orb]** safety and taste together |
| 23 | Will one friend leave the two-hour test running on their Deck? | A6 must-pass (minor M-3) | people |

**After A2's Deck reading.** 24. The Deck's frame figure, and which planet sizes the Deck offers.

**At A3's reading.** 25. The crater-size ratio (X-14); the 10-second cable notice; naming the A3 build as the new look reference (and again at A4 and A5).

**Before A4.** 26. Couch 2v2's line-up, a computer partner, the planet dials now that sizes exist (decision 16, the rest); what a transformation changes on the body (decision 17); A4's corrected cost (R2-19).

**At A6.** 27. After the freeze, every new idea waits unless you lift it in (decision 23); the new bug line (X-35).

---

## 5. What held up

Attacked and found sound. (The fourth reviewer's list did not reach this writer; see section 8.)

**The amendments.**
- Every brief the first review names has a matching amendment (44 briefs), and the amendment text matches its source word for word in the briefs opened.
- The token arithmetic adds up: the milestones sum to 228M and the register recomputed by script gives 184.35M of rows.
- The register edits the first review asked for are really there.
- Rule 1 (no build to an outside tester on a red gate) is carried the same way in A2 to A6.
- "Every upload is Orb's own action" holds across all five Tools briefs.
- The close-fight amendments were written conditionally and survive Orb's later answer.
- The rule for a look change made to pass a safety reading is the same in the path and four A2 briefs.

**The order.**
- GW1a's target was made first, twice, byte-identical, on the kept 9 November tree.
- Flight 3500 is a GW1b rider in both the path and Game Design's page.
- The checks the switch flips would break were parked ahead of their groups.
- The safety chain's first link landed before any reading (commits 191e5e30, 59c6b195).
- The CI job split came before the check-scripts ratchet.
- Spike S5 passed on day one: a Linux build drew its start menu.
- The build id does not move the golden and reads no clock.
- The sizes park's stacking order is consistent, and medium stays byte for byte today's.

**The cost.**
- Every milestone's size-class count matches the register by script.
- The week ranges are consistent with each other and with the stated dates.
- The weeks are not bound by the meter at the path's pace; people, serial landings and the shared PC set them.
- The gravity well's 12M carry survives the stand-in's size guess; the issue is whose queue it sits in.
- Reset 2 can still serve A3 on the calendar.

---

## 6. Minor

Each was checked against the files by this writer. All held.

| # | From | What | Evidence | Fix | Who |
| --- | --- | --- | --- | --- | --- |
| M-1 | R2-AM-12 | The briefs were not updated after Orb's answers. A1/orb.md still asks for the standing yes and recommends removing the marks; A3/orb.md still says today's rule "would be built" until Orb answers. | A1/orb.md:51, :53; A3/orb.md:12; `08-orb-answers.md`:22-26 ("for the EP to apply"); `git log` shows only 0649439b on the audit folder | Append a dated "After Orb's answers" section to the briefs 08-orb-answers.md lists | EP |
| M-2 | L2-12 | Parks from different owners do not stack. After Tools' two patches, World's and UI's grants on `render/core/main.gd` each apply alone but not together, in either order. World's "others" patch and Encounter's rows patch both flip the same three lines of interrupts.json. World's park folder has no README. | Re-tested here with `git apply` on scratch copies of HEAD's files: "patch failed: render/core/main.gd:1370" and ":1337"; "patch failed: data/director/interrupts.json:594" in both orders | Rendering re-cuts the three grants as one; World drops its "others" patch and adds the README; each landing review includes a stacked apply check | EP; Rendering; World |
| M-3 | R2-AM-14, COST-14 | Stale lines a reader meets first. Spikes at 4.5M in the path's A1 token line and six A1 briefs (the path says 7.5M elsewhere). "Six weak enemies at once" on Orb's A1 page and in the path's PLAY THIS (the trial measures up to five). Tools' A1 load "about 11.75M" (the table says 14.5M). X-17 at A3 still read on "Orb's saved play files" in two briefs. A2's carried readings omit X-26 and X-21's Deck part. The Deck soak is must-pass at A6 but asked "If one of them is willing". "Splitting GW2 is offered to Orb" is in the review table and on no Orb page. | path:129 against :90; A1/orb.md:39 and path:88 against path:93; A1/tools-pipeline.md:47; A3/encounter-systems.md:28 and A3/qa-balance.md:25 against path:193; A2/ep.md:42 against path:148, :150; A6/orb.md:12 against path:315; `06-adversarial.md`:50 | One clean-up pass | EP |
| M-4 | COST-12 | The marks row (A-RENDER-13) is still priced 0.25M. VFX re-priced it at about 1.6M after Orb's answer. The clips for Orb need a quiet capture window. | `docs/vfx/marks-on-fighters.md`:57, :69; A3/vfx.md:28; path:577 | Re-size the row; give VFX the window | Production Ops; EP |
| M-5 | COST-13 | The machine calendar the first review added is not in the sprint, which has process caps only. | A1/ep.md:57; sprint:63-69 | A short table: long runs with hours, two quiet windows a week, who pauses | EP |
| M-6 | L2-14 | The feature half of Orb's "ping-pong" clarification has no place in the order. Its row (A-COMBAT-10) is a nice-to-have in the pool for GW3; the ideas log holds only the bug half. | vision.md:1881; path:374; `03-gap-register.md`:45; `ideas-log.md` (ID-24 only) | Log it with a price and a named window and show Orb that line (section 4, item 12) | EP; Production Ops |
| M-7 | L2-13 | The S1 clip needs VFX's stage pulses and Tools' launcher on a scratch copy; S2 asks Tools for two private builds. Neither is in an A1 brief. The S1 trial cost about 0.3M against 2M planned; the three design pages cost about 9.2M and sit in no line (see R2-26). | s1-beam-in-space-trial.md:57, :74; gravity-well-trial-design.html:531 | Two named sprint items with owners | EP; VFX; Tools |
| M-8 | L4-09 (input cut off; checked from the files) | The path says a replay saved on the A1 build "still plays on A2's". X-27 as specified and as Simulation built it refuses any replay from another build, and every build has its own id. So every new build refuses older replays, window or not. | path:63, :141, :271 against path:101; `docs/architecture/pending/replay-build/README.md`:3 "refused plainly by a later build", :7 "every build is its own" | Reword the three path lines: across builds, replays are checked through the tools' replay path, not in the game | EP |

---

## 7. Refuted

No checked finding was refuted whole. Sixteen did not hold as written; their confirmed cores are used above. These are the claims the checkers struck.

| Finding | Claim struck | Reason |
| --- | --- | --- |
| R2-AM-04 | The desktop capture has "no milestone, no row, no cost and no owner" | It is A2 row A-MARKET-03 under Tools (path:168) |
| R2-AM-10 | About 25 briefs require "same scene, same ticks"; the old build refusing replays is why the comparison fails | Three briefs do; `side-by-side.mjs` compares captured clips and replays nothing |
| L2-03 | The sprint and the design disagree on when the planet windows start; Camera re-tunes twice | A refinement, not a conflict; the second is inference |
| L2-09 | VFX cannot edit render/; the flash readings were started on day one; sizes change the look | VFX owns `render/vfx/`; briefed, not started; medium is unchanged |
| L2-10 | X-16 "cannot pass at A3" | It passes at stage 1 against a defender already moving; the wording is ambiguous, not impossible |
| COST-02 | Week one covers a third of A1 under a 40-point cap; A1 is 2.8 to 4.2 weeks | The 40% share was replaced at sprint:98; the estimates rest on a dropped rule |
| COST-03 | A quarter of "A1's 40-point allowance"; "in about three hours"; 1 to 1.3 points per 1M | Same dropped rule; neither figure is in a file |
| COST-07 | "The stand-in spent 9.5M in its first three hours" as a meter fact | Not in any meter record |
| COST-08 | A4 with every smaller version is 53M; the saving falls to 12M | About 50.5M and 15M; the custom planet's saving is not shown undone, since the size work is planned in A1 |
| COST-09 | One building fault; the design shows the price is wrong; the design says Encounter is handed a fault | The rows cover outcrops and terrain too; the design gives no price and never mentions Encounter |
| COST-10 | Five benches do not fit the friends' session; the numbers window is read "at one size" | 25 minutes fits; no file says at which size the bands are read |
| COST-11 | Week one's rate is divided by 67M, so the re-estimate will be wrong | It was divided by the audit's measured 18.5M |
| L4-02 | Two accepted recommendations are deferrals; the Performance briefs and path:365 record decisions Orb did not make | Only decision 14 defers; the other two are wording about a future step |
| L4-03 | The Deck was the path's reason for deferring sizes | The reason given was the missing frame-rate study |
| L4-04 | Only the Deck figure is put back to Orb; no A2 to A5 line carries a frame reading; X-26 is read only at A1 and A6 | A5/orb.md:26; path:233; path:150 |
| L4-05 | No decisions row covers the changes; only three appear on an Orb page | Decisions 13, 15, 16, 18, 19 and six Orb-page lines cover several |

---

## 8. How this was done and what it cost

**Method.** Four reviewers attacked the amended path, one lens each: the amendments, the order, the cost, the exit criteria. Every blocker and major then went to its own checker, whose job was to refute it against the files. This writer merged the results, re-read the path, the sprint, the A1 Orb page, the audit's record of Orb's answers and vision.md lines 1725 to 1888, and checked each minor finding against the files (one by re-running the patch stacking on scratch copies outside the repo).

| Count | Number |
| --- | ---: |
| Reviewers | 4 |
| Checkers (one per blocker and major) | 41 |
| Findings received | 51 (41 checked, 10 minor) |
| Checked findings that held (most with small corrections) | 25 |
| Checked findings corrected: wrong as written, confirmed core used | 16 |
| Checked findings refuted whole | 0 |
| Minor findings checked by this writer | 10 held, 0 dropped |
| Findings in this report after merging | 28 (4 blockers, 24 majors) and 8 minors |

**Limits.**
- The results handed to this writer were cut off partway through the fourth reviewer's first minor finding (L4-09). Any further minors from that reviewer, and its list of what held up, are not in this report. M-8 was rebuilt from the files.
- The blockers and majors rest on the checkers' reading of the files; this writer re-read the path, sprint and vision lines they cite but did not re-open every brief.
- Where two checkers judged the same matter differently (R2-04), both verdicts are stated.
- Checkers marked medium confidence on: L2-01 (the second route for R2-01), L2-02, L2-10, COST-04, COST-05, COST-06, COST-10 and L4-08.

**Cost.** About 5.2M tokens in all: four reviewers, 41 checkers (on Opus) and this writer, 46 agents. (Added by the stand-in from the run's own count; the writer did not have it.) That is more than a lean review would cost, because every blocker and major had its own checker; none was refuted whole, and 16 of 41 were corrected.
