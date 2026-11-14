# first-pad: one person's first press takes player one (Controls, 2026-11-01)

The EP's urgent order after Orb's first play: Orb ended up in Player 2's seat (slot 1 had 2,085 of 2,086 input changes, slot 0 never moved).

## Cause (read from the code, then reproduced with scripted pads)
`render/core/main.gd` `_on_menu_started` pre-claims slot 0 for "Player 1 is Controller" on `Input.get_connected_joypads()[0]`. If that is not the pad in Orb's hands (a phantom or virtual entry, a second device, or just a different number than the Xbox 360 pad), the hub saw the real pad's first press as a **second device** and `_assign` joined it as player two. Slot 0 stayed on a pad nobody touched.

## The fix: hub only, no change to `render/core/main.gd` (so no grant is needed)
`sim/input/hub.gd` (+12 lines): a per-device `_pad_used` flag, set when that pad presses a button, pulls a trigger or pushes either stick past 0.5. In `_pad_slot`, when slot 0 is claimed on a pad that has **never been used** and a different pad (not slot 1's) presses, the press **takes slot 0**: the unused pad's layout is released and `slot_pad[0]` points at the new pad, the press is player one's, and no join is made. A pad that has been used keeps its slot, so a second person on another pad **joins as player two** as before. `reset_claims()` clears the flags. Keyboard-claimed player one is unchanged (a pad press is a second person).

`_pad_event` still ignores pads while the start card is open (`ui_hud.is_overlay_open()`), so the rule acts on the first press after the match starts, which is what the EP's rule says. Start on a not-yet-used pad also goes to `pad_button` and lands on player one.

## Files
| File | What |
| :--- | :--- |
| `first-pad.patch` | Built on HEAD's `sim/input/hub.gd` (applies to HEAD and to the working tree and to the stack): the hub change and `sim/input/test/pad_first_press_test.gd` (23 checks) |

Apply: `git apply docs/controls/pending/first-pad/first-pad.patch`. Independent of every other park (anchors are untouched by `first-press.patch`).

## Tested
Scripted pads at device 0 (phantom, pre-claimed), 1 and 2 through the real hub: the real pad takes slot 0, no join, its stick moves player one; a pad that pressed or pushed a stick first makes the next pad a joiner; a nudge under 0.5 does not count; a second person on pad 2 after the real person on pad 1 joins as player two; a third pad takes neither slot; keyboard player one unchanged; two pads from the menu keep their own slots; `reset_claims` clears. Full input suite (27 tests) and `node tools/lint-determinism.mjs` pass on the stack.

## Not done / caveat
Nothing was run against the real game window or Orb's pad. If Orb's pad had already pressed something on the phantom's number first, the rule would not move it; the black box (`slot_pad` in the fight record) would show that.
