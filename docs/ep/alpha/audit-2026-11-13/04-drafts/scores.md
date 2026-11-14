# Scores for the three path drafts

Scorer's sheet, 2026-11-13. Rules: `docs/ep/alpha/alpha-audit-specification.md` lines 576 to 600. Rows, needs, hash flags and size classes were read from `03-gap-register.json` by the scorer's own script, which parsed each draft's "gaps closed" lists and golden-window lists out of the written file (not from the planners' summaries).

**Best-scored draft: risk first (`path-risk.md`), 82 of 100.** Modes first 79. Newcomer first 76. The gap is small; the grafts below matter as much as the pick.

## What the script found

| Check | Risk | Modes | Newcomer |
| --- | --- | --- | --- |
| Rows placed | 180 | 190 | 181 |
| Required rows (174) in exactly one milestone | 174 | 173 | 173 |
| Required rows missing | none | A-PERF-02 (moved after Alpha) | A-PERF-02 (moved after Alpha) |
| Rows placed twice | 0 | 0 | 0 |
| "After" rows placed | 0 | 0 | 0 |
| Nice rows placed | 6 | 17 | 8 |
| Rows placed before a row in their "needs" | 0 | 0 | 0 |
| Needs links that share a milestone | 47 | 43 | 44 |
| Hash rows placed, and all inside a named window | 36, yes | 39, yes | 36, yes |
| Windows (hash rows in each) | 4 (12, 11, 10, 3) | 4 (11, 8, 18, 2) | 3 (12, 8, 16), plus a reserve |
| Milestones with no hash row | A2, A5 | A2, A6 | A2, A5 |
| Row tokens at the register's classes | 177.55M | 181.95M | 177.8M |
| Row tokens the draft budgets | 177.55M (register classes) | 155.9M (ten resizes already taken) | 164.2M (five resizes already taken) |

All three self-checks match the script. Every milestone's token figure reproduces from the size classes (S 0.25M, M 1.2M, L 4M, XL 8M) once each draft's own resizes are applied.

The longest chain in the register's "needs" field, by cost: A-ENERGY-02 > A-ENERGY-01 > A-COMBAT-04 > A-CONTROLS-06 (13.45M). Next: A-MODES-02 > A-AI-01 (12M), then A-CODE-03 > A-CODE-01 > A-TOOLS-01 > A-PERF-01 or A-TOOLS-02 (10.65M).

## The table

| # | Rule | Risk | Modes | Newcomer |
| ---: | --- | ---: | ---: | ---: |
| 1 | Every milestone ends in a build the owner can play, with "what to try" | 9 | 9 | 8 |
| 2 | Criteria testable, from X-01 to X-34, tool built before the milestone that must pass | 8 | 9 | 7 |
| 3 | Every required row in exactly one milestone (by script) | 10 | 8 | 8 |
| 4 | Order, and no row before a row it needs (by script) | 7 | 8 | 6 |
| 5 | Hash rows bundled into few golden windows | 7 | 9 | 8 |
| 6 | Budgets follow size classes; weeks honest | 8 | 6 | 8 |
| 7 | The critical path and three risks are the real ones | 9 | 8 | 7 |
| 8 | Decisions few, plain, each with a recommendation, none decided for the owner | 7 | 5 | 6 |
| 9 | After Alpha is listed | 9 | 9 | 9 |
| 10 | The change-control rule is usable | 8 | 8 | 9 |
| | **Total** | **82** | **79** | **76** |

## Reasons and faults, rule by rule

### 1. A playable build with "what to try"

- **Risk, 9.** All six milestones have "What Orb can play" and a PLAY THIS with things to try. Fault: A1 and A2 give nothing new to press, and A1's page asks the owner to judge four trial clips, not a build (`path-risk.md:40`, `:94`).
- **Modes, 9.** Every PLAY THIS names what is new and what to try, and the overview table shows which modes start from the menu at each milestone (`path-modes.md:15-22`). Fault: A6 has nothing new (`path-modes.md:222`), which is right for a candidate but thin as a page.
- **Newcomer, 8.** All five present. Faults: A3's playable thing is two builds (a tester build and a "LAN flavour"), which the page does not tell the owner how to tell apart (`path-newcomer.md:133`); A5's "try" is the checklist only (`path-newcomer.md:231`).

