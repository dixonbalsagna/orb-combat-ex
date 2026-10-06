# Brawl slice C1: control and the even mash

Owner: Encounter Systems Director. Date: 2026-10-06. Status: applied to the tree and frozen, waiting for the EP's commit. Parked sources: `docs/director/pending/brawl-c1/` (`bash apply.sh <root>` rebuilds the slice on 197592a1 or later, while the seven files it edits are HEAD's; the goldens are regenerated after it). Spec: `docs/design/brawl-second-pass.md` sections 1 and 7, with the rulings "the centre and what is in its way" and the walk-out's guard. Cut: `brawl-plan.md` section 9. It follows the zip's first slice (`zip-z1.md`).

## 1. What it does

**The stick moves the brawl.** A brawl has a centre, the point midway between the two, and both sticks move it.

| Thing | Rule in C1 | Number (data, the `brawl` block) |
| :--- | :--- | :--- |
| **A stick's rate** | His stick, by how far it is pushed, times 0.4 of his own free-flight speed in the neutral stance. For the Protagonist that is 172 units a second, 2.3 bh | `nudgeMul` |
| **Two sticks** | They add. Two who agree move the brawl at about 0.8. Two who oppose cancel, and the faster flyer wins the difference: 9 units a second between the launch pair | |
| **The ramp** | Each stick goes through Controls' ramp (`SimAim.nudge_ramp`): a fresh push starts at 0.4 of its rate and is full 11 ticks later; an analogue stick moved gradually passes unchanged | `aim.nudgeStart`, `aim.nudgeTicks` (Controls' data) |
| **Smoothness** | The centre's own speed follows the sticks by at most a full nudge over 8 ticks, up and down. So letting go brakes over 8 ticks and doesn't stop dead | `nudgeRampTicks` |
| **The cap** | The pair never moves more than 0.3 bh in a tick, the ground's lift on a slope included | `maxStepBh` |
| **By his state** | Striking, charging or reeling from a light: full. Guarding with no blow of his own on its way: 0.6. Staggered: none | `nudge.guard` |
| **The carried speed** | Half of the two velocities added as they meet carries on as drift and fades to nothing over 20 live ticks. An attacker who came in by a lunge counts at his own flight speed along his line | `carryShare`, `carryTicks` |
| **The attraction** | Unchanged: the pair's gap is held at striking distance, at one height. One change: when the higher fighter stands on the ground, the other comes up to him at once, so a pair on a slope stays level | `pullBhPerSec` (existing) |
| **A building** | A step may not bring the pair's middle within 0.5 bh of a standing building's box. The part of the step along the face carries on, so the brawl slides along a wall, and a nudge upward takes it over the roof. No damage, no pin, no bonus | `nudge.clearBh` |
| **The ground and a ridge** | The core holds a fighter on the ground, so the brawl slides along it. A slope too steep to climb inside the cap stops the step across; a nudge upward goes over | |
| **Walking out** | Both sticks held away, each within 45 degrees of straight away from the rival, for 12 full live ticks running. The brawl ends `walk` 12 ticks after the tick the later stick was first read, never sooner: free, nobody decisive, nothing to wait for. Each leaves with the speed he had | `partTicks`, `partDeg` |
| **What stops the count** | A blow of either on its way or kept, an attack button down, a reel or a stagger. A guard doesn't | |

**The even mash.**

| Thing | Rule in C1 | Number |
| :--- | :--- | :--- |
| **A lead in the trade** | At 120 ticks a lead of 2 takes the close, as before. After 120 a lead of 2 takes it on the tick it appears | `flurry.tradeMaxTicks`, `levelWithin` (existing) |
| **A level trade** | It goes on. The seeded draw, `flurry.momentum` and the last closer's slot are gone | |
| **The double hit** | A trade still level at 240 ticks. Both lines are cleared and each throws one blow that can't be blocked, turned or dodged. The two land on the same tick, 8 live ticks later | `flurry.doubleTicks`, `double.windupTicks` |
| **Its worth** | 4 brawl lights to each | `skillMul` (existing) |
| **Nothing calls it off** | From the cue to the contact, attack presses are spent (`press_ack` `double`), and neither can dodge, escape, burst or reverse. The mood takes its 480 units on the cue's tick, so the double hit has to be certain by then | |
| **What follows** | Both are thrown back 6 bh from the centre, opposite ways, over 24 live ticks after the blow's hit-stop: an upright slide on the ground, a drift in the air. No wear from the throw. Nobody is decisive. The brawl ends `double` | `double.throwBh`, `double.throwTicks` |

