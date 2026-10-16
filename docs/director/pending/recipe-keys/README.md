# Combat's two recipe keys, read by the director (parked, 2026-10-16)

Owner: Encounter Systems Director. Combat's asks in `docs/combat/split-and-pieces.md`: the mash key (section 1, for `pending/split/recipes.split.json`) and the interjection's key (section 3). **Built and read in scratch on main 06b0200e. Not applied.**

## To build it

`node keys.cjs <root> mash` and `node keys.cjs <root> interject`, from this folder. `--check` reads every anchor and writes nothing; any other option or step is refused.

| Step | File | Change | Lands with |
| :--- | :--- | :--- | :--- |
| `mash` | `sim/director/brawl.gd` | `_mashCell`, Combat's `_mashCell` stand-in. A mashed medium or heavy (a press inside the gap that makes it a flurry) draws on `mediumMash` or `heavyMash` when the recipes name it, else on the tap's cell. Not a launcher, not an energy blow | Combat's `recipes.split.json` and Tools' two schema keys, in one commit |
| `interject` | `sim/director/ring.gd` (stage 3) | `_piece`: the ring beat carries a piece from the recipes' `interject` (a light) or `interjectMedium` (a medium; `interject` when there is none), under the brawl's own rules. The interjection's wind-up cue names its cell in `source` (`x` or `y`), as the agreed cue list has it (`../return/cues.md`) | After stage 3, and Combat's `interject` pool when it is built |

## What it read

**The mash key** (`probes/keys1.gd`). A scripted player taps Y every 12 ticks or B every 28 against the medium AI, 3 matches. Every blow is sorted by the cells whose pool holds its piece.

| Build | Mashed Y | Mashed B |
| :--- | :--- | :--- |
| Main with the key, today's recipes | The tap's pool, as before. **The golden is main's byte for byte** | The tap's pool, as before |
| Main with Combat's split, no key | 554 of 554 from the stop (`medium`): the grind is never thrown | Mixed: the held B's pool and the advance |
| **Main with Combat's split and the key** | **554 of 554 from the grind (`mediumMash`)** | **257 of 257 from the advance (`heavyMash`)** |

The taps are untouched: a tapped Y throws the stop, and a tapped B any heavy.

**The interject key** (`probes/keys2.gd`). Stages 2 and 3 applied on main 06b0200e: both scripts ran clean and the validator passed. Then the AI on three bodies, 3 matches.

| Build | Ring beats | With a piece | The wind-up cue's `source` |
| :--- | ---: | ---: | :--- |
| Stage 3 | 32 | 0 | `""` |
| Stage 3 and the key, no recipes key | 32 | 0 | `x` |
| Stage 3 and the key, the recipes' `interject` pointed at the light pool for the test | 32 | **32** | `x` |

With no recipes key, the only change is the cue's cell. Combat's pool of the guard's lights (section 3: nine lights on a line or an arc in) is the recipes key's value once it is built.

## Open

- **For Tools:** `mediumMash` and `heavyMash` under `brawl`, and in `fallback.lower`'s names, in `combat-recipes.schema.json` (Combat's section 1). Later, `interject` and `interjectMedium`.
- **For Combat:** the `interject` pool, and `interjectMedium` if a medium interjection should drop from above.
