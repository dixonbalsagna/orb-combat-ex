# The beam struggle as a tug of war on the pulse (parked, 2026-10-16)

Owner: Encounter Systems Director. Game Design's redesign (`docs/design/rule-of-cool.md` section 2, the eleventh round item 2), after Orb's playtest: "it felt like the winner of the beam struggle was determined as soon as the beams were fired and that nothing I pressed during it could affect the outcome."

That was true. On main the clash's winner is drawn from state and a random term when the beams meet, and it lasts a fixed 1.6 s. **Built and read in scratch on main 0ee9cb6b. Not applied.**

## To build it

`node bs.cjs <root>` from this folder, then regenerate the golden. `--check` reads every anchor and writes nothing; any other option is refused.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/beam.gd` | Encounter | The struggle: `_startStruggle`, `clashTick`, `clashPress`, `_press`, `_resolveStruggle` |
| `sim/director/exchange.gd` | Encounter | A player's press in a clash is scored (`requestAttack`); the struggle's tick |
| `data/director/interrupts.json` | Encounter | `beamStruggle`, every number Game Design named. `enabled` false is the clash as before |
| `tools/schemas/director-interrupts.schema.json` | **Tools** | `beamStruggle` |
| `sim/core/state.gd` | **Simulation** | One field, `Clash.mid`: the meeting point, 0 at A's hands to 1 at D's. -1 for a clash with no struggle |
| `sim/core/hash.gd` | **Simulation** | `mid` hashed while a struggle holds it. A clash with no struggle hashes as before |
| `sim/core/sim.gd` | **Simulation** | The clash's sparks at `mid` when there is one, else the old glide |
| `render/core/beam_view.gd` | **Rendering** | The two beams meet at `mid` when there is one, else the old glide |

**With `enabled` false, the golden is main's byte for byte.** With it on, 9 cases move.

## As built (every number is data)

- **The meeting point.**
  - It starts in the middle, moved toward the weaker side by state: 0.005 of the line for each point of power (tier × 10, ki × 0.35, menace and flow, as the old score had them, with no draw), at most 15%.
  - An answering heavy blast still starts 10 points down.
- **The pulse.** One every 20 ticks, 15 of them. Each sends a `beam_pulse` cue (`k` the pulse, `n` its tick).
- **A surge.** Any face button within 4 ticks of a pulse moves the point 10% toward the rival; within 1 tick, 15%. One surge a pulse for each fighter. Cue `beam_surge` (text `surge` or `sharp`).
- **A stray.** Any other press moves the point 5% back toward himself. Cue `beam_stray`.
- **The comeback.** Within the quarter of the line nearest his own hands, a surge is ×1.5.
- **The AI.**
  - It hits 40%, 65% or 85% of pulses by level, pressing 2 or 3 ticks off the pulse, so never a sharp surge.
  - Its presses are drawn when the struggle starts (keyed draws). Its other presses during a clash are spent unscored, as before.
- **The end.**
  - **The point reaches a fighter:** he is overwhelmed. He takes the winner's beam and half of his own, and is launched along the beam's line, which carves by the winner's tier. It counts as the clash's launch, as before.
  - **On time within 10% of the middle:** the beams detonate where they meet. Each takes a quarter of the other's beam, both are knocked back, and the ground there craters by the higher tier.
  - **On time further over:** the side the point is on takes half the beam, with no launch.
  - Each end sends a `beam_end` cue (text `overwhelmed`, `detonate` or `time`; `x` the point).
- **The stick** leaning in is the renderers' to draw. It adds nothing to the point.
- **For the views:** `S.game.clash.mid` each tick, and the cues above. `beam_struggle` (text `start`) opens it, with `n` the tick it ends by at the latest.

## What it read

`probes/bs1.gd`, against medium; seeds from 1.

**The AI on both sides** (20 matches, 64 struggles):

| Game Design's row | Bound | Read |
| :--- | :--- | :--- |
| The one with more surges wins, head start under 10% | At least 80% | **42 of 42** |
| The point crosses the middle | At least 25% | **52 of 64 (81%)** |
| Won from behind (more than 10% down at some point) | At least 15% | **9 of 64 (14%)**; 9 of 43 that ended with a winner (21%) |
| How they end | | 39 on time, 21 detonations, 4 overwhelmed; median 305 ticks |

**A scripted player against the AI** (30 matches a mode):

| The player | Struggles | Won | How | Median length |
| :--- | ---: | ---: | :--- | ---: |
| Presses nothing | 33 | 0 | Overwhelmed every time | 124 ticks |
| On the beat (the tick after the pulse: a sharp surge) | 35 | **35** | 34 overwhelmed, 1 on time | 183 ticks |
| 3 ticks late (a surge) | 38 | **38** | 9 overwhelmed, 29 on time | 305 ticks |
| Mashes (every 3 ticks) | 31 | 0 | 30 overwhelmed | **35 ticks** |

- **The struggle is decided by the presses now.** Keeping the beat always beats medium, and not pressing always loses.
- **"A player who keeps the beat usually overwhelms the medium AI before time runs out" needs 1-tick timing.** 3 ticks off, he still wins every time, but mostly on time.
- **The masher wins no more often than a fighter who doesn't press (0 and 0), but he loses about four times faster.** At 20 presses a second most of his presses are strays: about ten in a struggle that lasts a little over half a second.

## Open

- **For Game Design.**
  - Mashing is much worse than not pressing, where the rule says "no better". If it should be about equal, one lever is to count at most one stray between two pulses.
  - "Won from behind" reads 14% against 15%.
  - The 3-ticks-late player overwhelms medium only 9 times in 38.
- **Grants:** Simulation's three lines and Rendering's one, in the table above.
- **For VFX, Camera, Audio and UI:** `clash.mid` and the cues `beam_struggle`, `beam_pulse`, `beam_surge`, `beam_stray` and `beam_end`, for the bulge, the tightening camera, the beat and the rising sound Game Design describes.

## Gates

- The full gate list, 35 of 35, on main 0ee9cb6b with the park applied and the golden regenerated.
- Play changes in all 9 golden matches (their light digests), since most matches hold a beam clash.
- Wounds, rally, cripple, mood, keyed, `rosterHash` and `fightHash` are unchanged.
- With `enabled` false the golden is main's byte for byte.