### 2. Testable criteria, tools before the pass

- **Risk, 8.** The best on early tools: the probes for X-03, X-04, X-13, X-16 and the 1280 by 800 sweep exist at A1 (A-COMBAT-08, A-UI-09), the soak and the Deck bench at A2, and most criteria are marked "first reading" or "must pass". Faults: X-05 "exists and passes" at A3 with the smoke suite (A-MODES-08) built in A3 (`path-risk.md:149`); X-03 must pass at A4 with its probe (A-CONTROLS-06) built in A4 (`path-risk.md:188`); X-17 must pass at A1 with its count built in A1 (`path-risk.md:51`); X-08 is reworded from 5 to 10 seconds outside the decisions table (`path-risk.md:297`).
- **Modes, 9.** States one rule and keeps it: a tool and its first reading in one milestone, the pass from the next (`path-modes.md:13`). X-03's probe is A4 and its pass A5; X-14's check is A4 and its pass A5; the probes for the fight are built in A3 before A4. Faults: the soak script (A-QA-02, a blocker) is not built until A5, so the first two-hour soak is on the candidate (`path-modes.md:196`, `:231`); the horde's largest wave is never read on a Deck before A6 (`path-modes.md:118`); X-18 by a real outside install from the itch.io page is first tried on the candidate.
- **Newcomer, 7.** Probes are built in A3 before A4 (`path-newcomer.md:149`). Faults: X-06 Easy must pass at A1 on 40 matches (`path-newcomer.md:44`) while A-AI-11, which says 40 matches cannot tell bands apart, is in A2; X-03 and X-14 must pass at A4 with A-CONTROLS-06 and A-WORLD-06 built in A4 (`path-newcomer.md:188`, `:191`); X-18, X-20 and X-22 must pass at A2 with their tools built in A2 (`path-newcomer.md:90-94`); "Round 1 returned" is an exit criterion of A2 (`path-newcomer.md:100`) although round 1 is said to run during A3 (`path-newcomer.md:121`), so A2 cannot close when the page says it does.

### 3. Every required row in exactly one milestone

- **Risk, 10.** 174 of 174, none twice. A-PERF-02 is kept, made smaller, in A3.
- **Modes, 8.** 173 of 174. A-PERF-02 (a required blocker) is moved after Alpha (`path-modes.md:257`). Stated openly with a reason, but it is not the planner's to move.
- **Newcomer, 8.** 173 of 174, the same row (`path-newcomer.md:266`).

### 4. Order

No draft places a row before a row it needs. The scores are for the order of the four bands.

- **Risk, 7.** Main becomes the played game first, the outside-tester gates second, and the first real Deck run is at A2, which is sound. Faults: the safety gates (A-LEGAL-01, A-LEGAL-03, A-LEGAL-08) are A2, not A1, behind a 72-row A1 (`path-risk.md:108-120`); the mode list and fighter pick (A-MODES-01, A-MODES-06, both blockers) and the mode smoke suite wait until A3 (`path-risk.md:159-162`), so the fight is reworked before any mode but solo runs end to end and before an automatic run can try it in every mode; six of the eight modes are not playable until A4.
- **Modes, 8.** The closest to the specification's order: safety and the build blockers in A1, modes in A2 and A3, the fight in A4, the newcomer in A5. Faults: "blockers first" is reinterpreted (`path-modes.md:7`) so the five fight blockers (A-COMBAT-01 to 04, A-ENERGY-01) land fourth of six; the horde and the computer's team play are built on the old fight and then have the fight changed under them; Easy is tuned in A3 (A-AI-02) before the rules change in A4; the itch.io rehearsal (A-TOOLS-02, A-TOOLS-03, blockers) is A3, after a friend has already been handed a build at A2; A1 carries A-LEGAL-01 (a failing reading), A-CODE-01, A-TOOLS-01 and the mode shell at once.
- **Newcomer, 6.** Puts the newcomer's path ahead of the modes, argued at `path-newcomer.md:275`. Faults: outside testers hold a build before six modes exist and before the fight's rules are the Alpha's, so two rounds of volunteers' time are partly spent on a game that will change; the fight blockers are last before the candidate with no milestone between them and the candidate; polish and the candidate are one milestone; Easy is tuned at A1 (A-AI-02) three milestones before the fight it is tuned for.

