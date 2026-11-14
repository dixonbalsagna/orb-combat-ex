# Parked: knock_wall_check and walk_check stage from the buildings index; gw1a-pins' two world pins come off (after GW1a)

Encounter, 2026-11-15, sprint A1. World traced the GW1a finding (`docs/world/pending/everywhere-knock/README.md`): it's the checks' staging, not a game fault.
- A knock aims at a building of the index (`WorldStructures.near`).
- The index leaves out a building whose front face is toward the camera past `plans.indexFrontBH`, because the view lowers it.
- With `plans.everywhere` on, the nearest building over *all* buildings could be one of those. No knock aims at it.

**Checks only. It stacks on `../gw1a-pins/`,** whose two `WorldPlan.everywhereOverride` lines it removes. beam_front_check's pin stays.

## What it does

| Check | Change |
| :--- | :--- |
| `knock_wall_check` | `_front` picks its building from `WorldStructures.near` (3,000 around the start), as World's `everywhere_check` rows do. **The "on, in reach" row now asks World's contract:** the knock aims at the nearest indexed wall along the line, inside its reach and depth window, that a flight reaches (`_firstWall`, the same reading as World's row). That can be a nearer building in another row of the street than the one staged beside: on GW1a's data it stages beside 867 and the knock rightly takes the nearer 866. Every other row reads as before |
| `walk_check` | Its ten buildings come only from the index (`WorldStructures.inBand`, the index's own rule) |

## Apply

On main + energy-on-pins + gw1a-pins: `git -c core.autocrlf=false -c core.eol=lf apply index-stage.diff`.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `index-stage.diff` (`sim/director/tools/knock_wall_check.gd`, `walk_check.gd`) | Encounter | 821afb4a99585182be4b6faedcb89c98b52b16c6 |

## Proof

Run on main 4327cfbb + energy-on + gates-shipped + energy-on-pins + gw1a-pins + this park. Records are in `docs/director/runs/4327cfbb/index-stage/`, and every output went through `tools/gate.mjs`.

| Data | `knock_wall_check` | `walk_check` |
| :--- | :--- | :--- |
| The 9 November target (`plans.everywhere` on) | 0 failed | 0 failed (8 of 10 reach leaning) |
| Main's (`everywhere` off) | 0 failed | 0 failed (10 of 10) |

The "off, in reach" row (the knock's wall aim forced off) still expects no aim: that's the in-reach row's negative control.

## NEEDS FROM EP

- **For after GW1a, with gw1a-pins.**
- **Game Design:** World's design note, nearest along the line against nearest in depth, would change `_firstWall`'s order with `DirLaunch._wall`'s. Both read the same rule today.
