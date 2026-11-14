# dash-handover (park, on 3aaf0df3)

LT's dash is on from the press tick and only while LT is held: no free 12-tick lunge after a release, so a tap stays the slip (Game Design, 2026-11-08, (c)). Design, the tap table and what stays Simulation's: `docs/controls/dash-handover.md`. Records: `docs/controls/runs/3aaf0df3/` (CD-22).

## Apply order (this batch: the four patches are a chain, recut 2026-11-08 on c7b0414b with the b-no-beam interim and its 12-tick chord; records `docs/controls/runs/c7b0414b/`)

1. `pending/b-no-beam/b-no-beam.patch` then `pending/b-no-beam/director-isb.patch` (grant: sim/director/brawl.gd, approved by Encounter)
2. `pending/inert-knock/inert-knock.patch`
3. `pending/dash-handover/dash-handover.patch`

They touch the same lines of timing.json and input_data.gd (the switch list), so each was cut on the one before: apply them in this order with `git apply`, each is clean on HEAD 3aaf0df3 in sequence. The three before this one landed or are listed in their own READMEs.

## This patch

Seven files: `data/input/timing.json`, the schema, `sim/input/input_data.gd`, `layout.gd` (the dash line), the new `sim/input/test/dash_handover_test.gd` (+ `.uid`) and the probe `sim/input/tools/lt_tap_probe.gd`. No grant. Switch `switches.dashHandover`, off; flip it with Simulation's range-free dash.

## Tested

All 44 input tests pass with the four applied in order; `dash_handover_test` 15 checks; negative control (layout reverted): 7 fail; lint and validate clean; byte for byte. Not run: parity golden (the switch is off), QA's close-time rows (Simulation's change is not in).
