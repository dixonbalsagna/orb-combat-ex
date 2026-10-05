# Blocked blows and the arms, and the mood by a blow's form

2026-10-05. Game Design's rulings 1 and 2 on the first brawl build (`docs/design/melee-press-feel.md` section 9d), as built in the core, and what was measured. The first ruled values missed their bands; Game Design re-ruled from the measurements, and the re-ruled values are the ones in the data. Section 2 has their reading: the arms and the mood are in their bands.

## 1. As built

**Blocked blows** (`wounds.json` `block`, both fighters; `SimWounds.addGuardWear`).

- `block.streamArmShare` 0.5: a blocked light puts this share of its wear on the arms. The rest is soaked, and the legs take nothing. This holds in a planned exchange as well as in a brawl.
- A blocked heavy still splits by `guardWearSplit` (arms 0.7, legs 0.3).
- `block.armWearCap` 180000 (30 points at 6000 units a point; first ruled at 45): no blocked blow, light or heavy, takes the arms past it. What is over the cap is soaked and does not spill into the core. An arm already past the cap from landed blows takes nothing from a block.
- The loader refuses a cap at or over battered (`stageAt[1]`), so blocking alone can never batter an arm.
- A blocked blow is a light when its exchange's kind is `light`. The brawl sets the kind for each blow, so no line of Encounter's was needed.

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
