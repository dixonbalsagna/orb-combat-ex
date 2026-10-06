# Zip slice Z1: the zip strike and the zip heavy

Owner: Encounter Systems Director. Date: 2026-10-05. Status: applied to the tree and frozen, waiting for the EP's commit. Parked sources: `docs/director/pending/zip-z1/` (`node apply.cjs <tree>` rebuilds the slice on 07f5652 or later; the goldens are regenerated after it). Spec: `docs/design/melee-press-feel.md` section 2c, with "Ruled for the first zip slice". Plan: `brawl-plan.md` sections 7, 7.10 and 7.11. It follows brawl slice B1c (`brawl-b1c.md`).

## 1. What it does

LT held with X or Y in the mid band is a zip: he pays, holds a tell, goes in, strikes once and comes out again.

| Thing | Rule in Z1 | Number (data, the `zip` block) |
| :--- | :--- | :--- |
| **Where** | From 3 to 12.5 bh, free to act, with no exchange running. Nearer or further the same press is what it was before | `band` |
| **The price** | 20 ki for the zip strike and 30 for the zip heavy, paid at the press and never returned. Without the ki the press is the plain lunge | `strike.ki`, `heavy.ki` |
| **The tell** | He holds still for 6 ticks, or 10 for the heavy | `tellTicks` |
| **The way in** | 6 to 8 ticks by distance, or 8 to 10 for the heavy. He flies to striking distance on his own side, and his end point follows the rival | `inTicks` |
| **In reach** | His blow lands 4 ticks after he arrives, or 12 for the heavy. He stays 6 more, or 10. He has no guard there, and his presses are spent | `reachBefore`, `reachAfter` |
| **The blow** | A zip strike is worth a skill strike, which is 4 brawl lights. A zip heavy is worth a brawl heavy. Each is times its reading | `mul` |
| **The speed reading** | A tap. ×1. A strike reels the rival 4 ticks; a heavy staggers him 12 | `reel.speed`, `stagger.speed` |
| **The tech reading** | Earned by the press when it is made inside the rival's own tell: he flies in on the floor and the rival's approach is dropped as he arrives. Or earned by a second press within the classifier's beat of his arrival: he keeps the way in he flew. Either way the blow is ×1.25, a strike reels 8 and a heavy staggers 20, and he leaves on the floor | `mul.tech`, `reel.tech`, `stagger.tech` |
| **The held reading** | The button kept down through the tell and 12 ticks more, or 20 for the heavy. ×1.25. A strike is in reach 8 ticks before it lands and reels 12. A heavy knocks back, which is decisive. Let go early, he goes at once in the speed reading | `heldTicks`, `heldReachBefore`, `mul.held`, `reel.held` |
| **The way out** | 10 ticks, or 12 for the heavy, and 1 more for each 2 bh of path past 8 bh, 20 at most. No strike reaches him on it | `outTicks`, `out` |
| **Legal's floor** | No way in or out takes fewer than max(4, the distance in bh over 3, rounded up) ticks. The tech reading travels on that floor | `floor` |
| **A shot on the way in** | It stops a zip strike. A zip heavy shrugs off a weak shot at part of its damage, as a heavy charge does, and is stopped by the rest | The blast data's `charge.shrugPower`, `shrugMul` |
| **A shot on the way out** | It drops him: out of control for 24 ticks, with no landing damage. The shot does its own damage | `knockdownTicks` |
| **Outrun** | If the rival gets more than 12.5 bh from where the zip began before he arrives, it ends short with no blow | `band.maxBh` |
| **The dodge that becomes a zip** | LT's press is a dodge at once. A face press within 8 ticks of it, when he wasn't threatened, takes the dodge back and the zip starts where he stands | `dodgeConvertTicks` |

## 2. The exit

The stick is read on the tick his blow lands, through Controls' sample ring: the direction held for 3 of the last 12 ticks.

| Stick | Where he ends | Cue's `text` |
| :--- | :--- | :--- |
| **None** | Back where he started | `home` |
| **Within 45 degrees of straight toward the rival** | The far side, at the distance he started from | `far` |
| **Anything else** | On the stick's bearing round the rival, at his start distance plus 6 bh × (1 − the angle off straight away over 90 degrees), 12.5 bh at most | `point` |

