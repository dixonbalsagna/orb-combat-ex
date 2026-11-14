# Parked: no pull back to the fight line through the air after a wall (with World's held cityHold row)

Encounter, 2026-11-14, sprint A1. This is the ping-pong bug Orb named on 14 November: "a fighter bounces off something in the background and then ricochets in an unrealistic and immersion-breaking trajectory".
- The cause is in `brunt.gd`: the stand-in's planet design, section 7, confirmed against the code and in Orb's 1646 match. Today a wall throws him back at a quarter of his speed, freezes the fight, and his depth is pulled back to the line mid-air.
- World's held `cityHold` row (`lodgeHold` body, `wallRebound` 0, `wallStop` 0, `wallDepthHold` 1, `repeatMarks` 2) removes the throw and the freeze.
- But **for a slam high up a tower the fall outlasts the hold,** and `stepZ` still pulls his depth home while he's falling.
- This park is that last piece. **It acts only with `wallDepthHold` on, so the golden doesn't move.** It rides with `cityHold` into Orb's private build, and onto main only on Orb's word.

## What it does

**One line in World's `stepZ`** (a grant): with the wall's depth hold on, a launched body isn't pulled home through the air (`z *= 0.001^dt`, a third of a second). His depth stays for the flight, and once he has landed `DirPlane` eases him home on the ground (`depth.json` `planeEasePerTick` 20, eased in and out, never a snap). A test-only static, `WorldBrunt.testHoldAirOff`, keeps the old pull for the negative control.

**The in-air chain is untouched.** Knock, zip round and knock again is the director's sends (`DirLaunch.doLaunch` from the opponent's blows). This changes only where a body's depth goes after a wall. With `cityHold` on, the director's flight strike, follow, knock-wall, chase, swing and city-push checks all pass.

## The readings (World's staging: seeds 1 to 8, tiers 1 to 3, a 9 to 15 floor tower on the front street)

| | Today | `cityHold` as built | `cityHold` + this |
| :--- | :--- | :--- | :--- |
| Sent from 100 up (16 wall slams): thrown back off the face | 16 | 0 | 0 |
| ... the whole fight frozen | 0.50 s | 0 | 0 |
| ... depth home while still in the air | 100% | 0% | 0% |
| Sent from 900 up (8 wall slams): thrown back | 8 | 0 | 0 |
| ... depth home while still in the air | 100% | **100%** (the fall outlasts the hold) | **3%** |
| ... back on the line | 51 ticks, in the air | 49 ticks, in the air | 83 ticks, on the ground |

## Apply

On main def3445a: `git -c core.autocrlf=false -c core.eol=lf apply grant-world-holdair.patch wall-return-check.diff`. It has no effect until `cityHold`'s values are set (`tools/preview/switches.mjs` row `cityHold`).

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `grant-world-holdair.patch` (`sim/world/brunt.gd` `stepZ`: one line, plus the test-only static) | World | e8e051e0ac8d15e4089c4d1084374b802b471ce2 |
| `wall-return-check.diff` (the new check `sim/director/tools/wall_return_check.gd`) | Encounter | a1ca73c75f7b3a723861178cd2f940fefb3dfe5a |

## The check

`wall_return_check.gd`, 5 checks: World's staging, sent from 100 and from 900 above the ground.
- Wall slams staged.
- Today: every slam throws him back, and his depth comes home in the air (the bug).
- `cityHold` with the grant: nobody thrown back, nothing frozen.
- `cityHold` with the grant: his depth comes home after he lands (at most a tenth in the air), inside 240 ticks.
- **Negative control,** `cityHold` as built: from 900 up his depth comes home in the air.

## Proof

The gates ran on main def3445a plus both patches. Records are in `docs/director/runs/def3445a/wall-hold-air/`, and every output went through `tools/gate.mjs` with no SCRIPT ERROR.
- **The golden check passed, so the golden doesn't move:** `wallDepthHold` is 0 on main.
- Validate 0 errors; self-test 10,093 of 10,093; ratchet 365.
- These checks pass: `wall_return_check` (5 of 5, its negative control included), `knock_wall_check`, `city_push_check`, `flight_strike_check`, `follow_check`, `swing_check` and `plane_check`.
- The core checks `two_states` and `load_split` pass.
- World's own checks on main's defaults pass: `wall_check`, `brunt_check` and `wall_hold_check`.
- **Render:** 15 of 15.

## NEEDS FROM EP

- **World:** the grant (one line). With `cityHold` on, World's `wall_check` ("the homework switches stand at today's") and `brunt_check` ("the last hit holds the body for the tier's seconds", which reads a whole-fight hold) each fail one row by design. They need `cityHold`-aware rows when the row lands.
- **QA's city read** and **Orb's private build** with `cityHold` and this, as you've arranged.
