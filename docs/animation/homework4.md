# Homework 4 for Animation: the arms that bend wrong, the styles, the tech's legs, three poses (Animation, 2026-10-16; parked)

Owner: Animation. Brief (the EP, quoting Orb's marks in `docs/ep/vision.md`, "Orb answers homework 4"): (1) the three styles on each button are "not distinct enough yet" and "arms still seem to bend in weird, unnatural ways": find the frames, fix them, then push the styles apart; (2) each fighter moving his own way: keep it; (3) `cue-tech.gif`: "his legs fold up and look strange"; then my three first-value poses (the sole fall, the cast charge, the opening's forward arm) and the rename of `rival10`. **Built and gated in scratch, parked as a fifth patch (`docs/animation/pending/homework4.patch`, README there); nothing in the tree.** It applies after the four before it (`git apply --check` clean on 4cdc8df6 with them). Render side only: no sim file, no hash.

## 1. The arms: what bent wrong, and where

**Method.** `joint_scan --strict` says 0, because the joint limits are loose (the upper arm may twist 100 degrees, and the elbow's bend plane is whatever the twist allows). So I measured the shape instead: for each arm of each frame, the shoulder, elbow and wrist in the body's frame (a probe in the scratch copy: `_arm_sample`, `_pose_scan`; the scenes are the nine cells of the flurry study, both fighters, tap, mash and hold of X, Y and B), and looked at the frames it flagged in the clips Orb watched (`art/animation/review/nine-cells-look/`).

**What it found: the chicken wing.** An elbow carried above and behind its shoulder (more than 2 units up, 4 back) with the forearm hanging down from it (more than 8 below the elbow) and the arm bent past 50 degrees. In the clips it is the **free arm of a light's contact**: at the instant of a cross, a jab or a spear hand the rear arm's forearm points straight up behind the head like an antenna (the sheet `arms-x-tap-wing-before-after.png`, rows one and three before, two and four after). The cause is in the pose bake, not the layers: the key poses author the free hand in the body's frame (a hand at the ribs, "folded across"), while the strike's lean and lunge carry the shoulder 20 units forward of where that hand is, so the hand ends up **behind its own shoulder**, and the only bend that reaches it is elbow up and back. The bake already slides such a hand forward (data `retarget_units`), but only when the twist it needs is past the comfort limit, and this bend sits inside it.

**The fix** (`AnimPose._is_wing`, data `joints.json` `wing`): in the **contact and follow keys of strikes** (not the chambers, where a cocked elbow is meant, and not a dash's swept-back arms) the bake treats a wing as uncomfortable too and slides the hand forward to the nearest place a natural bend reaches, taking a margin of 4 units beyond the first legal place so the layers over the pose do not carry the upper arm back past its limit. `retarget_units` goes 12 to 24 (the slide is only used where a wing or a twist asks for it). One pose is skipped by name (`ru.su_heel.follow`: the slid hand there pulled the heel kick's own leg 70 degrees through the limit pass in the `fix30` test, which that piece must pass).

| | Before | After |
| :--- | ---: | ---: |
| Chicken-wing arms in the 316 strike contact and follow keys | 57 | **5** |
| Chicken-wing arm-frames in the nine cells, both fighters (4,440) | 163 | **68** |

The 68 are the transitions (a blend from a guard to a key passes through a wing for a frame or two: the cross's first contact frame) and the arms of the heavies' follows. **What it did not fix, honestly:** the last pass of the joint limits still pulls a joint more than 30 degrees on 38 frames across 106 pieces (33 before; the same kind, a few frames each, mostly the free arm's twist in a held contact key and a heavy's leg). They are corrected before they are drawn, so they read as a brief twist rather than a wrong bend; I did not chase them and they are a list for the next pass (`_fix_scan` in the probe).

New assert (`_test_arms`): 8 or fewer wing arms in the strike keys, and the beat below.

## 2. The three styles pushed apart (data; `press_styles.json`)

The measure of "distinct" is Orb's eye, so the clips are the evidence (section 6). What I changed, all in data and one key:

| Cell | Before | Now |
| :--- | :--- | :--- |
| **X mashed** | a forward lean of 2 degrees a blow to 10 | **3.5 a blow to 18**, and **a beat**: the pelvis dips 1.8 units on each blow of a run and rises between (`press_run.bob`, new) |
| **Y mashed** | lean 3 a blow to 14; the shoulders turn 0.06 | **lean 4.5 a blow to 22**, a beat of 2.6 units, **the shoulders roll 0.18** (the medium's windmill turns the whole trunk) |
| **B mashed** | the march: 5 units a heavy, a dip of 0.3 over 5 ticks | **9 units, a dip of 0.55 over 6 ticks**: a stomping advance |
| X tapped, X held, Y tapped, B tapped, B held | unchanged | unchanged: a tap has no beat and no lean (asserted), a held X digs in, a held B coils |

Measured in the study scenes (the free stance of the tier scenes: the live brawl's crouch lowers every number by a few degrees), before then after: an X mash leans 14.9 then 16.5 degrees on average and drops its pelvis to 30.6 then 28.8 units, against a tap's 7.5 and 32.8; a Y mash leans 5.7 then 6.6. **Those are modest numbers**, and I'll say so: the tier scenes' own pieces dominate the mean lean. The change that reads is the rhythm (the dip on each blow) and the larger run lean; whether it is enough is for Orb's eyes on the clips. **Where the styles still blur and what it would take:** a held Y is a tap's twin in the live brawl (the sim has no Y hold yet: Encounter's charged medium, parked), and a tapped B differs from a mashed B only by the march. Those two need the sim's side before the body can draw them.

## 3. The tech's legs

`rt.air_tech` ended in a tuck: both feet drawn up to 32 units under a crouched pelvis, which reads as the legs folded in on themselves. Now: **spread** (the chest to the chaser, the arms flung apart as one up and forward and one up and back, the legs scissored with one foot forward and one trailing, neither lifted past 14) then **brace** (upright, the knees only a little bent, the feet gathered under him, the arms coming in to guard). No foot above 20 in either pose (asserted). The sheet `tech-legs-before-after.png` and the clip `tech-before-after.gif`.

## 4. The three first-value poses

| Pose | Was | Now |
| :--- | :--- | :--- |
| The guards' falling sole (`gd.su_sole_fall`) | a high front stomp | a higher chamber (the foot at 76, the knee at the hip, the body leaning back 14 degrees) and a drop onto the chest from there, so the foot visibly comes down |
| The cast charge (`bm.hold.charge_*`) | the arm held out | **the firing arm drawn back** (the hand at the shoulder, the elbow back and out) **and the other hand held out toward the rival as the aim**, shoulder height, open for the Protagonist, open for the Anti-hero's rear hand; the fire pose is unchanged |
| The opening's forward arm (`lq.open.snap`, `open`) | reached level at the rival | the forward arm up at about 45 degrees (the hand at 80) and the back arm up and back: a flung recoil, not a reach |

Sheets: `poses-sole-fall-before-after.png`, `poses-beam-cast-before-after.png`, `poses-opening-before-after.png` (before above, after below). `reach.json`: `gd.su_sole_fall` 32 to 31.

## 5. Each fighter his own way (Orb: yes, keep it)

Nothing in the per-fighter `ease` rows or the `fighters.json` profiles changed. The clips for the two fighters are side by side for the same cell, so you can see that it still holds.

## 6. Clips and sheets for Orb (this PC only, uncommitted, `art/animation/review/homework4/`)

Before on the left, after on the right, one cell and one fighter each, at fight distance (3.7 to 7.6 MB): `x-tap-protagonist-arms-before-after.gif`, `x-tap-antihero-arms-before-after.gif` (the wing, at its worst), `x-mash-protagonist-`, `x-mash-antihero-`, `x-hold-protagonist-`, `y-mash-protagonist-`, `y-mash-antihero-`, `b-tap-protagonist-`, `b-mash-protagonist-`, `b-mash-antihero-before-after.gif`, and `tech-before-after.gif`. The sheets are the five PNGs named above (`arms-x-tap-wing-before-after.png` too). "Before" is the tree plus the four parked patches; "after" adds this one.

## 7. Gates

Scratch export of 4cdc8df6's tree (the render and data are unchanged from 0ca6f670) with the four patches and this one. `anim_check` passed (seed 4, 2400 ticks; `_test_arms` is new), `joint_scan --strict` 0 of 932 poses and 0 on screen, `lead_scan --strict` 0 feet first and not a tumble, `held_scan --strict` 217 held poses and 0 fail, determinism plain and `-- --intro --seeds=2 --ticks=900` passed, the flash count passed in 56 runs (the scratch copy's own `check-log.js`), and `lead_scan` and `joint_scan --strict --bodies=4` clean. The last batch of pose changes (section 4) was followed by `anim_check`, `joint_scan` and `held_scan` again; the rest ran before it, and a pose in a sequence no scan reads touches none of them. One failure on the way, fixed: the wing fix's first form pulled a heavy's leg through the limit pass in `fix30` (the skip above).

## 8. For others

- **Rename done:** the guards' wave is `guard1` again (Tools widened the wave pattern in the working tree, not yet committed): `rival10` files are removed by the patch.
- **Tools (schema):** `joints.json` `wing` (`fix`, `suffixes`, `skip`, `flex_deg`, `up`, `drop`, `back`, `margin`), `press_styles.json` `press_run.bob`, and what the last patches named (`named` in the manifest rows, `roles.<fighter>.beam`, the `cash_in` style).
- **Encounter and Combat:** nothing needed; the Y hold and a distinct B tap are the sim's (above).
