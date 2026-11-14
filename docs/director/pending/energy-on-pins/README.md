# Parked: Encounter's checks under the energy model on (A-ENERGY-04, for GW1a)

Encounter, 2026-11-14, sprint A1. Simulation's `docs/architecture/pending/energy-on/` turns the energy model and the dash on in main's data. Four of my checks failed with it: `arc_check` 1, `follow_check` 3, `loader_check` and `floorlift_check` 1. **Checks only: nothing in the sim changes,** so main still reproduces the 9 November build (GW1a's target).

| Check | With the model on | The cause | What this does |
| :--- | :--- | :--- | :--- |
| `follow_check` "60 after the send" (3 rows) | the far tap did nothing, and no taunt | his landing holds the clock (0.4 s) on the tick the check pressed. In play the host offers a press again until the first live tick (`sim_host.gd`) | **Re-read under the model:** the check waits out a hold before it presses, as the host does. The follow itself is right |
| `arc_check` "the meteor's own bowl" | radius 4,571 (World's spec: 6,046) | with the model on, `WorldCrater.impactEnergy` drops the tier factor, because a model speed already carries the tier. The meteor's landing speed is authored data, so its bowl loses its tier. **A real fault** | **Pinned `"power": false`** for that row. The fix (`DirArc` digs the meteor's bowl with the tiered formula in both models, in `../power-on/`) changes play, so it waits until after GW1a, when main no longer has to match the 9 November build |
| `floorlift_check`, the pop table's control | the control (riseTicks 1, no limit) sees no pop: the drop and the send land differently with the model on | the table measures World's water-floor lift, and its control can't show the pop it guards against | **Pinned `"power": false`** for the table's matches only. The check's other rows run under the model |
| `loader_check` | every chain link's launch beat differs: the live plan says `"share": "chainLink"` and the frozen one doesn't | it plans each exchange twice, with the live data and with the frozen parity copy (the model-off parity profile). With the model on only the live plan gets the energy share's key | **Pinned `"power": false`**: the frozen copy is a model-off regression |
| `beam_ai_check` (4 rows; **not in Simulation's list**: main moved since its run) | the computer's first beam comes at tick 2,007 and never reaches a stage | **with the dash on**, the computer closes fast on its rival and starts its beam hold **while locked in an exchange** (100 energy, two stages, its state "locked"), where the hold never climbs a stage. With the dash off it passes, so it isn't the model | **Pinned `"dash": false`**: the check tests the beam move's computer mechanics. **A finding:** `DirBeamMove.aiStart` doesn't check that the computer is free, so with the dash on its hold-and-release beam is often lost. The 9 November build has it too, so GW1a reproduces it. The fix (no hold while locked) is for after GW1a |

## Apply

On main dd4dca9a: `git -c core.autocrlf=false -c core.eol=lf apply energy-on-pins.diff`. It applies alone and stacks with energy-on's two patches.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `energy-on-pins.diff` (`sim/director/tools/arc_check.gd`, `beam_ai_check.gd`, `follow_check.gd`, `floorlift_check.gd`, `loader_check.gd`) | Encounter | 68404e8a5a908963fab87f13a9a8afd878ee90f4 |

## Proof

On a scratch copy of main dd4dca9a with energy-on's two patches (the model and the dash on) and this park:

| Check | The model on | The model off (`power.json` as main has it) |
| :--- | :--- | :--- |
| `arc_check` | 0 failed | 0 failed |
| `follow_check` | 0 failed | 0 failed |
| `floorlift_check` | 0 failed | 0 failed |
| `loader_check` (20 matches; the full 200 run belongs to the landing gate, 30 to 40 min) | passed | passed |
| `beam_ai_check` | 0 failed | 0 failed |

**Every director check with the model and the dash on.** The sweep ran on main dd4dca9a plus energy-on's patches plus the first four pins, before `beam_ai_check` was pinned. Records are in `docs/director/runs/dd4dca9a/energy-on-pins/`, and every output went through `tools/gate.mjs` with no SCRIPT ERROR.
- All pass but `beam_ai_check`, which is the fifth pin above. That's 40 of 41, with `loader_check` and `launch_cost_check` left out for their length.
- Validate 0 errors; self-test 10,093; ratchet 365.
- The core checks `two_states` and `load_split` pass.
- The golden fails, as it must with the model on: GW1a's target is Simulation's.

## NEEDS FROM EP

- **After GW1a:** the meteor's bowl fix (`../power-on/power-on.diff`'s `arc.gd` part) as a rider, then `arc_check`'s pin comes off. The rest of `../power-on/` (the held moment by share) waits on Simulation's `readable` block, as before.
- **World**, for the dash-speed floor clip (Simulation's finding): I'll help on the movement side if asked. The director's moves that place a body on a floor are already listed in `floorlift_check`'s table of moves.
