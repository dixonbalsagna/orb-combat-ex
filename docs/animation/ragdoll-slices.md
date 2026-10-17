# The ragdoll slices and the su_hammer hunt (2026-10-17)

Owner: Animation. Brief: the EP's six hours (the su_hammer hunt, RG0, RG1, RG3 behind its own switch, RG2 behind the brake flag). Plan: `docs/animation/ragdoll-physics-paper.md`. Render side only: no sim file, no sim hash. Six parked patches on top of the eight (`docs/animation/pending/`, README order). **No capture was made** (the machine's quiet window): the frames for Orb are one command each, below.

## 1. The su_hammer hunt: found

**The coupling is the join smoothing's global jump test.** `_inertialise` turns a join in the solved pose into a smooth settling: when any bone's rotation changes by more than a threshold between two ticks, it starts an offset on **every bone and the hips** that decays over about a tenth of a second. The test looked at every bone, the free arm included. At the contact-to-follow step of `ru.su_hammer` the free arm's hand moves from its contact key to the follow key. With the free hand's contact target at x 22 the arm's change was under the threshold and the whole-body join started 4 ticks after the blow (the follow key's own jump); at x 23 it was over, and the join started 2 ticks after. A join that starts earlier carries the hips on from where they were drawn, and the blow's fall is delayed by about two ticks: the striking hand was 3.6 units higher at tick 6 (76.9 against 73.3, Legal's h05 limit 76).

How I found it: the scene played with the target at 22 and at 23 (and, because the effect depended on the pose pair, at (23, 58) against (22, 58)), every bone's pose dumped for 114 ticks, diffed. The first bones that differ besides the free arm (and the striking arm's own 0.13 degrees of arithmetic) were the hips at tick 66, with `press`, `ticks_to_contact`, the contact weight and the step all equal, and `_ip_active` true two ticks earlier in the run that failed.

**The fix** (`hammer-join.patch`, `anim_fighter.gd`): while a one-hand blow plays, the free arm's shoulder, upper arm and forearm are left out of the jump test (`_blow_free_side()`). The free arm is the slew's business (the seventh patch's rate limit); it still takes the join's offset when another bone starts one. With the fix, the hand-set row for the hammer is gone: `ru.su_hammer` takes its fitted free hand (36.2, 53.2, -9.4; 14.0 from the guard) and h05 reads 73.3. No other piece moved: the whole windups test, anim_check, and every scan passed.

## 2. RG0: a varied flail, and fold or arch (`ragdoll-variety.patch`, `RenderAnim.rd_variety`, on)

- **The flail is the launch's own.** Each flight's phase, and each joint's frequency, amplitude and phase shift, come from an integer hash of (slot, launch number, the render's count of that body's flights): `AnimRagdoll.hash01`, no random draw, no float in the mix. The same launch flails the same way in every replay; another launch by 0.19 radians at the largest joint after 40 ticks in the unit test, another fighter likewise. Data: `ragdoll.json` `variety` (hz 0.18, phase 0.6, amp 0.2).
- **The side that hit picks fold or arch.** `crumple` takes a side from the event's normal (the ground's slope, or `nx, ny` once World sends them) and the body's turn: a chest to the surface folds as before, a back arches (a per-joint `arch` multiplier in `ragdoll.json`: head and spine -0.8, arms +0.5, legs -0.5), a head or foot first stays the plain fold. Test: a body turned chest-down reads +1, back-down -1, upright 1.0; the spine and the head go opposite ways for the two.

## 3. RG1: mass, tier and the limb lag chain (`ragdoll-weight.patch`, `RenderAnim.rd_weight`, on)

- **Gain** = tier gain over mass: every impulse (crumple, kick, hit) and the flail is scaled by `tier_gain` of the opponent's power tier (1.0, 1.25, 1.5, 1.8 at tiers 1 to 4, blended between) and divided by the body's mass (`ragdoll_motion.json` `weight`: Protagonist 1.0, the rival 1.1, the dummy 1.3, **placeholders** until Game Design gives the fighters a mass). Test: 1.00 at tier 1, 1.80 at tier 4, 0.77 for a body 1.3 times heavier.
- **A blow travels down the body:** each degree of freedom has a lag in ticks (`ragdoll.json` `lag`: head 0, trunk 2, arms 4 to 5, legs 5 to 6) and its impulse waits that long. Test: after a crumple the head moves at once, the spine by 2 ticks, the shin not before 6 and by 7 it does. Off, every joint takes the blow at once, as before.
- The tier is read from the opponent (`Fighter.tier`), so no sim change. A `launch` event's own `tier` would be better when Simulation adds it (the paper's ask).

## 4. RG3: six degrees of freedom out of the plane (`ragdoll-oop.patch`, `RenderAnim.rd_oop`, **off**)

The ragdoll had twelve joints, all about the local z axis. Six more, flagged `oop` in `ragdoll.json`: **spine twist, spine side bend, head roll, each upper arm's twist, pelvis twist.** Each has its own springs, limits (spine twist 0.6 rad, side bend 0.45, head roll 0.5, arm twists 1.1, pelvis 0.5), a lag, a flail amplitude and a hit-table row. They run only with the switch on (`--rd-oop`, or `window.__oop = 1` in the study): `AnimRagdoll.n_on` is 12 or 18, and reduced motion keeps it at 12. A broken arm's twist hangs with it. **Off by default: Orb sees the before and after first.**

