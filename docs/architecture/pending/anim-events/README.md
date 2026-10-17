# Animation's view fields: a launch's tier, a hit's hit-stop and tier (parked build)

Owner: Simulation and Engine. 2026-10-17. What Animation asked of the sim's events (`docs/animation/ragdoll-physics-paper.md` section 5), **as view fields outside the hash, so no golden moves.** Built and proved in scratch; nothing is in the tree. Independent of `../forms/`: either order.

**Apply** from the repo root: `python docs/architecture/pending/anim-events/anim_events.py .` (no new class, no import needed).

| Asked | As built |
| :--- | :--- |
| `launch` `tier` | The `launch` event carries `tier`: the launch's power tier, the launcher's (1 to 4 today) |
| `hit_stop` `ticks` and `tier` | A hit's `damage` event (`SimDamage.hit`) carries `stop` (the hit-stop ticks in force after it, counted as `SimCore.step` spends them: the check plays them out and they match) and `tier` (the hitter's tier) |
| `air_brake` | **Not built: there is no air brake in the sim.** See below |

- **Why view fields and not new events.** The golden folds every tick's events, their types and their hashed fields, into each match's light digest. So a new event, or a new hashed field, moves the whole golden, though no state moves.
  - A view field (as the blow cue's `run` and `run_to`) is read by the views and not by the hash.
  - When a window regenerates the golden anyway, a `hit_stop` event of its own can replace the damage event's two fields at no extra cost.
- **The other hit-stops.** An impact, a brunt, a collision with a building and the director's interrupts freeze the fight too. They write `S.dirS.stop` themselves, seven writers in all.
  - The views read those from `S.dirS.stop` and each tick's `frozen` mark.
  - One `hit_stop` event for all of them is one function each writer calls, and it rides that regeneration.
- **The air brake.** Game Design's rule (`melee-press-feel.md` §12: LT, a hold brakes at 20 ki a second, a tap techs, the lock kept 20 ticks after a hit) has no code in the sim.
  - LT is now the manoeuvre stance's bit (`SimIntent.stanceMask` 8).
  - The flight it brakes is World's ground-contact journey and the core's free flight.
  - So `air_brake` needs a decision first: who builds the brake, and on which control. Then the event (phase, reason, speed, direction) comes with the rule.

| File | Change |
| :--- | :--- |
| `sim/core/state.gd` | `FxEvent.stop` (not hashed) |
| `sim/core/fx.gd` | The launch's `tier`; `SimFx.stopTicks` |
| `sim/core/damage.gd` | A hit sets its damage event's `stop` and `tier` |
| `sim/core/tools/parity.gd` | "Animation's view fields: a launch's tier, a hit's stop and tier" |
| `docs/architecture/fx-events.md` | The `damage` and `launch` rows |

**Proof:**
- Alone, on HEAD 1e06319b with the depth window: import clean; parity on the committed golden, unregenerated, **60 of 60**, the new check among them; the golden regenerated **byte-identical**.
- With `../forms/` on 70cf2fe6: parity **61 of 61**, the golden byte-identical, the full gates (in `../forms/README.md`).
