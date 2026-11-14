# Alpha audit, area AI: the computer opponent

Baseline 8901d351 (game code of the played build, 6a30b4c9). Read-only review; nothing was run. "Played build" means `homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d`, read from its own `tree/data/`. "Orb's-scheme pad" means the scripted player `orbs` in `tools/feel/gauntlet.gd`: right-stick flicks and LB guard. "Masher" is a script that taps X every 8 ticks. "The ring" is the parked one-versus-many director (`DirRing`).

## Summary

- **Works:** three levels in data (83 values differ), picked in the start menu and carried into the match and the replay; Easy matches the player's pace in the played build; the computer's beams use the player's own hold-and-release in the played build; 2v2 partner behaviours are coded.
- **Does not work:** Easy reads 47.5% for the Orb's-scheme pad (band: at least 70%); Medium and Hard are unmeasured; main's data is not the played build's; the computer never uses the right-stick strike; no computer ally can be started.
- **Biggest gap:** nothing drives many weak enemies. The horde's enemy control does not exist on main (X-10).

## Questions and answers

### Q1. The difficulty levels: what differs, and are their win rates measured on the current build?

**What differs.** Three levels, `easy`, `medium`, `hard` (`data/director/ai.json:55`, `:88`, `:121`); the file's own level is medium (`:52`). 83 leaf values differ between at least two levels; 4 are equal in all three (`reads/RR-06.md:115`, table at `:24-113`; spot-checked here against `ai.json:56-86`). In plain words the levels change:
- **Pace and volume in a brawl:** ticks between its lights 12, 8, 6; string length; how often it guards (0.2, 0.4, 0.4).
- **Reads:** perfect-block share (`perfectBlockMul` 0.32, 0.45, 0.55, times a brawl share, with its own rate against a heavy it sees: 0.05, 0.15, 0.3), punish, reversal, answers to beams (dodge 0.4, 0.55, 0.7).
- **Use of the kit:** launches, held heavies, blasts, zips and flight strikes, chase, transformations held back or taken.
- **Shared by all levels:** reaction time 14 ticks (`ai.json:37`), stance weights (`:41-51`), and several constants in code (F-AI-15).
- Levels change decisions only, never a fighter's stats (`docs/design/modes.md:41`; the code reads the level's block at `sim/director/ai.gd:432-434`).
- The level is one value per match, not per fighter (`sim/director/ai.gd:390-392`; F-AI-10).

**Are win rates measured on the current build? No, not on its packed data, and only for Easy.**

| Tree | Level | Pad | Won | Record |
| --- | --- | --- | --- | --- |
| 397a7adf + pace-match park, pace matching off | easy | Orb's scheme | 2/40 (5%) | `docs/director/runs/397a7adf/pace-match/gauntlet/gauntlet_cells.txt:4` (uncommitted) |
| same, pace matching on | easy | Orb's scheme | 26/40 (65%) | same file `:8` (uncommitted) |
| 6eec6a75 replay tree + hit-stop park, "shipped" | easy | Orb's scheme | 18/40 (45%) | `docs/director/runs/6eec6a75/hitstop-row/table.txt:2` |
| same | easy | masher | 18/40 (45%) | `table.txt:5` |
| 6eec6a75 + the patches that landed as 6a30b4c9, "final" | easy | Orb's scheme | 19/40 (47.5%) | `docs/director/runs/6eec6a75/hitstop-row/final/table.txt:4` |
| same | easy | masher | 17/40 (42.5%) | `final/table.txt:7` |

- The "final" cell is the nearest thing to the played build: the 6eec6a75 tree with the dash-slip and hit-stop patches laid on (`final/cells.txt:1-2`). It is not a run on the build's packed data (F-AI-04).
- **Medium and Hard: no win-rate record since 2026-11-01** (`reads/RR-06.md:117`). The design page's own table shows 0 / 0 / 0 from 10 matches (`docs/design/gauntlet-plan.md:20-22`) (F-AI-03).
- **The 65% to 45% drop the EP flagged is unprobed and may be noise.** The two cells are 26/40 and 18/40 on different trees; with 40 matches each, the difference is about 1.8 standard errors (F-AI-13). Nothing under `docs/director/runs/6eec6a75/` explains it.
- Orb's own matches against Easy (2026-11-08, 2026-11-09) have no recorded winner (`reads/RR-06.md:120-121`).

