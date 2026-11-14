# flight-strike-b: LT + B stays B when the flight strikes are on (Controls, 2026-11-07; re-cut on HEAD 85e838b6 for the batch)

Contract: `docs/controls/flight-strike-b.md`. Run record: `docs/controls/runs/cb477edf/`.

## Files
- `flight-strike-b.patch` (6 files), all Controls': `sim/input/layout.gd` (one condition on the RT-only conversion), `input_data.gd` (`flight_strike_b()`, and the switch in `pin_switches_off`), `data/input/timing.json` (`flightStrikeB: false`), `tools/schemas/input-timing.schema.json`, the new `sim/input/test/flight_strike_b_test.gd` (29 checks) with its `.uid`.

Apply: `git -c core.autocrlf=false -c core.eol=lf apply flight-strike-b.patch`. Independent of `../pad-brace/` and `../refusal-knocks/`.

## Checked
All 38 input tests on the tree with all three Controls parks; lint and validate clean; the patch on clean HEAD files gives the tested tree byte for byte. The switch is off, so nothing moves with it off.

## NEEDS FROM EP
- **Tools:** the page row `flightStrikes` flips `zip.flightStrikes.enabled`, `switches.flightStrikeB` and `switches.dodgeHeld` together (needs `rightStick`, `signatureRtOnly`).
- No grants.
