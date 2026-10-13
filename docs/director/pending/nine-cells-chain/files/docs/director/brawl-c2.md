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
- **Armour.** While a heavy winds or charges, a light does 0.3 of its worth (`heavy.armour.lightMul`) and changes nothing else. A medium that lands before tick 20 ends it; after that it does its damage and nothing more.
- **A medium winding:** a wound blow that lands ends it. A light lands in full, adds to the run, and its reel waits until his blow has landed. A stagger ends any wind-up.
- **The run** is counted in quarters of a point. A landed light or heavy adds one point, a medium two (`flurry.runBy.medium`), and a burst's blow half. A blow that lands on him takes the same off his own run. The close comes at a run of 4, whatever lands it.
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
| `giveGround` | It backs off from a wind-up it sees, after its reaction time; and from a signature's tell | 0.1, 0.45, 0.7 |
| `mediumVsHeavies` | Against a rival whose last two blows were heavies, its string is mediums | 0.15, 0.4, 0.7 |
| `perfectVsHeavy` | Its perfect block against a heavy it sees wound in the open | 0.05, 0.2, 0.4 |
| `perfectMul` | Its perfect-block share inside a brawl, on its level's own | 0.21, 0.15, 0.5 |
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
17. **The AI's loader reads the dig-in keys** (the stick slice). `DirAI.skill()` keeps only the keys it lists, and `digInBy`, since C1, and `digInBoth` were not among them: each read took its default. So the rival's half as much again was applied in no reading of sections 9 and 11, and `digInBoth` was false whatever the data said. Since the second-round tune the loader carries every top-level key as it is written, so none is dead: `reactTicks`, `mineMinKi`, `stance` and `beamLook`, whose data equalled the code's default, and `answerTicks`, whose data now says the 28 the code was playing.
18. **A player's held stick is never left dead** (`nudge.floor` 0.5, the stick slice): the pair moves his way by half his own nudge at least, whatever the AI's stick, the speed the brawl began with or the centre's old drift say. Two players who oppose each other still cancel. And the one who may give ground moves alone only by a stick that does not point at the rival: toward him it nudges the centre.
19. **Nobody is cornered by a nudge** (the stick slice). At a building's face, and at a slope too steep to take in one step, the pair goes up it by the same step and over, where it used to stop.
20. **The AI digs in to a bounded number of double hits** (`digInMax` 2, `digInRestS` 45, the stick slice). Against a steady presser who flies back in, every trade it dug in to ran level to the double hit: 10.3 a match on my probe, against a hard row of 4, where QA's masher read 0.6.
21. **The brawl's reads are pure** (the second-round apply). A read used to size the director's integers before it looked, and their count is in the gameplay hash: UI's call to `launcherRest` in an intro changed it. Now a slot that was never written reads 0, and only a write sizes. `sim/director/tools/reads_check.gd` calls every read on a fresh match, in an intro, in a brawl and after one, and fails if the hash or the count moves. The change alone leaves every golden as it was.

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

## 13. The second-round tune (2026-10-12, scratch copy of main 981ba0e3)

Game Design's rulings (`docs/design/brawl-second-pass.md` section 14, "The second round"), in its order, each lever read before the next. The X masher is read on 200 matches, seeds 1 and 101: on main its two halves read 54 and 40.

**The code under it.** With every new key at the value that plays as today, the masher rows read the same wins, medians and blow counts as main.
- The AI's loader carries every top-level key (decision 17).
- The run is counted in quarters, so a medium can count more than a light.
- Each fighter's last two blows of the brawl are kept, for the AI's answer to a run of heavies.
- The AI's perfect block against a heavy takes its level's `perfectVsHeavy` when the key is there.

**The levers.**