- **A blocked point** (under the ground, or within 1 bh of a building) slides round the circle toward his start bearing in 15-degree steps, the shorter way and upward on a tie, 24 probes at most. With none clear he goes home. A point on the ground is clear.
- **The way out is a rush.** It is straight when nothing is in the way. When its straight line comes within 1.5 bh of the rival, at any angle, it bows 2 bh: over him, and under him when the stick points down and there are 2 bh of room beneath. It bows over the ground or a building when the straight line would cross one, and the bow is raised up to three times until the path is clear.
- **The bow's 2 bh is its height at the middle of the way out** (`zip.bowBh`, Simulation's `Rush.arc`). The rival is near the start of that path, so right over him the path is about 0.8 bh off the straight line. Animation draws the pass with that in mind.
- The read's `pass` says which: `over`, `under`, `round` (no clear bow was found, so the path is straight) or empty.

## 3. The rival's answers

| Answer | Rule | Outcome |
| :--- | :--- | :--- |
| **A guard** | Held as the blow lands | A zip strike chips. A zip heavy staggers the blocker 12 ticks. He leaves as usual |
| **A perfect block** | A fresh guard press in the blow's window | B1c's: he staggers 20 ticks and the blocker has the riposte. The zip ends `countered` and the brawl is announced |
| **The tech counter** | A single light pressed from 4 ticks before his arrival until his blow lands | His blow is cancelled at the press. The light lands as a skill strike ×1.25 and staggers him 12 ticks. The zip ends `countered` and the brawl is announced with the rival as its starter |
| **The heavy counter** | A heavy whose wind-up ends from 6 ticks before his arrival until his blow lands. Against a zip heavy, a tapped heavy pressed at the tell is in time | His blow is cancelled. The heavy lands in full and knocks him back, which is decisive. The zip ends `countered`. No brawl |
| **A mashed light** | A light within 12 ticks of the rival's last press | No counter. Landing on him, it catches him |
| **A catch** | Any blow of the rival's that lands on him in reach and isn't a counter | His way out is lost. The zip ends `caught` and the brawl is announced. If his own blow was still to come it is pushed back by his reel and lands as a brawl blow at its zip worth |
| **Too early, too late** | A light pressed more than 4 ticks before the arrival meets nothing. A heavy whose wind-up ends earlier leaves the rival in its recovery. A heavy that lands after he has left meets nothing | |
| **A dodge away** | The rival leaves by the brawl's own rule as he arrives | His blow misses, and he still leaves by his exit |
| **A shot** | Fired during the tell or the way in | Section 1 |

The rival presses these where he stands. While a zip is aimed at him his light or heavy press is kept for the arrival and never starts a lunge of his own.

## 4. The AI

| Choice | Rule | Per level (`ai.json`) |
| :--- | :--- | :--- |
| **It zips** | At an attack beat in the mid band, with 10 ki to spare. Not from the band's outer 3 bh, where a drifting rival outruns it. Not at a rival who has pressed an attack in the last 30 ticks: a masher's blows catch a zipper | `zipShare` 0.08, 0.25, 0.4; `stringLapseTicks` (existing) |
| **The heavy** | A share of its zips | `zipHeavyShare` 0.2, 0.3, 0.35 |
| **Its exit** | Back. At a share: the far side, above, or away | `zipExit` 0, 0.3, 0.6 |
| **Its answer** | One draw when it sees the tell: the counter, the dodge on the arrival, or the guard at the rate it guards any approach | `zipCounter` 0, 0.2, 0.35; `zipDodge` 0, 0.1, 0.15; `approachReact` (existing) |
| **Its counter** | Against a zip heavy, a heavy if its wind-up can end in the window. Otherwise a light two ticks before the arrival | |
| **Its punish** | Once the zipper's blow has resolved, a light at a share. It catches him if it lands before he leaves | `zipPunish` 0.2, 0.75, 0.95 |

It writes the press a player makes: LT held with X or Y, and the stick for its exit. It zips in the speed reading only.

## 5. For Animation, Camera, UI and QA

**The read is the truth** (`docs/animation/zip.md` sections 9 and 12). `DirZip.read(S, f)` is empty when `f` isn't zipping. Otherwise: `reading` (speed, tech, heavy), `btn` (x, y), `phase` (tell, in, reach, out), `n` (live ticks since the phase began) and `len`; `tell`, `in`, `hits` (1), `hd` (the ticks in reach), `out`, `lift` (0); `blow` (0 before his blow, 1 after); `via` (back or run), `pass`, `entry_in` and `entry_out` (empty); `dist_bh`; `exit` (home, far, point; empty until his blow lands) and `x`, `y`.

