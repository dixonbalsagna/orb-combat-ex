# Air recovery (Animation, 2026-10-23)

Owner: Animation. Window 4 of Orb's push (launch and return). Parked as `docs/animation/pending/air-recovery.patch` (render side; one key, `recover`, added to `data/anim/locomotion.json`, so it rides on the `anim.locomotion/1` schema request in `flight-locomotion.md`). Apply after `hit-reactions.patch`.

## What was there

A launched body was drawn well: the flail, the brace, the flight lead that turns it head first, the air brake's skid when the sim's brake starts. But when control came back mid-air (the sim's brake ends the launch and the fighter is `free` again, well off the ground, still at speed) the body went from the skid straight to the stance: the flight lead let go at its own rate and nothing caught the fighter. The tumble and the return flight already read, so the missing beat was the catch.

## What the player sees

When a fighter goes from launched (or dropped) to free well off the ground (40 units or more) after going 250 units a second or faster, he catches himself over 28 ticks:

| What | How |
| :--- | :--- |
| **The arms** | the brake skid's entry pose (`ab.skid.enter`, arms flung, legs coming under) at 0.55 of a part weight, in over 7 ticks and out over 21 |
| **The torso** | rocks once past upright and settles (spine, head and a little pelvis roll, in opposite phase to the spine): 0.4 rad at most, damped over the 28 ticks |
| **By speed** | the whole catch scales with how fast he was going (0.3 at 450 units a second to 1.0 at 1,500) |
| **Side** | the pelvis roll takes the side of the tumble's spin, so a body that went over one way catches the other way |

It stands aside the moment the fighter is busy (an exchange, a rush, a press-ack or a recoil) and under reduced motion it is 0.6. Every ramp is 6 ticks or more (the snappy profile solves on twos). Nothing is written to the sim; the speed is read from the launched ticks.

## Files

`render/anim/anim_fighter.gd` (`_air_recover_layer`, after the ground layer and before the air-brake layer), `render/anim/render_anim.gd` (`RenderAnim.air_recover`, `--no-air-recover`), `data/anim/locomotion.json` (`recover`), `tools/anim_check.gd` (`_test_air_recover`), `tools/flurry_study.gd` (scenario `rd_catch`; `window.__noar = 1` is the before).

## Tests and gates

`_test_air_recover`, both fighters: a launch at 1,500 units a second 400 units up, ended at tick 60, moves the head 2.5 units or more against no recovery (measured 2.8 and 2.6), by 0.68 units a tick at most, and it has let go a second later; nothing shows before the launch ends; a slow launch (150) and one 8 units off the ground are not caught at all. Gates on a scratch export of main with the earlier four parks: `anim_check` with no arguments (9,008 checks), the scans `--strict`, the 4-body scans, determinism plain and `--intro`.

## Schema

The `recover` key goes into the `anim.locomotion/1` request (flight-locomotion.md): an object `{pose` (an existing pose id), `w` (0 to 1), `ticks` (integer 12 to 60), `rock` (0 to 1), `min_air` (0 to 500), `min_speed` (0 to 3000), `ref_speed` (above 0)`}`, all required.

## Not here

The tumble itself and the return flight (the exchange rush already draws the flight pose; `return` cues are Encounter's and the lead layer owns the head-first turn), kept as they are: the audit found nothing to add there that a clip showed.
