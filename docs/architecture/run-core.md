# The run: its state, the carry, the stage header and tier 5 (the core's side, paper)

Owner: Simulation and Engine. 2026-10-16. The core's answer to Game Design's `docs/design/run-mode.md` (7022b7df, with Legal's RL-145 and section 10's answers, 0dfe3f91), section 7 and the sim questions in sections 1.3, 2, 3.1 and 10. It builds on `planet-slice-core.md` (the world as a function of the setup, the wear list in a place's frame). **Paper only: nothing in `sim/` or `data/` changed.** Every number below is Game Design's or World's; the core adds none.

## 1. The answers in short

| Question | Answer |
| :--- | :--- |
| **What a stage header holds** | **An ordinary replay that plays on its own,** with two additions: everything the match reads at tick 0 is in its `setup` (the planet keys, the wear for the places its slice crosses, and a `stage` block: the carry the match needs, already worked out), and a `run` block the match never reads: the run seed, the chapter and the choice, the run state at the start (embedded) and its hash, the hash of the run state the stage ended in, and the chain's link |
| **Stage seeds, chained** | **The seed is `H(run, "stage", chapter, choice)`, as Game Design wrote, and it does not depend on what happened.** The chain is a separate hash through the headers (`link`), which proves the order and the hand-over and feeds no draw. So two players racing one seed with the same choices meet the same draws in every stage, whatever they did in the last one |
| **The ledger as sim state** | **Two halves.** During a stage, a **tally** in the match's state (`S.tally`: who killed whom where, who brought down what, the hero's time near buildings, style counts), written at the core's existing choke points and hashed only in a run. Between stages, the **ledger** in the run state: whole numbers, closed from the tally by a pure function at the stage's end. **The bands (none, some, many; low, mid, high) are not stored:** the beat picker works them out from the counts, so a new band is Narrative's data and never a re-baseline |
| **Tier 5's state** | **The match's ceiling comes from the setup** (`stage.ceiling`: the run's tier plus one, or 5 for the boss), not from the fighters' ladder. The fifth step is not a power threshold: the tremor makes it ready. Its state is a small `S.cata` block (the phase, the tremor's tick, the catastrophe events' counts and timers, the hazard wear, the ash, the magma), hashed only when the ceiling is 5. **Every table indexed by tier has four entries today** (at least 13 in the data and 3 in code, listed in section 6): their fifth entries live in one file read only by a tier-5 setup |
| **The golden** | **Nothing moves.** Everything here is behind `setup.stage`, which no versus match has. The run adds keys: a short scripted run on a fixed seed, its final link and run-state hash pinned |

## 2. The run state

**What it is.** Everything that passes from one stage to the next (`run-mode.md` section 7), as one JSON document of **whole numbers and short strings only**: exact in JSON, hashed by the core's canonical hasher (`FighterData._canon`, the one the fighters' data already use), the same in any language. A share is kept in thousandths, a fill in thousandths of its meter. The sim never reads it: the host builds each stage's setup from it (section 3).

