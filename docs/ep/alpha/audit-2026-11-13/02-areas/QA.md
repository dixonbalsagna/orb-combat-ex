# Alpha audit, area QA: QA and testing

Baseline 8901d351 (game code of the played build, 6a30b4c9). Read-only review, 2026-11-13. Owner of the area: QA & Balance (`qa/`, `prototype/tools/`; `DIRECTORS.md:447`). Sources used first: `reads/RR-06.md`, `reads/RR-08.md`, `01-inventory/I-06-net-qa-prototype.md`, `01-inventory/I-11-builds-evidence-ci.md`; the lines relied on were re-read in the files.

## Summary

- **Works:** a seeded headless batch harness with scripted players, a green CI job for the old prototype suite, and careful replays of Orb's saved play files on the build's own data.
- **Does not:** none of the four exit criteria this area touches (X-01, X-06, X-13, X-25) is met or even measurable in full today.
- **Biggest gap:** nothing exists for outside testers (no checklist, guide or protocol), and nothing soaks the Godot game.
- The bug list holds 1 of the 52 problems Orb reported in play since 2026-11-01.
- Balance and difficulty were last measured in full on 2026-10-14, on data that differs from Orb's build on 72 of 92 switch rows.

## Questions and answers

**Q1. A single bug list with severities: does one exist? Is every bug from Orb's plays on it?**
A list exists, `qa/known-bugs.md` (217 lines). It is one file but two registers: KB-001 to KB-006 for the pinned prototype (`qa/known-bugs.md:9-14`) and GB-001 to GB-009 for the Godot game (`:21-29`). It has **no severity field**: since 2026-11-07 each entry has a release horizon (private, web, store) and a closing step (`:16`, `:18`). Its title is still "Known bugs in the prototype" (`:1`).
Orb's bugs are **not** on it. RR-08 lists 52 problems Orb reported from 2026-11-01 to 2026-11-09; one has a matching entry (terrain bounces, GB-005) and 51 have none (`reads/RR-08.md:81-83`). The newest entry was found on 2026-10-03 (`qa/known-bugs.md:200`). The problems do exist elsewhere: in `docs/ep/vision.md:1607-1703`, in QA's run records (`docs/qa/runs/1931a0f8/README.md`, `docs/qa/runs/6a30b4c9/README.md`) and in the EP's owed list (`questions.md:16`), so there are at least three lists that do not agree.

**Q2. A playtest protocol for outside testers: what they're asked to do, what's recorded, how reports come back.**
None exists. The only tester-facing page is Legal's note (`docs/legal/alpha-tester-note.md:1-3`), which covers who may test, safety and what a tester agrees to. No file says what a tester should do, in what order, or what to send back: a search of tracked file names for tester, playtest, checklist or protocol finds only that note, `docs/legal/pre-store-checklist.md`, `docs/controls/phone-test-checklist.md` and scratch or tool files; the words "tester guide" appear only in the specification and in `docs/ep/alpha/stand-in-directive-2026-11-09.md:277`.
What is recorded today, on Orb's PC only: the browser build's saved match file with Orb's answers (`docs/qa/runs/6a30b4c9/README.md:3`), the LAN build's saved files and the "Make my report folder" tool (`tools/preview/lan-report.mjs:1-10`). That tool's shortcut "points at this repository's copy" (`:4`) and writes into Orb's homework folder (`:10`), so an outside tester cannot use it as it is. The in-game feedback panel opens from the pause menu (`render/core/main.gd:38`); on 6a30b4c9 Orb found the game "paused, no menu" (`docs/qa/runs/6a30b4c9/README.md:33`; `docs/ep/vision.md:1683`).
How reports come back: Orb's answer is Discord, "Possibly discord, I do have one that I could convert over to this purpose" (`docs/ep/vision.md`, the Alpha entry, answer 4). No page tells a tester how to post there. Legal's Discord set-up question is open with Orb (`questions.md:20`).

