# Agency, slice 14: the tapped shot's share, and a floor under the flow's cut

Owner: Encounter Systems Director. Date: 2026-10-04. Status: in the tree on HEAD `32b466d`, waiting for the EP's commit. Rule: `docs/design/agency-pass.md` §23.

Everything here runs only in the `dynamic` profile.

## What changed

| Part | Rule | Where |
| :--- | :--- | :--- |
| **A tapped charged shot** | It does 0.4 of the kind's damage (was 0.6): 33 for a tap. A full charge is unchanged at 82.5 | `interrupts.json` `blast.heavy.tapShare` |
| **A floor under the flow's cut** | The winner's flow still takes up to 10 points off the rival's chance to survive his finisher, but the cut never takes the chance below 0.08, the struggle's floor. A chance already below it is left as it is | `alchemy.json` `flow.contestFloor` 0.08; `exchange.gd` `flowCut`, `_opContest`, `_opContestBranch` |
| **A comment** | The comment above the contest's branch now gives the struggle's numbers as they are: base 23, +10 a hit, −5 a missed beat, −15 a stray press, floored at 8 | `exchange.gd` |

**No new state, event, cue or feed line. No core lines.**

## Results

**QA's scripts against the medium AI,** 100 matches each (before is slice 13's build):

| Row | Before | After | Band |
| :--- | ---: | ---: | :--- |
| Mixed blaster (L L L and a tapped H, about every 14 ticks) | 61 of 100 | 46 of 100 | 30 to 50% |
| Slow mix (L L and a tapped H, every 24 ticks) | 29 of 100 | 7 of 100 | reference, no band |
| Bolt-only | 33 of 100 | 31 of 100 | 20 to 40% |

The mixed blaster is in its band at 0.4, so the step to 0.3 is not taken.

**QA's harness** (`node qa/run-godot.js`, four arms, 100 matches an arm; before is slice 13's build):

| Row | Before | After | Band |
| :--- | ---: | ---: | :--- |
| Blasts' share of damage | 11.6% | 10.8% | 10 to 25% |
| Finisher survival rate | 31.5% | 27.0% | 25 to 40% |
| The masher against the easy / medium / hard AI | 100 / 38 / 1 of 100 | 100 / 38 / 0 of 100 | at least 60 / 35 to 50 / at most 15 |
| Match length, median | 493.1 s | 477.4 s | 360 to 480 s |
| Match length, 90th percentile | 593.8 s | 588.1 s | at most 600 s |
| KAI over both slots | 49.0% | 51.5% (51.0% from P1, 52.0% from P2) | 45 to 55% |
| First brink, median | 405.1 s | 395.8 s | 270 to 420 s |
| Brink to KO, median | 69.7 s | 70.1 s | 45 to 90 s |
| Lights-only mirror, brink to KO | 34.7 s | 35.6 s | 30 to 55 s (re-based, §23) |
| Front-row structures lost | 54.3% | 55.3% | 25 to 50% |
| Perfect blocks per 100 melee exchanges | 16.8 | 16.6 | 5 to 15 |
| Exchanges that end in a knock-back | 32.4% | 32.6% | 25 to 35% |
| Launches of the exchanges that separate | 38.7% | 37.9% | 25 to 40% |
| Bolt-only against the medium AI (QA's 40-match row) | 10 of 40 | 13 of 40 | 20 to 40% |
| Arms' share of limb breaks (about 37 breaks a run) | 74.1% | 47.5% | 35 to 65% |

98 bands pass, 17 fail, 21 pending (96, 19 and 21 before). Blasts stay above 10%, so the AI's firing share is not raised. **Outside their bands:** front-row structures by 5 points and perfect blocks by 1.6. The match median is inside its band (477 s; it was over it on slices 9 to 13).

**One hard test fails in this run: C1,** the rolling 60 s casualty budget, on seed 89 (a window over budget at tier 1 or 2). Nothing in this slice touches casualties. World has a known casualty-window fault (a window that frees a second early) and takes the tree next for it; whether seed 89 is that fault was not confirmed here.

**Gates** on a clean copy of HEAD with exactly the tree's changes (no sim or data file differs between that copy's base and `32b466d`; parity again in the tree): goldens regenerated (9 matches, 176,338 ticks; 170,384 before); parity, the loader check at 200 matches, `npm test` 5 of 5, determinism, seam, the animation check, the cue check, Controls' input tests and its mash probe pass. The validator shows one error, the new key, until Tools' `apply-slice14.cjs` is run.

## Notes

- **The slow mix fell from 29 to 7 of 100.** It has no band. At one press every 24 ticks, two bolts and a tap of 33 do about 59 in 72 ticks, against 75.5 before, and every barrage of that mix is the weak one (slice 13). If a slow, deliberate mix should hold its own against the medium AI, that is a design question.

## Data keys for Tools

| File | Keys |
| :--- | :--- |
| `data/director/alchemy.json` | `flow.contestFloor` (number, 0 to 1) |
| `data/director/interrupts.json` | value only: `blast.heavy.tapShare` 0.4 |
