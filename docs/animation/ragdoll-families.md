# Ragdoll: out-of-plane on, flail families, weight you can see, the skid's judder (Animation, 2026-10-25)

Owner: Animation. Orb's ragdoll answers of 2026-10-25 (docs/ep/vision.md): the out-of-plane joints, turn them on; the air skid "close, but..."; each launch flailing its own way, "can't tell"; weight, "no difference I can see"; the skid's lean about right; judge it in play, "more variety is better, follow rule of cool". Parked as `docs/animation/pending/ragdoll-families.patch` (render side plus data), after `pop-juggle.patch`.

## What was wrong (measured, not guessed)

- The flail was almost invisible. A loose joint is a spring with a natural rate near 0.55 Hz, and the flail's target swung at 2 to 3.4 Hz: the joint followed it at about a twentieth of the amplitude (the arm's 0.7 rad target drew about 0.03 rad). So no launch looked like anything.
- The per-launch variety was a hash that moved each rate by 18% and each amplitude by 20%: the same flail with slightly different numbers.
- The weight was a gain of 1.0 to 1.8 by tier on top of that invisible flail.

## What changed

| Piece | Change |
| :--- | :--- |
| **Out-of-plane joints** | `RenderAnim.rd_oop` is on by default (`--no-rd-oop` is the before). The six joints (spine twist and side bend, head roll, each upper arm's twist, the pelvis's twist) turn the body about its long axis in a flail and a hit. Reduced motion keeps the body in its plane, as before |
| **The flail now swings what the data says** | the target is made bigger by exactly what the spring will take away at that rate (`variety.comp` in ragdoll.json: strength 0.85, at most 4 times; the out-of-plane joints at most 1.6 times, so a twist does not sit at its limit) |
| **Six flail families** | `variety.families` in ragdoll.json, one picked per launch by a hash of the slot, the launch number and his flights (replay-safe): **rag** (slow, limp, long), **windmill** (the arms big and the left against the right), **starfish** (small movement about arms and legs held open), **frantic** (fast, big, random phases, short), **whip** (the spine and head, the arms trailing), **cartwheel** (the arms and legs together, wide and long). Each is a multiplier on each joint group's amplitude and rate, a phase pattern, a resting bias and a duration |
| **Weight you can see** | the flail scales with the launch's own power (the speed he is sent at, `weight.launch` in ragdoll_motion.json): a light pop flails at 0.55 of the amplitude and 0.75 of the duration, a full send at 1.6 and 1.4. The tier gain rises from 1, 1.25, 1.5, 1.8 to 1, 1.3, 1.8, 2.5 |
| **The air skid** | `brake.json`: the limbs and cloth stream 3.2 times (was 2.0) while braking, the skid's least weight is 0.5 (was 0.35), and the arms and head judder at 9 Hz by the skid's weight (`judder` 0.1 rad): friction made visible. The lean stays (Orb: about right). The catch after the skid is the air recovery's (window 4) |

## What is measured

`_test_ragdoll_families`: all six families come up in 80 launches; no two are within 0.25 rad rms of each other in every joint (the closest pair 0.30, whole trajectories over the flail); a full send moves 9.5 rad a second summed over the joint groups against 3.7 for a light pop (2.6 times) and lasts 1.23 against 0.69 of the flail's scale (1.8 times). The oop test now reads the switch as on and keeps its limits (no joint at its limit for more than 6 ticks, none past a limit at the extremes). `anim_check`, the scans `--strict` and both determinism runs: see the report.

## In play

Two real-play captures through the flash hook (Windows web build, `launchai` and `mashdummy`, the same sim before and after): `docs/animation/img/ragdoll-launch-before-after.gif` (the Rival knocked back by a signature beam, before on the left, after on the right). Honest read: at the game's camera distance the difference is real but small in this scene (the beam knock-back holds the body in its own pose for most of the flight); the flail families show clearly in the study scene, `docs/animation/img/ragdoll-flail-families.gif` (six launch numbers, the Protagonist, in place). Orb's note stands, "they would look better if I saw them in game": the next step is Orb playing a build, and tuning from what Orb sees.

## The schema request (Tools)

Closed schemas already exist for all three files; each needs its new keys (Orb's word grants them):
- `anim-ragdoll.schema.json` (`data/anim/ragdoll.json`): `variety` gains `comp` `{strength (0 to 1), max (1 to 10)}` and `families`, an array of `{name (string), amp, hz (each an object of head, spine, arm, leg, oop, numbers 0 to 4), anti (optional, object of arm and leg, 0 or 1), bias (optional, an object of dof ids from `dofs` to a number -3 to 3), phase (optional, 0 to 3), dur (0.3 to 3)}`.
- `anim-ragdoll-motion.schema.json` (`data/anim/ragdoll_motion.json`): `weight` gains `launch` `{ref_speed (above 0), speed [two numbers], amp [two numbers], dur [two numbers]}`.
- `anim-brake.schema.json` (`data/anim/brake.json`): `judder` (0 to 0.5) and `judder_hz` (1 to 30).
