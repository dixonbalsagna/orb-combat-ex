# The beam baseline, the b-no-beam park replay and the charge-outcome read (QA, 2026-11-08 overnight)

EP brief of 2026-11-08 (Orb's order of 21:52) and its additions, cut by the EP's pace rule: **finish the beam baseline, the park replay and the charge read, then stop.** The close-fight control table is dropped (Encounter's audit covers it); the side-from-blow arms and the 40-a-cell re-read wait for their parks.

## Method and overlays (disclosed)

- **Build:** a `git archive` of main at **c974e451** (sim, data, net, project.godot, qa, tools/preview, tools/schemas, prototype/tools) in scratch, with the page's switches flipped (`tools/preview/switches.mjs`, 56 flipped; `flightStrikes` and `fullSend` were not present in the data), plus **QA's working copies of `qa/godot/records.gd` and `qa_planet.gd`** laid over it (uncommitted: they hold the beam, launch and control recording and the new `QA_HUMAN=rbeam` and `QA_PLANET` keys `power`, `travel`, `level`). Nothing was applied to the repo.
- **Settings:** build 2's page settings: the one energy model on (`power`), travel 1.5, whole-ring planets `gen=3;planets=3,7,11,13,17,19,23,25,37,31;touches=0,1,2,3;cols=4800`, seeds 1 to 60, the computer at **easy** and at **medium**. `--jobs=3`, below-normal priority; the machine was 20 to 76% loaded by other sessions (a deterministic sim: load changes the time, not the numbers).
- **Arms (60 matches each):** AI v AI easy, AI v AI medium, and a **scripted human** on slot 0 against easy and against medium (`QA_HUMAN=rbeam`: every 240 ticks RB goes down at tick 14, the right stick leans toward the foe from tick 20 to 92, RB comes up at 100; X is mashed with the left stick toward him the rest of the time). The human bot throws a level beam only; it is one bot's idea of using the scheme, not a player.
- **Saved:** `beam-baseline-tables.md` (the four tables), `beam-rows.csv` (all 3,723 beams: arm, seed, tick, shooter, range, dx, dy, dz, tiers, wide, window, outcome, outcome tick, target state). Records JSON are in the scratchpad only (large).
- **Definitions:** range = true distance at the fire; height difference = target minus shooter; *wide* = fired wide of him (`beam_wide`, no outcome); *answered* = the outcome the target's answer decided (DODGE, DEFLECT, GUARD, CLASH, or a late answer that started a struggle); *hit* = no answer took it; *fire to outcome* = ticks from `beam_fire` to `beam_outcome`. The window is the `beam_window` cue's hand-to-arrival ticks.

## 1. The beam baseline (for Orb's beam overhaul)

| | AI v AI easy | AI v AI medium | Human beams v easy | Human beams v medium |
| :--- | ---: | ---: | ---: | ---: |
| Beams fired (a match) | 1,445 (24.1) | 1,178 (19.6) | 563 (9.4); 245 by the human, 4 a match | 537 (8.9); 261 by the human, 4.4 a match |
| Range at the fire: median | 58 | 58 | 58 (human's: 156) | 58 (human's: 216) |
| Fired over 2,000 units | 25.0% | 19.5% | 2.7% (human's 4.1%) | 4.8% (human's 8.8%) |
| Fired over 5,000 units | 15.4% | 11.4% | 1.2% | 1.9% |
| Height difference over 1,000 | 5.8% | 3.9% | 0.9% | 1.7% |
| **Fired wide of him** | **50.2%** | **51.1%** | 35.0% (the computer's 51%, the human's 14%) | 34.5% (the computer's 57%, the human's 11%) |
| Of those aimed at him: hit | 51.9% | 31.1% | 49.5% | 44.0% |
| ... answered (dodge, deflect, guard, clash, struggle) | 44.4% | 66.7% | 49.7% | 56.0% |
| ... escape gamble | 3.8% | 2.3% | 0.8% | 0% |
| Fire to outcome, ticks (hits) | 43, up to 62 | 43, up to 62 | 43, up to 62 | 43, up to 62 |

What it says, plainly:
- **Most beams are fired at contact** (median 58 units, the gap of a brawl at contact): half of the computer's beams are fired **wide of him** in every AI arm (the `beam_wide` cue: the thrown sector was outside the assist cone of `beam_aim.gd`); why the computer's aim is off the line half the time is not read here. The scripted human, aiming at him, goes wide 11 to 14%.
- **The long shots are a real share, not a rarity:** 11 to 15% of AI beams are fired from over 5,000 units, and 12 to 14% of the hits come from over 5,000 units (51 of 373 hits on easy, 21 of 179 on medium) with 22 and 7 hits across a height difference over 1,000. Orb's notes (a hit from 6,568 units and 2,850 up) are the tail of this.
- **Time from fire to hit is set by range only:** 43 ticks at contact, 46 at 500 to 2,000, 62 beyond 2,000 (the ceiling in `beamplay.gd frontTicks`); the window the player has to answer is 41, 44 and 60 ticks.
- **What answers a beam:** clash (a late answer that started a struggle) and guard carry most of it. **A dodge tap answers 1 to 3%** (21, 4, 20 and 17 beams of about 580 to 700 in an arm); deflect (the perfect block) 4 to 8%. No hit landed on a target that was launched, dropped or down (0 in every arm).
- **The scripted human's 78 RB holds a match produce about 4 beams** (5%): the rest were refused or lost (target not free for 0.3 s, a blow taken, the 'late' rule). That is this bot's rate, not a player's, and says only that the hold is not a sure thing.
- Medium answers more than easy (66.7% against 44.4%) and is hit far less (31.1% against 51.9%).

## 2. Replay of 1931a0f8's 1714 file with Controls' b-no-beam park (`park-replay-b-no-beam-1714.txt`)

The park's patches do not apply to the 1931a0f8 tree (the context differs), so its three hunks (`switches.bNoBeam`, `SimInputData.b_no_beam()`, `DirBrawl.isB`'s early return) were put in **by hand into a scratch copy of the build-1 tree**, and the replay runs the file's own inputs.

- **The intent's mode and the fighter's `act.mode` at tick 3326 are both 0 (physical):** it was not energy mode. `beam_trace` now prints both.
- **The exchange at 3326 is a full signature exchange** (`kind sig`, template `signature`, slot 0 the shooter) with the pair **2.83 body heights apart** (the close band is 3), no stance held (mask 0).
- **CORRECTION (Controls, `docs/qa/runs/1931a0f8/controls-b-3326-stale-queued-signature.md`, 2026-11-08): the next bullet is wrong about the park.** The beam at 3326 was a stale signature queued at tick 3297, three ticks before my mid-match flip, while the switch was still off; flipping before tick 3297 (`--flip=3290`) makes 3326 a heavy and no beam. In play the switch is on for the whole match, so the park does close B alone. My `--flip` test measured the queue, not the rule. Left below as first written.
- **The park does not close tick 3326.** With the switch off until tick 3300 and on from there (`--flip=3300`, so the match is the same up to it), slot 0's B at tick 3326 still starts the beam (`beam_charge: start`). **The park does close tick 8096** (B with the dodge held, mask 8): with the switch on from tick 8070 (`--flip=8070`) no beam starts there.
- With the switch on from the start, the replay diverges (a different match) and slot 0 starts three beams, none at a B press (the intents at those ticks carry no B).
- **So the leak at 3326 is not `isB`'s with a stance held.** The press became a signature exchange in the close band with nothing held; why `isB` (or the path before it) did not make it the heavy there is Controls' and Encounter's to find. QA has not found the cause.

## 3. The charge-outcome read on Orb's 1726 file (`../1931a0f8/charge-trace-orb-play-20261108-1726.txt`)

Build-1 tree, slot 0, 34 charges (17 heavy, 17 stick hold), `qa/godot/charge_trace.gd` (new):

| Heavy charges (B or Y held into a charge): 17 | Count |
| :--- | ---: |
| Thrown after the player let go | 13 (9 held 42 to 52 ticks, one 36, three quick releases at 1, 13 and 14; the flash comes at 12 to 16) |
| Stopped by a blow of the foe's | 1 |
| Lost to a stagger or the brawl's end | 2 |
| A miss (the blow was thrown and missed) | 1 |

**No heavy charge was ended by the sim at its maximum hold.** In 9 of the 17 the player took 2 to 5 hits while charging and the charge went on (it is armoured), so a hit does not interrupt it; **3 of 17 were taken from the player** (one stopped by a blow, two lost to a stagger or the brawl's end).

| Right-stick holds: 17 | Count |
| :--- | ---: |
| Let go before stage 1 (6 to 10 ticks): no beam came of them | 5 |
| Let go as a strike (toward, down) | 3 |
| The blow landed | 2 |
| Went on as a beam (stages 1, 2, 2, 3, 5, 5) | 6 |
| Unclosed (a stick start with no end cue for 5,411 ticks) | 1 |

Of the 6 beams from holds, five had no hit taken during the hold. **Nothing in these 34 charges was ended by the game for a reason the player did not cause, except the 3 heavy charges above.** I found no arbitrary interruption in this file; what the player felt may be the 5 holds that never reached stage 1 (the stage needs about 12 ticks) and the 'late' and 'soon' refusals, which the counts do not tie to a charge.

## Dropped, waiting, and items from the brief

- **Dropped by the EP:** the close-fight control table. The arms recorded it (`rec.ctl`) and nothing is reported.
- **Wait for parks:** the side-from-blow arms (tree prepared in the scratchpad: main d985eb15 plus the park, switch on after the page flip; the control arm needs the switch off) and the 40-a-cell re-read of Orb's scheme and the masher at paceMatch and the hit-stop budget.
- **Game Design's question:** the 'pressing toward' dodge-follow switch is not in build 2 (it does not exist yet); sent separately.

## Tools (all in `qa/godot/`, uncommitted)

`records.gd` (beamGeo, ctl, ctlMin, launchGeo; `QA_HUMAN=rbeam`), `qa_planet.gd` (`power`, `travel`, `level`), `beam-base.js`, `control-table.js` (not used in this report), `side-from-blow.js` (waits for its arms), `charge_trace.gd`, and `beam_trace.gd` (now prints the intent's mode, the fighter's `act.mode`, the exchange behind each beam charge, and takes `--flip=<tick>`).
