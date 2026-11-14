# landing: every Controls park and switch Orb's page has, on HEAD (Controls, 2026-11-06; job 1 of the controller-vision brief, row 12)

Cut on main 51ab2001, tested on a clean export of it. Two patches, so the landing and the decision to flip are separate.

## 1. `controls-landing.patch` (2,200 lines, 25 files): the code, data keys and tests; every switch stays OFF
What it carries (the Controls parks in the stack's order, re-cut onto HEAD; every one applied with no conflict):
- the working tree's sim/input code the page lays over main as an overlay (the quick read's reader, the layout, the left hand, the hub, `input_data.gd`, the L3 brace default removed on Arena) and `data/input/layouts.json`;
- `quick-read`, `stick-feel` (the haptic kinds and the strike ladder), `responsive-2`, `first-press`, `signature-rt-only`, `stick-feel-host` (render/core/main.gd), `haptic-switches` (all the switch keys and the schema), `web-rumble` (render/core/main.gd), `queue-20` (strike.queueTicks 20);
- `first-pad`, `beam-aim`, `stage-haptics` (not on the page yet; the EP asked for them in the set);
- the new tests (`quick_read`, `stick_feel`, `pad_first_press`, `beam_aim`, `stage_haptics`) with their `.uid` files, the edits to `haptics_test`, `strike_gate_test` and `strike_hub_test`, and `sim/input/tools/orb_aim_probe.gd`.
`input-buffer` stays out (off, the EP's call). Touches `render/core/main.gd` (Rendering's file, +35 lines: the strike ladder's and the beam window's rumble calls, the `stick_start` note to the hub, the web rumble shim): **a grant**.

Apply on a clean main: `git apply docs/controls/pending/landing/controls-landing.patch`. It replaces, once landed: `docs/controls/pending/{quick-read,stick-feel,queue-20,first-pad,beam-aim,stage-haptics}` and the stack's `controls-*` entries (`controls-layouts`, `controls-quick-read`, `controls-stick-feel`, `controls-queue-20` in tools/preview/stack.json, which also overlay the working tree's sim/input and layouts.json: both overlays then equal the commit).

## 2. `controls-switches-on.patch` (222 lines, 15 files): the switch values the page flips; apply LAST, after every other Controls park in `docs/controls/pending/`
`data/input/timing.json`: `rightStick`, `beamAim`, `quickRead`, `hapticLadder`, `hapticIncoming`, `hapticIncomingBeam`, `hapticRefused`, `specialsOff`, `signatureRtOnly`, `webRumble`, `stallKeep` and `hapticImpact` to true (the page's values plus the four the brief adds: `hapticIncomingBeam`, `stallKeep`, `hapticImpact` and `beamAim`; `driverOnRb` is left off, see below). Plus `SimInputData.pin_switches_off()` and one line in each of the 13 tests that check the old, off behaviour, so they run against off whatever the data says (they failed 7 to 9 checks each with the switches on, by design: for example they test that RT + X is the power special, which `specialsOff` changes). The order of the parks is **landing, stall-keep, impact-haptics, refusals, lt-take-back-claw (a test), dodge-held, then this** (re-cut on 2026-11-06 to apply after dodge-held, with `dodgeHeld` left off and pinned off in the old-behaviour checks); the chain was applied to clean base files and equals the tested tree byte for byte.

**Flipping it changes the golden.** With `rightStick` true alone the tick-0 state hash differs (parity.gd: seed 1, `fcd9129e1bea63ee` against golden `9640828030d86292`, first difference at value 178), because the state carries the right-stick fields. So flipping on main needs the golden regenerated (Simulation / the EP) in the same commit. With the landing patch alone (all off) parity passes unchanged.

## Tested (on a clean export of HEAD, Godot headless, below normal priority, at most 3 jobs)
| Tree | Result |
| :--- | :--- |
| Landing patch applied: all 29 input tests | all pass (the 5 new ones included) |
| Landing: `sim/core/tools/parity.gd` (golden, switches off) | **golden check passed** (byte-identical with the switches off) |
| Landing: `net/tools/word_check.gd` | passed, 620 checks |
| Landing: `net/tools/rollback_check.gd --right-stick` (LAN and a lossy profile) | PASS, 1,200 confirmed-tick hash comparisons, 0 failures |
| Landing: `node tools/lint-determinism.mjs`, `node tools/validate.js` (311 files, 0 errors, 1 old warning), `stack-selftest` | ok |
| Landing and the later parks, then the switches-on patch: all 33 input tests | all pass |
| The same tree: word_check, rollback_check --right-stick | pass |
| Landing + switches-on: parity.gd | **fails at the tick-0 state** (above) |
| The patch applied to clean base files gives the same bytes as the tested tree | yes (LF, compared byte for byte) |

## NEEDS FROM EP (the pieces that are not Controls')
- **The grant** for `render/core/main.gd` (Rendering's file, +35 lines, see above).
- **Golden regeneration** (Simulation / EP) in the commit that flips `rightStick`.
- **Encounter's and Combat's switch values the page also flips** (data/director/stick.json `lightStops` true to false; interrupts.json `stances`, `driver`, `blast.driver.enabled`; data/combat phrases.json and mixed.json `enabled`; the director's `swing`, `ending`, `follow`, `beamFront`, `struggle`, `vsHuman` and the rest of tools/preview/switches.mjs): not Controls' files. **`driverOnRb`** (mine, off here) must flip together with Encounter's driver park and `signatureRtOnly`, or RB + B stops being Y's blast with no Driver to read it.
- **Tools:** after the landing, `tools/preview/stack.json` loses its four `controls-*` parks and the switch rows for the landed switches read their values from main (`beamAim` and `hapticIncomingBeam` have no row yet).
- Nothing else of Encounter's is needed for the landing itself: the haptics and aim land with their cues unused until Encounter wires them.

## Not in it
`input-buffer` (off, the EP's call); the later jobs of the brief (stalls, the four more rumble kinds, refusals, the raw pad's right stick, the LT claw check) are separate parks cut on top of this one.
