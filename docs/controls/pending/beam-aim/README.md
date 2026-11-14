# beam-aim: the beam's aim holds, and the throw carries it (Controls, 2026-11-01)

Orb's order: beam aiming that feels "really responsive and engaging", with charge stages on a hold and a timed release. The reasoning and Orb's thumb data (counts only) are in `docs/controls/beam-aim-feel.md`.

## What it does (switches.beamAim, off; off is byte-identical)
- **The throw carries the aim.** The stick springs home in under a tick once the thumb lifts, so the old reader's aim on the release step was the stick at rest: 0, which reads as "right". Now the release step carries the sector of the mean of the last 3 rim ticks (a tick is the rim when its deflection is 85% of the hold's peak or more). A flick shorter than the settle takes the peak of its arc.
- **The shown aim trails the thumb.** While the stick is held it moves only once the stick is more than 4 degrees from it, then stays 4 behind. A thumb that holds still no longer walks the 32-way sector; a real re-aim is followed within the 4 degrees.
- **At rest the aim is 0**, so the spring-back bounce (17 of 41 of Orb's holds) is never read.

## Files
| File | What |
| :--- | :--- |
| `beam-aim.patch` | `sim/input/strike_read.gd` (+69), `input_data.gd` (`beam_aim_on()`), `data/input/timing.json` (`switches.beamAim` false; `strike.aimTrail` 4, `aimLatchTicks` 3, `aimLatchPeak` 0.85), `tools/schemas/input-timing.schema.json`, `sim/input/test/beam_aim_test.gd` (31 checks), `sim/input/tools/orb_aim_probe.gd` (reads Orb's private file by path, prints counts only) |

Apply: `git apply docs/controls/pending/beam-aim/beam-aim.patch`, **after** `quick-read`, `stick-feel`, `responsive-2`, `first-press`, `haptic-switches` (it is built on the full stack; its anchors are lines those parks add). Independent of `first-pad`.

## Checked
Beam-aim test 31 of 31; whole input suite (28) passes on the stack; `node tools/lint-determinism.mjs` ok; `node tools/validate.js` 300 files, 0 errors. Orb's samples through the real reader (the plain reader, 103 pushes): off 92 throws carry aim 0 and the median error against the held direction is 154 degrees; on, 1 carries 0 and the error is 4.2 degrees (median), 7.2 (ninetieth).

## Not in it
Nothing reads `rsAim` yet except the record: the director's arm and the beam's elevation following it are Encounter's. The release thump and the stage scaling of the ladder pulses wait for the EP's word.