- **Joint limits:** every turn goes through the same cut-to-the-limit machinery (the ball joints' swing and twist limits), the six at their extremes on the guard stance leave 0 joints past a limit, and a joint scan of the whole data with the switch on, `lead_scan` and `joint_scan` at four bodies on it: all pass.
- **A new check against a stuck rag:** a twist sitting at its limit for 6 ticks or more fails (`_test_ragdoll_oop`). Live, over two seeded matches of 7,200 fighter-frames with the switch on, no joint reached the screen past a limit and the peaks, after the first tuning, were: spine twist 0.28 of 0.6, side bend 0.31 of 0.45, head roll 0.28 of 0.5, the arms 0.74 and 0.67 of 1.1, the pelvis 0.39 of 0.5. (The first values saturated the limits: the hit table and the flail were halved.)
- **The frames for Orb** (rule: before and after, nothing committed, this PC only):

  ```
  node tools/machine/capture.mjs frames --dir <web build of the study> --out <dir> --count 100 --step-js "window.__adv = {n}" --tick-js "window.__tick" --init-js "window.__cap=1;window.__only='rd_launch'" ... --session animation
  node tools/machine/capture.mjs frames ... --init-js "window.__cap=1;window.__only='rd_launch';window.__oop=1" ...
  ```
  The scenario `rd_launch` is a heavy blow at tick 6 and 84 ticks of flight; `rd_brake` below. The study is built as before (`build_web*.sh`: flurry_study.tscn as the main scene). Rendering the GIFs waits for the EP's word.

## 5. RG2: the mid-air skid (`air-brake.patch`, `RenderAnim.air_brake`, on, inert without an event)

- **The sim's brake is an event.** `air_brake` (the fields it uses: `actor`, `text` start or end, `kind` the reason, `amount` the speed at the start). There is none in the sim yet, so nothing plays until Simulation sends one; the scan and the study send it themselves. A `data/anim/brake.json` gives the lean (18 to 45 degrees against the velocity), the reference deceleration (3,000 u/s2 for full strength, never under 0.35), the ramps (4 ticks in, 8 out), the lead's rate and the ragdoll's whip (2 times).
- **Three shared poses** in a new wave `brake1` (`ab.skid.enter`, `ab.skid.hold`, `ab.skid.exit`): the spin taken out with the arms wide; the brace, torso leaned back, knees bent, feet reaching toward the travel, forearms up and forward; the arms drawing in. They are mixed in at the weight of the deceleration he actually shows, before the flight lead.
- **The flight lead turns the body to the lean instead of head first** while the brake is on (blended by the skid's weight, with a faster rate), and its "long way round through head first" rule is off for these frames. The ragdoll's flail is damped and its acceleration drive doubled, so limbs stream forward as he slows.
- **`lead_scan` exemption keyed to the brake state:** a frame where `AnimFighter.braking()` is true is counted apart (`braking in the air (exempt)`), never as "feet leading and not a tumble". Live today it is 0 (no event yet), 144 tumbles allowed, 0 bad, as before.
- **Test (`_test_air_brake`):** a Protagonist launched at 1,600 u/s: coasting he is laid out 84 degrees from upright (head first); with the event at tick 30 he is braced at 39 degrees by tick 50 against his velocity, the weight reaches 1.0, no NaN, no joint past a limit; the event's end lets him go within the ramp; without the event none of it happens. The new poses pass the joint audit (`brake1` 30 checked, 0 bad).
- **Frames:** the study scenario `rd_brake` (launched at 1,500 u/s, the brake from tick 30 to 60); `--no-air-brake` is the before.

## 6. Gates (below-normal priority, at most 3 Godot processes)

On the final tree: `anim_check` seed 4, 2,400 ticks (passed, with `_test_guard`, `_test_ragdoll_vary`, `_test_ragdoll_weight`, `_test_ragdoll_oop`, `_test_air_brake`); `joint_scan --strict` (all waves, 0 bad), `lead_scan --strict`, `held_scan --strict` (0 fail), `guard_scan --strict` (0 of 149), `determinism` plain and `--intro` (passed), `lead_scan` and `joint_scan` at four bodies (0, 48,000 live frames none past a limit); and again `joint_scan`, `joint_scan --bodies=4 --only=live` and `lead_scan --bodies=4` with `--rd-oop` on (all 0). The study's two new scenarios run clean in `--measure` (0 on screen, 0 NaN).

## 7. What is next, and who gives what

- **Simulation:** the `air_brake` event with the fields above, and `launch.tier`. **World:** `interior_contact` and `interior_end` (the paper's section 5); the ground events already accept `nx, ny`, so a ceiling bounce needs only the event's normal for the arch. **Game Design:** the masses, the chain's values.
- **RG4 (the chain) and RG5 (the hit-stop release)** wait for those events; RG4's poses (`ce.slam`, `ce.rebound`, `lg.climb`) can be made before World has them.
- **Orb:** the before and after of RG3 (and RG2's skid) before the out-of-plane switch goes on.
