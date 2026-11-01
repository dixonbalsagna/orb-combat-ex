# The follow-through: the handover and the weight carried on (Animation, 2026-10-30)

Owner: Animation. Orb on the lead-in clips: "follow-through should be important as well". The goal the EP set: after the contact the body carries the blow's weight on and settles, with no pop back to idle or the next key; data, the same way as the lead-in, with a switch. Render only: no sim state, no contact tick and no hash moves.

## What was wrong

Read from the same 75 samples as the lead-in (`lead-in.md`), the fourteen ticks after a contact. In a mashed B string the pelvis jumped 10 to 20 units in one tick about ten ticks after the first blow's contact (`su_ram` 18.4, `su_drive` 15.1, `su_heel` 15.1, `su_blade_jaw` 13.2). The cause is not the pose carry (`_press_carry` carries the hips and the bones across the handover correctly): it is the **contact solve**. The last blow's contact solve holds the pelvis and the hand on the defender through the first half of the follow-through, and when the next blow's wind-up takes the window (it starts `L` ticks before its own contact, which in a string is still inside the last blow's follow-through) that blow's solve weight goes from about 0.9 to 0 in one tick. The solve had pulled the pelvis 18 units off the follow key's hips (`su_ram`: key 32, drawn 14); letting go put it back.

The body also stopped at the follow key with nothing of the blow's weight after the contact.

## The fix

Two parts, one switch (`RenderAnim.follow_through`; `--no-follow-through` is the before), data in `data/anim/follow_through.json`.

1. **The handover.** When a blow that has a row in `follow_through.json` is handed over to the next wind-up while its contact solve is still in force, the solve lets go over `handover_ticks` (5) instead of on one tick, with the old blow's own target and step and only the body's lunge and step (not the limb, which is the new pose's: `_ci_out`). Blows with no row hand over as they did: the first version eased every blow, and one light's retreat step left a contact 6.6 units short of the defender in `anim_check`'s seed-4 match (3 allowed), so the ease is for the listed blows only.
2. **The carry.** A row's `drive` (units forward, through the same `_pr_dx` the style's stretch uses, so the contact solve counts it) and `dip` (units the hips sink) peak a third of the way through the row's `ticks` and are settled by the end; both are zero on the contact tick, so the landing is the key's. Heavier blows drive and dip more, kicks dip more than hand blows (a heavy hand: 3.5 and 2.2 over 12 ticks; a heavy kick: 3.0 and 3.0; a medium hand: 1.5 and 1.0 over 8; a medium kick: 2.0 and 1.8 over 10). `ru.su_hammer` has a zero row: Legal's hand-held-up rule (the hand at 76 or lower six ticks after the contact) leaves no room.

## What it did (the 75 samples)

| Reading | Lead-in only | With the follow-through |
| :--- | :--- | :--- |
| samples with a one-tick pelvis step over 12 units (the ten ticks before to the fourteen after a contact) | 16 | 10 |
| the handover step in a mashed B string: `su_ram`, `su_drive`, `su_heel`, `su_blade_jaw` | 18.4, 15.1, 15.1, 13.2 | 9.7, 3.7, 9.1, 8.4 |
| the striking arm's swing off the contact tick, samples over 45 degrees | 23 | 20 |
| the hips sink after the contact, median | 2.3 units | 3.3 |
| the pelvis drives past the contact pose, median | 0.0 | 0.5 |

Read these numbers against `solve-carry.md`: the last row measures the pelvis against its own contact pose, which the follow key's hips fall away from faster than the drive rises, so it understates the drive; against the same blow with no drive the carry is 1.4 units (median) by this route and 3.0 by the contact solve's own (park 4). The sink shows either way.

## Proof

- `anim_check` `_test_follow_through`: four blows in a mashed string (`su_ram`, `su_drive`, `su_heel`, `su_blade_jaw`), with and without: the biggest pelvis step in the thirteen ticks after the second contact at most 12 and 0.75 of the before; the second contact tick the same pose (0.00 units apart); a lone blow that is not listed identical with the switch on and off; 50 rows, each a key set with a drive of 0 to 8, a dip of 0 to 6 and 4 to 20 ticks. 10,000 checks pass, on clean HEAD with the split stacked.
- The other gates and the clips are in the report. The clips are in `img/follow-through/`.

## Not here

- The striking arm's pop when the contact solve lets go of it (`su_hook`, `su_plate`, `su_hammer` turn 45 to 95 degrees of upper-arm twist a tick, six to ten ticks after the contact) is not changed: most of it is the arm rolling about its own axis, which the direction of the arm barely shows, and it wants its own window.
- The rows' values were tuned on today's proportions; the lists and the mechanism carry onto the finished models.
- `data/anim/follow_through.json` needs Tools' schema: the draft is `schema-drafts/anim-follow-through.schema.json`.
