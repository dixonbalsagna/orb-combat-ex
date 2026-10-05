# Brawl slice B1b: the even mash, the AI until B2, shots against the brawl's scale

Owner: Encounter Systems Director. Date: 2026-10-05. Status: applied to the tree on HEAD 23af4a1, measured in a scratch copy whose code and data files are that commit's, waiting for the EP's commit. Parked sources: `docs/director/pending/brawl-b1b/`. Spec: `docs/design/melee-press-feel.md` section 9d, rulings 3, 4 and 5, and the close guard added to ruling 3. Rulings 1 and 2 (blocked blows and the arms, the mood by form) are Simulation's and are on main. It follows slice B1 (`brawl-b1.md`).

## 1. What changed

**The even mash (ruling 3).**

| Thing | Rule | Number (data) |
| :--- | :--- | :--- |
| **A blow on a staggered fighter** | It does its damage and adds nothing to the run. So a close doesn't start the closer's next lead | `flurry.staggeredAddsRun` false |
| **The close guard** | A fighter can't be closed on again while a close's stagger lasts, or for 90 ticks after he recovers from it. The rival's run still counts, and a run of 4 closes on his first blow after the 90 | `flurry.closeGuardTicks` |
| **Who a trade breaks for** | At the trade's limit a lead of 2 or more takes the close. Runs within 1 are a level trade, settled by a seeded draw in which the fighter who made the last close in this brawl has 9 chances in 10. When nobody has closed yet in this brawl the odds are even | `flurry.levelWithin`, `flurry.momentum` |
| **The close's set-up weight** | A flurry's close counts 0.34 of a set-up against a fighter on the brink. B1 had 0.25. The ruling's value is 0.5 and its range is 0.34 to 0.5: section 4 says why it is at the bottom | `launch.json setup.weight.blurPlain` |
| **`flurry.closeAfter`** | Gone. It was the first build's name for `runToClose` | |

**The AI until B2 (ruling 4).**

| Thing | Rule | Per level (`ai.json`) |
| :--- | :--- | :--- |
| **Its tap gap** | 12, 8 and 6 ticks | `brawl.tapGap` |
| **Its answer to a close** | When a flurry's close has landed on it, its next action as its stagger ends is a tapped heavy, at a share by level | `brawl.heavyAfterClose` 0.2, 0.6, 0.9 |
| **A heavy into a running flurry** | Still a mistake made at a rate: 1.0, 0.33 and 0.1. Medium was 0.58 in B1. It is the lever for the masher's band (section 4) | `brawl.rashHeavy` |
| **The section 9c answers** | Still built and not set | |

**Shots and shooters (ruling 5).**

| Thing | Rule | Number (data) |
| :--- | :--- | :--- |
| **A heavy shot** | Worth its kind's damage times the brawl's scale times 2, as a heavy blow is. Bolts keep their value. `tapShare` stays 0.4 | `brawl.shotHeavyMul` |
| **A shooter** | To the AI, a rival who has fired in the last 90 ticks and has landed no melee blow on it in the last 120 | `brawl.shooter.firedTicks`, `noMeleeTicks` |
| **In a brawl with a shooter** | The AI's guard share and ender share are its level's `vsShooter` numbers | `vsShooter.guardShare`, `enderShare` |
| **Coming in on a shooter** | Its attack from outside reach is the heavy lunge or the heavy charge, at a share by level. It doesn't taunt, mine or soften that press | `vsShooter.heavyApproachShare` |

## 2. For QA

**The `trade_break` cue** now carries:

| Field | Meaning |
| :--- | :--- |
| `actor`, `target` | The fighter it breaks for, and the other |
| `n` | The trade's ticks at the break, on `S.tick` |
| `amount` | The limit, `flurry.tradeMaxTicks` |
| `x`, `y` | The actor's run and the target's run at the break |
| `text` | `lead` when a lead of more than `levelWithin` took it; `draw` when it was a level trade |
| `k` | Who made the last close in this brawl: 0 nobody yet, 1 the actor, 2 the target. A break changed hands when `text` is `draw` and `k` is 2 |

**When a trade breaks.** On the first live tick at or after its limit. A hit-stop holds the sim, so the break can come late by the ticks of the stop that covers the limit. The longest lateness measured is 2 ticks: over 4,578 breaks in QA's two mirrors (95th percentile 1 tick), and over 162 in my two probes against the AI. `LATE_OK` at 12 has room.