| Part | Fields |
| :--- | :--- |
| The run | `format` "meridian-run-state", `v` 1; `run` (the run seed, 64 bits as 16 hex digits: a JSON number is exact only below 2^53); `mode` (story, standard, hard), `pressure`, `assist`; `chapter` (the next stage's) |
| The planet | `planet` (its seed, `H(run, "planet")`, and the hash of its places list) |
| Each place (by the places list's id) | `status` (fresh, damaged, fallen); `wear` (the place-frame records of `planet-slice-core.md` section 5); `dead` (by cause: player, opponent, other); `fled`; `lost` (buildings brought down, by cause); `changed` (the chapter that last changed it) |
| The player's carry | `fighter`; `tier`; `fills` (Witness and Trial); `branches` (the branch of each form taken, in order); `wounds` (a stage a region, 0 to 3); `cards` |
| The run's counters | `dread` (thousandths); `chances`; `sky` (the ash, thousandths); the score's parts |
| The ledger's stages | One record a stage: the offer's kind, the opponent, the result, how it ended, the finisher, its length in ticks |
| The chain | `link` (section 4) |

- **Size:** a few hundred numbers plus the wear lists, which are a few KB a damaged place (`planet-slice-core.md`): about 5 to 20 KB for a full run. It is embedded in every stage header.
- **Rounding at the hand-over** (a fill or Dread to thousandths) is deliberate: the next stage starts from the integers, and both directions are pure, so a run replays to the bit.

**The carry: from a stage's end to the next stage's start.** A pure function `carry(state, the stage's end, the choice)` that returns the next run state. The stage's end is read from the match's final state and its tally (section 5). It is Game Design's table 1.3, as rules:

| What | Rule (Game Design's) |
| :--- | :--- |
| Places | The wear the match left on each place is turned into place-frame records and merged into the place's list (`planet-slice-core.md` section 5, with its cap). The dead are added by cause. Those who fled a standing place come home; those who fled a fallen place are gone. The status is worked out again (damaged at 5% of buildings or people lost, fallen under 40% standing or present) |
| Open country | A crater outside every place is kept as a point on the sphere (section 10.2), in whole numbers: its unit vector times 2^30, rounded (about 0.00002 units at the planet's radius), with its radius, depth and rim. A later slice lays it on the columns whose point is within its reach (a dot product against `SimDetMath.cos(reach / R)`) |
| People | The people present at the next stage's start: the slice's people at the run's start, less the dead, less those who fled a fallen place (section 10.2) |
| The player | Tier: one step a stage, to the stage's ceiling (section 1.3). Wounds: broken stays broken (a rest heals it to battered), every other region heals one stage. Fills and branches as the form rules leave them. Power, ki, the hero's cost meter, the mood, the cooldowns and the timers are not carried: they reset at the start |
| A lost stage | A chance is spent. The place falls: its people flee for good. Dread + 100 thousandths. No chance left: the run ends |
| Dread | The villains' kills over the planet's people, over 0.4, plus 0.1 a place taken, at most 1: worked out again from the ledger each time, never accumulated as a float |
| The sky | The match's ash at its end |

## 3. The stage header

A stage is a match, and its file is a replay (format v4) that **plays on its own, from its header**, as any replay does. What a run adds:

**In `setup`** (read by `newMatch`; everything the match needs at tick 0):

| Key | What |
| :--- | :--- |
| `planet`, `touch`, `pick` | The slice (`planet-slice-core.md` section 2) |
| `wear` | The wear lists of the places the slice crosses, and the open-country craters within reach of its line, copied from the run state |
| `stage` | The carry the match reads, already worked out from the run state: `tier` and `ceiling` for each fighter (the player at the run's tier, the opponent at it or one above at a Proving ground), the power floor, the player's wounds by region, his fills, `meter0` (the villain's feeding meter at the start: 100 times Dread, for menace now and Pride when it lands), the AI's level, `pop0` (the slice's people at the run's start, for the meters' 425 / `pop0`), `present` (the people present at this stage's start, for the budget's and the ceilings' shares), `peopleLeft` (the planet's ceiling: section 7), the offer's kind, and `sky` |

The match reads only `setup`. **It never parses the run state.** So the rules of a stage's start are one pure function, `stageSetup(state, offer)`, which the host calls and the run's replay checks.

**In a `run` block** (the match never reads it):

| Key | What |
| :--- | :--- |
| `seed` | The run seed (hex) |
| `chapter`, `choice` | Which stage, and which of the three offers |
| `offers` | The hash of the three offers the chapter made |
| `state`, `stateHash` | The run state at the start, embedded, and its hash |
| `endHash` | The hash of the run state the carry made from this stage's end |
| `link` | The chain (section 4) |

**The checks on a stage alone:** its `seed` is `H(run, "stage", chapter, choice)`; `stateHash` is the hash of `state`; `setup.stage` and `setup.wear` are what `stageSetup` makes from `state` and the chosen offer. A header that fails one is refused with the reason `"run"`. Then it plays as any replay, against its checkpoints and `world`.

## 4. Seeds, offers and the chain

**One hash for every draw a run makes before a match:** `H(run, key, a, b)`, 32 bits, the core's own mix (as `SimRng.keyed`: FNV-1a over the key, then fmix32 over the run seed's two halves and the two indices). The keys keep the streams apart:

| Draw | Seed | Notes |
| :--- | :--- | :--- |
| The planet | `H(run, "planet", 0, 0)` | |
| A chapter's offers | `SimRng(H(run, "offers", chapter, 0))` | A stream of its own for each chapter, so a chapter's offers never depend on how many draws an earlier chapter used. The offers are `f(that stream, the run state)`: the picker skips fallen places, as Game Design rules. The same history gives the same offers |
| A stage's match | `H(run, "stage", chapter, choice)` | The match's seed (32 bits, as every match's) |
| The boss's place | none | A rule: the most populous city still standing, ties to the lower id |

**Why the stage seed leaves the history out.** Game Design's goal is that a seed can be shared and a run raced. If the seed took in what happened (the last stage's end), two racers with the same choices would meet different draws from the second stage on, for having fought differently. Their offers can still differ (a city one of them saved may have fallen for the other), which is the run's story. Their draws do not.

**The chain** is what "chained through the stage headers" gives: a hash that proves each stage followed the one before, and that its start is the last one's end.

- `link(0) = H(run, "run")`.
- `link(k + 1)` hashes `link(k)`, stage k's `stateHash`, its final gameplay hash and its `endHash`.
- Stage k + 1's header carries `link(k + 1)`, and its `stateHash` must equal stage k's `endHash` (QA's hard row: "the run state at a stage's start is the one the last stage ended with").
- The last link is one hash for the whole run. **QA's golden pins it,** with the final run state's hash.

**The run file** (`meridian-run`, v1): the run seed, the mode, the choices, and each stage's replay in order. A run plays back stage by stage: work out the offers, check the choice, build the setup and check it against the stage's, play the stage, carry, check the next header. Each stage still plays alone from its own header. `SimReplay.play` returns only hashes today; the run's player needs the final state too (a small change: a callback, or the state handed back).

## 5. The ledger as sim state

**During a stage: the tally** (`S.tally`, in the match's state, hashed only when the setup has a `stage`, as depth's state is hashed only with depth on). It counts at the places the core already funnels through:

| Ledger need | Counted where | Already there |
| :--- | :--- | :--- |
| The dead, by place and cause | `WorldCollateral.kill` (every death goes through it, with its building and its cause) | The cause (a fighter, or none) and the building index. The building's place id is new: World's plan gives each building its place and its index in the plan |
| Fled | The evacuations (same) | Building and owner |
| Buildings brought down, and damage to cities, by cause | The structures' damage and fall | The owner on most paths (to be checked path by path: a blast, a brunt, a collapse, a beam) |
| `avoided_towns` | Each tick, the player's ticks within 1,500 units of a building | New, cheap: one test a tick |
| Style (chains through two or more buildings, duels of perfects won, the boss's finisher) | The events that already announce them | The events |
| Forms taken and their branches; `result` and `comeback` facts (a win from the brink, two broken regions) | The form step; the KO; the wounds | The state |

Causes are slots: the player (slot 0), the opponent (slot 1), and other (a guard of one-v-many, a collapse with no owner).

**Between stages: the ledger,** inside the run state, closed from the tally by a pure function at the stage's end, in **whole numbers: counts and ticks.** `casualties` is the dead and the people present at the start, not "some"; `menace` is the meter in thousandths, not "high"; `city_cause` is the damage by cause, not a name. **The beat picker works out Game Design's bands** (under 1%, 1 to 10%, over 10%; 30 and 70; 60%) in the presentation layer, from the ledger and the run seed, as Narrative's rule 6 already has it. So:
- Narrative or Game Design can move a band, or add one, without moving a run's hash or any golden;
- the ledger holds facts, the picker holds readings.

**Why the tally is in `S` and the ledger is not.** The tally changes every tick that something dies, so it is match state: it must be in the hash, or a replay could agree on the fight and disagree on the story. The ledger changes once a stage, outside the tick, and the run's chain covers it.

## 6. Tier 5's state

**The ceiling comes from the setup.** Today a fighter's top tier is `1 + the ladder's thresholds` (`SimFighter.topTier`, the tier cap of 9a8b3a2c). In a stage it is the lower of that and `setup.stage.ceiling`, so a stage at tier 2 tops out at 3 whatever the ladder says. The boss's setup has a ceiling of 5.

**The fifth step is not a power threshold.** The ladder ends at 100. Game Design's tremor makes the fifth form ready instead: when the boss's first region breaks, or after 150 s of fight time (9,000 ticks), whichever comes first. Both fighters become `formReady` for tier 5, the boss takes his at once, and the player by holding Transform, through the form path that exists (`SimFighter` manual tier-up).

**`S.cata`** (in the match's state, hashed only when the ceiling is 5; integers and tick counts):

| Field | What |
| :--- | :--- |
| `phase` | 1 until the tremor, then 2 |
| `tremorTick` | The tick of the tremor, -1 before |
| `events`, `breaches`, `clouds`, `meteor`, `cloudTick` | The catastrophe events used: at most 3 in all (2 breaches, 2 blast clouds, 1 meteor), and the last cloud's tick (30 s apart). Each event borrows its allowance through the collateral's set-piece path (section 10.1: up to 20% of the people present at once, and the blast flag past `leaveFrac`) |
| `hazardWear`, `allWear` | For each fighter, the wear from hazards (magma, fire, falling stacks) and from everything, in wear units: the boss fight holds hazards to 25% of all wear (section 10.1), and magma never finishes anyone |
| `ash`, `ashTo`, `ashLeft` | The ash in thousandths, its target and the ticks left of its rise, which takes at least 120 s (7,200 ticks: Legal c05; Game Design's first value was 20 s). No rule reads it; the views do (`SimCata.ash`, 0 to 1), and the carry hands it to the run's `sky`. **Built ahead of the tier, with VFX's `blast_cloud` cue (applied in c09c3bef):** `S.cata` is null until a blast cloud, so it is hashed only once one lands; the tier-5 window adds the other fields and sets it up from the ceiling |
| `magma` | World's state (Research's magma as a twin of the water state, 79a0941e), held as World's water is held. It cools to rock, which raises the ground: rock records go into the wear list at the stage's end and stay for the run |
| `exo` | Later (not in the MVP): the exosphere's band and its 60 s |

**The tables that stop at four.** Every one is read as `table[tier - 1]` and would read past its end at tier 5:

| Where | Tables |
| :--- | :--- |
| `data/fight/ladder.json` | `reach.structure`, `beam.structure`, `beam.levelCapShare`, `beam.overshoot` |
| `data/biomes/blast.json` | `tierEnergy`, `tierDamage`, `tierRadius` |
| `data/biomes/brunt.json` | `tierFactor`, `towerPunches` |
| `data/biomes/contact.json` | `bounce.perTier` |
| `data/director/launch.json` | `knockBack.distBh`, `knockBack.skidSpeed` |
| `data/fight/shots.json` | `mine.tierR` |
| `sim/world/collateral.gd` (code, World's) | `BUDGET`, `CEILING`, `EVENT_ALLOW` (which also gains the catastrophe kind) |
| Read by act | The mood's acts (a stage's act is its tier: an act 5) and anything of the director's read by tier, which Encounter's inventory lists |

**Where the fifth entries live:** one file, `data/fight/tier5.json`, holding the fifth entry of each table by its file and key (Game Design's: structure reach 2.4, the budget 25% a minute, the ceiling 95%, and the rest), read only by a setup whose ceiling is 5, and folded into that replay's data hash only (`SimReplay.dataHash(setup)` already takes the setup). So:
- versus data and every versus replay's data hash stay as they are;
- the collateral's three code tables move to data on the way (numbers live in data);
- a check (parity, and Tools' validator) holds that every tier table named in the inventory has its fifth entry, so a table added later at four entries fails before a boss fight reads past it.

The ladder's per-tier gains (speed + 0.1, damage + 0.09, launch + 0.16 a tier) are already a formula in the tier and carry on to 5 without a table.

## 7. The planet's ceiling inside a match

Game Design's planet ceiling (at most 40% of the planet's people dead before the boss, 70% by the end) is a run fact, but it must hold inside a match. The budget and the tier's ceiling become shares of `stage.present` (the people present at the stage's start), where today they are shares of `pop0`; in versus the two are the same number, so nothing moves. The host works out `stage.peopleLeft` (the whole people the run may still lose, from the run state) and the collateral's cumulative ceiling takes the lower of its own and that. Past it, people shelter, as they do at today's ceiling. One line in `WorldCollateral.ceilingLeft`, World's.

## 8. The golden and the QA rows

- **Nothing in versus moves:** a setup without `stage` reads none of this, the tally and `S.cata` are not hashed without it, and `tier5.json` is not in a versus replay's data hash.
- **New keys:** the run seed's derived seeds for a few (run, chapter, choice); a scripted short run on a fixed seed (three short stages and the boss, each ended by a scripted finisher so the golden stays quick), with each stage's final hash, the final link and the final run state's hash. The full-length MVP run is QA's nightly row, not the golden's.
- **QA's hard rows map to checks:**

| QA's row | The check |
| :--- | :--- |
| A building marked, breached or downed is in the same state when a later slice crosses it | Two scripted stages on crossing slices: the building's stage at the second's tick 0 is the first's at its end |
| A stage replays bit-identical from its header alone | A stage replay played with no run file |
| The run state at a stage's start is the one the last stage ended with | The chain: `stateHash(k + 1) == endHash(k)` for every stage |
| No stage starts with a fighter in a crater or under water | The start's placement reads the laid wear before it places the fighters (World's, with the touch-down) |

## 9. Open

| For | Question |
| :--- | :--- |
| Game Design | **A Rampage's 15 s head start:** played (the opponent alone in the streets for 900 ticks before the player lands, part of the match and its replay) or laid on as wear before tick 0. Played is the more honest picture and costs nothing special; laid-on is cheaper and gives no 15 s the player watches |
| Game Design | The Dread and fill roundings to thousandths at the hand-over (section 2) are acceptable. And a stage that ends before its step (a finisher in the first 1:30): does the run still step his tier? |
| World | A building's place id and plan index (window 3), not in the per-tick building hash (the world hash covers them); the owner on every damage path; the budget and ceilings as shares of `stage.present`, and `ceilingLeft` taking `peopleLeft`; the magma's state; the three collateral tables moved to data, with the catastrophe kind |
| Encounter | The director's tables read by tier or act, for the inventory in section 6 |
| Narrative | The bands as the beat picker's data (section 5) |
| Tools | Schemas for the run state, the run file and `tier5.json` when the run is built; QA's runner playing a run file |

## 10. What it costs the core

| Piece (Game Design's order) | Core work |
| :--- | :--- |
| 3: the run state, its hash, the carry, stage seeds, the run log and its replay | `SimRun`: the state's canon and hash, `H`, the chain, `stageSetup`, `carry` (with World's wear extraction), the run file's player; `newMatch` reading `setup.stage`; the replay's `run` block and its refusal |
| 5: the ledger | `S.tally` and its counters at the choke points (with World's owners); the close |
| 6 and 7: tier 5, the tremor, the breach, the blast cloud, the ash | The setup's ceiling in the tier cap; the tremor's trigger; `S.cata` with the event counts and the hazard-wear share; `tier5.json` and the tier tables' reads; the moves are Encounter's, World's and VFX's on top |
| 8: fail forward and the score | Rules in `carry` |
