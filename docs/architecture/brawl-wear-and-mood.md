# Blocked blows and the arms, and the mood by a blow's form

2026-10-05. Game Design's rulings 1 and 2 on the first brawl build (`docs/design/melee-press-feel.md` section 9d), as built in the core, and what was measured. The first ruled values missed their bands; Game Design re-ruled from the measurements, and the re-ruled values are the ones in the data. Section 2 has their reading: the arms and the mood are in their bands.

## 1. As built

**Blocked blows** (`wounds.json` `block`, both fighters; `SimWounds.addGuardWear`).

- `block.streamArmShare` 0.5: a blocked light puts this share of its wear on the arms. The rest is soaked, and the legs take nothing. This holds in a planned exchange as well as in a brawl.
- A blocked heavy still splits by `guardWearSplit` (arms 0.7, legs 0.3).
- `block.armWearCap` 180000 (30 points at 6000 units a point; first ruled at 45): no blocked blow, light or heavy, takes the arms past it. What is over the cap is soaked and does not spill into the core. An arm already past the cap from landed blows takes nothing from a block.
- The loader refuses a cap at or over battered (`stageAt[1]`), so blocking alone can never batter an arm.
- A blocked blow is a light when its exchange's kind is `light`. The brawl sets the kind for each blow, so no line of Encounter's was needed.
- These two keys are for blocked melee blows. A blocked shot has its own share and cap, and what is over its cap reaches the core (section 5).

**Where a landed light lands** (`wounds.json` `family.light`): 12, 4, 11, 5 for head, core, arms, legs. It was 3, 1, 3, 1, which is 12, 4, 12, 4.

**The mood** (`mood.json` `impulses` and `rates`; `SimMood.tick`).

The `damage` event carries the blow's form in `mode` (in the hash). `SimDamage.hit` sets it: the director's `o.form` when it names one (`skill`, reserved for brawl B2), else `brawl` when the exchange's template is `brawl`, else empty.

| Impulse | Units | Read from |
| :--- | ---: | :--- |
| `brawlLight` | 15 (first ruled at 20) | a numbered `damage` of kind light with `mode` brawl |
| `brawlHeavy` | 120 | the same, of kind heavy |
| `skillStrike` | 90 | a numbered `damage` with `mode` skill (nothing sends it yet) |
| `blocked` | 0 | a numbered `damage` of kind guard |
| `flurryClose` | 180 | the cue `stagger` with text `flurry`, given to its `target` (who closed) |
| `guardBreak` | 240 | the cue `guard_break`, given to its `target` |
| `knockback` | 180 | the `knockback` event, given to its `attacker` |
| `strike`, `heavyStrike` | 90, 210 | as before, for a blow with an empty `mode` |

`chainLink` is not given inside a brawl: the flurry's close is its earned beat. `rates.decay` is 4 units a tick (it was 3).

**Checks** (`sim/core/tools/parity.gd`): "blocked blows and the arms" and "the mood by a blow's form".

## 2. What was measured

100 AI matches an arm, seeds 1 to 100, `--jobs=3`. "B1" is the first brawl build (5a0d527). "First" is the first ruled values (share 0.5, cap 45, `brawlLight` 20, decay 3). "Now" is the re-ruled values, read in the tree.

| | Band | B1, default | First, default | **Now, default** | B1, swap | First, swap | **Now, swap** |
| :--- | :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Arms' share of limb breaks (W5) | 35 to 65% | 91% | 83% | **54%** | 79% | 86% | **60%** |
| Limb breaks a match | | 0.33 | 0.48 | 0.39 | 0.28 | 0.42 | 0.52 |
| Calm, share of match time | 20 to 40% (re-based) | 4.1% | 8.1% | **25.2%** | 4.2% | 8.4% | **25.6%** |
| Tense | 40 to 65% (re-based) | 32.4% | 47.8% | **60.5%** | 32.9% | 47.7% | **59.1%** |
| Frenzied | 5 to 20% | 63.5% | 44.1% | **14.3%** | 62.9% | 43.9% | **15.3%** |
| Act 2 begins, median | | 78 s | 78 s | 78 s | 80 s | 80 s | 80 s |
| Median length | | 455.3 s | 494.9 s | 503.5 s | 467.2 s | 523.3 s | 525.6 s |
| First brink, median | | 366 s | 408 s | 421 s | 390 s | 436 s | 453 s |
| KAI's wins of 100 | | 50 | 51 | 48 | 49 | 58 | 47 |