| Cue | When | Fields |
| :--- | :--- | :--- |
| `zip_light`, `zip_heavy` | The tell starts | `target`; `amount` the tell's ticks; `n` the way in; `dur` the whole zip with the default exit; `x` and `y` the ticks in reach before his blow and after it, as planned at the press |
| `zip_out` | His blow lands | `text` the exit kind; `x`, `y` the exit point; `n` the way out's ticks; `amount` the ticks he was in reach before his blow and `dur` the ticks he stays after it; `k` the reading (0 speed, 1 tech, 2 held). It comes 6 or 10 ticks before the way out begins. QA's table test reads the ticks here: a held zip strike is in reach 8 ticks before its blow, which is known only as the tell ends |
| `zip_end` | Every zip | `text`: `done`, `stopped`, `outrun`, `shot`, `down`, `caught` or `countered` |
| `brawl_start` | He is caught or countered by a tech strike or a perfect block | `actor` the rival; `text` `caught` or `countered` |
| `press_ack` | | `zip` (a zipper's own press, spent), `answer` (the rival's press, kept for the arrival), `zip_no_ki` (the press became the plain lunge), `zip_refused` (not free to act) |
| `stagger` | | Two new texts: `zip` (a zip heavy landed) and `counter` (the tech counter landed) |

- **The ticks in reach run on the brawl's lines with no brawl announced.** For those ticks `DirBrawl.inBrawl` is true, and the zip's blow is a brawl strike beat in `S.dirS.ex.beats` with `zip` true, `style` the reading and `read` its index. A zip that leaves sends no `brawl_start` and no `brawl_end`. Anything that keys off `DirBrawl.inBrawl` sees a zip's 10 or 22 ticks in reach as a brawl; `DirBrawl.quiet(ex)` tells them apart.
- **The exchange events fire for those ticks:** `attack` on the arrival, with the tag `ZIP`, and `exchange_end` when he leaves. So a zip that arrives counts as an exchange started.
- **Two queries:** `DirZip.zipping(f)` and `DirZip.untouchable(f)` (true on the way out).
- **Nothing running:** `brawl_probe.gd` counts a zip's ticks as running from its tell.
- **For QA's hard tests:** a home exit can be inside a building's reach when he started there. The rule sends him back where he started, so the "never inside a building" test exempts home (the EP's ruling).
- **Second breath:** the zip's tell restarts the zipper's wait, as any approach of his own does.

## 6. How it is built

- `sim/director/zip.gd` (new): the phases, the exit, the answers, the read, and the AI's use and answers. Its state is integers after the brawl's in the fighter's own list, 67 a fighter with Controls' 37-integer sample ring. Nothing is shared.
- **One other value moved:** medium's `brawl.rashHeavy` 0.33 to 0.3, for the masher's band on the retune base (section 8).
- `sim/director/exchange.gd`: `DirZip.takes` after the brawl's in `requestAttack`; `DirZip.tick` after the approaches; `startZip`, which makes the exchange the ticks in reach run in; no request starts against a fighter on his way out.
- `sim/director/brawl.gd`: `beginQuiet`, `quiet` and `announce`; `blowAt`, a blow put on a line by rule; a zipper's press in reach is spent; no `brawl_end` for a brawl that was never announced; the zip's hooks where a blow is thrown and where it lands; the rival AI's ticks in reach.
- `sim/director/blast.gd`: a shot against a zipper. `sim/director/ai.gd`: three hooks.
- `sim/director/tools/zip_probe.gd` (new): the rows and the hard tests. `brawl_probe.gd`: a zip counts as running.
- **New keys:** the top-level `zip` block in `interrupts.json`; six keys a level in `ai.json`: `zipShare`, `zipHeavyShare`, `zipCounter`, `zipDodge`, `zipPunish`, `zipExit`. Tools' `docs/tools/pending/apply-zip1.cjs` carries them, and it goes in the same commit. On a copy with it applied the data validates: 158 files, 0 errors, 0 warnings, and Tools' self-test passes.

## 7. Limits, and what is left

- **The rival's heavy answer is a tapped heavy.** A heavy held and let go on the arrival isn't modelled before he arrives, so against a zip strike the heavy counter needs a read.
- **Flow.** The tech reading's flow +1 isn't in. Flow isn't earned in a brawl until the skill strike (C3 in the second pass's order).
- **A shot on the way out** was checked by reporting one to the module on his third tick out. I couldn't time a real bolt to arrive in those ticks: while he is in reach the rival's energy presses are spent, as in any brawl.
- **The AI** zips in the speed reading only, and doesn't fire at a zipper on purpose.
- **Z2,** which now follows C1 to C6 (`docs/design/brawl-second-pass.md` section 10): the zip away and the AI leaving a brawl it is losing, the chase of a launch, the rushed zip heavy, the signature zip, piloted charges. Not in either: zip chains, the zip tackle, the exhaustion state.

