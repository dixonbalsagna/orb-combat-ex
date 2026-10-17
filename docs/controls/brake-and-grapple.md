# The air brake's bit, the clinch's "A only", and the grapple's reads: built and parked behind switches

Controls, 2026-10-17, from the EP's brief (Game Design's rulings): `docs/design/buildings.md` section 7.2 and `docs/architecture/brake-core.md` for the brake, `docs/design/grapple.md` and `docs/controls/grapple-input.md` for the grapple. **Everything here is off until its owner switches it on, and with it off every intent, replay and checkpoint is the same to the bit.** `docs/controls/` holds the two patches; nothing outside `sim/input/` and `data/input/` is edited.

## The switches (`switches` in `data/input/timing.json`)

| Switch | Off (today) | On |
| :--- | :--- | :--- |
| `airBrakeGuard` | Guard held on a Simple slot is the defensive stance (`stanceMask` 1), sent or not | While the host says the slot's fighter is sent (launched), Guard held is `stanceMask` bit 8, the manoeuvre stance's hold, which the core reads as the brake |
| `grappleReads` | `SimPressRead.a_read` has the shove and the clinch-by-mash | `a_read` drops them: only the tackle's coil is read; a tap is a plain "tap" with no throw; a second A inside 12 ticks is a new press. `opts.grapple` overrides the switch either way |

`read.catchTell` 10 is data for `catch_read` and `brace_read` (additive: nothing calls them until the grapple does, so they need no switch). The schema for the two switches and `catchTell` is `docs/controls/switches-schema.patch` (Tools).

## 1. The air brake: LT held while sent is bit 8; on Simple and touch, Guard held while sent is too

- **LT already sets bit 8** on every layout that has it: the pad's LT, the keyboards' Space and the Full touch Dodge hold (the manoeuvre stance, resolved by the layout). Nothing changes there, sent or not, switch or not (tested). **An LT tap at contact stays the tech:** its press is still the `dodge` edge, and bit 8 lasts only the press and the 2-tick release grace, so a tap cannot hold a brake of any length.
- **Simple has no LT.** On the Simple pad and Simple touch, `SimStance.air_brake_mask(mask, sent, simple)` turns the defensive bit (1) into bit 8 while `sent` is true and the switch is on. Guard's own `guard` field is left as it was (the brake needs only the mask). RT held still dominates (a charging fighter is not braking), and every other Simple button is unaffected.
- **"Sent" comes from the host, once a tick:** `hub.set_sent(slot, on)` (`SimLayout.set_sent`, `SimTouch.set_sent`), set before `hub.intent(slot)`. The host line is `docs/controls/sent-host.patch` (render/core/sim_host.gd, one line, `hub.set_sent(k, S.fighters[k].state == "launched")`): the sim's own state for a send, read by the host. Simulation may offer a better predicate (its brake's state) in place of `state == "launched"`.
- **Determinism:** the bit is in the intent the layout builds, and the replay records the intent, so a replay carries the brake and needs no state; tested through the packed intent. The layout reads no render state, and the host reads sim state only.
- **Full touch** is not changed: it has the Dodge hold for LT's bit, and its Guard stays a guard. The AI's use is Encounter's.

## 2. `struggle_press`'s "A only" for a Simple slot in a clinch

`SimPressRead.struggle_press(prev, intent, {"a_only": true})`: for a Simple slot (mode -1) the surge is dropped, so only A is read (LB's `context`, or Guard's `guardPress` standing for A on touch Simple, as `grapple-input.md` recommends) and everything else, the Attack's rising level and Y's press, reads `"none"` (the director throws a Simple player's vicious blows). It returns `"letgo"` for A: in a clinch the director reads that as the pummel. A non-Simple slot ignores the option (it has real X, Y and B). Without it, the function is exactly as before.

## 3. The grapple's reads

- **`catch_read(entry, live_now, p)`:** for an A pressed in reach, on the live clock. `"tell"` while it is down inside the tell plus the grace (`catchTell` 10 plus `windupGrace` 4, so under 14 live ticks); `"tap"` if it was let go by 14 (the catch lands at the tell's end or at the release if later: the clinch, or the throw at once on an open fighter); `"carry"` if it is still down at 14 or was let go after. A touch tap (5 to 12 ticks) is always a catch on every device. Out of reach the director keeps `charge_read` (the tackle's coil at 16).
- **`brace_read(entry, live_now, p)`:** `{braced, since}`. A is braced once it is still down at the same 14, so the catch's carry and the brace start on the same tick and a tap never braces. A pummel is the press itself, on the pulse.
- **`a_read` retired behind `grappleReads`:** see the switches.
- **Latched charge and charges off** are as `grapple-input.md` says (a toggled brace; no carry from a latch; no brace or carry with charges off). Nothing here changes them.

## Proof

`brake_grapple_test.gd` (66 checks): the switches' defaults; the brake on the Simple pad and Simple touch (off, on, not sent, sent, RT dominating, the outer ring, other buttons) and through the hub per slot (only the sent slot, the bit surviving the packed intent, switching off); LT, Space and the Dodge hold unchanged and Arena's and Full touch's Guard unchanged; `a_only` on the Simple pad, Simple touch, a non-Simple slot and without the option; `catch_read` (every threshold, taps 3 to 12, the live clock, unstamped logs, a data override, the tackle's 16 untouched); `brace_read` (13 not, 14 is, `since`, release, taps never, the shared line); `a_read` off and on. On a clean export of HEAD with these files and both patches: all 16 input tests, `npm test --prefix sim` (5 of 5), `tools/validate.js` (0 errors) and its self-test (7966 of 7966), and render determinism plain and `-- --intro --seeds=2 --ticks=900` (each same as the sim alone).
