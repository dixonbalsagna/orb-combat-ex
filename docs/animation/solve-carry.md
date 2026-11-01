# The solve's carry and the striking arm's release (Animation, 2026-10-30)

Owner: Animation. The EP's brief (Orb: "follow-through matters"): a real forward carry, changing the contact solve so the body's weight moves through the blow after the contact without breaking hand contact or the approved snap; the striking arm's release pop (`su_hook`, `su_plate`, `su_hammer`); a switch; listed blows only; how many gain and what it costs; and whether a blend change could help the pulled frames. Render only: no sim state, no contact tick and no hash moves. Park 4, on `follow-through.md`.

## A correction to the follow-through account

`follow-through.md` said the forward drive "barely shows" (0.0 to 0.5 units, median). That measured the pelvis against its own contact pose, and the follow key's hips fall back faster than the drive rises, so any drive was masked. Measured against the **same blow with no drive** (the row's `drive` zeroed), the old route (the drive added to `_pr_dx`, which the contact solve counts) carried a median of 1.4 units across the 75 samples where the row asks for 1.5 to 3.5: it showed, but the solve took part of it back, through its lunge and its step (30 of the 50 key sets gain half a unit or more by the change below).

## The change

Two parts, one switch (`RenderAnim.carry_solve`; `--no-carry-solve` is the before), the data in `data/anim/follow_through.json`.

1. **The carry goes through the solve, not into its target.** A listed blow's `drive` is `_pr_carry`, outside `_pr_dx`. The solve judges the lunge and the step from the target as the key left it (so they are as at the contact), and then the hand's IK target is moved back in the body's frame by the carry: the body drives on by the carry and the hand stays where it landed, the arm folding by that much. The contact tick is untouched (the carry is zero on it). The row's `drive` and `ticks` are as before.
2. **The striking arm's release is rate-limited.** In the 17 ticks after a listed blow's contact (through the next blow's wind-up, but not the last two ticks before its own contact, which are the snap) the striking upper arm may turn at most `release_deg` (30; a row may carry its own) in a tick; held back by the limit it is stopped at its joint range, as the free arm's slew is. The arm is late, never early, and the contact and the snap are not touched. The cause of the pop, read from the probe: the contact solve's weight and the follow key hand the limb over in the one tick (`su_hook` and `su_plate` 53 and 54 degrees three ticks after the contact, `su_hammer` 41 to 44 on three ticks as its elbow folds from 47 to 108 degrees of flex); the first version of the limit applied only to the blow's own ticks and the arm caught up in a 58-degree turn when the next wind-up took the window, so it runs on through the handover.

## What it did (the 75 samples, 50 key sets)

| Reading | Before (the old route, no limit) | With the solve carry |
| :--- | :--- | :--- |
| the pelvis goes this far past the same blow with no drive (6 ticks after the contact), median | 1.4 units | 3.0 |
| ... mean | 1.5 | 2.6 |
| key sets that carry their row's full drive (3 units or more) | 7 of 50 | 16 |
| key sets that gain half a unit or more over the old route | | 30 of 50 |
| the striking hand's drift from where it landed, 4 ticks after (mean) | 2.1 | 2.2 |
| samples whose striking upper arm turns over 35 degrees a tick in the 13 ticks after the contact | 18 | 6 |
| ... over 50 degrees | 6 | 1 |
| worst turn | 69 degrees | 56 |
| `su_hook`, `su_plate`, `su_hammer` (worst turn after the contact) | 53, 54, 41 | 30, 30, 30 |

The hand stays: its drift is the same to a tenth of a unit on the blows that latch it (`su_ram`, `su_drive`, `su_palm_arm` 0.2, 0.2, 0.1 either way). The blows where it drifts (`su_plate` 6.5 against 5.3 with no drive, `su_blade_jaw` 1.0) are the swinging ones, whose hand is not latched; the test reads the latched ones.

**How many gain:** 30 of the 50 listed key sets carry further; the release is smoother on the three families named (the hook, the plate, the hammer: worst turn 53, 54 and 41 down to the limit's 30). **What it costs:** two small branches a tick for a listed blow after its contact (the carry's add and a rate limit on one upper arm), no forward kinematics and no new solve; not benched here (the machine was loaded by other sessions' captures, so a measurement would be invalid: the bench is `tick_bench.gd`, `--no-carry-solve` for the other side).

## The blends: could a blend change help the pulled frames?

Not by a blend change in the places I could reach, and not broad. Across the 75 samples, 56 of 2,550 frames (2.2 per cent) in the 34 ticks around a contact have a final-pass correction over 2 degrees, mean 5: 17 in the wind-up (mostly a held blow's coil), 18 in the return, 10 in the approach to the contact, 7 in the follow, 4 in the snap. The blends themselves (`AnimPose.mix`, `mix_lag`, `slerp_limb`) already go by swing and twist for the shoulders and hips. Two narrow candidates, each a trim that refuses to take a jointed bone further past its range than either end of the blend, were tried and changed **no frame**: one in the lead-in's own blend (the approach), one on the return mix. So the blends are inside their limits when they run; what the last pass corrects is added after them, by the later layers (the contact solve, the free-arm slew, the recoil and the held coil: `joint_scan`'s stage D). A fix would be in those layers, one at a time, and 2 per cent of frames at 5 degrees does not call for it.

## Proof

- `anim_check` `_test_solve_carry`: four hand blows (`su_ram`, `su_fist_heave`, `su_drive`, `su_palm_arm`) with no drive, the old route and the solve's: the pelvis goes at least 3 units past no drive and no less than by the old route; the striking hand drifts at most a unit more than with no drive; the contact tick the same pose (0.00 units apart); `su_hook`, `su_plate` and `su_hammer`'s striking upper arm turns at most 36 degrees a tick after the contact and no more than without the limit.
- The other gates and the clips are in the report. The clips are in `img/solve-carry/`.

## Not here

- A kick's foot target is moved back by the carry the same way (the foot is the limb); the test and the numbers above read hand blows.
- Rows' `release_deg` is 30 for all; a blow that wants its arm back sooner takes its own.
- The values were tuned on today's proportions; the mechanism carries onto the finished models.
- `follow_through.json` gained `release_deg` (global and per row): the schema draft is updated in `schema-drafts/anim-follow-through.schema.json`.
