# The contact-key pass: the free arm stays near the guard (2026-10-16)

Owner: Animation. Brief: the EP, "the contact-key pose pass (a free arm that stays near the guard), piece by piece, as an eighth patch". Render side only: no sim hash moves. Parked as `docs/animation/pending/guard-pass.patch`.

## What was wrong

The seventh patch fixed the free arm at run time: a rate limit on its slew, a wing drawn to the guard (`_free_arm_slew`). That is a bandage over the key poses. On the contact key of a strike, the hand that is not striking sat wherever the pose's author left it: in a falling hammer, dropped at the hip; in a ram, thrown back; in a side kick, out behind the body. The slew only kept the arm from snapping between keys. It did not stop the arm from being a long way from where a fighter keeps it.

## The measurement

`render/anim/tools/guard_scan.gd` (new, permanent, `--strict`) takes every strike's contact key (149 of them, both fighters, every wave) and measures, for the hand that is not striking (both hands in a kick), the distance to the nearer of the two guard hands of `stance.aggressive`. It measures **in the chest's own frame**: a torso turned 50 degrees into a blow carries its guard with it, and that is right; a hand left in space as the chest turns away from it is the fault.

Goals (data, set in the scan): **20 units for a hand blow, 30 for a kick**, where the other arm is also for balance.

| Distance from the guard (units) | Before | After |
| :--- | ---: | ---: |
| 10 or less | 39 | 41 |
| 10 to 20 | 74 | 99 |
| 20 to 30 | 28 | 9 (all kicks, within their 30) |
| 30 to 40 | 4 | 0 |
| over 40 | 4 | 0 |
| **Past the goal** | **28 of 149** | **0** |
| Worst | 43.4 (`pu.su_blade_jaw`) | 28.8 (a kick, goal 30) |

(The 28 past their goals before were 25 hand blows over 20 and 3 kicks over 30.)

## How it is made

