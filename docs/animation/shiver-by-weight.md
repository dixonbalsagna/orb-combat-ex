# The shake by weight (Animation, 2026-10-22)

Owner: Animation. Parked as `docs/animation/pending/shiver-by-weight.patch` (render side only; applies on main with the recoil flips). Asked for by the EP after rulings-2026-10-22 5b and section 6: a mashed light must not shake like a launch, and a blow that flows with no hit-stop still shows a shake on the struck body.

## What changes

- **The stop's shake follows its weight.** Until now every hit-stop shook both bodies by the profile's one amount (`shiver` 0.9 units for the snappy profile, 0.4 for the fluid), whatever the stop's length. The body now reads the longest stop of the freeze (render only, from `S.dirS.stop`) and scales the shake by `sqrt(ticks / 8)`, between 0.5 and 1.6:

  | Stop (GD's table) | Ticks | Shake, as a share of the old one |
  | :--- | ---: | ---: |
  | a mashed light | 2 | 0.50 |
  | a tapped light | 3 | 0.61 |
  | a medium | 5 | 0.79 |
  | a heavy | 8 | 1.00 (as before) |
  | a launch or a close | 12 | 1.22 |
  | a full launch | 14 | 1.32 |
  | a decisive blow | 20 | 1.58 |
  | the KO | 24 | 1.6 |

- **A blow that flows with no stop of its own** (a mash's later blows, GD section 6) shakes the struck body for 6 ticks, drawn only, decaying: 0.3 to 0.7 of the profile's shake by the blow's weight (a light about 0.4). It follows the contact event (the damage event's `stop` field is 0), not the stop. A guarded blow, and a blow that has a stop of its own, add nothing past the stop.
- Nothing moves in the sim: the shake is an offset of the drawn root, rebuilt every frame as before.
- `RenderAnim.shiver_by_weight`, `--no-shiver-weight` (the study's `window.__noshiver = 1`) is the before.

## Tests and gates

`_test_shake` in `anim_check`: the stop's shake against its weight (2 ticks 0.4 to 0.62 of the 8-tick one, 24 ticks at least 1.4, rising with the stop), a flowing light's shake small but there and gone by tick 10, and none for a guard or a blow with its own stop. On a scratch export of main with the recoil flips: `anim_check` with no arguments passes, joint, lead, held and guard scans `--strict`, the 4-body lead and joint scans, and determinism plain and `--intro`.

A trap met on the way, worth knowing: the shake is the one writer of `root_off` that starts the frame from zero (`root_off = root_off * 0.0` in the else). Anything inserted between that `if` and its `else` takes the `else` over and the root offsets pile up across frames (seven `anim_check` rows went red, 32 units of drift in a held beat).

## The wind-up cue's tolerance: nothing to widen

GD asked for `_cue_windup`'s 4-tick tolerance to be widened to 8, on the thought that a hit-stop's frozen ticks shift a blow's landing from the wind-up cue's. I measured it instead: a scratch counter on `_cue_windup` over AI v AI on seeds 12345, 4, 7 and 21 (2,400 ticks each, 331 wind-up cues in all) found every cue attached to its blow within the 4 ticks: 0 misses. So a stop does not shift the landing (the cue's tick and the clock stay together through it) and the tolerance stays at 4. A frozen-tick correction I tried then made it worse (6 cues of 331 pushed out of the window on seed 12345), so it is not in the patch. Widening to 8 would also match a neighbouring light in a mash (lights come every 4 to 6 ticks), so not that either.
