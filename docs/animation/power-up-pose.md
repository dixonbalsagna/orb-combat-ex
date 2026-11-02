# Powering up on RT: the pose (Animation, 2026-11-01, paper)

A sketch for the EP, not built. It answers `docs/design/beam-answers-2.md` section 3 (RT stays the charge: "standing there powering up while the ground cracks is a moment I wouldn't give up") inside Legal's RL-239 (5): **upright or braced, hands low and relaxed or one fist; never arms wide (h02); never both hands at the hips; no crouch with clenched fists; no one stands screaming; at most two of the seven marks at any moment; the hold up to the first step in 17.5 s is a held pose and is read every tick.** VFX sketches the world's response; this is the body.

## The idea: the genre's best moment is the stillness, not the scream

The scene people remember is a body that stops moving while everything around it starts to. So the pose is a **stance that takes up ground and then barely moves**, and the pressure shows in small, slow things that are not light: the breath, a tremor that grows, a foot that digs, the chin that lowers, one hand that closes. A scream, wide arms and a crouching fist would each say "effort" in one frame; this says it over 17 seconds, and it reads every tick because no tick is a pose that Legal has refused. The world answers (VFX): the ground lifts under him with weight, the dust drifts *toward* him instead of away, a thin slow ring in lane colour. The body has to stay out of their way: it never needs its arms.

## One rule for all fighters

- **Stance:** upright torso, feet wide and planted (the pelvis never more than 14 units under the stand, so it is a brace, not a crouch), weight a little back at first.
- **Hands:** low and relaxed (the `relaxed` state) or **one** fist at the breastbone. Never both fists, never both hands within 10 of each other at the hip zone, never above the shoulder, nothing wider than the shoulders.
- **Head and face:** chin level to a little down, eyes on the foe, **mouth closed** (the face's calm state: Art's, to confirm), no shout.
- **The loop:** a 3.2 s breath (the chest and shoulders rise 1 unit and fall), a tremor that grows with the charge from 0.2 to 1.0 unit and never faster than 2 Hz, and four slow steps in the stance by the charge's fraction: the front foot digs, the hips sink 2 units a step, the chin lowers 3 degrees a step, the held hand tightens. Nothing moves in under 6 ticks (the snappy profile solves on twos), and no step is a pop.

## One sketch per attitude

Sketch coordinates are the wave format (pelvis-relative, x forward). The second row of each is the same body at the top of the charge.

**The Protagonist: resolve.** He is the one who has to hold the line, so he plants first and looks straight at the problem.

| Phase | Sketch |
| :--- | :--- |
| `set` (0 to 20 percent) | upright, lean 8, hips [0, -8, 0], spine lean 6, head pitch 4, right fist at the breastbone `hand_r [10, 54, 12]`, left hand low and relaxed beside the thigh `hand_l [4, 26, -14]`, feet wide `foot_r [-14, 2.5, 12]`, `foot_l [14, 2.5, -10]` |
| `top` (100 percent) | lean 12, hips [2, -14, 0], spine lean 10, head pitch 10, the fist tightened and drawn in `hand_r [12, 56, 12]`, the left hand lower and further from the body `hand_l [10, 30, -12]`, the front foot dug 3 units forward |

**The Anti-hero: cold.** He does not brace against it; he lets it come and keeps his weight back, a predator that has decided. He is the stillest of the two, and what moves is a shoulder and the head.

| Phase | Sketch |
| :--- | :--- |
| `set` | upright, lean 2, hips [-4, -3, 0], spine twist -6, head pitch 8 yaw 4 (chin down, eyes up at the foe), both hands low and loosely curled `hand_r [2, 32, 14]`, `hand_l [6, 30, -12]` (not open palms), a long stance with the weight on the rear leg `foot_r [-18, 2.5, 10]`, `foot_l [16, 2.5, -8]` |
| `top` | hips [-2, -8, 0], the weight eased forward, the head a little lower, **one** hand drawn up and closed at the breastbone `hand_r [10, 52, 12]` (one fist; the other stays low) |

**The other ten.** The layer takes one table by fighter id, so each fighter supplies an attitude word and a sketch. Three that cost nothing new, as slots (Narrative's words, not mine): *regal* (the chin level and high, the hands low and apart, the torso very upright, no clasp), *steady* (a wide stance, the torso square, the hands relaxed at the thighs: the pose is the stance), *wry* (the weight on one leg, one hand low, a half turn of the head). They have to pass the same rule; they cannot be arms folded high or hands together.

## What it costs and what it checks

- **A wave** (`pw`): per fighter, a `set` pose, a `top` pose and the layer mixes the two by the charge's fraction; two to three sketches a fighter. The breath and tremor are the layer's, not poses.
- **A layer:** `_power_layer`, beside the charge hold (`charge.hold`, a crouch with one fist: it stays for the other charges). It reads the charge fraction and the sim's tick, nothing else, and is render only.
- **The every-tick check, which is the real cost:** a test in `anim_check` that plays the whole 1,050-tick hold (and the first step) on the real solve and runs Legal's held tests on **every tick**: the pair test (both hands within 10 and in the hip zone), the arms-wide test (h02), the emitter test, nothing above the shoulder, the pelvis no more than 14 under the stand, and no pop (no tick changing the pose by more than 0.6 of a step). The existing held lint only reads authored poses; this one reads the mix.
- **Legal's stills:** four a fighter (`set`, the middle, `top`, and a breath extreme) before it goes live.
- **Size:** one session, after Art confirms a calm face and Legal has the sketches.

## What I need decided

1. The attitude word for each of the ten other fighters (Narrative through the EP).
2. Whether the Anti-hero's one raised closed hand at the top is a fist Legal accepts: RL-239 says one fist, and RL-218 says no open palm for him. It is consistent, but it is the line I would show Legal first.
3. A calm, closed-mouth face state (Art).
