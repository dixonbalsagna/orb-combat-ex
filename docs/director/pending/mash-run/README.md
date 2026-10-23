# A mash's later blows flow (parked, 2026-10-22)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-22.md` 6 (b) and 7d, on Simulation's mash-flow (`docs/architecture/pending/mash-flow/`: `light_flow`, 0 ticks, never raised by the budget's floor). Only while hit-stop by weight is on (`S.hitstopOn`; `data/fight/hitstop.json`, off): off, nothing is written and the slot is never sized, so the golden doesn't move.

## To build it

On main (hit-weights-5b is on it) with Simulation's mash-flow and Tools' grant, in one commit: `node mr.cjs <root>` from this folder. Without Simulation's park an unknown weight falls back to the hit's own stop, so the two go together. `--check` reads every anchor and writes nothing. The 7a park (`../press-wait/`) applies after it: its slot follows this one's.

| File | Change |
| :--- | :--- |
| `sim/director/mash.gd` (+ `.uid`) | New: `DirMash.name(S, f, w)`, a mash's later blow `light_flow` |
| `sim/director/brawl.gd` | The brawl's strike names `DirMash.name(S, f, weightOf(a))` |
| `data/director/interrupts.json`, `tools/schemas/director-interrupts.schema.json` (**Tools'**) | `mash` {`flowGapTicks` 12} |

## The rule as built

- A mash is a run of one fighter's mashed or burst blows: a brawl blow that names `light_mash` (a flurry's, a held pace's, a burst's). Each lands within `flowGapTicks` (12) live ticks of his last; the run starts again after 12 without one.
- The first blow keeps `light_mash` (2 ticks). Each later one names `light_flow`, which holds no stop.
- Every other blow keeps its table stop.
- State: one `f.act.dirI` slot after the recoil flips', the live tick of his last mashed or burst blow.

## What it read (main 73a7df95 plus mash-flow, this and 7a, in scratch; 10 AI matches of 3 minutes, 108,000 ticks, hit-stop by weight on)

| | Hit-stop share of all ticks | 10 s blocks over 18% | Worst block | Longest stop |
| :--- | :--- | :--- | :--- | :--- |
| hit-weights-5b alone (2026-10-22) | 20.2% | 96 of 136 | 298 frozen to 600 live | 30 |
| **with the mash flow** | **12.6%** | 44 of 150 | **164 to 600, 21.5% of the block** | 12 |

- 5,541 later mash blows flowed with no stop; 2,190 first blows held 2.
- **GD's 7d hard row** (no 10 s block over 40% frozen) **passes**: the worst is 21.5%.
- **Gate list** on that copy: 35 of 35 at 0. The golden's nine AI matches are byte-identical. Its two human replays moved, from 7a in the same copy; this park writes nothing with hit-stop off.

## Probe (`probes/hwp.gd`, from a copy's root)

`hwp.gd -- <matches> <seed0> [--off]`. It reads:
- the hit-stop, pause and other shares;
- the 10 s blocks over 18% and the worst block;
- the longest stop;
- each damage event's stop.
