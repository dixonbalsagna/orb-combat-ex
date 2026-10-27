# Secondary motion (Animation, 2026-10-23)

Owner: Animation. Window 5 of Orb's push. Parked as `docs/animation/pending/secondary-motion.patch` (render side; a new data file `data/anim/secondary.json`, whose schema `anim.secondary/1` Tools writes, granted on Orb's word). Apply after `air-recovery.patch`.

## What was there

The sash and pack (five spring bones) trail the velocity and flutter at speed. Nothing else on the body followed through: the head, the back and the arms were placed by the pose and stopped dead with the body. There is no hair, coat or tail bone in the rig (hair is a palette colour), so the follow-through here is of the body's own loose parts.

## What the player sees

Four loose parts, each on its own damped spring, stepped once per sim tick beside the cloth (so a replay shows the same):

| Part | Behaviour |
| :--- | :--- |
| **Head** | lags a start and a stop and nods at a landing and a take-off, 0.3 rad at most; snaps away from a blow and settles |
| **Upper back** | the same, smaller (0.18 rad) |
| **Forearms** (both) | hang free: they trail a run, fling up at a landing, swing on after a blow (0.55 rad at most, loose springs) |

Each is kicked by the change in the body's velocity over the tick (along the way he faces and up; a landing's one-tick stop is the biggest) and by a blow (`on_hit`, scaled by force, away from the blow). The Protagonist's follow-through is loose and wide (1.15, damped 0.85), the Anti-hero's tight and quick (0.85, damped 1.15). Under reduced motion it is 0.5; a frozen tick (hit-stop) runs at a tenth. It is applied before the pose join smoothing, so nothing pops. Render only.

## Files

`render/anim/anim_fighter.gd` (`_follow_tick`, `_follow_kick`, `_follow_apply`), `render/anim/anim_data.gd` and `render_anim.gd` (loader, `RenderAnim.secondary_motion`, `--no-secondary`), `data/anim/secondary.json` (new), `tools/anim_check.gd` (`_test_secondary`), `tools/flurry_study.gd` (scenario `sc_course`; `window.__nosec = 1` is the before).

## Tests and gates

`_test_secondary`, both fighters, on a run, a stop, a hop and landing and a blow: nothing moves standing still; the forearms follow a start and a stop by 1.5 units or more (measured 2.8 and 3.1 for the Protagonist, 2.0 and 2.2 for the Anti-hero), a landing swings the hand 2 units and the head 0.5, a blow 2 and 0.6; no part turns more than 0.09 radians a tick (measured 0.084 and 0.056); it has settled a second after the last blow. Gates on a scratch export of main with the earlier five parks: `anim_check` with no arguments, the scans `--strict`, the 4-body scans, determinism plain and `--intro`.

## The schema request (Tools)

`data/anim/secondary.json`, schema `anim.secondary/1`, closed except `_` keys, all required: `dv_ref` (array of two numbers above 0); `hit`: `{force_ref}` (above 0); `parts`: exactly `head`, `spine_2`, `forearm_l`, `forearm_r`, each `{stiff` (1 to 300), `damp` (0 to 30), `gx`, `gy` (numbers -10 to 10), `hit` (0 to 20), `max` (0 to 1.2)`}`; `fighters`: a roster id (`^[A-Z][A-Z0-9_]*$`) to `{scale` (0 to 3), `damp` (0.1 to 3)`}`.

## Not here

Hair, coat and tail follow-through proper: the rig has no bone for them. That needs a rig change (a hair chain on the head, a coat chain on the pelvis) and the renderer's draw for them, which is Art's and Rendering's. Parked until they ask.