### Q2. Does Easy match the player's pace? Does the computer perfect-block charged attacks too easily?

**Pace: yes in the played build, no on main.**
- The rule is coded: Easy's gap between blows is never shorter than the median gap of the player's last 3 seconds of attack presses, kept between 12 and 30 ticks; 27 against another computer (`sim/director/pace.gd:72-82`; used at `sim/director/brawl.gd:4157`; the player's presses are noted at `sim/director/exchange.gd:736`).
- Switch: `false` on main (`data/director/ai.json:56`), `true` in the played build (`build:orb-first-play-6a30b4c9-6627cb9d:tree/data/director/ai.json:56`) (F-AI-05). Only Easy has the block; Medium and Hard keep fixed gaps, as ruled (`docs/design/gauntlet-plan.md:120`).
- Effect on record: 2/40 to 26/40 for the Orb's-scheme pad (table above, uncommitted). Its check, `pace_check`, is local only (F-AI-12).
- **But Easy is still under its band** with pace matching on: 47.5% against "at least 70%" (`docs/design/gauntlet-plan.md:22`, `:131`) (F-AI-02).

**Perfect block against charged attacks: the fix Orb's remark led to is not on main; the rate was last measured on 2026-10-16.**
- Orb, 2026-10-16: "The computer perfect-blocks charged attacks too easily" (`docs/ep/vision.md:1325`).
- Encounter's answer, the computer guessing across the charge instead of deciding before the release, is parked: "Built and read in scratch on main 0ee9cb6b. Not applied" (`docs/director/pending/perfect-guess/README.md:3`). Checked against main: the key `chargeGuess` is in the schema (`tools/schemas/director-ai.schema.json:506`) and in no data file and no `.gd` file (`git grep chargeGuess`: schema and two docs only) (F-AI-11).
- What main does today: one draw per strike with a window, and for a heavy seen wound up in a brawl the level's own rate, 0.05, 0.15, 0.3 (`sim/director/interrupt.gd:411-431`).
- Measured then: 5.9%, 6.2%, 5.1% of charged heavies perfect-blocked at easy, medium, hard, every one decided before the release (`docs/director/pending/perfect-guess/README.md:39-40`); QA's run on 0ca6f670 left the "stale mark" row pending (`docs/qa/main-0ca6f670.md:29`).
- **On the played build: not evidenced.** QA's probe exists (`qa/godot/charge.gd:2-11`); no record of it under `docs/qa/runs/`.

### Q3. Can the computer do everything a player can, and nothing a player can't?

**Everything a player can: no.**
- The computer writes the same input record a player's pad writes (`sim/input/control.gd:11-14`; `sim/director/ai.gd:52-58`), and Orb's rule is on record: "the AI can do anything the player can" (`docs/ep/vision.md:608`).
- **It never throws a right-stick strike.** The only right-stick input a computer writes anywhere in `sim/` is the beam's hold and release (`sim/director/beam_move.gd:157`, `:175-188`); its attack choices are light, heavy, the B press, guard, dodge, blast and zip (`sim/director/ai.gd:262-283`; `sim/director/brawl.gd:3754-3757`, `:4104-4140`) (F-AI-06).
- Whether it uses the two signature inputs Orb named (RT + RB + flick, RT + flick), the gravity well, or every cell of the move table: **not evidenced**; no coverage record for the computer's side exists.

**Nothing a player can't: true in the played build's data for beams, false on main, and unchecked.**
- Orb, 2026-11-06, build 10d8b8cf: the opponent "seemed to be able to pull off charging beams in melee range" (`docs/ep/vision.md:1654`).
- In the played build the computer's beams, signature included, go through the player's own hold and release (`sim/director/beam_move.gd:139-158`; switch `ownMove.enabled` and `ownMove.ai` true at `build:...:tree/data/director/interrupts.json:294`, `:303`) (F-AI-20).
- On main both are false (`data/director/interrupts.json:294`, `:303`), so the computer falls back to the old B request (`sim/director/ai.gd:260-263`, `:275-278`), which "locks its rival through the charge" in the check's own words (`sim/director/tools/beam_ai_check.gd:6`) (F-AI-05, F-AI-07).
- No record of `beam_ai_check` on 6a30b4c9 (it appears in run logs of 397a7adf, 665f58d6 and ba87218e only), and it is not in CI. No tool counts computer beams by the input that started them (F-AI-07).
- The beam count itself: Easy fired 459 beams in 40 matches against the Orb's-scheme pad, which fired none (`final/cells.txt:4`; counted from `beam_fire` events, `tools/feel/gauntlet.gd:319-320`).

### Q4. Horde enemies: any AI for many weak enemies? What does the one-versus-many choreographer support today?

**No AI for many weak enemies exists.** (F-AI-01)
- Henchmen: "Paper only: no data file, nothing built" (`docs/combat/henchmen-grades.md:3`). The page has grades, crowd caps and bands for QA (`:5-12`, `:183-185`), all unbuilt.
- **On main:** stage 1 only. A match holds 2 to 5 bodies; slots 0 and 1 are the pair the match is between; bodies past them "stand" until the director's stage 2 (`sim/core/roster.gd:36-40`; landed in 06b0200e, 2026-10-16). The computer's target is always one of the first two bodies (`sim/core/roster.gd:64-65`).
- **Parked, not on main:** stages 2 and 3, the ring (`docs/director/pending/one-v-many-s2/`, `-s3/`; `sim/director/ring.gd` does not exist on main). As parked it supports one fighter against a boss with guards: one partner in the exchange, single interjecting blows from the nearest free guard on an opening, at most one per 1.5 s, never within 8 ticks of the partner's blow; guards never launch, knock back or fire (`docs/director/pending/one-v-many-s3/README.md:22-31`). Read at 3, 4 and 5 bodies (`:33-49`). That matches the rule of at most 4 on 1.
- **What it does not cover:** weak enemies, grades, waves, respawn, more than five bodies, two players. The henchmen page's test wave is 12 (`docs/combat/henchmen-grades.md:183`).
- The park's patches use exact-text anchors and were last rebuilt on 2026-10-16; whether they still apply is not evidenced (F-AI-17).
- The co-op research recommends a different first step, two players against one boss-grade opponent, with grunts after it (`docs/research/co-op-brawler.md:9-17`); nothing was built from it (`:3`).

### Q5. 2v2 partners: is there a computer ally, and how good is it?

**No computer ally can be played with; partner behaviour exists in code and is unmeasured.** (F-AI-08)
- Teams are slots 0 and 2 against 1 and 3 (`sim/core/cross.gd:5`). The only 2v2 line-up puts the computers in the second and fourth slots, both on the enemy team (`net/lan.gd:34`), with humans in sim slots 0 and 2 (`net/lan.gd:35`).
- Coded for any computer fighter in a two-fight match: it flies to the other fight when its own is finished, drops its fight to come when its partner is on the brink and strikes from outside on an opening, and dodges a beam of the other fight that has it first on its line (`sim/director/outside.gd:156-173`, `:300-304`; called first in `sim/director/ai.gd:59-62`).
- Switch: off in data (`data/director/interrupts.json:633`, the same in the LAN build's tree); on per match by the setup key of the "together" LAN line-up only (`net/lan.gd:32`).
- Proof it works: one check record, "a computer partner comes when his partner's on the brink, and strikes from outside" (`docs/director/runs/20713b02/slip-arrive/sim_slip/outside_check.txt:14`). Not in CI.
- **How good: not evidenced.** No record measures a human-plus-computer team, and the ally would play at the enemy's level (F-AI-10).

## Exit criteria

| Id | Status | Proof or gap | Measuring tool, and whether it exists |
| --- | --- | --- | --- |
| X-06 | **Gap** (Easy), **not evidenced** (Medium, Hard) | Easy 47.5% (19/40) on the tree that became the played build (`final/table.txt:4`); no Medium or Hard record; no run on packed data | The scripted Orb's-scheme player **exists** (`tools/feel/gauntlet.gd:187-206`, with `--level`), but it is Tools', not QA's, is not in CI, and models only flicks and guard (F-AI-16). QA's nearest is the `lb` arm (`qa/godot/stickplay.gd:5-6`). Missing: a run against a build's `tree/data`, saved under `docs/qa/runs/<sha>/` |
| X-10 | **Gap** | No enemy control for a horde, no waves or respawn, five bodies at most (Q4). The frame-rate half is not measurable until a wave exists | Mode smoke: missing (see F-MODES-09). Largest-wave frame record: Performance's bench, another area's; nothing to point it at yet |

**The proposed numbers in X-06.** Change them to the project's own record:
- **Easy: at least 70%** (not 60 to 80%). Game Design ruled it twice (`docs/design/gauntlet-plan.md:22`, `:131`), with the reason: a newcomer must beat Easy within three tries and guarding is worth more than mashing (`:63`). A ceiling of 90% keeps it a fight; that ceiling is this audit's suggestion, not on record.
- **Medium: 35 to 60%** (not 35 to 55%): `gauntlet-plan.md:22`.
- **Hard: at most 20%** (not 10 to 30%): `gauntlet-plan.md:22`. A floor above 0 is worth adding, since "Hard at 0% is right" is ruled only for one-note pads (`:29`); suggested 5%.
- **Matches per cell: 100, not 40.** At 40 the reading is good to about 15 points either way, as wide as the bands (F-AI-13). The data file's own tuning notes used 100 (`data/director/ai.json:27`).
- **Add the masher beside it:** at least 60% on Easy (`gauntlet-plan.md:125`); it read 42.5% (`final/table.txt:7`).

## Findings

Gaps first by severity, then things that work. Full fields are in `AI.findings.json`.

| id | kind | statement | evidence | criterion | severity | alpha | owner | cost | hash |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-AI-01 | gap | No computer control for many weak enemies: henchmen are paper only, the ring is parked, a match holds five bodies with no waves or respawn | `docs/combat/henchmen-grades.md:3`; `sim/core/roster.gd:36-40`; `docs/director/pending/one-v-many-s3/README.md:3` | X-10 | blocker | required | encounter-systems | L | yes |
| F-AI-02 | gap | Easy is too hard for the Orb's-scheme pad: 19 of 40 (47.5%) against a band of at least 70% | `docs/director/runs/6eec6a75/hitstop-row/final/table.txt:4`; `docs/design/gauntlet-plan.md:22`, `:131` | X-06 | major | required | game-design | S | yes |
| F-AI-03 | gap | Medium and Hard have no win-rate record for Orb's scheme since 2026-11-01 | `reads/RR-06.md:117`; `docs/design/gauntlet-plan.md:20-22` | X-06 | major | required | qa-balance | S | no |
| F-AI-04 | gap | No win rate measured on the played build's packed data; records are scratch trees with patches, from a Tools script outside QA and CI | `final/cells.txt:1-2`; `tools/feel/gauntlet.gd:2-3` | X-06 | major | required | qa-balance | S | no |
| F-AI-05 | gap | Main's computer data is not the played build's: pace matching, beam pacing against a human and the hold-and-release beam are off on main | `data/director/ai.json:14`, `:56`; `data/director/interrupts.json:294`, `:303`; the build's same lines | X-06, X-17 | major | required | encounter-systems | S | yes |
| F-AI-06 | gap | The computer never throws a right-stick strike, the main attack of Orb's scheme | `sim/director/beam_move.gd:157`, `:175-188`; `sim/director/ai.gd:262-283`; `docs/ep/vision.md:608` | X-13 | major | nice | encounter-systems | M | yes |
| F-AI-07 | gap | No standing check that the computer uses only a player's inputs; on main its signature is the old B request; no record for the played build | `sim/director/ai.gd:260-263`; `sim/director/tools/beam_ai_check.gd:2-6`; `docs/ep/vision.md:1654` | X-17 | major | required | encounter-systems | S | no |
| F-AI-08 | gap | No computer ally: the only 2v2 line-up has both computers on the enemy team, and nothing can start a human-plus-computer team | `net/lan.gd:34-35`; `sim/core/cross.gd:5`; `docs/ep/vision.md:870` | X-09 | major | required | encounter-systems | M | yes |
| F-AI-09 | gap | Easy matches run long: about 576 s average for the Orb's-scheme pad, 426 s for the masher, against a 6 to 8 minute normal match | `final/cells.txt:4`, `:6` (ticks 1,383,534 and 1,021,345 over 40); `tools/feel/gauntlet.gd:91` | X-13, X-06 | minor | nice | game-design | S | yes |
| F-AI-10 | gap | The level is one value per match, not per fighter | `sim/director/ai.gd:390-392`, `:432-434`; `sim/core/sim.gd:156-157` | X-09, X-10 | minor | required | encounter-systems | S | yes |
| F-AI-11 | gap | The fix for "perfect-blocks charged attacks too easily" is parked, not on main; the rate is unmeasured on the played build | `docs/director/pending/perfect-guess/README.md:3`; `tools/schemas/director-ai.schema.json:506`; `sim/director/interrupt.gd:411-431` | none | minor | required | encounter-systems | S | yes |
| F-AI-12 | gap | The computer's checks run by hand only (level, pace, computer beam, 2v2 partner); no CI job reads a win-rate band | `.github/workflows/ci.yml:221`, `:229`, `:269`; `01-inventory/I-02-sim-director.md:12` | X-06, X-02 | minor | nice | tools-pipeline | S | no |
| F-AI-13 | gap | 40 matches a cell cannot separate neighbouring bands; the flagged 65% to 45% drop is inside the noise and on two different trees | `hitstop-row/table.txt:2`; `397a7adf/.../gauntlet_cells.txt:8` (uncommitted) | X-06 | minor | required | qa-balance | S | no |
| F-AI-14 | gap | Backburnered ideas still steer the computer: where it leads the fight comes from the hero and villain meters; hiding choices remain though no fighter can hide | `sim/director/location.gd:103-105`; `data/fighters/RIVAL/meters.json:5`; `sim/director/ai.gd:108-111`; `data/fighters/RIVAL/fighter.json:11` | X-15 | minor | nice | encounter-systems | S | yes |
| F-AI-15 | gap | Some of the computer's numbers are constants in code, not data | `sim/director/ai.gd:452-455` | X-15 | minor | after | encounter-systems | S | no |
| F-AI-16 | gap | The Orb's-scheme pad is a narrow model: flicks and guard only, 0 beams in 40 matches against Easy's 459 | `tools/feel/gauntlet.gd:6`, `:187-206`; `final/cells.txt:4` | X-06 | minor | nice | qa-balance | S | no |
| F-AI-17 | gap | The parked ring was last rebuilt 2026-10-16 with exact-text patches; whether it still applies is not evidenced | `docs/director/pending/one-v-many-s3/README.md:3`, `:7`, `:33` | X-10 | minor | nice | encounter-systems | S | no |
| F-AI-18 | works | Three levels in data differ on 83 values; the menu offers them; the level travels in the setup and the replay header | `data/director/ai.json:55`, `:88`, `:121`; `render/core/main.gd:432-438`; `sim/core/sim.gd:156-157`; `sim/core/replay.gd:233` | X-06 | none | n/a | encounter-systems | n/a | no |
| F-AI-19 | works | Easy's pace matching is built and on in the played build; it lifted the scripted pad from 2 to 26 of 40 | `sim/director/pace.gd:72-82`; the build's `ai.json:56`; `397a7adf/.../gauntlet_cells.txt:4`, `:8` (uncommitted) | X-06 | none | n/a | encounter-systems | n/a | no |
| F-AI-20 | works | In the played build the computer's beams use the player's own hold and release of the right stick | `sim/director/beam_move.gd:139-158`; the build's `interrupts.json:294`, `:303` | X-17 | none | n/a | encounter-systems | n/a | no |
| F-AI-21 | works | The computer acts only through the input record a pad writes; its perfect-block chance is data per level, lower for a seen heavy | `sim/input/control.gd:11-14`; `sim/director/interrupt.gd:421-429`; `data/director/ai.json:21` | none | none | n/a | encounter-systems | n/a | no |
| F-AI-22 | works | A scripted player for Orb's scheme exists and takes a level | `tools/feel/gauntlet.gd:3`, `:187-206`; `qa/godot/stickplay.gd:5-6` | X-06 | none | n/a | tools-pipeline | n/a | no |
| F-AI-23 | works | 2v2 partner behaviours are coded for any computer fighter and passed their check on 20713b02 | `sim/director/outside.gd:156-173`, `:300-304`; `docs/director/runs/20713b02/slip-arrive/sim_slip/outside_check.txt:14` | X-09 | none | n/a | encounter-systems | n/a | no |
| F-AI-24 | works | Stage 1 of one versus many is on main: two to five bodies, the first two decide the match | `sim/core/roster.gd:36-47`; commit 06b0200e | X-10 | none | n/a | simulation-engine | n/a | no |

Owner notes: every code and data path cited sits under an "owns" line (`sim/director/`, `data/director/`: encounter-systems; `qa/`: qa-balance; `tools/`: tools-pipeline). F-AI-02 goes to game-design because the bands and the levers are its rulings (`docs/design/gauntlet-plan.md`); Encounter applies them. `data/fighters/` (F-AI-14's meters) was not placed here; the finding's edit is in `sim/director/`.

## Gaps the questions missed

1. **Main is not the played build for the computer** (F-AI-05). Three switches that shape every solo match are on only through the build's switch page. A candidate cut from main's data would play a different, much harder Easy.
2. **The level is per match, not per fighter** (F-AI-10). Both the ally and graded horde enemies need it; the data file has called it "step 4" since the levels were written (`data/director/ai.json:3`).
3. **Match length against Easy** (F-AI-09). Nearly ten minutes for the pad closest to how Orb plays, on the level a newcomer starts at.
4. **The measuring stick is weaker than the criterion assumes** (F-AI-04, F-AI-13, F-AI-16): it sits outside QA, has never run on packed data, uses 40 matches, and plays a thin version of Orb's scheme.
5. **The computer's beam count.** 459 beams in 40 Easy matches is 11.5 a match; the data file's note still says "about 3 signatures a match (band 2 to 4)" (`data/director/ai.json:20`). The note predates the beam pacing against a human (`ai.json:14`), and the count may include stick beams as well as signatures; no band for it exists on record. Folded into F-AI-07's count tool.
6. **The cap on the computer's rush at a human is off everywhere** (`data/director/ai.json:36`, the same in the played build), though Orb's first play named being rushed "at full speed" for "cheap hits" (`docs/ep/vision.md:1316`). Whether later work (the dash's arrival ease) covers it is not evidenced; no finding raised.
7. **Leftovers of backburnered systems in the computer's choices** (F-AI-14): the roaming rule keys on the meters, so a fighter with neither meter would not roam.

## Not evidenced

| What | One measurement that would settle it |
| --- | --- |
| Win rates of the Orb's-scheme pad on the played build's packed data, all three levels | The gauntlet's `orbs` and `masher` arms, 100 matches a level, run on the build's `tree/` |
| Why Easy read 65% on one tree and 45% on the next | The same seeds on both trees at 100 matches; if the gap holds, a bisect over the patches between them |
| How often the computer perfect-blocks a charged attack on the played build, and when it decides | `qa/godot/charge.gd` at each level on the build's tree (its "stale mark" row) |
| Whether the computer ever fires a beam by an input a player lacks, on the played build | QA's beam trace extended to count computer beams by starting input, over the same batch |
| Whether the computer uses the two signature inputs, the gravity well and each move-table cell | The moveset coverage probe of X-03, pointed at a computer slot |
| How good a computer ally is | A two-fight batch with a scripted pad plus a computer against two computers: the pad's team's win rate and the ally's rescues |
| Whether the parked ring still applies to main | The owner's dry run of `s2.cjs` and `s3.cjs` on a scratch copy |
| What bodies past the second do on main today | Not read past the comment at `sim/core/roster.gd:38-39`; a 3-body headless match with the event feed |

## Decisions for Orb

1. **Should the computer use the right-stick strikes in Alpha?** Today it never does, though they are your main attack. Recommendation: yes at Medium and Hard, built before the final difficulty tuning (F-AI-06).
2. **How hard should Easy be for someone playing your way?** Game Design's rule is that such a player wins at least 7 matches in 10; the last reading was under 5 in 10. Recommendation: keep "at least 7 in 10" as the Alpha bar and tune Easy to it (F-AI-02).
3. **Is a computer partner part of Alpha's 2v2?** You asked for "CPU partner optional" in co-op; no line-up has one. Recommendation: yes, one line-up for Alpha (one human and a computer partner against two computers), so a solo tester can play 2v2 (F-AI-08).
