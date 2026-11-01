# Standing beats (Animation, 2026-10-31)

With the water family's floor on, a free fighter stands far more than he hovers (his floor in the ring's water is its surface less his feet), and the stance of a standing body is lower and leans: the head 11 units ahead of the pelvis (4 in the hover), the pelvis 32.3 up (36.6). Several layers were set on the hovering body: what they add to a standing one is small or reads differently. This park stages the checks on a standing body and retunes what did not read.

## The checks

`anim_check.gd` stages a body at `y = 0` ("on the ground"). The match is a planet and the tests' x (500 to 1900) is deep sea whose bed is 2,633 units under it, so with the floor off that body hovers, and with it on it stands. The five tests whose subject is the body's own stance (press-tick anticipation, lunge crouch, styles, medium wind, energy reach) now set `_standing`: `_stage_y` puts both fighters on the sim's own floor (`WorldWater.floorAt`; the sea bed with the floor off, the surface with it on). Every other test keeps y = 0. Result on this tree: anim_check 10,014 checks, 0 failures with the family off and with it on.

The one failure left with the family on ("zip view down: ... the state locked") was the check's, not the body's: with the water interrupt on the drop ends early and the AI's next exchange starts inside the 60 ticks after it (states dropped x24, free x28, locked x10 on; dropped x24, free x38 off), so the run's last state is "locked". The check now asks that the body's drop is gone and the sim let him up ("free" after the last dropped tick). This part of the patch needs `water-checks.patch` under it (its context is that patch's zip lines).

Flash (collapse clip, Tools' check-clip, main 7b624ea7 against main plus this park alone): normal 2 general, 0 red, area 2.5; reduced 2, 0, 2.5, both exports, PASS in both modes, identical readings.

## Retuned (all render only, outside the sim hash)

- **Press-tick and lunge crouch** (`ak.x_p.set`, `ak.y_p.set`, wave ack1): the light cell was LESS crouched than `stance.aggressive` (lean 8, hips -3 against 10, -4), so the Protagonist's light cell added 0.43 units and its lunge crouch 0.35. Now the light is lean 14, hips [5,-6] (crouch 3.9 at the end of the 6-tick wind-up) and the heavy is lean 18, hips [3,-11] (10.5, the Rival's heavy is 10.4). `ak.y_p.set`'s hand_l pulled to reach (lint clean).
- **Mashed Y** (`press_styles.json` medium `press_run`): bob 2.6 to 7.0 units, lean 4.5 to 5.5 degrees a blow (max 26). A mashed heavy now pounds on a standing body; tap and mash were 1.5 apart.
- **Energy in reach** (`press_styles.json` `energy_back`, `_run_layers`): the standing lean put the two heads 16.7 and 17.2 apart in a run of bolts (Legal e09 wants 18 or more). A bolt or blast now sits the shoulders back 4 degrees and the root 3.6 units, in over the blow and out over 8 ticks after contact: heads no nearer than 18.4 and 20. `pk.bolt_flick` contact (hips -14 to -20) and `rk.bolt_flick` (-22 to -26) go lower so a flick still rises past the lines, and `rk.bolt_sweep` (hips 5 to 11) falls further (-47 against the lines' -25 and -10). pose_lint issues on pk. and rk. fall (13 to 12, 17 to 15).

## Thresholds reset

- Styles: 2.5 to 1.9. On a standing body the fighters are 1.9 apart at the median and the pose half of every distance is smaller; the rule is now "at least as far apart as the two fighters". Nearest pair after the retune is 1.98 (Protagonist tap~mash); tap~hold is 2.0.
- Medium wind, uppercut (w8): the check read the hand's height 4 ticks out; on a standing body the guard hand already sits at the chamber's height, so it read the rule as higher. w8's meaning is "no dip first": the check now reads the pelvis (26.9 with the rule, 25.1 without; the hover 29.1 and 26.3).
- Press-tick (1.2 at tick 8), lunge crouch (2.5) and energy reach (18, flick/sweep path angles) keep their thresholds.

## Clips (local, art/animation/review/standing-beats/)

A (main) beside B (this park), same ticks, inputs drawn: `standing-lunge|ymash|bolts-protagonist|rival-AB.gif`. Scene: the idle dummy; X from 330 units (lunge crouch) and again in the cooldown (press-tick); Y from 330; Y mashed five times; RB held with X tapped.
