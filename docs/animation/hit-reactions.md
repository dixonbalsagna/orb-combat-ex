# Hit reactions with variety (Animation, 2026-10-23)

Owner: Animation. Window 3 of Orb's push. Parked as `docs/animation/pending/hit-reactions.patch` (render side; a new data file `data/anim/reactions.json`, whose schema `anim.reactions/1` Tools writes, granted on Orb's word). Apply after `ground-locomotion.patch`.

## What was there

Every blow drew the same two flinch poses (`react.flinch_f` for a front blow, `react.flinch_b` for a back one, `react.fold` on a heavy core hit) and an additive pose for the region (`react.head`, `core`, `arms`, `legs`) with a push and a damped wave up the spine, plus the ragdoll's own kick. A mash of lights and a heavy to the gut differed in size, not in kind.

## What the player sees

Each blow now picks a **variant** by three things the sim already says: its **weight** (the force: light under 0.5, medium to 1.0, heavy over), the **way it came** (front or back, and whether it lifts him, is level or drives him down: the draw's vertical part past 0.35) and the **body part** (head, core, arms, legs). It never picks the one the last blow picked, and the pick is a hash of the tick, the slot and the hit's number, so a replay draws the same. A variant is a set of bone turns shaped by an envelope (in over 0.05 s, held, out), a hips drop, a push along the blow and how much of the generic flinch it leaves (`base`). After it, the **recovery** for the blow's weight draws the body getting itself back: a nod and a shoulders-down settle after a light, a shake of the head after a medium, a hunch and a breath after a heavy. Guarded blows draw none (the guard hit has its own pose).

Eighteen variants, every combination of weight, body part, direction and draw having at least two to choose from (checked by a script over the data):

| Variant | Weight | Part | Way | Draw | Seconds | Bones |
| :--- | :--- | :--- | :--- | :--- | ---: | :--- |
| `jolt` | light | any | any | any | 0.32 | head, neck, spine_2 |
| `turn_away` | light/medium | head/core/arms | any | level/up | 0.38 | head, pelvis, spine_2 |
| `shrug` | light | arms/core | any | any | 0.36 | clavicle_l, clavicle_r, head, spine_1 |
| `step_back` | light/medium | legs/core | front | level/down | 0.42 | pelvis, shin_r, spine_1, thigh_r |
| `head_whip` | medium/heavy | head | any | level/up | 0.55 | head, neck, spine_1, spine_2 |
| `gut_fold` | medium | core | any | level/down | 0.50 | head, neck, spine_1, spine_2 |
| `arch_back` | medium/heavy | core/head | any | up/level | 0.52 | head, neck, spine_1, spine_2 |
| `stagger_side` | medium/heavy | any | any | level | 0.55 | pelvis, shin_l, spine_2, thigh_l, thigh_r |
| `knee_buckle` | medium/heavy | legs | any | any | 0.60 | shin_l, shin_r, spine_1, thigh_l, thigh_r |
| `spin_off` | heavy | any | any | level/up | 0.60 | head, pelvis, spine_1, spine_2, thigh_r |
| `double_over` | heavy | core | any | level/down | 0.66 | head, shin_l, shin_r, spine_1, spine_2, thigh_l, thigh_r |
| `arms_flung` | heavy | arms/core | any | any | 0.60 | head, spine_2 |
| `slump` | heavy | legs/core | any | down/level | 0.70 | head, shin_l, shin_r, spine_1, thigh_l, thigh_r |
| `duck_under` | light/medium | head | any | any | 0.42 | head, neck, spine_1, spine_2 |
| `hop_back` | light | legs | any | any | 0.40 | shin_l, shin_r, spine_1, thigh_l, thigh_r |
| `shoulder_spin` | medium | arms | any | any | 0.50 | clavicle_l, clavicle_r, head, pelvis, spine_2 |
| `drop_head` | medium/heavy | head | any | down | 0.55 | head, neck, spine_1, spine_2 |
| `stumble_fwd` | medium/heavy | any | any | any | 0.58 | shin_l, spine_1, spine_2, thigh_l, thigh_r |

Recoveries: `settle` (light), `shake_off` (medium, the head shaking 3.5 times a second), `catch_breath` (heavy, a hunch the shoulders and hips rise out of over 0.7 s).

Pitch turns are in the away-from-the-blow frame (a front blow's head goes back; a blow from behind mirrors it into the arch the other way); yaw and roll take a side from the blow's own draw. The amount scales with the force (0.6 to 1.2), the blow's amplitude and the fighter's wear. Under reduced motion it is 0.6. `RenderAnim.hit_variants`, `--no-hit-variants`. Nothing is written to the sim.

## Files

`render/anim/anim_fighter.gd` (`_pick_reaction`, `_apply_reaction_variant`, `_apply_reaction_recovery`, and the reaction layer's hooks), `render/anim/anim_data.gd` and `render_anim.gd` (the loader, the switch), `data/anim/reactions.json` (new key set), `tools/anim_check.gd` (`_test_reactions`), `tools/flurry_study.gd` (scenario `hv_set`: fourteen blows in turn; `window.__nohv = 1` is the before).

## Tests and gates

`_test_reactions`: 48 blows (three weights, four body parts, both ways, two draws) in one run for each fighter against the plain flinch: every blow picks a variant, none picks the last one's, every one differs from the plain flinch by 0.6 units or more in its first 0.6 s, twelve or more of the variants are used, light and heavy do not share their whole pool, the same hits pick the same variants on a replay, no NaN or limit. Gates on a scratch export of main with the lunge crouch and the two locomotion parks: `anim_check` with no arguments, the scans `--strict`, the 4-body scans, determinism plain and `--intro`.

## The schema request (Tools)

`data/anim/reactions.json`, schema `anim.reactions/1`, closed except `_` keys, all required: `light_max`, `medium_max` (numbers above 0, ascending), `attack` (0.05 to 0.3); `variants`: an array of `{id (string), weight, region, dir, vert (arrays of the allowed words: light, medium, heavy; head, core, arms, legs, any; front, back, any; up, level, down, any), dur (0.1 to 2), hold (0 to 1), base (0 to 1), dx, dy (numbers -3 to 3), hips (-10 to 10), bones (an object of rig bone names to arrays of three numbers -1.6 to 1.6), pose (optional, a pose id), pose_w (optional, 0 to 1)}`; `recover`: an array of `{id, weight (array), start (0 to 2), dur (0.2 to 2), hips (-10 to 10), bones (as above), shake (0 to 1)}`. Cross-references: every `pose` exists; every bone name is a rig bone.

## Not here

The stagger already reads (the launcher's opening, `lq.open`). A reaction that carries the body (the knock-back, the launch) is the ragdoll's and window 4's. Facial reactions and the cloth's follow-through are window 5's.
