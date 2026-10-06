# Brawl slice B1c: the perfect block and the reversal inside the brawl

Owner: Encounter Systems Director. Date: 2026-10-05. Status: applied to the tree on HEAD d1007c1, measured in a scratch copy of b6a7e47 (the commits between touch docs only, and both hold Simulation's 3bd86be), waiting for the EP's commit. Parked sources: `docs/director/pending/brawl-b1c/`. Spec: `docs/design/melee-press-feel.md` section 9f, with section 9e's ruling 2 and its give-back for the shooters. It follows slice B1b (`brawl-b1b.md`). The zip plan's review is `brawl-plan.md` section 7.10.

## 1. What changed

**Inside a brawl, a perfect block and a reversal resolve in place. Neither ends the brawl.**

| Thing | Rule | Number (data) |
| :--- | :--- | :--- |
| **A perfect block** | The blow is turned and does nothing. The attacker's string is closed, his run is cleared, and he staggers in place for 20 ticks. The brawl's idle clock starts again | `brawl.perfectBlock.staggerTicks` |
| **The riposte** | The blocker's next attack pressed within 30 ticks of his perfect block. It can't be blocked or perfect-blocked, and the rival can't leave by a dodge or a boost while it is on its way | `brawl.riposteTicks` |
| **A light riposte** | Worth a skill strike, which is 4 brawl lights. It reels for 8 ticks. It adds nothing to the run and is never a close. On the brink it counts as a close does | `skillMul`, `brawl.riposteReelTicks`, `launch.json setup.weight.riposte` |
| **A heavy riposte** | A brawl heavy. After a turned light it lands as a lone heavy does, with a stagger in place, and on the brink it counts as a close does. After a turned heavy or ender it is an ender: it goes to the launch decision, launches when a launch is earned and knocks back when it isn't. That is the one case that separates them | |
| **A reversal** | Made as before: context after a block, for its ki, with its cooldown. The attacker's string is closed, his run is cleared, and he staggers in place for 20 ticks. The reverser's heavy lands for certain 10 live ticks later, worth a brawl heavy, in place. It doesn't knock back or launch. On the brink it counts as a close does | `brawl.reversal.staggerTicks`, `contactTicks` |
| **A reversal against a blocked heavy** | The heavy still chips the guard. The guard isn't broken: the reversal takes the moment | |
| **The mood** | Both give the parry's impulse | |

**The AI.**

| Thing | Rule | Per level (`ai.json`) |
| :--- | :--- | :--- |
| **Fewer enders** | After two landed blows it closes its string with an ender at a share by level. Otherwise it keeps tapping to the flurry's close, or guards and goes again | `brawl.enderShare` 0.6, 0.4, 0.35 |
| **Its heavy at a guard** | When it would be its string's ender, it is weighed by the ender's share as well | No new key |
| **Its riposte** | At its level's riposte rate. It is a light. After a turned heavy or ender it is a heavy at its ender share, since that heavy separates them | `riposte` (existing), `brawl.enderShare` |
| **Its reversal** | Weighed on a block at most once in 120 ticks, as before | `aiReversalEveryTicks` |
| **A barrage** | Medium guards one more often again, now that a blocked shot reaches the core | Medium `barrageGuard` 0.25 |

## 2. For QA, Animation and UI

| Event | Fields |
| :--- | :--- |
| **Cue `riposte`** (new) | Sent on the press. `actor` the blocker, `target` the rival, `text` `light` or `heavy`, `n` the `S.tick` of its contact. That is an absolute tick, as the `blow` cue's `n` is, and a hit-stop can make the real contact later |
| **Cue `stagger`** | Two new texts beside `flurry` and `heavy`: `perfect_block` and `reversal`. `actor` the fighter who staggers, `target` the one who earned it, `n` the ticks |
| **Strike beats** | A brawl's beat may carry `riposte`, `reversal` and `sure`, each true. A `sure` blow can't be blocked, perfect-blocked or left. A blow that a perfect block turned has `o.turned` true |
| **Cues `perfect_block`, `reversal`** | As before, on the block's tick |
| **Cue `brawl_end`** | It no longer says `perfect_block` or `reversal` |

- **The riposte's beat is in `S.dirS.ex.beats` from the press to its contact:** 2 ticks for a light, 34 for a heavy. It is the same exchange all along, because the brawl doesn't end.
- **The reversal's heavy** is in the beats from the block's tick. It lands 10 live ticks later. On `S.tick` that is 10 plus the hit-stop of the blocked blow: I read 12 after a blocked light and 17 after a blocked heavy.
- **Rows that change meaning:** "how brawls end" has no perfect-block or reversal share now. Perfect blocks for each 100 blows still counts the `perfect_block` cue.

## 3. How it is built

- `sim/director/brawl.gd`: `perfectBlocked`, `reversed` and `sureAgainst`; three more integers a fighter (the riposte's window, what was turned, and the AI's riposte), so the state is 37; the riposte in `_throw`; a turned blow, the riposte's light and a reversed heavy in `contact`; a sure heavy's count on the brink in `_heavyLanded`; the AI's riposte and its heavy at a guard in `aiInput`.
- `sim/director/interrupt.gd`: `perfectBlock` and `reversal` hand a brawl's to `DirBrawl` and return; a sure beat has no perfect-block window; a dodge-cancel is refused while a sure blow is on its way.
- A blow scheduled from inside a blow's own beat counts from that tick: the reversal's heavy would have landed a tick late.
- `sim/director/tools/brawl_probe.gd`: `--mix=1` is the mixing presser of section 9f. Nothing running follows section 2b's list. It counts perfect blocks, reversals and ripostes inside brawls, and gives a brawl's 90th percentile.
- **New keys:** `interrupts.json` `brawl.perfectBlock` {`staggerTicks`}, `brawl.riposteTicks`, `brawl.riposteReelTicks`, `brawl.reversal` {`contactTicks`, `staggerTicks`}; `launch.json` `setup.weight.riposte`. Tools' `docs/tools/pending/apply-brawl-1c.cjs` carries them: with it the validator reads 158 files, 0 errors and 0 warnings, and its self-test passes 4445 of 4445.

## 4. What moved, and what didn't

| Key | Before | Built | Why |
| :--- | :--- | :--- | :--- |
| `brawl.damageMul` | 0.38 | 0.31 | The AIs spend more of the fight in a brawl, so matches shorten. Section 9f's start of 0.34 read a mean of 357 s on my probe of 12 AI matches, and 0.31 read about 400 s. On the harness 0.31 reads medians of 413.0 and 417.4 s |
| Medium `barrageGuard` | 0.05 | 0.25 | The give-back of section 9e. Bolt-only and the mixed blaster against medium, by this value: 0.05 read 55 and 56 of 100; 0.2 read 37 and 36; 0.3 read 19 and 53. At 0.25 the harness reads 27 and 48 |
| `vsShooter.heavyApproachShare` | 0.05, 0.1, 0.3 | Unchanged | With `barrageGuard` at 0.3, raising it to 0.1, 0.2 and 0.4 read 14 and 26, under both bands. There is no room for it at this base |
| `aiReversalEveryTicks` | 120 | 120 | As ruled. It is the masher's lever: at `damageMul` 0.34 the masher read 35 of 100 at 120, and 49 to 52 at 150 to 240 |
| `brawl.reversal.staggerTicks` | | 20 | As ruled. It is no lever under 22: the reversal's heavy lands at tick 10 and its own 12-tick stagger covers the rest. The masher read the same 35 at 12, 14 and 16 |

## 5. Rows

Measured on the scratch copy. The tree's seven files are byte for byte that copy's. QA's harness is `node qa/run-godot.js`, four arms, 100 matches an arm, 3 jobs: 99 bands pass, 28 fail and 21 are pending; of its tests 6 pass, 1 fails (W5, on the arms' share below) and 42 are pending. Every gate exits 0 on the copy: the goldens, parity, the loader check, determinism, the seam sweep, the cue check, Animation's check, the four input tests, the mash probe and `npm test --prefix sim`, which also passes in the tree.