### 5. Golden windows

- **Risk, 7.** Four windows, every hash row inside one, and the terrain rows ride the fight's window. Faults: the fourth window is inside the candidate milestone (`path-risk.md:271`), so every probe is re-run after the candidate's numbers move; the fight's rules are split across GW2 and GW3, so the move table and transformations re-record a second time on rules a month old.
- **Modes, 9.** Four windows, the last (two rows, numbers only) closes at A5, and A6 is frozen (`path-modes.md:212`, `:240`). Fault: W3 holds 18 rows, four of them nice (`path-modes.md:176`); one window that large is hard to land in one go.
- **Newcomer, 8.** Three windows, the fewest. Fault: tuning (A-QA-05, A-QA-08) sits inside the same window as the rework it tunes, and a "reserve" fourth window (`path-newcomer.md:213`) is likely to be used, so the honest count is four.

### 6. Budgets and weeks

- **Risk, 8.** Budgets at the register's classes with the resized figure given beside (187M and 168M), 25% rework on top, weeks as ranges, the owner's play counted at two to four days a milestone and the friends' evenings counted (`path-risk.md:9-17`). Faults: A1 (72 rows, 14,805 uncommitted paths, five trials) in 1.5 to 2.5 weeks and A5 in one week including a dress rehearsal are thin (`path-risk.md:80`, `:244`); the 4.5M for trials and 5M for verification are the planner's own figures.
- **Modes, 6.** Says the record is thin (`path-modes.md:9`). Faults: every budget already takes ten resizes the owner has not agreed to (`path-modes.md:248`); the pace assumed is the highest of the three (about 60M a week); 8 to 11.5 weeks is the shortest total and excludes the year-end holidays by its own note (`path-modes.md:25`); A2 puts both LAN modes in the game, the team match and four L rows into 1 to 1.5 weeks (`path-modes.md:105`); the owner's play is "about an hour" a build (`path-modes.md:27`).
- **Newcomer, 8.** The most careful pace (20 to 30M a week), 11 to 16 weeks, volunteers given one to two weeks a round, and "add 2 weeks if the fight starts cold" (`path-newcomer.md:217`). Faults: budgets take five resizes as agreed (`path-newcomer.md:346`); the reserve is 14M on 164M, about 8%, against a record with no comparables (`path-newcomer.md:22`); work done behind switches in A2 and A3 is counted in A4's tokens but in A2's and A3's weeks.

### 7. Critical path and risks

- **Risk, 9.** The chain matches the register's longest needs chain and adds the two that run beside it; the three risks (main cannot simply become the played game, the Deck, the fight rework) each have a guard and one has a stop rule (`path-risk.md:417-434`). Fault: the trials that size the risks are themselves unbudgeted in weeks.
- **Modes, 8.** Names the same chain and makes one finding the others miss: Encounter Systems sits on five links, so its queue sets the date (`path-modes.md:298`). Fault: part of that chain is made by this draft's own order (the horde ahead of the fight), not by the register.
- **Newcomer, 7.** Two chains, tokens and people, and the only draft to make the failing outside-tester gates a top risk (`path-newcomer.md:338`). Fault: making main the played game, the step everything waits on, is not among the three risks.

