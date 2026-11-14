# The charge's stages on the pad (Controls, 2026-11-07; for Encounter, Rendering, Tools and Audio)

Before: the pad's charge rumble was the hub's own three rungs of the stick reader (a tick, a knock, a thud at 12, 28 and 46 ticks after `push-stick`'s re-cut, 12, 30, 54 before), whatever the fighter's real stages. A base fighter has two stages (the second at 28), a top fighter six (12, 28, 46, 66, 90, 120); stages 4 to 6 had no pulse and a base fighter felt a third thud for a stage it did not have. Now the pad is told **each stage the director reaches**, from Encounter's cue `stick_stage` (beam-move; strike-stages gives plain charged blows the same cue).

## What it does (`switches.hapticStages`, off; needs `hapticLadder` and `rightStick`)
| | |
| :--- | :--- |
| **The pulse** | One per stage, by the existing `SimHaptics.stage_requests(slot, k, n)`: stage 1 the tick (`ladder_1`), the last stage (k = n) the thud (`ladder_3`), those between the knock (`ladder_2`) rising from 0.7 to 1.0 of its strength. **A base fighter's two stages are the tick and the thud, and no more**; three stages are the old ladder; six climb |
| **Where it comes from** | `SimHaptics.event_requests(e)` on the event `cue` / `stick_stage` (actor the charger, `k` the stage, `n` the count, source "capped"). `main.gd`'s `_haptics_from_events` already hands every event to `event_requests`, so **no host line is needed** |
| **Capped** | The cue's source "capped" (what he can pay stopped the climb) is the knock of a press that went nowhere: `stick_refused` at 0.6, and no stage pulse. This is the "capped knock nothing consumed" of the morning review |
| **A step down** | Says nothing (k under the last stage told). Climbing back to a stage told before is told again. A first stage is always a new charge and always ticks |
| **The hub's rungs** | With `hapticStages` on the hub's own ladder pulses step aside (`SimInputHub._note_ladder`), so a stage is never felt twice. The **release thump stays** (from the reader's level, 0.4 to 1.0 by rung; not yet by stage: `stick_release`'s level is the reader's) |
| **Independent of** | `hapticImpact` (its own switch). Presentation only: the only state is the last stage each pad was told (`SimHaptics._stage_last`), never read by the sim |

## Switch it with beam-move and strike-stages
No cue comes with beam-move off, so a hold would be silent with `hapticStages` on. Tools' page row: `{ id: 'hapticStages', file: 'data/input/timing.json', path: ['switches', 'hapticStages'], from: false, to: true, needs: ['beamMove'] }`, flipped after the beam-move page row.

## Proof
- `stage_cue_test.gd` (25 checks, new): a base fighter's two stages tick and thud; six stages tick, four climbing knocks (0.7 to 1.0, none over the thud), thud; three are the old ladder; one is the thud; a step down is quiet and the climb back is told; capped is the 0.6 knock; a new charge ticks; the other pad's stage is its own; out-of-range cues are nothing; each of `hapticStages`, `hapticLadder` and `rightStick` off silences it; `hapticImpact` off does not; other events as before; through the hub, a held stick is silent but for the throw's thump with it on and the old three rungs with it off.
- `sim/input/tools/stage_pulse_probe.gd` (`stage-pulse-probe.patch`, needs Encounter's beam-move stack): **real cues from a held beam charge**: a base fighter (tier 1) is told `ladder_1`, `ladder_3` at 0 and 16 ticks after the first; a top fighter (tier 4, full power) six pulses at 0, 16, 34, 54, 78, 108 (the stages 12, 28, 46, 66, 90, 120); a top fighter with 20 energy is told two pulses, then the capped knock, and never the thud.
- All 36 input tests pass on HEAD + switches-on + push-stick + this; lint and validate clean; the patches applied to clean base files give the tested tree byte for byte.

## Left
- The release thump by stage (not the reader's three rungs) needs the stage at the throw; `stick_release` carries the reader's level. Say if you want it.
- Audio's `charge.tick.light` ladder reads the same cue, so sound and pad climb together.
