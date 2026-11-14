# Parked: Encounter's checks under the energy model on (A-ENERGY-04, for GW1a)

Encounter, 2026-11-14, sprint A1. Simulation's `docs/architecture/pending/energy-on/` turns the energy model and the dash on in main's data. Four of my checks failed with it: `arc_check` 1, `follow_check` 3, `loader_check` and `floorlift_check` 1. **Checks only: nothing in the sim changes,** so main still reproduces the 9 November build (GW1a's target).

**Re-cut (2026-11-15, the GW1a review's major 2):** the two real faults are no longer pinned off. `arc_check`'s meteor bowl and `beam_ai_check`'s beam hold run under the energy model and the dash (Orb's path) as **GW1a ceilings**: the failing value is held at today's number on the 9 November data, may only get better, and names its owed fix, Encounter's `../gw1b-riders/` (GW1b). The riders, re-cut to match, put both rows back in full. The other three pins are unchanged: each is a path Orb's game doesn't take (a table's control, the frozen model-off parity copy) or a re-read.

| Check | With the model on | The cause | What this does |
| :--- | :--- | :--- | :--- |
| `follow_check` "60 after the send" (3 rows) | the far tap did nothing, and no taunt | his landing holds the clock (0.4 s) on the tick the check pressed. In play the host offers a press again until the first live tick (`sim_host.gd`) | **Re-read under the model:** the check waits out a hold before it presses, as the host does. The follow itself is right |
| `arc_check` "the meteor's own bowl" | radius 4,571 (World's spec: 6,046) | with the model on, `WorldCrater.impactEnergy` drops the tier factor, because a model speed already carries the tier. The meteor's landing speed is authored data, so its bowl loses its tier. **A real fault** | **A GW1a ceiling** (re-cut): the row runs under the model and holds the bowl at today's 4,571 (a floor of 4,570): it may only grow. Owed fix: `../gw1b-riders/` (the meteor's bowl dug with the tiered formula), which the EP picked over World's meteor-power and which puts the row back to more than 5,000 |
| `floorlift_check`, the pop table's control | the control (riseTicks 1, no limit) sees no pop: the drop and the send land differently with the model on | the table measures World's water-floor lift, and its control can't show the pop it guards against | **Pinned `"power": false`** for the table's matches only. The check's other rows run under the model |
| `loader_check` | every chain link's launch beat differs: the live plan says `"share": "chainLink"` and the frozen one doesn't | it plans each exchange twice, with the live data and with the frozen parity copy (the model-off parity profile). With the model on only the live plan gets the energy share's key | **Pinned `"power": false`**: the frozen copy is a model-off regression |
| `beam_ai_check` (4 rows; **not in Simulation's list**: main moved since its run) | the computer's first beam comes at tick 2,007 and never reaches a stage | **with the dash on**, the computer closes fast on its rival and starts its beam hold **while locked in an exchange** (100 energy, two stages, its state "locked"), where the hold never climbs a stage. With the dash off it passes, so it isn't the model | **A GW1a ceiling** (re-cut): the check runs with the dash on. On the 9 November data three of its four rows pass; "nobody is locked while it charges" fails with the rival locked 29 ticks, so it's held at today's 29: it may only come down. **The cause:** `DirBeamMove.aiStart` doesn't check that the computer is free. The 9 November build has it too, so GW1a reproduces it. Owed fix: `../gw1b-riders/` (no hold unless free or charging), which puts the row back to 0 |

## Apply

On main (checked on 5cef4af7; the five checks are unchanged since 4327cfbb): `git -c core.autocrlf=false -c core.eol=lf apply energy-on-pins.diff`. It applies alone and stacks with energy-on's two patches.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `energy-on-pins.diff` (`sim/director/tools/arc_check.gd`, `beam_ai_check.gd`, `follow_check.gd`, `floorlift_check.gd`, `loader_check.gd`). The re-cut; the first cut was 68404e8a | Encounter | 11ddb9a577648caf0659062ba4a0a28ed9fd2117 |

## Proof of the re-cut

On main 4327cfbb + energy-on + gates-shipped + this park, with Orb's 9 November data (GW1a's target) and with main's data. Records are in `docs/director/runs/4327cfbb/energy-on-pins-v2/` (`gp*` unpinned, `c*` the re-cut, `r*` the re-cut with the riders; `9` the 9 November data, `m` main's), every output gated, no SCRIPT ERROR.

| | `arc_check` | `beam_ai_check` |
| :--- | :--- | :--- |
| Unpinned, before the re-cut (9 November data) | 1 failed: the bowl 4,571 | 1 failed: the rival locked 29 ticks |
| **The re-cut (9 November data)** | **0 failed** (the bowl 4,571, at the ceiling) | **0 failed** (29, at the ceiling) |
| The re-cut + `../gw1b-riders/` re-cut (9 November data) | 0 failed, the full row: the bowl 6,046 | 0 failed, the full row: 0 locked |
| The re-cut, main's data with energy-on alone | 0 failed | **3 failed** (below) |
| The re-cut + the riders, main's data with energy-on alone | 0 failed (6,046) | 0 failed (0 locked) |

- **Main's data with energy-on but without GW1a's target data** is a state that exists only mid-stack. There the computer charges at tick 2,007 and never lets go in 9,000 ticks, so three of `beam_ai_check`'s rows fail (the ceiling row passes, at 10). If GW1a pushes energy-on and the target data as separate commits, CI on the first would show it.
- The determinism lint is clean.

## Proof of the first cut

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

- **GW1b:** `../gw1b-riders/` (re-cut to stack on this) drops both ceilings and fixes both faults. The rest of `../power-on/` (the held moment by share) waits on Simulation's `readable` block, as before.
- **The landing order:** energy-on and the target data in one pushed window, or `beam_ai_check` fails on the commit between (above).
- **World**, for the dash-speed floor clip (Simulation's finding): I'll help on the movement side if asked. The director's moves that place a body on a floor are already listed in `floorlift_check`'s table of moves.