**Q3. The soak test (X-25).**
Not present for the game. Three scripts carry the name: `qa/tests/soak.test.js:1` (1,000 matches on the pinned prototype, in CI's QA job), `sim/core/tools/soak.js:2-3` (the frozen JS core) and `sim/world/tools/gen2_soak.gd:2` (short Godot matches "a few ticks each", left out of the gated list by `tools/world-checks.mjs:19`). `sim/director/tools/stick_soak.gd:2` is a press-outcome table, not a soak. None runs the exported game, none runs for hours, none samples memory, and none has a Linux record. The only memory-like read in any tool is an object count in the network checks (`net/tools/rollback_check.gd:257`). The nearest evidence of stability is indirect: a 4-hour headless batch of 3,200 matches on 3198301f with none capped (`docs/qa/chain-3198301f.md:3`), and gauntlet cells that print "SCRIPT ERROR 0" over 40 matches (`docs/director/runs/6eec6a75/hitstop-row/final/cells.txt:3`).

**Q4. Balance bands: the target is 45 to 55% between fighters; what's measured on the current build?**
Nothing on the current build. The target is written at `docs/design/balance-targets.md:43`. The last full reading is the Protagonist at **48.9%** (interval 45.4 to 52.3), inside the band, on commit 3198301f, run 2026-10-14 (`docs/qa/chain-3198301f.md:67`, `:1`). A later batch on 0ca6f670 was stopped at four of eight arms (`docs/qa/main-0ca6f670.md:13`). QA's records for the November builds (`docs/qa/runs/`: 091dfac9, 1931a0f8, 6a30b4c9, c974e451) are replays, a LAN log read and beam tables; none has a fighter win rate. The October readings used main's data; Orb's build differs from main on 72 of 92 switch rows (`01-inventory/inventory.md:51`), so they do not describe what Orb plays. The 2v2 target (`balance-targets.md:45`) has never been measured: nothing under `qa/` mentions teams.

**Q5. The Alpha match checklist (X-13).**
Does not exist. No tool reads a match and reports which pillars showed up (a search of `qa`, `tools` and `sim` for a checklist of pillars finds none). The parts are there: QA's records count every event type in a match (`qa/godot/records.gd:507`), and the sim sends events for a crater (`sim/core/fx.gd:95`), a beam's outcome (`:180`), a transformation (`:250`) and a building hit (`:492`). An event for a lap of the globe and one for the gravity well's pull were not found in `sim/core/fx.gd`: not evidenced either way without reading every sender. QA already replays Orb's saved files on the build's tree (`docs/qa/runs/6a30b4c9/README.md:5`), so the probe could run on both scripted matches and Orb's files, as X-13 asks.

## Exit criteria

| Id | Status | Proof or gap | Measuring tool, and whether it exists |
| --- | --- | --- | --- |
| X-01 | gap | No tester checklist or guide exists (Q2), and no Alpha candidate exists to test. | Tester checklist and guide: **missing**. Legal's note exists (`docs/legal/alpha-tester-note.md`). |
| X-06 | gap | Easy: 19 of 40 (47.5%) for the Orb-scheme script on the final-patches tree (`docs/director/runs/6eec6a75/hitstop-row/final/table.txt:4`), below 60 to 80%. Medium, Hard: no record (`reads/RR-06.md:131`). | **Exists**, in Tools' folder: `tools/feel/gauntlet.gd`, arm `orbs`, `--level=easy\|medium\|hard` (`:3`, `:6`). It matches Orb's scheme (right-stick flicks, LB guard). Not yet run "on the candidate's packed data". |
| X-13 | not measurable today | No checklist probe (Q5). | Alpha match checklist probe: **missing**; event counting exists (`qa/godot/records.gd:507`). |
| X-25 | not measurable today | No soak of the Godot game on either platform (Q3). | Soak script: **missing**; the three scripts named "soak" cover other things. |

**The proposed numbers.**
- **X-06 bands (Easy 60 to 80, Medium 35 to 55, Hard 10 to 30).** Keep Easy: the record shows it is reachable (65% and 70% in two cells of the pace-match trial, `docs/director/runs/397a7adf/pace-match/gauntlet/gauntlet_cells.txt:8,12` (uncommitted)), and the EP notes 65% on the second Sunday build against 45% on 6eec6a75 (`questions.md:16`). Keep Medium as a starting point: Game Design's own band for a button masher against Medium is 35 to 50 (`docs/qa/cloud-reports/2026-11-07-city-step-one-reread.md:36`). Hard: not evidenced, no record to confirm or change it. **Change the sample:** 40 matches is too few. At 19 of 40 the 95% interval is about 33 to 62% (this audit's Wilson calculation), wider than a 20-point band; QA's own pass rule needs the interval inside the band widened by 2 points (`docs/qa/README.md:25`). 200 matches a level, with the script in both slots, would fit that rule; the gauntlet plays slot 0 only (`tools/feel/gauntlet.gd:4`).
- **X-13 (6 to 8 minutes).** Matches the design band (median 360 to 480 s, `docs/qa/chain-3198301f.md:65`). Not confirmed on the current build: Orb's one finished match on 6a30b4c9 was 19,388 ticks, about 5.4 minutes (`docs/qa/runs/6a30b4c9/README.md:3`; `sim/core/constants.gd:12`).
- **X-25 (two hours, memory growth under 10%).** Not evidenced: the project has no memory record of any length to confirm or change it. A first 20-minute pilot would show whether 10% is a sensible line.

