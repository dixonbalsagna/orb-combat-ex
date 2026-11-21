# Step-up: the side-by-side (Animation, 2026-11-20, run on main a25e9d9b's GW1a stack)

A and B are the same build, the GW1a stack (s422) plus World's floor-rise grant plus `step-up.patch`; A has `step_up.enabled` false in `data/anim/ground_motion.json`, B true. Scratch web exports on the strip ground (`notiles`), the real renderer and rig.

The lift is staged by hand: at tick 40 of a 120-tick cycle the floor under the idle first fighter is raised by 0.9 body heights in a bank 41 columns wide, and he is put on it in the same tick, as World's floor-rise does. (No real match produced one; Game Design calls it rare.) The camera's own ease follows, as the ruling says.

| File | What |
| :--- | :--- |
| `step-up-protagonist-AB.gif`, `step-up-antihero-AB.gif` | A beside B, ticks 30 to 76, half speed |
| `step-up-protagonist-A-over-B-contact-sheet.png` | the Protagonist, A over B at ticks 39 to 51 |

What it shows: the same lift and the same camera in both; in B the pelvis dips about 5 units (of a 75-unit body) for 12 ticks, in over 6 and out over 6, then the stance is back. It is small at the fight camera's distance, a hitch rather than a gesture. Nothing is drawn inside the bank in either. The flash gate does not apply (no light). Numbers: `docs/animation/pending/step-up/records/`.
