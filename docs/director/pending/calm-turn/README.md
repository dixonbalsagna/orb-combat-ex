# The calm-moment turn, the director's part (parked, 2026-10-22)

Owner: Encounter Systems Director. `DirCalm`, wired to World's window 3 (`WorldEpoch`, parked in `docs/world/scratch-build/calm-turn/`). It follows my `../../calm-turn.md`, Game Design's `rulings-2026-10-19b.md` §1 with 1e, and Rendering's warm-up input.
- **It sits behind `calmTurn.enabled` (false)** in `data/director/interrupts.json`, and behind World's own switch. With either off nothing runs, and the golden doesn't move.
- **Built and read in scratch on window 3. Not applied.**

## To build it

On main plus World's window 3:
1. `node ct.cjs <root>` from this folder;
2. with World's OK, `node grant_world.cjs <root>`;
3. with Simulation's OK, `node grant_sim.cjs <root>`.

`--check` reads every anchor and writes nothing. It composes with the hit-weights and camera-intent v3 parks.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/calm.gd` | Encounter | New: `DirCalm`. `atSend` (the ask and the pick), `pick`, `hold`, `why` (the hold's reason, for probes), `warmRate`, `warmTicks` |
| `sim/director/melee.gd` | Encounter | `DirCalm.atSend` after the send |
| `data/director/interrupts.json`, `tools/schemas/director-interrupts.schema.json` (**Tools'**) | Encounter | `calmTurn` |
| `sim/world/epoch.gd` | **World** (`grant_world.cjs`) | `choose` records the pick's `tick` and its `due`; `cancel(S)` drops a pick still waiting. Neither is hashed |
| `sim/core/sim.gd` | **Simulation** (`grant_sim.cjs`) | `WorldEpoch.tick(S, DirCalm.hold(S))` |

## The rules as built

- **The ask, at a launch's send.** It pivots on the predicted rest point, on the side the send went, and the pick is made at once. A new send cancels a pick still waiting and asks again for its own landing.
- **The warm-up** (Rendering's, as the EP agreed). The host is asked to warm the picked ring fast enough to have it by the landing: from `warmCols` 16 to `warmColsMax` 64 columns a frame, carried by the `calm_turn` cue's `k`. The swap waits the ring's columns over that rate, in ticks, since the pick. It's the same in any replay.
- **The hold**, all of these at once:
  - the ring warm;
  - the sent fighter within `pivotSlack` 3,000 of the pivot (World keeps that ground exactly);
  - the other within `otherSlack` 12,000 (World's carry zone, where the ground fades);
  - a fighter at rest from a send within `landedTicks` 30, and both down or set (under 60 u/s);
  - no exchange, approach, beam clash, taunt, flip or counter-rush, no waiting attack, no open finisher.

  World then adds its own calm check and swaps.
- **The pick.** Each place a candidate brings into view scores: a rival's home 5, a landmark 4, a city 3, his own home 2, a town 1. A tie goes to the smaller bearing. The planet has only cities and towns yet.
- **Not here yet:** a form step's pause, and a set piece's cutaway (World's calm refuses an open set piece).

## What it read (main 8bc3e562 plus window 3, in scratch; 6 AI matches on planet 7, the Whole ring, about 20 minutes)

| Read | Result |
| :--- | :--- |
| Picks | 23; the rate asked was 64 columns a frame for 18 of them |
| Turns | **1**: 2.5 degrees, both fighters set (one down), nothing in flight, no press waiting. **No bad swap** |
| Picks still waiting at the end | 4 of 6 matches |
| Why the hold was off, in the 30 ticks after a landing | off pivot 611, moving 257, warming 157, exchange 28; it held 37 |
| With `calmTurn` off | no ask |

**Turns are rare in AI v AI, and why.**
- World pins the pivot at the ask, and the ask must come the warm time before the swap. The only early moment is the send, so the pivot is a prediction: the sent body's rest is a median 3,600 units off it.
- The pair is often 4,000 to 7,500 apart at the landing, and the AI re-engages within 20 to 45 ticks of it.

The levers are Game Design's and World's:
- a longer settle (`landedTicks`);
- a wider exact zone;
- a pivot fixed at the swap, which needs a read at the swap, so a hitch;
- a calmer moment type, such as a breath after a knock-back.

Human players may leave more calm moments; that isn't read here.

- **Off:** the gate list is running; its result goes in the report.

## Probe (`probes/ctp.gd`, from a copy's root, with window 3)

`ctp.gd -- <matches> <seed0> [--ticks=14400] [--off]`: asks, turns, the state at each swap, the hold's reasons.
