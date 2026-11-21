# Parked: a building's height is only asked when the choice reaches it

Encounter, 2026-11-02. A small launch-cost cut. **No switch: the same buildings, for fewer ground reads.** `WorldBrunt.candidates` asked every building in reach for its ground, then took the best two and the nearest. It now asks in score order and stops when the choice is made. Same choice, by construction.

**A plain patch on HEAD. World's file, `sim/world/brunt.gd`, so it's a grant.**

**Apply in a scratch export:** `git -c core.autocrlf=false -c core.eol=lf apply candidates-heights.diff`. Then copy.

## Read

Both of Orb's matches, on `field-place` and its grant, with the bake and the page's switches: **all checkpoints and both final hashes hold** (630154cb09579ddc, c130250f9f984886).

The gain is small and shows on one tick. Second match, medians of 3, in ms:

| | `candidates` | Whole tick |
| :--- | ---: | ---: |
| Tick 2171, launch | 6.5 to **3.7** | 34.5 to 28.4 |
| Mean of the 21 launch ticks | 0.62 to 0.51 | 11.4 to 11.0 |

Most ticks show no change you could read from noise, so don't expect more than that.

## Proof

On the stack: golden byte-identical, validate, self-test 9,977. With the page's switches and parks on: determinism on the field, rollback, `two_states`. `arc_check` shows the 2 rows `ground-settle` fixes, and `swing_check` the same 4 page-data rows as on main.