## 8. Rows

Measured on a scratch copy of 07f5652 (Simulation's retune) with this slice. The tree's ten files are byte for byte that copy's. The tree was at 3b2a704 when the slice went in: between the two, nothing under `sim/` or `data/director/` changed, and one of Animation's data files did (`data/anim/ragdoll_motion.json`). QA's harness is `node qa/run-godot.js`, four arms, 100 matches an arm, 3 jobs: 120 bands pass, 21 fail and 21 are pending; of its tests 7 pass and none fail. Every gate exits 0 on the copy: the goldens, parity, the loader check, determinism, the seam sweep, the cue check, Animation's check, the four input tests, the mash probe and `npm test --prefix sim`. In the tree, `npm test --prefix sim` passes all 5 stages and Animation's check passes; the other gates weren't run again there.

**The standing rows.**

| Row | Read | Band | |
| :--- | ---: | :--- | :--- |
| Match length, median: default arm and swap arm | 406.3 s and 407.3 s | 360 to 480 s | In |
| Match length, 10th percentile: each arm | 320.4 s and 289.9 s | at least 300 s | **The swap arm is under.** The harness reads the default arm |
| Match length, 90th percentile: each arm | 519.7 s and 541.0 s | at most 600 s | In |
| KAI over both slots | 51.0% (46.0% from P1, 56.0% from P2) | 45 to 55% | The point is in. The harness fails it on the interval, [44.1, 57.8] at 100 an arm |
| Masher at an 8-tick gap on `S.tick` against the easy, medium and hard AI | 94, 45 and 0 of 100 | at least 60%; 35 to 50%; at most 15% | In |
| The same masher at 6 and 10 ticks against medium | 53 and 33 of 100 | reported | |
| Bolt-only against medium | 25 of 100 | 20 to 40% | In |
| The mixed blaster against medium | 35 of 100 | 30 to 50% | In |
| The slow blaster against medium | 2 of 100 | reported | |
| Blasts' share of damage | 9.3% [8.8, 9.8] | 10 to 25% | **Out** |
| First brink, median | 333.4 s | 270 to 420 s | In |
| Brink to KO, median | 62.2 s | 45 to 90 s | In |
| Finisher survival | 32.0% | 25 to 40% | In |
| Launches of the exchanges that separate | 28.3% | 25 to 40% | In |
| Limb breaks a match, and the arms' share | 0.41 and 53.7% | 0.3 to 0.5; 35 to 65% | In |
| Region breaks and rallies a match | 2.25 and 0.36 | 1.5 to 2.5; 0.3 to 0.7 | In |
| Second breath's share of battered wear | 21.0% | at most 25% | In |
| Mood: Calm, Tense and Frenzied shares | 31.8%, 60.8% and 7.4% | 20 to 40%; 40 to 65%; 5 to 20% | In |
| Acts 2, 3 and 4 start at | 96.3 s, 184.9 s and 302.2 s | 90 to 150 s; 150 to 240 s; 270 to 345 s | In |
| Frenzied share of act 4 | 14.0% | at least 15% | **Out** |
| Act 4 arrives before the first brink | 76.0% [66.8, 83.3] | at least 80% | **Out** |
| Perfect blocks a minute, medium AI | 2.53 | 1 to 4 | In |
| Civilians lost, and front-row structures lost | 18.0% and 31.3% | 12 to 30%; 25 to 50% | In |

**The zip's rows.** QA's harness, the AI against itself, 100 matches: 311 zips, 0.45 a minute, 215 zip strikes and 96 zip heavies.

| Row | Read | Band | |
| :--- | ---: | :--- | :--- |
| Zips whose blow lands clean | 47.9% [42.4, 53.5] | 35 to 55% | In |
| Zips countered by a tech or heavy strike | 19.0% [15.0, 23.7] | 10 to 25% | In |
| Zips that end with the zipper caught | 32.8% [27.8, 38.2] | 20 to 35% | The point is in. The harness fails it on the interval |
| Ki spent on zips, of all ki spent | 3.3% | at most 25% | In |
| Blocked; dodged; stopped by a shot; outrun; knocked down | 14.8%; 8.4%; 6.8%; 3.5%; 0 | reported | |
| How they ended | 118 done, 102 caught, 59 countered, 13 shot, 11 outrun, 8 stopped | reported | |
| The price, at the press | 311 of 311 on the table | a hard test | Passes |
| The tell and the whole length | 311 of 311 | a hard test | Passes |
| The ticks in reach before and after the blow | 221 played zips and 311 plans | a hard test | Passes |
| Travel never under Legal's floor, each way | 311 of 311 | a hard test | Passes |
| No stick exit over 12.5 bh, in the ground or in a building | 51 exits checked; 260 home exits exempt | a hard test | Passes |
| No brawl announced in a zip unless he is caught or countered | 0 over 311 | a hard test | Passes |
| A player who only zip strikes, against medium | 27 of 100; 668 zips: 349 done, 104 stopped, 97 countered, 60 caught, 50 shot, 8 outrun | reported | |

**My probe's rows** (`zip_probe.gd` and `brawl_probe.gd`). A scripted zipper presses a zip every 90 ticks when he can.

| Row | The zipper, both buttons, 30 matches | The zipper, strikes only, 20 matches |
| :--- | ---: | ---: |
| Zips | 269 | 194 |
| The blow lands clean | 36.1% | 37.1% |
| Countered | 13.0% | 14.4% |
| Caught | 21.6% | 28.4% |
| The zipper wins against medium | 0 of 30 | 1 of 20 |

- **The zipper with both buttons:** 14.5% blocked, 8.9% stopped by a shot, 27.1% ended `stopped`, and zips were 24.6% of the ki he spent.
- **The AI against itself:** 0.49 zips a minute, a mean match of 427.7 s, a brawl's median 2.85 s and 90th percentile 7.67 s, 28.0% of fight time in a brawl, and 10.3 s a minute with nothing running. QA's harness reads the same things at 2.9 s, 7.6 s and 27.9%, with 28 blows in a median brawl.
- **The two pressers against medium, 20 matches each at an 8-tick gap.** Lights only: a brawl's median 8.88 s, 90th percentile 48.2 s, 70.5% of fight time, 9 wins. The mixing presser: 2.97 s, 10.22 s, 59.7%, 7 wins.
- **How the AI's brawls end** (harness): knock-back 64.9%, signature 19.7%, launch 10.6%, break 2.5%, idle 2.2%.
- **A minute of an AI match** (harness): 4.5 brawls, 167.4 blows, 2.4 closes.
- The hard tests in my probe: 0 failures on both scripts and on the AI.

**What is out, and what I know about each.** I didn't run the harness on 07f5652 without the slice, so I can't say from my own run which of these the zip moved.

- **The AI's share of fight time in a brawl, 27.9%,** against the 30% that section 9f set for after the zip. The zip was expected to lift it. It reads 25.2% in B1c's chain, on a different base, so the two aren't a clean before and after. At 0.45 zips a minute with a third of them caught, the catches alone add about one brawl every 7 minutes, which is too few to move the share.
- **Blasts' share of damage, 9.3%.** It read 10.4% in B1c's chain. The EP's rule was not to move `barrageGuard` or `heavyApproachShare` unless a row asked. This one asks, by 0.7 of a point. I didn't move them: it needs a second chain, and bolt-only (25) and the mixed blaster (35) move with them. Medium's `barrageGuard` is the lever.
- **The swap arm's 10th percentile, 289.9 s.** It was 279.3 s in B1c's chain.
- **The Frenzied share of act 4, 14.0%, and act 4 before the first brink, 76.0%.** Both are mood rows on Simulation's retune. I moved nothing in the mood.
- **Zips that end caught, 32.8%.** The point is in the band and the interval's top is over it at 311 zips. The lever is each level's `zipPunish`.
- **KAI over both slots** fails on the interval only, as it does at 100 matches an arm.
- **The rest of the 21** aren't the zip's: the rows counted for each exchange (9.98 started a minute, knock-backs 50.5%, "continues" 29.5%), six launch-journey rows and brunts, the lock-break's median, timeouts on the interval, the two blast scripts against the rush-heavy script, and the blur's link-following script.

**The zip-strike-only player wins 27 of 100 in QA's script and 1 of 20 in mine.** The two scripts differ: QA's zips 6.7 times a match and mine 9.7, and 15.6% of QA's zips end `stopped` against 27.1% of my two-button zipper's. I haven't compared them further. The spec gave no band, and the row is reported.