### 8. The owner's decisions

- **Risk, 7.** 23 rows, each with one recommendation and what it blocks; budgets stay at the register's classes, so no resize is taken for the owner. Faults: 23 is not few, and rows 16, 17 and 22 each hold three or four questions (`path-risk.md:457-463`); the X-08 rewording is not in the table (`path-risk.md:297`).
- **Modes, 5.** Grouped by when each is needed, which is useful. Faults: 22 numbered items hold about 35 questions through "Also:" riders (`path-modes.md:314`, `:318`, `:321`, `:333`, `:341`); the resizes of A-CODE-05 and A-RENDER-06 and the move of A-PERF-02 are in the budgets with no question of their own; the reading of "blockers first" is decided, not asked (`path-modes.md:7`); line 307 tells the owner a topic was left off.
- **Newcomer, 6.** Asks the fight's decisions at A1, the right time. Faults: 26 items, with item 18 holding about ten answers and item 22 five (`path-newcomer.md:370`, `:376`); "this draft plans on the recommendation" (`path-newcomer.md:346`).

### 9. After Alpha

- **Risk, 9.** Everything the specification names, the remainders of each resize, and the 22 rows with a line each (`path-risk.md:374-401`). Fault: A-COMBAT-09 is both in the pool and on this list.
- **Modes, 9.** Complete and grouped, with the reason beside the rows that need one (`path-modes.md:279-286`).
- **Newcomer, 9.** Complete, with the Steam items and the backburnered meters placed (`path-newcomer.md:304-312`).

### 10. Change control

- **Risk, 8.** Three plain tests for "now", a trial's page counts as a change request, no rule changes after A4, first log entries listed (`path-risk.md:403-413`). Fault: during the push it does not say that the owner sees and agrees each line, or how fast.
- **Modes, 8.** One log with a place, the owner's own words, a size class and a hash flag, and "nothing is refused silently" (`path-modes.md:290`). Fault: no time limit, and no rule for testers' findings.
- **Newcomer, 9.** Six numbered steps: logged the same day, a recommendation within one working day, nothing built before the owner's yes, like-for-like swaps mid-milestone, a rule for testers' findings, and a standing exception for safety, Legal, spending and anything public (`path-newcomer.md:314-326`).

## Grafts onto the risk-first draft

**From modes first**

1. Move the mode list, the fighter pick, the Quit row and the mode smoke suite into risk's A1: A-MODES-01, A-MODES-06, A-MODES-11, A-MODES-08 (modes has them in A1; risk in A3, A3, A2, A3). Solo and two players then start from the menu from the first build, and the smoke suite exists a milestone before risk's A3 and A4 must pass X-05. None has a hash flag; A-MODES-08 needs A-MODES-01 and A-TOOLS-01, both then in A1.
2. Adopt the tool rule of `path-modes.md:13` across risk's milestones: where a tool and its first reading share a milestone, the pass is required from the next. In practice: X-03's pass moves from risk's A4 to A5 (A-CONTROLS-06 stays in A4), X-17's A1 line becomes a reading.
3. Close the numbers window before the candidate: move risk's GW4 rows A-QA-05 and A-QA-08 (and A-AI-02) from A6 to the end of A5, as modes' W4 does, so A6 is frozen and the candidate's measurements are not taken on numbers that moved that week. Risk's A5 then gains a window; its A6 keeps none.
4. Add the Encounter Systems finding to risk's critical path: that one director holds the switch rows, beams, signatures, the horde's enemies and the bands, so its queue sets the date (`path-modes.md:298`).
5. Group risk's decisions table by when each answer is needed (to start A1, during A1 for A2, and so on), as modes does.
6. Take modes' two placements that keep work together: A-ENERGY-07, A-ENERGY-08 and A-UI-10 are fine where risk has them, but A-QA-04 (balance between the two fighters) should be re-read at the numbers window as well as at A1, as modes does at A5.

**From newcomer first**

