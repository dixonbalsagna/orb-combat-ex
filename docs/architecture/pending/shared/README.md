# shared: Encounter's three asks (parked)

Owner: Simulation and Engine. 2026-10-22. Encounter's asks in the EP's brief of 2026-10-22, all neutral: no golden moves, no switch. The page is `../../feel-core.md` section 6.

- **(b) The launch curve as shared functions,** for the planner (`DirLaunch.predictFlight`) and World's predictors (`WorldBrunt.flightTo`, `chainPlan`, `next`): `SimFlight.share`, `kOf`, `toFloor`, a `Track` stepped by `tick` with the flight's own arithmetic, and `predict` to the touchdown. The live step calls the same functions.
- **(a) `SimBrake.controlBack(S, f)`,** the brake's control back under a public name, for the recoil flip with ground contact off (Encounter's `recoil.gd` calls `_control` today).
- **(c) A `cam_intent` cue is left out of the light digest** (`SimHash.hashFx`), so switching the camera feed on moves no golden.

## Apply

On a clean export of 4d2f568b or later, from the repo root: `python docs/architecture/pending/shared/shared.py .`

No grants. Apply it before Encounter's recoil-flips park, which then calls `SimBrake.controlBack` in place of `SimBrake._control` (one word in `recoil.gd`).

## What it changes

- `sim/core/flight.gd`: the shared functions and the `Track`; `pace` and `toContact` call them.
- `sim/core/brake.gd`: `controlBack`.
- `sim/core/hash.gd`: `hashFx` skips a `cue` of kind `cam_intent`.
- `sim/core/tools/parity.gd`: one check.
- `docs/architecture/fx-events.md`: the `cue` row says so.

## Results (scratch, on 4d2f568b)

- Alone: import clean, parity on the committed golden 67 of 67, golden byte-identical.
- With `brake2/` and `boons/` (and their grants): parity 68 of 68, golden byte-identical; the full gates (npm 5 of 5, determinism and its intro, seam, the flash count, the validator 0 and 0, the self-test 8,577 of 8,577, QA's run-all, the loader, the flash self-test) and all 15 of Rendering's checks pass.
- The check:
  - for a shallow and a steep send, the track equals the live flight to the bit every tick;
  - `predict` names the touchdown tick;
  - `controlBack` ends a flight;
  - a `cam_intent` cue leaves the digest and another cue moves it;
  - one AI match of 2,400 ticks run twice with the feed on gives the same cues on the same ticks and the same play.
