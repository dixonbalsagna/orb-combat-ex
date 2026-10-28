# Gen 2 baseline: the arm-3 bands on procedural planets (QA, cloud, 2026-10-28)

Brief: `docs/ep/cloud-briefs/qa-gen2-baseline.md`. Build: origin/main **767ed0d**, run in a scratch `git archive` with the branch's `qa/godot/` laid over it. The overlay is disclosed: `brawl.launcher.anywhere.enabled`, `anywhere.answer.enabled`, `water.enabled` and `rally.enabled` set to true. Everything else is main's own: `linkWorth` 0.8, `pop.full` 0.72, `pop.stringPoints` 3, easy's answer 0.25.

## The table

Three arms on the same seeds 1 to 200. The **control** is the hand-made world that every earlier read ran on. **Gen 2** is the same matches on gen 2 planet rings. A third arm, **gen 1 rings**, uses the same planets and touches made by gen 1; it separates "a planet ring" from "gen 2's content". Each cell gives the value with its 95% bootstrap interval over matches (2,000 resamples, seeded). Win shares carry a Wilson interval.

| Row (band) | Gen 1, hand-made world | Gen 1 planet rings | **Gen 2 planet rings** |
| :--- | :--- | :--- | :--- |
| Match length, median (360 to 480 s) | 398.6 (385.1 to 412.9) | 400.1 (385.1 to 411.1) | **395.6** (381.5 to 410.7) |
| Match length, p10 (at least 300 s) | 305.7 (292.0 to 319.0) | 309.9 (300.4 to 331.5) | **304.2** (296.3 to 317.4) |
| Match length, p90 (at most 600 s) | 549.3 (520.9 to 574.0) | 531.1 (500.9 to 566.0) | **523.4** (495.4 to 568.1) |
| Rallies a match (3 to 10) | 5.71 (5.33 to 6.13) | 5.27 (4.86 to 5.70) | **5.30** (4.91 to 5.71) |
| Full launches a match, L16 (6 to 12) | 8.99 (8.41 to 9.63) | 8.36 (7.84 to 8.88) | **8.49** (7.92 to 9.08) |
| Links a rally, median (2 to 4) | 2 (2 to 2) | 2 (1 to 2) | **2** (1 to 2); mean 2.88 (2.69 to 3.08) |
| Rallies that turn (15 to 40%) | 19.9% (17.7 to 22.2) | 16.9% (14.9 to 19.0) | **18.4%** (16.1 to 20.7) |
| Civilians lost at the KO (12 to 30%) | 20.5% (19.0 to 22.1) | 21.5% (19.8 to 23.2) | **22.6%** (21.2 to 23.9) |
| Structures lost at the KO, share (watch, §21 15 to 40%) | 31.5% (28.4 to 34.8) | 58.0% (54.6 to 61.5) | **59.9%** (56.4 to 63.5) |
| Structures on the ring | 118 | 43.4 | 38.5 |
| Structures levelled a minute at tier 2 (at most 4%) | 0.90 (0.57 to 1.31) | 3.35 (2.65 to 4.15) | **4.01 (3.19 to 4.97) FAIL** |
| Journeys over 4,000 units (at most 20%) | 11.6% (9.4 to 13.9) | 21.1% (18.1 to 24.3) FAIL | **20.8% (17.8 to 23.7) FAIL** |
| Bounces a bounced journey (1.2 to 2.0) | 1.66 (1.51 to 1.81) | 1.75 (1.62 to 1.89) | **2.04 (1.86 to 2.22) FAIL** |
| Masher easy / medium / hard (60+; 35 to 50; at most 15), 100 each | 99 / 39 / 0 | not run | **95 / 46 / 0** |
| Newcomer v easy (L17, 50 to 95%), 200 | 88.5% (83.3 to 92.2) | not run | **84.0%** (78.3 to 88.4) |
| Newcomer v medium (L17, 10 to 50%), 200 | 27.5% (21.8 to 34.1) | not run | **23.5%** (18.2 to 29.8) |
| First-launch rows (first60, thrown60, landed120), easy and medium | 100% on every row | not run | **100%** on every row |
| Timeouts at 900 s | 0 | 0 | 0 |
| Hashes repeat (5 seeds) | | | **5 of 5** |

