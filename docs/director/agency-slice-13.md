# Agency, slice 13: timing paid on every press, flow paid in set-ups and contests

Owner: Encounter Systems Director. Date: 2026-10-03. Status: in the tree on HEAD `60ecfb6`, waiting for the EP's commit. Rules: `docs/design/agency-pass.md` §22; Combat's `docs/combat/struggle-scoring.md` (the EP's ruling); QA's `docs/qa/baseline-df05b9f.md`.

Everything here runs only in the `dynamic` profile.

## What changed

| # | Rule | Number | Where |
| ---: | :--- | :--- | :--- |
| 1 | **A timed blur press lands clean at once.** A link's strike from a press on the beat does ×1.0 of a light; off the beat ×0.8. It no longer waits for the lock | `alchemy.json` `blur.timedMul` 1.0; `launch.json` `blur.strikeMul` 0.8 | `melee.gd` `strike` |
| 2 | **Flow adds damage.** Every melee strike of his does 4% more for each point of flow, 20% at flow 5. Shots are not included | `flow.dmgPer` 0.04 | `melee.gd` `strike` |
| 3 | **The blur's full ender comes from flow.** It is the full one (the full distance and a full set-up) when his flow is 3 or more as it plays, else the weak one. The four-press lock stays as the cue for the look (`blur_locked`) and changes no number | `blur.fullEnderFlow` 3 | `melee.gd` `launchBeat`; `blur.gd` |
| 4 | **A lone heavy at flow 5 is a showcase.** The cue `showcase_ender` now also fires for a lone heavy launched by the stick at flow 5. **The extra impact wear is not in** (`flow.launchWear`): a launch has no wear multiplier | (none) | `melee.gd` `launchBeat` |
| 5 | **Flow counts in contests.** Each point of the flow he held as the exchange, or his finisher, started adds 2 to his beam clash score and takes 2 points off the rival's chance to survive his finisher, up to 10 | `flow.contest` 2, `flow.contestMax` 10 | `exchange.gd` `flowEdge`, `_start`, `startFinisher`, `_opContest`, `_opContestBranch`; `beam.gd` `_clashScore`; `alchemy.gd` `markFlow` |
| 6 | **The AI's timed share** is 0.15, 0.45, 0.8 by level (was 0.4, 0.65, 0.85). The key is still `timedPress` | `ai.json` | data only |
| 7 | **A barrage with a tapped heavy is weak.** A barrage that includes a charged shot fired with no charge gets the weak ender: 0.6 of the distance and half a set-up | `interrupts.json` `blast.barrage.tappedHeavyWeak` true | `blast.gd` `_barrage` |
| 8 | **The finisher's struggle.** The press score is floored at `scoring.floor`, the score of a player who does not press, before the tilts come off. A stray press now costs 0.15 and the floor is 0.08 | `finishers.json` `contest.struggle.scoring.perStray` −0.15, `floor` 0.08 (Combat's file, those two values by the EP's grant) | `exchange.gd` `_opContestBranch` |

**Readings the EP confirmed:** "his clash score" is the beam clash score (the melee heavy clash is Combat's selector and is not touched); flow in a contest is the flow held when the exchange or the finisher started, because a finisher's contest comes after the 90-tick lapse.

**State:** one more integer a fighter (`DirAlchemy.FLOW_EX`). **No new event or cue.** The feed's `BLUR ENDER` names the flow when it is the full one; `BARRAGE ENDER` says when a tapped heavy made it weak. **No core lines.**

## Results

**The timed masher against the plain masher** (40 matches a row). QA's script and a script on the beat are given apart, so they are not confused:

| Row | As QA's script reads it | At acc=100, win=1 | Band |
| :--- | ---: | ---: | :--- |
| F6 (no stick) | 21 of 40 (52.5%) | 26 of 40 (65.0%) | 62 to 82% |
| T6 | 23 of 40 (57.5%) | 26 of 40 (65.0%) | 62 to 82% |

Before this slice QA read 50.0% and 47.5% (`baseline-df05b9f.md`). **As QA's script reads them, F6 and T6 are still outside the band.** Traced per player, before the struggle ruling was in:
- QA's timed masher is on the director's beat on 56% of its blur presses, not 80%. About a fifth are its deliberate misses; another fifth land 6 ticks or more from any blow. The plain masher is on the beat on 20% by luck. So the timed script takes the full ender on 23% of its enders against the plain masher's 14 to 17%. At acc=100, win=1 it is on the beat on 74% and takes the full ender on 50%.
- The timed script does not press in the finisher's struggle. Before rule 8 its chance to survive a finisher averaged 5 to 7% against the plain masher's 21 to 27%.

**Other script rows** (QA's scripts on the final build):

| Row | Result | Band |
| :--- | ---: | :--- |
| Bolt-only against the medium AI | 33 of 100 | 20 to 40% |
| Mixed blaster (L L L and a tapped H, about every 14 ticks) against the medium AI | 61 of 100 | 30 to 50% |
| Slow mix (L L and a tapped H, every 24 ticks) against the medium AI | 29 of 100 | reference |
| T8: a timed player against the medium AI | 40 of 40 | 70 to 90% |

Core and flow rows on the first build of the slice, before rule 8 (40 a row): F1 70.0%, F2 67.5%, F3 57.5%, F4 50.0%, F5 42.5%; T1 72.5%, T2 55.0%, T3 67.5%, T4 40.0%, T5 45.0%, T7 30.0%, T10 60.0%, T9 45.0%.

**QA's harness** (`node qa/run-godot.js`, four arms, 100 matches an arm; before is slice 12's build):

| Row | Before | After | Band |
| :--- | ---: | ---: | :--- |
| The masher against the easy / medium / hard AI | 100 / 40 / 1 of 100 | 100 / 38 / 1 of 100 | at least 60 / 35 to 50 / at most 15 |
| Finisher survival rate | 28.6% | 31.5% | 25 to 40% |
| Match length, median | 484.2 s | 493.1 s | 360 to 480 s |
| Match length, 90th percentile | 602.7 s | 593.8 s | at most 600 s |
| KAI over both slots | 47.0% | 49.0% (47.0% from P1, 51.0% from P2) | 45 to 55% |
| First brink, median | 397.2 s | 405.1 s | 270 to 420 s |
| Brink to KO, median | 75.2 s | 69.7 s | 45 to 90 s |
| Lights-only mirror, brink to KO | 49.6 s | 34.7 s | 45 to 55 s |
| Blasts' share of damage | 11.6% | 11.6% | 10 to 25% |
| Front-row structures lost | 52.7% | 54.3% | 25 to 50% |
| Exchanges that end in a knock-back | 32.6% | 32.4% | 25 to 35% |
| Launches of the exchanges that separate | 38.5% | 38.7% | 25 to 40% |
| Perfect blocks per 100 melee exchanges | 16.3 | 16.8 | 5 to 15 |
| Bolt-only against the medium AI (QA's 40-match row) | 11 of 40 | 10 of 40 | 20 to 40% |
| Arms' share of limb breaks (about 37 breaks a run) | 70.3% | 74.1% | 35 to 65% |

96 bands pass, 19 fail, 21 pending (91, 17 and 21 before; QA has added rows since). **Outside their bands:** the match median by 13 s (it did not come down as section 22 expected), front-row structures by 4 points, perfect blocks by 1.8, the arms' share of limb breaks (a small sample), and **the lights-only mirror's brink to KO, new: 34.7 s against 45 to 55.** Two mashers now finish each other sooner: a masher's struggle no longer earns survival (rule 8), and a blind masher still takes the full ender on about one ender in seven.

**Finisher survival by the winner's flow** (60 AI matches on the final build): 77 contests at flow 0, mean chance 25.1%, 23 survived; 13 at flow 1, mean chance 33.6%, 7 survived; none at flow 2 or more. So a flow-5 attacker was not seen between AIs. By the rule he takes 10 points off: about 15% left against an average AI victim, 20% in a contest with no struggle, and 0% against a victim on the struggle's floor (8% before the flow).

**Gates** on a clean copy of HEAD with exactly the tree's changes (no sim or data file differs between that copy's base and `60ecfb6`; parity again in the tree): goldens regenerated (9 matches, 170,384 ticks; 174,493 before); parity, the loader check at 200 matches, `npm test` 5 of 5, determinism, seam, the animation check, the cue check, Controls' input tests and its mash probe pass. The validator shows 6 errors, all this slice's new keys, until Tools' slice 13 schema script is run.

## Notes

- **T8 is outside its band, and no number of this slice moves it.** The medium AI's `timedPress` at 0.45, 0.55 and 0.65 gives 40 of 40 each time (the masher 42, 40 and 44 of 100; AI mean length 494, 468 and 473 s over 30 matches). `flow.contest` 0 gives 40 of 40 and `flow.dmgPer` 0.02 gives 38 of 40. In 12 traced matches the timed script starts 15 finishers and the medium AI none, and the AI holds no flow for 88% of the match. The ruled 0.45 is kept. It is a question of how hard the medium AI should be against a well-timed player (its `guardRepeat` and punish rates, which also move the masher's band).
- **The mixed blaster is over its band with rule 7 on.** With L L L H every four shots hold a tapped heavy, so every barrage of this mix is now the weak one, and it still wins 61 of 100. The ender is not what carries it. A tapped charged shot does 49.5 (0.6 of 82.5) for one press, against 13 for a bolt: `interrupts.json` `blast.heavy.tapShare` is the next number to look at.
- **`flow.launchWear` needs a patch.** Impact wear is dealt in six places (World: `contact.gd` 730 and 952, `slide.gd` 153, 166 and 173, `brunt.gd` 438; Simulation: `fighter.gd` 60). Simulation adds a fighter field `launchWear` (1.0, in the state hash, reset when the flight ends); those six calls multiply by it; `DirLaunch.doLaunch` then sets it from the flow.

## Data keys for Tools

| File | Keys |
| :--- | :--- |
| `data/director/alchemy.json` | `flow.dmgPer`, `flow.contest`, `flow.contestMax` (numbers); `blur.timedMul` (number), `blur.fullEnderFlow` (integer) |
| `data/director/interrupts.json` | `blast.barrage.tappedHeavyWeak` (boolean) |
| `data/director/ai.json` | values only: `timedPress` 0.15, 0.45, 0.8 |
| `data/combat/finishers.json` | values only: `contest.struggle.scoring.perStray`, `floor` |

## Left for later

- `flow.launchWear` (the patch above) and Combat's showcase rows.
- The power style's upgrade (a release on the flash).
- A5 the running mix, A6 pulse clashes, A7 Blow for Blow.