## Findings

Gaps first by severity, then things that work. Full fields (cost basis, risk, other directors needed) are in `QA.findings.json`.

| id | kind | statement | evidence | criterion | severity | alpha | owner | cost | hash |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-QA-01 | gap | No tester checklist, guide or playtest protocol exists; only Legal's note. | `docs/legal/alpha-tester-note.md:1-3`; `docs/ep/alpha/stand-in-directive-2026-11-09.md:277`; file-name and text searches (Q2) | X-01, X-18, X-19, X-21 | blocker | required | qa-balance | S | no |
| F-QA-02 | gap | No soak test for the Godot game: nothing records crashes, hangs or memory over hours on either platform. | `qa/tests/soak.test.js:1`; `sim/core/tools/soak.js:2-3`; `sim/world/tools/gen2_soak.gd:2`; `sim/director/tools/stick_soak.gd:2` | X-25 | blocker | required | qa-balance | M | no |
| F-QA-03 | gap | The bug list holds 1 of Orb's 52 play problems since 2026-11-01; its newest entry is from 2026-10-03. | `reads/RR-08.md:81-83`, `:18`; `qa/known-bugs.md:200`, `:1` | X-02 | major | required | qa-balance | S | no |
| F-QA-05 | gap | Fighter balance is not measured on Orb's build; the last full reading (48.9%) is from 2026-10-14 on different data. | `docs/qa/chain-3198301f.md:67`, `:1`; `docs/qa/main-0ca6f670.md:13`; `01-inventory/inventory.md:51` | X-06 | major | required | qa-balance | M | no |
| F-QA-06 | gap | Difficulty is measured only at Easy for Orb's scheme; no Medium or Hard record. | `reads/RR-06.md:131`, `:114-129`; `tools/feel/gauntlet.gd:3` | X-06 | major | required | qa-balance | S | no |
| F-QA-07 | gap | Easy reads 47.5% (19 of 40) for Orb's scheme on the nearest record, below the proposed 60 to 80%. | `docs/director/runs/6eec6a75/hitstop-row/final/table.txt:4`; `.../hitstop-row/table.txt:2`; `questions.md:16` | X-06 | major | required | encounter-systems | S | yes |
| F-QA-08 | gap | A right-stick-only pad won 0 of 60 against Medium (2026-11-07) and 2 of 30 against Easy (2026-11-02). | `docs/qa/cloud-reports/2026-11-07-city-step-one-reread.md:38`; `docs/qa/cloud-reports/2026-11-02-kept-build.md:9` | X-06 | major | required | game-design | M | yes |
| F-QA-09 | gap | No Alpha match checklist probe exists. | `qa/godot/records.gd:507`; `sim/core/fx.gd:95`, `:180`, `:250`, `:492`; search (Q5) | X-13 | major | required | qa-balance | M | no |
| F-QA-11 | gap | CI's QA job runs only the legacy prototype suite; the Godot QA batch and its self-test run in no workflow. | `.github/workflows/ci.yml:30-43`; `qa/run-all.js:2`; `01-inventory/I-06-net-qa-prototype.md:43` | X-06, X-13 | major | required | qa-balance | S | no |
| F-QA-12 | gap | QA has no script or band for 2v2 or the horde. | search of `qa/` (no match); `docs/design/balance-targets.md:45` | X-09, X-10 | major | required | qa-balance | M | no |
| F-QA-13 | gap | The report route is proven only on Orb's PC: the report tool needs the repository, and the feedback panel sits behind a pause menu Orb found missing. | `tools/preview/lan-report.mjs:4`, `:10`; `render/core/main.gd:38`; `docs/qa/runs/6a30b4c9/README.md:33`; `docs/ep/vision.md:1683` | X-21 | major | required | tools-pipeline | M | no |
| F-QA-04 | gap | The bug list has no severity field, and its title still names the prototype. | `qa/known-bugs.md:1`, `:16`, `:18` | none | minor | required | qa-balance | S | no |
| F-QA-10 | gap | Match length is not measured on the current build against 6 to 8 minutes; Orb's finished match ran about 5.4 minutes. | `docs/qa/runs/6a30b4c9/README.md:3`; `sim/core/constants.gd:12`; `docs/qa/cloud-reports/2026-11-07-city-step-one-reread.md:36` | X-13 | minor | required | qa-balance | S | no |
| F-QA-14 | gap | The Orb-scheme script lives in Tools' gauntlet, plays 40 matches in slot 0 only, and fired no beam in the recorded cells. | `tools/feel/gauntlet.gd:4`, `:6`; `docs/director/runs/6eec6a75/hitstop-row/final/cells.txt:4` | X-06 | minor | required | qa-balance | S | no |
| F-QA-15 | gap | Three QA tool files carry uncommitted edits, so today's band rules are not the baseline's. | `qa/godot/bands.js` (uncommitted); `qa/godot/selftest.js` (uncommitted); `qa/godot/swing-rows.js` (uncommitted); `baseline-status.txt:100-102` | none | minor | required | qa-balance | S | no |
| F-QA-17 | gap | Five older bug entries are open or fixed but never re-checked in play since 2026-10-02. | `qa/known-bugs.md:22-27` | none | minor | required | qa-balance | S | no |
| F-QA-16 | gap | QA's tools still measure the backburnered meters and biome signature variants and still say KAI. | `qa/godot/records.gd:979-980`; `qa/run-godot.js:131`, `:140`; `qa/godot/bands.js:359`; `docs/qa/README.md:31` | none | minor | nice | qa-balance | S | no |
| F-QA-18 | gap | Orb's saved play files carry no checkpoints, so replays are checked only by running clean. | `docs/qa/runs/6a30b4c9/README.md:5` | X-27 | minor | nice | tools-pipeline | S | no |
| F-QA-19 | works | CI's QA job is green on the newest finished run, on the same game code as the played build. | ci:43553420852; `.github/workflows/ci.yml:30-43`; `01-inventory/I-11-builds-evidence-ci.md:35` | none | none | n/a | qa-balance | n/a | no |
| F-QA-20 | works | A seeded headless batch harness exists, with arms, band checks, a time guard and a refusal of short or failed runs. | `qa/godot/godot.js:36`, `:63`, `:65`; `docs/qa/README.md:9` | X-06 | none | n/a | qa-balance | n/a | no |
| F-QA-21 | works | QA replays Orb's play files on the build's own data and traces a problem to a tick and a rule. | `docs/qa/runs/6a30b4c9/README.md:5`, `:19`; commit 6d2e17e0 | X-17 | none | n/a | qa-balance | n/a | no |
| F-QA-22 | works | A scripted player matching Orb's scheme exists and takes Easy, Medium or Hard. | `tools/feel/gauntlet.gd:3`, `:6` | X-06 | none | n/a | tools-pipeline | n/a | no |
| F-QA-23 | works | The three computer levels are distinct in data: 83 values differ. | `reads/RR-06.md:108`; `data/director/ai.json:52` | X-06 | none | n/a | encounter-systems | n/a | no |
| F-QA-24 | works | Every bug entry carries a release horizon and a closing step. | `qa/known-bugs.md:16`, `:18-27`; commit 1cbdcc07 | none | none | n/a | qa-balance | n/a | no |

