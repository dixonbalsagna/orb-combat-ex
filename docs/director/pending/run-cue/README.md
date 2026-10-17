# UI's run on the blow cue (parked, 2026-10-16)

Owner: Encounter Systems Director. UI's ask (`docs/ui/brawl-teaching.md` section 3), on Simulation's two `FxEvent` fields (8cac4e1b). The twelfth round's launch marks wait on it: the run's pips, the full gauge and the first-time hint stay dark until it lands. **Built and read in scratch on main 79a0941e. Not applied.**

## To build it

`node rc.cjs <root>` from this folder. It refuses until `FxEvent` has `run_to`. `--check` reads every anchor and writes nothing; any other option is refused. It applies to main as it is, and after window 1 (the return fix and the launcher window). Neither field is hashed, so the golden doesn't move.

| File | Change |
| :--- | :--- |
| `sim/director/brawl.gd` | `_runCue`, on the brawl's four `blow` cues: a press's blow, a blow by rule (a zip's), the reversal's medium, and a wound blow's release (which also gains its `target`) |

## The fields

- **`run`:** the striker's run on the target as the blow is thrown, in whole points, 0 to `run_to`. It reads `run_to` when his next light that lands is the close, after a trade he won too.
- **`run_to`:** the run at which his next light closes (`runToClose`, 4 today). UI's gauge is full when `run` reaches it.
- This is the meaning UI's code already reads (`ui_event_hub.gd`: full when `run` ≥ `run_to`). The cue list first said "the blows still to land", and is corrected (`../return/cues.md`).

## What it read

On main 79a0941e with the script: **the golden is main's, byte for byte.**

`probes/rcp.gd`, the AI on both sides, 3 matches:

| Row | Read |
| :--- | :--- |
| Blow cues carrying a run | 5,051 of 5,051, every one with `run_to` 4 |
| By `run` | 0: 2,114; 1: 2,403; 2: 399; 3: 97; 4: 38 |
| Flurry closes whose striker's last blow cue read the gauge full | 22 of 24 |

The two closes that came without a full gauge are most likely a run that filled while that blow was already on its way: its cue was sent at the throw.
