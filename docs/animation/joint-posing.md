# Joint posing through the moves: the stomp, and what the measures say (Animation, 2026-10-30)

Owner: Animation. Orb: "the y-mashed stomp still looks a little stilted, more work is needed all around on joint posing during the moves"; standing note: no unnatural arm or knee bends. The EP's order: the Y-mashed stomp first, as Orb's named example, then the worst others by a measure named here.

## The stomp

The key poses of `w1.stomp` (the Anti-hero) and `pr.stomp` (the Protagonist) were the same sketch: both hands pinned at the same place, mirrored across the body at head height (`[8, 65, +22]` and `[8, 65, -22]`), the same on the chamber and the contact, so in a side view the two forearms stood vertical in front of the face and stayed there for the eight ticks of the blow, over a front-kick leg held horizontal and a torso that stood upright through it. It read as a pose held, not a stomp thrown.

Reworked (the poses in `data/anim/waves/wave1.poses.json` and `protag1.poses.json`; the `targets.json` re-aim of `w1.stomp.follow` that overrode the follow's hand is removed):

| | Chamber | Contact | Follow |
| :--- | :--- | :--- | :--- |
| torso | leans back 8, the spine turned back 10 | leans in 10, the spine turned in 6, the head pitched into it | leans 9, settling |
| pelvis | sinks 4 | sinks 5 and drives 12 forward | sinks 4, 8 forward |
| lead arm | forward and low, the fist at 22 ahead and 52 up | 26 ahead, 50 up | folding back to 20 and 53 |
| rear arm | drawn back, 2 ahead and 57 up | 2 ahead, 58 up, back against the leg | 10 ahead |
| elbows | poles given (down and back) so the elbow plane cannot swap | the same | the same |

The foot, the knee's height and the contact are the key's own: where the foot lands did not move. The blow's own lead-in row is re-tuned on the new poses (a mashed Y's stomp: pelvis step on the contact tick 4.1 against 13.5, free upper arm 37 and 25 degrees against 111).

What the measures say: **nothing, because the stomp was already clean on them.** The old stomp had no pulled frames and no arm swing over 30 degrees a tick. The elbows were folded between 122 and 145 degrees through the whole blow (arms shut, as in the strip) and now move between 104 and 160; the hands, which were 3 to 6 units apart at the contact in a side view, are 11 to 13 apart. The change is a look, and the look is Orb's to judge from `img/follow-through/stomp-*.gif`.

## The measure for the rest, and what it found

The measure: **frames of the final limit pass that corrected over 3 degrees** (the pose asking a joint for what it can't do: the margin `joint_scan` checks, counted per tick in the 35 ticks around a contact), and **arm swings over 70 degrees a tick off the blows' own contact ticks** (the direction of the upper arm and forearm, not the twist). Over the 75 samples, on the stack with the lead-in and the follow-through, 23 samples had any. The worst, in order: `body_hook` (7 frames, to 5 degrees), `roundhouse` (8, to 6), `cross_arm_ram` (6, one at 15 degrees three ticks before the contact), `drop_kick` of both fighters (5 and 5, to 12 and 8), `su_plate` (5), `spinning_heel` (2, and a pull of 18 degrees fourteen ticks after the contact).

**What did not improve.** I tried one edit to each of the first three families (the roundhouse's chamber foot 6 units nearer the body and its contact foot 4 lower, the drop kick's lean 70 to 62 with the feet 3 to 5 lower, the Protagonist's heel kick 4 lower) and read the same measure: the roundhouse went from 10 pulled frames to 9, the drop kicks from 6 and 5 to 7 and 7 (worse), the heel unchanged. Reverted. The pulls are in the blends between the keys, not in the keys, so a pass that moves the keys blind does not improve the measure. This is the honest result of the pass: the joint-limit margin on these blows was already small (the worst corrected frame in the whole set is 18 degrees, the median 4), and the visible faults that remained were the pops, which the lead-in and the follow-through address.

## Rig-neutral

Everything here is bone data and weights: poses as sketches (the hips, lean and spine in degrees, the limbs as effector targets with elbow and knee poles), and lists of weights. The hand and foot targets and the poles are in today's rig's units (a hand 22 ahead and 52 up is today's arm length); on a finished model with other proportions they are re-fitted by the retarget (`retarget_suggest.gd`), which is the existing path. Flagged as tuned to today's proportions: the stomp's targets above, and every row's values in `lead_in.json` and `follow_through.json` (the lists are rig-neutral, the picks are not).
