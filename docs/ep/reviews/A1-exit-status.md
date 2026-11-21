# Sprint A1: where each finish-line item stands

- **Who:** Orb's stand-in, the review specialist of sprint A1.
- **When:** 2026-11-20, about 20:40, read against main at commit 485b328a.
- **What:** every exit criterion of A1 in `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (lines 97 to 106), the sprint's added planet line (`docs/ep/sprints/A1-sprint.md:50`), and what the first build was promised to hold (path, line 88).
- **How:** read-only; nothing was run in Godot or a browser. Five readers gathered the evidence, and the stand-in wrote the page and re-opened the file behind every row marked "met".

## In plain words

**A1 is not finished, and it is not close to finished by count, but the hard part is done.** A1's goal is that the team's main copy of the game *is* the game you played on 9 November, that it builds as a Windows program with one command, and that it opens on a start menu. Today:

- **The main copy is still the older game.** Everything that turns it into your 9 November game is built, checked and reviewed, and sits in one stack waiting to go in. Its review found nothing that blocks it. Once it goes in, about half of the "waiting to go in" rows below move at once.
- **No Windows program of your game exists yet.** A Windows and a Linux build were made automatically once, but from the older game, and the Windows one was never started. The first real one can only be made after the stack above goes in.
- **The start menu, the fighter pick, Quit and the pause fix are built** and ride in the same stack.
- **Nothing has been measured on the program you will play** (frames a second, loading time, memory), because that program does not exist yet.
- **The four trials** (a beam you can sidestep, the pull into a close fight, several weak enemies, the map of dead button presses) were all built and tried. One has its closing page complete; three need a few lines; two still need their clip for you.
- **The planet work you added** (sizes, terrain, destruction, feet on the ground) is built in pieces but not ready: it has to be redone on top of the two landings before it, and small planets draw a broken picture today.

**The count.** The finish line breaks into 44 parts:

| State | Parts | What it means |
| :--- | ---: | :--- |
| Met | 5 | In the main copy, with a record that proves it |
| In, not proven | 11 | In the main copy, but no record proves the finish line's own words |
| Waiting to go in | 21 | Built, and waiting outside the main copy |
| Not started | 7 | Nothing built |

**What is waiting on you** is at the end of this page: six questions, none of them blocking the next step.

## The order from here

1. **Land the stack that makes main your 9 November game.** Named fixes first (the review `docs/ep/reviews/GW1a-standin.md`).
2. **Make the first Windows program, then Linux, from that commit,** start each once, and compare stills with the 9 November page at the same moments of one replay. The sprint page still lists this after the next landing; the path's own amendment puts it here.
3. **Take the first measurements on that program** in a quiet window: frames, loading, memory.
4. **Land the second stack** (the round planet as the default, launch distance 1.5, top speed 3,500, the old meters off, the stray-beam fixes), after its eight blockers are fixed (`docs/ep/reviews/GW1b-review.md`).
5. **Redo and land the planet work** on top of both (`docs/ep/reviews/GW1c-readiness.md`).
6. Beside all of it: commit QA's finished work, file the missing records, and close the trial pages.

## Scoreboard, by exit criterion

Team words used below, once: a **park** is finished work waiting outside main in a `docs/<area>/pending/` folder. **GW1a** is the landing that makes main the 9 November game; **GW1b** is the one after it; **GW1c** is the planet work. The **golden** is the set of recorded reference matches the game must reproduce exactly.

| # | Criterion, in its own words (shortened) | Met | In, not proven | Waiting | Not started |
| :--- | :--- | ---: | ---: | ---: | ---: |
| 1 | X-29: one command and one CI run make the Windows and Linux builds; the build shows a version number; a changelog entry is written | 1 | 1 | 1 | 1 |
| 2 | X-17, first reading: a count of beams started by anything but the right stick or RT + B | | | 2 | 1 |
| 3 | X-05, first reading: the mode test has run solo and two players, on Windows and Linux, from the menu, with a pad alone, to a result, a rematch and a quit | | 3 | | |
| 4 | X-27: a saved match carries its build's id; one from another build is refused with a plain message | 2 | | 1 | |
| 5 | A golden record exists for the game you play; the checks run with the switches as shipped; the switch table is cut down | | | 4 | |
| 6 | First readings: frames and loading on the desktop build; win rates at Easy, Medium and Hard | | 1 | 1 | 2 |
| 7 | X-33: the change rule and the ideas log exist; one backlog; the working folder is committed or deliberately ignored | 1 | 2 | | |
| 8 | The measuring tools exist and each has a first reading; the 1280 by 800 menu sweep has stills of every menu | | | 5 | 1 |
| 9 | Trials S1 to S5 each end in one page: what was tried, what it cost, the size now believed, the question for you | 1 | 4 | | |
| 10 | The planet line: sizes selectable and playing; small, medium and big drawn and measured; feet within 8 units of the ground; terrain step 2 landed | | | 6 | 1 |
| 11 | The goal's own words: the first desktop build, compared by stills; it opens on a mode list with a fighter pick and can be quit with the pad | | | 1 | 1 |
| | **Total** | **5** | **11** | **21** | **7** |

## Each criterion, part by part

### 1. The builds (X-29)

| Part | State | Evidence | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- |
| One CI run makes the Windows and Linux builds, the solo game included | **Met**, by its literal words only | `docs/tools/runs/148f4e16/desktop-owner-private-43589936940.md:3` "success, about 2 min 45 s"; `:13` "Export Windows, Linux, macOS: all passed"; the Linux program played the test match to the same result as the project | The commit it built carries the older game, not the 9 November one. The same record says Windows was "read, not run" and that no file was kept. Repeat it on the commit where the first stack lands | Tools |
| One command makes both builds | In, not proven | `tools/desktop-local-build.mjs` is on main; its own header says "Windows only today"; `docs/tools/runs/3c2ff9ac/local-owner-private-build.md:9` "Linux ... not tried" | Either one local command that also makes Linux, or the EP's written word that starting the CI run counts as the one command | Tools, EP |
| The build shows a version number | Waiting | The number exists (`tools/version.json`), but the line on screen is in the park `docs/ui/pending/a1-menu-fixes` | Land the park; a still of a real build's menu showing the number | UI, Tools |
| A changelog entry is written | Not started | `docs/tools/changelog.md` holds only its heading: "Build 0 means no build has been numbered yet" | Written when the first build is numbered, with one plain line for players | Tools |

### 2. The stray-beam count (X-17, first reading)

| Part | State | Evidence | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- |
| The count tool exists | Waiting, and fragile | `qa/godot/x17_count.gd` exists on this PC but is not committed and not in a park | Commit it | QA, EP |
| A reading on your saved matches | Waiting, and fragile | `docs/qa/runs/6a30b4c9/x17-first-reading.txt`, uncommitted: on your 9 November matches, 7 beams from the stick, 1 from RT + B, **0 from anything else**. On the 8 November matches, 6 from something else | Commit it | QA, EP |
| A reading on the scripted set | Not started | The committed record `docs/qa/runs/6a30b4c9/stray-beams-scripted-set.md` measures a different thing (late beams after a new press) | Run the count on the scripted set before the stray-beam fix lands | QA |

### 3. The mode test (X-05, first reading)

| Part | State | Evidence | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- |
| The test exists | In, not proven | `tools/smoke/mode_smoke.gd` and its CI step are on main (commit e702e058) | It drives the old start screen, not the new mode list, and counts a missing Quit row as a pass. Re-point it when the menus land | Tools, UI |
| It has run on Windows and Linux | In, not proven | Linux: a green CI step. Windows: one sentence in `docs/tools/mode-smoke.md` ("solo: 14 steps, 0 failed. two people: 14 steps, 0 failed") | No result file is saved for either. Save one per mode and per platform on the first real build | Tools |
| From the menu, with a pad alone, to a result, a rematch and a quit | In, not proven | The test moves the menu through the game's own menu calls, not pad presses, and ends the match itself after 600 ticks | A run with real pad presses from the mode list to a result, a rematch and a Quit that closes the game | Tools, UI |

### 4. Saved matches and builds (X-27)

| Part | State | Evidence | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- |
| A saved match carries its build's id | **Met** | `sim/core/replay.gd:7` on main (commit f068b697); `docs/sim/runs/f83c78e9/replay-build-b1/summary.txt` | Nothing. Only a built program writes the id | Simulation |
| One from another build is refused | **Met** | `sim/core/replay.gd:155-156` and `:179-180` refuse before the first tick; `docs/sim/runs/f83c78e9/replay-build-b1/rb_negative.txt` | Nothing for the refusal | Simulation |
| With a plain message | Waiting | The sentence is in the park `docs/ui/pending/a1-replay-words`, whose README says "No code uses the term yet" | You read the sentence; UI lands it; something shows it on screen when a match is refused | UI, Simulation, Tools |

A related fact: the matches you saved on 9 November will be refused by main after the first stack lands, because the data they were made with differs by two switches and a note (`GW1a-standin.md`, S-08). The path's sentence "Orb's 9 November play files still verify" cannot be met as written.

### 5. The golden record and the switch table

| Part | State | Evidence | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- |
| A golden record exists for the game you play | Waiting | The target is recorded and committed (`docs/sim/runs/6a30b4c9/gw1a-target/README.md:7` "Recorded twice on the same tree: byte-identical"). Main's own golden is still the older game's | The first stack lands. Two known gaps in the record: it holds launch distance 2.0 where you played 1.5, and none of its matches plays the newest planet type the game now starts on (S-01, S-07) | Simulation, EP |
| Main reproduces that record exactly | Waiting | The stacked copy does: its golden has the target's checksum (`GW1a-standin.md`, "Confirmed fine") | Land the stack; save the comparison on main | EP, Simulation |
| The checks run with the switches as shipped | Waiting | The parks `docs/architecture/pending/{gates-shipped, energy-on, frame-gw1a, a1-owed}` | After landing, 33 World checks and 12 picture checks still force the old world (S-09, S-11): dated follow-ups | World, Rendering |
| The switch table is cut down to real choices | Waiting | 93 rows today; `docs/tools/pending/gw1a-retire/README.md:7` "85 rows out, 8 stay", to be applied after the stack lands. 69 of the 87 data rows still differed on 14 November and no data has landed since | Land, then retire the rows; a fresh dated count from the EP | Tools, EP |

### 6. First readings

| Part | State | Evidence | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- |
| A frame record for the desktop build on your PC (X-23) | Not started | No desktop build of your game exists. No Performance commit since 12 November | A build after the first stack lands; a one-click test you start once in a quiet window | Performance, Tools |
| Loading times (X-26) | Not started | The last timing is from 27 October, before the menus and the round ground | The same test | Performance |
| Win rates at Easy, Medium and Hard (X-06) | Waiting, and fragile | `docs/qa/runs/6a30b4c9/x06-first-reading.md`, uncommitted: **Easy 61% over 400 matches, Medium 0 of 200, Hard 0 of 200.** The scripted player fired no beams, so it did not play your full scheme | Commit it; read again with the player that uses beams; repeat on the first real build | QA |
| Enough matches to tell the levels apart | In, not proven | `docs/qa/sample-size.md` is on main; the reading says Easy "cannot be called in or out at 400" | More seeds for Easy | QA |

### 7. Process (X-33)

| Part | State | Evidence | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- |
| The change rule and the ideas log exist and the playbook points to them | **Met** | `docs/production/change-control.md`, `docs/production/ideas-log.md`; `docs/ep/playbook.md:15` | Nothing for A1 | Production, EP |
| One backlog | In, not proven | The only file is `docs/production/backlog-draft.md`, which lists what it still lacks | The EP adopts one backlog and the playbook points to it | EP |
| The working folder is committed or deliberately ignored | In, not proven | 14,805 loose files on 13 November; **5,754 today**, 5,237 of them pictures under `docs/rendering/img`. Code and data are still loose too, QA's tools among them | Commit or ignore the rest, code and data first | EP, each owner |

### 8. Measuring tools

| Part | State | Evidence | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- |
| The button-press probe (X-03), with a first reading | Waiting | The tool is in the park `docs/controls/pending/coverage-probe`; its reading is committed: `docs/controls/runs/51b840f5/coverage-kept-6a30b4c9-reading.txt` | Land the tool | Controls |
| The transformation probe (X-04) | Not started | No file, park or run anywhere | Build it and take one reading | QA, Simulation, Encounter |
| The "everything shows up in one match" checklist (X-13) | Waiting, and it measures the wrong list | `qa/godot/pillars.js`, uncommitted. It checks the seven design pillars, not the ten things the criterion lists | Re-cut it to the criterion's list; commit | QA |
| The beam sidestep test (X-16) | Waiting | `qa/godot/x16_sidestep.gd`, uncommitted. At the two longer ranges the beam hit 20 of 20; at the short range no beam was fired, so that range was not tested | Fix the short range; commit | QA |
| The 1280 by 800 menu sweep exists | Waiting | The park `docs/ui/pending/a1-screen-sweep` | Land it | UI |
| It has stills of every menu | Waiting | `docs/ui/runs/def3445a/screen-sweep/sweep.md`: 24 screens read, 6 stills in the repo; the rest are on this PC only, and all were taken on the menu demo, not the game | A full set from the built game | UI |

### 9. The trials

| Trial | State | Has | Lacks | Owner |
| :--- | :--- | :--- | :--- | :--- |
| S1, a beam that travels | **Met** | `docs/director/s1-beam-in-space-trial.md`: what was tried, the cost (`:57` "About 0.3M tokens"), the size (`:61` "large at least"), the questions (`:87`) | The clip for you (`:86` "A clip is needed") | Encounter; the EP routes the clip |
| S2, the pull into a close fight | In, not proven | Built and tried (`docs/sim/s2/`), ten clips made for you | The page on main is still marked DRAFT; the finished text is uncommitted. Its cost line covers only part | Simulation, EP |
| S3, several weak enemies | In, not proven | `docs/director/horde-trial.md`: six tests pass | No closing section: total cost, the size now believed, the questions. The frame cost waits for a quiet window | Encounter, EP |
| S4, the map of button presses | In, not proven | `docs/combat/move-table-s4.md`: tried, both sizes priced, one question (`:69`) | One line on what the trial cost. Worth telling you: the audit's "18 dead presses and 65 repeats" was not confirmed. Pressing every cell found one dead press (LB + A) and 32 repeats per fighter | Combat |
| S5, a picture from a Linux build | In, not proven | `docs/tools/s5-linux-still.md`: the Linux build drew the start menu in CI | A cost line and a size line. The still itself was not kept | Tools |

### 10. The planet line

Taken from `docs/ep/reviews/GW1c-readiness.md`, which has the detail and six blockers.

| Part | State | What is true today | Owed | Owner |
| :--- | :--- | :--- | :--- | :--- |
| Sizes selectable | Waiting | The data offers five; the menu row is in parks outside the planet list | Land the sizes; a run from the menu to a match at each offered size | World, UI |
| Each generates and plays | Waiting | Each ran for ten seconds on one planet, but four of the five ran on the smallest one's ground (blocker C-01) | The fix exists in Rendering's park; re-run after it | World, Simulation |
| Small, medium and big drawn | Waiting | Medium is unchanged. Big has no stills on record. **Small draws a broken picture** (C-03) | Fix small; file stills of all three | Rendering |
| Small, medium and big measured | Not started | Nothing valid is on record (C-06) | A build that takes a size, and one quiet run each | Performance, Tools |
| Tiny and huge | Waiting on you | Both would be offered with nothing drawn; huge cannot fill its ground (C-05). The EP's rule meanwhile: A1 offers small, medium and big | Your answer (below) | Orb, EP |
| Feet within 8 units of the drawn ground | Waiting | With the four parks in: 0 of 3,046 samples over at medium, 0 of 2,425 at small, 2 of 3,315 at big | Make the check a gate; one tower's picture fault is unexplained (C-04); the lakes fix | Rendering |
| Terrain step 2 landed | Waiting | Passed its camera check on the older main; no longer applies after the first stack (C-07) | Re-cut and re-check | World, Camera |

### 11. The first build, as promised

The path's line 88 says what the first build would hold. Where each stands:

| Promised | State | Where |
| :--- | :--- | :--- |
| The same game as 9 November, made from main by one command, as a Windows program | Not started | Waits on the first stack, then the build step |
| A mode list, a fighter pick, Quit with the pad | Waiting | `docs/ui/pending/a1-start-flow`, in the first stack |
| Pause opens its menu | Waiting | `docs/ui/pending/a1-pause-clock`, in the first stack. No picture of it in the real game yet |
| The start menu's d-pad moves evenly | Waiting | With the mode list |
| A stick beam you let go of no longer fires later; RT + B only just after RT | Waiting | `docs/director/pending/stray-beams`, in the second stack |
| The old hero and villain meters no longer change the fight | Waiting | `docs/architecture/pending/meters-zero`, in the second stack |
| A report button that saves a file | Waiting | `docs/tools/pending/code-03`, in the first stack; re-cut on 20 November after the review |
| Four trial clips with a question under each | Two of four | The close-fight clips and the weak-enemies clips exist. The beam clip and the button map do not |

So the first build after the first stack will have the menus, the pause fix and the saved report, and will not yet have the beam fixes or the meters change. The draft `docs/ep/proposals/first-build-notes.md` says this to Orb in plain words.

## Waiting on Orb

None of these blocks the next step. Each is asked on its own page, one at a time.

| Question | Where it is asked | Why it waits |
| :--- | :--- | :--- |
| Are the words in the new menus right? | The homework page on the new menus' words | Unanswered |
| Up close, does your stick move only you? | The homework page under the close-fight clips | You leaned one way in words on 14 November (`docs/ep/vision.md:1887`); the plan was to ask again under the clips, and that page is unanswered |
| Do tiny and huge planets count for A1 if they cannot be drawn well and measured in time? | The sprint report | Asked without a recommendation, so your "recommendation on all" did not settle it |
| How fast should a beam fly? | Not asked yet | It needs the beam clip, which does not exist |
| The weak-enemies questions (two now, six after the clip) | The sprint report; `docs/ep/proposals/horde-trial-design.md`, section 11 | The first two are asked; the clip is being cut |
| Should LB + A, the one dead press, become a counter? | `docs/combat/move-table-s4.md:69` | Not yet put to you |

Also yours, but not a design question: where the second backup copy of the project should live (`docs/tools/backup.md`).

## Records that disagree, for the EP

| What | Evidence | Fix |
| :--- | :--- | :--- |
| QA's A1 work is almost all uncommitted: four readings, five tools, the bug list. It is in no park and nobody has reviewed it | `git status` on `qa/godot/` and `docs/qa/runs/6a30b4c9/` | QA lists it; the EP commits it. Until then every X-06, X-13, X-16 and X-17 row above rests on files that exist only on this PC |
| The sprint page puts the first desktop build after the second landing | `docs/ep/sprints/A1-sprint.md:26-27`, against the path's amendment (`04-path-to-alpha.md:26`) | Swap steps 6 and 7 |
| The EP's rulings of 20 November on the first stack's review (launch distance stays 2.0; the new menu stays on; the recorder check; the planet type in the golden) are not written in the sprint page or a decision | Searched `docs/ep/sprints/` and `docs/decisions/` at 485b328a; they were given to the stand-in by message | One paragraph in the sprint page |
| Production's tracker is stale | `docs/production/milestone-rows.md`: every QA and Performance row "not started"; one row marked "landed" whose Windows step has never run (`:146`); the mode test marked "parked" though it is on main | Production updates it from this page |
| The EP's count of switch rows still differing was due every two days | Last count 14 November | A fresh count when the first stack lands |

## How this was done

Five readers (on the cheaper model) each took one group of criteria and returned 104 evidence rows with file and line. The stand-in merged them into the 44 parts above, kept the strictest reading where two readers differed (trial S5), and re-opened the file behind each of the five "met" rows and several others. States are as of commit 485b328a; the first stack was not on main at that commit. Cost: about 0.9M tokens for the readers, plus the stand-in's own reading and writing.