## 2. The AI

| Choice | Rule | Per level (`ai.json`, the `brawl` block) |
| :--- | :--- | :--- |
| **Its nudge** | One draw with each choice it makes. It presses toward the rival as it starts a string and gives ground as it guards, and holds that until its next choice | `nudgeShare` 0.35, 0.5, 0.65 |
| **By `care`** | A fighter whose `care` isn't 0 takes the brawl away from the more peopled side, or toward it when his `care` is negative, in place of the rule above. Both launch fighters have `care` 0.0, so this is dormant | |
| **Its walk-out** | The first time in a brawl that a player holds away, and it has no blow of its own on the way, it weighs once whether to hold away too. If it does, it presses nothing for up to 24 ticks. If it stays, it stays for that brawl: moving the stick again draws nothing | `walkOut` 0.1, 0.2, 0.3 |
| **Two AIs** | They never walk out. The ground an AI gives as it guards moves the centre and is no offer to part: when it was, two AIs that guarded together parted about four times a match | |

- **The AI's nudge is not in its intent.** A stick in the intent also leans a fighter's blows and tilts his launches (every press records it). The AI's presses would all have carried its nudge as a tilt, and its launches would have gone sideways. So its nudge is a number of its own, and the brawl's movement reads `DirBrawl.stick(ex, f)`: a player's own stick, or the AI's nudge. Its blows and launches are as they were.
- Its draws are keyed (`SimRng.keyed`), so they take nothing from the match's own stream.

## 3. For Camera, Animation, VFX, Audio, UI and QA

