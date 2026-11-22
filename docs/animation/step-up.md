# The step-up (Animation, 2026-11-20; parked for GW1b)

Game Design's ruling (`docs/design/buildings.md`, 2026-11-20): the sim keeps World's one-tick floor lift uncapped (`docs/world/pending/floor-rise/`: a free fighter on a rising lake floor, or stepping onto a steep bank, is put on the floor in one tick, never inside it), and **the view covers it**: a lift of more than 0.5 body heights in one tick plays a short step-up, the landing crouch's opening frames, and the camera's own ease absorbs the rest. Nothing is drawn inside the bank.

## What was built

- **The rule** (`AnimFighter._ground_layer`, `render/anim/anim_fighter.gd`): the layer reads the fighter's height and place at each solve (`_gl_prev_y`, `_gl_prev_x`; read only, nothing written). If he was grounded and still is, his height rose by more than `min_bh` (0.5) body heights since the last solve, he moved at most `max_move` (200) units sideways, and he is not rising on his own (`vy` under the take-off's minimum), it starts the landing crouch with the step-up's own length. A hop, a fall, a rise from the air and a jump of place (a respawn, a teleport) are not lifts.
- **The look:** the landing's own sink and flex (`land` row, by surface), at a strength of the lift over `ref_bh` (2) body heights and never under `p_min` (0.5), over `ticks` 12 (in over 6, out over 6: the "opening frames" of an 18-tick landing, let go early). A 0.9 body-height lift is a 5.4-unit crouch of the pelvis on a 75-unit body, both fighters. The body is never moved down into the bank. It stands aside while he is busy (an exchange, a rush, a hold, a launch), as the landing does.
- **The data:** `data/anim/ground_motion.json` `step_up` (`enabled`, `min_bh`, `bh`, `max_move`, `ref_bh`, `p_min`, `ticks`), with its schema (`step-up-schema.patch`, tools/schemas/anim-ground-motion.schema.json: optional block). Off by `enabled: false`.
- **The check:** `_test_step_up` (both fighters, on the real rig). A bank is raised under him by hand (the terrain's deform, and his height set to the new floor, as the sim does in one tick) on flat dry land; rows: a 0.9 body-height lift crouches the pelvis 2 to 9 units (5.4 measured) and lets go inside 14 ticks (12), without a pop (2.59 units in a solve, under the idle body's twos), one step-up for one lift, no NaN or joint past a limit, the body's height offset never negative (never into the bank); a 0.3 lift, a jump of place (400 sideways), a rise from the air and the row off each leave the pelvis as it was with no lift (to 0.05).

## Proof

- `anim_check` on the GW1a stack plus World's floor-rise grant: 0 failed, 10,556 checks (10,538 before; the step-up adds `_test_step_up`'s). On main with the patch: see the park's README.
- The look gate's side-by-side: `docs/animation/runs/a25e9d9b/step-up/` (GIFs and a contact sheet, A without the step-up, B with it).

## Not shown, not proven

- **The lift is staged by hand in the clip** (the bank raised and the fighter put on it, as World's floor-rise does): the sim's own lift needs a fighter inside a rising floor stepping onto a 2.6-in-1 bank, which Game Design calls rare. The check reads the sim's height, so a real lift reads the same; no real match in the repository produced one.
- **A rush or an exchange in progress** does not play it (the ground layer stands aside); the camera's ease covers those.
- **The size:** 5 units of a 75-unit body is a small dip at the fight camera's distance. It reads in a close still; at the shipped camera it is a hitch, not a gesture, which is the ruling's intent. If Orb wants it bolder it is `p_min` and the land row's sink.
