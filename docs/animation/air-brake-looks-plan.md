# The air brake, the skid landing and the regain: a plan for readable looks (Animation, 2026-11-07)

From Orb's morning play ("I did pull off an air skid ... I regained control in midair after a knockback in a less spectacular fashion. Keep tuning these, these will look great with polish"). Orb's file has no brake mark; the held-LT stretches after a launch are at about ticks 1055, 7740 and 15518 (of 19,280). Rather than replay them, the three moments were staged on the real solve (a knockback at 1,600 u/s, the brake from tick 30 to 60, then control back in the air, or a landing into the skid) and drawn as stick strips (`art/animation/review/air-brake/current-*.png`, local).

## What the strips show (main today)

1. **The brake is one straight bar.** The flight lead leans the whole body 18 to 45 degrees against the travel and the three shared poses (`ab.skid.*`) keep the hands near the chest, so feet, hips and head line up on a slant. It reads as "sliding", not as "standing on the brakes". The two fighters share it, open hands and all (the Anti-hero keeps no open hand under RL-218 (2); the old poses predate that rule).
2. **The regain has no beat.** At the sim's control tick the lean lets go in about 2 ticks (45 degrees to upright), then the "catch" is a 0.55-weight arm shift and a 0.2 rad rock that does not show at fight distance, and he hangs rigid in the air.
3. **The regain turns him the wrong way.** Free at 250 units a second or more faces the travel direction, so a body that was knocked away from the foe and regains control still moving away flips to face away for about 12 ticks, then flips back as he slows: two turn-steps in a row, the first one wrong.
4. **The skid landing snaps.** Plank to crouch in 4 ticks (`slide.brake`, lean 25, arms by the sides), no carried weight, no foot dug in.

## The looks

| Moment | The new look | How |
| :--- | :--- | :--- |
| **Air brake** | A clear **plant**: hips dropped, one leg thrown out ahead toward the travel with the foot flat (the planted heel), the other knee bent behind it, the near arm out ahead and low pressing against the air, the far arm swung back for balance, the chest turned toward the foe so he brakes facing him. A silhouette with a corner in it (a K, not a bar). A 6-tick dig at the start (the lean overshoots 8 degrees and settles), the judder as it is | New poses in wave `brake2`, one set a fighter (Protagonist: flat blades; Anti-hero: fists), named in `brake.json` by fighter; the lead's lean numbers up a little |
| **Regain** | Three beats over about 26 ticks: **unwind** (the lean eases to upright over 8, no snap, the planted leg draws in), **turn to face** (the facing is held on the foe the whole recovery, and one clean pivot with the turn layer's step if he faced away), **flourish** (a quick tuck of the knees and an arm sweep that ends in the guard: passing through, never held, one frame of "arms out" at most) | `_air_recover_layer` re-cut; one pose pair a fighter; face rule in `_wanted_face` while the recovery runs |
| **Skid landing** | The plant carried to the ground: lean 40, hips low, the lead foot dug in ahead, one hand trailing near the floor, eased in over 6 ticks from the air plant (no snap), and a push-up into the stance with a step as the slide ends | `slide.brake` per fighter; blend from the brake weight |

## Inside the rules

- RL-218: hands as above, nothing held, no head target, no glow (VFX's dust and sparks are theirs), no hand at a hip, no clasp, no both-arms-wide held pose (the flourish passes through it in under 6 ticks and ends in the guard; Legal gets stills of it).
- Nothing is written to the sim; every ramp is 6 ticks or more (the snappy profile solves on twos); reduced motion plays 0.6.
- Look gate (ADR 0010): this changes a look Orb sees now (the airBrake switch is on in his build), so A and B clips with LT and the stick drawn, both fighters, both flashes modes, through the side-by-side. No dissolves, fades or blurs.

## Parks, in order

1. **brake-look**: the plant poses and the dig, per fighter. Data and a wave only.
2. **regain-look**: the three beats and the facing rule. Layer, data, tests.
3. **skid-landing**: `slide.brake` per fighter and the blend.
Each is a separate patch against main; clips with the button strip come with each.

## Cost

About 300,000 tokens: poses and sheets 70,000, the regain layer, the facing rule and tests 110,000, the landing 50,000, clips and gates 70,000.

## Asks

- **Legal:** stills of the plant (both fighters) and of the flourish's widest frame.
- **Encounter / Simulation:** none. The sim's `air_brake` events (start, end with the reason) are enough; the landing reads the slide state it already has.
- **VFX (if it wants):** a dust drag at the planted foot and a streak while the brake is on; the body leaves room for it.
