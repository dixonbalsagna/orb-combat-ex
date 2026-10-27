# The mid-band lunge's crouch (Animation, 2026-10-23)

Owner: Animation. Parked as `docs/animation/pending/lunge-crouch.patch` (render side, plus one key in `data/anim/press_ack.json` and its schema, granted on Orb's word). From Encounter via the EP: Performance's mid-match "5 ticks late" light is the mid-band lunge's authored wind-up (`bands.lunge.windupTicks`: light 6, heavy 10, from 225 units or more) and no pose drew it. The sim reacts on the press tick (a rush event, the cue `lunge_light` or `lunge_heavy` with `amount` the crouch's ticks, `press_ack` started) and the body moves only when the crouch ends.

## What the player sees

On the press tick the fighter drops into his crouch and deepens it over the cue's own ticks (6 for a light, 10 for a heavy, 10 for the return from a send: the `return` cue), then hands over to the travel with no snap: the layer lets go over 6 ticks as the rush begins. It is the press-ack's pose for the weight (the light's cell `x`, the heavy's `y`), each fighter's own, at 0.9 and 0.95 of it (the return's 0.8). A crouch of under 6 ticks is not drawn: the snappy profile solves on twos, so a shorter ramp reads as a snap (the lesson of the anticipation). In measure: the Protagonist's crouch is 5.5 units deep at the end of a light's 6 ticks and 12.1 at the end of a heavy's 10, the Anti-hero's 3.4 and 8.5; the largest one-tick change is under half the crouch.

## Files

`render/anim/anim_fighter.gd` (`on_lunge_crouch`, the press-ack layer's ramp length read from the crouch), `render/anim/render_anim.gd` (the cues `lunge_light`, `lunge_heavy`, `return`, and a charge cue with a wind-up), `data/anim/press_ack.json` (new key `lunge`: `light`, `heavy`, `return`, each `{cell, w}`), `tools/schemas/anim-press-ack.schema.json` (the key, required: the schema edit is Animation's, as Orb's word grants), `tools/anim_check.gd` (`_test_lunge_crouch`), `tools/flurry_study.gd` (scenarios `lu_light`, `lu_heavy`; `window.__nolu = 1` is the before). `RenderAnim.press_ack`, `--no-press-ack`.

## Tests and gates

`_test_lunge_crouch`: both fighters, a light, a heavy and the return: the crouch is at least 2.5 units deep when its wind-up ends, the body is exactly the stand again after the travel starts, no tick changes it by more than 0.6 of its size, no NaN or limit; a 4-tick crouch draws nothing. `node tools/validate.js` and its self-test pass with the schema edit. Gates on a scratch export of main: `anim_check` with no arguments, the scans `--strict`, the 4-body scans, determinism plain and `--intro`.

## Look gate

`docs/animation/img/lunge-crouch-before-after.gif`: real play on a scratch build (two scripted players; P1 holds 250 units from the idle P2 and presses a light, then a heavy), before on the left and after on the right, cropped to the presser. The crouch is a lower, leaning stand through the wind-up, then the lunge. Nothing is drawn on the fighters.

## Re-cut 2026-10-23: a short wind-up is drawn too

Performance found a mid-match light still moves the body first at about 130 ms: a wind-up reported as 5 ticks fell under the 6-tick ramp rule and drew nothing. A wind-up of 3 to 5 ticks is now drawn over 6 (the crouch overlaps the travel's first ticks and the exit ramp hands over, so there is still no snap); under 3 ticks nothing. `anim_check` gains a 5-tick light row and the "never drawn" row moves to 2 ticks.

