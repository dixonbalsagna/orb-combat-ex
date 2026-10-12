# The nine cells: a pool for every cell of the brawl

Owner: Combat and Choreography. Date: 2026-10-12. Status: **parked, measured in scratch.** It lands in the EP's window with Encounter's hook and Tools' schema, with one regeneration of the goldens. Brief: the EP's of 2026-10-12, step 2.

Today the live brawl picks by strength alone from four old pools, so B plays the old heavies, a bolt is an ordinary light, and the heavy tier and the energy pieces Animation has posed are never thrown. `recipes.brawl.json` names a pool for every cell, and `../brawl-hook.md` is the change that reads it.

**Since the report (2026-10-12):** committed as `c6f58415`. Animation's packs are on main (`04dd6729`, `115ee361`) with the ids and rows this note names, and with its part of section 6 done: a blow's strength picks its style, every bolt and blast is thrown from either arm, and the charged medium has its hold. Legal cleared the blast after a bolt (`321c046d`). The generator is version 14 with 80 self-test cases; `recipes.brawl.json` has not changed since the commit. The window waits on Encounter's hook.

**Built on Animation's packs as they stand in the working tree** on 2026-10-12 at 10:04, not yet committed: its ids for the rival's flick and sweep, and rows 09 and 10 of each tier, which it marks provisional. The generator reads the tree. If a pack moves again, `--check` goes red and the chain of section 8 brings the data level in minutes.

## 1. What is parked

`recipes.brawl.json` is the next `data/combat/recipes.json`. It is the live file plus additions. The live pools and every live `pieces` row are unchanged inside it (the builder checks both).

