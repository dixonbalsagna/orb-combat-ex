# charge-lost (park, on 592a807b)

A lost charge is felt: three pad pulses of their own (`charge_broken`, `charge_lapsed`, `hold_short`), the charger's pad only, no screen mark. Design: `docs/controls/charge-lost.md`. Records: `docs/controls/runs/592a807b/` (CD-22).

## Apply

`git apply docs/controls/pending/charge-lost/charge-lost.patch` (eight files, all in Controls' paths: `data/input/timing.json`, `tools/schemas/input-timing.schema.json`, `sim/input/input_data.gd`, `haptics.gd`, `hub.gd`, `test/haptics_test.gd`, and the new `test/charge_lost_test.gd` with its `.uid`). Cut on HEAD 592a807b. No grant needed; no host change (`render/core/main.gd` already hands every event to `SimHaptics.event_requests`).

## Switch

`switches.chargeLostCue`, off (also in `pin_switches_off`). One Tools row, no pairing. The shipped data already has `hapticImpact`, `hapticRefused` and `rightStick` on. UI may want words for `charge_broken`, `charge_lapsed` and `hold_short` (suggested "Charge broken", "Charge lost", "Hold longer").

## Tuning, in data

`strike.shortHoldTicks` (6): raise to 8 or 10 if every slow quick-beam feels nagged. The three shapes are code defaults in `haptics.gd`, like the other newer kinds.

## Tested

All 45 input tests pass (`charge_lost_test` 45 checks, `haptics_test` 80 with the three kinds added); negative control (haptics.gd and hub.gd put back): 16 of 37 fail; lint and validate clean (321 files, 0 errors); the patch applies and reproduces the tested tree byte for byte. Not run: the parity golden, the director checks and `hud_check` (nothing in the sim, the intent or the screen changes), and a real pad.
