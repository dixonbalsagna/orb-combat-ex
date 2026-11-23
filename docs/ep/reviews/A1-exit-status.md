# Sprint A1: where each finish-line item stands

- **Who:** Orb's stand-in, the review specialist of sprint A1.
- **When:** 2026-11-23, about 07:40, read against main at 0d21624b (the newest commit, ead18383, adds only Orb's word of today to the vision page). It replaces the reading of 2026-11-20 against 485b328a.
- **What:** every exit criterion of A1 in `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (lines 97 to 106), the sprint's added planet line (`docs/ep/sprints/A1-sprint.md:50`), and what the first build was promised to hold (path, line 88).
- **How:** read-only; nothing was run in Godot or a browser. Nine readers on the cheaper model gathered the evidence, nine checkers tried to refute every "met" row and every blocker, and the stand-in re-opened the files behind the rows below. The ordered list of what to do next is its own page: `docs/ep/reviews/path-to-alpha-1.md`.

## In plain words

**A1 is not finished, but its shape has changed: most of what was waiting three days ago is now in the main copy. What is left is the planet work and the proof.**

- **The main copy is now your game.** The 9 November game went in on 20 November, and the round planet, launch distance 1.5, top speed 3,500, the old meters switched off and the stray-beam fixes went in on 22 November. The computer no longer loses to a held charged heavy.
- **A Windows program of that game exists, and you have it** (the newest build in your homework folder). No record shows it has been started with its window open, and its still pictures have never been compared with the 9 November build.
- **The menus, the fighter pick, Quit and the pause fix are in.** Every picture of them on record is from before they went in, and the test that drives them still opens the pause menu with the keyboard and never chooses "Close the game".
- **Nothing has been measured on the program you play** (frames a second, loading time).
- **The planet sizes are the long pole.** None of that work is in the main copy yet. It applies cleanly on top of the two landings, small now draws correctly, and five named faults still stand between it and landing.
- **The automatic checks on GitHub are red on the newest commit** in two places. That is the first thing to fix, because every later record leans on them.

**The count.** The finish line breaks into the same 44 parts as on 20 November:

| State | 20 Nov | 23 Nov | What it means |
| :--- | ---: | ---: | :--- |
| Met | 5 | 13 | In the main copy, with a record that proves the finish line's own words |
| In, not proven | 11 | 18 | In the main copy, but no saved record proves those words |
| Waiting to go in | 21 | 7 | Built, and waiting outside the main copy |
| Not started | 7 | 6 | Nothing built |

Six of the seven waiting parts are the planet work. Most of the eighteen unproven parts close with records taken once, on the commit where the planet work lands, and not with new building.

**Production's own tracker** counts A1 by the audit's 77 rows and reads 44 landed (`docs/production/milestones.md`, commit 4d214270). It is low for QA, whose nine rows all read "not started" although the readings went in on 20 November (471d1d4d), and a little high in two places (A-CODE-04, A-NET-05). The corrections are at the end of this page.

## Scoreboard, by exit criterion

Team words used below, once: a **park** is finished work waiting outside main in a `docs/<area>/pending/` folder. **GW1a** is the landing that made main the 9 November game; **GW1b** made the round planet the default; **GW1c** is the planet work still to land. The **golden** is the set of recorded reference matches the game must reproduce exactly. A **pin** is a line in a check that forces an older world or older numbers for that check.

| # | Criterion, in its own words (shortened) | Met | In, not proven | Waiting | Not started |
| :--- | :--- | ---: | ---: | ---: | ---: |
| 1 | X-29: one command and one CI run make the Windows and Linux builds; the build shows a version number; a changelog entry is written | | 3 | | 1 |
| 2 | X-17, first reading: a count of beams started by anything but the right stick or RT + B | 3 | | | |
| 3 | X-05, first reading: the mode test has run solo and two players, on Windows and Linux, from the menu, with a pad alone, to a result, a rematch and a quit | 1 | 2 | | |
| 4 | X-27: a saved match carries its build's id; one from another build is refused with a plain message | 2 | | | 1 |
| 5 | A golden record exists for the game you play; the checks run with the switches as shipped; the switch table is cut down | 1 | 3 | | |
| 6 | First readings: frames and loading on the desktop build; win rates at Easy, Medium and Hard | | 2 | | 2 |
| 7 | X-33: the change rule and the ideas log exist; one backlog; the working folder is committed or deliberately ignored | 1 | 2 | | |
| 8 | The measuring tools exist and each has a first reading; the 1280 by 800 menu sweep has stills of every menu | 3 | 1 | 1 | 1 |
| 9 | Trials S1 to S5 each end in one page: what was tried, what it cost, the size now believed, the question for you | 2 | 3 | | |
| 10 | The planet line: sizes selectable and playing; small, medium and big drawn and measured; feet within 8 units of the ground; terrain step 2 landed | | | 6 | 1 |
| 11 | The goal's own words: the first desktop build, compared by stills; it opens on a mode list with a fighter pick and can be quit with the pad | | 2 | | |
| | **Total** | **13** | **18** | **7** | **6** |

## Each criterion, part by part

### 1. The builds (X-29)

| Part | Was | Now | Evidence | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- |
| One CI run makes the Windows and Linux builds, the solo game included | Met | **In, not proven** | The only green run built a commit from after GW1a and before the round planet: `docs/tools/runs/d168a518/windows-local-dispatch-1.md:3` and `:22` ("Third dispatch ... GREEN"). The run ids it cites no longer open on GitHub | Repeat the run on the commit where GW1c lands and save the record | Tools |
| One command makes both builds | In, not proven | **In, not proven** | `tools/desktop-local-build.mjs:2` "Windows only today" | Add the Linux export, or the EP's written word that starting the CI run counts as the one command | Tools, EP |
| The build shows a version number | Waiting | **In, not proven** | The line is on main (`ui/widgets/ui_feedback.gd:122`, commit e5618ab3). No still of a built program shows it | One still from a built program | UI, Tools |
| A changelog entry is written | Not started | **Not started** | `docs/tools/changelog.md` is four lines with no entry; `tools/version.json` reads `"build": 0`. Two builds have gone to Orb since, against the page's own rule ("One entry for every build handed to a person") | Number the next build and write its entry | Tools |

### 2. The stray-beam count (X-17, first reading)

| Part | Was | Now | Evidence | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- |
| The count tool exists | Waiting | **Met** | `qa/godot/x17_count.gd`, committed in 471d1d4d | Nothing | QA |
| A reading on your saved matches | Waiting | **Met** | `docs/qa/runs/6a30b4c9/x17-first-reading.txt:5` "X17 TOTAL stick 7, rtb 1, other 0" | Nothing for a first reading | QA |
| A reading on the scripted set | Not started | **Met** | Same file, `:16`: "20 matches ... 537 beams, 0 neither stick nor RT + B" | The readings page gives 549 for the same 20 matches (`docs/qa/readings/x17-beam-sources.md:19`); QA reconciles the two totals | QA |

All three readings are from before the stray-beam fixes landed. The fix has a passing check on main since (`docs/director/runs/bce578a7/gw1b-director-checks/director_checks.txt:44` "stray_beam_check exit 0"). The count itself must pass from A2, on play files saved by the current build, so it is taken again there.

### 3. The mode test (X-05, first reading)

| Part | Was | Now | Evidence | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- |
| The test exists | In, not proven | **Met** | `tools/smoke/mode_smoke.gd:3` "REAL PAD BUTTONS"; it drives the new mode list, and a missing Quit row now fails (`:182`); CI runs it | Nothing | Tools, UI |
| It has run on Windows and Linux | In, not proven | **In, not proven** | Two Windows results exist, inside a landed park's folder, with `"commit": "unknown"` (`docs/ui/pending/s04-report-where/runs/mode-smoke-solo-windows.json`). Linux runs only in CI and no result is saved | One saved result per mode and per platform, named for its commit | Tools |
| From the menu, with a pad alone, to a result, a rematch and a quit | In, not proven | **In, not proven** | The pad now drives the list, the setup, the fighter pick, the result card and the rematch. Pause is still opened with the keyboard (`mode_smoke.gd:278` `_key(KEY_P)`), Quit is answered with "Stay" (`:291`), and the match is ended by the test itself (`:242`) | Start on the pad opens pause; "Close the game" is chosen and the program is seen to close | Tools, UI |

### 4. Saved matches and builds (X-27)

| Part | Was | Now | Evidence | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- |
| A saved match carries its build's id | Met | **Met** | `sim/core/replay.gd:126-127`; `docs/sim/runs/f83c78e9/replay-build-b1/summary.txt` | Nothing | Simulation |
| One from another build is refused | Met | **Met** | `sim/core/replay.gd:156-157`; `docs/sim/runs/f83c78e9/replay-build-b1/rb_negative.txt` | Nothing | Simulation |
| With a plain message | Waiting | **Not started** | The sentence is on main (`ui/data/terms.json`, `replay_wrong_build`), but no code reads it: nothing shows it when a saved match is refused. The park held only the words, so "waiting" overstated it | Code that shows the sentence, a check row, and a still or log | UI, Simulation |

### 5. The golden record and the switch table

| Part | Was | Now | Evidence | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- |
| A golden record exists for the game you play | Waiting | **Met** | Main's golden is byte for byte the recorded target (sha256 `6b3e14c2...`, `docs/sim/runs/c2154c69/x06-target/README.md:7`). Seven of its nine matches play the round planet at launch distance 1.5 and top speed 3,500 (`data/fight/power.json:108-110`; `data/biomes/world.json`) | Nothing. Two matches and both scripted replays stay on the flat arena on purpose | Simulation |
| Main reproduces that record exactly | Waiting | **In, not proven** | The only saved passing run is on a scratch copy (main plus the three X-06 patches); its own page says CI was not reached | The passing run saved on main itself, on Windows and from CI's Linux job, for one commit | Simulation, EP |
| The checks run with the switches as shipped | Waiting | **In, not proven** | The data is shipped, but the pins grew: 34 check files force the flat arena, 33 World checks force the older world and numbers, 12 picture checks draw the old strip ground, and 4 put launch distance back to 2.0. There is no list of them with an owner and a date | A register of every pin, each classed as fair or as hiding the shipped game, and a round-planet row for the ones that hide it | EP, World, Rendering, Simulation, Camera, Audio |
| The switch table is cut down to real choices | Waiting | **In, not proven** | 85 rows went (887ff798); 8 remain (`tools/preview/switches.mjs:337-356`). One of the 8 offers the planet type that is already the default. The last count against the 9 November build ("0 of 5", 22 November) is a note in the tracker, not a saved record, and is from before X-06 | Drop or re-word the one row; one dated count saved after X-06 | Tools, EP |

One pin deserves the EP's and Legal's eye: the check that proves no bystander dies still runs under the older-world pin (`sim/world/tools/bystanders_check.gd:146`), so that proof has not been read on the world players now get.

### 6. First readings

| Part | Was | Now | Evidence | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- |
| A frame record for the desktop build on your PC (X-23) | Not started | **Not started** | No Performance commit since 7 November | The program started once in a quiet window. By the path's rule 7 a session may not start it: Orb or CI does | Performance, Tools, Orb |
| Loading times (X-26) | Not started | **Not started** | The same | The same sitting | Performance |
| Win rates at Easy, Medium and Hard (X-06) | Waiting | **In, not proven** | Readings are on main, but none is on the landed game: the three-level reading used a player that throws no beam (`docs/qa/readings/x06-orbs-scheme-win-rates.md:5`), and the latest (Easy charge 90%, Medium charge 45%, Medium whole kit 10%, 40 matches a cell) was taken on main plus patches, with no Hard cell | One reading on the landed game's packed data, all three levels, with the player that uses your whole scheme | QA |
| Enough matches to tell the levels apart | In, not proven | **In, not proven** | Every reading since is 40 a cell: "a smoke at this size: ±12 to 15 points" | The size `docs/qa/sample-size.md` asks for, on that reading | QA |

Two cells are left for human play by Game Design's ruling (Easy against the charge, Medium against the whole kit). That ruling is only in an uncommitted edit of `docs/design/gauntlet-plan.md`.

### 7. Process (X-33)

| Part | Was | Now | Evidence | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- |
| The change rule and the ideas log exist and the playbook points to them | Met | **Met** | `docs/ep/playbook.md:15` | Nothing | Production, EP |
| One backlog | In, not proven | **In, not proven** | Still `docs/production/backlog-draft.md`, which lists QA's bug list as missing although it is on main now | Production regenerates it; the EP adopts it and the playbook points to it | EP |
| The working folder is committed or deliberately ignored | In, not proven | **In, not proven** | 5,614 loose files (5,754 on 20 November), 5,145 of them pictures under `docs/rendering/img`. 52 tracked files are changed and uncommitted, among them one data file (`data/art/energy-lanes.json`), Combat's park data, a Performance tool and one command file | An ignore rule for the pictures; the rest committed or dropped, owner by owner. Landed park folders cleared only after the records inside them are moved out (the mode-test results above are one) | EP, each owner |

### 8. Measuring tools

| Part | Was | Now | Evidence | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- |
| The button-press probe (X-03), with a first reading | Waiting | **Waiting** | Still the park `docs/controls/pending/coverage-probe` (14 November); its reading is on main. Combat's data moved on 20 November, so the park and its list of cells need a re-check | Re-check, land (its README says no grant is needed), one reading on today's game | Controls |
| The transformation probe (X-04) | Not started | **Not started** | `docs/qa/readings/README.md:24` "Not yet run: X-04's forms probe" | Build it and take one reading. It is the only A1 tool with nothing built | QA, Simulation, Encounter |
| The "everything shows up in one match" checklist (X-13) | Waiting | **Met** | Re-cut to the criterion's ten items; `docs/qa/readings/x13-match-checklist.md:30`: your play 6 of 10, scripted 5 of 10 | Nothing | QA |
| The beam sidestep test (X-16) | Waiting | **Met** | `docs/qa/readings/x16-beam-sidestep.md:15` "FAIL. 20 of 20 beams hit at each of the three ranges"; the short range now fires | Nothing. A failing first reading is the expected result | QA |
| The 1280 by 800 menu sweep exists | Waiting | **Met** | `ui/tools/screen_sweep.gd`, on main since e5618ab3 | Nothing | UI |
| It has stills of every menu | Waiting | **In, not proven** | `docs/ui/runs/09e2de07/screen-sweep/sweep.md:33`: 24 screens, 5 stills kept, taken on the menu demo and not the game | A full set from the built game, with the held-back stills at least listed | UI |

### 9. The trials

| Trial | Was | Now | Has | Lacks | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- |
| S1, a beam that travels | Met | **Met** | All four things (`docs/director/s1-beam-in-space-trial.md:57`, `:87`) | The clip for you | Encounter, Tools |
| S2, the pull into a close fight | In, not proven | **Met** | Final text on main (114c768b): tried, cost and size (`docs/sim/s2/trial-page.md:84`), the question (`:108`), ten clips | Its cost is given as lines of code plus the review's tokens; one line for the whole would be tidier | Simulation |
| S3, several weak enemies | In, not proven | **In, not proven** | Unchanged: six tests pass | The closing section: total cost, the size now believed, the questions | Encounter |
| S4, the map of button presses | In, not proven | **In, not proven** | Both sizes priced, one question | One line on what the trial itself cost | Combat |
| S5, a picture from a Linux build | In, not proven | **In, not proven** | The Linux build drew the start menu in CI on 14 November | A cost line, a size line, and "no question" if there is none | Tools |

### 10. The planet line

Nothing of this is on main: there is no sizes data file, and the ground memory is still keyed by the planet's seed alone (`sim/world/field.gd:143`). World's record shows its stage for this landing applying cleanly on the last GW1b commit with 95 checks and none red (`docs/world/planet-stack-recut.md`). The blockers below are from `docs/ep/reviews/GW1c-readiness.md`.

| Part | Was | Now | What is true today | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Sizes selectable | Waiting | **Waiting** | The parked data still offers all five, against the EP's rule of three. The menu row was last re-cut on the GW1a stack | Tiny and huge switched off in the data until Orb answers; the menu row re-cut; a run from the menu to a match at each offered size | World, UI, Rendering |
| Each generates and plays | Waiting | **Waiting** | The ground-memory fix (C-01) is now in World's list, but the check row that would catch it coming back is missing, and nobody has played a size to a result (C-11) | That row; one full match and one saved-match replay per size | World, Simulation, QA |
| Small, medium and big drawn | Waiting | **Waiting** | The cause of small's broken picture is found and fixed in the park (52aa1708), and stills of every size read correctly by eye. One picture reading on small is over the team's own bar, repeatably, with its cause still open; the EP has the detail | The cause found and fixed; the look gate for each size; the stills named in a committed record (they sit in an ignored folder) | Rendering, Tools |
| Small, medium and big measured | Not started | **Not started** | No record names a size. The build that takes a size is a scratch copy | A real build that takes a size, and one quiet reading each | Performance, Tools |
| Tiny and huge | Waiting on you | **Waiting on you** | Tiny now draws. Huge still cannot fill its ground (it needs 864 ground tiles and the store holds 800). The question is on your sprint report with a recommendation: count A1 done with three sizes | Your answer | Orb, EP |
| Feet within 8 units of the drawn ground | Waiting | **Waiting** | No new numbers: the three feet parks have not been re-cut since the two landings, the sized check is a scratch file and not a gate, and one tower's picture fault is unexplained (C-04) | Re-cut, re-read at three sizes, the check made a gate | Rendering |
| Terrain step 2 landed | Waiting | **Waiting** | Re-cut by World and applies. Camera has not re-run its chase check on it, and as shipped (its settling switch off) it misses its own measure: 14 of 40 matches over the limit | Camera's re-check; a ruling on the measure | World, Camera |

Three more things hang on this landing. The crater park in the same stage changes how big a beam's crater is under the rules you play, with no switch (C-02). A beam fault on the round planet (`docs/director/pending/beam-standoff-planet`) waits for the next re-recording of the golden, which this landing is. And lakes near towns still draw no water while fighters stand at the lake's level; the window for that fix has not been named in writing.

### 11. The first build, as promised

| Promised (path, line 88) | Was | Now | Where |
| :--- | :--- | :--- | :--- |
| The same game as 9 November, made from main, as a Windows program, compared by stills | Not started | **In, not proven** | Two Windows programs were made from main: one after GW1a (cb8d7934) and one on the last GW1b commit (b624340a). Each played its test match to the same result as the project. Neither record is in the repository, neither program was started with its window on record ("read, not run"), and no still comparison with the 9 November build exists |
| A mode list, a fighter pick, Quit with the pad | Waiting | **In, not proven** | On main (e5618ab3). Every still is from before it landed |
| Pause opens its menu; the start menu's d-pad moves evenly | Waiting | In, not proven | The same |
| A stick beam you let go of no longer fires later; RT + B only just after RT | Waiting | **Met** | On main, with a passing check on a commit that holds the fix and the round planet (section 2) |
| The old hero and villain meters no longer change the fight | Waiting | **Met** | `docs/sim/runs/c2154c69/x06-target/records/parity.txt:65` "ok the old meters change nothing; the comeback for both (decision 6)" |
| A report button that saves a file | Waiting | In, not proven | On main. No record shows a file saved by a built program |
| Four trial clips with a question under each | Two of four | **One of four** | Only the close-fight clips can be watched. The weak-enemies clips are marked not for viewing (they show the camera, not a crowd); the beam clip and the button map picture do not exist |

The first two rows are the two parts counted in the scoreboard. A caution for whoever files the two build records: each holds this PC's folder paths, so they must be cleaned before they go into the public repository.

## Waiting on Orb

None of these stops the next step. The path page ranks them and adds the ones A2 needs.

| Question | Where it is asked | State |
| :--- | :--- | :--- |
| Play the newest build: does it feel like your game, and how hard are Easy and Medium? | The play page in your homework folder | No word from you on either build yet. Two of the difficulty numbers wait on it |
| Are the words in the new menus right? | Its own homework page, and again on the play page | Unanswered. Testers will read these words |
| Is A1 done with small, medium and big, and tiny and huge polished after? | The sprint report, now with a recommendation (yes) | Unanswered |
| Up close, does your stick move only you? | The homework page under the close-fight clips | Unanswered; for A3 |
| Should the camera follow close or pull back on a fast launch? Should the screen split a moment sooner? | Two homework pages (the second asks for an answer by 28 November) | Unanswered; each has a default meanwhile |
| Should LB + A, the one press that does nothing, become a counter? | The sprint report | Now asked; unanswered; for A4 |
| The weak-enemies questions | Two on the sprint report; seven more wait in a draft for a usable clip | Unanswered; for A4 |
| How fast should a beam fly? | Not asked: it needs the beam clip | For A3 |

Settled since the last page: **where the second backup lives.** You answered on 14 November (`docs/ep/vision.md:1885`), and the copy was made. `docs/tools/backup.md:3` and your sprint report still ask it.

## Records that disagree, for the EP

| What | Evidence | Fix |
| :--- | :--- | :--- |
| CI is red on the newest pushed commit in two jobs: the data job (the list of check scripts) and one of the picture-count jobs (the EP has its name). The first hides the steps after it, the version-and-changelog check among them | The run on 0d21624b; `sim/director/tools/hold_answer_check.gd` (new in 8006fe3d) is in neither `tools/check-scripts.json` nor `ci.yml` (0 mentions each), which is the likely cause of the first. The second was not read: the run was still going | Tools reads the finished run and fixes both |
| Production says GitHub is locked and that the X-06 landing is not pushed | `docs/production/status.json:578`; `docs/production/milestone-rows.md:37` "NOT PUSHED". Main reached GitHub at 0d21624b and CI ran on it | Production corrects both; ead18383 is still to push |
| Older CI run ids cited in records no longer open | The runs cited in `docs/tools/runs/d168a518/windows-local-dispatch-1.md:22` and `docs/tools/s5-linux-still.md:3` return "not found" | The EP checks whether the run history was lost; the saved records are now the only proof |
| The tracker has QA's nine A1 rows "not started" | `docs/production/milestone-rows.md:109-112` against 471d1d4d. A-QA-03, A-QA-07 and A-QA-09 meet their own words | Production updates them. It also holds A-CODE-04 as landed with 55 check scripts unreviewed, A-NET-05 without a saved refusal, and the wrong commit for A-UI-09 (it is ed1591cb) |
| Your sprint report says the desktop build is made with one command | The tool makes Windows only (section 1) | Add Linux or write the ruling before X-29 is called met |
| The look gate's written reference is still the demo of 15 October | `docs/ep/taste.md:7`, against decision 4, which Orb accepted on 13 November: the 9 November build | The EP updates the page; no new question for Orb is needed |
| Stale "parked" folders and headers for landed work | About forty GW1b folders, `docs/director/pending/stray-beams`, `docs/architecture/pending/meters-zero`, `docs/director/pending/x06-bands`, and `docs/rendering/pending/capture-steady` | Owners clear them, after moving any record out |
| Pages Orb reads carry stale asks | The start page in the homework folder still names the 9 November build as the one to play; the menu-words page shows five planet sizes against the EP's rule of three | The EP tidies them |
| `CLAUDE.md` still lists the licence and the title clash as open, and still says Pro plan and no workflows | Against `docs/ep/vision.md:1795` and Orb's order of 6 November | The EP's process rows A-PROCESS-06 and A-PROCESS-11 |

## How this was done

Nine readers on the cheaper model each took one group (the builds; the mode test, saved matches and golden; the readings and tools; process and trials; the planet line; what A2 needs; open work; what waits on Orb; the audit's 77 rows) and returned 194 rows. Nine checkers then tried to refute every "met" row, every row that changed state and every blocker: of 99 claims they confirmed 76, narrowed 21 and overturned 2, both upward (the stray-beam check, which a reader had missed, and the backup question, which Orb had already answered). A tenth agent looked for what nobody had covered. The stand-in re-opened the files behind the rows above, took the stricter state wherever a reader and a checker differed, and wrote the page. Cost: about 2.3M tokens on the cheaper model for the nineteen agents, shared with the path page, plus the stand-in's own reading and writing.
