# Energy, stamina and the body: the build spec for the third milestone

Written by Orb's stand-in (design and review specialist), 2026-11-14, for the EP. **Design only.** Nothing here is built or decided. Every number is a first value kept in data, and Game Design rules on numbers. It turns Game Design's model page, `docs/design/energy-stamina-body.md` (2026-11-13, "the model page" below), into steps Simulation, Encounter, Controls, UI, VFX, Animation, Audio and QA can build from. Where the model page and the two workshop pages differ, the model page wins, and this page follows it. Every place this page departs from it is in section 4.

Read with it: the model page; `docs/ep/vision.md` lines 1735, 1740, 1756, 1784 to 1788, 1800 and 1802; the path's third milestone (`docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` lines 181 to 216) and its briefs under `05-directives/A3/`.

## 1. In plain words

- **Three things run through every fight.** Energy pays for big moves, as today. Stamina is your wind. The body is the deep health that never comes back in a match.
- **Plain blows give stamina back.** Land X, Y or B and your stamina rises: a little for a light, more for a heavy. A well-timed press gives half as much again (today's code cannot yet tell a well-timed press in the close brawl, so that part needs work first), mashing gives about a third, a blocked blow gives half, and a miss gives nothing.
- **Big moves cost stamina as well as energy.** A beam, a signature, a flight strike, a burst or the dodge that cancels a move all take some. A signature takes about a third of a full stamina.
- **Flying flat out costs stamina slowly.** Holding LT takes about 17 seconds to empty a full stamina.
- **Blocking costs stamina too.** A little for a light blow, more for a heavy. Block for too long and you run out of breath.
- **Nothing is ever refused for stamina.** If you run out, the move still comes out and takes extra energy instead. While you are out of breath your blows are a fifth weaker, flat-out flight is a fifth slower, and every hit injures you 1.6 times as much.
- **Breaking away brings it back.** While you are trading blows, only your own landed blows bring stamina back. To catch your breath you have to get out. (That is how this page reads the rule; Game Design has yet to rule on it.) Out of the fight, stamina refills in about 7 seconds when you are healthy and about 14 when your body is spent.
- **Injuries let hits reach the body.** While every part is sound, almost nothing gets through. The more a part is hurt, the more of each hit on it reaches the body, and the middle of the body is the gate for all of it. When the middle breaks or the body runs out, the fighter is on their last legs and a finishing move can end the match.
- **A new form gets you back in the fight.** Stamina refills with a higher top, and injuries ease. The body does not heal. The more of the deep health a fighter has lost, the faster being hit fills their form: up to 1.8 times, at the very end.
- **No bars.** You read all of it from the fighter: breathing, posture, the aura, the ground under them, and a slow heartbeat in your own pad. The energy line in the corner stays.
- **None of this is in the game yet.** It is built switched off, measured, and switched on only when the measurement shows the fighter who falls behind first still wins between about a third and under half of the time.

## 2. Where things stand

| Thing | State | Where |
| :--- | :--- | :--- |
| The model page | Written, 2026-11-13. The one page for the rules | `docs/design/energy-stamina-body.md` |
| Stamina | **Missing.** The word is in no sim, data, UI, render, net or audio file. Tools' list for it is empty | `tools/ratchet-fighter-specific.json:13` |
| The data file | **Missing.** `data/fight/` has no `vitals.json` | `data/fight/` |
| The body | The old hit points still exist, are hashed, fall by the full damage of every hit, stop at 0 and end nothing | `sim/core/damage.gd:26`, `sim/core/wounds.gd:38`, `sim/core/hash.gd:6` |
| Injuries | Built: four parts, wear in fixed point, stages at 30, 60 and 90, limbs stop below broken and spill into the core, the brink is the core broken | `sim/core/wounds.gd`, `data/fight/wounds.json` |
| Energy (the meter moves spend) | Built, with its own numbers as literals in code: start 60, regen 5 a second, charging 30 a second, hit gain 0.04, guard drain 0.08 | `sim/core/state.gd:1077`, `sim/core/fighter.gd:685`, `:695`, `:767`, `sim/core/damage.gd:84`, `:89`, `:90` |
| The energy model (send speed and flat-out flight by tier and power) | Built. Off in main's data, on in Orb's builds through the page's setup word. It never reads or writes the energy meter | `data/fight/power.json:4`, `sim/core/power.gd:116-123`, `:182-187` |
| Flat-out flight at 3,500 a second | Ruled by Game Design on Orb's decision. Main's data still says 5,000. Lands in the first milestone's second window | `docs/design/flight-3500.md`, `data/fight/power.json:108` |
| The ladder and forms | Built: one number 0 to 100, thresholds 35, 65, 100, a form waits for the transform press. The Protagonist's own steps are off | `data/fight/ladder.json`, `sim/core/fighter.gd:552-602`, `data/fight/forms.json:4` |
| The comeback | Built for one fighter only (the one with the hero's meter). Cap 0.5 in that fighter's meters file, the power of 2 in code | `sim/core/damage.gd:50-54`, `data/fighters/PROTAGONIST/meters.json:57-58` |
| The old meters | Still act in every match. Game Design's page zeroes them in the first milestone's second window. Not done in data yet | `sim/core/fighter.gd:686-705`, `sim/core/damage.gd:50-57`, `sim/director/beam.gd:208`, `:245` |
| The press grade | Built. Each press is tagged plain, held, mashed or timed | `sim/director/alchemy.gd:50-53`, read at `sim/director/melee.gd:334-343` |
| Parks that touch this | None. No file under `docs/*/pending/` mentions stamina or the data file. Simulation's model switch flip is parked for the first milestone | `docs/architecture/pending/power-flip/` |
| What the player reads today | Breathing by wear, a sag near the brink, broken-limb poses, marks that never fade, an aura that wavers when the core is hurt, the energy line and power pips on the corner plate. Nothing for stamina | `render/anim/anim_fighter.gd:2910`, `:5274-5290`, `render/core/fighter_view.gd:266-271`, `render/vfx/react.gd:82-89`, `ui/core/ui_sim_bridge.gd:108-110` |
| QA's comeback measurement | **Missing.** The band is listed as pending in QA's own table | `qa/godot/bands.js:477` |

Main's fight code is the build Orb last played (6a30b4c9); the difference is data switches and page setup words. So the baseline for every reading below is the build's own packed data, not main's switch list.

## 3. The design

### 3.1 The five numbers and where each lives

| Number | State | Range | Starts | Hashed |
| :--- | :--- | :--- | :--- | :--- |
| **Energy** | `f.ki`, as today | 0 to `energy.max` (100) | `energy.start` (60) | Always, as today (`hash.gd:6`) |
| **Power** | `f.power`, as today | 0 to 100 | 0 | Always, as today |
| **Injuries** | `f.wear[4]`, `f.stage[4]`, as today | 0 to 100 wear a part | 0 | Always, as today (`hash.gd:181-185`) |
| **Body** | `f.hp`, **reused** (the model page, section 1). With the switch on it falls only by what gets through (3.4). Its top is `f.maxhp` (1,600 for all three fighters today, already per fighter in `fighter.json`) | 0 to `maxhp` | `maxhp` | Always, as today. It is also already in the LAN check (`net/desync.gd:69`) |
| **Stamina** | New: `f.vit.st`, where `f.vit` is a `VitalsState` that exists only while the switch is on | 0 to the ceiling: `stamina.max` + `stamina.formCeiling` × (tier − 1), so 100, 115, 130, 145 | `stamina.start` (100) | Only while the switch is on (6.1) |

`VitalsState` holds three fields: `st` (stamina), `busy` (stamina was spent since the fighter's last step) and `winded`. The ceiling is worked out from the tier, so it is not stored.

The switch is `data/fight/vitals.json` `"enabled"`, off. A match's setup may carry `"vitals": true` or `false` for that match, the same way the kick's setup key works (`sim/core/sim.gd:266`). That is how QA runs the same seeds with the loop off and on, and how one of Orb's builds can try it before main's data flips.

### 3.2 Stamina: what spends it

| Spend | Amount | Data key | Where it hooks |
| :--- | :--- | :--- | :--- |
| Any move that spends energy | 0.7 of the energy the move actually took, at most 30 a payment (the model page says 30 a move: section 4, row 22) | `stamina.ofEnergy`, `stamina.moveCap`, with one share per kind in `stamina.ofEnergyBy` | One call after each of the 34 spend lines in 3.9. At the eight lines that can stop at 0 energy, one read of the energy before the line as well |
| Flying flat out (LT held, stick past half) | 6 a second | `stamina.flatOutPerSec`, `stamina.flatOutStick` | `sim/core/fighter.gd:735`, the free branch |
| A slip (a tapped LT that eases to the slip's speed) | 5 | `stamina.slip` | `sim/core/fighter.gd:746`, on the tick `SimPower.slip` starts its brake |
| Guarding a blow | Light 1.5, medium 3, heavy 6 | `stamina.guard` | `sim/core/damage.gd`, after `hurt` at `:119`, when the family is guard |

Worked sums for the 0.7 rule, with main's prices (the scratch model, section 9, prints the whole list):

| Move | Energy | Stamina | If winded, extra energy |
| :--- | ---: | ---: | ---: |
| Signature | 45 | 30 (the cap) | 60 |
| Beam, top stage | 50 | 30 (the cap) | 60 |
| Beam, first stage | 12 | 8.4 | 16.8 |
| Zip strike / zip heavy | 20 / 30 | 14 / 21 | 28 / 42 |
| Burst | 30 | 21 | 42 |
| Reversal | 20 (10 after two seconds of guard) | 14 (7) | 28 (14) |
| Dodge that cancels a move | 15 | 10.5 | 21 |
| Energy blast / bolt | 8 / 1 | 5.6 / 0.7 | 11.2 / 1.4 |
| Plain heavy / plain medium | 5 / 1 | 3.5 / 0.7 | 7 / 1.4 |

The model page writes the dodge as "so 10". The rule gives 10.5 and the sim does not round, so 10.5 is what it charges (section 4, row 10).

Three losses of energy are not spends and cost no stamina, because the other fighter caused them: the guard's energy drain (`damage.gd:89`), the guard break's 25 (`melee.gd:249`) and the old automatic clash's 40 (`beam.gd:101`).

**The energy actually taken.** Eight of the 34 lines stop at 0 energy and so can take less than their price: `exchange.gd:297`, `melee.gd:91`, `stance.gd:83`, `stick.gd:154` and `:733`, `beam_move.gd:116` and `:289`, and the air brake (`brake.gd:168`). The brake also keeps working with no energy at all, at half strength (`brake.gd:163`). At those eight the hook reads the fighter's energy before the line and charges 0.7 of the difference after it. So a fighter with no energy who brakes pays no stamina for energy they never paid. The other 26 lines subtract their price whole, so the price is what was taken.

### 3.3 Stamina: what refills it

| Refill | Amount | Data key | Where it hooks |
| :--- | :--- | :--- | :--- |
| A plain blow that lands | Light 3, medium 5, heavy 8 | `stamina.refill` | `sim/director/melee.gd`, in `strike` after `:347` |
| ... pressed well timed | × 1.5 | `stamina.timedMul` | The press's tag is `DirAlchemy.TIMED`. **Inside a brawl the tag is never set today** (`alchemy.gd:212-215`), so there the × 1.5 cannot be earned until section 4, row 24 is ruled |
| ... mashed | × 0.35 | `stamina.mashMul` | The tag is `DirAlchemy.MASHED`, or the blow's weight is a mash's (`brawl.gd:387-388`) |
| ... blocked | × 0.5 | `stamina.blockedMul` | The same test as `melee.gd:352` |
| ... missed, parried or perfectly blocked | Nothing | | `strike` returns before `:347`, or the damage is 0 |
| A quick stick flick | As a medium (5) | `stamina.refill.stickQuick` | Stick level 0 or 1 (`brawl.gd:373-375`) |
| A charged stick strike below its top stage | As a heavy (8) | `stamina.refill.stickCharged` | Stick level 2. Level 3, the top, refills nothing |
| A grab that lands | As a heavy (8) | `stamina.refill.grab` | `sim/director/grapple.gd:541` |
| Resting | 12 a second × (0.6 + 0.6 × body share), × 0.85 with battered legs | `stamina.regenPerSec`, `stamina.bodyRegen`, `stamina.legsBatteredMul` | `SimVitals.step`, called from `sim/core/fighter.gd` after `:716` |
| A new form | To the new ceiling | `form.staminaRefill`, `stamina.formCeiling` | `sim/core/fighter.gd:27`, `tierUp` |

Energy moves refill nothing: beams, bolts and blasts, flight strikes and zips, the Driver, mines, the full hold's send. Encounter marks a blow as plain through one helper, `DirMelee.mark` (new, 6.5), which writes `"refill"` into the blow's options **only while the loop is on**. A blow without the mark refills nothing. With the loop off the mark is never written: a blow's options are often a beat's own arguments, and a beat's arguments are hashed (`sim/core/hash.gd:142-147`), so an ungated key would change the hash of every match.

**What "resting" means here.** A fighter rests on a tick when they spent no stamina since their last step and they are not one of the two fighters in the running exchange. That is the test wound fading already uses (`wounds.gd:178-180`). Inside an exchange only plain blows refill. The model page says "Resting (no spending)" and, in its runaway section, that "breaking away refills stamina at 12 a second"; this page takes the second as the meaning of the first. `stamina.restInExchange` (0) is the share of resting that still runs inside an exchange, so the other reading is one number away (section 4, row 4).

Checked sums (scratch model): resting gives 14.4 a second at a full body, 10.8 at half, 7.2 at empty. Empty to full takes 6.9, 9.3 and 13.9 seconds. After a signature and a 20-energy special (100 − 30 − 14 = 56), the way back to 100 is four ordinary light-light-medium strings (11 each, before the medium's own 0.7 charge) or twelve mashed ones (3.85 each). Three well-timed strings (16.5 each) would do it too, but only in a planned exchange: in a brawl no press is tagged well timed today (row 24).

**Stamina a second, by how the blows are pressed.** The sums above are by the blow. The brawl is paced by its own gaps (`data/director/interrupts.json` `brawl`: a light flurry's presses are 6 to 12 ticks apart, a medium's 12 to 16, a heavy's 28 to 34), and the mash tag needs three presses inside 20 ticks (`alchemy.gd:22`, `:203`), so presses 11 or more ticks apart are not tagged mashed. With the first values, the plain blows paying the 0.7 rule (a medium costs 1 energy, a heavy 5):

| How the blows are pressed | Ticks apart | Landed, stamina a second | Blocked, a second | What the guarding fighter pays, a second |
| :--- | ---: | ---: | ---: | ---: |
| Lights, one at a time, just outside the flurry | 13 | +13.8 | +6.9 | 6.9 |
| A light flurry, at its slowest (flurry weight, × 0.35) | 12 | +5.25 | +2.6 | 7.5 |
| A light flurry, at its fastest | 6 | +10.5 | +5.25 | 15 |
| Mediums, at their fastest | 12 | +21.5 | +9.0 | 15 |
| Mediums, at their slowest | 16 | +16.1 | +6.75 | 11.25 |
| Heavies, at their fastest | 28 | +9.6 | +1.1 | 12.9 |
| Heavies, at their slowest | 34 | +7.9 | +0.9 | 10.6 |
| For scale: resting at a full body, half, empty | | 14.4, 10.8, 7.2 | | |

What that says, by arithmetic only (no run; whether the brawl really treats a light 13 ticks after the last as a lone light was read from the data's gaps, not from the code, not verified):
- **The best refill is a steady beat just outside the mash lines.** Mediums on a 12-tick beat give 21.5 a second landed, more than resting at a full body, and still 9 a second into a guard. A medium inside its own flurry keeps a medium's weight (`brawl.gd:383-388`), so the mash share never touches it.
- **One tick of spacing changes a light's refill 2.6 times** (13.8 against 5.25).
- **A signature's 30 comes back in about 1.4 seconds of landed mediums.** That is a very short respite.
- **A held guard is winded from full in under 7 seconds** by mediums at their fastest (15 a second), and by this page's reading of resting (row 4) the guard gets nothing back while it lasts.

That reads as a metronome rewarded, which is not what "mashing refills a third" was for. It is section 4, row 23 and reading R24, and it has to be ruled together with rows 4 and 7.

### 3.4 The body: what reaches it

Each time `hurt` takes damage from a fighter, the body loses **damage × severity × share**.

| | Sound | Bruised | Battered | Broken | Data key |
| :--- | ---: | ---: | ---: | ---: | :--- |
| Share of a hit on the head, arms or legs, by that part's stage | 0 | 0.12 | 0.28 | 0.5 | `body.spill` |
| × the core's gate, by the core's stage | 0.6 | 1.0 | 1.5 | 2.0 | `body.coreGate` |
| Share of a hit on the core, by the core's stage | 0.05 | 0.25 | 0.5 | 0.8 | `body.coreSpill` |

- A limb's share after the gate is capped at 0.9 (`body.spillCap`).
- Severity is the same factor that worsens the wear (3.5).
- The stage read is the one the hit met, before this hit's own wear moves it.
- A guarded hit lands on the arms (the guard family's weights are 0, 0, 1, 0 in `wounds.json`), so it uses the arms' row, on the damage after the guard has cut it.
- The body never rises in a match. Two lines that raise the old hit points today are switched out while the loop is on: the meteor landing's floor of 200 (`sim/director/arc.gd:358`) and the hiding kit's heal (`sim/core/fighter.gd:714-715`, dead for today's roster).
- **Body share** is `hp ÷ maxhp`. It feeds resting (3.3) and the power fill (3.5).

Checked sums (scratch model): damage needed to empty a 1,600 body if the state never changed.

| The hit lands on | Share | Rested | Winded |
| :--- | ---: | ---: | ---: |
| The core, sound | 0.05 | 32,000 | 20,000 |
| The core, bruised | 0.25 | 6,400 | 4,000 |
| The core, battered | 0.5 | 3,200 | 2,000 |
| A bruised limb, core sound | 0.072 | 22,222 | 13,889 |
| A battered limb, core bruised | 0.28 | 5,714 | 3,571 |
| A battered limb, core battered | 0.42 | 3,810 | 2,381 |
| A broken limb, core broken | 0.9 (capped) | 1,778 | 1,111 |

For scale: a plain light is about 8 damage, a medium about 20 and a heavy about 48 before the fighter's own multiplier (`data/director/interrupts.json` `brawl`: 26 × 0.31, × 2.5, × 6).

### 3.5 The connecting rules

| Orb's rule (`vision.md:1756`) | As a number | Data key | Where it hooks |
| :--- | :--- | :--- | :--- |
| "high body gives a bonus to stamina regeneration" | Resting × (0.6 + 0.6 × body share) | `stamina.bodyRegen` | `SimVitals.step` |
| "high stamina keeps energy energy gain boosted" | Every energy gain × (0.75 + 0.5 × stamina share) | `energyFromStamina` | `fighter.gd:710-711` (regen), `:767` (charging), `damage.gd:90` (hit gain), and the director's rewards in 3.9 |
| "taking damage with low stamina increases severity of injuries" | Each hit's wear × (1 + 0.6 × (1 − stamina share)): 1.0 rested, 1.3 at half, 1.6 at empty | `severityMax` | `wounds.gd:126-131`, `wearK`, the one factor both wear paths use |
| "taking damage with injuries starts affecting body" | 3.4 | `body.*` | `damage.gd:21-43`, `hurt` |
| "encourages reaching new forms" | A new form refills stamina to the new ceiling and eases wear by 20 on every part that is not broken | `form.*` | `fighter.gd:27`, `tierUp` |
| The hurt fighter reaches a form sooner (Orb: "yes", `vision.md:1785`) | Power from damage taken × (1 + 0.8 × (1 − body share)), up to 1.8 | `power.hurtBoost` | `damage.gd:91` |
| Charging reads stamina | Power while charging × the same stamina factor as energy | `energyFromStamina` | `fighter.gd:768` |

Stamina share is stamina ÷ the ceiling. Checked sums: at a full stamina, regen is 6.25 a second and charging 37.5; at empty, 3.75 and 22.5. Five heavies on a sound arm make 9.1 wear rested and 14.5 winded. A heavy taken gives 0.29 power at a full body and 0.52 at an empty one.

**When the hurt fighter's boost arrives.** It multiplies only the power that comes from damage taken (`data/fight/ladder.json` `takenPerDamage` 0.006). It does not touch the fill by time (0.05 a second), by charging (0.5 a second) or by damage dealt (0.0037). It reaches 1.8 only at an empty body, which is the brink itself. In the toy fight the body is still at about 0.72 of its top (rested) to 0.82 (winded) when the core reaches wear 30 with 3 hits in 10 guarded, so at the moment a fighter falls behind the boost is about 1.14 to 1.22 on one of four sources. The model page lists it among the pull-backs against the runaway. By these numbers it arrives late (section 4, row 25; reading R26).

**The form's limits.** A broken part does not ease (`form.mendBroken` false), which keeps a crippled limb broken for the match, as Wounds has it (`wounds.gd:465`). The model page's own limit, that a form never lifts a fighter off the brink, is read on its own (`form.neverOffBrink` true): whatever `mendBroken` says, a broken part that makes the brink is never eased below its broken line. With today's values the first test already covers it. The second is there so that one changed value cannot undo the ruling. The body does not heal.

### 3.6 Winded

A fighter is winded from the tick their stamina reaches 0 until it is back at `stamina.winded.recoverAt` (15). While winded:

| Effect | Number | Data key | Where it hooks |
| :--- | :--- | :--- | :--- |
| Their plain blows are weaker | × 0.8 | `stamina.winded.blowMul` | `damage.gd`, in `hit`'s multiplier after `:69`, for an exchange of kind light, medium or heavy |
| Flat-out flight is slower | × 0.8 | `stamina.winded.flightMul` | `fighter.gd:735-741` and `kick.gd:120` (3.10) |
| Stamina they lack is paid from energy | 2 energy a point | `stamina.winded.energyPerPoint`, and `stamina.winded.lackFromEnergy` for which spends it covers | `SimVitals.spend` |
| Hits injure them more | × 1.6 at zero | `severityMax` | 3.5 |

No press is refused and no input is held. The only gate on input in the sim's core stays the stun (`wounds.gd:272-309`), which this page does not touch. Every energy gate keeps checking the energy price alone, as today. So a winded fighter with exactly 45 energy can still fire a signature: it takes the 45, then asks for 60 more for the 30 stamina they lack, and they end at 0 energy.

**What the fall-through covers, and what it does to a winded fighter.** The model page says "any stamina you lack is paid from energy", under "No press is ever refused". This page's first value takes "any" at its word and applies it to every spend: pressed moves, flat-out flight, the slip, the guard's cost and the air brake (`lackFromEnergy`, five values, all true). That is a reading, not a ruling (section 4, row 20). With it, a winded fighter's own ways out all get dearer at once:

| What the winded fighter does | Energy it takes | Beside it |
| :--- | ---: | :--- |
| Holds LT flat out | 12 a second (6 stamina lacked × 2) | 3.75 a second comes in at empty stamina. They also fly a fifth slower, and they never rest while LT is held |
| Holds the air brake | 48 a second (its own 20, and 14 stamina lacked × 2) | 60 energy is gone in 1.25 seconds, and then the brake works at half strength |
| The dodge that cancels a move | 36 (its own 15, and 10.5 × 2) | |
| A slip | 10 | |
| Guards a heavy, a medium, a light | 12, 6, 3 a blow | On top of the guard's own energy drain. Under a fast flurry that is up to ten payments a second, each with the fall-through's cue |

The model page's first pull-back against the runaway is "breaking away refills stamina", and Game Design's ruling on the gravity well says "The energy-paid escape stays the fast, clean exit" (`docs/design/gravity-well-reading.md:63`). By these numbers, fleeing flat out and the paid escape are the routes a winded fighter can least afford. Row 20 proposes that only pressed moves fall through, and that the other four simply stop at zero stamina with no energy taken and no cue.

**When energy is short too, the rest is dropped.** `spend` stops at 0 energy and nothing is owed afterwards. So a winded fighter with exactly a move's price in energy pays no stamina price for it at all, as in the example above. The model page does not say what happens then (section 4, row 21). A spend by the second sends no cue each tick; the winded state's own start cue and signals carry it.

The model page says "At zero you're winded" and does not say when it ends. Without an exit line, any refill would end it on the next tick, the 0.8 factors would barely bite, and QA's "time spent winded" would have nothing to count (section 4, row 5).

### 3.7 The brink and the end

- The brink comes when the core breaks, as today, **or** when the body reaches 0 (`brink.bodyEmpty`). `SimWounds.updateStages` (`wounds.gd:213-218`) gets the second test, and `hurt` calls it on the hit that empties the body.
- Only a finisher ends a match. `HP_ENDS_MATCH` stays false (`wounds.gd:38`). The finisher contest, the set-up count and the time cap are not touched.
- **Vitality** reads the nearer road: 1 − the larger of (core wear ÷ 90, body lost ÷ body top). It is `SimWounds.brinkProgress` (`wounds.gd:236-241`) with one more term while the loop is on. The comeback, the computer's stance weights (`sim/director/ai.gd:84`) and the ending's standing read (`sim/director/ending.gd:76`) all follow it with no change of their own.
- **A brink by the empty body cannot be rallied.** A Rally mends a broken region, and the body never refills, so `rallyRegion` finds nothing that takes the fighter off the brink. The model page does not say this; it follows from its two rules together. It needs Game Design's ruling (section 4, row 9).
- Guards and other bodies past the two principals have a body and stamina like anyone, and still no brink (`wounds.gd:217`).

Which road comes first? The scratch model (one fighter only takes hits; a toy, not the sim) gives, over 400 trials each:

| Case | Core breaks first | Body empties first | Damage taken to reach the brink | Body left when the core breaks |
| :--- | ---: | ---: | ---: | ---: |
| Loop off (today) | 100% | 0% | 16,600 | not used |
| Rested, guards 3 hits in 10 | 97% | 4% | 16,700 | 430 of 1,600 |
| Winded, guards 3 in 10 | 94% | 6% | 7,800 | 450 |
| Rested, guards 7 in 10 | no brink inside an hour | | | |
| Winded, guards 7 in 10 | 6% | 94% | 19,200 | 90 |

What that says, to be measured in the real sim before anyone trusts it: the core stays the usual road, as the model page wants; the body is close behind it (about a quarter left when the core breaks); a fighter who mostly guards is only ever ended by the body, and only if they let themselves stay winded; and being winded more than halves the damage it takes to reach the brink (2.1 times, not 1.6, because fading does not speed up to match). The last one is the runaway risk in one number, and it is reading R10.

### 3.8 The comeback and the old meters

The comeback for every fighter and the old meters set to zero land in the first milestone's second window, before any of this (the amended first-milestone brief for Simulation, line 51). This spec assumes both are in. If they are not, every reading here with "loop off" is taken against the wrong game.

When the data file exists, the comeback's two numbers get a home in it: `comeback.cap` 0.5 and `comeback.exponent` 2, read in every match, per fighter. Today the cap sits in one fighter's meters file and the 2 is a literal (`damage.gd:54`). How Simulation states it "in data for both fighters" in the first milestone is not parked yet, so the move is a step of this build only if it is still needed (not verified).

The model page's lever stands: if the fighter who falls behind first wins more than 45%, the cap drops to 0.35; it is never raised.

### 3.9 Energy's literals: the re-count, and where each goes

**The count.** Three ways, because the earlier figure (321 lines in 55 files, 51 literals) could not be reproduced with any one search (not verified):

| What is counted | Lines | Files |
| :--- | ---: | ---: |
| The whole word `ki` in GDScript under `sim/`, tests, tools and checks left out | 221 | 30 |
| ... tests, tools and checks included | 406 | 76 |
| ... and the JS core too | 436 | 87 |
| Reads or writes of a `.ki` field (a fighter's energy or a price in data), shipped code | 148 | 22 |
| Lines that write a fighter's energy | 47 | 18 |
| The readers' full table (energy, power and level together) | 199 rows | 33 |

Of the 47 writes, 36 take energy away and 11 add it. Of the 11, one is a refund of a price (`zip.gd:378`) and one is a price difference written as an addition (`chase_tap.gd:188`). The readers' table has each line by file and kind: 47 prices, 42 gates, 39 reads by the computer, 20 gains, 17 displays, 15 model reads, 7 state, 3 setup, 3 cooldown sets, 3 score reads, 2 drains, 1 clamp. It is Appendix A at the end of this page (file and line, kind, and what the line does), so that it outlives the scratch folder it was made in.

**The literals, by meaning, and their new home.** About 70 literal numbers in runtime code, plus 16 caps of 100 written as clamps (10 of energy, row 2; 6 of power, row 29) and one inside a banner's text. They come to 31 meanings.

| # | Value | Meaning | Where today | Goes to | Owner |
| ---: | ---: | :--- | :--- | :--- | :--- |
| 1 | 60 | Energy at the start | `state.gd:1077` | `vitals.json` `energy.start` | Simulation |
| 2 | 100 | Energy's top (10 clamps) | `fighter.gd:711`, `:767`; `damage.gd:90`; `interrupt.gd:306`, `:318`, `:337`; `melee.gd:301`, `:308`; `blast.gd:410`; `zip.gd:378` | `energy.max` | Simulation, then Encounter's lines |
| 3 | 5 | Regen a second | `fighter.gd:685` | `energy.regenPerSec` | Simulation |
| 4 | 25 | Extra regen while hidden (dead for today's roster) | `fighter.gd:685` | `energy.hiddenRegenPerSec` | Simulation |
| 5 | 1 | Regen's floor under the old meter's penalty | `fighter.gd:695` | `energy.regenFloor` | Simulation |
| 6 | 30 | Energy a second while charging | `fighter.gd:767` | `energy.chargePerSec` | Simulation |
| 7 | 0.85 | Speed kept each tick while charging (4 lines) | `fighter.gd:762-766` | `energy.chargeKeep` | Simulation |
| 8 | 1.35 | Damage taken while charging | `damage.gd:84` | `energy.chargingHitMul` | Simulation |
| 9 | 0.04 | Energy gained per point of damage dealt | `damage.gd:90` | `energy.hitGainPerDamage` | Simulation |
| 10 | 0.08 | Energy lost per point of damage guarded | `damage.gd:89` | `energy.guardDrainPerDamage` | Simulation |
| 11 | 45 | The signature's price and gate (9 lines in 5 files) | `exchange.gd:281`, `:348`; `beam.gd:41`, `:129`, `:134`; `beamplay.gd:100`, `:591`; `brawl.gd:713`; `ai.gd:425` | `interrupts.json` `prices.signature`, read once by a helper. The banner's "NEED 45 KI" (`exchange.gd:283`) reads it too | Encounter |
| 12 | 4 | The classic heavy's price and gate | `exchange.gd:294`, `:343` | `prices.heavy` | Encounter |
| 13 | 2 | A blind swing at a hidden target | `exchange.gd:297` | `prices.blindSwing` | Encounter |
| 14 | 6, 5 | A chain link's price and gate; the chain's most links | `exchange.gd:595`, `:786` | `prices.chainLink`, `prices.chainMax` | Encounter |
| 15 | 40 | The heavy-blast answer to a beam, and the old automatic clash (5 lines) | `beam.gd:42`, `:101`, `:138`, `:140`; `beamplay.gd:594` | `prices.heavyBlastAnswer`, `prices.autoClash` | Encounter |
| 16 | 3 | A pursuit that slips away | `melee.gd:91` | `prices.slipAway` | Encounter |
| 17 | 25 | Energy a guard break takes | `melee.gd:249` | `prices.guardBreakDrain` | Encounter |
| 18 | 8 | The parry's reward in the parity profile | `melee.gd:301` | `prices.parryParity` | Encounter |
| 19 | 10, 0.35, 16 | The beam contest's score: tier × 10, energy × 0.35, a draw up to 16 | `beam.gd:208`, `:245` | `prices.beamScore` | Encounter |
| 20 | 85 | The computer stays hidden under this energy | `ai.gd:111` | `ai.json` `energy.hideUntil` | Encounter |
| 21 | 55, 350 | The computer charges under this energy, beyond this gap (2 lines) | `ai.gd:177`, `:225` | `energy.chargeBelow`, `energy.chargeMinGap` | Encounter |
| 22 | 50 | The computer fires its signature from this energy | `ai.gd:274`; `brawl.gd:4119` | `energy.sigAt` | Encounter |
| 23 | 25 | The computer's patient reversal needs more than this | `interrupt.gd:560` | `energy.patientReversalAbove` | Encounter |
| 24 | 10 | The computer's reserve over a zip's price (2 lines) | `zip.gd:1421`, `:1429` | `energy.zipReserve` | Encounter |
| 25 | 25, 1.2, 40, 20, 30 | Fallbacks that repeat keys the data already has | `ai.gd:103`, `:294`; `chase.gd:74` | Nowhere: the keys exist and are read. Drop the fallbacks only if the loader errors on a missing key | Encounter |
| 26 | 0.8, 0.2 | A second copy of the model's level | `beam_move.gd:67` | Its own keys in `interrupts.json` `beamPlays.front.ownMove`: `levelTier` 0.8, `levelPower` 0.2. **Not** a call to `SimPower.level`: that reads `data/fight/power.json`, which is folded into a replay's data hash only while the model's switch is on (`replay.gd:193-194`). With the model off, as in main, a tuned share there would change beam stages without moving the hash. `interrupts.json` is always hashed (`sim/director/data.gd:55`) | Encounter |
| 27 | 2, 4, 6 | Beam and strike stages: 2 + 4 × level, 2 to 6 | `beam_move.gd:72` | `interrupts.json` `beamPlays.front.ownMove` (`stagesMin`, `stagesSpan`, `stagesMax`) | Encounter |
| 28 | 0.5, 25 | A beam crater's power from the ladder | `sim/world/crater.gd:66-67` | World's data. It still reads the ladder at 25 a tier while the thresholds are 35, 65, 100 | World |
| 29 | 100 | Power's top (6 clamps) | `fighter.gd:661`, `:768`; `damage.gd:91`, `:92`; `wounds.gd:469`; `collateral.gd:408` | Stays in code as one named constant: the model's level divides by it | Simulation |
| 30 | 430, 2.4 | The plain dash, copied inside the model | `power.gd:248` (from `fighter.gd:609`, `:623`) | Flight, not energy. Not in this build | Simulation |
| 31 | 3 | Level × 3 indexes the four-tier tables | `sim/world/brunt.gd:605`, `:612` | Stays: it is the tier count | World |

Rows 1 to 10 are the model page's list ("start, cap, regen, the charge rate, hit gain and guard drain") plus the three that sit in the same lines. They are read in every match, so they sit in a block of the data file that the switch does not gate (section 4, row 1).

Unread keys that look live: `data/input/timing.json` `attackQueue.signatureKi` (45) and `heavyKi` (4) match rows 11 and 12 and nothing reads them. Their owner retires them when the prices land, or two files will disagree one day.

**The 34 spend lines that get the 0.7 rule**, with the kind each passes. One call is added after each (and one read of the energy before each of the eight in 3.2 that can stop at 0), and the spend itself is left exactly as written, so nothing moves with the switch off.

| Kind | Lines |
| :--- | :--- |
| signature | `exchange.gd:348`, `beam.gd:134` |
| beam | `beam.gd:140`, `beam_move.gd:289`, `beamplay.gd:213` |
| shot | `blast.gd:185`, `:192`, `:279`; `brawl.gd:798`; `driver.gd:119` |
| flight | `chase.gd:173`, `:188`; `chase_tap.gd:188` (on the difference paid); `zip.gd:455`, `:726`; `zip.gd:201` (a flight move's wound blow) |
| defence | `bands.gd:541`; `blast.gd:254`; `interrupt.gd:456`, `:507`, `:583` |
| special | `stance.gd:83`; `melee.gd:91` (a pursuit that slips away); `exchange.gd:297` (a blind swing); `stick.gd:733` when the strike is released at its top level, 3, which is the full hold's send |
| plain | `brawl.gd:815`, `:3302`, `:3314`; `exchange.gd:343`, `:595`; `stick.gd:154`; `stick.gd:733` at levels below 3 |
| hold (a price by the second) | `beam_move.gd:116`, `driver.gd:106` |
| brake | `sim/core/brake.gd:168` |

`stick.gd:733` is one line that passes one of two kinds by the level it is released at, so the lines still count 34: 2, 3, 5, 6, 5, 3, 7, 2 and 1, with that line counted under plain.

"Plain" holds only blows that can refill: the face buttons' blows and the stick strike below its top level. A move that refills nothing is never in it, so the proposal in section 4, row 7 (plain blows free of the rule) cannot quietly free a move the model page names as an energy move. The model page says of the full hold's send and flight strikes that they "are energy moves, so they spend stamina by the 0.7 rule".

Each kind has its own share in `stamina.ofEnergyBy`, all 0.7 as ruled. Two of them are flagged for Game Design in section 4 (rows 7 and 8): plain blows, and the air brake.

**The energy gains that take the stamina factor:** regen (`fighter.gd:711`), charging (`:767`), the hit gain (`damage.gd:90`), a perfect block or deflect (`interrupt.gd:306`, `:318`, `:337`; `blast.gd:410`) and a parry (`melee.gd:301`, `:308`). The refund (`zip.gd:378`) gives back a price and is not scaled.

The 34 lines are the 37 that take energy away (the 36 above and `chase_tap.gd:188`), less the three losses in 3.2 that the other fighter caused. Their line numbers come from a search of main at 752c381f; the search's list and the readers' table agree.

### 3.10 How it joins what exists

| What exists | What changes | What does not |
| :--- | :--- | :--- |
| The energy model (`power.json`, on in Orb's builds) | Nothing in it. It reads tier and power, never the energy meter. Winded flight multiplies the speed after the model has set it | Send speeds, the slip's own speed, the flat-out base |
| The kick (`sim/core/kick.gd`) | `_kept` holds a flight's best speed until the flight ends, so the winded factor is applied after it (`kick.gd:120`). Applied before, a fighter who ran dry mid-flight would never slow | The kick's own state and switch |
| The ladder and forms | A tier rise calls the form's refill and easing. Power from damage taken is boosted by a low body. Charging's power reads stamina | The ladder stays one number that keeps counting. A form does not use power up (section 4, row 6) |
| Wounds | `wearK` takes the severity factor; `updateStages` and `brinkProgress` take the body's road; `step` hands its "in the exchange" test to a helper so resting can share it | Region pick and its one draw, fades, second breath, the crippling moment, the Rally |
| Damage | `hurt` takes the body's share instead of the full amount while the loop is on. `hit` takes the winded blow, the guard's stamina cost and the power boost | The stance table, the combo growth, hit-stop, the event |
| Guard | A guarded blow now costs stamina. It is the guard's first cost by the blow other than energy | The guard still costs nothing by the second. The perfect block is free |
| The match's end | The brink gets a second road | The contest, the time cap's rungs, the idle rule (its doubled wear is wear only, not body) |
| The computer | Reads vitality, so it reads the body with no change. Needs three stamina habits (below) or the measurement is of a computer that ignores the loop | Its energy thresholds move to data unchanged |
| The old meters | Assumed zeroed (3.8) | Their code stays until after Alpha |
| The hiding kit | Its heal of the old hit points is switched out while the loop is on | Dead for today's roster either way |

**The computer's three habits** (Encounter's code; their numbers sit in `data/fight/vitals.json` `computer`, in the loop's part of the file, and are read only while the loop is on). They are not in `data/director/ai.json` because the whole text of that file is folded into every replay's data hash (`sim/director/data.gd:53`, `sim/director/ai.gd:372`), so tuning them there would void saved matches and split a LAN pair even with the loop off:
1. Winded or under `breakAwayBelow`, and not the one pressing: the escape weight rises, as it does today for low energy (`ai.gd:103`, `lowKi`).
2. It does not start a signature or a special whose stamina it lacks unless it can also pay the extra energy (`ai.gd:274`, `brawl.gd:4119`).
3. It lets go of flat-out flight when winded unless it is fleeing.

These are stated as intent, not designed to the line. Encounter owns them.

### 3.11 How the player reads it with no bars

Orb's rule (`vision.md:1740`): "go with recommended", which was no health bars on screen. Orb on marks (`vision.md:1802`): "LETS TREAT THESE SHAPES AS PLACEHOLDERS FOR DIEGETIC AURAS, GLOWS, FLARES ETC. THAT SHOWCASE GAME MECHANICS WHERE NECESSARY. UI/UX ELEMENTS MUST BE NON-INTRUSIVE, RULE-OF-COOL, PROTECT PLAYER AGENCY AND ENJOYMENT, RESPECT THE SPECTACLE". Nothing below is drawn on, over or between the fighters: each signal is the fighter's own body, their own aura, the ground they stand on, or the pad in the player's hands.

**Every row is a placeholder.** VFX owns the aura and ground columns, Animation the body, Controls the pad, Audio the sound. Each visible change passes the look gate, and the EP takes the safety reading on any aura change before it lands.

**One meaning to a channel.** At this game's speed a player cannot tell four meanings apart on one look, and Orb's words are that whatever is built "has to complement high speed combat" (`vision.md:1735`). So, as placeholders: the aura's **size** is energy and nothing else. The aura's **steadiness** is the core and nothing else, as VFX's worn read has it today. **Stamina never touches the aura**: it lives in posture, breath and the pad. **The body** lives in the fighter's stance and in the ground under them, so it can be read without a knock-down and from a still. The form-ready flare and a new form's burst are moments, as today, not a standing look.

| What the player needs to know | The fighter's body | The aura | The ground | The pad (your own) | Sound | Sim hands the view |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Energy: how much | | Size: larger with more, small when low | | | | `f.ki`, state |
| Energy: charging (RT held) | The charge pose, as today | Grows while it fills | Dust and sparks at the feet, as today | A slow rising rumble | The charge loop, as today | `f.state`, state |
| Stamina: fine | Normal breathing | | | | | `f.vit.st`, state |
| Stamina: low (under 30) | Shoulders heave; the idle sags | | | A slow heartbeat | Audible breath | Cues `stamina_low` and `stamina_ok` |
| Winded | Bent, hands dropping between blows; flat-out flight visibly labours | | | The heartbeat, faster | Ragged breath | `f.vit.winded`; cues `winded` and `winded_end` |
| A move took energy because stamina ran out | A stumble in the follow-through | | | One sharp knock | A cough or grunt | Cue `stamina_lack` |
| A plain blow gave stamina back | The recovery of the blow is crisper when well timed | | | | A sharper exhale on a well-timed one | Nothing new: the damage event |
| The body: how much is left | A lasting change of stance: they stand lower and carry their weight unevenly, more so with less body. Slower get-ups. Marks on the torso of their own kind that stay through a form | | Less dust lifts under them as they move and land, and almost none near empty (an example for VFX to replace) | | Strained voice | `f.hp ÷ f.maxhp`, state |
| The core is hurt | An arm across the ribs | Steadiness: wavers, as VFX's worn read does today | | | | `f.stage`, the `region_stage` event, both as today |
| A limb is hurt or broken | The arm hangs, the leg drags, as today | | | | | The same |
| A form is ready | | Flares | Small debris lifts at the feet | | | `f.act.formReady`, as today |
| A new form eased the injuries | Marks fade one step; posture straightens | Burst | The power-up's own crater, as today | A deep pulse | | Cue `form_mend`; `tier_up` as today |

- The pad signals go only to the fighter's own player. Controls' pulse code reads events, never state, which is why the low and winded lines are sent as a start and an end.
- The winded idle that Animation plays today when energy is under 6 (`render/anim/anim_fighter.gd:2910`) should read stamina once it exists; energy has the aura.
- Marks must be able to fade or the form's easing cannot be seen (Rendering's row, `render/core/fighter_view.gd:266-271`).
- Two kinds of mark share the torso and must not be confused. An injury mark sits on the hurt part and steps down when a form eases that part. A body mark sits on the torso only, never steps down in a match, and should look like a different kind of damage (worn or torn, say, against bruised). Art and Rendering own the look.
- The aura's steadiness already means the core today (`render/vfx/react.gd:82-89`). The draft of this page also thinned the aura for a winded fighter and dipped it for the fall-through. Both are dropped: with them the aura carried four meanings.
- The corner plate keeps its energy line and power pips. Game Design has ruled no stamina bar, and that UI may propose a thin stamina line there behind the look gate (the model page, section 9). Whether Orb is asked first is the EP's call; a draft question is in section 11.

## 4. Departures and proposals

Each row is for Game Design to rule. "Departs" means this page's first value differs from the model page's words. "Fills" means the model page is silent and the build needs an answer. "Proposes" means this page follows the ruling and suggests a change.

| # | What | The ruling | This page | Why |
| ---: | :--- | :--- | :--- | :--- |
| 1 | **Departs.** Where energy's literals live | Section 8: the file is "behind `enabled`, off", and energy's literals "move to data" (no file named) | An `energy` block in the same file that is read in every match; `enabled` gates the loop only | Energy cannot be switched off. One file keeps one home for the model. The block is hashed apart from the loop's numbers so tuning the loop while it is off does not void saved matches (6.1) |
| 2 | **Fills.** The comeback's two numbers | Cap 0.5 and the power of 2, no data home named | `comeback.cap`, `comeback.exponent` in the always-read part | "Stated in data for both fighters" (Simulation's first-milestone brief) needs a home that is not one fighter's meters file |
| 3 | **Departs.** The meter loader | Section 8: "the meter loader has to accept the new kind" | Stamina does not go through `meters.json`. The loader fix stays its own small job with its own fixture test | A meter in that loader is a number fed by sources with effects from a fixed list (`fighter_data.gd:20-23`). Stamina is spent and refilled from about forty places and needs state that is hashed only while on |
| 4 | **Departs.** Resting | "Resting (no spending)" | Resting also needs the fighter to be out of the running exchange. `stamina.restInExchange` 0 | Read literally, a guarding fighter rests on every tick between blows. A light flurry costs the guard 7.5 to 15 a second (lights 12 to 6 ticks apart) and resting returns 10.8 to 14.4 at half a body or more, so only the fastest strings (15 a second) could wind a guard, and slowly, and the model page's own runaway section would describe almost nothing. 1 restores the literal reading. The other side of this choice is in 3.3's table: with no rest in an exchange, mediums at their fastest wind a held guard from full in under 7 seconds. Rule it with rows 7 and 23 |
| 5 | **Fills.** When winded ends | "At zero you're winded" | It ends at `recoverAt` 15 | 3.6. 0 restores the literal reading |
| 6 | **Departs.** A form and power | Section 2: "A new form uses it up" | The ladder is left as built: one number that keeps counting to 100, thresholds 35, 65, 100 | The code never resets power on a form (`fighter.gd:590-602`), and a reset would change how fast the second and third forms come. If the sentence is meant as a rule it is a new rule and needs numbers |
| 7 | **Proposes.** Plain blows and the 0.7 rule | "Any move that spends energy also spends 0.7 of that energy as stamina" | Follows it: `ofEnergyBy.plain` 0.7. Proposes 0 | Plain mediums and heavies cost 1 and 5 energy today. With the rule, a heavy that lands nets +4.5, a blocked one +0.5, a mashed one −0.7 and a miss −3.5. Orb's words (`vision.md:1787`): "attacking with normal face-button attacks should be a respite between special or signature attacks". The model page's own list of energy moves does not name plain blows. The proposal covers only the kind "plain" in 3.9, which holds only blows that can refill, so no move that refills nothing is freed. With 0, every per-second figure in 3.3's table rises (mediums at their fastest to 25 a second), so rule it with rows 4 and 23 |
| 8 | **Proposes.** The air brake | The same rule | Follows it: `ofEnergyBy.brake` 0.7, so 14 stamina a second while braking. Proposes 0 | The brake is what a fighter who has just been sent flying presses. Taxing it winds the fighter who is already losing |
| 9 | **Fills.** A brink by the empty body | "Leaving the brink stays the Rally's job"; the body refills "never, in a match" | No Rally lifts it (`brink.bodyRally` false). This follows "never, in a match" | 3.7. The other answer is a Rally that gives back a small share of the body once, so both roads allow one; it would be the one time any of the body came back, against the model page's words. Draft question 3 in section 11 is for Orb only if Game Design does not rule first |
| 10 | **Departs.** The dodge's stamina | "its 15 energy, so 10" | 10.5 | 0.7 × 15. The sim does not round |
| 11 | **Fills.** What counts as a hit on the body | "Each hit that lands" | Every damage through `hurt`: blows, shots, beams, and also landings, slides and collisions | Wear already takes all of them through the same line, and the body is the attrition clock. `body.fromLandings` false leaves landings out |
| 12 | **Departs.** A form's easing | "eases every part's wear by 20" | Every part that is not broken (`form.mendBroken` false). The model page's `form.neverOffBrink` is read on its own as well (3.5) | A crippled limb is "broken for the match" (`wounds.gd:465`) and broken regions never fade (`wounds.gd:168-169`). Easing one would undo the crippling moment |
| 13 | **Proposes.** Flat-out flight far from the fight | 6 a second, wherever | Follows it: `flatOutWithin` 0 (everywhere). Proposes a distance | At 3,500 a second a full stamina lasts 16.7 seconds: 58,000 units. A lap of the medium planet is 44 seconds and of the huge one 176 (`planet-a1-design.md:47`). On the two largest sizes a fighter crossing to the fight arrives winded. Game Design rules the number first. Draft question 2 in section 11 is about the feel, and is for Orb only after that, if it is still open |
| 14 | **Fills.** Stamina at the start, and after a form | Not said | Starts at 100. The ceiling rises 15 a tier: 115, 130, 145 | The workshop toy did the same |
| 15 | **Fills.** What a guarded shot or beam costs | Light 1.5, medium 3, heavy 6 "a blow" | A bolt as a light, a heavy shot or a guarded beam as a heavy | The same split the guard's wear uses (`damage.gd:106-111`) |
| 16 | **Fills.** Which gains take the stamina factor | "every gain", three named | The three, plus perfect-block, deflect and parry rewards. Refunds are not scaled | 3.9 |
| 17 | **Fills.** The winded blow | "your blows land at 0.8 strength" | Blows of an exchange whose kind is light, medium or heavy, thrown by either fighter in it: a brawl's second fighter and a parry's riposte count. Not beams or shots, a shot fired inside an exchange included | Beams and shots are paid for in energy and stamina already. The test is on the blow, not on who started the exchange: the broken-arm rules beside it read only the fighter who started it (`damage.gd:62-69`), and copying that here could leave a brawl's second fighter at full strength while winded (whether that fighter is ever "the one who started it" in the core's eyes was not verified, so the test does not lean on it) |
| 18 | **Notes.** The model page's dates | "Until the body exists (GW1)"; the comeback "lands in GW1" | The body exists from the third milestone's window; the comeback lands in the first milestone's second window | The path and the amended brief say so |
| 19 | **Notes.** The workshop pages | Flat costs of 15 and 30; mashing costs 12 a second; guarding costs 0.8 of the damage; stages at 25, 50, 80; a body of 100; a form needs 50 energy | Superseded by the model page throughout: the 0.7 rule, mashing only refills less, flat guard costs, stages at 30, 60, 90, a body of 1,600, no energy price on a form | The toy's result tables do not carry over. Section 9's model replaces them |
| 20 | **Fills.** What the energy fall-through covers | "any stamina you lack is paid from energy at 2 energy a point", said under "No press is ever refused" | Every spend: pressed moves, flat-out flight, the slip, the guard's cost, the air brake (`winded.lackFromEnergy`, five values, all true). **Proposes** pressed moves only: the other four stop at zero stamina, take no energy and send no cue | 3.6's table. The ruling speaks of presses. Applied to everything, a winded fighter's flight, brake and paid escape all cost energy they are not getting back, and a guarded flurry sends up to ten fall-through cues a second |
| 21 | **Fills.** The debt when energy is short as well | Not said | Dropped: energy stops at 0 and nothing is owed. A spend by the second sends no fall-through cue each tick | Nothing is refused, and a carried debt would be one more hashed number. The cost: a winded fighter with exactly a move's price pays no stamina price for it (R6). "Never silent" is met for by-the-second spends by the winded state's own start cue and signals, not by a cue a tick |
| 22 | **Departs.** The cap of 30 | "at most 30 a move" | At most 30 a payment | Most moves pay once. Those that pay more than once: a held beam (2.8 a second while held at its top stage, then up to 30 on firing); the Driver (2.8 a second while loaded, then 16.8 at its top level, so past 30 after about 4.7 seconds loaded); a flight strike paid in two parts (for example 14, then 7); a charged heavy (3.5, then 2.1); a stick strike (two small parts). Only the first two can pass 30, and only by seconds held. The other answer is a running total for the move, kept in the fighter's stamina state and cleared when the move ends: one more hashed field, and an "end of move" call in each of those files |
| 23 | **Proposes.** Refill by the second | Refill is by the blow: 3, 5, 8, "×0.35 mashed (Controls' press read)" | Follows it. Proposes one of: the mash share for any light or medium thrown inside its own weight's flurry gap, read from the gap and not from the tag; or a cap on refill a second, near resting (a new key, and one more hashed field to count it) | 3.3's table: mediums on a steady 12-tick beat refill 21.5 a second landed, more than resting at a full body, and 9 a second into a guard; one tick of spacing changes a light's refill 2.6 times. Reading R24. Rule it with rows 4 and 7 |
| 24 | **Fills.** What "well timed" means in a brawl | "×1.5 well timed ... (Controls' press read)" | The press's tag. Inside a brawl that tag is never "timed" today (`alchemy.gd:212-215`: a press in a brawl neither earns nor loses flow), and the brawl is on in main's data (`interrupts.json` `brawl.enabled`). So until this is ruled the × 1.5 exists only in planned exchanges, and perhaps in a blur string (not verified) | For Game Design and Controls. Either the refill reads Controls' grade of the press against the blow's own contact (the grade exists: `alchemy.gd:219`), or the × 1.5 is stated as a planned-exchange rule only. Without a ruling, QA's comeback batches run with the rule dead in the close fight |
| 25 | **Proposes.** What the hurt fighter's boost reads | "× (1 + 0.8 × (1 − body share)), so up to 1.8 times" | Follows it. Proposes reading 1 − vitality (the nearer road, which 3.7 already works out) in place of body share alone | 3.5: by body share the boost is about 1.14 to 1.22 at the moment a fighter falls behind, and 1.8 only on the brink. Keyed to the nearer road it would be about 1.27 at that moment whichever road got them there. Reading R26 |
| 26 | **Fills.** What QA's two markers mean with the loop on | "'Falls behind' means the first to reach a third of the way to the brink"; the stamina gap "averaged over a match" | "Falls behind" is the first fighter whose `brinkProgress` reaches one third, by the nearer road (core wear over 90, or body lost over body top). With the loop off that is core wear 30, as today. The stamina gap is averaged over the whole match, with the two fighters named leader and trailer by who fell behind first; a match where nobody falls behind is left out of the gap and counted | The model page's section 4 gives the nearer road for vitality. The draft of this page used core wear 30 in both arms and averaged from the tick; both are now saved only as second columns, so the arms can also be compared like for like. In the toy a fighter who guards half their hits has lost a third of the body before core wear 30 in 83 trials in 100, so the two markers name different fighters exactly in the guarding case |
| 27 | **Fills.** Three small rules the data adds | "Flying flat out (LT held)"; no low line; nothing on a blow both mashed and well timed | Flat out also needs the stick past half (`flatOutStick` 0.5). The low line for the signals is 30 (`lowAt`). A blow that is both mashed and well timed counts as mashed | LT held with the stick at rest is not flying. The signals need one line to start and end on. Mashing should not be rescued by one lucky press |
| 28 | **Proposes.** A question to Orb on a stamina line | Section 9, headed "Calls this page makes (no question to Orb)": to "A stamina bar?" the answer is "None.", and "UI may propose a thin line on the corner plate, behind the look gate" | Follows it: nothing new on screen, and no line is built by this spec. Section 11 keeps a draft question that reopens the ruling, for the EP to use only if the EP wants Orb's word before UI spends on a proposal | It is Game Design's ruling to reopen, not this page's |

## 5. Data

### 5.1 `data/fight/vitals.json` (new)

Why here: it is the file the model page names; `data/fight/` holds the game's shared rules with a per-fighter file of differences laid over them, as `wounds.json` and `ladder.json` already are. A fighter's own `data/fighters/<id>/vitals.json` is optional and holds only differences, by the loader's existing rule (`fighter_data.gd:281-321`). It may not carry `enabled`.

```json
{
  "schema": "vitals/1",
  "_about": "Energy, stamina and the body (docs/design/energy-stamina-body.md). energy and comeback are read in every match. Everything else is the loop, read only while enabled is true or a match's setup says vitals true. Every number is Game Design's first value.",
  "enabled": false,

  "energy": {
    "start": 60, "max": 100,
    "regenPerSec": 5, "hiddenRegenPerSec": 25, "regenFloor": 1,
    "chargePerSec": 30, "chargeKeep": 0.85, "chargingHitMul": 1.35,
    "hitGainPerDamage": 0.04, "guardDrainPerDamage": 0.08
  },
  "comeback": { "cap": 0.5, "exponent": 2 },

  "body": {
    "fromMaxHp": true, "refillPerSec": 0, "fromLandings": true,
    "spill": [0, 0.12, 0.28, 0.5],
    "coreGate": [0.6, 1.0, 1.5, 2.0],
    "coreSpill": [0.05, 0.25, 0.5, 0.8],
    "spillCap": 0.9
  },
  "stamina": {
    "start": 100, "max": 100, "formCeiling": 15,
    "regenPerSec": 12, "bodyRegen": [0.6, 0.6], "legsBatteredMul": 0.85, "restInExchange": 0,
    "refill": { "light": 3, "medium": 5, "heavy": 8, "stickQuick": "medium", "stickCharged": "heavy", "grab": "heavy" },
    "timedMul": 1.5, "mashMul": 0.35, "blockedMul": 0.5,
    "ofEnergy": 0.7, "moveCap": 30,
    "ofEnergyBy": { "signature": 0.7, "beam": 0.7, "shot": 0.7, "flight": 0.7, "defence": 0.7, "special": 0.7, "plain": 0.7, "hold": 0.7, "brake": 0.7 },
    "flatOutPerSec": 6, "flatOutStick": 0.5, "flatOutWithin": 0,
    "slip": 5,
    "guard": { "light": 1.5, "medium": 3, "heavy": 6 },
    "lowAt": 30,
    "winded": { "blowMul": 0.8, "flightMul": 0.8, "energyPerPoint": 2, "recoverAt": 15,
      "lackFromEnergy": { "move": true, "flatOut": true, "slip": true, "guard": true, "brake": true } }
  },
  "energyFromStamina": [0.75, 0.5],
  "severityMax": 0.6,
  "power": { "hurtBoost": 0.8 },
  "form": { "staminaRefill": true, "mendWear": 20, "mendBroken": false, "neverOffBrink": true },
  "brink": { "coreBroken": true, "bodyEmpty": true, "bodyRally": false },
  "computer": { "breakAwayBelow": 20, "breakAwayWeight": 1.2, "keepForBigMove": true, "dropFlatOutWinded": true }
}
```

- The model page's keys are kept exactly. Added: `schema`, `_about`, `energy`, `comeback`, `body.fromLandings`, `stamina.start`, `restInExchange`, `ofEnergyBy`, `flatOutStick`, `flatOutWithin`, `lowAt`, `winded.recoverAt`, `winded.lackFromEnergy`, `form.mendBroken`, `brink.bodyRally`, `computer`.
- `winded.lackFromEnergy` says which spends fall through to energy when stamina runs out (3.6; section 4, row 20). "move" is every pressed move under the 0.7 rule, the by-the-second holds included.
- `form.neverOffBrink` is read (3.5, 6.3). A key that looked live and was not read would be the same trap as the two in `timing.json` (3.9).
- `computer` holds the numbers for the computer's three habits (3.10). They are placeholders for Encounter. They sit here, in the loop's part, so that tuning them with the loop off moves no saved match (6.1).
- `brink.coreBroken` repeats what `wounds.json` already says of the core (`regions.core.brink`). The loader pins it to true, as it pins other mirrored values (`fighter_data.gd:701`).
- `body.fromMaxHp` is pinned to true: the body's top is the fighter's `stats.maxhp`.
- `body.refillPerSec` is the model page's lever and stays 0.
- `flatOutWithin` 0 means everywhere. A value in units means "only while the rival is nearer than this".

**Schema, same commit:** `tools/schemas/fighter-vitals.schema.json`, named as `fighter-ladder.schema.json` and `fighter-wounds.schema.json` are. How the data job maps a schema to a file was not opened (Tools'; not verified). It should hold at least:

| Key | Rule |
| :--- | :--- |
| `enabled` | boolean; refused in a fighter's own file |
| `energy.start`, `energy.max` | 0 ≤ start ≤ max; max > 0 |
| every `*PerSec`, price and refill | number ≥ 0 |
| `chargeKeep`, every `*Mul`, `spillCap`, `restInExchange` | number in 0 to 1, except `timedMul`, `chargingHitMul` (≥ 1) and `legsBatteredMul` (0 to 1) |
| `spill`, `coreGate`, `coreSpill` | four numbers, each list not falling from left to right |
| `bodyRegen`, `energyFromStamina` | two numbers, [low, span], both ≥ 0 |
| `refill.stickQuick`, `stickCharged`, `grab` | a number, or one of "light", "medium", "heavy" |
| `ofEnergyBy` | exactly the nine kinds; each 0 to 1 |
| `winded.lackFromEnergy` | exactly the five spends (`move`, `flatOut`, `slip`, `guard`, `brake`); each a boolean |
| `form.staminaRefill`, `mendBroken`, `neverOffBrink`; `brink.*`; `computer.keepForBigMove`, `dropFlatOutWinded` | boolean |
| `computer.breakAwayBelow`, `breakAwayWeight` | 0 ≤ below ≤ `stamina.max`; weight ≥ 0 |
| `winded.recoverAt`, `lowAt` | 0 ≤ value ≤ `stamina.max` |
| `comeback.cap` | 0 to 0.5 (the model page: never raised) |
| `mendWear` | 0 to 100 |

### 5.2 `data/director/interrupts.json`: a new `prices` block (Encounter)

Why here: every newer price already lives in this file and `DirInterrupt` already reads it.

```json
"prices": {
  "_about": "The classic exchange's energy prices, moved out of code with their values unchanged (sim/director/exchange.gd, beam.gd, beamplay.gd, melee.gd, brawl.gd, ai.gd).",
  "signature": 45, "heavy": 4, "blindSwing": 2,
  "chainLink": 6, "chainMax": 5,
  "heavyBlastAnswer": 40, "autoClash": 40,
  "slipAway": 3, "guardBreakDrain": 25, "parryParity": 8,
  "beamScore": { "tierWeight": 10, "kiWeight": 0.35, "drawMax": 16 }
}
```

Schema: `tools/schemas/director-interrupts.schema.json`. `beamPlays.front.answerKi` (40) stays the stick fire-back's own key.

The same file's `beamPlays.front.ownMove` block gains five keys with today's values (3.9, rows 26 and 27): `levelTier` 0.8, `levelPower` 0.2, `stagesMin` 2, `stagesSpan` 4, `stagesMax` 6.

### 5.3 `data/director/ai.json`: one new block (Encounter)

```json
"energy": { "hideUntil": 85, "chargeBelow": 55, "chargeMinGap": 350, "sigAt": 50, "patientReversalAbove": 25, "zipReserve": 10 }
```

Schema: `tools/schemas/director-ai.schema.json`. The values are today's literals.

**These two director files are hashed whole, whatever any switch says.** The replay's data hash folds in the full text of `ai.json` and of `interrupts.json` (`sim/director/data.gd:53`, `:55`; `sim/director/ai.gd:372`). So adding these blocks moves every replay's data hash once (step 2), and any later edit to either file moves it again. That is why the computer's stamina habits are not here: their numbers are in `vitals.json` `computer` (5.1), where the loop's part is hashed only for a match with the loop on. An earlier draft of this page had them in `ai.json` and promised they could be tuned freely with the loop off; that promise did not hold.

### 5.4 Other files

| File | Change | Owner |
| :--- | :--- | :--- |
| `data/input/timing.json` `attackQueue.signatureKi`, `heavyKi` | Retired, or wired to read `prices` | Controls |
| `tools/ratchet-fighter-specific.json` `systems.stamina` | Lists `sim/core/vitals.gd`; `body` gains `sim/core/wounds.gd` if Tools agrees | Tools |
| `tools/preview/switches.mjs` | One row for `vitals`, as the kick's row at `:228` | Tools |
| `data/fighters/<id>/vitals.json` | None needed for the three fighters today | Game Design, later |

## 6. Pseudocode and hooks

Line numbers are main's at 752c381f. From there to 78425d6d nothing under `sim/`, `net/` or `data/` changed but one new tool file, so they hold at both. Every function named exists with the signature shown unless it is marked new. Fighters are "they" in comments too.

### 6.1 Hash discipline

| Piece | Exists | Hashed | Why the hash is unchanged with the switch off |
| :--- | :--- | :--- | :--- |
| `f.vit` (`st`, `busy`, `winded`) | Only while `S.vitalsOn`; null otherwise, as `f.kik` is (`state.gd:1112`) | `hash.gd`, a gated line beside the kick's at `:201-203`; `net/desync.gd`, beside `:105-107` | The gated line appends nothing when off |
| `S.vitalsOn` | Always (a bool on the state, beside `kickOn` at `state.gd:91`) | Not itself: what it gates is | As `kickOn` |
| `f.hp` as the body | Always | Already in `SimHash.FIGHTER` (`hash.gd:6`) and so already in the LAN check | Off, `damage.gd:26` runs exactly as today |
| `f.vd` (the fighter's `VitalsDef`) | Always | No: it is data, covered by the data hash, as `f.wd` and `f.ld` are (`state.gd:1122-1124`) | Not state |
| The `energy` and `comeback` blocks | Always read | Folded into each fighter's data hash under `vitals.base` | **This is the one thing that moves with the switch off: the replay data hash moves once**, when the file first lands with today's values. The state hash does not move, because the values are the literals. The roster's hash moves with it, and the GDScript golden file stores that hash (`rosterHash`, written at `sim/core/tools/golden_recipes.gd:109`, checked at `sim/core/tools/parity.gd:3656-3657`). So step 1 regenerates the golden file in the same commit, and only that one value may differ |
| The loop's numbers | Read only while on | Folded into a replay's data hash only for a match with the loop on, beside the kick's at `replay.gd:195-196` | The fold is skipped when off. So Game Design can tune the loop while it is off without voiding a saved match |
| Cues | Sent only while on | In the event hash as plain `cue` events (`hash.gd:441`); no new event type | None sent when off |
| A plain blow's mark (`refill` and `mash` in the blow's options) | Only while `S.vitalsOn`: `DirMelee.mark` writes nothing otherwise (6.5) | Yes, through the beat. A classic or brawl blow's options are its beat's own arguments (`exchange.gd:439`, `:484`; `brawl.gd:1281`, `:1385`), and every key of a beat's arguments is hashed (`hash.gd:62-76`, `:142-147`) | The mark is never written when off. Hit-stop's weight already follows this pattern, for this reason (`melee.gd:52-57`). **A key added to a blow's options without its switch changes the hash of every match** |
| The director's two data files (`ai.json`, `interrupts.json`) | Always read | Folded whole into every replay's data hash (`sim/director/data.gd:53`, `:55`) | They are not gated. Step 2 moves the replay data hash once, and so does any later edit to either file. No loop number lives in them (5.3) |

Folding only part of a file has a precedent: `replay.gd:223-225` folds only the `turn` block of World's rings file.

**The rule every hook follows:** a guarded statement added beside the old line, never a rewrite of the old line. With `f.vit == null` the same float operations run in the same order as today. No draw from `S.rng` is added, moved or removed; the loop makes no random draw at all.

**The golden window.** Steps 1 and 2 (literals into data) move the replay data hash and land in the third milestone's window, "The fight's rules". Step 1 also regenerates `sim/core/test/golden.json` in the same commit, because the roster's hash is stored there: only `rosterHash` may differ, every tick-0, match and replay hash in the file stays identical, and the report shows the diff. Step 2 should leave that file untouched: by its recipe it stores the roster's hash and a hash of four fight files, not the director's data (`golden_recipes.gd:104`, `:109`; read from the recipe, not run). Steps 3 to 6 land in the same window with the switch off and a line in each report showing the golden hashes identical. **Switching it on in main's data is its own change to the fingerprint**: it goes in the same window if QA's measurement and Game Design's ruling are in before the window closes, and otherwise in the fourth milestone's window, which is the last that takes rule changes. It should not ride in the "numbers only" window.

### 6.2 State, loading and setup

```gdscript
# sim/core/state.gd
# beside kickOn (:91)
var vitalsOn: bool = false            # the loop: data/fight/vitals.json's switch, or the setup's "vitals"

# beside KickState (:1038)
## A fighter's stamina while S.vitalsOn (sim/core/vitals.gd).
class VitalsState:
	var st: float = 0.0        # stamina now, 0 to the ceiling
	var busy: int = 0          # 1 when stamina was spent since their last step: no resting this tick
	var winded: bool = false   # from 0 until back at recoverAt

# in Fighter, beside kik (:1112) and wd, md, ld (:1122-1124)
var vit = null                   # VitalsState while S.vitalsOn, null otherwise
var vd = null                    # the fighter's FighterData.VitalsDef (data; covered by the data hash, not hashed here)
```

```gdscript
# sim/core/fighter_data.gd
# new class beside LadderDef (:110). Typed fields only: the tick never reads a Dictionary (:9).
class VitalsDef:
	var energyStart: float; var energyMax: float; var regen: float; var hiddenRegen: float; var regenFloor: float
	var chargePerSec: float; var chargeKeep: float; var chargingHitMul: float; var hitGain: float; var guardDrain: float
	var comebackCap: float; var comebackExp: float
	var spill: Array; var coreGate: Array; var coreSpill: Array; var spillCap: float; var fromLandings: bool
	var stStart: float; var stMax: float; var formCeiling: float
	var regenPerSec: float; var bodyRegenLow: float; var bodyRegenSpan: float; var legsBatteredMul: float; var restInExchange: float
	var refill: Array            # by SimVitals.R_*: light, medium, heavy, stickQuick, stickCharged, grab (names resolved to numbers at load)
	var timedMul: float; var mashMul: float; var blockedMul: float
	var ofEnergy: Array          # by SimVitals.K_*: the nine kinds
	var moveCap: float; var flatOutPerSec: float; var flatOutStick: float; var flatOutWithin: float; var slip: float
	var guard: Array             # light, medium, heavy
	var lowAt: float; var windedBlow: float; var windedFlight: float; var energyPerPoint: float; var recoverAt: float
	var lackPays: Array          # by SimVitals.S_*: move, flatOut, slip, guard, brake (booleans)
	var energyLow: float; var energySpan: float; var severityMax: float; var hurtBoost: float
	var formRefill: bool; var mendWear: int; var mendBroken: bool; var neverOffBrink: bool   # mendWear in wear units: points x SimWounds.WEAR_SCALE
	var bodyEmptyBrink: bool; var bodyRally: bool
	var aiBreakBelow: float; var aiBreakWeight: float; var aiKeepForBig: bool; var aiDropFlatOut: bool   # the computer's three habits; the director reads them

# _ensure (:161-162): the game's file, loaded with the other two
var sv = _load(shared + "vitals.json", "fight/vitals.json") if shared != "" else null

# _one(id, h, sw, sl) (:186) gains sv. After lj (:190):
var vj = _resolveQuiet(id, "vitals.json", sv)        # new: _resolve (:284) without the fold. Null, with _resolve's "missing too" error, when neither file exists
if not (fj is Dictionary and wj is Dictionary and lj is Dictionary and vj is Dictionary):   # the test at :191, with vj added
	return false                                        # energy is read in every match, so this file is not optional
def.vd = _vitals(id, vj)                              # new: vj -> VitalsDef, with _err on a bad or pinned key
var base := {"energy": vj.energy, "comeback": vj.comeback}
h.text(id + "/vitals.base"); _canon(h, base)          # the roster's hash, always
# ... and in the per-fighter hash (:204-209), one more part: ["vitals.base", base]
var hl := SimHash.Hasher.new()                        # the loop's numbers, hashed apart
hl.text(id + "/vitals.loop"); var loop: Dictionary = vj.duplicate(true); loop.erase("energy"); loop.erase("comeback"); loop.erase("enabled")
_canon(hl, loop); _loopHashes[id] = hl.hex()

static func loopHashOf(id: String) -> String          # new, as hashOf (:242)
static func vitalsEnabled() -> bool                   # new: the game's file's "enabled" == true
```

```gdscript
# sim/core/roster.gd, createFighter (:24-29)
f.vd = def.vd
f.ki = def.vd.energyStart          # was the class default 60.0 (state.gd:1077)

# sim/core/sim.gd, _mSetupsA, after the kick's two lines (:266-267)
S.vitalsOn = setup.get("vitals", SimVitals.enabled()) == true
SimVitals.setup(S)

# sim/core/hash.gd, after the kick's block (:201-203)
if S.vitalsOn:   # the loop: only when on, so a match without it hashes as before
	_obj(out, f.vit, SimVitals.HASHED)

# net/desync.gd, after the kick's block (:105-107)
if S.vitalsOn:
	for f in S.fighters:
		_fields(v, md, f.vit, SimVitals.HASHED)

# sim/core/replay.gd, dataHash, after the kick's lines (:195-196)
if setup.get("vitals", SimVitals.enabled()) == true:
	h.text("vitals")
	for id in setup.get("slots", FighterData.order().slice(0, 2)):   # the same default as :237
		h.text(FighterData.loopHashOf(String(id)))

# net/snapshot.gd:152, the list of data definitions a snapshot shares instead of copying
# gains FighterData.VitalsDef. VitalsState is an inner class of SimState and is copied by reflection with no change.
```

**The file is not optional, and the parity gate's fixtures must know it.** The parity gate already loads fixture folders with no shared folder at all (`sim/core/tools/parity.gd:3752`), and its fixtures copy only `wounds.json` and `ladder.json` into each fighter's folder (`:3702`, `:3721`). Without the null test above, `vj.energy` would stop that gate with a script error, and every fighter would lack `vd`. So step 1 also edits `parity.gd`: the fixtures copy or expect `vitals.json` exactly as they do the other two, and one new case checks the "vitals.json is missing too" message.

### 6.3 `sim/core/vitals.gd` (new, class `SimVitals`)

```gdscript
class_name SimVitals
extends RefCounted
## Stamina, and what it and the body do to each other (docs/design/energy-stamina-body.md). The switch is
## data/fight/vitals.json "enabled" (off), copied into S.vitalsOn unless the setup has its own "vitals". Off, nothing
## here runs, no state exists and nothing is hashed. No draw from S.rng anywhere here.

const HASHED: Array = ["st", "busy", "winded"]
const K_SIGNATURE: int = 0; const K_BEAM: int = 1; const K_SHOT: int = 2; const K_FLIGHT: int = 3; const K_DEFENCE: int = 4
const K_SPECIAL: int = 5; const K_PLAIN: int = 6; const K_HOLD: int = 7; const K_BRAKE: int = 8
const R_LIGHT: int = 0; const R_MEDIUM: int = 1; const R_HEAVY: int = 2; const R_STICK_QUICK: int = 3; const R_STICK_CHARGED: int = 4; const R_GRAB: int = 5
const S_MOVE: int = 0; const S_FLAT: int = 1; const S_SLIP: int = 2; const S_GUARD: int = 3; const S_BRAKE: int = 4   # what a spend is, for winded.lackFromEnergy

static func enabled() -> bool:
	return FighterData.vitalsEnabled()

static func setup(S: SimState) -> void:
	for f in S.fighters:
		f.vit = SimState.VitalsState.new() if S.vitalsOn else null
		if f.vit != null:
			f.vit.st = minf(f.vd.stStart, ceiling(f))

static func ceiling(f) -> float:
	return f.vd.stMax + f.vd.formCeiling * (f.tier - 1.0)

static func share(f) -> float:          # stamina share, 0 to 1
	return clampf(f.vit.st / ceiling(f), 0.0, 1.0)

static func bodyShare(f) -> float:
	return clampf(f.hp / maxf(1.0, f.maxhp), 0.0, 1.0)

static func energyMul(f) -> float:      # callers guard on f.vit != null
	return f.vd.energyLow + f.vd.energySpan * share(f)

static func severity(f) -> float:
	return 1.0 + f.vd.severityMax * (1.0 - share(f))

## What of amt reaches the body from a hit on region, by the stages it met.
static func bodyLoss(f, region: int, amt: float) -> float:
	var d = f.vd
	var cs: int = f.stage[SimWounds.CORE]
	var sh: float = d.coreSpill[cs] if region == SimWounds.CORE else minf(d.spillCap, d.spill[f.stage[region]] * d.coreGate[cs])
	return amt * severity(f) * sh

static func powerTakenMul(f) -> float:
	return 1.0 + f.vd.hurtBoost * (1.0 - bodyShare(f))

static func flightMul(f) -> float:
	return f.vd.windedFlight if f.vit.winded else 1.0

## Stamina goes. What they lack comes out of energy where the data says this kind of spend falls through, said with its
## own cue. What energy cannot cover is dropped, not owed. Nothing is refused here or anywhere.
static func spend(S: SimState, f, amt: float, src: int, perSecond: bool = false) -> void:
	var v = f.vit
	if v == null or amt <= 0.0:
		return
	var was: float = v.st
	v.busy = 1
	if v.st >= amt:
		v.st -= amt
	else:
		if f.vd.lackPays[src]:
			f.ki = SimMathx.jmax(0.0, f.ki - (amt - v.st) * f.vd.energyPerPoint)
			if not perSecond:
				SimFx.cue(S, f, "stamina_lack", "", "")
		v.st = 0.0
	_edges(S, f, was)

## The 0.7 rule: one call after each energy spend. energy is what the spend line actually took: its price where the line
## subtracts it whole, and the fall in the fighter's energy across the line where the line can stop at 0.
static func tax(S: SimState, f, energy: float, kind: int) -> void:
	if f.vit != null and energy > 0.0:
		spend(S, f, minf(f.vd.moveCap, f.vd.ofEnergy[kind] * energy), S_BRAKE if kind == K_BRAKE else S_MOVE, kind == K_HOLD or kind == K_BRAKE)

## A plain blow landed, or was blocked.
static func refill(S: SimState, f, row: int, timed: bool, mashed: bool, blocked: bool) -> void:
	var v = f.vit
	if v == null:
		return
	var g: float = f.vd.refill[row] * (f.vd.mashMul if mashed else (f.vd.timedMul if timed else 1.0))
	if blocked:
		g *= f.vd.blockedMul
	var was: float = v.st
	v.st = minf(ceiling(f), v.st + g)
	_edges(S, f, was)

## Once a tick from stepFighter, after SimWounds.step.
static func step(S: SimState, f, dt: float) -> void:
	var v = f.vit
	var d = f.vd
	var was: float = v.st
	if v.busy == 0:
		var r: float = d.regenPerSec * (d.bodyRegenLow + d.bodyRegenSpan * bodyShare(f))
		if SimWounds.battered(f, SimWounds.LEGS):
			r *= d.legsBatteredMul
		if SimWounds.inExchange(S, f):
			r *= d.restInExchange
		v.st = minf(ceiling(f), v.st + r * dt)
	v.busy = 0
	_edges(S, f, was)

## The low line and the winded state, each told once as it starts and once as it ends.
static func _edges(S: SimState, f, was: float) -> void:
	var v = f.vit
	var d = f.vd
	if not v.winded and v.st <= 0.0:
		v.winded = true
		SimFx.cue(S, f, "winded", "", "")
	elif v.winded and v.st >= d.recoverAt:
		v.winded = false
		SimFx.cue(S, f, "winded_end", "", "")
	if was >= d.lowAt and v.st < d.lowAt:
		SimFx.cue(S, f, "stamina_low", "", "")
	elif was < d.lowAt and v.st >= d.lowAt:
		SimFx.cue(S, f, "stamina_ok", "", "")

## A new form: stamina to the new ceiling, and every part that is not broken eases.
static func onForm(S: SimState, f) -> void:
	var v = f.vit
	var d = f.vd
	var was: float = v.st
	if d.formRefill:
		v.st = ceiling(f)
	_edges(S, f, was)
	var changed: bool = false
	for r in range(4):
		var broken: bool = f.stage[r] == 3
		if f.wear[r] <= 0 or (broken and not d.mendBroken):
			continue                                   # a broken part stays broken: a crippled limb, and the core on the brink
		var w: int = maxi(0, f.wear[r] - d.mendWear)
		if broken and d.neverOffBrink and f.wd.brinkRegion[r]:
			w = maxi(w, f.wd.stageAt[2])               # the model page's limit, read on its own: never eased below the broken line
		if w != f.wear[r]:
			f.wear[r] = w
			changed = true
	if changed:
		SimWounds.updateStages(S, f)
	SimFx.cue(S, f, "form_mend", "", "")
```

`busy` is read one tick late for a spend the director makes, because the director's update runs after the fighters' step (`fighter.gd:643-645`). That is fixed and the same on every machine.

### 6.4 The core's hooks

```gdscript
# sim/core/damage.gd, hurt (:21-43)
if f.vit == null:                                                                       # :26, as today
	f.hp = f.hp - amt if SimWounds.HP_ENDS_MATCH else SimMathx.jmax(0.0, f.hp - amt)
# ... :27-33 unchanged: hurtT, breathT, the region and its one draw, the damage event ...
if region >= 0:                                                                         # :34
	if f.vit != null and (number or f.vd.fromLandings):
		f.hp = SimMathx.jmax(0.0, f.hp - SimVitals.bodyLoss(f, region, amt))            # the body, by the stages the hit met
	# :35-38 unchanged: addGuardWear or addWear
	if f.vit != null and f.vd.bodyEmptyBrink and f.hp <= 0.0 and not f.brink:
		SimWounds.updateStages(S, f)                                                    # a blocked light may add no wear, so ask

# sim/core/damage.gd, hit (:46-130)
# after the broken-arm lines (:62-69):
# Either fighter of the exchange, so a brawl's second fighter and a parry's riposte count. A shot fired inside an
# exchange names its own kind in its options (exchange.gd:1113) and is left out.
if A.vit != null and A.vit.winded and ex != null and (ex.kind == "light" or ex.kind == "medium" or ex.kind == "heavy") and String(o.get("kind", "")) == "":
	m *= A.vd.windedBlow
# :84   sm = D.vd.chargingHitMul                                        (was 1.35)
# :89   D.ki = SimMathx.jmax(0.0, D.ki - dd * D.vd.guardDrain)          (was 0.08)
# :90   var gain: float = dd * A.vd.hitGain                             (was 0.04)
#       if A.vit != null: gain *= SimVitals.energyMul(A)
#       A.ki = SimMathx.jmin(A.vd.energyMax, A.ki + gain)
# :91   var tk: float = dd * D.ld.taken
#       if D.vit != null: tk *= SimVitals.powerTakenMul(D)
#       D.power = SimMathx.jmin(100.0, D.power + tk)
# after hurt (:119), the guard's cost, read after the hit so the hit met the stamina they had:
if fam == "guard" and dd > 0.0 and D.vit != null:
	var row: int = 1 if (ex != null and ex.kind == "medium") else (0 if (block == SimWounds.BLOCK_LIGHT or block == SimWounds.BLOCK_SHOT) else 2)
	SimVitals.spend(S, D, D.vd.guard[row], SimVitals.S_GUARD)
```

```gdscript
# sim/core/wounds.gd
# wearK (:126-131), before the return:
if f.vit != null:
	k *= SimVitals.severity(f)

# step (:178-180): the test moves into a helper so resting shares it. The file's count of the spelling the
# two-fighter count watches stays the same: one read moves, none is added.
static func inExchange(S: SimState, f) -> bool        # new: the body of today's :178-179
# and step reads:  if inExchange(S, f): return

# updateStages (:213-218), after the loop over the brink regions:
if f.vit != null and f.vd.bodyEmptyBrink and f.hp <= 0.0:
	brink = true
# ... the principal test at :217 stays after it: a guard still has no brink

# brinkProgress (:236-241), before the return:
var p: float = minf(1.0, float(w) / float(f.wd.stageAt[2]))
if f.vit != null and f.vd.bodyEmptyBrink:
	p = maxf(p, 1.0 - SimVitals.bodyShare(f))
return p

# _brinkWith (:329-336), first line:
if f.vit != null and f.vd.bodyEmptyBrink and f.hp <= 0.0 and not f.vd.bodyRally:
	return true                                        # no mend lifts a brink the empty body made
```

```gdscript
# sim/core/fighter.gd
# tierUp (:27), first line:
if f.vit != null:
	SimVitals.onForm(S, f)

# stepFighter
# :685   var regen: float = f.vd.regen + (f.vd.hiddenRegen if f.hidden and f.canHide else 0.0)     (was 5.0, 25.0)
# :695   regen = SimMathx.jmax(f.vd.regenFloor, regen - pen)                                       (was 1.0)
# before :710:
if f.vit != null:
	regen *= SimVitals.energyMul(f)
# :711   f.ki = SimMathx.jmin(f.vd.energyMax, f.ki + regen * dt)                                    (was 100.0)
# :714   if f.hidden and f.canHide and f.vit == null:        # the old heal of the hit points: not while they are the body
# after SimWounds.step (:716):
if f.vit != null:
	SimVitals.step(S, f, dt)

# the free branch (:735-746)
var sp: float = flightSpeed(S, f, i.dash)                                                # :735, unchanged
var flat: bool = f.vit != null and i.dash and SimDetMath.hypot(i.mx, i.my) > f.vd.flatOutStick and SimDir.holdMove(S, f) == 1.0
if flat and (f.vd.flatOutWithin <= 0.0 or absf(dxo) <= f.vd.flatOutWithin):              # dxo: the gap read at :727
	SimVitals.spend(S, f, f.vd.flatOutPerSec * dt, SimVitals.S_FLAT, true)
if S.kickOn and SimDir.holdMove(S, f) == 1.0:
	SimKick.move(S, f, i, sp, k)                                                         # :738; the winded factor is applied inside, after _kept
else:
	if flat:
		sp *= SimVitals.flightMul(f)
	f.vx += (i.mx * sp - f.vx) * k                                                       # :740-741, unchanged
	f.vy += (i.my * sp * 0.85 - f.vy) * k
# :746
if S.slipOn and SimPower.slip(f, i.dash) and f.vit != null:                              # slip now returns true on the tick its brake starts
	SimVitals.spend(S, f, f.vd.slip, SimVitals.S_SLIP)

# charging (:762-768)
# :762-766   *= f.vd.chargeKeep                                          (was 0.85, four lines)
# :767       var ce: float = f.vd.chargePerSec * dt                      (was 30.0)
#            if f.vit != null: ce *= SimVitals.energyMul(f)
#            f.ki = SimMathx.jmin(f.vd.energyMax, f.ki + ce)
# :768       var cp: float = f.ld.charge * dt
#            if f.vit != null: cp *= SimVitals.energyMul(f)
#            f.power = SimMathx.jmin(100.0, f.power + cp)
```

```gdscript
# sim/core/kick.gd, move (:120), after  sp = _kept(S, f, flying, sp)
if f.vit != null and flying:
	sp *= SimVitals.flightMul(f)       # after the kept top speed, or a flight that began rested would never slow

# sim/core/power.gd, slip (:143): returns bool. True on the one tick f.slipT is set from 0 (:150-152), false otherwise.

# sim/core/brake.gd, around :168. The brake goes on working with no energy (:163), so the tax reads what was really taken.
var k0: float = f.ki                                   # before :168: a local read, the same with the loop off
# :168   f.ki = SimMathx.jmax(0.0, f.ki - kiPerSec * dt)   (unchanged)
SimVitals.tax(S, f, k0 - f.ki, SimVitals.K_BRAKE)      # after :168
```

`SimFighter.flightSpeed` itself is not changed, so its other readers (the computer at `ai.gd:363`, the arrival at `bands.gd:105`, `brawl.gd:1567`, `swing.gd:952`, the trail at `render/vfx/meteor.gd:306`) read the rested speed. That is a small untruth for a winded fighter; if any of them needs the true speed, it multiplies by `SimVitals.flightMul` itself.

### 6.5 The director's hooks (Encounter)

A director file may name a core class, so these call `SimVitals` directly. No core file names a director class, so the load-split gate (`sim/core/dir.gd:7-9`) is not touched.

```gdscript
# The 0.7 rule: one call after each spend in 3.9. The spend's own line is not edited. Where the line subtracts its price
# whole, the price is what was taken. For example:
# sim/director/exchange.gd:348
A.ki -= 45.0                                            # (becomes DirInterrupt's prices.signature in step 2)
SimVitals.tax(S, A, 45.0, SimVitals.K_SIGNATURE)
# sim/director/interrupt.gd:456
f.ki -= float(c.ki)
SimVitals.tax(S, f, float(c.ki), SimVitals.K_DEFENCE)
# sim/director/chase_tap.gd:188
A.ki += paid - cost
SimVitals.tax(S, A, cost - paid, SimVitals.K_FLIGHT)
# Where the line can stop at 0 (exchange.gd:297, melee.gd:91, stance.gd:83, stick.gd:154 and :733, beam_move.gd:116 and
# :289), read the energy before it and tax the fall. For example sim/director/stick.gd:733:
var k0: float = f.ki
f.ki = maxf(0.0, f.ki - (float(c.levels[l].ki) - float(c.levels[0].ki)))
SimVitals.tax(S, f, k0 - f.ki, SimVitals.K_SPECIAL if l >= 3 else SimVitals.K_PLAIN)   # level 3 is the full hold's send

# The energy rewards that take the stamina factor, for example sim/director/interrupt.gd:318
var rw: float = float(c.ki)
if d.vit != null:
	rw *= SimVitals.energyMul(d)
d.ki = SimMathx.jmin(d.vd.energyMax, d.ki + rw)

# The plain blow's mark: sim/director/melee.gd, beside weigh (:55-57) and on its pattern. Nothing is written while the
# loop is off, because a hit's options are often a beat's, and a beat is hashed.
static func mark(S: SimState, o, row: int, mash: bool = false) -> void:
	if S.vitalsOn and o is Dictionary and not o.has("refill"):
		o["refill"] = row
		if mash:
			o["mash"] = true

# The plain blow's refill: sim/director/melee.gd, strike, after SimDamage.hit (:347)
if dmg > 0.0 and a.vit != null and o.has("refill"):
	var pp: int = DirLaunch.phrase(S, ex, a)                                   # the press behind this blow (launch.gd:1183)
	var tag: int = ((pp >> 8) & 3) if pp >= 0 else DirAlchemy.PLAIN           # as :338-339 read it
	var blocked: bool = not o.get("ignoreStance", false) and (ex.sD if d == ex.D else ex.sA) == 1.0   # :352's test
	SimVitals.refill(S, a, int(o.refill), tag == DirAlchemy.TIMED, tag == DirAlchemy.MASHED or bool(o.get("mash", false)), blocked)
```

The press's tag is never `TIMED` inside a brawl today (`alchemy.gd:212-215`), so in a brawl the hook above can only ever pass plain or mashed (section 4, row 24). A light inside a live blur string may be the exception; whether a blur string can run in a brawl was not verified.

Who calls `DirMelee.mark`, beside the call to `DirMelee.weigh` that the sites I opened already make (`brawl.gd:1384`, `exchange.gd:483`, `:512`, `grapple.gd:540`). It is Encounter's call; this is the table to start from. No site writes `refill` or `mash` into a blow's options by hand, and no authored data carries either key:

| Blow | Where | `refill` | `mash` |
| :--- | :--- | :--- | :--- |
| A brawl light | `brawl.gd:1384-1385`, weight `light` | `R_LIGHT` | |
| A flurry, floor or burst light | weight `light_mash` (`brawl.gd:387-388`) | `R_LIGHT` | true |
| A brawl medium | weight `medium` | `R_MEDIUM` | |
| A brawl heavy, a double, the launcher | weight `heavy` or `launch` from a face button | `R_HEAVY` | |
| A stick strike, level 0 or 1 | `a.stick`, `stickL` < 2 (`brawl.gd:373-375`) | `R_STICK_QUICK` | |
| A stick strike, level 2 | `stickL` == 2 | `R_STICK_CHARGED` | |
| A stick strike at its top stage, a zip's blow, an energy reach | | none | |
| A grab that lands | `grapple.gd:541` | `R_GRAB` | |
| A classic exchange's strikes and chain links | `exchange.gd:484`, `:513` | by the exchange's kind; none for a signature | |
| A finisher's strikes | `exchange.gd:1234` | none | |

Three reads of the old hit points change while the loop is on:

```gdscript
# sim/director/arc.gd:358: the meteor landing's floor would heal the body
if f.vit == null:
	f.hp = maxf(f.hp, float(c.hpFloor))
# sim/director/camintent.gd:63-65: "nobody has been hit yet" can no longer read the hit points, which a limb hit leaves full
if float(f.hp) < float(f.maxhp) or (f.vit != null and f.wear[0] + f.wear[1] + f.wear[2] + f.wear[3] > 0):
	fresh = false
# sim/director/ending.gd:76 needs no change: with the ending off it reads hp over maxhp, which is now the body's share
```

## 7. What breaks

| What | How | Who fixes |
| :--- | :--- | :--- |
| QA's damage readings from the hit points | `qa/godot/gp.gd:79`, `:196`, `:205` and `qa/godot/stickplay.gd:256-262` measure damage as the fall in hit points. With the loop on that is the body's loss, a fraction of the damage. They already stop counting once the hit points reach 0, about a minute in. They should read the damage event's amount | QA |
| QA's records of "health share" | `qa/godot/records.gd:557`, `:696`, `:699` save hp over maxhp. With the loop on it becomes the body's share, which is the better read; older rows are not like for like | QA |
| The old overlay's bar | `render/core/hud.gd:219` (behind F2) draws the hit points. It would draw the body. Harmless, and the overlay is on the audit's list to go | Rendering |
| The camera's "first blood" tag | `camintent.gd:64`, 6.5 | Encounter, Camera to confirm |
| The camera's "comeback" tag and the computer's stance weights | Both follow vitality, which now reads the body too. The computer turns defensive a little sooner | Encounter reads it; no code |
| The meteor landing's floor | `arc.gd:358`, 6.5 | Encounter |
| Animation's winded idle | Plays on energy under 6 (`anim_fighter.gd:2910`). Should play on the winded state | Animation |
| Marks that never fade | A form's easing lowers a stage; the marks stay at the worst stage reached (`fighter_view.gd:266-271`) | Rendering |
| UI's stage model and cards | A form's easing sends `region_stage` events going down. Rally and fading already send them, so the path exists; whether a card shows for a falling stage was not checked (not verified) | UI |
| VFX's worn read | `render/vfx/react.gd:82-89` reads the core's stage and the brink. A brink by the body with a sound core would read as "on the brink" with no core injury. Correct, and worth one still | VFX |
| The pad | No pulse exists for a wound, the brink, low energy or a stun, so the heartbeat is a new kind, not a change (`sim/input/haptics.gd:306`, `:330-341`) | Controls |
| The flat-out dash's closing times | Game Design's targets after the 3,500 ruling (0.45 s from 1,000 units, 1.0 s from 3,000, 1.9 s from 6,000) are for a rested fighter. A winded one is a fifth slower. QA reads them rested | QA |
| VFX's flight trail | It starts at 3,500 a second (`data/vfx/meteor.json` `burn_from`, per `flight-3500.md`). A winded base fighter flies at 2,800 and shows none; at base a rested one is exactly on the line and shows none either. No change, and a free signal at higher tiers | None |
| Saved matches and LAN | Steps 1 and 2 each move the replay data hash once: every saved match made before them refuses to play, as with any data change in a window. A LAN pair must both have the files. Any later edit to `ai.json` or `interrupts.json` moves it again, whatever the loop's switch (6.1) | EP, at the window |
| The golden file | Step 1 changes the roster's hash, which `sim/core/test/golden.json` stores, so the parity gate fails until the file is regenerated in the same commit (6.1) | Simulation |
| The parity gate's loader fixtures | They copy only two shared files into a fixture folder. `vitals.json` becomes a third, or the gate stops on a script error (6.2) | Simulation |
| The JS core | It keeps the old literals. The parity run stays with the loop off. Moving literals to data must leave the parity run bit for bit the same | Simulation |
| The two counts | The two-fighter count is at its baseline (365) and counts comments. No line in 6 adds one of its four spellings; a builder's comment that writes one would. The fighter-specific count must list the new file | Simulation, Tools |
| The model's flat-out speed check | `sim/core/tools/power_check.gd` pins the flat-out range. Whether it runs any match long enough for a winded factor to show was not opened (not verified); it runs with the loop off by default either way | Simulation |
| The gravity well and the travelling beam, in the same window | Both change the exchange code these hooks sit in. The well's walk-out costs no energy (Game Design, `gravity-well-reading.md:12`), so no stamina. If the well changes what "in the exchange" means, resting follows it through the one helper | Simulation, Encounter |

## 8. Build order and owners

Each step lands behind the switch (or changes no value), with its own check. "Window" is the third milestone's golden window unless said.

| # | Step | Owner and paths | Needs first | Its check | Fingerprint |
| ---: | :--- | :--- | :--- | :--- | :--- |
| 0 | Rule on section 4's rows | Game Design: `docs/design/energy-stamina-body.md` | This page | The EP reads the rulings against Orb's words | None |
| 1 | Energy's core literals into data: the file, the `energy` and `comeback` blocks, the loader, the schema, rows 1 to 10 and 29 | Simulation: `sim/core/fighter_data.gd`, `roster.gd`, `state.gd`, `fighter.gd`, `damage.gd`, `sim/core/tools/parity.gd` (the loader fixtures), `sim/core/test/golden.json`; a grant for `data/fight/vitals.json`; Tools for the schema | The first milestone's windows closed; step 0's row 1 | `golden.json` regenerated in the same commit with only `rosterHash` changed: every tick-0, match and replay hash in it identical, and the diff in the report. The parity gate passes on the new file, its loader fixtures included. A lint that finds no energy literal in `sim/core/` (new, Tools) | State: none. Roster hash and replay data hash: move once |
| 2 | The classic prices and the computer's energy habits into data, rows 11 to 27 | Encounter: `sim/director/*.gd`, `data/director/interrupts.json`, `ai.json`; Controls for the two unread keys | Step 1 (for `energy.max`) | The parity gate passes with `golden.json` untouched; a count showing the signature's 45 and the answer's 40 are each read from data in one place, fallbacks aside (R2) | State: none. Replay data hash: moves once, and again on any later edit to these two files |
| 3 | The state and the switch: `SimVitals`, `VitalsState`, setup, the three registrations, the snapshot's list, resting, winded, flat-out, the slip, the brake, the cues | Simulation: `sim/core/vitals.gd` (new), `state.gd`, `sim.gd`, `hash.gd`, `replay.gd`, `fighter.gd`, `kick.gd`, `power.gd`, `brake.gd`; grants for `net/desync.gd` and `net/snapshot.gd` (Netcode) | Step 1 | `sim/core/tools/vitals_check.gd` (new), part A: readings R3 to R6. Off: golden hashes identical. On, run twice: the same hash | Off: none |
| 4 | Severity, the body, the brink's second road, vitality, the power boost, the form | Simulation: `damage.gd`, `wounds.gd`, `fighter.gd` | Step 3; step 0's rows 9, 11, 12 | `vitals_check` part B: readings R7 to R11 | Off: none |
| 5a | The 0.7 rule at the 33 director lines (the brake's line landed in step 3) | Encounter: the 15 director files in 3.9 | Step 3; step 0's rows 7, 8, 20, 21, 22 | `sim/director/tools/stamina_check.gd` (new), part A: it counts 33 calls and the brake's, 34 in all, and reads R3 from real moves. Stamina falls by 3.2's table | Off: none |
| 5b | The core's three hooks in `hit` (the winded blow, the guard's stamina cost, the hit gain's stamina factor), and the stamina factor on regen and on charging | Simulation: `sim/core/damage.gd`, `fighter.gd` | Steps 3 and 4; step 0's rows 15, 16, 17 | `vitals_check` part C: R14, and the gains at a full and an empty stamina (6.25 and 3.75 a second; 37.5 and 22.5 charging) | Off: none |
| 5c | The plain blow's mark and refill: `DirMelee.mark`, its call sites, the hook in `strike` | Encounter: `sim/director/melee.gd`, `brawl.gd`, `exchange.gd`, `grapple.gd` | Step 5a; step 0's rows 23, 24 | `stamina_check` part B: R12, R13 and R24. **With the loop off, no blow's options carry `refill` or `mash`, and the golden hashes are identical** | Off: none. On: the mark is in the beat's hash |
| 5d | The director's six reward lines' stamina factor, and the three hit-point reads | Encounter: `sim/director/interrupt.gd`, `blast.gd`, `melee.gd`, `arc.gd`, `camintent.gd` | Step 5b | `stamina_check` part C. QA's match checklist sees a refill, a special's spend and a signature's spend in one normal match | Off: none |
| 6 | The computer's three habits | Encounter: `sim/director/ai.gd`, `brawl.gd`; a grant for the `computer` block of `data/fight/vitals.json` | Steps 5a to 5d | The computer's winded share of a match is read (R19); no change with the loop off | Off: none |
| 7 | The measurement: the tool, the baseline with the loop off, then on, same seeds | QA: `qa/godot/comeback.gd`, `qa/godot/comeback.js` (new) | The baseline can start once the comeback for every fighter is on main; the rest needs step 6 | R15 to R19 and R25 to R27, saved under `docs/qa/runs/<sha>/` | None |
| 8 | The signals | Controls: `sim/input/haptics.gd`. Animation: `render/anim/`. VFX: `render/vfx/`. Rendering: `render/core/fighter_view.gd`. Audio: `audio/`. UI: `ui/`. Tools: the switch row and the ratchet's list | Step 3 for the state and cues | The look gate for each visible change; UI's blind read (R20) | None |
| 9 | Levers, then the switch goes on in main's data | Game Design rules; the EP lands it | R15 to R18 inside their bands. Step 8's winded, low and fall-through signals landed (pad, sound and posture), and R20 read | The golden records are re-recorded once | **Changes it.** This window if in time, else the fourth milestone's |

After step 6 and the first signals of step 8 (winded, low and the fall-through, in the pad, the sound and the posture), one of Orb's builds can carry the loop on through the setup word, so Orb can fight with stamina empty and see what a hit does without waiting for main. Not before. With no bars, a build with the loop on and no signals gives the player nothing to read, and a silent fall-through is what the model page rules out ("so it's never silent"). The third milestone's own must-pass line also asks for a still set showing that health, energy and readiness can be read from the fighter at speed (`04-path-to-alpha.md:194`), so step 8 is not optional polish.

Step 5 was one step in the draft. It is four here because it was two owners, 33 lines across 15 files that three other reworks edit in the same window, and five different rules behind one check.

## 9. Readings

The scratch model is `esb-model.js (in the stand-in's scratch folder)` (node, no dependencies). It is arithmetic and a toy fight, not the sim. Pass lines marked "mine" are first values for Game Design.

| # | Reading | First pass line | Measured with |
| ---: | :--- | :--- | :--- |
| R1 | Golden hashes with the switch off, after every step | State, match and replay hashes identical at every step. `rosterHash` changes once, at step 1 | `sim/core/tools/parity.gd` against `sim/core/test/golden.json` (exist). Never run `sim/core/tools/golden.gd` as a check: it rewrites the file, so it always "passes". `qa/golden-hashes.json` is the JS core's own record and belongs only to the JS parity run |
| R2 | Energy literals left in `sim/core/` after step 1; the signature's 45 and the answer's 40 after step 2 | 0; each read as a price from data in one place. The fallbacks in 3.9's row 25 still write 40, 20 and 30 as literals unless Encounter drops them, so the lint leaves a `.get(key, fallback)` line out | A new lint (Tools) |
| R3 | A signature's stamina; a 20-energy special's; the dodge's | 30; 14; 10.5 | `vitals_check` (new) |
| R4 | Flat-out from a full stamina to winded, no resting | 1,000 ticks, give or take 1 | `vitals_check` |
| R5 | Resting, a second, at body share 1, 0.5, 0; with battered legs at 1 | 14.4; 10.8; 7.2; 12.24 | `vitals_check` |
| R6 | A winded 45-energy signature from exactly 45 energy | Fires; energy ends at 0; one `stamina_lack` cue; no refusal. The 60 energy still lacked is dropped (section 4, row 21) | `vitals_check` |
| R7 | Five heavies on a sound arm, rested and winded | Wear in the ratio 1 to 1.6, within one wear unit a hit | `vitals_check` |
| R8 | The body's share for each row of 3.4 | The table, exactly | `vitals_check` |
| R9 | The body over a whole match, a meteor landing and a form included | Never rises | `vitals_check`, and QA's batch |
| R10 | Damage taken to reach the brink, winded against rested, same hits | Reading only. The toy says 2.1 times less. Over 2 is a flag for the second lever (winded severity 1.4) | QA's tool, a scripted pair |
| R11 | A form with a battered arm, a broken (crippled) leg and the core at 85 | Arm eases 20; leg stays broken; core eases to 65; stamina at the new ceiling; the body unchanged. And with the core broken and `mendBroken` forced true in a fixture: the core's wear is held at the broken line and the fighter is still on the brink | `vitals_check` |
| R12 | A plain heavy landed, well timed, mashed, blocked, missed | +8, +12, +2.8, +4, 0 (before any 0.7 charge). The well-timed line is read in a planned exchange only: in a brawl no press is tagged well timed today (section 4, row 24) | `stamina_check` (new) |
| R13 | Beams, bolts, zips, flight strikes, the Driver, a top-stage stick strike | Refill 0 | `stamina_check` |
| R14 | Guarding a light, a medium, a heavy, a bolt, a beam | 1.5, 3, 6, 1.5, 6 | `stamina_check` |
| R15 | The fighter who falls behind first wins, loop off and on | 30 to 45% both (the model page) | QA's new tool. "Falls behind" is the first fighter whose `SimWounds.brinkProgress` reaches one third: with the loop on, the nearer of the core's road and the body's (6.4); with it off, core wear 30, as today. The core-only marker (core wear 30 in both arms) is saved beside it as a second column, not as the gate |
| R16 | The leader's stamina minus the trailer's, averaged over the whole match | At most 25 points (the model page) | The same. The trailer is the fighter who fell behind first by R15's marker. The average from the tick one falls behind is saved as a second column. A match where nobody falls behind is left out and counted |
| R17 | Time the trailing fighter spends winded | At most 15% of the match (the model page) | The same |
| R18 | First brinks that come by the empty body | 3 to 30% (mine: "the core stays the usual road", yet the body road is real). Also read: body left when the core breaks | The same |
| R19 | Match length, loop on against off; and the computer's winded share | Median within 15% (mine); reading only for the second | QA's batch |
| R20 | A reader who has not seen the match answers four things from clips (hurt or fine; energy or empty; a form ready or not; out of breath or fine) and one from stills (how much is left in them: most, half, almost none) | 8 of 10 on each of the five (mine) | UI's blind read, with QA. It serves the third milestone's own must-pass line, and it shows whether the body can be read at all |
| R21 | LAN: a forced difference in one fighter's stamina | Caught on the next check | `net/tools/desync_check.gd` (exists; a case to add) |
| R22 | Two fights at once, and five bodies, with the loop on | Their checks pass; no guard reaches a brink | `sim/core/tools/fights_check.gd`, `cross_check.gd` (exist) |
| R23 | The two counts | Two-fighter at most 365; fighter-specific 0 with the new file listed | `tools/ratchet-two-fighter.mjs` and Tools' fighter-specific count (exist) |
| R24 | Stamina a second from each press pattern in 3.3's table, landed and blocked, with the guarding fighter's cost beside it | Reading first. Flags (mine): a pattern that refills faster landed than resting at a full body (14.4); a pattern that still nets above zero into a guard once the first lever is in. By arithmetic the first values trip both: mediums at their fastest give 21.5 landed, and with a blocked blow at 0.25 they still net 2.75 a second | `stamina_check`, scripted presses at fixed gaps |
| R25 | A winded fighter with 60 energy, chased flat out by a rested rival: the seconds until their own choices have them back at 15 stamina | Reading only | QA's tool, a scripted pair |
| R26 | The hurt fighter's boost in force at the tick a fighter falls behind, and the seconds from that tick to their next form, loop off and on | Reading only. The toy says a boost of 1.14 to 1.22 at that tick | QA's new tool |
| R27 | One against three: the share of ticks each body spends resting | Reading only. R22 checks only that no guard reaches a brink | `fights_check`, or QA's batch (not verified in a run) |

**How many matches for R15.** At a true rate near 40%, 400 matches give a 95% range of about 4.8 points either way (1.96 × √(0.4 × 0.6 ÷ 400)). That is enough to say "inside 30 to 45" when the reading is 35 to 40, and not enough within 5 points of an edge. Comparing two arms of 400 with each other, the range on the difference is about 6.8 points either way. Run both slot orders, since a mirror match has shown a slot skew before. QA's batch size is already 400 an arm.

## 10. Size

My guess: **12 to 19 million tokens across eleven sessions**, and two to four weeks beside the beam and the well.

| Who | Guess | It depends on |
| :--- | ---: | :--- |
| Simulation, steps 1, 3, 4 and 5b | 3 to 4.5M | Whether the parity run and the goldens come back identical first time after the literals move |
| Encounter, steps 2, 5 and 6 | 3 to 5M | 33 spend lines across 15 director files that the beam and signature work are editing in the same window. The computer's habits are the unknown |
| QA, step 7 | 2 to 3M | One lever pass is one more pair of batches; three levers and a cap could be four passes |
| Controls, Animation, VFX, Rendering, Audio, UI, step 8 | 3 to 5M together | How many signals pass the look gate first time |
| Game Design, Tools, the EP's reviews | 1 to 1.5M | Section 4 has 26 rows to rule |

The audit sized the three rows this covers as one large, one medium and one small (this page's reading of the rows; the class of each was not re-checked). Its size classes are stated outright (`04-path-to-alpha.md:46`: small about 0.25M, medium about 1.2M, large about 4M), which prices the three at 4 + 1.2 + 0.25 = 5.45M. This guess is 2.2 to 3.5 times that, and at its top it is larger than the 12M the path carries for the gravity well (`:38`). It adds about 6.5 to 13.5M to the milestone's 53M, in a milestone the path already calls the most likely to overrun (`:216`). **Whether that is a scope or spend question for Orb is the EP's call, not this page's.** The difference is the signals, the computer's habits and the lever passes, which the audit's rows did not carry. The cheapest cut is the signals beyond winded, low and the fall-through, which could follow in the fourth milestone.

## 11. For Orb

Draft questions for the EP to ask, one at a time. Game Design rules first on each. A question goes to Orb only if it is still open after that, and each says so.

**1. Do you want to see a thin stamina line in the corner, to compare?**
Game Design has ruled that there is no stamina bar, and that UI may show Orb a thin corner line later for approval. Ask this only if the EP wants Orb's word before UI spends time on one.
- *Nothing new on screen.* You read stamina from the fighter's breathing and posture, and from a slow heartbeat in your pad. On a keyboard there is no heartbeat, so it is the fighter alone.
- *Let UI show me a thin line to compare.* UI builds a thin line beside the energy line, off to start, so you can turn it on in the same sitting and judge by playing.

I think Orb would want the first for now. Orb's answer on health bars was "go with recommended" (`vision.md:1740`), and what was recommended was no bars. The second costs UI's time and can be asked after Orb has played with the signals.

**2. Should flying flat out tire you everywhere, or only near the fight?**
Ask this only after Game Design has ruled on the numbers, and only if the feel is still open.
- *Everywhere.* Holding LT always costs stamina. With the first numbers a full stamina is about 17 seconds of it, which is a little over a third of a lap of today's planet and about a tenth of a lap of the largest size. Crossing a big planet to reach the fight, you arrive out of breath unless you ease off on the way.
- *Only near the other fighter.* Far away, flat-out flight is free; inside a set distance it costs. Chasing and fleeing in a fight still tire you. Travelling does not.
- *Everywhere, but slower to drain far away.* A middle road: travel costs something, never enough to arrive empty.

I think Orb would want the second: Orb asked for five planet sizes, and the larger ones should not punish the trip to the fight.

**3. When the deep health runs out, can a second wind still pull a fighter back once?**
Ask this only if Game Design does not rule it first.
- *No.* Once the deep health is empty the fighter is on their last legs for the rest of the match. Each time the other fighter wins a big moment against them, they face a finishing move, with the same chance to survive it as today. Matches where someone blocks everything still end.
- *Once.* The first time they survive a finishing move, a little of the deep health comes back and they are off their last legs, as happens today when the middle of the body breaks. After that, no more. This would be the one time any of the deep health comes back in a match.

I think Orb would want the first. The rule so far is that the deep health never comes back in a match, the first answer keeps that rule whole, and it is what this spec builds first. The second is there if Orb would rather both ways of reaching the edge allow one more comeback.

## 12. Risks, unknowns and what was not verified

**Risks**
1. **The runaway is real in the toy.** Being winded more than halves the damage it takes to reach the brink. The model page's three levers exist for this; the first batch may well need the second one.
2. **Four readings of the model page change the whole feel, and they pull on each other:** whether a fighter rests inside an exchange (row 4), whether plain blows pay the 0.7 rule (row 7), what the energy fall-through covers (row 20), and how refill is held down by the second (row 23). Rows 4, 7 and 23 must be ruled together, because each one's sums assume the other two. The build should not start step 5a before they are ruled.
3. **Three reworks share one window and one set of files.** The beam, the signature inputs and the well all edit the exchange code the 34 lines sit in. The lines are single additions on purpose, but every one of them can be lost in a merge. Step 5a's check counts them.
4. **The measurement measures the computer.** If the computer ignores stamina, the bands describe a game nobody plays. Step 6 comes before the loop-on batches for that reason.
5. **The body changes meaning under a switch.** Any tool that reads the old hit points as damage reads wrong with the loop on (section 7). The safe pattern is to read the damage event.
6. **A big planet and a flat-out cost pull against each other** (row 13).
7. **The baseline moves under the measurement.** The comeback for every fighter and the zeroed meters land first; a "loop off" batch taken before them is void.
8. **A steady beat out-refills resting.** By arithmetic on the brawl's own gaps, mediums pressed on a 12-tick beat give back 21.5 stamina a second landed and 9 a second into a guard, and one tick of spacing changes a light's refill 2.6 times (3.3). Nothing has measured it. If it holds in the sim, "plain blows are a respite" becomes "a metronome is the best move in the game".
9. **A winded fighter's ways out all cost energy at once** under the first value's reading of the fall-through (3.6). The runaway section's first pull-back is breaking away, and this reading makes breaking away the dearest thing a winded fighter can do.
10. **The well-timed bonus cannot be earned in the brawl today** (row 24). If the comeback batches run before that is ruled, they measure the loop with one of its rules dead in the close fight.
11. **The hurt fighter's boost arrives late** (3.5): about 1.14 to 1.22 at the moment a fighter falls behind, on one of four sources of power.
12. **The size is 2.2 to 3.5 times the audit's** for these rows (section 10), in the milestone the path already calls the most likely to overrun.
13. **A key written into a blow's options is hashed.** The plain blow's mark is gated on the loop's switch for that reason (6.1, 6.5). Any builder who adds a key to a blow's options by hand, ungated, changes the hash of every match with the loop off.

**Not verified**
- The earlier count of 321 lines, 55 files and 51 literals. My counts are in 3.9; none matches it.
- The readers' line table (199 rows) was spot-checked against the files, not re-derived line by line. The core's lines in sections 3 and 6 (`damage.gd`, `wounds.gd`, `fighter.gd` 540 to 790, `kick.gd`, `power.gd`, `hash.gd`, `replay.gd`, `roster.gd`, `state.gd`'s fighter, the loader) were opened. Of the director's lines I opened `exchange.gd` 268 to 353 and 806 to 871, `melee.gd` 275 to 362, `brawl.gd` 370 to 399, 786 to 821 and 1360 to 1409, and `ending.gd` 50 to 124; the other spend lines in 3.9 are from a search. The fixer then printed all 33 director spend lines, and each is the energy spend 3.9 says it is. The computer's literals (rows 20 to 24) and the pad's lines are the readers' and were not opened.
- How the comeback for every fighter will be stated in data in the first milestone; nothing is parked for it.
- How Tools' data job maps a schema file to a data file.
- Whether `data/combat/styles.json` holds unread copies of the chain and beam-score numbers, as the readers' map says. I opened the file's head only.
- Whether UI shows a card for a wound stage going down, and whether the cards show at all under the minimal HUD.
- Whether `power_check` would see a winded flight.
- What Orb's packed build holds for the slip's tick count and the flat-out base (the readers flagged both).
- The toy fight in section 3.7 is not the sim: no launches, beams, landings, second breath or late-match wear ramp. Its ratios are a reason to measure, not a result.
- The per-second refill table in 3.3 is arithmetic on the data's gaps. Whether the brawl treats a light 13 ticks after the last as a lone light, and how often a medium really lands every 12 ticks, were not read from the code and not run.
- Whether a blur string can run inside a brawl, which would let a light be tagged well timed there.
- Whether a brawl's second fighter is ever "the attacker" of the exchange as the core sees it. The winded blow's test was written so that it does not matter; the broken-arm rules beside it (`damage.gd:62-69`) do depend on it.
- That step 2 leaves the golden file unchanged. It was read from two lines of the recipe, not run.
- Which of the 26 spend lines that subtract their price whole can be reached with less energy than the price. Their gates were not each opened.
- The toy figures in 3.5 and in section 4, row 26 (0.72, 0.82, 83 in 100) come from the design reviewer's script, built on this page's toy fight. The fixer ran it again and got the same figures. It is still a toy.
- The audit's size class for each of the three rows.
- Nothing here was run in Godot. No pseudocode has been compiled.

## Appendix A. Every line in the sim that reads or writes energy, power or the model's level

This is the readers' table 3.9 counts from: 199 rows in 33 files, from a search of main at 752c381f. It was spot-checked against the files, not re-derived line by line (section 12). The kinds: PRICE is a spend; GATE is a test before a move; AI is a read by the computer; GAIN adds energy or power; DISPLAY is text or a cue that shows a number; MODEL is a read by the energy model or of the ladder; STATE, SETUP and COOLDOWN are as named; METER is a score that reads power; DRAIN is energy another fighter takes; CLAMP is a cap. The scratch table's column of quoted code is left out.

| # | File and line | Kind | What the line does |
| ---: | :--- | :--- | :--- |
| 1 | `sim/core/boons.gd:104` | SETUP | training start / boon: power set to the form step power (data) |
| 2 | `sim/core/boons.gd:109` | SETUP | training start: power set to ladder threshold (data) |
| 3 | `sim/core/brake.gd:163` | GATE | air brake: rate x noKiMul 0.5 when energy is 0 (brake.json) |
| 4 | `sim/core/brake.gd:168` | PRICE | air brake hold: kiPerSec 20 a second (brake.json) |
| 5 | `sim/core/damage.gd:84` | STATE | a hit on a charging fighter: stance multiplier 1.35 (takes more); no data key |
| 6 | `sim/core/damage.gd:89` | DRAIN | guarding: lose 0.08 x damage guarded; no data key |
| 7 | `sim/core/damage.gd:90` | GAIN | attacker gains 0.04 x damage dealt, cap 100; no data key |
| 8 | `sim/core/damage.gd:91` | GAIN | power: victim + takenPerDamage x damage (ladder.json), cap 100 |
| 9 | `sim/core/damage.gd:92` | GAIN | power: attacker + dealtPerDamage x damage (ladder.json), cap 100 |
| 10 | `sim/core/fighter.gd:555` | MODEL | tierByPower: power vs ladder thresholds (data) |
| 11 | `sim/core/fighter.gd:661` | GAIN | power fill fillPerSec a second (ladder.json), cap 100 |
| 12 | `sim/core/fighter.gd:685` | GAIN | free regen 5/s, +25/s hidden in cover; no data key |
| 13 | `sim/core/fighter.gd:695` | CLAMP | regen floor 1/s under the hero meter penalty; no data key |
| 14 | `sim/core/fighter.gd:707` | GAIN | regen x wounds.json penalties.coreKiRegen 0.7 when the core is battered (data) |
| 15 | `sim/core/fighter.gd:709` | GAIN | regen x forms gains.regen (forms on only; data) |
| 16 | `sim/core/fighter.gd:711` | GAIN | energy regen applied in free/locked/down, cap 100 |
| 17 | `sim/core/fighter.gd:762` | STATE | charging: velocity x0.85 a tick (the charge slows the fighter); no data key |
| 18 | `sim/core/fighter.gd:767` | GAIN | charging: energy +30 a second, cap 100; no data key |
| 19 | `sim/core/fighter.gd:768` | GAIN | charging: power + chargePerSec (ladder.json), cap 100 |
| 20 | `sim/core/forms.gd:149` | MODEL | forms: steps reached by power (forms.json steps) |
| 21 | `sim/core/forms.gd:450` | MODEL | forms level for branch extras (step count, not energy) |
| 22 | `sim/core/forms.gd:463` | MODEL | forms level read by blockWiden |
| 23 | `sim/core/hash.gd:6` | STATE | ki, power, tier are hashed fighter fields |
| 24 | `sim/core/hash.gd:191` | STATE | sigReadyT hashed |
| 25 | `sim/core/power.gd:182` | MODEL | level(f) definition |
| 26 | `sim/core/power.gd:183` | MODEL | level = tierShare x (tier-1)/3 + powerShare x power/100 |
| 27 | `sim/core/power.gd:187` | MODEL | energy = base x topOverBase^level |
| 28 | `sim/core/power.gd:248` | MODEL | flatSpeed re-derives the dash: 430 x spd x form x 2.4, a copy of fighter.gd:609/:623 literals |
| 29 | `sim/core/power.gd:249` | MODEL | flat-out far speed = powerFlat x growth^level x spd x close/plain |
| 30 | `sim/core/stage.gd:227` | STATE | sigReadyT is a time stamp shifted when fights swap (2v2) |
| 31 | `sim/core/state.gd:1077` | SETUP | start energy 60 (every fighter, every match); no data key |
| 32 | `sim/core/state.gd:1127` | STATE | sigReadyT field |
| 33 | `sim/core/wounds.gd:469` | GAIN | power + wounds.json cripple.surgePower 10 on a cripple, cap 100 |
| 34 | `sim/director/ai.gd:103` | AI | stance weights: escape weight lowKi 1.2 below lowKiBelow 25 (ai.json; code fallbacks repeat them) |
| 35 | `sim/director/ai.gd:111` | AI | stay hidden while energy < 85; no data key |
| 36 | `sim/director/ai.gd:177` | AI | defensive computer charges when energy < 55 and gap > 350; no data key |
| 37 | `sim/director/ai.gd:225` | AI | same rule, second branch: 55 and 350; no data key |
| 38 | `sim/director/ai.gd:274` | AI | computer fires signature at energy >= 50 (price is 45) and off cooldown; no data key |
| 39 | `sim/director/ai.gd:294` | AI | computer lays a mine at energy >= mineMinKi 40 (ai.json; fallback repeats it) |
| 40 | `sim/director/ai.gd:409` | AI | _fired: sigReadyT > 0 means it has fired a signature |
| 41 | `sim/director/ai.gd:417` | AI | sig pacing gap vs human: reads sigReadyT minus the cooldown |
| 42 | `sim/director/ai.gd:419` | AI | sig pick x kiHigh/kiLow by the human energy vs kiAt 45 (ai.json vsHuman) |
| 43 | `sim/director/ai.gd:425` | AI | sigDue: computer needs energy >= 45 (the price, literal) |
| 44 | `sim/director/ai.gd:427` | AI | sigDue: human energy >= kiAt (ai.json) |
| 45 | `sim/director/arc.gd:175` | MODEL | meteor gate reads forms level (SimForms.level), not energy |
| 46 | `sim/director/bands.gd:539` | GATE | calling off a committed heavy charge needs dodgeCancel.ki 15 (interrupts.json) |
| 47 | `sim/director/bands.gd:541` | PRICE | calling off a committed heavy charge: pays dodgeCancel.ki 15 |
| 48 | `sim/director/bands.gd:543` | DISPLAY | event-feed text with the price |
| 49 | `sim/director/beam.gd:41` | AI | computer beam answer: signature at >= 45 and off cooldown, or last stand; literal 45 |
| 50 | `sim/director/beam.gd:42` | AI | computer beam answer: heavy blast at >= 40; literal 40 |
| 51 | `sim/director/beam.gd:101` | PRICE | beam CLASH for an unanswered defender: pays 40 (old automatic clash); literal |
| 52 | `sim/director/beam.gd:129` | GATE | queued signature answer needs 45 and off cooldown; literal |
| 53 | `sim/director/beam.gd:134` | PRICE | signature answer: pays 45; literal |
| 54 | `sim/director/beam.gd:135` | COOLDOWN | signature answer starts the signature wait |
| 55 | `sim/director/beam.gd:138` | GATE | queued heavy-blast answer needs 40; literal |
| 56 | `sim/director/beam.gd:140` | PRICE | heavy-blast answer: pays 40; literal |
| 57 | `sim/director/beam.gd:208` | METER | beam clash score: tier x10 + energy x0.35 + draw 0..16 + menace + flow; literals |
| 58 | `sim/director/beam.gd:245` | METER | beam power (no draw): tier x10 + energy x0.35 + menace + flow; literals |
| 59 | `sim/director/beam_move.gd:66` | MODEL | a second level(f) definition |
| 60 | `sim/director/beam_move.gd:67` | MODEL | level copy with literals 0.8 / 0.2 / 3 / 100 (duplicates power.json level) |
| 61 | `sim/director/beam_move.gd:72` | MODEL | stage count 2 + round(4 x level), 2..6; literals |
| 62 | `sim/director/beam_move.gd:115` | GATE | held at the top stage while it can pay the top price |
| 63 | `sim/director/beam_move.gd:116` | PRICE | top stage held: topDrainPerSec (ownMove 4 / strikeStages 2) a second |
| 64 | `sim/director/beam_move.gd:118` | GATE | stage capped by what it can pay (price per stage, data) |
| 65 | `sim/director/beam_move.gd:227` | PRICE | strike stage prices = stick.json levels[s].ki - levels[0].ki |
| 66 | `sim/director/beam_move.gd:242` | DISPLAY | refusal cue "ki" at release |
| 67 | `sim/director/beam_move.gd:273` | GATE | beam stage fire needs price[st-1] (ownMove.price) |
| 68 | `sim/director/beam_move.gd:274` | DISPLAY | refusal cue "ki" |
| 69 | `sim/director/beam_move.gd:289` | PRICE | beam stage fire pays price[st-1] (12..50) |
| 70 | `sim/director/beam_move.gd:291` | COOLDOWN | sets sigReadyT for the computer pacing only |
| 71 | `sim/director/beamplay.gd:100` | GATE | answer refused for energy < 45 (cue "ki"); literal |
| 72 | `sim/director/beamplay.gd:101` | DISPLAY | refusal cue "ki" |
| 73 | `sim/director/beamplay.gd:102` | GATE | answer refused while the signature wait runs |
| 74 | `sim/director/beamplay.gd:112` | GATE | stick fire-back needs answerCost (answerKi 40 or ownMove price[0] 12) |
| 75 | `sim/director/beamplay.gd:113` | DISPLAY | refusal cue "ki" |
| 76 | `sim/director/beamplay.gd:211` | GATE | fire-back needs answerCost |
| 77 | `sim/director/beamplay.gd:213` | PRICE | fire-back pays answerCost (data) |
| 78 | `sim/director/beamplay.gd:591` | AI | computer beam plan: can signature at 45; literal |
| 79 | `sim/director/beamplay.gd:594` | AI | computer late answer at heavy-blast 40; literal |
| 80 | `sim/director/blast.gd:159` | GATE | energy shot needs blast.light.ki 1 / heavy.ki 8 (interrupts.json) |
| 81 | `sim/director/blast.gd:161` | DISPLAY | banner NEED n KI |
| 82 | `sim/director/blast.gd:185` | PRICE | energy shot pays w.ki (one branch) |
| 83 | `sim/director/blast.gd:192` | PRICE | energy shot pays w.ki |
| 84 | `sim/director/blast.gd:240` | GATE | context deflect needs blast.deflect.context.ki 10 |
| 85 | `sim/director/blast.gd:254` | PRICE | context deflect pays 10 (data) |
| 86 | `sim/director/blast.gd:270` | GATE | mine needs blast.mine.ki 8 |
| 87 | `sim/director/blast.gd:272` | DISPLAY | banner NEED n KI |
| 88 | `sim/director/blast.gd:279` | PRICE | mine pays 8 (data) |
| 89 | `sim/director/blast.gd:410` | GAIN | perfect block of a shot: + perfectBlock.ki 8, cap 100 |
| 90 | `sim/director/brawl.gd:713` | GATE | brawl takes a signature press only at >= 45 and off cooldown (or last stand); literal 45 |
| 91 | `sim/director/brawl.gd:794` | PRICE | energy reach (bolt 1 / blast 8, interrupts.json brawl.energy.reach) |
| 92 | `sim/director/brawl.gd:795` | GATE | energy reach falls back to the fist without the energy |
| 93 | `sim/director/brawl.gd:798` | PRICE | energy reach pays ep |
| 94 | `sim/director/brawl.gd:802` | GATE | launcher lit only at >= brawl.launcher.ki 5 |
| 95 | `sim/director/brawl.gd:807` | PRICE | brawl blow price: launcher 5 / heavy 5 / medium 1 |
| 96 | `sim/director/brawl.gd:808` | GATE | heavy short of price drops to medium |
| 97 | `sim/director/brawl.gd:811` | PRICE | dropped to medium price 1 |
| 98 | `sim/director/brawl.gd:812` | GATE | short of medium: a light |
| 99 | `sim/director/brawl.gd:815` | PRICE | pays the blow price |
| 100 | `sim/director/brawl.gd:2299` | AI | computer launches in a string only at >= launcher.ki |
| 101 | `sim/director/brawl.gd:2408` | DISPLAY | launcherNow: is the launcher lit (read by the cue and HUD) |
| 102 | `sim/director/brawl.gd:2436` | DISPLAY | link cue only when the launcher is affordable |
| 103 | `sim/director/brawl.gd:3278` | GATE | banked held heavy needs charge.ki - launcher.ki (8-5=3) |
| 104 | `sim/director/brawl.gd:3300` | PRICE | heavy charge over the tap: charge.ki - heavy.ki (8-5=3) |
| 105 | `sim/director/brawl.gd:3301` | GATE | can pay the charge extra |
| 106 | `sim/director/brawl.gd:3302` | PRICE | pays the charge extra |
| 107 | `sim/director/brawl.gd:3314` | PRICE | banked hold pays charge.ki - launcher.ki |
| 108 | `sim/director/brawl.gd:3731` | AI | computer picks medium at >= medium.ki |
| 109 | `sim/director/brawl.gd:3736` | AI | computer picks heavy at >= heavy.ki |
| 110 | `sim/director/brawl.gd:3738` | AI | computer mix medium at >= medium.ki |
| 111 | `sim/director/brawl.gd:3741` | AI | computer energy reach at >= its price |
| 112 | `sim/director/brawl.gd:3763` | AI | computer charge at >= charge.ki |
| 113 | `sim/director/brawl.gd:4018` | AI | computer launcher at >= launcher.ki |
| 114 | `sim/director/brawl.gd:4031` | AI | computer medium when affordable and in time |
| 115 | `sim/director/brawl.gd:4093` | AI | computer medium into a heavy |
| 116 | `sim/director/brawl.gd:4119` | AI | computer signature at >= 50 off cooldown; literal 50 |
| 117 | `sim/director/brawl.gd:4125` | AI | computer guard break heavy at >= heavy.ki |
| 118 | `sim/director/brawl.gd:4129` | AI | computer heavy into a flurry at >= heavy.ki |
| 119 | `sim/director/chase.gd:74` | PRICE | chase blow price = zip.strike.ki 20 / zip.heavy.ki 30 (fallbacks repeat them) |
| 120 | `sim/director/chase.gd:97` | GATE | chase needs the price |
| 121 | `sim/director/chase.gd:132` | GATE | queued chase needs the price |
| 122 | `sim/director/chase.gd:155` | AI | computer chases when it can pay |
| 123 | `sim/director/chase.gd:162` | AI | computer waits for energy in its own rally |
| 124 | `sim/director/chase.gd:165` | AI | computer no chase without energy |
| 125 | `sim/director/chase.gd:173` | PRICE | tap chase pays cost (chase_tap price) |
| 126 | `sim/director/chase.gd:188` | PRICE | chase pays the zip price |
| 127 | `sim/director/chase_tap.gd:154` | GATE | chain chase tap needs its price (rate x priceStep^(k-1); first is free) |
| 128 | `sim/director/chase_tap.gd:185` | GATE | upgrade of a paid tap needs the difference |
| 129 | `sim/director/chase_tap.gd:188` | PRICE | pays the difference (refunds what it paid) |
| 130 | `sim/director/driver.gd:64` | GATE | Driver (held B) needs blast.driver.ki[0] 10 |
| 131 | `sim/director/driver.gd:65` | DISPLAY | refusal cue |
| 132 | `sim/director/driver.gd:98` | GATE | next Driver level only when ki[lv+1] is affordable |
| 133 | `sim/director/driver.gd:106` | PRICE | Driver loaded: loadedKiPerSec 4 a second |
| 134 | `sim/director/driver.gd:107` | GATE | loaded Driver drops a level when it cannot pay |
| 135 | `sim/director/driver.gd:119` | PRICE | Driver fire pays ki[lv] (10/14/18/24) |
| 136 | `sim/director/exchange.gd:281` | GATE | signature request dropped below 45 (banner NEED 45 KI); literal |
| 137 | `sim/director/exchange.gd:285` | DISPLAY | stick beam refusal cue "ki" |
| 138 | `sim/director/exchange.gd:288` | GATE | signature dropped while sigReadyT is ahead |
| 139 | `sim/director/exchange.gd:294` | GATE | heavy below 4 becomes a light; literal |
| 140 | `sim/director/exchange.gd:297` | PRICE | blind swing at a hidden target: 2 (lock-lost); literal |
| 141 | `sim/director/exchange.gd:343` | PRICE | heavy exchange: pays 4; literal |
| 142 | `sim/director/exchange.gd:348` | PRICE | signature: pays 45; literal |
| 143 | `sim/director/exchange.gd:349` | COOLDOWN | signature wait starts (DirBeam.sigCooldown) |
| 144 | `sim/director/exchange.gd:595` | PRICE | chain link: pays 6; literal |
| 145 | `sim/director/exchange.gd:786` | GATE | chain window: combo < 5 and energy >= 6; literals |
| 146 | `sim/director/grapple.gd:516` | AI | computer throw weights x0.5 below launcher.ki |
| 147 | `sim/director/interrupt.gd:306` | GAIN | perfect block (one variant): + c.ki, cap 100 |
| 148 | `sim/director/interrupt.gd:318` | GAIN | perfect block: + perfectBlock.ki 8, cap 100 |
| 149 | `sim/director/interrupt.gd:337` | GAIN | deflect: + perfectBlock.ki 8, cap 100 |
| 150 | `sim/director/interrupt.gd:449` | GATE | dodge cancel needs dodgeCancel.ki 15 (free before windup) |
| 151 | `sim/director/interrupt.gd:456` | PRICE | dodge cancel pays 15 |
| 152 | `sim/director/interrupt.gd:494` | GATE | burst needs burst.ki 30 |
| 153 | `sim/director/interrupt.gd:507` | PRICE | burst pays 30 |
| 154 | `sim/director/interrupt.gd:560` | AI | computer patient reversal only at energy > 25; literal |
| 155 | `sim/director/interrupt.gd:567` | PRICE | reversal price: kiPatient 10 after patientTicks, else 20 |
| 156 | `sim/director/interrupt.gd:574` | GATE | reversal needs its price |
| 157 | `sim/director/interrupt.gd:583` | PRICE | reversal pays |
| 158 | `sim/director/melee.gd:91` | PRICE | pursuit "slips away": attacker pays 3; literal |
| 159 | `sim/director/melee.gd:249` | DRAIN | guard break: defender loses 25; literal |
| 160 | `sim/director/melee.gd:301` | GAIN | parry, parity profile: + 8; literal (templates.json profiles hold 8/12 for the others) |
| 161 | `sim/director/melee.gd:308` | GAIN | parry, spaced/dynamic profile: + reward.ki 8 / cleanReward.ki 12 (templates.json) |
| 162 | `sim/director/rally.gd:283` | AI | computer sells only at >= medium.ki |
| 163 | `sim/director/rally.gd:847` | STATE | rally ends with reason "ki" when short of the next chase |
| 164 | `sim/director/stance.gd:81` | PRICE | circle stance move: price over the medium blow |
| 165 | `sim/director/stance.gd:83` | PRICE | circle pays the extra |
| 166 | `sim/director/stance_cost.gd:35` | PRICE | circle.ki 10 x repeatMul 1.5^n (interrupts.json stances.circle) |
| 167 | `sim/director/stick.gd:152` | PRICE | stick strike: level ki over the medium blow |
| 168 | `sim/director/stick.gd:154` | PRICE | stick strike pays the extra |
| 169 | `sim/director/stick.gd:459` | DISPLAY | refusal cue "ki" |
| 170 | `sim/director/stick.gd:492` | GATE | stick strike needs medium.ki |
| 171 | `sim/director/stick.gd:494` | DISPLAY | refusal cue "ki" |
| 172 | `sim/director/stick.gd:724` | GATE | charged stick level capped by levels[l].ki - levels[0].ki |
| 173 | `sim/director/stick.gd:733` | PRICE | charged stick release pays the level difference |
| 174 | `sim/director/zip.gd:197` | PRICE | wound blow during a zip: heavy 5 / medium 1 |
| 175 | `sim/director/zip.gd:198` | GATE | wound blow needs it |
| 176 | `sim/director/zip.gd:201` | PRICE | pays it |
| 177 | `sim/director/zip.gd:225` | GATE | zip strike/heavy needs zip.strike.ki 20 / heavy.ki 30 |
| 178 | `sim/director/zip.gd:271` | GATE | flight strike needs price minus refund |
| 179 | `sim/director/zip.gd:272` | DISPLAY | refusal "ki" |
| 180 | `sim/director/zip.gd:305` | GATE | flight strike from a brawl needs price |
| 181 | `sim/director/zip.gd:306` | DISPLAY | refusal "ki" |
| 182 | `sim/director/zip.gd:358` | PRICE | flight strike price: blows x10/y15/b20 + up to 10 by distance, x1.5 per chain link |
| 183 | `sim/director/zip.gd:367` | GAIN | take-back refund: dodgeCancel.ki inside the take-back window |
| 184 | `sim/director/zip.gd:378` | GAIN | refund applied, cap 100 |
| 185 | `sim/director/zip.gd:427` | GATE | chain link needs price |
| 186 | `sim/director/zip.gd:428` | DISPLAY | refusal "ki" |
| 187 | `sim/director/zip.gd:455` | PRICE | flight strike pays price |
| 188 | `sim/director/zip.gd:726` | PRICE | zip pays k.ki |
| 189 | `sim/director/zip.gd:769` | DISPLAY | event-feed text |
| 190 | `sim/director/zip.gd:1421` | AI | computer zips at >= strike.ki + 10; literal reserve 10 |
| 191 | `sim/director/zip.gd:1429` | AI | computer zip heavy at >= heavy.ki + 10; literal reserve 10 |
| 192 | `sim/director/zip.gd:1484` | AI | computer flight strike keeps ai.kiReserve 20 |
| 193 | `sim/director/zip.gd:1486` | AI | same |
| 194 | `sim/director/zip.gd:1582` | AI | computer counter to a zip: heavy at >= heavy.ki |
| 195 | `sim/director/zip.gd:1590` | AI | computer counter: medium at >= medium.ki |
| 196 | `sim/world/brunt.gd:605` | MODEL | model on: building damage factor read along the tier table by level x 3 |
| 197 | `sim/world/brunt.gd:612` | MODEL | model on: lodge seconds by level x 3 |
| 198 | `sim/world/collateral.gd:408` | GAIN | power + destroyed mass x md.worldPower (meters.json destroyed_power), cap 100 |
| 199 | `sim/world/crater.gd:82` | METER | beam crater power P = 0.5 + power/25 (consts :66-67); no data key |

## Checks

Two independent reviewers attacked the draft, one reading it against the code and one as Orb would. Each of the two blockers then went to a checker whose job was to refute it, and the fixer checked every other finding against the files or by arithmetic before using it.

| Finding (plain words) | Verdict | What changed |
| :--- | :--- | :--- |
| Marking a plain blow wrote a key into the blow's options with no switch on it. Those options are hashed, so every match would have hashed differently with the loop off. Blocker; the checker confirmed it, with one correction: the draft did not say the key was written with the loop off, it just never gated it | Fixed | 3.3 and 6.5: one helper, `DirMelee.mark`, on the pattern hit-stop's weight already uses, writes nothing while the loop is off. 6.1 has a row for the hazard, step 5c checks it, and it is risk 13 |
| The measurement that decides whether the switch goes on used its own meaning of "falls behind" (core wear 30) and its own average, not the ones Game Design ruled, and did not say so. Blocker, raised by both reviewers; the checker confirmed it | Fixed | R15 uses the nearer road at one third, R16 the whole match. The draft's two markers are saved as second columns. Section 4, row 26 |
| Step 1 could not leave the golden file identical: the roster's hash is stored in it | Fixed | 6.1, section 7, step 1 and R1: the file is regenerated in the same commit, and only that one value may differ |
| R1 named a tool that rewrites the golden file, and a record that belongs to the JS core | Fixed | R1 names the parity gate, and says never to run the regenerator as a check |
| The computer's stamina numbers sat in a file that is hashed whole, so tuning them would void saved matches with the loop off | Fixed | The numbers moved to the loop's part of `vitals.json` (`computer`). 5.3 and 6.1 say that the two director files move the hash on any edit |
| Having the beam's stage count call the energy model's level would let main's beams change with a file main does not hash | Fixed | 3.9 row 26 and 5.2: the two shares become keys in a file that is always hashed |
| The loader's pseudocode had no path for a missing file, and the parity gate already loads fixtures without one | Fixed | 6.2: a null test, and step 1 gains the gate's fixtures |
| The 0.7 rule charged stamina for energy a move never took (a brake with no energy, a spend that stops at 0) | Fixed | 3.2, 6.3, 6.4 and 6.5: the rule reads the energy actually taken at the eight lines that can stop at 0 |
| The winded blow's test also weakened shots fired inside an exchange, against the page's own row | Fixed | 6.4 and section 4, row 17. The suggested extra test on who started the exchange was **not used**: it could have left a brawl's second fighter at full strength. Ripostes are now said to count |
| Refill was only checked by the blow. By the second, a steady beat of mediums refills faster than resting, and one tick of spacing changes a light's refill 2.6 times | Kept as a risk, with a proposal | 3.3 has the table; section 4, row 23; reading R24; risks 2 and 8. The suggested pass line was **not used** as a pass line, because by arithmetic the first values fail it even with the first lever; it is a flag |
| The energy fall-through was applied to flight, the brake, the slip and the guard without saying so, which makes every way out dearer for a winded fighter | Fixed as a named reading; kept as a risk | 3.6 prints the costs. A data key says which spends fall through. Section 4, rows 20 and 21; reading R25; risk 9 |
| A press is never tagged well timed inside a brawl, so the × 1.5 could not be earned in the close fight | Kept as a risk, for Game Design and Controls | 3.3, 6.5, R12, section 4, row 24, risk 10, and a note in section 1 |
| The switch could go on, and Orb could be handed a build, before any signal existed; and step 5 was too large for one check | Fixed | Step 9 and the note after the table need step 8's first signals. Step 5 is now 5a to 5d |
| The first question to Orb reopened something Game Design had ruled with "no question to Orb", and the second had no order of who rules first | Fixed | Section 11: each question says when to ask. Question 1 has two choices and now recommends nothing new on screen. Section 4, rows 13 and 28. Dropping question 1 outright was **not used**: the EP may still want it |
| The body had no signal in the aura, the ground or the pad, and the aura carried four meanings | Fixed | 3.11: one meaning to a channel, a stance and ground placeholder for the body, two kinds of mark told apart, and R20 widened to five answers |
| "Up to 1.8 times as fast" overstated the hurt fighter's help: it is one of four sources and reaches 1.8 only on the brink | Fixed, with a proposal | Section 1 reworded; 3.5; section 4, row 25; reading R26; risk 11 |
| The size was understated against the audit, and nobody was told what it does to the milestone | Fixed | Section 10: 2.2 to 3.5 times, 6.5 to 13.5M more, and the EP's call. The reviewer's "its largest fight row" was **not used**: the path carries two larger rows |
| Minors, all used: counts and line numbers (10 clamps of energy, not 16; `beam.gd:41` holds 45; the snapshot's list is at `:152`; R2's wording); the "plain" kind held moves that refill nothing; the cap is by payment, where the ruling says by move; question 3 recommended what the spec did not build; `form.neverOffBrink` was in the data and read by nothing; section 1 left out the guard's cost and the no-rest reading; the by-file table lived only in a scratch folder; three small added rules had no row | Fixed | 3.9 rows 2 and 15 and the kinds table; section 4, rows 22 and 27; question 3; 3.5 and 6.3; section 1; Appendix A |
