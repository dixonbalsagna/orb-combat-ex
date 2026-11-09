# LT high-speed flight: is the pad slow to start it up close? (Controls' check, 2026-11-08)

The EP's overnight brief, item 2: Orb says the LT high-speed flight is too slow up close and only speeds up far apart. Encounter measures the zip; this is the pad side. Records: `docs/controls/runs/c974e451/lt-speed-probe.txt` and `lt_speed_probe.gd.txt` (CD-22). No patch: nothing on the pad side is slow.

## What the pad does (read from `sim/input/layout.gd` and measured)

| Step | Value | Slows a close start? |
|---|---|---|
| LT trigger reads as down | 0.35 pulled (up 0.25), `stick.triggerOn/Off` | No: reached in the first few ticks of a pull |
| The dash | `i.dash` is true on LT's press tick: the dodge edge is a lunge for `dodge.lungeTicks` (12), then LT held for `tapHold.holdStart` (12) is the sprint; the two meet with no gap | No: no ticks are lost before the dash |
| The left stick | dead zone 0.2, full at 0.9 (`stick.fullAt`), linear between, in 1/16 steps; so full speed needs 90% deflection | A little: a stick pushed to 0.6 flies at 0.57 of full. Linear, the same at every distance |
| Stances | a stance pressed after LT replaces it: LB (the vanish) kills the dash; RB does not | Only LB, by design |

Measured on the real hub into the sim, the energy model on, a standing rival (`lt_speed_probe.gd`; units a second, flier's speed at ticks 3, 6, 12, 24, 48 after LT and the stick go down):

| Separation | Pad, LT + stick full | Hand-made intent (dash on, stick 1.0) |
|---:|---|---|
| 600 | 386 657 980 1019 1252 | 309 526 784 972 1190 |
| 1500 | 386 657 980 1019 1031 | 309 526 784 972 1028 |
| 3000 | 598 1013 1485 1466 1278 | 479 811 1193 1412 1299 |
| 6000 | 1023 1732 2539 2505 2184 | 818 1387 2040 2414 2220 |
| 12000 | 1872 3169 4647 4585 3997 | 1498 2538 3733 4418 4063 |

- The pad is never slower than a hand-made full-speed intent (it is a little faster over the first ticks: the lunge). So nothing on the pad delays the start.
- Stick 1.0 and 0.9 are identical; 0.6 gives 0.57 of the speed (linear).
- Pressing LT with the stick already over gives the same curve; LT then RB gives the same; RB held then LT gives the same.

## So where is the distance dependence?

In `sim/core/fighter.gd` `flightSpeed`: the dash is 2.4 times the tier's step, and `ramp = (sep - BOOST_NEAR) / (BOOST_FAR - BOOST_NEAR)` (`sim/core/constants.gd`: 1,500 and 12,000) scales it up to `TRAV_FREE` 10 times (with the energy model on, `SimPower.flatSpeed` takes the far end by his level). Under 1,500 units the ramp is 0: the dash is the melee dash, about 1,000 units a second (13 body heights), at any distance inside it. At 3,000 it is about 1,450, at 6,000 about 2,500, at 12,000 about 4,600. That is Orb's "only speeds up far apart". It is Simulation's and Game Design's number, not the pad's.

## Proposal (for the EP to route; Controls changes nothing)

1. **The lever is the ramp's near end, in `sim/core` (Simulation) with Game Design's say.** Two small options that leave the far end alone: (a) lower `BOOST_NEAR` from 1,500 to about 300, so the boost starts at the edge of melee and a flight from 1,500 apart already flies at about 1.9 times; (b) give the dash a floor on the ramp (for example `max(ramp, 0.15)`), so close in it is about 2.35 times the melee dash. Either is one number and moves the golden hash; neither touches input.
2. **Pad side, only if Orb wants it:** a deeper pull of LT could add speed (an analog read, which the pad has and the keyboard does not). It would be a new input and a new rule, so I would not build it without Game Design.
3. Encounter's zip (`zip.speed`, the flight strike's lunge) is separate from this walk-flight speed; Orb's note does not say which he meant. Worth asking him or checking which one he was holding.

Not measured: the energy model's own close-range term at the tiers above 1 (the probe is tier 1), and a real thumb's deflection (a worn stick that never reaches 0.9 would fly slower; `fullAt` could drop to 0.8 as a pad-side nudge, at the cost of a touchier stick).
