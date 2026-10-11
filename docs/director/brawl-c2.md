# The brawl, slices C2a and C2t with the heavy's hold: as built

Encounter Systems, 2026-10-06. The design is `docs/design/brawl-second-pass.md` sections 1 to 3 and 5b; the cut is `brawl-plan.md` section 10. This page says what the code does. Where it differs from the design page, the difference is listed under Decisions.

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
- **The burst.** A light whose button is still down 16 live ticks after the press throws seven more by itself, landing at 18, 22, 26, 31, 37, 45 and 56 ticks from the press. Each carries its number, 2 to 8, on its beat.
- **On the Simple layout** a wound press whose button is already up when it arrives was wound by its hold, and lands 2 ticks later.
- **Out of reach,** Y is the heavy lunge landing as a medium, and B the same lunge landing as the heavy. The wind-up counts from the press, so most of it is spent on the way.
- **A shot on a lunge with a wound blow** stops it as it would stop that blow's wind-up: a bolt counts as a light, a heavy shot as a medium, a charged shot as a heavy.

## 2. Giving ground, reach, and the closing rule

- **Who may give ground:** the fighter whose rival is winding or charging, while he has no blow on its way or kept, no attack button down, and is neither staggered nor open after a miss. His guard may be up.
- **His stick moves him alone,** at 5 bh a second, and 0.6 of that behind a guard. A stick within 45 degrees of straight away backs him off: the gap opens by his whole step, whatever the ground does under him. The gap never opens more than 2.4 bh past striking distance. At a building's face he goes up it by the same step.
- **The rival who winds follows** by the part of his stick that points at him, at 0.6 of the rate. The rest of that stick nudges the centre as before, and never opens the gap.
- **Reach, read as the blow lands:** a medium reaches 0.5 bh past striking distance, a heavy 1 bh, and a charged heavy up to 1.5 bh as it fills. Out of reach it misses: the cue `miss`, and he is open for 20 ticks. Open, he can't throw, guard, dodge or give ground.
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
- Y is the blast: a wind-up of 12 ticks read as a medium's, worth 2.5, 8 ki. A clean hit knocks him back 4 bh and the brawl ends. With the stick away it sends him back past the attacker.
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
| `digIn` | It trades on in a level trade | 0.12, 0.22, 0.35, half as much again for the rival |
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
| `miss` | The swinger is the actor, the rival the target. Text `gave_ground` or `reach`; `source` the cell; `n` the ticks he is open |
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

## 9. As measured (2026-10-11, scratch copy of main acb1a1bb with the slice)

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
