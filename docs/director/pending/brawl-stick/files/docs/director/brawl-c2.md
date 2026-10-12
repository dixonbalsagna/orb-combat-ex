# The brawl, slices C2a and C2t with the heavy's hold: as built

Encounter Systems, 2026-10-06. The design is `docs/design/brawl-second-pass.md` sections 1 to 3 and 5b; the cut is `brawl-plan.md` section 10. This page says what the code does. Where it differs from the design page, the difference is listed under Decisions. The follow-up tune of 2026-10-11 (the design page's section 14) is in: section 11 lists what it changed.

Code, all in `sim/director/`: `brawl.gd` (most of it), `alchemy.gd` (the press log knows B and the buttons' levels), `exchange.gd` (B with no stance is the heavy; the tell's tick), `zip.gd` (answers by strength; the tech counter is an opening), `melee.gd` (a forced launch; a brawl's blow places its own attacker), `blast.gd` (a shot on a lunge), `launch.gd` (a launch starts the launcher's rest), `interrupt.gd` (no dodge while open), `recipe.gd` (a medium counts with the lights), `ai.gd` (the signature press holds a stance). Data: `data/director/interrupts.json` `brawl` and `zip.heavy.damage`; `data/director/ai.json`, each level's `brawl` block and `digInBy`.

## 1. Three strengths

| | X, the light | Y, the medium | B, the heavy |
| :--- | :--- | :--- | :--- |
| Press | `light` | `heavy` | `sig` with no stance held and the energy family off |
| Lands | 2 ticks | 12 live ticks | 28 live ticks |
| Worth, in brawl lights | 1 | 2.5 | 6 |
| Ki | 0 | 2 | 5 |
| A clean hit | A reel of 4 | A reel of 6 | He staggers 12 in place |
| Its flurry | Taps 6 to 12 apart | Presses within 16 | Presses within 34 |
| On a guard | Chips | Chips double | Staggers the blocker 12 (`guard_break`) |
| To the core | `light` | `medium` | `heavy` |

- **The core's weight** is the exchange's kind as the blow lands. The launcher and the charged heavy are heavies. The riposte's and the reversal's wound blows are mediums.
- **A wound blow** (a medium, a heavy) is announced when it is thrown, with its landing tick. Its wind-up counts live ticks.
- **The tap rule.** At the wind-up's end the button is read. Up: it lands. Down: it waits. Let go inside 4 ticks: it goes at once. A medium still down at 16 goes by itself, as a tap.
- **The heavy's hold.** Still down at 32 it charges, for 3 more ki; without them it goes at 32 as a tap. It is full at 44, with `charge_full`. It lands 4 ticks after he lets go, and by itself at 70. It is worth 8 to 10 by its charge. A clean hit below full knocks him back; at full it launches him.
- **Armour.** While a heavy winds or charges, a light does half and changes nothing else. A medium that lands before tick 20 ends it; after that it does its damage and nothing more.
- **A medium winding:** a wound blow that lands ends it. A light lands in full, adds to the run, and its reel waits until his blow has landed. A stagger ends any wind-up.
- **The run** counts in halves. A landed blow of any strength adds one point; a burst's blow adds half. The close comes at a run of 4, whatever lands it.
- **A press he can't pay for** throws the strongest blow he can pay for. A B without its 5 ki is a medium, in an opening too. A Y or a B without a medium's 2 ki is a light. It has no cue of its own: the blow's cue names what he threw.
- **The burst.** A light whose button is still down 16 live ticks after the press throws seven more by itself, landing at 18, 22, 26, 31, 37, 45 and 56 ticks from the press. Each carries its number, 2 to 8, on its beat.
- **On the Simple layout** a wound press whose button is already up when it arrives was wound by its hold, and lands 2 ticks later.
- **Out of reach,** Y is the heavy lunge landing as a medium, and B the same lunge landing as the heavy. The wind-up counts from the press, so most of it is spent on the way.
- **A shot on a lunge with a wound blow** stops it as it would stop that blow's wind-up: a bolt counts as a light, a heavy shot as a medium, a charged shot as a heavy.

## 2. Giving ground, reach, and the closing rule

- **Who may give ground:** the fighter whose rival is winding or charging, while he has no blow on its way or kept, no attack button down, and is neither staggered nor open after a miss. His guard may be up.
- **His stick moves him alone,** at 5 bh a second, and 0.6 of that behind a guard. A stick within 45 degrees of straight away backs him off: the gap opens by his whole step and no more, whatever the ground does under him. On a rising face he takes a shorter step along it. The gap never opens more than 2.4 bh past striking distance. At a building's face he goes up it by the same step.
- **The rival who winds follows** by the part of his stick that points at him, at 0.6 of the rate. The rest of that stick nudges the centre as before, and never opens the gap.
- **Reach, read as the blow lands:** a medium reaches 0.5 bh past striking distance, a heavy 1 bh, and a charged heavy up to 1.5 bh as it fills. Out of reach it misses: the cue `miss`, and he is open for 20 ticks. Open, he can't throw, guard, dodge or give ground.
- **No blow lands from beyond `contact.reach`,** 68 units of horizontal distance. A blow still beyond it once its attacker is placed misses, with the text `reach`. The blows that land by rule keep their guarantee: the B in an opening, the double hit's two, a zip's.
- **The gap a wound blow must reach is counted, not measured.** It is what the gap was as the wind-up began, plus every step the rival gives, less every step the winder follows. So the table of the design's section 1 holds on a slope as on the flat: out of an unfollowed tapped heavy from tick 16, never out of a followed one. A blow with no wind-up of its own keeps the measured distance.
- **The closing rule.** A press from a gap closes it as part of the blow. The blow lands 2 ticks later for each bh of gap, and never more than 4 later. A wound blow's wind-up begins when the gap is closed. The beat carries `close` (those ticks) and `gap` (in bh).
- **A wound blow steps through its reach** in its last ticks before the contact: one tick for a medium, two for a heavy, three for a charged heavy. So the hand has no gap left to bridge as it lands. What it steps is added back when the reach is read, so the reach is still the blow's own.
- **No fighter of a brawl moves more than 0.6 bh in a tick.** Each tick the code counts what the core has moved him and what he has moved alone, and a step in takes only what is left. A blow that lands places its attacker by that rule too.
- **Striking distance** is `contact.offset` in `data/combat/templates.json`, 58 units, for every blow. The sim reads no reach by piece.
- **A staggered player keeps half his nudge,** read from the stick as held (`heldMx`, `heldMy`).

## 3. The launcher

- **An opening** gives it: a stagger of 12 ticks or more from a flurry's close, a broken guard, a perfect block, or a zip's tech counter. A landed heavy's stagger and a reversal's don't.
- **In an opening his B always lands:** a wind-up of 14 ticks, worth 3, for 5 ki. It can't be blocked or turned, and the stagger is held until it lands.
- **It launches when a launch is ready on the rival.** The launcher rests on a fighter for 40 s of fight time after any launch of him (`launcher.restS`). While it rests, the same B knocks him back.
- **The cue `launcher_open` goes out only when a launch is ready.** No cue means the B will knock back. `launcher_close` follows it, with `used` or `lapsed`.
- **The stick aims a launch,** read once at the press: up, or toward the rival. The launch planner picks among its candidates that way. With no stick, with the stick away, and with the stick down on the ground, it is the planner's own pick.
- **Held past its 14 ticks** it loses the guarantee and is a heavy from there.
- **A B kept for it goes before an X pressed after it,** so a player who mashes on after the B still gets it.
- A heavy charged to full launches whatever the rest says, and is aimed the same way, by the stick at the release.
- `launcher.flightMul` is the launcher's share of a heavy's launch force (1 now).

## 4. Energy in reach

- With the energy family held, X is the point-blank bolt: contact at 2 ticks, worth 1, 1 ki, a reel of 4, one point of run. Mashed, it has the X flurry's pace and worth. Held, it is one bolt.
- Y is the blast: a wind-up of 12 ticks read as a medium's, worth 2.5, 8 ki.
- **The blast is an ender, and not an opener.** When his run is 2 or more as it lands (`blast.enderRun`), a clean hit knocks him back 4 bh and the brawl ends. That knock-back counts as half a set-up, as a close does (`blast.halfSetup`). With the stick away it sends him back past the attacker. Thrown cold it is a medium with a reel of 6 (`blast.reelTicks`): it adds its point to the run, and the brawl goes on.
- **Each is the blast's own hit in the core, with no exchange passed.** A guard takes it by the blocked shot's rule; clean, it spreads as a shot and cripples nothing. The mood reads the bolt as a light and the blast as a medium. On a guard the blast doesn't knock back.
- Against a heavy's armour the bolt is a light and the blast a medium.
- B with the energy family held is the beam, as before.
- One landing in 20 ticks, for both fighters together, carries `k` 1: it may take the full flash.

## 5. A signature's tell

The defender isn't frozen for it. Until the beam leaves, his stick moves him alone at the rate of giving ground, less behind a guard, for at most 2.4 bh in all. It is movement and nothing else: the outcome is still read from his stance and his answers, which he holds while he moves, and moving doesn't take him out of the beam. The AI does it against its level's `giveGround` share of the signatures it faces.

## 6. The AI

Each level's `brawl` block, easy, medium, hard:

| Key | What | Values |
| :--- | :--- | :--- |
| `tapGap`, `tapGapMax` | Each string of its lights has its own pace, drawn between the two | 12 and 12, 8 and 11, 6 and 6 |
| `mixMedium`, `mixHeavy` | A blow of its string is a medium, or a heavy | 0.002, 0.004, 0.006 and 0.001, 0.002, 0.003 |
| `breakGuard` | A heavy at a guard, inside a brawl | 0.06, 0.1, 0.18 |
| `heavyIntoFlurry` | A heavy into a running flurry of lights | 0.01, 0.01, 0.05 |
| `mediumIntoHeavy` | A medium into a rival's heavy while one still ends it | 0, 0.2, 0.5 |
| `burst` | A held X | 0.05, 0.08, 0.08 |
| `digIn` | Decided as a trade starts: it matches his pace for that trade, blow for blow, until the trade breaks or the double hit lands | 0.1, 0.3, 0.3, half as much again for the rival. Two AIs never both dig in to one trade (`digInBoth` false, beside `digInBy`): one of the two, drawn for the trade, may. It digs in only while the match has had fewer than 2 double hits (`digInMax`), and not within 45 s of fight time of the last (`digInRestS`) |
| `giveGround` | It backs off from a wind-up it sees, after its reaction time; and from a signature's tell | 0.05, 0.2, 0.4 |
| `follow` | It walks its blow after a rival who backs off | 0.3, 0.6, 0.9 |
| `launcher` | It throws its B in an opening | 0.15, 0.25, 0.6 |
| `charge` | It charges a heavy, and lets go within 8 ticks of the flash | 0.15, 0.15, 0.45 |
| `energy` | A light or a medium of its string is the bolt or the blast | 0.06, 0.12, 0.15 |

It throws a medium, or a light when a medium would be late, at a rival who is open after a miss.

## 7. Cues and reads

| Cue | Fields |
| :--- | :--- |
| `blow` | Text `light`, `medium`, `heavy`, `bolt`, `blast`, or `release`; `k` 1 for a flurry blow; `n` the landing tick; `source` `lunge` or `zip` when it is thrown on the tick its attacker arrived by one |
| `windup` | `start`: `source` the cell, `dur` the wind-up alone in live ticks, `n` the landing tick, `k` 1 for a B thrown in an opening. `charge`: `n` the tick of the flash. `end`: `k` 1 thrown, 2 stopped by a blow, 3 lost to a stagger or the brawl's end, 4 a miss |
| `charge_full` | As the charge fills |
| `burst` | `start`, and `end` with `k` the blows |
| `miss` | The swinger is the actor, the rival the target. Text `gave_ground`, or `reach` (also a blow still beyond 68 units once placed); `source` the cell; `n` the ticks he is open |
| `launcher_open`, `launcher_close` | Open, only when a launch is ready: the actor may launch, `target`, text the opening's kind, `n` the tick it is due to end. Close: text `used` or `lapsed` |
| `energy_reach`, `energy_land` | Text `bolt` or `blast`. Reach: `n` the landing tick, `x` and `y` the stick. Land: `source` `hit`, `guard`, `armour` or `miss`; `k` 1 for the full flash |
| `double_hit` | As in C1, with `x` and `y` the centre |
| `press_ack` | As before, and `lapsed` with source `x` for a light dropped behind a B kept for an opening |
| `charge_stopped` | Text `lunge` when a shot stopped a Y or B lunge |

A landing tick on a cue is the tick it was sent plus the live ticks to the landing; a hit-stop in between makes the real tick later.

On the strike beat: `strength`, `flurry`, `burst` (its number), `close`, `gap`, `launcher` and `ready`, `charged` and `charge`, `aim`, `energy`.

Reads: `DirBrawl.winding(S, f)`, `DirBrawl.giving(S, f)`, `DirBrawl.launcherOpen(S, f)` (the tick his opening ends, or -1), `DirBrawl.launcherReady(S, f)` (his B would launch), `DirBrawl.launcherRest(S, o)` (live ticks until a launch is ready on o; one slot and the clock).

## 8. Decisions

1. **Giving ground is one rate for every fighter** (`give.bySpeed` off). With his speed in it, the table's two hard rows can't both hold.
2. **The edge of a reach misses** (`give.edgeBh` 0.033), so the table holds by QA's count of ticks.
3. **The winder's stick still nudges the centre,** and only its part toward the rival follows him.
4. **Away, and down on the ground, fall to the planner's pick.**
5. **Open means open:** no blow, no guard, no dodge, no giving ground for the 20 ticks.
6. **The charge is paid in two parts:** 5 ki at the press, 3 more at tick 32.
7. **Inside a brawl the AI's heavy at a guard has its own share** (`breakGuard` in the brawl block).
8. **A lunge's arrival tick takes no step in.** The lunge has already moved him further than 0.6 bh on that tick. The blow's cue says `source` `lunge`.
9. **A far heavy charge arrives worth a medium.** Its extra quarter went with `heldMul`, until the charged medium exists.
10. **A punished taunt is not an opening yet:** it isn't a stagger inside a brawl today.
11. **The counted gap** (section 2). Measured on the ground, a followed heavy missed on a slope and an unfollowed one landed, each by a unit or two; the design's table leaves 2.5 units either way.
12. **The AI's tap gap has a spread at medium** (8 to 11), Game Design's named lever for the masher rows, and the medium AI throws half as many heavies into a flurry as first built. The X masher had fallen to 16 of 100: the AI no longer winds 12-tick heavies that a masher lands free blows into.
13. **A fighter who gives ground into a building's face goes up it.** Stopped dead, he was the one case in about two thousand that a heavy still caught.
14. **No blow lands from beyond 68 units** (the EP's ruling on QA's hard row, follow-up). Two causes were traced, and each has its own fix. A light's reach could be wider than the room its placement had left on a tick the core had already moved him: that blow now misses, with the text `reach`. And a wound blow's counted gap ran short of the ground when the rival backed off up a rising face, because the ground lifted him by more than his step: the step is now fitted both ways, so the count and the ground agree. Over a ledge that no step fits, the count takes what the gap really opened by.
15. **Two AIs never both dig in to one trade** (`digInBoth` false, follow-up). As ruled, each AI drew its own share as a trade started. With both dug in, each matched the other's pace and the trade ran level to the double hit: 1.65 double hits a match between AIs, and 6 in one match against a hard row of 4. With one digger a trade it reads 0.01 a match, and 1 at most. Against a player nothing changes.
16. **The medium AI's `digIn` is 0.3,** inside Game Design's range of 0.1 to 0.4. At 0.2 a presser got 0.37 double hits a match, under the band; the masher read 48 of 100 at both.
17. **The AI's loader reads the dig-in keys** (the stick slice). `DirAI.skill()` keeps only the keys it lists, and `digInBy`, since C1, and `digInBoth` were not among them: each read took its default. So the rival's half as much again was applied in no reading of sections 9 and 11, and `digInBoth` was false whatever the data said. Four other top-level keys are read the same way and still take their defaults: `reactTicks`, `mineMinKi`, `stance` and `beamLook`, whose data equals the default, and `answerTicks`, whose data says 20 where the code's default is 28.
18. **A player's held stick is never left dead** (`nudge.floor` 0.5, the stick slice): the pair moves his way by half his own nudge at least, whatever the AI's stick, the speed the brawl began with or the centre's old drift say. Two players who oppose each other still cancel. And the one who may give ground moves alone only by a stick that does not point at the rival: toward him it nudges the centre.
19. **Nobody is cornered by a nudge** (the stick slice). At a building's face, and at a slope too steep to take in one step, the pair goes up it by the same step and over, where it used to stop.
20. **The AI digs in to a bounded number of double hits** (`digInMax` 2, `digInRestS` 45, the stick slice). Against a steady presser who flies back in, every trade it dug in to ran level to the double hit: 10.3 a match on my probe, against a hard row of 4, where QA's masher read 0.6.

## 9. As measured, the first chain (2026-10-11, scratch copy of main acb1a1bb with the slice)

**A correction to my reports of this chain.** Twice I reported the harness arms as having no failing row. That was a miscount: `harness.md` marks a failing row in bold, and my search missed it. Chain B read 86 pass, 34 fail and 63 pending. The tune before the apply read 84 pass, 36 fail and 63 pending. Most of the failing rows were failing before the chain; the ones this chain owns are in section 11.

QA's scripts, 100 matches unless said. The numbers the build lands with: `damageMul` 0.31; at medium `charge` 0.15, `launcher` 0.25, `tapGapMax` 11.

| Row | Reading | Band |
| :--- | :--- | :--- |
| Out of an unfollowed tapped heavy, started by tick 16 | 7,374 of 7,374 | Every time |
| Out of a followed one | 0 of 4,851 | Never |
| A B in a ready opening lands and launches | 296 used, 0 lapsed | Every time |
| A clean blast's knock-back | 318 of 318 at 4.0 bh | 4 bh |
| A blow moving its attacker over 0.6 bh in a tick, outside a lunge's or a zip's arrival | 0 of 33,502 and 20,051 (my probes) | None |
| The X masher against medium | 45 of 100 | 35 to 50% |
| Launches a match in all, AI against itself, 12 matches | 11.2 | 6 to 12 |
| Match median, AI against itself | About 340 to 360 s | 400 to 450 s. **Under its band.** `damageMul` is not its lever: 0.27 bought 5 to 12 s |

Outside their bands and with Game Design (its section 14): double hits for a presser (0 a match), the blast-heavy script (58 of 60), B mashed (60 of 60) and Y mashed (0 of 60), the flurry head to heads, a first launch inside 30 s (71%).

## 10. Not built

The charged medium, the just release, the fresh and the set guard, the wrench, the shove, the lift, a turning send (C2b). Getting out of a beam by moving (C5). Combat's pools by button: mediums play `combo.accent` pieces and heavies `power.last` pieces as stand-ins.

## 11. The follow-up tune (2026-10-11, scratch copy of main 2e0f3b2c)

The EP's four items after the first chain, with Game Design's rulings (`docs/design/brawl-second-pass.md` section 14).

| What changed | Where it is told | Its keys |
| :--- | :--- | :--- |
| No blow lands from beyond 68 units; the giver's step is fitted both ways | Sections 2 and 8, decision 14 | None |
| A press he can't pay for throws the strongest blow he can pay for. Before, a B without its ki was a light at once | Section 1 | None, and no cue of its own |
| The blast is an ender, and not an opener | Section 4 | `brawl.energy.reach.blast.enderRun` 2, `halfSetup` true, `reelTicks` 6 |
| The AI weighs digging in as a trade starts, and two AIs never both do | Sections 6 and 8, decisions 15 and 16 | `digIn` 0.1, 0.3, 0.3; `digInBoth` false |
| Matches are longer | `data/fighters/PROTAGONIST/wounds.json` and `RIVAL/wounds.json` | `wearPerDamage` 330 to 270, by the EP's grant for that one number |

**The 68-unit row, traced.** It had two causes.
- **A light's reach.** Over 90 matches between AIs, one blow landed beyond 68 units after its placement. It was a light, 71 units off: the core had moved him 13 units on that tick, and what was left of his step could not cover the reach his blow was read by. That is the rule's case, and the blow now misses.
- **A wound blow's count.** On QA's followed-heavy script, 11 of 2,426 heavies landed by the count while the two stood 69 to 72 units apart, the rival 60 to 90 units higher. He had backed off up a rising face. That was the count, and the count is fixed: 0 of 2,433 after it.

**As measured.** QA's scripts, 100 matches unless said.

| Row | Reading | Band |
| :--- | :--- | :--- |
| Damaging strikes within 68 units, four arms | 0 of 658,535 beyond; the longest 68.0 | Every one |
| Out of an unfollowed tapped heavy, started by tick 16 | 3,693 of 3,693 | Every time |
| Out of a followed one | 0 of 2,745 | Never |
| A blow moving its attacker over 0.6 bh in a tick, outside an arrival (my probe) | 0 of 21,028 | None |
| The X masher against medium | 47 of 100 | 35 to 50% |
| Double hits a match, a presser against medium | 0.61, and one or more in 48% of matches | 0.5 to 2, and 35 to 65% |
| Double hits between AIs; the most in one match | 0.02 a match; 1 | Reported; at most 4 |
| The blast-heavy script against medium, 60 matches | 29 of 60 | 30 to 50% |
| Launches a match in all, the AI against itself, 12 matches | 11.2 | 6 to 12 |
| Match median, the default arm | 377 s | 360 to 480 s |
| First brink, median | 277 s | 270 to 420 s |
| Brink to KO, median | 70.7 s | 45 to 90 s |
| Match length, 10th percentile | 265 s. **Under.** | 300 s or more |
| Limb breaks a match | 0.21. **Under,** and it did not move with the lever: 0.23 on the first chain at 300 | 0.3 to 0.5 |

The other three arms read medians of 364, 321 and 318 s, and 10th percentiles of 280, 256 and 256 s. The harness read 95 pass, 29 fail and 62 pending.

**The length lever, on the default arm.** The first chain as committed, with `wearPerDamage` alone at 300, reads a median of 336 s, a 10th percentile of 250 s and a first brink at 261 s. The follow-up's rules without digging in read the same. Digging in costs about 20 s of that.

| `wearPerDamage`, with the follow-up | Median | 10th percentile | First brink | Limb breaks a match |
| :--- | ---: | ---: | ---: | ---: |
| 300 | 316 s | 237 s | 238 s | 0.20 |
| 285 | 341 s | 252 s | 258 s | 0.17 |
| 270 | 377 s | 265 s | 277 s | 0.21 |

270 is the floor of the grant, and the one value that brings the median and the first brink into their bands. The 10th percentile needs another lever.

**Still out of band, and whose.**
- **The B masher against medium: 60 of 60,** with the rule for a press he can't pay for in. So that rule alone is not the row. Game Design's levers for it are the AI's.
- **The AI's wind-ups a minute of brawl: 15.7 against 4 to 10.** It is the row. QA's count sums both fighters' `windup` starts, and both are AIs in the arms, so each AI reads about 7.9. It also counts the B thrown in an opening (`k` 1), which nobody can give ground against.
- **Launches as a share of the endings that separate: 50.7% against 25 to 40%.** It is a rule that is not built. The knock-backs that band counts on come from C2b's throws, and Game Design's own table marks the row to be read again after C2b. The blast, now an ender, gives fewer knock-backs than it did.
- **Two of QA's scripted rows need a change with these rules.** The clean blast's knock-back row reads any knock-back within 3 ticks of a clean blast, and a blast thrown cold has none of its own. The give log keeps the tick of the last miss from one match into the next, so one miss marks every wind-up of the next match up to that tick.

## 12. The stick slice (2026-10-11, scratch copy of main 9a22894a with the follow-up)

Orb's rule: a held stick moves the pair on every live tick of a brawl, outside knock-backs, staggers and hit-stop. The changes are decisions 17 to 20.

**What a dead stick was.**
- **Mostly the hit freeze.** QA's count runs on the match clock, which also advances through a freeze, when nothing moves. In its own pair, a holder against a scripted masher with no stick, 27.7% of held ticks read dead before this slice and after it. Two lights mashers land a blow every 4 ticks or so, and each blow freezes 2. Against the medium AI the freeze is 31% of a presser's held ticks.
- **On live ticks, three causes.** The AI's stick pointed the other way, and the two cancelled. The speed the brawl began with, or the centre's old drift, still carried the pair against his stick. And a building's face stopped the step dead: in the re-laid city one brawl stood 500 ticks at a face.

**As measured.** My probe: a presser, X every 8 ticks, against the medium AI, the stick held one way through every brawl.

| Row | Before | After |
| :--- | :--- | :--- |
| Live held ticks with a dead stick, east | 8.6% | 0.4% |
| West | 8.4% | 0.6%, and 0.3% when going up a face is not counted |
| Away from the rival | 6.3% | 0.6%, and 0.3% |
| Toward him | 15.1% | 0.5% |
| The stick down from tick 24 of a brawl for 60 ticks (QA's drift, 30 matches): his first step along it within 2 live ticks | 1,679 of 2,524 | 2,564 of 2,568; the other 4 at 3, on a stagger |
| The same: no step along it in the 60 ticks | 133 | 0 east; 43 of 2,526 away, each going up a face |
| QA's own pair, a holder against a scripted masher, every tick counted | 60,758 of 219,108 dead | 60,956 of 219,969 |
| The drift against the AI, by QA's pair | 1.12 bh a second | 1.39, against 1.47 with no rival stick |
| Double hits a match, my steady presser | 10.3 | 2.0 |
| Double hits a match, QA's presser; one or more; the most | 0.61; 48%; 3 | 0.69; 56%; 2 |
| The X masher against medium | 47 of 100 | 47 of 100 |

What is left on live ticks is by rule: the double hit's wind-up and a zip in reach read no stick, and a stagger leaves half a nudge.

The other rows hold: the blast script 26 of 60; out of an unfollowed tapped heavy 3,693 of 3,693, out of a followed one 0 of 2,502; no blow over 0.6 bh outside an arrival, 0 of 45,219; within 68 units, 0 of 660,881 beyond; the most double hits between AIs in one match 1.

**The arms.** Medians 351, 373, 298 and 334 s; 10th percentiles 263, 273, 239 and 269 s; first brink 273 s; brink to KO 66.6 s; limb breaks 0.16 a match. The default arm on the same base without the slice read 381 and 264 s, and with the rival's share at 1.0 the slice reads 356 and 273 s. One run to the next moves a 100-match median by about 15 s, so QA's larger run decides whether the slice costs length.

**The AI's own stick.** The medium AI's `nudgeShare` is 0.3, from 0.5 (the EP's ruling). By QA's pair it holds its stick against a player's on 21.4% of the ticks he holds his, from 35.5%, against a band of under 25%. His drift against it reads 1.48 bh a second, the same as against no stick. Every row of the table above was read at 0.5. At 0.3 the X masher read 54 of 100, and QA's presser 0.70 double hits a match. The masher row read 58 at 0.35, 38 at 0.4 and 47 at 0.5: it moves by ten with any change in the AI's draws, so 100 matches can't place it inside a band of 35 to 50.

**Two of QA's readings need a change with it.** The dead-stick count should leave out the ticks on which the sim did not step. And the drift's latency against the AI reads the pair's speed rising above what it was as the stick went down: against an AI the pair is often moving already, so it reads late, or never, while he steps along his stick from the first or second tick.