1. Bring the outside-tester gates forward so they are being worked from the first day of A1 and are the first thing briefed: A-LEGAL-01, A-LEGAL-08, A-CAMERA-02, A-LEGAL-03 (newcomer A1; risk A2). If they cannot close in A1 they close early in A2, but a failing reading on the ground every played build uses should not wait behind 72 rows. Add it to risk's three risks as newcomer does (`path-newcomer.md:338`).
2. Bring the tester guide and the real itch.io install forward: risk's A2 Deck session should use a first full draft of A-QA-01 and the real restricted page (A-TOOLS-02, already in risk's A2), not a one-page sheet, and should ask two friends, not one. A-QA-01 still closes in A5.
3. Make later builds reach the same friends as updates through the page (risk already asks for bench files at A3 and A4; make each a real update), so X-30 and X-31 are exercised several times before the candidate.
4. Ask the fight's decisions at A1 (`path-newcomer.md:358-362`): the stamina loop's extent, how much gravity well, the move table's bar, the "workshop this" items. Risk asks them as rows 11 to 15 with no date; its trials S1, S2 and S4 need the answers' shape to know what to try.
5. Use newcomer's change-control steps as the frame (the one-working-day recommendation, the owner's yes before anything is built, the like-for-like swap, the tester-findings rule, the standing exception), and keep risk's three tests for "now" and its "a trial's page is a change request" inside it.
6. Use newcomer's pace (20 to 30M tokens of landed work a week) as the low case beside risk's 35M, and its allowance of one to two weeks for each round of volunteers.
7. Keep a reserve for fixes after each tester round (newcomer holds 6M after round 1 and 8M at the candidate); risk has only the 25% overall.

## Faults all three share

1. **Too many decisions.** 22 to 26 numbered items, each bundling more, against a rule that asks for few. None separates "the owner must choose" from "the owner only needs to hear the default".
2. **The same resizes are assumed by all three** (the horde at three bodies inside the five-body limit, the smaller move table, LAN for the trusted two on Windows only, two pads, a seed and three dials). Two drafts put them in the budgets. If the owner declines the larger ones, every draft grows by 15 to 20M tokens and one to three weeks, and none shows that path as a plan.
3. **Criteria are reworded by the planner**: X-08 (5 seconds to 10, Windows only), X-05 (LAN modes on Windows only), X-11 (no size), X-03 (the smaller table), X-15 (risk). These are changes to the exit criteria and belong to the audit and the owner, with the reason, not inside a milestone's text.
4. **X-03's probe cannot be built early.** The register says A-CONTROLS-06 needs A-COMBAT-04, so the probe and the table land together in every draft. The dependency should be questioned: a probe that presses every cell can be written against today's table.
5. **A-CODE-01 and its ten needed rows share one milestone** in all three (43 to 47 needs links sit inside a single milestone per draft). The script passes them, but none gives the order inside A1, which is where the first risk lives.
6. **No comparables.** All three say the size classes have no finished work behind them, and all three still give totals to a decimal place. A-PROCESS-08 (the weekly record) is in A1 everywhere, but no draft names the date the weeks are re-estimated.
7. **The year-end holidays are not in any range.** Modes says so; the other two do not mention them. Every range runs through late December.
8. **The first two-hour soak on a real Deck, the horde's largest wave on a Deck, and LAN 2v2 across five matches are each first passed late** (the candidate, or one milestone before it) in every draft.
9. **No milestone says what happens if its exit is missed**: slip, cut, or ship the milestone short. Risk has one stop rule (the gravity well at A3's midpoint); the others have none.
10. **The first desktop build is assumed to work.** All three make "one command builds Windows and Linux from main" an A1 exit; none plans the first desktop build of the played game as its own early step with its own look check against the browser build the owner played.
11. **Directors' load is not checked.** Each lists who is active; none adds up a director's rows per milestone against what one session lands in a week. Modes notes the Encounter Systems queue but does not re-order for it.