Owner notes. F-QA-07: `data/director/ai.json` sits under `data/director/`, read by `sim/director/ai.gd`; placed with Encounter Systems by its charter (the computer opponent), with Game Design setting the band. F-QA-13 and F-QA-18: the report and replay tools are under `tools/`, so Tools & Pipeline leads. F-QA-22: `tools/feel/` is Tools' path.

Severity notes. F-QA-01 and F-QA-02 are blockers because X-01 and X-25 cannot be met, or shown to be met, without them, and both protect outside testers; each is small to build. F-QA-07 and F-QA-08 are majors because a newcomer who loses half of Easy matches, or whose main attack input loses nearly always, is likely to stop playing; both rest on records older than the played build and need a re-read first (F-QA-06).

## Gaps the questions missed

1. **QA's measurements and Orb's build are different games.** QA's full baselines run on main's data; Orb's builds flip 72 of 92 switch rows (`01-inventory/inventory.md:51`). Only one-off reads have used a build's own tree (`docs/qa/cloud-reports/2026-11-02-kept-build.md:3`; `docs/qa/runs/6a30b4c9/README.md:5`). X-06 asks for "the candidate's packed data"; no standing QA command does that (F-QA-05).
2. **The game QA measures is not in CI** (F-QA-11). The QA job takes 1m43s of a 15-minute limit (`01-inventory/I-11-builds-evidence-ci.md`, the job table), so there is room.
3. **The right stick as a way to win** (F-QA-08). Orb's scheme attacks with the right stick; QA's own stick-only rows lose almost always. The Orb-scheme script (flicks plus LB guard) does better (45 to 47.5% on Easy), so the guard is doing the work.
4. **No team or horde coverage** (F-QA-12). Four of the eight Alpha modes are team modes.
5. **The report route for a tester** (F-QA-13). It touches X-21 more than QA, but the protocol in Q2 cannot be written until it is settled.
6. **Sample sizes** (F-QA-14). The 40-match cells cannot place a win rate inside a 20-point band.
7. **Leftovers** (F-QA-16). Harmless, but the batch summary still prints the rival's menace, a backburnered meter.

