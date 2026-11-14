# chord-full-send: a chord is the biggest press, and the full send's haptic (Controls, 2026-11-07; from Encounter's refusal-reasons and stick-slam)

Contracts: `docs/controls/chord-pick.md`, `docs/controls/full-send-haptic.md`. Run record: `docs/controls/runs/090264d7/` (`chord-full-send-*`).

## Files
- `chord-full-send.patch` (10 files), all Controls': `sim/input/layout.gd` (`_pick_chord`, `take_dropped` joins the chord list), `input_data.gd` (`chord_pick_on()`, in `pin_switches_off`), `data/input/timing.json` (`chordPick: false`) with its schema, `haptics.gd` (the `full_send` kind, `full_send_requests`, the codes `recovering`, `set_piece`, `chord`), and tests: `chord_pick_test.gd` (15), `full_send_haptic_test.gd` (14), `haptics_test.gd` (the kind in its list), each new one with its `.uid`.

**Apply on top of `../flight-strike-b/` and `../refusal-knocks/`** (the schema and timing hunks sit beside flightStrikeB, the table hunk beside `queue_full`): `git -c core.autocrlf=false -c core.eol=lf apply chord-full-send.patch`.

## Checked
All 40 input tests on the tree with the four Controls parks (`pad-brace` is independent); lint and validate clean; the patch on the three-park tree gives the tested tree byte for byte. `chordPick` is off, so nothing moves with it off; no host line for the haptic.

## NEEDS FROM EP
- **Tools:** page row `chordPick` (`switches.chordPick`; the hub needs `hapticRefused` to knock and list it).
- **UI:** words for `chord`, `recovering` and `set_piece`.
- A press the host drops in a pause (16 in Orb's play) stays with Rendering.