**The standing rows.**

| Row | Read | Band | |
| :--- | ---: | :--- | :--- |
| Match length, median: default arm and swap arm | 413.0 s and 417.4 s | 360 to 480 s | In |
| Match length, 10th percentile: each arm | 304.9 s and 279.3 s | at least 300 s | **The swap arm is under.** The harness reads the default arm |
| Match length, 90th percentile: each arm | 569.1 s and 557.7 s | at most 600 s | In |
| KAI over both slots | 51.5% (48.0% from P1, 55.0% from P2) | 45 to 55% | In |
| Masher at an 8-tick gap on `S.tick` against the easy, medium and hard AI | 96, 45 and 0 of 100 | at least 60%; 35 to 50%; at most 15% | In |
| The same masher at 6 and 10 ticks against medium | 57 and 43 of 100 | reported | The 6-tick masher is over 50 |
| Bolt-only against medium | 27 of 100 | 20 to 40% | In |
| The mixed blaster against medium | 48 of 100 | 30 to 50% | In |
| The slow blaster against medium | 8 of 100 | reported | |
| Blasts' share of damage | 10.4% | 10 to 25% | In, at the floor |
| First brink, median | 323.9 s | 270 to 420 s | In |
| Brink to KO, median | 58.7 s | 45 to 90 s | In |
| Finisher survival | 33.3% | 25 to 40% | In |
| Launches of the exchanges that separate | 29.3% | 25 to 40% | In |
| Limb breaks a match, and the arms' share | 0.41 and 73.2% | 0.3 to 0.5; 35 to 65% | **The arms' share is out,** and test W5 fails on it |
| Region breaks and rallies a match | 2.17 and 0.36 | 1.5 to 2.5; 0.3 to 0.7 | In |
| Mood: Calm, Tense and Frenzied shares | 13.7%, 58.4% and 27.9% | 20 to 40%; 40 to 65%; 5 to 20% | **Calm and Frenzied are out** |
| Acts 2, 3 and 4 start at | 64.2 s, 148.0 s and 236.6 s | 90 to 150 s; 150 to 240 s; 270 to 345 s | **All three are early** |
| Perfect blocks for each 100 blows, medium AI | 1.58 | 2.2 to 6.5 | **Under** |
| Civilians lost, and front-row structures lost | 22.0% and 40.5% | 12 to 30%; 25 to 50% | In |