| Game Design's cell (`docs/design/brawl-second-pass.md` §15) | `brawl` key | Pool | Rival | Protagonist | What it holds |
| :--- | :--- | :--- | ---: | ---: | :--- |
| X tapped | `light` | `combo.link` | live | live | Unchanged |
| X tapped, stick toward | `lightToward` | `blur.toward` | live | live | Unchanged |
| X mashed | `flurry` | `brawl.flurry` | 9 | 10 | As committed |
| X held: the burst | `burstFast`, `burstMid`, `burstSlow` | `burst.fast`, `burst.mid`, `burst.slow` | 8, 13, 27 | 8, 12, 24 | Lights by the gap before each blow: a kick never fits a fast gap |
| X held: the pace it settles to | `burstFloor` | `burst.slow` | 27 | 24 | Every light |
| Y tapped or mashed | `medium` | `brawl.medium` | 10 | 10 | The mediums that read on a 12-tick wind-up |
| Y held | `mediumHeld` | `brawl.medium.held` | 14 | 14 | Every medium, the leaps, spins and two-arm blows included (Encounter's pass 2) |
| Y out of a perfect block | `reversal` | `brawl.reversal` | 5 | 4 | A medium on a line or a rise, by hand, elbow, knee or head |
| B tapped or mashed | `heavy` | `brawl.heavy` | 10 | 10 | The heavy tier: Animation's `su_` strikes |
| B held | `heavyHeld` | `brawl.heavy` | 10 | 10 | The same ten |
| B in an opening | `launcher` | `brawl.launcher` | 8 | 7 | Heavies of the tier that read on half the wind-up, by where each sends |
| RB + X in reach | `bolt` | `reach.bolt` | 4 | 4 | The point-blank bolts |
| RB + Y in reach | `blast` | `reach.blast` | 2 | 2 | The blasts |

- `skill`, `juggle` and `lift` are as committed. Nothing reads them yet.
- **Fallback pools:** `brawl.heavy.lower` (5 a fighter: the old stand-ins) and `brawl.launcher.lower` (9 a fighter: posed mediums, by send).
- **Blocks:** `beat`, `burst`, `fallback` (`steps`, `lower`, `onTheTier`), `launcher` (`aim`, `noStick`, `bySend`, `bySendLower`) and `reach` (`rule`, `run`, `pieces`, `runs`, `after`).
- **`pieces`:** 30 new rows for Animation's 32 new key sets, one row an id. `strike.blast_chest` and `strike.blast_gut` are one row each for both fighters: the place and the path are the same. Every heavy has `sends`.
- **The mashed bolts:** `reach.runs` holds two runs of twenty bolts a fighter, each with the arm that throws it. Each run is a loop that keeps Legal's e09 however long it is played. The generator orders and checks them.
- **The launcher by send:** two pieces a send for both fighters, except that the Protagonist has one that sends down (`strike.su_drive`). With the stick down, his launcher falls back to a medium about one time in nine (`fallback.onTheTier`).

**The generated movesets** (128 rows a fighter) now read Animation's four new packs:

| | Posed | Derived | Waiting |
| :--- | ---: | ---: | ---: |
| The rival | 90 | 23 | 15 |
| The Protagonist | 85 | 28 | 15 |

B is 10 posed a fighter, with no row waiting. Energy in reach is 4 bolts and 2 blasts a fighter, all posed. The generator was version 13 at the report and is 14 now: `--check` passes on all three lines, and `--self-test` passes its 80 cases.

## 2. Four calls of mine

- **The ids are Animation's.** The rival's flick and sweep are `strike.bolt_flick_gut` and `strike.bolt_sweep_chest`, and the Protagonist's keep `strike.bolt_flick` and `strike.bolt_sweep`. I had expected other names. The recipes and `identity.json` carry Animation's, so no id waits on anyone.
- **The reversal has its own pool.** It comes straight out of a guard, with no room to wind up. So it is a medium on a line or a rise, and never a dropping kick or a turning blow. `brawl.medium` holds both kinds.
- **The double hit has no key.** It is one staged picture of two fighters with its own poses. A pool would only pick a look that the staging then overrides.
- **The wrench has no pool.** It is a held B on a battered limb (slice C2b), found as the launcher's send is: a heavy in `brawl.heavy` whose row lands on the limb the stick asks for. Each fighter now has one for an arm and one for the legs. Nothing reads a wrench in this window, so the file carries no key for it.

## 3. Measured

**How.** A scratch copy of HEAD, with the parked recipes as the live file, Animation's four packs as they stand in the working tree, and a stand-in for part 1 of the hook (`../brawl-hook.md`): the pool by the cell, at the three callers. Four AI matches, seeds 101 to 104, level medium, 300 seconds each at most: 1,191.9 match seconds and 7,298 brawl blows. No blow was left without a piece.

| Cell | Rival: blows | From its pool | Protagonist: blows | From its pool |
| :--- | ---: | :--- | ---: | :--- |
| Light, mashed | 2,544 | all | 2,361 | all |
| Light, tapped | 477 | all | 475 | all |
| Bolt | 278 | all; each of the 4 thrown | 327 | all; each of the 4 thrown |
| Burst | 272 | all | 308 | all |
| Reversal | 42 | all; each of the 5 thrown | 41 | all; each of the 4 thrown |
| Heavy | 33 | all from the tier | 34 | all from the tier; each of the 10 thrown |
| Medium | 33 | all; each of the 10 thrown | 30 | all; each of the 10 thrown |
| Light, as a riposte | 11 | all | 15 | all |
| Launcher | 7 | all from the tier; 5 of the 8 thrown | 9 | all from the tier; 5 of the 7 thrown |
| Blast | 0 | | 1 | `blast_chest` |

The rival threw all ten of his tier, as a heavy or as a launcher.

**The same seeds on today's pools** gave the same 7,298 blows and the same match seconds. The pick changes what a blow looks like, and nothing else.

**The string rules,** counted on the `pieces` table over each fighter's blows running:

| Rule | With the hook | On today's pools |
| :--- | ---: | ---: |
| Two running to the gut (Legal's s02) | 2 | 0 |
| Three running to one place (s02) | 106 | 238 |
| A spin after a spin (s04) | 0 | 0 |
| One of his last two pieces again | 0 | 0 |
| A rise after a rise, at any height | 52 | 0 |

- **The gut rule does not hold yet.** Both breaks came from one moment: the picker drew a gut blow six times running from the rival's four bolts, gave up, and cleared its own flag, so the next blow could go to the gut too (`sim/director/brawl.gd:924`). Two of his four bolts go to the gut. It is rare, and the fix is the hook's (`../brawl-hook.md` part 5).
- **The rises.** Legal's s05 bans a rise after a rise only while he is airborne. The probe did not read his height, so 52 is a ceiling. The new pools hold more rising blows than the old ones.
- **One place three times** happens less than half as often as today, and it still happens: the picker doesn't keep that rule.

**A blast straight after a thrust bolt of the same hand: cleared by Legal** (`321c046d`). Each fighter's two blasts are a thrust from the hand one of his bolts uses, so RB + X then RB + Y repeated a hand and release one time in four, and no pick could avoid it. Legal's e06 now says the repeat rule counts the delivery too: a blast is braced on a held pose for 12 ticks, lands once and ends the brawl, so it is its own piece. The generator reads it that way from version 14. Two bolts of one hand and release running stay refused.

**Joints.** Animation's `joint_scan.gd --strict` on the scratch copy, the final file and the same seeds exits 0.
- 890 authored poses (8,860 frames): none past a limit. `rival7` and `protag10` with their ten rows each: 300 frames a pack. `rival8` and `protag11`: 180 each.
- 116 sequences: none.
- 24,000 fighter-frames of the four matches, with the tier and the energy pieces thrown: none reaches the screen past a limit.
- The solve's last pass pulls three of the Protagonist's bolts back by more than 30 degrees on some frames, all at the left upper arm's twist: `pk.bolt_flat` (6 frames), `pk.bolt_sweep` (5) and `pk.bolt_thrust` (5). They pass, and Animation may want to look.

**Not measured.**
- The launcher's pick by send, the mashed bolts from their runs and a charge's second pick: the stand-in does none of them (parts 2 and 4 of the hook, and the end of part 1).
- Blasts: the AI threw one.
- A human at the pad.

## 4. The apply list: one window, one regeneration

1. **Animation's working tree is committed:** the rename (`rival8`) and rows 09 and 10 of each tier (`rival7`, `protag10`). The recipes name those ids.
2. **`recipes.brawl.json` becomes `data/combat/recipes.json`,** with `_target` and `_changes` dropped: by Tools' script, or by Combat on the EP's word.
3. **Tools' schema** takes the additions of section 5.
4. **Encounter's hook** (`../brawl-hook.md`).
5. **The goldens are regenerated once.** The frozen parity copy holds templates and finishers only and is not touched.

- Steps 2 and 4 belong together. With the file and no hook, the fight plays as today and only the data hash moves. With the hook and no file, it falls back to today's four pools.
- **Checks in the window:** Tools' validator on the new file; `python -B docs/combat/pending/movegen/gen_moveset.py --check --recipes data/combat/recipes.json`, which tests every pool the blocks name against Legal's rows; and Animation's joint scan, strict.

## 5. For Tools: what `apply-brawl-recipes.cjs` needs

It knows `beat`, `burst`, `fallback` with `heavyOnStandIns`, a `path` on every piece, and ten `brawl` kinds. To take this file:

1. **`brawl` keys** (its `KINDS`): add `launcher`, `reversal`, `bolt`, `blast`, `burstFast`, `burstMid`, `burstSlow` and `burstFloor`. `fallback.lower` takes its keys from the same list, so `launcher` and `reversal` come with it.
2. **`fallback.onTheTier`** replaces `heavyOnStandIns`, which is gone, and its fixture cases with it. For each fighter: `heavies` (a count), then `heavy`, `mashedB` and `launcher` (a step to how often it is reached), and `bySend` (a send to the same).
3. **A new block, `launcher`:**
   - `aim`: `up`, `down`, `toward` and `away`, each to a send (`up`, `down`, `across`, `turned`).
   - `noStick`: `planner`.
   - `bySend` and `bySendLower`: a fighter to a send to a list of strike ids.
   - Cross-checks: a fighter is a key of `pools`; each id is a row of `pieces` whose `sends` has that send; a `bySend` id is in his `brawl.launcher`, a `bySendLower` id in his `brawl.launcher.lower`.
4. **A new block, `reach`:**
   - `rule`: `id`, `same` (a list of `hand` and `release`) and `max`.
   - `run`: `samePlacePathArm`, `pathsIn` (two counts), `freeArm` (`atMostOneIn`, `atLeastOneIn`, `gapsDiffer`), `notPeriodic` (a list of counts) and `proof`.
   - `pieces`: a fighter to `bolt` and `blast`, each a list of `id`, `set`, `hand`, `release`, `target` and `path`.
   - `runs`: a fighter to a list of `blows` (strike ids) and `arms` (`lead` or `free`).
   - `after`: a fighter to, for each run, the runs that may follow it.
   - Cross-checks: each id is a row of `pieces` with that `target` and `path`, and in his `reach.bolt` or `reach.blast`; a run's blows are of his `reach.bolt`; `arms` is as long as `blows`; `after` names runs that exist.
5. **Pools:** no change to the schema. `reach.bolt`, `brawl.heavy.lower` and the rest fit the pattern for a pool's name, and none is empty. The fixture becomes the new file.

`apply-movegen.cjs` was written for the generator's version 5. The movesets stay parked, so it is not in this window.

## 6. For Animation

1. **Rows 09 and 10 of each tier are in the recipes** as its packs have them today, provisional or not: `strike.su_edge_legs` and `strike.su_plate_arm` for the rival, `strike.su_knee_legs` and `strike.su_elbow_jaw` for the Protagonist. If a shape, a place or an id changes before the commit, Combat regenerates.
2. **Each bolt mirrored for the free arm.** `reach.runs` gives the free arm four or five bolts in twenty, on no regular count (Legal's e09).
3. **The charged medium's hold pose and its full flash,** for Encounter's pass 2.
4. **The style map.** The renderer maps a blow's strength to its style only when the beat says `flurry` (`render/anim/anim_fighter.gd:2167`). Once the hook stops sending an explicit style, a tapped medium or heavy would miss the map.
5. **Pieces the solve corrects hard** (section 3).

## 7. What stays parked

- **The generated movesets** and `lock.json`: parked. The recipes' new pools are built from them.
- **The launch pair's finisher rows** (`launch-pair.json`: The Verdict, Everything): parked.
- **`templates.brawl.json`:** no data in it survives. The lights-against-a-heavy pair was withdrawn by the armour rule, and the knock-back numbers are the director's now. What survives is the look of its six trade beats and its endings without a launch, as a brief for when Game Design sets those.
- **`templates.agency.json`:** the bands and the lunge are live. The far taunt's staging survives for the taunt as a gamble. The traded-blows set piece and the far charges wait on Game Design.
- **Retired:** `retired/README.md` lists the four files moved there, and six overtaken files left in place because other directors' scripts name their paths.

## 8. To run it again

The scripts are in Combat's session scratch (`dyn/`), not in the tree. In order: `merge_legal2.py`, `three_strengths_data.py`, `c2t_data.py`, `nine_cells_data.py`, then `gen_moveset.py`, then `nine_pools.py`. `nine_scratch_setup.py` prepares the scratch copy (`--no-hook` for today's pools) and writes the probe, `sim/director/tools/piece_probe.gd`. One Godot job at a time, always `--headless`.
