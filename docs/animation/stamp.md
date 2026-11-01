# The stamp: the Y-mashed stomp as a stamp (Animation, 2026-10-31)

Owner: Animation. Second round on Orb's note ("the y-mashed stomp still looks a little stilted"). Stacks on the stomp park (`stomp-posing.patch`, park 3) and so on the lead-in and follow-through parks. Render only: no sim state, no hash, no contact tick. Orb's A/B: today's main against this, a Y mashed, every blow the stomp, the input drawn at the frame edge (`art/animation/review/stamp/`, not committed).

## What I saw

Combat's look for the stomp (`strike.stomp`, a heavy ender that drives the foe down): "the knee drawn to his chest and the sole driven straight down; his arms spread for balance". The parked rework fixed the arms but kept the motion short: the foot dropped from 50 (chamber) to 38 (contact) while going 16 forward, which reads as a push-kick, though the tip data says `sole`, `drop`. The foot cannot come from far above the contact (the leg is 44 long, the defender's gut is 38 up, so a knee carried to the chest is as high as it gets); what makes a stamp a stamp is what comes after the contact and what the body does around it.

## The change (the poses of `w1.stomp` and `pr.stomp`, the follow-through rows)

| | Chamber | Contact | Follow |
| :--- | :--- | :--- | :--- |
| torso | leans back 14, the spine back 8 (was 8 and 4): the knee comes to the chest over a sunk standing leg (pelvis 8 down) | leans in 10 | leans in 12 |
| arms | spread for balance: the lead hand 18 ahead, 58 up, 19 out, the rear hand 4 behind, 60 up, 20 out the other way (both under Legal's 32) | lead hand swept down and out (28 ahead, 46 up), the rear hand thrown up and back (8 ahead, 64 up) | both brought forward (34 and 32 ahead), elbows bent |
| foot | knee at the chest, the foot at 52 | the sole on the gut, 34 ahead and 38 up | **the foot comes down to the floor in front of him (28 ahead, 6 up)**: the stamp lands; it was 22 up and in the air |
| weight | | pelvis sunk 5 and driven 12 | pelvis sinks 6 and drives 16 forward |

`follow_through.json` rows for both fighters: the drive 2.0 to 2.6 and the dip 1.8 to 3.2: after the contact the pelvis drops and carries on forward as the foot plants. The contact key's foot target and the contact tick are the key's own: where the foot lands on the defender did not move.

## What the checks say

`pose_lint` (the six poses): 0 issues. `anim_check`, `joint_scan --strict`, `lead_scan --strict` on the stack of the three parks and this: pass. Joint limits hold on every frame (the elbows' flexion stayed under 150; the free hands are at least ten units forward of their shoulders, which the shoulder's blind spot demands).

## The clips

`stomp-antihero-AB.gif` and `stomp-protagonist-AB.gif`: left today (main), right the stamp pass, the same ticks side by side; a Y pressed for two ticks every eight, drawn at the frame edge. The real solve, a real dummy, the blow forced to the stomp (every blow the same piece, so the mash shows only the stomp). The right side raises the knee higher with the torso leaning back and the arms out, the foot plants after the contact, and the body drops through it.

## Not here

The stamp is tuned to today's proportions (hand and foot targets are in today's rig's units; a finished model re-fits them with `retarget_suggest.gd`). Whether it reads as a stamp is Orb's call on the clips.