- **Data:** `data/anim/guard_pass.json` (new): for each of the 28 contact keys past its goal, the free hand's new model-space target, and its distance from the guard before and after. The scan's `--fit` mode writes the rows: the hand moves toward the guard just far enough to land at 0.7 of the goal (so a pose has room), never all the way. A blow that strikes with a different hand keeps its own free-hand habit.
- **Applied at generation:** `render/anim/tools/wave_gen.mjs` reads the file and sets the hand when it builds a wave's contact pose (including the poses a fighter takes from wave 1 through his profile, and the follow-through that is blended from the contact). Nothing is read at run time, so the pass costs nothing and cannot differ between builds.
- **Nine waves regenerated, poses only:** `wave1`, `protag1`, `protag7`, `protag10`, `protag11`, `protag12`, `rival4`, `rival7`, `rival8`. The manifests are not touched (Combat's parked strike data has moved on since they were made, and a regenerated manifest would carry that drift).
- **Four re-aimed targets removed:** `data/anim/targets.json` and `target_poles.json` replace the authored hand of a few poses after the joint limits (`joint-limits.md`). Three of them (`w1.hammer`, `w1.spear_hand`, `w1.sweep`) held the old free hand and overrode the new one. Their entries are gone; the bake's own final pass keeps the new targets inside the limits, and the joint audit confirms it (0 bad of 990 poses).
- **Test:** `_test_guard` in `anim_check` fails if any contact key is past its goal and if a row of the pass names a pose that is not baked.

## The pieces, one by one

All 28, worst first (distance from the guard in the chest's frame, units; `l` and `r` the free hand):

| Piece | Free hand | Before | After | New target |
| :--- | :--- | ---: | ---: | :--- |
| `pu.su_blade_jaw` | l | 43.4 | 14.0 | 38.2, 50.3, -13.2 |
| `ru.su_ram` | l | 42.1 | 14.0 | 49.3, 34.6, -11.8 |
| `pv.su_palm_arm` | l | 41.7 | 14.0 | 36.0, 49.7, -13.7 |
| `pu.su_drive` | l | 40.7 | 14.0 | 43.5, 35.0, -10.0 |
| `pv.su_blade_fall` | l | 35.7 | 14.0 | 39.8, 38.2, -13.2 |
| `w1.sweep` (kick) | r | 34.3 | 21.0 | 15.0, 36.3, 17.0 |
| `w1.side_kick` (kick) | l | 32.9 | 14.5 | -16.9, 55.0, -1.3 |
| `pr.side_kick` (kick) | l | 31.6 | 14.2 | -17.8, 56.6, -2.0 |
| `pu.su_turn` | l | 29.4 | 14.0 | 27.8, 54.3, -12.8 |
| `pr.hammer` | l | 28.1 | 13.5 | 28.3, 52.5, -10.1 |
| `rm.heel_backhand` | l | 26.2 | 11.8 | 20.6, 60.1, 2.2 |
| `ru.su_plate_arm` | l | 24.9 | 10.4 | 31.3, 52.6, -9.5 |
| `rk.bolt_flick` | l | 24.5 | 12.3 | 11.2, 46.9, -9.9 |
| `rk.blast_gut` | l | 24.0 | 13.1 | 23.1, 56.1, -9.4 |
| `ru.su_hammer` | l | 23.6 | 10.7 | 22.0, 53.0, -8.0 (hand-set, below) |
| `pm.palm_rise` | l | 23.5 | 12.4 | 20.6, 51.1, -8.7 |
| `w1.spear_hand` | l | 23.5 | 11.8 | 23.8, 48.7, -8.7 |
| `pr.jab` | l | 22.7 | 11.1 | 27.7, 58.2, -9.1 |
| `w1.hammer` | l | 22.6 | 11.3 | 29.4, 53.5, -9.8 |
| `pu.su_hammer_arm` | l | 21.7 | 12.4 | 26.6, 54.1, -9.2 |
| `pv.palm_turn` | l | 21.5 | 11.9 | 28.8, 59.2, -5.5 |
| `ru.su_fist_heave` | l | 21.5 | 14.0 | 28.8, 54.4, -9.2 |
| `pr.backfist` | l | 21.2 | 13.0 | 23.2, 60.9, -0.9 |
| `pk.blast_gut` | l | 20.7 | 13.8 | 21.9, 56.9, -8.9 |
| `rk.blast_chest` | l | 20.3 | 11.2 | 19.9, 59.0, -9.1 |
| `pk.blast_chest` | l | 20.1 | 12.8 | 18.4, 59.3, -8.4 |
| `rm.fist_rise` | l | 20.1 | 12.6 | 24.8, 55.4, -10.0 |
| `w1.overhand` | l | 20.0 | 12.9 | 28.0, 54.0, -10.0 |

Of the 28, five were far (over 35): the Protagonist's and the Anti-hero's super-heavy tier (the blade to the jaw, the ram, the stepping palm, the drive, the falling blade). Their free hand was thrown back or left low for the look of the wind-up and was still there at the contact.

**One piece needed a hand-set row.** `ru.su_hammer` moved its free hand forward to the guard, and the hammer's own striking hand then fell a tick later: Legal's h05 check (a hand at 76 or lower six ticks after a super-heavy's contact) read 76.9. The coupling is real and I did not find its cause in the time (the striking hand's trace at 6 ticks is 73.3 with the free hand at the guard's x of 22 and 76.9 with it at 23 or more, the same for any forward value, so it is a step and not a slope). The row keeps the hand at x 22 and lowers it to 53: 10.7 from the guard, h05 at 73.3. It is noted in the pass's file. A cause would be worth finding; it may be a second free-arm effect on the striking arm's timing.

## Gates

On the final tree: `anim_check` seeds 4, 2,400 ticks (passed, with `_test_guard`), `joint_scan --strict` (0 bad of 990 poses and of 126 sequences), `lead_scan --strict` (0), `held_scan --strict` (0 fail), `guard_scan --strict` (0 of 149 past their goal), `determinism` plain and `--intro` (passed), `lead_scan` and `joint_scan` at four bodies (0; 48,000 live fighter-frames, none past a limit). The bend scan of the nine cells improved a little without being aimed at: wings 45 to 40, upper-arm jerks 139 to 131, elbow flips 57 to 50. The flash count passed (56 runs, under the cap).

## What this is not

- **Not the chamber and follow keys.** The follow-through of a hand blow is blended from its contact, so it follows the pass for free (the derived ones); the chambers are untouched. If Orb wants the whole stroke, it is the same scan run on the other two roles.
- **Not a rule.** A free hand at the guard is the default. A piece whose free hand is the point (a dive, a spin, a held hammer's lead hand in guard before the fall) can keep its own: add it to the scan's exceptions with a reason.
- **Not the clips of every piece.** Four clips in `art/animation/review/homework4b/` (`guard-pass-super-heavies-*` and `guard-pass-jab-hammer-backfist-kick-*`, each fighter, before and after, 12 to 14 MB) show eight of the pieces. The change is modest on screen: the seventh patch's run-time slew had already drawn most free arms in toward the guard in live play, so the pass is the same fix made where it belongs, in the key poses. The scan's numbers are the clearer measure (worst 43.4 to 14.0 on the super-heavy tier).