| Cue | When | Fields |
| :--- | :--- | :--- |
| `double_hit` | The two blows are thrown, 8 live ticks before they land | `actor` and `target`: the two slots. `text` `both` and `k` 3: who is hit, by bits (1 the cue's fighter, 2 its target). `n` the `S.tick` they land. `amount` the ticks ahead. `dur` the level trade's length. `x`, `y` the centre |
| `brawl_end` | | Two new texts: `walk` and `double` |
| `trade_break` | A lead takes the close | `text` is always `lead` now. `k` is no longer set. `n`, `amount`, `x` and `y` as before |
| `knockback` (the core's event) | Each of the two slides after a double hit | `attacker` -1; `kind` `slideShort` on the ground or `drift` in the air; `amount` the distance; `n` the tick it ends |
| `press_ack` | | New texts: `empty` (a cell with no move: RT with X, Y or A, and A alone with no guard held outside the energy family) and `double`. `source` is the button's cell on every ack that has one: `empty`, `double`, `held`, `lapsed`, `energy`, `refused` (b), and the zip's four |

- **The centre:** `DirBrawl.centre(S, ex)` returns `x`, `y` (the point midway between the two), `vx`, `vy` (the speed the pair moves at on the next tick, in units a second), `part` (the ticks running for which both have held away; the walk-out comes at 12) and `double` (the live ticks until a double hit lands, or -1). It is empty when `ex` isn't a running brawl. It also answers for a zip's ticks in reach, where the centre doesn't move.
- **The fighters' own `vx` and `vy` are the drift,** over what the core's locked damping keeps. Both fighters carry the same velocity, and it is set again after every blow, because a strike places its attacker and stops him.
- **`DirBrawl.doubling(ex)`** is true from the cue to the contact. **`DirBrawl.stick(ex, f)`** is the stick the movement reads from `f`: for a script that wants to know whether the AI is nudging, since its intent's stick stays at rest.
- **The two blows of a double hit** are brawl strike beats with `double` true, `sure` true and `style` `tech`.
- **Hit-stops hold the pair** as they hold everything. A lights flurry at an 8-tick gap freezes 2 ticks in 8, so "the centre moves within 2 ticks of a stick" is 2 live ticks.

## 4. How it is built

- `sim/director/brawl.gd`: `_move` (the sticks, the ramp, the carry, the cap, the building test, the slope), `carryOn`, `centre`, `doubling`, `_parting`, `_double`, `_thrownApart`, `_aiNudge`, `_aiStick`; `_tradeTick` without the draw; `begin` keeps the carry; `over` stops the drift of two who stay locked, except after a walk-out; the cell on the acks. Thirteen new integers a fighter, after the brawl's 37: the two axes of his ramp, the centre's speed, the carry, the velocity given, the walk-out's count, the double hit's count, and two for the AI. The last closer's slot is now the double hit's landing tick.
- `sim/director/exchange.gd`: the drift set again after a brawl's blow; and the zip fix below.
- `sim/director/interrupt.gd`: no reversal and no burst while a double hit is on its way; `press_ack` `empty`.
- `sim/director/zip.gd`: the cell on the zip's four acks; and the zip fix below.
- **A hole from Z1, closed here.** QA's hard test "no brawl is announced during a zip unless he is caught or countered" failed twice in 400 matches on this slice's first chain. When the rival dodged away from a zipper in reach, the zip's ticks in reach ended under him, and for one tick he was neither in reach nor on his way out: a press of the rival's on that tick started a plain brawl with him. The code is Z1's, and Z1's chain happened not to hit it. Now no request starts against him on that tick (`DirZip.leaving`), as none does on his way out.
- `sim/director/tools/brawl_probe.gd`: `--stick=`, and the rows of section 5.
- **No core lines.** It uses Simulation's three reads (`SimFighter.flightSpeed`, `lockedKeep`, the mood's `double_hit`) and Controls' `SimAim.nudge_ramp` and `nudge_units`.
- **New keys,** in `interrupts.json` `brawl`: `nudgeMul` 0.4, `nudgeRampTicks` 8, `nudge` {`guard` 0.6, `clearBh` 0.5}, `maxStepBh` 0.3, `carryShare` 0.5, `carryTicks` 20, `partTicks` 12, `partDeg` 45, `flurry.doubleTicks` 240, `double` {`windupTicks` 8, `throwBh` 6, `throwTicks` 24}. **Removed:** `flurry.momentum`. In `ai.json`, each level's `brawl` block: `nudgeShare` and `walkOut`. Tools' `docs/tools/pending/apply-brawl-c1.cjs` carries them and goes in the same commit. On a copy with both applied the data validates: 164 files, 0 errors, 0 warnings, and Tools' self-test passes (4,856 of 4,856). Without Tools' script the validator reports 17 errors, all for these keys.
- **No existing value moved.**

## 5. Rows

Measured on a scratch copy of 3ea55dea with this slice, one Godot job at a time (QA's baseline had the machine). The tree's eight files are byte for byte that copy's. QA's harness is `node qa/run-godot.js`, four arms, 100 matches an arm, `--jobs=1 --masher=0`: 92 bands pass, 19 fail and 20 are pending; of its tests 7 pass and none fail. Its masher stage starts up to seven Godot jobs at once whatever `--jobs` says, so those rows were run one at a time through QA's own scripts and specs (`qa/godot/masher.gd`, `players.gd`). Every gate exits 0 on the copy: the goldens, parity, the loader check, determinism, the seam sweep, the cue check, Animation's check, the five input tests, the mash probe, World's probe, UI's HUD check and `npm test --prefix sim`. Main moved while the chain ran (to b0c01944: view, VFX and Animation data only under `sim/` and `data/`). On a clean copy of b0c01944 with the slice the regenerated goldens are byte for byte the measured copy's, and `npm test`, Animation's check, the cue check, the HUD check and World's probe pass. In the tree `npm test --prefix sim` passes all 5 stages; Controls' uncommitted work under `sim/input` was in the tree at the time.

**Two lines changed after the first pass,** and what was run again. The first pass (rows, arms, gates) ran with the walk-out ending on the twelfth tick and without the zip fix. The walk-out's count only acts when both fighters offer to part, and the zip fix only when a zipper's rival dodges away from him in reach. So the four arms and every gate were run again on the final code, with the zip pair and my probes; the goldens came out byte for byte the same; and the masher against medium, run again as a check, read the same 41 of 100. The other masher, blaster and mirror rows are the first pass's: none of their scripted players holds a stick away or dodges.

**The standing rows.**

| Row | Read | Band | |
| :--- | ---: | :--- | :--- |
| Match length, median: default arm and swap arm | 427.5 s and 415.7 s | 360 to 480 s | In |
| Match length, 10th percentile: each arm | 310.1 s and 305.2 s | at least 300 s | In |
| Match length, 90th percentile: each arm | 564.0 s and 545.2 s | at most 600 s | In |
| KAI over both slots | 55.0% (54.0% from P1, 56.0% from P2) | 45 to 55% | At the top edge, and the harness fails it. The interval is [48.1, 61.7] |
| Masher at an 8-tick gap against the easy, medium and hard AI | 91, 41 and 0 of 100 | at least 60%; 35 to 50%; at most 15% | In. They were 94, 45 and 0 |
| The same masher against medium on seeds 101 to 200 | 37 of 100 | | Main reads 46 there. Over both sets: 39% with this slice, 45.5% without |
| The masher at 6 and 10 ticks against medium | 42 and 16 of 100 | reported | They were 53 and 33 |
| Bolt-only against medium | 23 of 100 | 20 to 40% | In |
| The mixed blaster against medium | 42 of 100 | 30 to 50% | In |
| The slow blaster; the zip-strike-only player | 0 and 22 of 100 | reported | |
| Blasts' share of damage | 9.6% [9.0, 10.1] | 10 to 25% | **Out.** The EP's ruling: leave it for QA's next baseline |
| First brink; brink to KO | 344.9 s; 70.1 s | 270 to 420 s; 45 to 90 s | In |
| Finisher survival | 32.4% | 25 to 40% | In |
| Launches of the exchanges that separate | 28.4% | 25 to 40% | In |
| Limb breaks a match, and the arms' share | 0.41 and 51.2% | 0.3 to 0.5; 35 to 65% | In |
| Region breaks and rallies a match | 2.40 and 0.44 | 1.5 to 2.5; 0.3 to 0.7 | In |
| Second breath's share of battered wear | 21.2% | at most 25% | In |
| Mood: Calm, Tense and Frenzied shares | 31.9%, 60.9% and 7.2% | 20 to 40%; 40 to 65%; 5 to 20% | In |
| Acts 2, 3 and 4 start at | 94.9 s, 176.8 s and 297.1 s | 90 to 150 s; 150 to 240 s; 270 to 345 s | In |
| Frenzied share of act 4 | 13.7% | at least 15% | **Out,** as before |
| Act 4 arrives before the first brink | 77.0% [67.8, 84.2] | at least 80% | **Out,** as before |
| Perfect blocks a minute, medium AI | 2.38 | 1 to 4 | In |
| Civilians lost, and front-row structures lost | 20.1% and 36.8% | 12 to 30%; 25 to 50% | In |
| The AI's share of fight time in a brawl | 27.6% | 30 to 50% | **Out,** as before (27.9%). The EP's ruling: leave it |
| A brawl's median, 90th percentile and blows, the AI against itself | 3.0 s, 8.1 s and 29 | 2.5 to 6 s; at most 20 s; 10 or more | In |
| The zip's rows: clean, countered, caught, zip ki | 49.7%, 16.2%, 32.4%, 3.1% | 35 to 55%; 10 to 25%; 20 to 35%; at most 25% | In. Caught fails on its interval, as before |
| The zip's six hard tests | 296 zips | | All pass. The first pass failed one (section 4) |

**The rows C1 owns** (the second pass's section 11).

| Row | Read | Band | |
| :--- | ---: | :--- | :--- |
| The centre answers a stick | It moves on the tick after the stick is first read: 0.005 bh on that tick, 0.01 on the next, and all of its speed 12 live ticks after a fresh full push | within 2 ticks (a hard test) | In, on live ticks. In a hit-stop no input is read: a light's is 2 ticks, a heavy's 6 |
| The step the director gives the pair in a tick | at most 0.300 bh, over every probe | at most 0.3 bh (a hard test) | In. The pair's middle itself: see section 6 |
| How far a held stick moves a brawl against a rival who holds none | 2.3 bh a second for the Protagonist (172 units, traced) and 2.2 for the rival, less the ticks in hit-stop. A lights flurry at an 8-tick gap freezes 2 ticks in 8, which leaves about 1.7 by the arithmetic | reported | |
| A brawl's drift with a presser who holds toward the whole time | median 17.1 bh a brawl, 90th percentile 65 bh | reported | His brawls are long: median 10.1 s |
| A brawl's drift, the AI against itself | median 3.9 bh, 90th percentile 11.7 bh; the centre moves on 73% of a brawl's ticks; each AI holds a nudge on about 47% | reported | |
| Double hits a match, the AI against itself | 0 in the harness's 100 default-arm matches and in my 24 | 0.5 to 2; at least one in 40 to 70% of matches | **Out** |
| Every trade still level at 240 ticks ends in a double hit | 427 double hits in the even mirror, 95 in the uneven one, 10 with my pressers | a hard test | Passes on my probe: no level trade was seen older than 239 ticks without a double hit on its way. The traced cue's `dur` is 240 |
| The even lights-only mirror (8 against 8, `S.tick`) | 20 of 20 finish; first slot 13; median 164 s; brink to KO 53.9 s; 21 double hits and 14 closes a match | retired; reported | **It is not a stalemate as built** |
| The uneven mirror, 8 ticks against 10 | 60 of 60 finish; the faster tapper wins 60; brink to KO 30.8 s | at least 95%; at least 80%; 25 to 50 s | In |
| Walk-outs, the AI against itself | 0 | | By rule |
| A walk-out between two players | 12 ticks after the later stick is first read, in each of 3 traced | never under 12 (QA's row) | In |

**Why no double hits between AIs.** A level trade has to last 240 ticks, and an AI's string is 3 to 5 blows and then a heavy or a guard. In two sets of twelve AI matches, 17 and 18 level trades reached 120 ticks, 0 and 6 reached 150, 0 and 3 reached 180, 0 and 1 reached 210, and none reached 240. (The second set, seeds 101 to 112, was read before the zip fix.) So the lever, `flurry.doubleTicks`, would have to come down to about 120 to 130 for one a match, which is the every-two-seconds case the spec set 240 to avoid. Against a pressing player it is different: a lights-only presser saw 6 in 20 matches and the mixing presser 4.

**The trade's two old rows need re-basing.** A break is always for a lead now, and it can come any time after the limit: the latest seen was 17 ticks after it (QA's row allowed 12). And 137 of 1,256 breaks in the zip pair were not followed by a close within 24 ticks, where the old hard test read 0: a lead of 2 tends to appear as the other fighter stops landing, and then the trade lapses before the close. In both mirrors that count is 0.

**My probe's rows** (`brawl_probe.gd`), against the medium AI, with the zip slice's reading beside each.

| Row | The AI against itself, 12 matches | Lights only, stick toward, 20 | The mixing presser, 20 |
| :--- | ---: | ---: | ---: |
| A brawl's median | 3.18 s (2.85) | 10.1 s (8.88) | 3.28 s (2.97) |
| A brawl's 90th percentile | 7.9 s (7.67) | 43.6 s (48.2) | 10.28 s (10.22) |
| Share of fight time in a brawl | 31.7% (28.0%) | 71.3% (70.5%) | 59.9% (59.7%) |
| Nothing running, a minute | 9.4 s (10.3) | 2.4 s | 3.3 s |
| The presser wins | | 13 of 20 (9) | 5 of 20 (7) |
| Double hits | 0 | 6 | 4 |

- The AI against itself on seeds 101 to 112 reads 27.7% of fight time in a brawl, where main reads 28.7% (read before the zip fix).
- **How the AI's brawls end** (harness): knock-back 63.6%, signature 20.3%, launch 11.1%, break 2.6%, idle 2.4%, apart 0.1%, double 0.
- **A minute of an AI match** (harness): 4.3 brawls, 165.2 blows, 2.5 closes, 0.1 trade breaks.

**What is out, and what I know about each.**

- **Double hits in AI matches, 0.** Above. The lever is Game Design's.
- **KAI, 55.0%.** It read 51.0% on the zip slice's chain. Its interval at 100 an arm is 14 points wide, and nothing in this slice treats the two fighters differently except their flight speeds in a tug of war.
- **Blasts' share, the AI's brawl share, the Frenzied share of act 4, act 4 before the first brink:** all four were out on the zip slice's chain by about the same amounts.
- **The beam escape rate against an escaping defender, 18.3% [11.4, 28.0]** against 20 to 50%. It wasn't failing on the zip slice's chain. Nothing here touches a beam; the interval is 17 points wide.
- **Launches that pick a building, 39.2% [32.2, 46.7]:** the point is in, and it fails on the interval.
- **The rest of the 19** were failing before and aren't this slice's: the rows counted for each exchange (10.13 started a minute, knock-backs 50.0%, "continues" 30.2%), brunts and four launch-journey rows, the lock-break's median, timeouts and zips caught on their intervals.

## 6. Limits, and what is left

- **The double hit lands where the core picks.** The spec says on the head. A blow's wound region is picked in the core by its family, and no blow can name one. It needs one option on the core's hit from Simulation.
- **The mood takes more than the clash's 480.** The two slides are `knockback` events, and the mood adds its knock-back units (180) for each, to no fighter. Either the mood skips a knock-back with no attacker, or the 840 stands.
- **A double hit can still be lost to the world.** No press of either fighter stops it. A shot already in the air that staggers one of them doesn't either: his blow lands all the same. A shot that throws one of them out of reach in those 8 ticks does, and the mood has taken its units by then. I haven't seen it happen.
- **A pair inside a building's box moves freely.** Free flight passes buildings, so a brawl can begin inside one. The test counts every building within the blasts' depth of the fight's plane, as the zip's exit does. In AI matches the pair's middle is inside a box on 0.3 to 1.5% of a brawl's ticks (two sets of twelve matches).
- **The cap is on the drift.** A strike still places its attacker at striking distance in one tick, as it did before this slice, and when the two had come apart inside a brawl that is a jump: the pair's middle moved more than 0.3 bh on 0 and 2 ticks of two sets of twelve AI matches (about 85,000 brawl ticks each), on 1 tick of a presser's 145,000 and on none of the mixing presser's 126,000. The largest was 1.01 bh. I traced that one: the two were 2.7 bh apart inside a brawl, and a heavy that broke a guard placed its attacker at striking distance. How they come that far apart inside a brawl I haven't traced. A hard row that reads the centre's position will flag those ticks; one that reads `vx` and `vy` won't.
- **The nudge is the same rate up, down and across.** The core flies a fighter's vertical at 0.85 of his speed; the brawl doesn't copy that number.
- **`care` is 0.0 for both fighters,** so the AI's nudge by personality has nothing to read. It was traced once with a `care` set by hand.
- **Not in C1:** the double hit's close-up and its two poses a fighter; anything of the three strengths (C2a); the AI walking out of a brawl it is losing (Z2).