**The control reproduces the fourth and fifth addenda to the digit** (p10 305.7, median 398.6, p90 549.3, rallies 5.71, L16 8.99, turns 19.9%; newcomer 27.5% and 88.5%; masher 99 / 39 / 0). Main has moved since de029972, but these matches have not.

## Method

- **Gen 2 matches.** `QA_PLANET="gen=2;planets=3,7,11,13,17,19,23,25,29,31;touches=0,1,2,3;cols=2400"`. Seed s plays planet `planets[(s-1) % 10]` at touch `touches[((s-1)/10) % 4]`, on a 2,400-column ring (the campaign's `ringCols`) with `intro: false`. That gives 10 planets × 4 touches, 5 matches on each pair. The hand-made world has 4,800 columns, so a ring is half the length.
- **Runs.** Records: `run-arm.js --count=200 --jobs=4` with `QA_AUTOPSY=1`. Newcomer jobs: `masher-only.js` on seeds 1 to 100 and 101 to 200, added together. Masher levels: 100 matches. The machine is a 4-core cloud container at normal priority. No job was invalid, wall-capped or budget-stopped. One run's wrapper hit the tool's 2-hour limit and killed its children; the stage was resumed from its save files (jobs already saved are not re-run), so no figure mixes two runs of the same job.
- **Hashes.** Seeds 1, 42, 105, 158 and 200 were re-run alone in fresh processes, without the batch's other planets warmed. The gameplay hash and the whole record are identical to the batch in all 5 (for example, seed 105, planet 17, touch 2: `6acffdb552422937`).
- **Autopsy.** `autopsy.js` on the control and gen 2 (shortest 20, all, longest 20). The fight's own flow does not move. The loser's damage is 75.4% brawl and 17.3% energy on the control against 75.6% and 17.4% on gen 2. The brawl rate is 24.6/s against 25.1/s, pops 11.7 against 11.9 a match, the median launch gap 8.3 s against 8.5 s, and no KO falls within 2 s of an anywhere action in either. The shortest 20 differ by less than 1 s/s.

## Findings: where gen 2 leaves a band

1. **Structures levelled a minute at tier 2 (4.01%, band at most 4%) and structures lost at the KO (60% against 31%).** **Cause: the absence of buildings.** A ring stands about 38 to 43 structures against the hand-made 118, and the row is a share of them. In absolute terms tier 2 levels 1.54 a minute on gen 2 against 1.06 on the control, while the share rises fourfold. The gen 1 rings already read 3.35 (2.65 to 4.15), and their tier 1 reads 2.08 (band at most 2%), so the cause is a planet ring, not gen 2's content. Planet 11 (8 structures) loses 81% of them; rings with 50 or more structures read 2.85 to 3.94 a minute. **Owner: World** (the ring's sites and structures, `sites.json`). Whether the share bands should be re-based for a ring of 40 structures is **Game Design's** call.
2. **Journeys over 4,000 units (20.8%, band at most 20%).** **Cause: planet size and the absence of buildings,** not gen 2's content. The gen 1 rings read 21.1%, and the control reads 11.6%. On a ring there is less to stop a body (fewer walls and buildings), and the biome mix shifts from desert (36.6% of fight time on the control) to forest, ocean and plains (about 16 to 20% each). The overshoot is inside the interval of the band edge. **Owner: World.**
3. **Bounces a bounced journey (2.04, band 1.2 to 2.0).** **Cause: the biome mix and gen 2's ground profiles.** This is gen 2's own: the gen 1 rings read 1.75. The share of launches with a bounce rises from 23.8% on gen 1 rings to 26.8%. Gen 2's ground profiles (`data/biomes/ground.json` absorb) and its new fine biomes are the change between those two arms. The interval (1.86 to 2.22) straddles the band edge. **Owner: World** (ground profiles).

