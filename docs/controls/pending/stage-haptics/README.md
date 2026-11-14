# stage-haptics: the charge stages and the throw, felt on the pad (Controls, 2026-11-01)

The EP's word: build the release thump and the stage scaling in `haptics.gd` behind `switches.hapticLadder`, soft and chunky. Reasoning in `docs/controls/beam-aim-feel.md` section 5.

## What it adds (all behind switches.hapticLadder, off; off plays nothing new)
- **`release_thump`** (a new kind): one low push (strong 0.65, weak 0.10, 40 ms) and a short roll-off (strong 0.25, 30 ms). Nothing brighter than a thud. The thrower's pad, on the tick the stick falls and the strike is thrown, scaled by the charge reached (level 1 to 3: 0.6, 0.8, 1.0 of the data). A quick flick (level 0) throws none, so a mashed strike never buzzes. A cancelled charge throws none.
- **`SimHaptics.stage_requests(slot, n, of)`** for UI's `charge_stage` cue (`docs/ui/charge-stages.md`; the host calls it when the cue exists): stage 1 is the tick (`ladder_1`), the last stage the thud with its ring (`ladder_3`), those between the knock (`ladder_2`) rising from 0.7 to 1.0 of its strength. A two-stage charge is tick then thud; a six-stage one is tick, four knocks, thud. No knock is as heavy as the thud, so a long charge climbs without anything louder than the top.
- The strike's own three rungs already ring through `ladder_requests`, unchanged; the thump follows the throw.

## Files
`stage-haptics.patch`: `sim/input/haptics.gd` (+29), `hub.gd` (+3, the thump on the release edge), `test/stage_haptics_test.gd` (30 checks), and two test edits (`haptics_test.gd`: sixteen kinds; `stick_feel_test.gd`: the ladder test now expects the thump after the third rung, on the tick the stick falls). No data keys (the kind's numbers are defaults in code, overridable under `haptics.release_thump` like every kind).

Apply after `stick-feel.patch`, `first-press.patch`, `haptic-switches.patch` (the test edits sit on lines they leave); independent of `beam-aim` and `first-pad`. `git apply docs/controls/pending/stage-haptics/stage-haptics.patch`.

## Checked
stage_haptics_test 30 of 30; the whole input suite (29 tests) passes on the full stack; determinism lint ok; validate 0 errors. With the switch off the stages and the thump are empty and a whole charge and throw play nothing.

## Not in it
No continuous rumble while the thumb aims (a hypothesis to test against the no-rumble baseline); a heartbeat at the top stage; the host's call of `stage_requests` on UI's cue (two lines in `render/core/main.gd`, Rendering's file, when the cue exists).
