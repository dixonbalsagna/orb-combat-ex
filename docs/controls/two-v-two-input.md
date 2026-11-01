# 2v2 on the pad: the focus, the extra bits and the claw-grip check (Controls, 2026-11-01; paper only, nothing built)

For `docs/design/two-v-two.md` (Game Design) and `docs/net/two-v-two-lan.md` (Netcode). Orb's picture: two PCs on a LAN, one human and one pad on each, a partner and two opponents. This is what the input layer would need, in the order it matters.

## 1. Focus: who you are fighting

GD's rule: focus picks itself (the last one you hit, else the nearest in front, a stick strike toward someone goes to them); a button moves it to the next enemy; it eases over about 12 ticks and gives no blow. The input half:

| | Standard pad | Left-handed pad (the swap) | Keyboard |
| :--- | :--- | :--- | :--- |
| **Switch focus** | D-pad left and right (previous, next), **when the D-pad mirror is off** | the same actions land on the face buttons' positions, because the swap mirrors every binding (D-pad left and right become West and East); no special case | two keys of their own, remappable |
| **With the D-pad mirror on** | **Back** (next), hints move to the pause menu in 2v2 | the mirror of Back is Back (Start and Back are not swapped) | the same keys |
| **The call** ("I need you") | D-pad up (a voice line and a map mark) | North | a key |

- **The layout needs one switch more.** Today the layout switches the D-pad's strike mirror on and off (`set_mirror_dpad`, "auto" only for a pad with no right stick). Focus and call are bound to the D-pad with a condition: on while the mirror is off; Back takes focus while it is on. Same code path, a second pair of bindings gated by the same flag. Small, all in `sim/input`.
- **They are actions, not blows.** Focus and call are not face presses to the no-claw law (light, heavy, sig, context, special): they neither wait for the stick nor set the strike's R lockout, in either layout, so row S (the swapped layout makes the same stream) holds.
- **Remap.** Two new rows for focus (previous, next) and one for the call. The Back-with-mirror form is a fixed alternative.

## 2. The extra bits

Word 1 is full. Word 2 (`pack2`) uses 26 bits of 32, so six are free. Proposed:

| Field | Bits | Meaning |
| :--- | ---: | :--- |
| `focusStep` | 2 | 0 none, 1 next enemy, 2 previous enemy (an edge, kept until the step takes it, like the strike edges) |
| `call` | 1 | the "I need you" edge |

That is 3 bits, 29 of 32 used, three spare. It changes the packed word, so it needs Simulation (the hash and the intent copy), Netcode (the packed record, the confirmed frame) and Tools (the replay header's word-2 flag already exists, so a version bump of the word, not a new flag). Focus itself (who the fighter is closing on) is hashed state in the sim, set from the edge and the rules above; the layout only reports the press.

Slots: the hub keeps two human slots per machine. One human per PC fits that as it is; four slots in one hub is not needed for the LAN idea. The remote human arrives as the net layer's intent for a slot, as in a 1v1.

## 3. The claw-grip check (model section 8)

A D-pad press takes the standard left thumb off the move stick for the travel to the D-pad and back (6 ticks in the model, the fast thumb); a claw's index finger does not, so it keeps steering. Over 600 ticks, with a focus press as often as the least gap allows:

| Least gap between presses | Presses | Steering a claw keeps over the fast thumb |
| ---: | ---: | :--- |
| 12 ticks (GD's ease) | 50 | 300 ticks, half the horizon |
| 30 | 20 | 120 (20%) |
| 60 | 10 | 60 (10%) |

So a press that is merely worth little is not enough if presses can come every ease. **Two options for GD**, both on actions:

1. **A hold-off law** (my recommendation): a focus or call press holds the move stick for 6 ticks for every grip, like the strike law's lockouts, so a claw loses exactly what the fast thumb loses (model: claw gain 0). Costs the standard thumb nothing it was not already losing.
2. **A least gap** of 60 ticks between presses, which bounds the gain to 10% of the time. Focus picks itself and the press should be rare, so this costs little.

Either way the ease (12) outlasts the thumb's travel (6), so a claw cannot use the gap to land anything. The model exits 0 with both checks. The number 6 is the fast thumb's travel from the model; the capture tool should measure the D-pad's.

## 4. What is not Controls'

Per-pair hit-stop, two brawls at once, rollback with four bodies, the map, the plate: Simulation, Netcode, Camera, UI (see the 2v2 note and `docs/net/two-v-two-lan.md`). The input layer adds nothing there.
