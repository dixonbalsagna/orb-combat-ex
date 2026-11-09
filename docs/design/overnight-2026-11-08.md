# Overnight rulings, 2026-11-08: the launch's side, B and beams, and LT's speed

Owner: Game Design. On the EP's overnight brief, from Orb's Sunday plays and Orb's order of 21:52 (`docs/ep/vision.md`). These are for Encounter and Controls tonight. First values, as data.

## (a) Only the stick picks a launch's side

**Ruling: a launch goes the way of the blow. The director never flips it.** Only the stick can choose the other side.

- **What happened:** Orb's first meteor went the opposite way to the punch. `arc.gd`'s `heavyFull` (lines 195 to 200) flips the side when the stick picks none and `landingScore` prefers the other landing: at tick 2043, −8.0 the punch's way against +11.0 the other (QA, `docs/qa/runs/1931a0f8/play-20261108-1726.md`).
- **The rule, for every launch** (the arc, the ordinary planner, enders, the stick's full hold):
  - **The side is the blow's:** from the striker through the one struck, by his facing at contact.
  - **The stick picks the other side only when it says so:** "away" in `slam-and-pace.md`'s families, across behind you.
  - **The director may bend the angle within the side,** up to 20° toward a dramatic target (the physics packet's limit). **It may never flip the side** to get a better landing.
  - The launch planner doesn't offer candidates on the far side unless the stick chose it.
- **Why:** physics, and Orb's ask. You hit him, and he flies the way you hit him. A better landing the other way isn't worth a launch that reads as broken.
- **Data and owner:** Encounter takes the flip out of `heavyFull` and adds a guard on the planner's candidates. If a switch is wanted, `launch.json` `sideFromBlowOnly: true`. QA's row: launches whose side differs from the blow's with the stick at rest, **0**.

## (b) B never fires a beam

**Ruling: no press of B fires a beam or a signature, alone or with any shoulder, in any stance or layout.** This restates Orb's rule of 2026-11-01: beams are the right stick only.

- **What happened:** Orb's Sunday play had "firing beams without intending to". Two of Orb's four beams came from B: once alone, and once with the dodge held (QA).
- **B is the one rule for B:** a tap staggers, a hold sends (`press-decides.md`). Beams are RB + the right stick, and the signature is RT + the right stick (`signatureRtOnly`).
- **The computer** fires its beams through its own path, and with `beamMoveAi` on, through the player's path too. A player's B never.
- **Owners:**
  - **Controls:** the layout, so that no B combination maps to a beam or signature intent.
  - **Encounter:** the director refuses a beam request that came from B, with no other source.
  - **QA's row:** beams from a player's B press, **0**, on Orb's file replayed and on the scripted arms.

**The interim, accepted (2026-11-08, the EP's sequence).** Controls found that the RT + right stick signature isn't built, so closing B entirely would leave the signature out of reach. Until it lands:

| | Rule |
| :--- | :--- |
| **B alone, and LT + B** | **Never a beam or a signature,** from tonight. These were Orb's accidental cases |
| **RT + B** | **Keeps the signature, as a chord only:** B within 12 ticks of RT's press (`tapHold.holdStart`), before RT's hold becomes the channel. **A B pressed while RT is held to channel never fires it,** so a B mashed while powering up can't set off a signature |
| **When RT + right stick lands** | **RT + B goes in the same build.** No overlap, and no later |

- **Orb is told,** because this goes against Orb's 2026-11-01 "RT + B is out". It's one line on the play page: "Signature: RT + B, this build only."
- **QA's rows:**
  - signatures from B alone or LT + B: 0;
  - signatures from a B pressed during an RT channel: 0.

## (c) "LT high speed is fast at any range": the target

**What Orb felt** (21:52): "the LT high-speed didn't quite feel fast enough but sped up when we were further apart". **That's what the code does.**
- The dash (`fighter.gd` `flightSpeed`) is the melee dash, about 1,030 a second at base, out to 1,500 units apart.
- Beyond that it ramps with the gap, to full only at 12,000 apart. The old boost goes up to ×10, and with the energy model the flat-out 5,000.
- On top of that, the velocity reaches its target at about 11% a tick.
- So up close it's slow and slow to start, and it gets quicker the further away he is, slowing again as you close.

**The ruling: LT's high speed doesn't depend on the distance.** It's fast from the first tick and eases only at the arrival.

| | Target (base, plain stance, energy model on) |
| :--- | :--- |
| **Top speed** | **The flat-out speed of his level, at any range:** 5,000 a second at base, up to 11,525 at maximum (`power-scale.md`; Orb's slider 3,500 to 7,000 still sets the base). **No ramp by distance** (`BOOST_NEAR` and `BOOST_FAR` go for the dash) |
| **First tick** | **He's visibly moving on the tick after LT's press:** at least 1,000 a second, along the stick |
| **Full speed** | **By tick 12 after LT's press,** where today the sprint only starts at tick 12. LT still held, with the stick toward him |
| **The arrival** | It eases into striking distance over the last 1.5 bh. No overshoot and never a teleport (RL-076: at least 4 ticks, at most 3 bh a tick; 5,000 a second is 1.1 bh a tick) |
| **Close from 1,000 units** | **At most 0.4 s** (24 ticks), from LT's press to striking distance. Today, by the code, about 1.1 s |
| **Close from 3,000** | **At most 0.8 s** (48 ticks). Today about 2.5 s |
| **Close from 6,000** | **At most 1.4 s** (84 ticks). Today about 2 to 3 s. **At maximum, at most 0.75 s** |

- **A tapped LT is still the slip.** These targets are for LT held. A slip let go by tick 6 travels at most 1.5 bh, so a slip never turns into a leap.
- **The take-back (4 ticks) and the flight strikes are untouched.** A face press in the window still converts.
- **Camera:** 5,000 a second is inside what Camera follows softly. At the top level the rush's own pin carries it.
- **Owners:**
  - **Controls:** the lunge-to-sprint handover, so that tick 1 moves him and full speed comes by tick 12.
  - **Simulation:** the dash's speed with no distance ramp, and its response (a faster rise for the held dash than free flight's 11% a tick).
  - **Encounter:** the arrival's ease into the brawl.
  - **QA's rows:** speed on the first tick, and the close times from 1,000, 3,000 and 6,000 at base and at maximum, with the computer standing still.
- **Data** (`data/fight/power.json`):
  ```json
  "dash": { "anyRange": true, "firstTickMin": 1000, "fullByTicks": 12, "arriveEaseBh": 1.5,
    "closeSec": { "1000": 0.4, "3000": 0.8, "6000": 1.4 }, "slipMaxBh": 1.5 }
  ```
