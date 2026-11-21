# Step-up: the landing crouch's opening frames when a floor lifts a fighter (Animation, 2026-11-20, parked for GW1b)

Game Design's ruling (docs/design/buildings.md 2026-11-20): World's floor-rise lift stays uncapped in the sim, and the view plays a short step-up when a floor lifts a grounded fighter by more than 0.5 body heights in one tick. Design and proof: `docs/animation/step-up.md` (inside `step-up.patch`, which adds it).

## Files

| File | What |
| :--- | :--- |
| `step-up.patch` (sha1 5c37d7aa) | `render/anim/anim_fighter.gd` (the ground layer reads his height from the last solve; `_gl_ld_ticks` lets the landing run a step-up's own length), `data/anim/ground_motion.json` (`step_up` row), `render/anim/tools/anim_check.gd` (`_test_step_up`, 2 helpers), new `docs/animation/step-up.md`. Applies on HEAD a25e9d9b and on the GW1a stack (s422), checked |
| `step-up-schema.patch` (sha1 71c0cf08) | `tools/schemas/anim-ground-motion.schema.json`: the optional `step_up` block. **Needs the EP's grant.** `validate` fails without it |

## Result

- `anim_check`: **0 failed, 10,556 checks** on the GW1a stack plus World's floor-rise grant (the stack's 10,538 plus the step-up's), and **0 failed, 10,556** on fresh main with both patches. `validate` 0 errors, self-test 10,093 of 10,093, two-fighter ratchet 365 unchanged (main, both patches). `records/`.
- `_test_step_up`, both fighters: a 0.9 body-height lift crouches the pelvis 5.4 units on the stack's site (3.4 on main's, another surface) over 12 ticks, one step-up for one lift, no NaN or joint limit, never moved down into the bank; a 0.3 lift, a jump of place, a rise from the air and the row off do nothing.
- The look gate's side-by-side: `docs/animation/runs/a25e9d9b/step-up/` (GIFs of A without the step-up and B with it, a contact sheet; the lift staged by hand, see below).

## What is and is not shown

- The clips stage the lift by hand on the real renderer (the bank is raised and he is put on it, as World's floor-rise does in one tick). No real match produced one (Game Design: it needs a fighter already inside a rising floor stepping onto a 2.6-in-1 bank). The check reads the sim's height, so a real lift reads the same.
- It is small: 5 units of a 75-unit body is a hitch, not a gesture, at the fight camera's distance (the contact sheet shows the dip against A). If Orb wants it bolder it is `p_min` and the land row's sink (data).
- It does not play while he is busy (an exchange, a rush, a hold, a launch): the ground layer stands aside, and the camera's ease covers those.
- **The tile-ground water-stance probe** (the EP's other item) is not in this park. It follows.

## Nothing else changes

No sim file is touched (the lift is read from the fighter's height, never written); no change to anything without the row's trigger; the look gate's flash gate does not apply (limbs only, no light).
