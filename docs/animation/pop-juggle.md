# The pop and the juggle (Animation, 2026-10-23)

Owner: Animation. The seventh park of Orb's push, from Encounter's launch-pop (on main) and launch-spike (parked) cues. Parked as `docs/animation/pending/pop-juggle.patch` (render side; a new data file `data/anim/pop.json`, whose schema `anim.pop/1` Tools writes, granted on Orb's word). Apply after `secondary-motion.patch`. **Authored and not yet run**: the quiet window kept Godot off; the gates and the test below are still to do.

## What was there

Under launch anywhere (`anywhere.pop.enabled`, off on main) a launcher under power pops the struck fighter up and back down in reach. The sim carries him on a rush arc and stuns him; the body drew the plain rush pose all the way up and down, with nothing for the rise, the hang, the fall, the second pop's slam, the burst out or the landing.

## What the player sees

The cue `pop` (actor: the popped fighter; text `up`, `slam`, `spike`, `burst`, `tech`, `land`) starts a phase, drawn as poses that move toward their targets over 6 ticks, so a phase, a second cue or the end hands over without a snap:

| Cue | The body |
| :--- | :--- |
| `up` (dur ticks, amount height in body heights) | **rise**: stretched and trailing (`launch.spread`, 0.8); **apex**: hangs limp (`wound.arm_limp`, 0.45); **fall**: tucks and folds (`launch.tuck`, 0.5). By the share of the pop's `dur`, so it follows whatever Encounter sets (24 ticks now). A lower pop shows 0.6 to 1.0 of it |
| `slam` / `spike` | head down, streamlined (`launch.stream`, 0.9 and 0.95), held 8 ticks |
| `burst` | the burst pose (`move.burst`, 0.9), 8 ticks |
| `tech` | the air tech's own sequence (`rt.air_tech`, 14 ticks), as for the rival's tech: thrown open, then tucked |
| `land` | set (n 1): caught in a guard (`stance.defensive`, 0.55, 10 ticks); reeling (n 0): a stagger (`react.stagger`, 0.65, 12 ticks); a spike's landing (amount 1): folded over (`react.fold`, 0.75, 16 ticks) |

From the apex he is free to guard, perfect-block and strike in the air. While a beat plays on him (`_seq` is not empty) the pop's weights drop to 0.35 of themselves, so a strike or a guard reads. A launch, a knockdown or a lock ends the pop's draw. Under reduced motion the weights are 0.6. Nothing is written to the sim.

## Files

`render/anim/anim_fighter.gd` (`on_pop`, `_pop_layer` after the ground layer), `render/anim/render_anim.gd` (the cue dispatch, `RenderAnim.pop_juggle`, `--no-pop`), `render/anim/anim_data.gd` (loader), `data/anim/pop.json` (new), `tools/anim_check.gd` (`_test_pop`).

## Test (to run)

`_test_pop`, both fighters, five cue sequences (up and set; up and reel; up, slam and reel; up, spike and a spike landing; up, burst and set): the body differs from none by 4 units or more while he is up, by 3 units a tick at most, clean 0.3 units after, nothing before; a tech cue counts as the up alone (the tech's own sequence plays). No NaN, no joint past a limit.

## The schema request (Tools)

`data/anim/pop.json`, schema `anim.pop/1`, closed except `_` keys, all required: `ramp_ticks` (integer 6 to 30), `busy_scale` (0 to 1), `height_ref` (above 0); `up`: `rise` `{pose, w (0 to 1), from, to: [two numbers 0 to 1]}`, `apex` `{pose, w, in: [two], out: [two]}`, `fall` `{pose, w, from: [two]}`; `slam`, `spike`, `burst`: `{pose, w, ticks (integer 6 to 60)}`; `land`: `set`, `reel`, `spike`, each `{pose, w, ticks}`. Every `pose` is an id in `poses.json` (cross-reference).

## Not here

Encounter's flip out of a teched pop landing (`recoil` flip) is already drawn by the recoil flips. A juggle blow's own reaction on the popped fighter is the hit reactions' (a variant per blow); the pop's pose sits under it.
