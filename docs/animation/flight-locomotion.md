# Flight locomotion (Animation, 2026-10-23)

Owner: Animation. Window 1 of Orb's push ("fighters that move with weight, personality and variety in every common moment"; EP brief of 2026-10-23). Parked as `docs/animation/pending/flight-locomotion.patch` (render side; a new data file `data/anim/locomotion.json`, whose schema `anim.locomotion/1` Tools writes, granted on Orb's word). Apply after `lunge-crouch.patch`.

## What the player sees

A free fighter in the air now moves with weight. All of it is read from the sim's velocity, the dash input and the height above the ground (never written), and every ramp is 6 ticks or more (the snappy profile solves on twos: a shorter one reads as a snap).

| Moment | What the body does |
| :--- | :--- |
| **Acceleration** | the torso pitches into the acceleration on a spring: the shoulders lead (spine 0.4 and 0.55 of the lean), the pelvis counters, the neck and head follow. Up to 12 degrees at full acceleration; the Protagonist's spring is softer and floatier (damping 0.85), the Anti-hero's crisp (1.0) |
| **Overshoot** | the spring is underdamped, so when the speed settles the lean swings past zero and back: a dash that ends rocks forward, a stop rocks back and forward again |
| **Braking** | a hard stop from speed leans him back (65% of the forward lean) and flares him: the brake skid's own pose (`ab.skid.hold`) mixed in at 0.3, in over 12 ticks, when he decelerates past 1,800 units a second squared from over 330 |
| **Dash** | the press coils him for 8 ticks (the weight back, the hips down 2.4 units) before the speed is up, and the surge's forward lean then takes him forward: an anticipation the sim's own speed ramp (a 0.14 s time constant) leaves room for |
| **Banking** | the velocity's heading turning past 280 units a second rolls the body 12 degrees about its forward axis (the spine and head opposite the pelvis) and leans it into the turn |
| **Hover breathing** | slower than 140 units a second and off the ground, the chest and shoulders rise and settle (2.4 and 3 degrees), the head eases against them, the hips float: the Protagonist slow and wide (0.3 Hz), the Anti-hero quicker and tighter (0.44 Hz, 0.7 of the depth) |

It stands aside (and eases away over 8 ticks) while the fighter is in an exchange, a lock, a rush, a hold, a press-ack anticipation, a recoil or a launch, because those draw the body themselves. Under reduced motion the lean, the bank and the breath are 0.5.

## Files

`render/anim/anim_fighter.gd` (`_loco_layer`, after the press-ack layer), `render/anim/anim_data.gd` and `render_anim.gd` (the loader, `RenderAnim.flight_loco`, `--no-flight-loco`), `data/anim/locomotion.json` (new key set), `tools/anim_check.gd` (`_test_locomotion`), `tools/flurry_study.gd` (scenario `fl_course`; `window.__noloco = 1` is the before).

## Tests and gates

`_test_locomotion` drives the sim's own velocity smoothing (`fighter.gd`: `k = 1 - 0.0008^dt` toward the stick's speed) through a course of hover, cruise, dash, stop, arc, reversal and hover, for both fighters: the acceleration leans forward (0.35 or more, the head 1.2 units or more ahead), the stop leans back (0.3 or more) and the spring overshoots (the lean crosses zero), the stop from the dash flares (0.3 or more) and the cruise's start does not, the dash's coil dips the head 0.8 units or more at the press, the arc banks 0.25 or more, the hover breathes (the head moves 0.3 units or more) and not at dash speed, nothing changes the head by over 4 units a tick against the plain run (a stop from a dash is quick), no NaN or limit; and a lock switches it all off (nothing after 30 ticks). Gates on a scratch export of main with the lunge crouch: `anim_check` with no arguments, the scans `--strict`, the 4-body scans, determinism plain and `--intro`.

## The schema request (Tools)

`data/anim/locomotion.json`, schema `anim.locomotion/1`, closed except `_` keys, all required: `enter_ticks` (integer 6 to 30); `lean`: `stiff` (number 10 to 400), `damp` (1 to 60), `max_deg` (0 to 30), `back_scale` (0 to 1), `acc_ref` (number above 0), `filter_s` (0.005 to 0.5), `lag`: `pelvis`, `neck`, `head` (numbers -1 to 1); `flare`: `pose` (a pose id), `w` (0 to 1), `brake_ref` (above 0), `min_speed` (0 to 2000), `ticks` (integer 6 to 30); `dash`: `dash_ticks` (integer 6 to 30), `lean_back` (0 to 1.5), `dip` (0 to 10); `bank`: `roll_deg` (0 to 30), `omega_ref` (above 0), `min_speed` (0 to 2000), `lean_in` (0 to 1); `hover`: `still_speed` (above 0), `rate_hz` (0.05 to 2), `chest_deg` (0 to 10), `shoulder_deg` (0 to 10), `bob` (0 to 5), `off_ground` (0 to 100); `fighters`: roster id (`^[A-Z][A-Z0-9_]*$`) to `{rate, depth, lean, damp}` (numbers 0 to 3). Cross-reference: the flare pose exists in a wave.

The air-recovery park adds one more required key, `recover` (see `air-recovery.md`): `pose` (a pose id), `w` (0 to 1), `ticks` (integer 12 to 60), `rock` (0 to 1), `min_air` (0 to 500), `min_speed` (0 to 3000), `ref_speed` (above 0).

## Not here

The turn at a reversal (a facing flip drawn as a pivot), the wind and cloth on all of this (secondary motion is window 5), the take-off and landing (window 2).
