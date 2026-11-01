# The body's lead-in: weight and arm paths on the split's blows (Animation, 2026-10-30)

Owner: Animation. The EP's brief (Orb on the split clip: "looks pretty good, we should definitely keep refining the combos and the visual presentation"), then Orb on the three-blow clips: "give the other blows the lead-in too". Improve how the blows of the split read on screen, in anticipation, follow-through, weight on contact and arm paths. Render only: no sim state, no contact tick and no hash moves.

## What was wrong

Read from the split's cells (`docs/combat/pending/split/`, stacked on HEAD in scratch): 75 samples (51 distinct blows) of the new Y and B pools, both fighters, each played through the real solve with the real press layers and sampled every tick (`_tier_scene`, the rows `_bend_sample` keeps). Every one of them has the same fault on its contact tick. The style rows make the striking limb land on the contact tick with nothing in between (Orb's approved feel: instant-looking blows with an after-image), but **every other bone takes the contact key on that same tick too**:

| On the contact tick | Range over the 75 samples (median) |
| :--- | :--- |
| the pelvis steps forward | 3 to 41 units, median 14 (a fighter is about 70 tall) |
| the head steps forward | -11 to 54 units |
| the free upper arm turns | 26 to 156 degrees in the one frame, median 74 |

The body teleports into the blow and the free arm swaps its elbow side in a frame. In a mashed Y that is five pops a second.

## The fix

`AnimFighter._lead_in`, data in `data/anim/lead_in.json`, one row for each key set. Over the last three to five ticks before the contact the hips, spine, legs and free arm ease toward the contact key by the row's lists (the tick before the contact first). **The striking limb keeps its chamber and still lands on the contact tick**, so the fist or the foot is as instant as it was and the body is already behind it. The contact tick itself is the same pose as before (0.00 units apart in the test).

A row has up to four lists, each a weight from 0 to 1 per tick:

| List | Moves | Why separate |
| :--- | :--- | :--- |
| `weights` | hips, spine, head | the body's own lead; tuned to the end state, not the raw key: a heavy's contact tick ends well short of its key's hips (the contact solve and the squash release take it back), so too large a weight overshoots and comes back |
| `arm` | the free arm | it moves nothing else, so it can lead further |
| `legs` | the legs that are not striking | a planted leg straightening early reads as a knee turned in |
| `solve` | the contact solve's lunge and step | the blow's own reach (a rising knee, a headbutt) is 10 to 30 units that the contact tick used to take whole; it now meets the target over the same ticks (`_ci_wb` in `_exchange_layers`) |

The pelvis may sink into the blow ahead of the contact but never rises before it (a heave's tell, a planted foot).

**How each row was picked.** A probe plays every blow in its cells with five candidate scales of a three- or four-tick shape, and then with the contact solve's ramp at 0, a half and the whole of it, and keeps the one with the smallest worst one-tick pelvis step before the contact and no overshoot (`pelvis_step + 3 x overshoot`). One blow (the crescent kick) took the five-tick shape; the rest the plain three- and four-tick ones, with the scale and the solve's share picked by the probe.

**Two blows are not at full strength, on purpose.** `w1.double_hammer` has no row: its hands-up peak is the blow's picture and `anim_check`'s double-hammer test holds it (the lead-in drew the hands together early). `ru.su_heel`'s last tick does not lead: any lead on it, of any size, turns the planted knee in on that frame (the nine-cell bends test allows none), so its contact tick still steps 23 units; the ticks before it do lead. Its fix is a pose, not a weight.

## What it did (75 samples, the worst one-tick move over the ten ticks before to the fourteen after a contact)

| Reading | Before | With the lead-in |
| :--- | :--- | :--- |
| pelvis step, median | 14.5 units | 8.2 |
| pelvis step, worst | 40.7 | 23.3 (the heel, below) |
| samples with a step over 12 units | 48 of 75 | 16 |
| free arm's visible swing a tick (the direction of the upper arm and the forearm), median | 74 degrees | 35 |
| samples with a free arm swing over 45 degrees | 63 | 26 |
| ... over 70 degrees | 39 | 14 |

The free arm swings that remain are the blows where the "free" arm is also doing something (`cross_arm_ram`, `body_hook`) or where the lead-in is short (`su_hook`, `su_plate`); they are the next rows to tune.

## Proof

- `anim_check` `_test_lead_in`: eight blows with and without (the stomp of both fighters, the ram, the drive, a rising knee, a haymaker, the Anti-hero's knee, the Protagonist's heave knee): the contact tick within half a unit (it was 0.00), the pelvis step and the free arm's turn on the contact tick at most 0.6 and 0.5 of the before; every row a real key set with lists of one to six weights in 0 to 1 (49 rows); two blows outside the pools identical with the switch on and off. 9,945 checks pass on clean HEAD with the split stacked.
- The other gates are in the report. The clips are in `img/lead-in/` (and the follow-through's in `img/follow-through/`).

## Not here

- Rows for blows outside the split's pools (the X cells, the zips, the launcher) are not written; the mechanism takes them.
- The strike arm's own turn on the contact tick is the instant blow and stays.
- Hand and foot targets and the pole hints in the poses are in today's rig's units; the lead-in's lists are weights and carry onto the finished models unchanged. The rows' *values* were tuned on today's proportions: a finished model with longer legs may want its heavy rows re-picked (the probe is the recipe).
- `data/anim/lead_in.json` needs Tools' schema: the draft is `schema-drafts/anim-lead-in.schema.json`.
