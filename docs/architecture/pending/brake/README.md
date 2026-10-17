# The air brake (parked build, ready to apply)

Owner: Simulation and Engine. 2026-10-17. The build of `../../brake-core.md`: Game Design's air brake (`docs/design/buildings.md` section 7.2) and Animation's `air_brake` event. **Built and proved in scratch; nothing is in the tree.** Behind `data/fight/brake.json` `enabled` (false): with it off, every match, replay and checkpoint is the same to the bit.

## To apply

From the repo root, then an import (`SimBrake` is a new class):

1. `python docs/architecture/pending/brake/brake.py .` (Simulation's files).
2. `python docs/architecture/pending/brake/grant_world.py .`: one function in World's `sim/world/contact.gd` (`brakeEnd`), for World to apply or grant. The brake calls it only while on.

It applies before or after `../forms/forms.py`.

| File | Change |
| :--- | :--- |
| NEW `sim/core/brake.gd` | `SimBrake`: the data, the start window, the tick, the event, control back |
| NEW `data/fight/brake.json` | The switch (off) and the numbers |
| `sim/core/state.gd` | `S.brakeOn`, `BrakeState`, `Fighter.brk` |
| `sim/core/sim.gd` | The switch and each fighter's brake state in `newMatch` |
| `sim/core/hash.gd` | `BrakeState` hashed only while the brake is on; the event's fields |
| `sim/core/fighter.gd` | `SimBrake.tick` at the top of `stepFighter` |
| `sim/core/replay.gd` | The brake's data in a replay's data hash, only with it on |
| `sim/core/fx.gd`, `view/fx.gd` | `air_brake` |
| `sim/core/tools/parity.gd` | "the air brake" |
| `docs/architecture/fx-events.md` | The event's row |
| World's `sim/world/contact.gd` (grant) | `brakeEnd`: a journey ended by the brake (`journey_end`, kind brake) |

## Proof (scratch, below-normal priority)

| Run | Base | Result |
| :--- | :--- | :--- |
| `brake.py` and World's function | HEAD ff68e994 | Import clean. Parity on the committed golden, unregenerated, **61 of 61**, no script error, the new check among them. The golden regenerated **byte-identical** |
| With `../forms/` and Encounter's grant, all four together | HEAD ff68e994 | Parity **62 of 62**; the golden **byte-identical** |
| The full gates, on that export | | npm 5 of 5; parity 62 of 62; determinism plain and with `--intro --seeds=2 --ticks=900` passed; seam passed; flash_worst 76 runs and check-log passed; validate 196 files, 0 errors and 3 warnings (the three new data files have no schema yet: Tools'); self-test 7545 of 7545; QA's run-all 7 of 7; the loader check passed; flash self-test 88 |
| Rendering's 15 checks, on that export | | **All 15 passed** (`depth_check` with Rendering's fix, a977a63c). `cue_check` passes with the 650 script-error lines main has too |

**The brake on, in live play** (`probe/brake_probe.gd`, a scratch probe; `probe/sends_probe.gd` measured the send speeds behind the data's first values):
- **One scripted send** of own speed 2,400 (power 0.48), so the window is 8 ticks:
  - it started on tick 8 and slowed him every tick;
  - he was back in control on tick 18, after 10 ticks of braking (0.17 s), at 763, under the third of 2,400 (800);
  - it cost 3.25 ki, and World's `journey_end` said brake.
- **Four AI matches of 7,200 ticks** with slot 1 holding the brake throughout: 5 to 7 sends to him, 2 to 5 brakes, most ending in control back (speed) and a few on the ground; 6 to 15 ticks a brake. Each match played the same twice.

## For the others

| Who | What |
| :--- | :--- |
| Controls | Guard held while sent sets `stanceMask` 8 on Simple and touch |
| Encounter | The AI's use (20, 50 and 80% by level); marking finishers and crippling blows alone, if the set-piece rule should narrow; `BrakeState.marks` when launch-anywhere's marks exist |
| World | `grant_world.py` |
| Tools | A schema for `data/fight/brake.json` |
| Game Design | `fullSpeed` (5,000) and `hardSpeed` (7,000), Simulation's first values from measured sends |
