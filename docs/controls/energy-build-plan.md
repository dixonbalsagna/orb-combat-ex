# Energy overhaul, Controls' build plan (paper; held until Orb answers GD's section 18)

Controls, 2026-10-23, for GD's rulings (`docs/design/energy-overhaul.md` section 19). Nothing is built. Everything is **behind one switch** so that with it off every intent, replay and checkpoint is the same to the bit. The grammar is in `energy-input.md`; this is the list of changes, files, tests and what other directors must supply.

## 0. The switch

`switches.energyV2` in `data/input/timing.json` (off), beside `airBrakeGuard` and `grappleReads`; schema by patch. GD says "behind energy.v2": the EP should confirm that is the same flag, or name where it lives and I read that one instead. With it off: no hybrid, the old wind-up values, no `charge_cancel`, no `charge_stage` rumble.

## 1. Mask 3 on (rule 10)

- `SimInputData.hybrids()` returns `[3]` from `stances.json` only when the switch is on (otherwise `[]`, as now). `stances.json` itself gains `"hybrids": [3]`.
- **No layout change**: LB+RB then reports `stanceMask` 3 with `guard` and `mode` both live (built and tested). Both press orders, a one-shot tap on each, and a latched energy plus LB all give mask 3.
- `stance_test.gd`: the assertion "no hybrid is enabled yet" becomes "off until `energyV2`, on with it"; add rows for mask 3 through the hub on a pad, the solo and shared keyboards, and Full touch; RT still dominates; LB+LT and RB+LT still read as the newest.
- A Guard press with RB held fires its `guardPress` (the perfect-block attempt): a test row.

## 2. Mode-aware wind-ups (rule 2)

- `read` gains `windupEnergyHeavy` 16 and `windupEnergyGrab` 10 (Y keeps 12; the grace is 4). Schema patch for Tools.
- `SimPressRead.windup_for`: with the switch on and the entry's `stance & 2` set (RB or mask 3), **B** returns `windupEnergyHeavy` (today B outside the martial stance returns -1, "the stance's own signature") and **A** returns `windupEnergyGrab`; Y is unchanged. `decision_for` follows: Y 16, B 20, A 14. RT and LT stances keep their present returns. Switch off: the old values, bit for bit.
- Tests: the three decisions in energy and mask 3, the martial ones unchanged, tap/charge at 16, 17, 20, 21 live ticks on a pad, a keyboard and touch, hit-stop release rows (the existing freeze rule), and a latched charge.
- **Open for GD:** under mask 3 (a lay), a hold past the lay "goes farther, set on release" (E71). I use the same energy decisions for it unless GD gives the lay its own window.

## 3. The charge cancel (rule 4)

- `SimPressRead.charge_cancel(prev, intent, charging) -> "dodge" | "guard" | ""`: pure; `charging` is the director's fact that a Y or B charge is loaded. A **dodge edge** (a tap of the dodge button, or the touch flick) is `"dodge"`; a **`guardPress` edge** is `"guard"`; neither is read when nothing is charging. A Guard press is also a perfect-block attempt (its edge still fires), and under the hybrid it is also LB joining RB.
- The sprint (a dodge held) is not a cancel; a held Guard that was already down is not a press.
- Tests: each layout's dodge and guard presses, a held guard, sprint, a latched charge cancelled by Guard, and that with the switch off the read returns `""`.

## 4. The charge-stage rumble (rule 7)

- `SimHaptics`: a `charge_stage` kind (a firm tick that gets stronger with the level) scaled by level over levels, plus the mapper row for the `charge_stage` cue (`k` the level, `n` the levels, actor the charger) and a quiet cancel tick. `charge_full` stays for the last level. Both gated by the haptics option, silent on a keyboard and iOS Safari, never constant (a gap per kind, as now).
- **Needs from Encounter:** the cue's fields (`k`, `n`, actor). I assumed these in the mapper's comment.
- Tests: the new kinds are distinct, short and duty-limited (the existing family tests extend), the mapper row, the scale.

## 5. The lay on each device (rule 10)

- **Pad, solo and shared keyboards, Full touch:** nothing new in the layout; mask 3 is the chord. The keyboards and Full touch get their one-hand form from the existing **energy toggle** (and the one-shot latch): energy latched, then Guard held, then a face button. Tests: that path through each layout.
- **Simple pad:** Guard is B (east); the lay is Guard held plus a face button at range, read by the director (the energy half is `autoMode`).
- **Simple touch needs a build item that I overstated earlier:** Simple touch has **no one-shot stance arming** (only Full touch does, `touch.gd`). So "tap Guard, then tap Attack" does not exist yet. The cheaper and cleaner answer, which the phone doc already wanted, is a **Guard toggle on Simple touch** (tap to guard, tap to drop, a setting; default on touch): Guard latched plus an Attack tap is the lay, one finger at a time. Cost: a latch in `SimTouch` for the Guard button, a setting through the hub, UI's option text, and tests. The tap-as-perfect-block must still fire the edge (a timed tap is the block); a latch changes only the held level. If Orb wants a one-shot instead, the same slot can arm for 30 ticks; a long window would turn a perfect block followed by an attack into a lay.
- **Simple touch Attack** is unchanged: tap light, hold medium, swipe up heavy (a swipe held after the swipe charges the beam: the hold level after the swipe is already in the intent); rapid fire is a mash of taps; X fires on the release.

## 6. What does not change

- No intent bit, no packing change, no replay break (mask 3 is representable and never appeared before).
- The mine on RB + A moves to the lays and RB + A becomes the grab (rule 11): the director's, not the input's. Mask 1 with A stays the reversal and the deflect (rule 12).
- X's stream still starts at the burst start, 16 live ticks (rule 16); the mash caps and the "lapsed" ack are the director's.

## 7. Gate list for the window

Input tests (18 and the new rows), `npm test --prefix sim`, `tools/validate.js` and its self-test with the schema patch, render determinism plain and `-- --intro --seeds=2 --ticks=900`, and the **switch-off equivalence run** (random intents through the layouts with the switch off, bit-identical to HEAD), as for the brake and grapple window.

## 8. Dependencies and the order

1. EP: confirm the switch name; Orb answers GD's question (tap B blast, hold B beam).
2. Tools: the schema patch (`energyV2`, the two `read` keys, `hybrids`).
3. Me: sections 1 to 4 first (data and pure reads, all testable alone), then 5.
4. Encounter: the `charge_stage` cue fields, the lay frames, mask 3 in the director, the Simple guard-at-range rule.
5. Rendering: a one-line host connect for the new rumble kinds if the mapper's cue loop needs an entry (it already passes every event).
6. UI: the Guard toggle setting's text for Simple touch.