## Not evidenced

| What could not be checked | The one measurement that would settle it |
| --- | --- |
| Whether `qa/run-godot.js` and the scripted players still run on the baseline code (no Godot runs allowed). | `node qa/godot/selftest.js`, then `node qa/run-godot.js --quick`, on a clean copy of 8901d351. |
| Whether the final-patches tree behind the 47.5% Easy reading equals 6a30b4c9's packed data. | The gauntlet's `orbs` arm at all three levels on `homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d/tree`. |
| The fighters' win rate, match length and stick-only rows on 6a30b4c9. | One default-and-swap batch and the stick rows on that tree. |
| Whether a lap of the globe and the gravity well send an event the checklist could read. | A list of every event type in one recorded match of the build (the records' event counts). |
| Memory growth, crash or hang over two hours, on Windows or Linux. | A 20-minute pilot soak of the exported game with memory sampled each match, then the full run. |
| Whether the 2v2 and horde modes can be played by scripts at all. | See the MODES area; no QA script exists to try. |
| What the three uncommitted QA edits change in the band rules. | A read of `git diff -- qa` by QA, then a commit or a revert through the EP. |

## Decisions for Orb

1. **Should Easy let a player using your scheme (right stick to attack, LB to guard) win about two matches in three?** Recommended: yes, keep 60 to 80%. The last reading was about one in two.
2. **Will one of your Steam Deck friends leave the game running computer against computer for two hours and send back the result file?** Recommended: yes, ask one friend; X-25 asks for the soak on each platform, and no Linux or Deck run record exists.
3. **Is one checklist per tester, ticked and posted to your Discord with the report file, the sign-off you want?** Recommended: yes; it is the smallest thing that makes "two testers completed it" checkable.
