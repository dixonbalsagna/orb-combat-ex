# The air brake's looks, built (Animation, 2026-11-07)

The plan is `air-brake-looks-plan.md` (Orb's morning play: "an air skid ... regained control in midair ... keep tuning these"). One patch, `docs/animation/pending/air-brake-looks.patch`, with the schema keys in `air-brake-looks-schema.patch` (needs the EP's grant). The three looks share `anim_fighter.gd` hunks, so they ship as one patch, but each switches off by data alone (named below).

## What the player sees

| Moment | Before (main) | Now |
| :--- | :--- | :--- |
| **Air brake** (held LT after a knockback or send) | One slanting bar, the hands at the chest, the same open hands for both fighters | A **plant**: the lead leg thrown out toward the travel with the foot flat, the other knee bent behind it, one arm pressed out ahead and the other swung back, the weight dropped, the chest turned to the foe; a 5-tick dig at the start. The Protagonist's hands are open blades, the Anti-hero's are fists (RL-218 (2)) |
| **Regain** (control back in the air, 40 units or more up, 250 u/s or more) | The lean let go in 2 ticks, a 0.55-weight arm shift, then a rigid hang; the face flipped to the way he drifted for about 12 ticks, then back | The lean **unwinds over 10 ticks** (`unwind_rate` 9 a second, was 45); the **face stays on the foe** the whole recovery and turns once, after the lean is gone (a mirror of a leaning body is a pop); a **tuck** (knees drawn up, hands in, 0 to 8 ticks) then a **sweep** (arms out and down, legs dropped under, 8 to 15) that lets go into the guard by tick 28. The recovery's strength has a floor (`p_min` 0.6): Orb's regain is at about a third of the send's speed, where the old scaling gave it 0.3 |
| **Skid landing** (a landing out of the brake) | The plant gone in 4 ticks, then the shared crouch | The plant **eases off over the exit ramp** (5 ticks, no snap: `brake.json` `exit_ticks` 5, RL-255) into his own **slide pose** for 0.6 s after the brake was last on: the lead foot dug in far behind, the weight low, one hand trailing near the floor, the other arm up toward the foe. Any other slide is `slide.brake` as before |

## Where

- Poses: wave `brake2` (`render/anim/tools/waves/brake2.mjs`, prefix `ax`): `plant_p` / `plant_r` (dig, hold, exit), `regain_p` / `regain_r` (tuck, open), `land_p` / `land_r` (hold); 12 poses; pose_lint 0 issues; `anim_held_lint` classes `ax.` as rest.
- Code (`render/anim/anim_fighter.gd`): `_air_brake_layer` reads the fighter's own plant (`brake.json` `fighters`) and carries the plant into a landing; `slide_pose_id`; `_air_recover_layer` plays the tuck and sweep (`locomotion.json` `recover.fighters`); `_recovering` (the lead's slower unwind); `_wanted_face` holds the face for the recovery. `render/anim/anim_data.gd` loads wave `brake2` with the brake's waves.
- Data: `data/anim/brake.json` (`fighters`, `unwind_rate`, `land_s`), `data/anim/locomotion.json` (`recover.p_min`, `tuck_w`, `open_w`, `fighters`).
- Off by data: delete `brake.json` `fighters` (back to the shared plant and slide), delete `locomotion.json` `recover.fighters` (back to the single catch pose), delete `brake.json` `unwind_rate` (back to the snap). `--no-air-brake` and `--no-air-recover` are the before as ever.

## Checks

- `_test_air_brake_looks` (new, both fighters, on the real solve): the six poses exist; the Anti-hero's carry no open hand; no NaN and no joint past a limit through the brake, the regain and the landing; the face never turns from the foe in ticks 60 to 100 of the recovery; the lean takes 10 ticks (6 or more wanted) to fall under a fifth of itself; the tuck sinks the pelvis 8.1 and 7.0 units; the plant still has weight 0.38 on the first tick of the landing; the landing plays his own slide pose, then `slide.brake` from 0.6 s on and for a slide with no brake before it.
- `_test_air_recover` (old): the head's step is now taken against its own track (7.9 units a tick at most; against none it was a 49-unit mirror at the control tick, the old behaviour being a snap that the new unwind and the held face remove); the slow and low launches are still caught by nothing.
- Full `anim_check`, `validate` (0 errors with the schema patch), self-test, the two-fighter ratchet (365, unchanged).

## Not yet seen

- **The real renderer.** The clips here are stick figures from the real solve (`art/animation/review/air-brake/*-AB.png`, A over B, ticks at 60 a second), not renderer frames: the flight-strike clips came from a hand-staged web scene, and a staged knockback with the sim's real brake needs the air-brake switch set in a capture build. The look gate's side-by-side against the reference build is for the EP's capture of a build with this patch (the brake is on in Orb's build, so any ordinary knockback with LT held shows it).
- **The sim's real regain.** Staged with the sim's own rules (control back at a third of the send's speed, the facing the sim gives); if the sim turns the fighter's own `face` during the brake, the one clean turn will show then.
- **The flash gate**: nothing here adds light; the tuck and sweep move limbs only. Not run.
- Legal: stills of the plant and the sweep's widest frame, both fighters (RL-218 (2) and (4); the sweep's hands are 22 and 21 out in depth, under h02's 32, and it lasts under 10 ticks).

## Changes after the first cut (2026-11-07, Legal's RL-255 and the EP)

- `brake.json` `exit_ticks` 8 to 5: the plant lowers within 5 ticks when the brake ends (the EP agreed 5; the old rule of 6 or more on twos gives way to it for this ramp). The test's carry threshold follows it.
- The longest brake: 36 ticks with ki, 72 with none (`creative-rulebook.md`: a rulebook call, not a Legal gate).
- Real side-by-side: `docs/animation/runs/85e838b6/air-brake/` (CD-22).