**Leads, not findings.** `zip.price` reads 1 of 333 off the table on gen 2 (seed 105: a light paid 21.77). These records carry no director line, so the price is read from the ki one tick later, and a ki change landing in the same tick fits; neither control has a miss. `10.brawl.share` reads 50.1% and 50.5% on both ring arms against a ceiling of 50%, with the control at 49.3%: that is noise at the edge. `5c.bounced` and the other journey-ending mix rows fail on all three arms alike, so they are not gen 2's.

**Everything else holds on gen 2:** match length, rallies, L16, links, turns, civilians, the masher at every level, the newcomer at both levels and the first-launch rows.

---

SUMMARY: Gen 2 keeps every whole-match, rally, newcomer, masher and first-launch band of the arm-3 read: p10 304.2 s (296 to 317), median 396, p90 523, newcomer 84.0% and 23.5%, masher 95 / 46 / 0. Hashes repeat on 5 of 5 seeds. Three rows leave their bands. Two of them (structures a minute at tier 2, long journeys) already leave on gen 1 planet rings, so a ring's 40 buildings and its length cause them. The third (bounces 2.04) is gen 2's ground. The hand-made control reproduces the last reads to the digit.

CHANGES: `qa/godot/qa_planet.gd` (new: a planet ring per seed from `QA_PLANET`). `qa/godot/records.gd`, `masher.gd` and `players.gd` now pass their match setup through it, and records.gd writes a `ring` field on planet runs. With `QA_PLANET` unset nothing changes: hand-made records from main's and the branch's records.gd are byte-identical. `qa/godot/compare-arms.js` (new: arms side by side with seeded bootstrap intervals, `--by-ring` splits by planet, touch and sea share). This report.

DECISIONS: The control is the hand-made world, as the brief defines gen 1, plus a gen 1 planet-ring arm to tell the ring from gen 2's content. Rings are 2,400 columns (the campaign's `ringCols`), 10 planets × 4 touches. No fix is proposed (Game Design's call).

NEEDS FROM EP: Nothing outside qa/ was needed. Please route: (1) to **World**: structures on a ring (about 40 against 118), long journeys, and gen 2's bounces (ground.json absorb). (2) To **Game Design**: whether the structure-share bands (15.str, §21) are re-based for planet rings. (3) A lead for **Encounter**: the zip.price miss at seed 105 on gen 2, to confirm with the director line.

RISKS: Ten planets and four touches are a sample, not the space. The per-planet rows are 20 matches each and only indicative. The rally-turn row on the gen 1 rings sits at 16.9%, close to its 15% floor. The sim gates (`npm test --prefix sim`, anim_check, the world checks, split_sweep, campaign_episode, parity) were not run, because no sim/, render/ or data/ path changed.

NEXT: When gen 2 is switched on, re-read these rows on the shipping ring setup (the campaign's own rebased rings and turns, through `SimCampaignRun`). Once World answers on building counts, re-read the structure rows on the new rings.

### Gates (this tree)

- `node tools/validate.js`: `278 files checked, 0 errors, 0 warnings`, exit 0
- `node tools/validate.js --self-test`: `parser 283 files + 7 text cases; engine 46 cases + 6 unsupported; schemas 170; data cases 8177`, exit 0
- `node tools/lint-determinism.mjs`: `determinism lint ok: no engine trig, PI/TAU, random numbers or clock in sim/core, sim/director, sim/world, sim/input`, exit 0
- `node qa/godot/selftest.js`: `godot qa selftest: 31 passed, 0 failed`, exit 0
- `node qa/run-all.js --quick`: `all 7 test files passed`, exit 0
- Records with `QA_PLANET` unset, 2 matches, main's records.gd against the branch's: byte-identical
