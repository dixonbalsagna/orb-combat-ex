# LT + B stays B for the flight strike (Controls, 2026-11-07; from Encounter's flight strikes)

With the right stick on and the RT-only signature rule (`switches.signatureRtOnly`), the layout sends B with LB, RB or LT held as Y's heavy (`layout.gd`, so a guard or a dodge never fires a beam by accident). LT + B therefore reached the director as LT + Y, and the flight strike's B (tell 14, a tapped B's worth, a stagger, never a send) could not be pressed on a pad. Encounter's QA arm saw 97 X, 14 Y and no B.

## The fix: `switches.flightStrikeB` (timing.json, off)
With it on (and `signatureRtOnly`), **LT + B is left as the B press** (`sig`, `sigHeld`): the director reads it as the flight strike's big blow (`kind == "sig"` with LT in the stance mask).

| Held with B | Rule on, flightStrikeB off | Rule on, flightStrikeB on |
| :--- | :--- | :--- |
| nothing, RT | B (signature) | B |
| LB, RB | Y's heavy | Y's heavy (RB + B stays B if `driverOnRb` is on, as before) |
| **LT** | **Y's heavy** | **B** |
| LT + LB (the vanish) | Y's heavy | Y's heavy (the held set has LB, so the vanish keeps its guard) |
| LT + RB (energy) | Y's heavy | Y's heavy |

The rule off changes nothing either way. The mask is untouched, so LT is still the dodge and the stance bit.

## Why a Controls switch and not the zip's own
The input layer does not read the director's data (`data/director/interrupts.json`). Like `driverOnRb` for the Driver, the switch is **set together with** `zip.flightStrikes.enabled`. Tools' page row `flightStrikes` should flip three things as one: `zip.flightStrikes.enabled`, `switches.flightStrikeB` and `switches.dodgeHeld` (LT held as the finger's state, so the take-back reads the finger and not the stance mask's release grace). It needs `rightStick` and `signatureRtOnly`.

## Proof
`sim/input/test/flight_strike_b_test.gd` (29 checks): the rule off with either switch (B is the signature whatever is held); the rule on, flightStrikeB off (the control: LT + B is the heavy); on (LT + B is B, LB, RB, LT + LB the heavy, none and RT B); with `driverOnRb` too (RB + B Driver, LT + B flight strike, LB heavy); LT still reports the manoeuvre bit. All 38 input tests pass; lint and validate clean.