**The brawl's own rows.** The AI against itself is QA's harness where it has the row, and my probe of 12 matches otherwise. The two pressers are my probe, 20 matches each against the medium AI at an 8-tick gap: one who mixes (he closes about half his strings with an ender once two blows have landed), and one who throws lights only.

| Row | The AI against itself | The mixing presser | Lights only | Band |
| :--- | ---: | ---: | ---: | :--- |
| A brawl's median length | 2.8 s (2.68 s on the probe) | 3.03 s | 9.3 s | 2.5 to 6 s, read on the first two |
| A brawl's 90th percentile | 7.1 s | 10.08 s | 45.9 s | at most 20 s, read on the first two |
| Blows in a brawl, median | 27 | 41 | 146 | 10 or more |
| Share of fight time in a brawl | 25.2% (23.3% on the probe) | 57.5% | 72.3% | at least 25% for the AI until the zip; 45 to 60% for the mixing presser |
| Nothing running, by section 2b's list | 10.3 s a minute | 3.8 s | 2.9 s | at most 15 s |
| After a knock-back, the time to the next engagement | median 0.9 s, 90th percentile 1.87 s | 0.23 s and 1.37 s | 0.43 s and 3.9 s | at most 2 s; at most 4 s |
| The AI's heavy after a close: reached the rival | 48 of 50 | 149 of 211 | 390 of 393 | |
| The presser wins | | 3 of 20 | 12 of 20 | |

- **How the AI's brawls end** (harness): knock-back 63.7%, signature 20.4%, launch 11.2%, idle 2.6%, break 2.2%.
- **In the AI's 12 probe matches:** 51 perfect blocks and 145 reversals inside brawls; 91 light ripostes and 4 heavy ones.
- **A minute of an AI match** (harness): 4.2 brawls, 151.6 blows, 2.3 closes. Before this slice it was 4.9, 104.5 and 1.6.
- By the probe's old count the AI's 10.3 s would read 18.7 s: 7.0 s of the difference has a shot in the air, 1.0 s a rush and 0.4 s a staggered fighter.

**The lights-only mirror.** QA's two mirrors of 60 matches: taps on live ticks, and taps on `S.tick`.

| Row | Live ticks | `S.tick` | Band | |
| :--- | ---: | ---: | :--- | :--- |
| Matches finished before the cap | 60 of 60 | 60 of 60 | at least 95% | In |
| Brink to KO, median | 27.1 s | 27.8 s | 25 to 50 s | In. The harness still prints the old 30 to 55 s |
| Matches won from the first slot | 50.0% | 40.0% | 40 to 60%, read on 200 matches | My own probe reads 20 of 40 |
| Level trades that change who has the momentum | 10.4% | 9.7% | 5 to 15% | In |
| A trade breaks on the tick of its limit | longest 2 ticks late, 2,829 breaks | 0 late, 2,656 breaks | never early; 12 late allowed | Passes |
| From a break to its close: over 24 ticks | 0 | 0 | 0 | Passes |
| Share of closes made by the fighter on the brink | 57.6% | 74.7% | reported | |
| A 6-tick tapper against a 12-tick one | | 40.8 closes a minute on the slower | reported | |

**What is out, and what I think it is.**
- **The arms' share of limb breaks, 73.2%.** Section 9d says this share is good to about 15 points on 100 matches, and names its lever: the landed light's pick, which is Simulation's data. Simulation read 63% on the base before this slice.
- **The mood: Calm 13.7% and Frenzied 27.9%.** The AIs land more blows a minute, 151.6 against 104.5, and each one feeds the mood. The levers section 9d names are `mood.json`'s `brawlLight` and then the decay. One thing here is my reading: a reversal inside a brawl gives the parry's impulse, as the ruling's table says "the same".
- **The acts, at 64.2, 148.0 and 236.6 s.** They didn't come back with the scale at 0.31. The lever is the ladder's first threshold.
- **The swap arm's 10th percentile, 279.3 s.**
- **Perfect blocks for each 100 blows, 1.58.** Blows rose and perfect blocks didn't. The lever would be each level's `perfectMul`. I didn't move it.
- **The AI's share of fight time in a brawl, 25.2%,** is at its floor, and my 12-match probe reads 23.3%. Between brawls the AIs fire and lunge. The zip is what the ruling expects to lift it.
- **The 6-tick masher, 57 of 100.** The band is read at 8 ticks.
- **The rows counted for each exchange** (10.6 exchanges a minute, knock-backs 48.3%, "continues" 31.7%, perfect blocks 26.4 for each 100). QA has re-based them.

## 6. Not in this slice

- The AI leaving a brawl it is losing, by a zip away or a dodge away. Section 9f sets it for the last brawl slice.
- The zip. Its plan is reviewed in `brawl-plan.md` section 7.10, with the pieces Simulation, World and Animation have built for it.
- B2's first deliverables: the skill strike at its worth and as an answer, the grade taken at the press, and a skill strike winning a shared beat.
