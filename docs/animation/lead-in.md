# The body's lead-in: weight and arm paths on three blows of the split (Animation, 2026-10-30)

Owner: Animation. The EP's brief (Orb on the split clip: "looks pretty good, we should definitely keep refining the combos and the visual presentation"): improve how the blows of the split read on screen, in anticipation, follow-through, weight on contact and arm paths, on the two or three blows that gain most. Render only: no sim state, no contact tick and no hash moves.

## What was wrong

Read from the split's cells (`docs/combat/pending/split/`, stacked on HEAD in scratch): 75 samples (51 distinct blows) of the new Y and B pools, both fighters, each played through the real solve with the real press layers and sampled every tick (`_tier_scene`, the rows `_bend_sample` keeps). Every one of them has the same fault on its contact tick. The style rows make the striking limb land on the contact tick with nothing in between (Orb's approved feel: instant-looking blows with an after-image), but **every other bone takes the contact key on that same tick too**:

| On the contact tick | Range over the 75 samples (median) |
| :--- | :--- |
| the pelvis steps forward | 3 to 41 units, median 14 (a fighter is about 70 tall) |
| the head steps forward | -11 to 54 units |
| the free upper arm turns | 26 to 156 degrees in the one frame, median 74 |

The body teleports into the blow and the free arm swaps its elbow side in a frame. In a mashed Y that is five pops a second. The strips (`img/lead-in/`) show it: the guard arm out straight one frame and folded in front of the face the next, the whole figure a step further on.

## The fix

`AnimFighter._lead_in`, data in `data/anim/lead_in.json`. For a key set listed in the file, over the last three or four ticks before the contact the hips, spine, legs and free arm ease toward the contact key by the row's weights (the tick before the contact first). **The striking limb keeps its chamber and still lands on the contact tick**, so the fist or the foot is as instant as it was and the body is already behind it. The contact tick itself is the same pose as before (0.00 units apart in the test).

Two lists a row: `weights` for hips, spine, legs and head, and `arm` for the free arm, which moves nothing else and so can lead further. The weights are tuned to the end state, not to the raw key: a heavy's contact tick ends well short of its key's hips (the contact solve and the squash release take it back), so a ram's weights are smaller than a stomp's or its pelvis overshoots and comes back.

**Three blows are listed**, picked for use after the split and for what they gain:

| Blow | Where it is thrown | Pelvis step on the contact tick | Free upper arm turn |
| :--- | :--- | :--- | :--- |
| `stomp` (`w1.stomp`, `pr.stomp`) | Y mashed, both fighters (the grind) | 12.0 to 3.7 units | 96 and 92 to 15 and 14 degrees |
| `su_ram` (`ru.su_ram`) | the Anti-hero's B: tapped, mashed and held | 23.2 to 4.3 | 54 to 11 |
| `su_drive` (`pu.su_drive`) | the Protagonist's B mashed | 10.4 to -1.0 (a unit of settle) | 59 to 12 |

Every other blow plays the same bytes with the lead-in on and off (the test samples three unlisted ones and requires 0). `RenderAnim.lead_in` is the switch (`--no-lead-in` is the before). To list another blow, add a row; the numbers to start from are the stomp's.

## Proof

- `anim_check` `_test_lead_in` (new): the four listed cases, with and without; the contact tick within half a unit (it was 0.00); the pelvis step and the free arm's turn at most 0.6 and 0.5 of the before; three unlisted blows identical with the switch on and off. 9,923 checks pass, on clean HEAD with these files and again on HEAD with the split stacked (recipes, enders and the mash key, scratch).
- `joint_scan --strict` (also `--bodies=4 --only=live`), `lead_scan --strict` (also `--bodies=4`), `held_scan --strict`, `guard_scan --strict`: pass on both. Determinism plain and `--intro` (2 seeds, 900 ticks): pass on both. The sim hash cannot move: nothing here is read by the sim, and `_scan_writes` holds.
- The look gate (ADR 0010), no dissolves, fades or markers over the fighters. The edge strip and the labels in the clips are on the clips, not in the game.
  - `img/lead-in/stomp-protagonist.gif`, `su_ram-antihero.gif`, `su_drive-protagonist.gif`: the study scene (the real solver against a dummy), the split's pools, today on the left (blue bar) and with the lead-in on the right (orange bar), one frame a tick, the contact tick lit in the strip along the bottom edge. In the ram the body now drops, rises and drives from three ticks out and the fist lands on the same tick; today he crouches and is a body-length further on in the next frame. In the stomp the guard arm folds up into the blow over three ticks instead of going from extended to folded in a frame.
  - `img/lead-in/split-walk-before-after.gif`: Combat's walk through the presses (Y tapped, mashed, held; B tapped, mashed, held; X held, mashed) on the idle dummy, real play on the split stack, the X, Y and B pressed drawn at the bottom edge, about 16 seconds. Only three blows changed, so most of it is the same twice; sampled every third tick, the lead-in is a frame or two.
- The collapse clip (`collapse`, seed 12345, 1500 ticks, headless Chrome through `tools/flash/capture-web.mjs`) on the split stack, with and without the lead-in: **reduced PASS (2.5 general, 3 at the area threshold 15% lower, 0 dips), the same without; normal FAIL at 3.5 on both** (the reading `water-stance.md` found on pure HEAD too; not this change's). The machine was busy; the capture guard held its 25% cap and the clips ran to their 1,500 ticks.
- Not run by me: the render gates outside Animation's (seam, ground, city, depth and the rest), outline and cull (they need a window), `validate` and `self-test`.

## Not here

- The other blows of the split's pools have the same one-tick pop (the table above is all 75 samples). They take the same row each; the three here are the ones the clip shows most. A blanket row for every medium and heavy is Orb's call, because it touches the approved snap's neighbours.
- The strike arm's own turn on the contact tick (50 to 170 degrees) is the instant blow and stays.
- `data/anim/lead_in.json` needs Tools' schema: the draft is `schema-drafts/anim-lead-in.schema.json`.