**Pooled over both arms, now:** the arms took 52 of 91 limb breaks, 57%. KAI won 95 of 200. No region has more than 27% of all wear, so W5 passes. Game Design's fallback step was not needed.

**Still out:** the median length is over W3's 8:00 on both arms. Blocks wear less than they did, so brinks come later. Game Design holds `wearPerDamage` where it is until Encounter's next brawl slice.

## 3. Why the first values missed

**The arms.** Ten matches read tick by tick, on the first values:

- every fighter's arms became battered (20 of 20, at a median of 260 s), and the legs of 8 of 20 (320 s);
- a heavy-class blow marked a battered arm 133 times and a battered leg 68 times, though heavies land on the legs more often (394 against 152);
- arms were battered for 4,446 fighter-seconds and legs for 1,907.

A block could fill the arms to 45, and battered is 60. A landed light picked the arms 3 times in 8 and the legs once in 8, and a brawl is mostly lights, so the last 15 points arrived quickly. The cap stopped blocking from battering an arm by itself. It did not stop blocking from doing three quarters of the work.

**The mood.** The same ten matches, by what fed the mood, in units a second (the decay took 180 a second above the act's floor):

| | In | The largest feeds |
| :--- | ---: | :--- |
| Act 1 | 257 | `brawlLight` 71, `brawlHeavy` 35, both AGGRESSIVE 28, `knockback` 26, `heavyStrike` 23, `guardBreak` 17, `flurryClose` 14 |
| The whole match | 195 | `brawlLight` 35, `heavyStrike` 24, both AGGRESSIVE 21, `brawlHeavy` 18, `knockback` 17, `strike` 16, `guardBreak` 11, `chainLink` 10 |

So the feed was above the decay even with a light at 20, and `brawlLight` was under a fifth of it. Two more facts set the ceiling for Calm:

- **The acts follow the forms, not the wounds.** Act 2 begins at 78 s because the first form step is at a median of 79 s (200 of 200 fighters). Acts 3 and 4 begin near 190 s and 295 s, with form steps 2 and 3. No wear lever moves them.
- **Act 3's floor is the Tense line** (`actFloors[2]` 1800, `bands.tense` 1800). From act 3 the mood cannot be Calm, so Calm is at most about 38% of a match, whatever the impulses are. Calm's band was re-based for this.

The mood does not feed back into the fight: a what-if that changes only the mood's data leaves wins, lengths and wounds identical.

## 4. What-ifs

Run in a scratch copy, 100 matches, default arm, each starting from the first ruled values. They are what Game Design re-ruled from.

| What changed | Arms' share of limb breaks | Calm | Frenzied | Notes |
| :--- | ---: | ---: | ---: | :--- |
| Nothing (the first ruled values) | 83% (0.48 a match) | 8.1% | 44.1% | |
| Blocks wear the arms nothing (share 0, cap 0) | 59% (0.32) | 8.4% | 44.6% | KAI 51, median 499.6 s |
| A landed light picks arms 2, legs 2 of 8 | 13% (0.56) | 8.5% | 47.6% | overshoots: legs 88%; KAI 62 |
| `brawlLight` 15, decay 4 | 83% | 25.0% | 13.1% | the fight is unchanged |
| Share 0.3, cap 45; `brawlLight` 20, decay 4 | 86% (0.35) | 21.0% | 19.3% | KAI 54, median 479.5 s |
| Share 0.5, cap 20; `brawlLight` 15, decay 5 | 79% (0.42) | 34.5% | 4.7% | KAI 53, median 511.9 s |
| Share 0.3, cap 20; `brawlLight` 20, decay 5 | 79% (0.42) | 31.3% | 6.7% | KAI 50, median 503.0 s |

The share and the cap alone leave the arms near 80% until blocks are off the arms altogether. The landed-light pick is the strong lever: one step of 1 in 32 with the cap at 30 moved the share from 83% to 57%, and 4 in 32 overshot to 13%.

A limb breaks in 30 to 50 of 100 matches, so a share read on 100 matches is good to about 15 points either way, and on 200 to about 10.

## 5. Blocked shots (2026-10-05, on Encounter's brawl repairs, 5651c59)

**What went wrong.** After section 1 a bolt-only player won 1 of 100 against the medium AI (band 20 to 40; 36 on the first brawl build). The cap was not the cause. Before, a blocked hit's wear went through the limb rule: a limb fills to just under broken and the rest spills into the core, so shots on a guard ended up wearing the core, and the core is what brings the brink. Section 1's cap soaks what is over it, so a guarding fighter's core took nothing from a blocked shot, at any cap.

**The rule** (Game Design, `melee-press-feel.md` section 9d): a block fills the arms to 30 whatever was blocked; past that a blow is soaked and a shot comes through to the core.

| What was blocked | To the arms | Over the arms' cap | To the legs |
| :--- | :--- | :--- | :--- |
| A light or flurry blow | `block.streamArmShare` 0.5, up to `block.armWearCap` (30 points) | soaked | nothing |
| A heavy blow | `guardWearSplit.arms` 0.7, up to `block.armWearCap` | soaked | `guardWearSplit.legs` 0.3 |
| A bolt (a shot of power under 2) | `block.shotArmShare` 0.5, up to `block.shotArmWearCap` (180000, 30 points) | **into the core** | nothing |
| A heavy or charged shot (power 2 or more) | the same | **into the core** | `guardWearSplit.legs` 0.3 |

- **As built:** `SimWounds.addGuardWear(S, f, damage, how)` with `BLOCK_HEAVY`, `BLOCK_LIGHT`, `BLOCK_SHOT` and `BLOCK_SHOT_HEAVY`. `SimDamage.hit` works out which: a guarded hit of kind `blast` is a shot, a bolt when the director names a power under 2 in `o.shot`, else a heavy one; a blow goes by its exchange's kind.
- **Two lines of Encounter's file,** by the EP's grant: in `sim/director/blast.gd` the mine's hit and the plain shot's hit pass `"shot": sh.power`. The director already reads a heavy shot as power 2 or more.
- **The loader** keeps `shotArmWearCap` under broken and `armWearCap` under battered. The two shot keys stay apart from the blows' keys though the caps are equal today.
- **The lever** is `shotArmShare`, inside 0.45 to 0.6. The caps of 45 and 75 were read and withdrawn: at 75 shots batter an arm that a heavy can then cripple (arms 70 to 74% of limb breaks), and at 45 a block does three quarters of the work again (68%).
- **Check** (`parity.gd`): "blocked shots and the arms".

**Read in the tree** at share 0.5, 100 an arm and 100 seeds a pair (QA's `players.gd` pairs):

| | Band | Default | Swap |
| :--- | :--- | ---: | ---: |
| Bolt-only against the medium AI | 20 to 40 of 100 | 33 | |
| Mixed blaster against the medium AI | 30 to 50 of 100 | 42 | |
| Arms' share of limb breaks | 35 to 65% | 67% | 59% |
| Median length (90th percentile) | 360 to 480 s | 435.7 s (567.8) | 451.8 s (588.2) |
| KAI's wins of 100 | | 59 | 55 |
| Calm, Tense, Frenzied | 20 to 40, 40 to 65, 5 to 20% | 22.3, 61.2, 16.5 | 23.6, 62.3, 14.1 |
| Acts 2, 3 and 4 begin, median | | 66, 159, 251 s | 66, 164, 259 s |

Pooled, the arms took 46 of 73 limb breaks, 63%.

**What fills the ladder** (asked with this slice: acts 2 and 4 start about a quarter early). Ten AI matches read tick by tick, by where each fighter's power came from up to each form step:

| Form step | Median | Damage taken | Damage dealt | The passive fill | Charging |
| :--- | ---: | ---: | ---: | ---: | ---: |
| 1 (power 30) | 65 s | 56% | 33% | 11% | 0% |
| 2 (power 65) | 163 s | 54% | 33% | 13% | 0% |
| 3 (power 100) | 273 s | 54% | 32% | 13% | 0% |

The AI spent a median of 0.0 s charging before each step, so `chargePerSec` is not a lever for the acts and was left alone. Nine tenths of the ladder is damage: a hit gives its victim 1% of the damage as power and its attacker 0.6% (two constants in `sim/core/damage.gd`). The brawl's damage scale went from 0.30 to 0.38 in Encounter's slice, which is the likely reason the acts came forward (act 2 began at 78 s before it and at 66 s after; not isolated by a run). The levers that would move the acts are those two rates or the thresholds (30, 65, 100 in `ladder.json`).

## 6. The retune on the riposte build (2026-10-05, on 2b96fdc)

Encounter's slice (a perfect block and a reversal resolve inside the brawl) put more blows on target: 151.6 a minute between the AIs, from 104.5. Three sets of rows went out with it. The arms took 73.2% of limb breaks. Calm read 13.7% and Frenzied 27.9%. The acts began at 64, 148 and 237 s. QA's baseline also read 40.4% of battered wear recovered by the second breath, against a ceiling of 25.

**What changed** (Game Design's rulings in `melee-press-feel.md` sections 9d to 9g and `spec-wounds.md` sections 1c and 8b):

| What | Was | Is | Where |
| :--- | :--- | :--- | :--- |
| A landed light's pick of the arms and the legs, in 32 | 11 and 5 | 10 and 6 | `wounds.json` `family.light` |
| Wear for a point of damage | 350 | 330 | `wounds.json` `wearPerDamage` |
| The ladder's first threshold | 30 | 35 | `ladder.json` `thresholds` |
| Power for a point of damage taken, and dealt | 0.01 and 0.006, constants in `damage.gd` | 0.0075 and 0.0045, data | `ladder.json` `takenPerDamage`, `dealtPerDamage` |
| The mood for a brawl's landed light | 15 | 13 | `mood.json` `impulses.brawlLight` |
| The mood's decay, units a tick | 4 | 5 | `mood.json` `rates.decay` |
| The once-a-match wound beats that raise the act | a limb battered, the core bruised, the core battered | the first two | `mood.json` `actBeats.oncePerMatch` |
| What restarts the second breath's 4 s | an exchange | an exchange, any hit he takes, his own approach | `SimWounds.step`, `f.breathT` |

**The two power rates** are each fighter's own: a hit gives its victim `takenPerDamage` of the damage from the victim's file and its attacker `dealtPerDamage` from the attacker's. Moving them into data at their old values changed no match (parity passed on the goldens untouched).

**The second breath waits for quiet** (`spec-wounds.md` section 1c). Measured before the change, over 12 AI matches: 74% of second-breath time was within 4 s of the fighter being hit or of an attack of his own, and what hit him then was always a shot. Shots never restarted the wait; only an exchange did. So a fighter under fire recovered as if the fight had paused.

- The wait now starts again on any hit he takes (landed or blocked, a blow or a shot), on an exchange he is in, and on his own approach from its tell, whether or not it lands. The last is one line of the director's, by the EP's grant: `sim/director/bands.gd`, in `begin()`.
- It does **not** start again when he fires a shot or when a hit of his own lands. That was built first, as "any attack of his own", and it took the bolt-only player from 27 wins in 100 to 8 and the mixed blaster from 48 to 15: a player who fires every 8 ticks restarted his own wait for ever. On the same 36 seeds bolt-only read 6 with that clause, 13 without it and 12 on the old rule.
- State: `f.breathT`, hashed. The wait counts from the later of `f.exT` and `f.breathT`.

**What starts the acts.** With the ladder slowed, the wound track began to lead. Thirty matches read tick by tick, with the three wound beats: act 4 began at a median of 245 s, and its cause was the core becoming battered in 19, a region break in 6 and a form step in 4. The ladder alone was already in band (the leading fighter's power reached 65 at 194 s and 100 at 308 s), so no threshold or rate could have moved act 4. With the core's battered beat out, the wound track gives two acts and the fourth needs a third form step or a region break. The core becoming battered still shows on the body and still feeds the mood.

**Read in the tree,** 100 an arm and 100 seeds a pair:

| | Band | Default | Swap |
| :--- | :--- | ---: | ---: |
| Arms' share of limb breaks | 35 to 65% | 60% of 47 | 49% of 45 |
| Calm, Tense, Frenzied | 20 to 40, 40 to 65, 5 to 20% | 31.0, 60.1, 8.9 | 34.1, 58.5, 7.4 |
| Acts 2, 3 and 4 begin, median | 90 to 150, 150 to 240, 270 to 345 s | 95, 183, 291 s | 94, 197, 322 s |
| Act 4 before the first brink | at least 80% of matches | 99% | 99% |
| Median length | 360 to 480 s | 408.5 s | 449.8 s |
| Length, 10th and 90th percentile | at least 300, at most 600 s | 316.5 and 540.8 s | 319.1 and 567.8 s |
| Second breath, share of battered wear recovered | at most 25% | 20.6% | 22.7% |
| First brink, median; brink to KO, median | | 324 s; 59 s | 377 s; 54 s |
| KAI's wins of 100 | | 55 | 48 |
| Bolt-only against the medium AI | 20 to 40 of 100 | 25 | |
| Mixed blaster against the medium AI | 30 to 50 of 100 | 35 | |

Pooled, the arms took 50 of 92 limb breaks, 54%.

**The mood's levers.** `brawlLight` 10 with decay 5 was in band but left Frenzied at 5 to 6%, on its floor. 13 with 5 centres it. The 240 that a perfect block or a reversal gives was left alone. Mood data does not feed back into the fight.

**Checks** (`parity.gd`): "the second breath waits for quiet" (what restarts the wait and what does not, and the director's line), and two rows in the wired-numbers check for the two rates.


## 7. The third weight and a named region (2026-10-06, on 2dc8a663)

Game Design's table is `docs/design/brawl-second-pass.md` section 2, "What the core decides by strength". The core now carries three weights for a blow: light, medium and heavy. **A blow's weight is the exchange's kind as the blow lands** (`ex.kind`; the brawl sets it for each press). The new heavy keeps the heavy's column. Every medium figure is a first value, and none has been run: nothing sends a medium yet.

| What the core decides | Light | Medium | Heavy | Where it lives |
| :--- | :--- | :--- | :--- | :--- |
| Wound pick (head, core, arms, legs) | 12, 4, 10, 6 | 8, 8, 7, 9 | 1, 3, 1, 3 | `wounds.json` `family.light`, `family.medium`, `family.heavy` |
| On a block | half to the arms, to the cap; nothing to the legs | as a light | 0.7 to the arms, 0.3 to the legs | `block.streamArmShare`, `block.armWearCap`, `guardWearSplit` |
| Staggers a fighter whose head is battered | no | no | yes | code: the event's kind is heavy |
| Marks a battered limb for the crippling roll | no | no | yes | `cripple.blows` |
| Thrown with a broken arm | x1.15 | x1.0 | x0.8 | `penalties.armsBrokenLightMul`, `armsBrokenMediumMul`, `armsBrokenMul` |
| Mood, in a brawl | `brawlLight` 13 | `brawlMedium` 40 | `brawlHeavy` 120 | `mood.json` `impulses` |

- The broken-arm multiplier is for the exchange's attacker (`ex.A`), as it was. A blow by the exchange's defender takes none.
- A medium's short reel is the director's. The core gives a medium no stagger.
- Outside a brawl a medium feeds the mood as `strike`.
- The damage event's `kind` is `medium` (`fx-events.md`).
- The style label still counts a medium with the lights. That is open with the EP.

**A hit that is not a blow can name a weight for the mood.** The option `form` on `SimDamage.hit` takes `brawl_light`, `brawl_medium` or `brawl_heavy`, and the mood adds that impulse whatever the event's kind. A point-blank shot goes through the blast's own hit, with no exchange passed, and names its weight there: a bolt as a light, a blast as a medium. Blocked, the named weight is dropped and the hit feeds the mood nothing, as a blocked blow does. Its wear is the blocked shot's (section 5).

**A blow can name where it lands.** The option `region` on `SimDamage.hit` takes `head`, `core`, `arms` or `legs`.

- Landed, the blow wears that region and the event names it. No region is drawn, so the seeded stream does not move.
- Blocked, the name is ignored: the block's rule decides.
- A name that is not a region is ignored, and the region is drawn as usual.

**Data.** `family.medium` (four numbers, 0 or more) and `penalties.armsBrokenMediumMul` (above 0) in both fighters' `wounds.json`; `impulses.brawlMedium` (an integer, 0 or more) in `mood.json`. The three form words are not data. Tools' schema script is `docs/tools/pending/apply-core-medium.cjs`.

**Neutral.** The goldens were regenerated on a clean export. Every match, replay and checkpoint is identical. Only the roster hash and the fight data hash moved, for the new keys.

**Checks** (`parity.gd`): "a medium blow, rule by rule" (a case for each row above, beside a light and a heavy, and a blocked point-blank shot), "a blow that names its region" (each region, no draw, a blocked blow, a name that is no region), and the medium's and the named weights' rows in "the mood by a blow's form".
