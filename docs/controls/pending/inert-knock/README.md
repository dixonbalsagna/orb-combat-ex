# inert-knock (park, on 4b090e10)

A right-stick push with RT held (or LB + RB) is told once: the refusal `charging` (`warding`), one pad knock, one row for UI. Design: `docs/controls/inert-knock.md`. Records: `docs/controls/runs/c974e451/inert-knock-*` (CD-22).

## Apply (second of the four patches of this batch; apply after b-no-beam, before dash-handover; see `pending/dash-handover/README.md`)

`git apply docs/controls/pending/inert-knock/inert-knock.patch` (seven files in Controls' paths: `data/input/timing.json`, the schema, `sim/input/input_data.gd`, `layout.gd`, `haptics.gd`, and the new `sim/input/test/inert_knock_test.gd` with its `.uid`). Cut on the working tree after `b-no-beam`: apply that first. No grant needed.

## Switch

`switches.inertKnock`, off. Flip it on in the landing commit or by a Tools row (it needs `rightStick` and `hapticRefused`, both on in main). UI needs words for `charging` and `warding` (suggested "Charging" and "Warding").

## Conflict

When the signature moves onto RT + right stick (Game Design, 2026-11-08), the `charging` case must go; see `docs/controls/inert-knock.md`.

## Tested

All 41 input tests pass; `inert_knock_test` 11 checks; negative control (layout reverted): 4 fail; lint and validate clean; byte for byte. Not run: parity golden, director checks, `hud_check` (nothing in the sim or the intent changes).