| Lever | From, to | What it read | Kept |
| :--- | :--- | :--- | :--- |
| `wearPerDamage` | 270, 255 | Median 373 to 400 s; 10th percentile 269 to 287 s; first brink 282 to 302 s | Yes |
| The second breath's wait, `fade.breathAfterTicks` | 240, 180, 150 | At 180: 10th percentile 281 s. At 150: 303 s. The wear it gives back: 22.9%, 32.1%, 44.0% of all battered wear | Yes, at 150. **It costs two rows** (below) |
| `cripple.base` and the light's pick, `family.light` | 0.02, 0.03; and 12, 4, 10, 6 to 12, 4, 8, 8 | Limb breaks 0.25 to 0.37 a match; the arms' share 80% to 62% | Yes |
| `mediumVsHeavies` (new) | 0.15, 0.4, 0.7 | The B masher 60 of 60, unmoved. His heavy staggers the AI for 12 ticks, so its medium lands on tick 22 of his next wind-up, 2 ticks after the armour holds | Yes, as ruled. It can't act at his pace |
| `giveGround` | 0.05, 0.2, 0.4 to 0.1, 0.45, 0.7 | The B masher 46 of 60 | Yes |
| `perfectVsHeavy` (new) | 0.05, 0.2, 0.4 | The B masher 14 of 60 | Yes. **In band.** `mediumIntoHeavy` and the heavy's ki were not needed and stand |
| `flurry.runBy.medium` (new) | 1, 1.75, then 2 | The Y masher 0, 1, then 4 of 60. He is out of ki within seconds: a medium every 12 ticks costs twice what comes back | Yes, at 2, Game Design's next step. **Under its band** |
| `heavy.armour.lightMul` | 0.5, 0.3 | The X masher 78 to 87 of 200; the B masher 15 to 14 | Yes |
| The easy AI's `perfectMul` | 0.3, 0.21 | Perfect blocks a minute at easy 2.51 to 1.94 | Yes |
| `impulses.brawlLight`, then `brawlMedium` | 13, 16, 20; and 40, 55 | At 16: Calm 35%, Frenzied 5.2%. After the acts' lever they read 43% and 3.6%, and at 20 and 55: 32%, 11%, and 17.5% in act 4. The mood moves nothing in the fight | Yes |
| The ladder's `takenPerDamage` and `dealtPerDamage` | 0.0075 and 0.0045, to 0.0056 and 0.0034 | Acts 2, 3 and 4 start at 90, 153 and 233 s, then at 111, 193 and 302 s. Limb breaks fell back to 0.27 | Yes |
| `cripple.base` again | 0.03, 0.04 | Limb breaks 0.27 to 0.29 | Yes. Just under its band at Game Design's last step |

**The tuned build, as measured.** The default arm, 100 matches, and QA's pairs.

| Row | Main | Tuned | Band |
| :--- | :--- | :--- | :--- |
| Match median | 373 s | 424 s | 360 to 480 s |
| 10th percentile | 269 s | 313 s | 300 s or more |
| First brink; brink to KO | 282 s; 72 s | 337 s; 63 s | 270 to 420 s; 45 to 90 s |
| Limb breaks a match; the arms' share | 0.25; 88% | 0.29; 55% | 0.3 to 0.5; 35 to 65% |
| Calm; Frenzied; Frenzied in act 4 | 41%; 3.4%; 9% | 32%; 11%; 17.5% | 20 to 40%; 5 to 20%; 15% or more |
| Acts 2, 3 and 4 start at | 90, 153, 239 s | 111, 193, 302 s | 90 to 150, 150 to 240, 270 to 345 s |
| The X masher against medium | 94 of 200 | 75 of 200 | 35 to 50% |
| The B masher | 60 of 60 | 12 of 60 | 20 to 50% |
| The Y masher | 0 of 60 | 2 of 60. **Under** | 20 to 50% |
| Perfect blocks a minute at easy | 2.51 | 1.94 | 0.5 to 2 |
| Double hits a match, a presser; one or more; the most | | 0.74; 58%; 2 | 0.5 to 2; 35 to 65%; 4 |
| Out of an unfollowed tapped heavy; out of a followed one | | 3,693 of 3,693; 0 of 2,017 | Every time; never |
| Within 68 units; a blow over 0.6 bh in a tick | 0 of 163,752 | 0; 0 of 25,599 | None |
| The wear the second breath gives back | 22.7% | 42.4%. **Over** | At most 25% |
| The blast script against medium | 26 of 60 | 37 of 60. **Over** | 30 to 50% |
| Launches a match, the AI against itself, 12 matches | | 14.3. **Over,** in matches a fifth longer | 6 to 12 |