**From the break to the close.** The chosen fighter's next landed blow closes. If he lands nothing for 24 ticks the trade is over and the break is spent. QA's hard test reads 0 of 4,578 breaks over 24 ticks in its two mirrors. The 24 ticks are counted on `S.tick` and checked on live ticks, so a hit-stop inside the window can add its ticks, as it does for the break. My pressing probe against the medium AI, where heavies bring hit-stops, read 25 ticks as its longest gap from a break to the next flurry close. That probe takes any flurry close inside 30 ticks, so it doesn't show that the close at 25 was the break's own. If QA runs this test outside the mirrors, allow the hit-stop.

## 3. How it is built

- `sim/director/brawl.gd`: the run on a staggered fighter, the close guard (one more integer a fighter), the last closer of the brawl (one shared integer, on the exchange's attacker), the break's rule and fields, `DirBrawl.shooter(S, f, o)`, `DirBrawl.shotScale()`, and the AI's answer heavy and `vsShooter` numbers. State is now 34 integers a fighter.
- `sim/director/blast.gd`: the three places that read a heavy shot's kind damage multiply it by `DirBrawl.shotScale()`: the damage at fire, and the two tests that ask whether a shot was tapped or fully charged.
- `sim/director/ai.gd`: at an attack beat outside reach, against a shooter, the press is a heavy at `heavyApproachShare`.
- `sim/director/tools/brawl_probe.gd`: it also counts trades that reached their limit, how late a break came, how long the next flurry close took, the second slot's heavies after a close and how many reached the rival, and the time from a knock-back to the next engagement.
- **New keys:** `interrupts.json` `brawl.flurry.staggeredAddsRun`, `levelWithin`, `momentum`, `closeGuardTicks`; `brawl.shotHeavyMul`; `brawl.shooter` {`firedTicks`, `noMeleeTicks`}. `ai.json`, each level: `brawl.heavyAfterClose`, and `vsShooter` {`guardShare`, `enderShare`, `heavyApproachShare`} beside `brawl`. **Removed:** `brawl.flurry.closeAfter`. Tools' `docs/tools/pending/apply-brawl-9d.cjs` carries them: with it the validator reads 158 files, 0 errors and 1 warning, and its self-test passes 4352 of 4352. The warning is medium's `barrageGuard` under easy's (section 4).

## 4. What moved from the ruling's starting values

| Key | The ruling, or B1 | Built | Why |
| :--- | :--- | :--- | :--- |
| `brawl.damageMul` | 0.30 (B1) | 0.38 | Match length. It is the lever section 9d names. At 0.30 Simulation read main's median at 503 and 526 s on the two arms. At 0.36 this slice read 474.6 and 476.7 s, with the swap arm's 90th percentile at 600.5 s. At 0.38 it reads 434.3 and 464.2 s |
| `setup.weight.blurPlain` | 0.5 | 0.34 | The mirror's brink to KO is under its band at every value in the range. By momentum and weight: (0.9, 0.5) 26.9 s; (0.85, 0.5) 25.6 s; (0.95, 0.5) 26.2 s; (0.85, 0.4) 27.8 s; (0.9, 0.34) 28.2 s; (0.95, 0.34) 28.9 s; and (0.9, 0.25) 30.9 s, which is outside the range. The momentum doesn't move it |
| Medium `brawl.rashHeavy` | 0.58 (B1) | 0.33 | The masher's band. A real-clock masher at an 8-tick gap won 26 of 100 at 0.25, 41 at 0.33 and 50 at 0.4 |
| `vsShooter.enderShare` | 0.5, 0.2, 0.1 | 0.5, 0.45, 0.3 | With the ruled shares the shooters stopped winning: see the next row |
| `vsShooter.heavyApproachShare` | 0.2, 0.6, 0.9 | 0.05, 0.1, 0.3 | Against the medium AI, bolt-only and the mixed blaster by this share: 0.6 gave 0 and 4 of 100; 0.3 gave 13 and 17; 0.1 gave 23 and 38; 0 gave 34 and 62. Those were read before the wear rule of b5aab64 |
| Medium `barrageGuard` | 0.42 | 0.05 | Not in the ruling. Since b5aab64 a guard soaks every blocked shot, so an AI that guards a barrage can't be worn down by one. On that base the mixed blaster and bolt-only read 40 and 14 of 100 at 0.05 with the approach share at 0.1; 38 and 8 at 0.15 with no heavy approach; and 56 and 16 at 0.05 with no heavy approach. Tools' validator warns that medium is now under easy's 0.2. It is a warning and not an error. I expect to raise it again when blocked shots reach the core |
| `blastShare` | 0.2, 0.4, 0.5 | 0.3, 0.55, 0.65 | Blasts' share of damage fell to 7.7% with heavy shots at the brawl's scale. How often the AI fires is the lever the ruling names. It reads 11.8% now. Firing more also lengthens a match, which is why the scale went up again |
| `brawl.shooter` | In the ruling's text | 90 and 120 as data | So the numbers aren't in code |

## 5. Rows

Measured on the scratch copy with `damageMul` 0.38. The tree's eight files are byte for byte that copy's. QA's harness is `node qa/run-godot.js`, four arms, 100 matches an arm, 3 jobs: 100 bands pass, 27 fail and 21 are pending; of its tests 7 pass, none fail and 42 are pending. Every gate exits 0 on the copy: the goldens, parity, the loader check, determinism, the seam sweep, the cue check, Animation's check (with its fix of 23af4a1), the four input tests, the mash probe and `npm test --prefix sim`, which also passes in the tree.

**The standing rows.**

| Row | Read | Band | |
| :--- | ---: | :--- | :--- |
| Match length, median: default arm and swap arm | 434.3 s and 464.2 s | 360 to 480 s | In |
| Match length, 10th percentile: each arm | 322.2 s and 345.1 s | at least 300 s | In |
| Match length, 90th percentile: each arm | 581.8 s and 596.0 s | at most 600 s | In. The swap arm has 4 s of room |
| KAI over both slots | 55.5% (52.0% from P1, 59.0% from P2) | 45 to 55% | **Out by half a point.** It read 54.0% at 0.36. The interval at 100 an arm is 7 points each way |
| Masher at an 8-tick gap on `S.tick` against the easy, medium and hard AI | 88, 37 and 0 of 100 | at least 60%; 35 to 50%; at most 15% | In |
| The same masher at 6 and 10 ticks against medium | 42 and 35 of 100 | reported | |
| The mixed blaster against medium | 28 of 100 | 30 to 50% | **Out by 2.** It read 33 at 0.36 and 35 on the chain before that |
| Bolt-only against medium | 8 of 100 | 20 to 40% | **Out.** Main read 1 of 100 without this slice. It waits on Simulation's blocked-shots slice, as ruled |
| The slow blaster against medium | 3 of 100 | reported | |
| Blasts' share of damage | 11.8% | 10 to 25% | In |
| First brink, median | 362.4 s | 270 to 420 s | In |
| Brink to KO, median | 60.4 s | 45 to 90 s | In |
| Finisher survival | 28.6% | 25 to 40% | In at the point; the interval reaches under the band |
| Launches of the exchanges that separate | 31.9% | 25 to 40% | In |
| Limb breaks a match, and the arms' share | 0.45 and 48.9% | 0.3 to 0.5; 35 to 65% | In |
| Region breaks and rallies a match | 2.17 and 0.34 | 1.5 to 2.5; 0.3 to 0.7 | In |
| Mood: Calm, Tense and Frenzied shares | 22.6%, 61.6% and 15.9% | 20 to 40%; 40 to 65%; 5 to 20% | In |
| Acts 2, 3 and 4 start at | 66.2 s, 159.9 s and 250.2 s | 90 to 150 s; 150 to 240 s; 270 to 345 s | **Acts 2 and 4 are early.** Simulation read that the acts follow the forms |
| Civilians lost, and front-row structures lost | 25.2% and 43.7% | 12 to 30%; 25 to 50% | In |

**The lights-only mirror.** QA's two mirrors of 60 matches: taps on live ticks, and taps on `S.tick`.

| Row | Live ticks | `S.tick` | Band | |
| :--- | ---: | ---: | :--- | :--- |
| Matches finished before the cap | 60 of 60 | 60 of 60 | at least 95% | In |
| Brink to KO, median | 26.1 s | 28.8 s | 30 to 55 s | **Out** |
| Share of closes made by the fighter on the brink | 48.8% (39 of 80) | 70.3% (52 of 74) | 10 to 40% | **Out** |
| Matches won from the first slot | 53.3% | 35.0% (21 of 60) | 40 to 60% | **Out at 60 matches on `S.tick`, in at 200:** see below |
| Level trades that change who has the momentum | 10.6% | 10.3% | 5 to 15% | In |
| A trade breaks on the tick of its limit | 0 early, longest 2 ticks late, 2,333 breaks | 0 early, 0 late, 2,245 breaks | never early; QA allows 12 late | Passes |
| From a break to its close: over 24 ticks | 0 | 0 | 0 | Passes |
| A 6-tick tapper against a 12-tick one | | 39.1 closes a minute on the slower; the faster wins 60 of 60 | reported | The ruling's estimate was about 33 a minute. The guard counts `S.tick`, which runs through hit-stops. I haven't checked that this is the whole difference |

**The mirror at 200 matches,** run after the chain to tell a slot effect from sampling. QA's `S.tick` mirror reads 57.5% from the first slot (115 of 200) and a brink to KO of 28.1 s. My own mirror probe reads 55.0% (110 of 200), 27.5 s, and 43.6% of closes by the fighter on the brink. So the first slot is inside its band on both, with an interval of 7 points each way. In QA's run the first 60 seeds read 35% and the other 140 read 67%, which is more spread than sampling alone should give. I haven't found why. The row needs 200 matches to be read.

**The brawl's own rows.** The AI against itself is QA's harness and my probe of 12 matches. The pressing player is my probe: a light every 8 ticks of `S.tick` against the medium AI, 20 matches.

| Row | The AI against itself | A pressing player | Band | |
| :--- | ---: | ---: | :--- | :--- |
| A brawl's median length, and its blows | 1.7 s and 17 blows | 3.9 s and 63 blows | 2.5 to 6 s; 10 or more | **The AI's brawls are short.** The player's are in |
| Share of fight time in a brawl | 17.3% | 54.1% | 45 to 60%, by the last brawl slice | **The AI's share is out.** The player's is in |
| After a knock-back, the time to the next engagement | median 0.98 s, 90th percentile 2.13 s, 195 knock-backs | 0.38 s and 1.3 s, 16 knock-backs | at most 2 s; at most 4 s | In |
| Of the brawl endings that separate: knock-backs and launches | 87% and 13% | | 60 to 75%; 25 to 40% | **Out.** Over all exchanges the launch share reads 31.9% |
| Perfect blocks for each 100 blows, medium AI | 2.32 | | 2.2 to 6.5 | In. For each 100 exchanges it reads 20.55 |
| Brawls, blows and closes a minute | 4.9, 104.5 and 1.6 | | reported | |
| How brawls end | knock-back 42.0%, reversal 27.5%, signature 11.3%, perfect block 9.8%, launch 6.2%, break 1.6%, idle 1.6% | | reported | |
| The AI's heavy after a close: reached the rival | 41 of 43 | 284 of 289 | | Without the close guard it was 2 of 696 |
| Presses thrown inside 10 ticks | | 94.1% | | 4.5% of his presses come while he is staggered |
| Contact inside 4 ticks of the press | | 67% | | |
| Time with nothing running | 19.9 s a minute | 6.9 s a minute | | |
| The pressing player wins | | 8 of 20 | | |

**What is out, and what I think it is.**
- **Bolt-only, 8 of 100.** A guard soaks every blocked shot on main. Game Design has ruled that a blocked shot's wear past the cap reaches the core, and Simulation builds it next. I didn't tune for it.
- **The mixed blaster, 28 of 100.** It is 2 under its band, and the same build read 33 and 35 on two other chains. The same ruling should raise it. If it passes 50% then, the levers to give back are medium's `barrageGuard` and `vsShooter.heavyApproachShare`.
- **KAI, 55.5%.** Half a point over. Nothing in this slice is by fighter.
- **The mirror's brink to KO, 26.1 and 28.8 s.** The weight is at the bottom of the ruling's range, and the momentum doesn't move it. It reads 30.9 s at a weight of 0.25, which the ruling left.
- **The brink fighter's share of closes, 48.8% and 70.3%.** My reading, not measured: a close by the fighter on the brink wipes the rival's set-up, so the state of one fighter on the brink lasts longest when he holds the momentum. The row then counts mostly his closes.
- **The AI's brawls, 1.7 s and 17.3% of fight time.** The AI closes its strings with an ender, and the ender knocks back. Those two bands are for the last brawl slice.
- **Knock-backs at 87% of the endings that separate.** A launch from a brawl needs a held heavy or flow 3, and flow isn't earned in a brawl until B2.
- **Acts 2 and 4.** Simulation read that they follow the forms. The lever section 9d names is the ladder's first step, and it waited for this slice.
- **The rows counted for each exchange** (exchanges a minute 13.07, knock-backs 45.4%, "continues" 33.4%, perfect blocks 20.55 for each 100). A brawl is one exchange of many blows. QA has re-based them.

## 6. Not in this slice

- The section 9c answers stay unset until B2 brings the parry.
- B2's first deliverables are in section 9d: the skill strike at its worth, the skill strike as an answer, the grade taken at the press, and a skill strike winning a shared beat.
- Simulation adds one field to two calls in `blast.gd` for the blocked-shots rule (the EP's grant). It isn't in these files.