The other arms read medians of 422, 369 and 371 s, and 10th percentiles of 305, 292 and 299 s. On the default arm alone the harness reads 92 pass and 18 fail, where main reads 87 and 23.

**The hard AI's perfect blocks** read 5.82 a minute against a band of 2 to 5.5, and 5.61 with its brawl `perfectMul` at 0.45. One step doesn't reach the band, so it stays at 0.5.

**The second breath's wait costs two rows.** Taking each length lever back alone, the blast script reads 42 of 60 without the ladder's rates, 37 without the wear, and 30 with the wait back at 240. So it is the wait that lifts the blast script, as it lifts the wear given back. The blast's price is not its lever here: at 12 ki it reads 40 of 60, and the script wins on its bolts. With the wait at 240 the 10th percentile reads about 287 s.

## 14. The nine cells, pass 1 (2026-10-12, scratch copy of main 68c1bbbb)

Game Design's order (`docs/design/brawl-second-pass.md` section 15, pass 1): the held X's floor pace, the medium at 1 ki, `wearPerDamage` 240 with the second breath's wait back at 240, and the readings. Main has not changed under `sim/`, `data/`, `tools/` or `qa/` up to c6f58415.

**A held X, as built.**
- **The hold is one state.** An X press whose button stays down is a hold. Its burst comes first, as before. After the burst's last blow, or after a stagger, it goes on at the floor pace: one blow every `burst.floorGap` ticks, each through a tap's own path. A reel carries it, as it carries a mashed press. Letting go ends it, and so does any other press.
- **A floor blow** is worth `burst.rate` for each tick of its gap (0.07 against a mash's 0.10), adds a full point to his run, and reels as a tap does. It is not in his press log, and it has no `press_ack`. The blow carries `floor` in its arguments.
- **A new burst needs a new press.** After the burst's last blow he is no longer open for `burst.openTicks`: the floor pace follows it. With `burst.floorGap` at 0 the old rule plays.
- **The AI is untouched.** It lets go 2 ticks after its burst's last blow, before a floor blow is due, and it never carries a hold.

**Two things threw the hold away, and both are closed.**
1. **A stagger takes a fighter's buttons.** The core drops his held levels while he is staggered, and on the tick a stagger ends that tick's were dropped before the director sees it over. So the hold read "let go" at every stagger: 27 to 32 times a match. This is what "any stagger threw the hold away" was. Now X is not read while he is staggered, and it counts as let go only when it has read up on two live ticks running (decision 22).
2. **Nothing pressed again when a brawl ended.** A brawl ends about 17 times a match: a launch, a knock-back, a trade thrown apart, a perfect block's turn. With X still down his fighter then stood still. `burst.holdCarries` (decision 23) lets the hold outlive its brawl: a brawl that starts with X already down goes on at the floor pace, and out of reach a free fighter's hold presses as a tap does, `floorGap` apart, so it closes the gap. The blow it arrives with is the floor's. With the key off the hold ends with its brawl, as first ruled.

**What wins a match is the close, not the damage.** A KO comes only from a decisive win on the brink, and in a brawl that is a close or a launch. The Y masher deals 9,026 a match against 9,326 and wins 3 of 60: he closes 1.5 times a match, and the AI closes on him 37 times and launches him 9.3 times. The holder's rows read the same way: his pace decides how often he closes, and his worth moves little.

**The holder, read.** One script against the medium AI, forms taken as they come. "As ruled" is the hold that ends with its brawl, read with a script that presses again after his fighter has stood idle for 30 ticks (a hold that never presses again deals 15 damage a minute). "Carries" is X held down for the whole match.

| The hold | Pace, worth a tick | Wins | Damage a minute, dealt and taken | Closes a match |
| :--- | :--- | ---: | :--- | ---: |
| As ruled | 10, 0.07 | 0 of 20 | 1,650 and 2,296 | 11 |
| As ruled | 8, 0.07 | 0 of 20 | 1,587 and 2,220 | 25 |
| As ruled | 10, 0.10 | 0 of 40 | 2,190 and 2,311 | 10 |
| As ruled | 8, 0.10 | 0 of 40 | 2,181 and 2,253 | 22 |
| As ruled | 10, 0.12 | 1 of 40 | 2,603 and 2,299 | 10 |
| Carries | 10, 0.07 | 0 of 20 | 1,687 and 2,327 | 11 |
| Carries | 10, 0.10 | 1 of 40 | 2,345 and 2,317 | 11 |
| **Carries** | **8, 0.07** | **7 of 120** | 1,680 and 2,225 | 27 |
| Carries | 8, 0.085 | 1 of 40 | 1,974 and 2,211 | 26 |
| Carries | 8, 0.093 | 6 of 40 | 2,210 and 2,200 | 26 |
| Carries | 8, 0.10 | 8 of 40 | 2,384 and 2,206 | 27 |
| The X masher, on the same probe | 8, 0.10 | 17 of 80 | 2,387 and 2,150 | 22 |

- **As ruled, no pace and no worth wins a match.** The hold that ends with its brawl never starts the next one well: his press from afar is a held press, which is a charge, and it arrives as a set piece and not as a brawl.
- **The ruled lever works once the hold carries.** At 8 ticks he closes as often as a masher does.
- **At the ruled worth he sits under his band:** 7 of 120 on my probe, and 3 of 60 on QA's holder with `hold=100000`. At a mash's worth he reads as the masher does on the same probe.
- **QA's holder as it stands (hold 60, rest 8) can't read this row.** The floor pace begins at tick 66 of a hold.

**The data, first.** These reads were taken with `burst.floorGap` 8, `burst.holdCarries` true and the worth at `burst.rate` 0.07 where the table says so. Game Design has since ruled on all three (section 15): the pace at 8, no carry by default, and the worth at 0.085.

**The other levers of the pass.**

| Lever | From, to | What it read | Kept |
| :--- | :--- | :--- | :--- |
| `medium.ki` | 2, 1 | The Y masher 3 of 60, as before | Yes, as ruled. **It moves nothing:** ki was not his limit |
| `wearPerDamage`, with `fade.breathAfterTicks` | 255 and 150, to 240 and 240 | On 200 matches: median 432 to 442 s; 10th percentile 313 to 326 s; first brink 342 to 349 s. The wear the second breath gives back 44.9% to 23.0% | Yes |
| The AI's `perfectVsHeavy` at medium | 0.2 | The B masher reads 19 of 60 | Left, as ruled: he is in his band |

**The build, as measured.** QA's scripts and the default arm on 200 matches.

| Row | Main | Pass 1 | Band |
| :--- | :--- | :--- | :--- |
| Match median | 432 s | 442 s | 360 to 480 s |
| 10th percentile | 313 s | 326 s | 300 s or more |
| First brink; brink to KO | 342 s; 69 s | 349 s; 69 s | 270 to 420 s; 45 to 90 s |
| Limb breaks a match; the arms' share | 0.29; 48% | 0.43; 45% | 0.3 to 0.5; 35 to 65% |
| Calm; Frenzied; Frenzied in act 4 | 32%; 11%; 17.5% | 32%; 11.5%; 19.8% | 20 to 40%; 5 to 20%; 15% or more |
| Acts 2, 3 and 4 start at | 111, 193, 302 s | 111, 203, 310 s | 90 to 150, 150 to 240, 270 to 345 s |
| Act 4 before the first brink | 63% | 71%. **Under** | 80% or more |
| The wear the second breath gives back | 44.9% | 23.0% | At most 25% |
| Launches a match, the AI against itself | 14.3 | 13.1 | 6 to 12; 14 if the length and the collateral hold, and they do |
| Civilians lost; front-row structures lost |  | 20.4%; 36.4% | 12 to 30%; 25 to 50% |
| Perfect blocks a minute at medium |  | 3.07 | 1 to 4 |
| **X held:** QA's holder with X down for good | 0 of 40 | 3 of 60. **Under** | 10 to 35% |
| X mashed | 73 of 200 | 86 of 200 | 35 to 50% |
| Y mashed | 3 of 60 | 3 of 60. **Under** | 20 to 50% |
| B mashed | 20 of 60 | 19 of 60 | 20 to 50% |

**A light on a medium held past its wind-up gave him a reel that never ended** (found by reading, and closed here). The reel was counted from his blow's landing tick, and a blow that waits for its button has none yet. So a player who held Y for 12 to 16 ticks and took a light in that time threw nothing more in that brawl. It is counted from the tick the light lands.

**A double hit lands on both, whatever the first blow breaks** (QA's hard test; it failed once in 7 on this build's default arm, on seed 188, and it could have on main). The first of the two blows broke a region, the break's chapter dropped every pending beat, the second blow with them, and the brawl handed over before it could land. With limb breaks at 0.43 a match that is no longer rare. Now the chapter keeps a double hit's blow that is still to land (`DirMelee._breakChapter`), and the brawl hands over to the break when both have landed. On seed 188 both now take their damage on the landing tick, and the break plays.

**The blast as an ender is marked.** The `energy_land` cue of a blast that lands as a string's ender carries `amount` 1; its own knock-back follows on that tick. Any other landing carries 0.

**Decisions** (the numbering runs on from section 8).
22. The hold's button is read with a debounce of two live ticks, and never while he is staggered. A real release is seen one tick late, and nothing is thrown on that tick.
23. `burst.holdCarries`: a held X outlives its brawl. It is a player's only: the AI's far charge holds X while its approach lasts, and that is no held X.
24. Any X press that stays down is a hold, and not only one whose burst ran. So a press whose own throw lapsed in a long reel still picks up at the floor pace.
25. A floor blow kept behind a busy line is thrown as one when the line frees (the held press's bit 32), and its lapse sends no cue.
26. The burst's `openTicks` apply only with the floor pace off.
27. A double hit's two blows both land before a break's chapter takes the exchange.

**New state.** Three integers a fighter: `FLOOR` (0 none, 1 an X press still down, 2 at the floor pace), `FLOOR_AT` and `FLOOR_T`. Their count is in the gameplay hash, so every golden moves.

**New keys,** for Tools: `brawl.burst.floorGap` (an integer, 0 or more) and `brawl.burst.holdCarries` (true or false).

## 15. Pass 1 as Game Design ruled it (the fifth round), the recipes hook and the fourth round: one chain (2026-10-13, built on main 91b3722f)

Everything in sections 14 to 17 is one chain with one golden. It is built in scratch from main by the scripts named in each section, and parked together.

**The fifth round's rulings on pass 1** (`docs/design/brawl-second-pass.md` section 16, "The fifth round"), as data.

| Ruling | Key | From, to |
| :--- | :--- | :--- |
| The hold waits a stagger out | (code, section 14) | |
| It does not carry out of reach by default | `burst.holdCarries` | false. The switch stays for Controls' hold-to-flurry setting |
| The pace | `burst.floorGap` | 8 |
| The worth of the whole held flurry | `burst.rate` | 0.07, 0.085 |
| A landed medium on the run | `flurry.runBy.medium` | 2, 3 |
| The medium AI's perfect block against a heavy it sees | `perfectVsHeavy` | 0.2, 0.15 |
| The hard AI's perfect blocks | `perfectMul`; `perfectVsHeavy` | 0.5, 0.45; 0.4, 0.3 |
| The ladder's two rates (granted lines) | `takenPerDamage`, `dealtPerDamage` | 0.0056, 0.006; 0.0034, 0.0037 |
| The wear, with room in the 10th percentile (granted lines) | `wearPerDamage`; `fade.breathAfterTicks` | 255, as on main; 150, 240 |

**As measured on the chain.**

| Row | Reads | Band |
| :--- | :--- | :--- |
| Match median; 10th percentile (the default arm, 200 matches) | 440 s; 324 s | 360 to 480 s; 300 s or more |
| First brink; brink to KO | 347 s; 71 s | 270 to 420 s; 45 to 90 s |
| Limb breaks a match; the arms' share | 0.31; 48% | 0.3 to 0.5; 35 to 65% |
| Acts 2, 3 and 4 start at | 106, 183, 283 s | 90 to 150, 150 to 240, 270 to 345 s |
| Act 4 before the first brink | 90.5% | 80% or more |
| The wear the second breath gives back | 23.2% | At most 25% |
| Launches a match; people lost; front-row structures lost | 12.8; 21.3%; 38.5% | 6 to 12, or 14 while length and collateral hold; 12 to 30%; 25 to 50% |
| A damaging strike from beyond 68 units | 0 of 416,670 | None |
| X mashed | 85 of 200 | 35 to 50% |
| Y mashed | 22 of 60 | 20 to 50% |
| B mashed | 6 of 60. **Under** | 20 to 50% |
| X held: a holder who lets go and holds again when no hold is running (my probe) | 3 of 120, where that probe's masher reads 14 of 80. **Under** | A third to two thirds of the same probe's masher |
| X held: QA's holder with X down for good | 0 of 60. The script has to let go and hold again | 10 to 35% |
| Perfect blocks a minute at easy, medium and hard | 2.13, 2.86 and 5.93. **Easy and hard over** | 0.5 to 2; 1 to 4; 2 to 5.5 |
| The harness on the default arm | 96 pass, 14 fail, no hard test among them |  |

**The wear, with the fourth round in.** At 255 the default arm read a median of 366 s and a 10th percentile of 272 s; at 240, 400 s and 296 s; at 225, Game Design's floor, 444 s and 330 s (100 matches each, on f631d1b1). The hammer keeps a brawl going where a resting launcher used to part the two, so damage comes faster. It is parked at 225.

**The chain's gates, in scratch on 91b3722f:** 28 of 30. The golden regenerated, parity, npm's five stages, the loader on 200 matches, the nine input tests, determinism plain and with intros, the seam sweep, the cue check, the mash probe, World's five, the HUD check, the validator and its self-test (6,444 data cases) and the brawl's read check (16 of 16) pass. Two do not, and neither is in the brawl.
- **Animation's check, two asserts.** Both hold the picture from before the recipes: "his blows were all his own key sets" lists the old pools' prefixes (`pr`, `ph`, `w1`, `rb`), and "by default a mashed Y plays today's heavy row" is the default the hook ends. Animation's to move, in the same chain.
- **The flash count, one run.** The AI against itself on seed 7, normal mode: the register grants 2.50006 of weight in the 60 ticks from tick 2939, against 2.5: a beam, its cut-in panel, a beam clash and a head flash of 0.0249 that had 0.0249 of room. Clean main reads 2.36 on that seed, because the match is a different match. No brawl effect is among the four. VFX's register and Tools' check, for the edge.

## 16. The recipes hook (Combat's `docs/combat/brawl-hook.md`, its seven parts)

Built by `h1.cjs` to `h4.cjs` on pass 1, with Combat's parked recipes as `data/combat/recipes.json` and Tools' `apply-brawl-recipes.cjs` for the schema.

| Part | As built |
| :--- | :--- |
| 1. The cell | `_piece(S, f, st, toward, cell, want)` reads the cell's pool from the recipes' `brawl` block. A press: `launcher`, `blast`, `bolt`, `heavy`, `medium`, `burstFloor`, `lightToward`, `flurry`, `light`. A burst's blow by `burst.slots`: `burstFast`, `burstMid`, `burstSlow`. The reversal: `reversal`. A pressed blow thrown by rule takes its strength's cell. A zip's blow and the double hit's have no cell and keep the pool of their strength. A wound blow that becomes a charge picks again, from `heavyHeld` |
| 2. The launcher's send | The piece is one whose row sends where the stick's quarter says, through `launcher.aim`. With no stick there is no filter: the launch planner picks its send 14 ticks after the piece is thrown |
| 3. No style | No blow of the brawl names a style. A zip's and the double hit's still do: their callers set it |
| 4. The bolt's arm | A bolt that follows a bolt in his string takes the next piece and arm of one of his runs (`reach.runs`), drawn when the mash starts and entered just past the bolt he has thrown. `hand` is `r` for the lead arm and `l` for the free one |
| 5. The gut rule | The pool is asked for a piece that is not to the gut and is not one of his last two. A blow lost before it lands, and a piece chosen at the press and replaced at a charge, still count: his next is not to the gut if the lost one or the one before it was |
| 6. The fallback | In order: the cell's pool; one of his last two again, the older first; the pool one strength down (`fallback.lower`). Then the same with the stick's send dropped, since a send nobody has is a wish and not a rule. Legal's rule is never dropped |
| 7. What moves | `data/combat/recipes.json` is in the data hash and the picks change: the golden is regenerated once, with the chain |

**Not built:** the wrench (C2b); a rise after a rise and the other string rules of part 5 (they need two more integers a fighter and a juggle to matter); the piece following the planner's pick with no stick.

**As measured** (the probe `hookprobe.gd`, six matches each of seven players against the medium AI, 79,552 blows, on the chain as built on 91b3722f).

| Row | Reads |
| :--- | :--- |
| A blow with no piece | 0 |
| A piece outside its cell's pool | 0 (a launcher held into a charge picks again from the heavies: the probe's label, not a fault) |
| Two blows running to the gut, over the blows that reached their contact | 0 in all seven |
| An aimed launcher whose piece does not send where its quarter says | 0 of 28 (across 6, down 6, turned 6, up 10) |
| Bolts thrown running | 6,506 from the runs, a fifth on the free arm, never the same piece twice running |
| Blows that name a style | Only zips and double hits |

**New state.** Three integers a fighter for the bolts' run (`BOLT_N`, `BOLT_RUN`, `BOLT_I`), and `GUT` keeps two bits.

## 17. The fourth round (`docs/design/brawl-second-pass.md` section 16, "The fourth round")

Built by `f1.cjs` and `f2.cjs`.

| Ruling | As built |
| :--- | :--- |
| A resting launcher is the hammer | B in an opening while the launcher rests still always lands, on the launcher's wind-up. It is a full heavy (`heavy.worth`), it staggers him in place as a landed heavy does, and the brawl goes on. Its beat carries `hammer` |
| The first move | A fighter sent by a launch, a wall slam or a knock-back is marked while he is sent. For `firstMove.lockTicks` (45) after he is free, a light, a medium or B of his from outside the close band is refused (`press_ack`, `refused`). A signature, a blast and a strike in reach pass. A zip's start is not gated |
| Digging in, once a match | One keyed draw a match at the level's share (0.3, 0.55, 0.75). An AI that digs in does so at the first trade after `digInAfterS` (30), and to `digInMax` (2) double hits at most, `digInRestS` (120) apart. `digInBy` for the rival is 1: the shares are by level |

**As measured.**

| Row | Reads | Bound |
| :--- | :--- | :--- |
| The route's player against the same script's masher (QA's pairs, 100 matches each) | 14 against 50. **Out** | Within 3 points, or above |
| Double hits, a steady presser: a match; matches with one; the most | 1.18; 68%; 2 | 0.5 to 2; 35 to 65% (Game Design expected about 55%, and under 1 a match); 4 |
| Exchanges that end in a knock-back, of those that reach a launch decision | 21.2% | 25 to 35%. The hammer parts nobody: the band wants a new base |
| Launches as a share of the exchanges that separate the two | 63.2% | 25 to 40%. The same |

**The route's player still loses, and why.** QA's route taps B only on the ping, which sounds for a ready launcher. So the hammer never plays in that script, and what it measures is the launch alone. After his launch the rival still starts the next exchange 128 times of 172 on my probe, lock or no lock: a tap from the far band opens a taunt and is no approach, so a player who taps has no first move to take. On my own probe, where the route's player and the masher share one press clock, they read 7 of 40 and 5 of 40. QA's route presses 1,902 times a match against its masher's 2,152, and lands 1,204 hits against 1,572.

**A proposal, built and off** (`firstMove.pursue`): while the first move is his, the launcher's press from the far band flies in, where a tap there would open a taunt. With it on, QA's route reads 19 of 100 against the masher's 37, and the rival starts 4.8 exchanges a match where he started 9.1.

**Decisions.**
28. The hammer takes the launcher's price (5 ki), its wind-up and its cell.
29. The first move's lock is read from the fighter's state: launched, dropped or down marks him, and the lock runs from the first tick he is free and not staggered.
30. `digInBy` goes to 1 for the rival, so the levels' shares are what they say.

**New state.** Two integers a fighter (`SENT`, `MOVE_AT`), kept across brawls.

**New keys,** for Tools: `brawl.firstMove` (`lockTicks`, `pursue`) and `digInAfterS`.
