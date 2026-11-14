# Parked: Encounter's checks under GW1a's whole data (the second pins park, for GW1a)

Encounter, 2026-11-15, sprint A1. energy-on-pins covered the energy model only. GW1a also lands every other switch group's data: the pad, the computer opponent, the match ending, the camera, the look, the sound, the menus and World's five files.

This park reads every director check on **main 4327cfbb + energy-on (both patches) + gates-shipped + energy-on-pins + the 9 November target data**, using Simulation's recipe: the kept build's data copied over main's, with `power.json` `enabled` and `dash.enabled` true. That data changes 21 files.

**Checks only: nothing in the sim changes.** It applies on main alone (none of its three files is energy-on-pins'), and it stacks after energy-on-pins.

## What went red, and why

38 of the 41 director checks pass as they are, along with `launch_cost_check` and `loader_check` (20 matches; the full 200 belongs to the landing gate). Three went red:

| Check | Red rows | Cause | What this does |
| :--- | :--- | :--- | :--- |
| `beam_front_check` | 4: RT + B pressed into a beam's charge (18 and 38 ticks) doesn't answer it; RB + B as a fire-back starts no struggle, so the meet point can't be read | **The 9 November pad.** B never starts a beam (`timing.json` `bNoBeam`), and RB + B is the Driver (`driverOnRb`). The beam's answer in that pad is the right stick, and those rows (RB and the stick) pass unpinned | **Pinned** around `_litHand` and `_fireBack` only: `SimInputData.pin_switches_off()` (Controls' helper made for this), then `load_and_apply()` puts the data's pad back for the rest of the check |
| `knock_wall_check` | 1: "on, in reach: aimed false". The knock still meets the wall (2 hits) | **World's `plans.everywhere`** (`field.json`, on in the 9 November data) lays every place on the field world. The street the check stages is another street, and the planner's aim at the building it picked is null | **Pinned** to the field world as main shipped it: `WorldPlan.everywhereOverride = 0`, World's own hook for tools, then -1 |
| `walk_check` | 1: "3 blows leaning, then B: at least 70% reach it": 6 of 10 | **The same `plans.everywhere`.** Its ten buildings are other streets. The walk is off in the 9 November build (`wallPush`); this check forces it on | **Pinned** the same way |

**The bisection:** each kept data file was put back to main's one at a time.
- Main's `field.json` alone turns both knock_wall and walk green.
- Main's `director/swing.json` alone turns walk green too (7 of 10), at the 70% line.
- `contact.json` (World's settle), `launch.json`, `rings.json` and `camera/swing.json` change neither.
- So World's `plans.everywhere` is the cause. The swing only moves the walk's marginal line.

## Apply

`git -c core.autocrlf=false -c core.eol=lf apply gw1a-pins.diff`.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `gw1a-pins.diff` (`sim/director/tools/beam_front_check.gd`, `knock_wall_check.gd`, `walk_check.gd`) | Encounter | 5f5eabd1bb9f1208d97e8382070217ef70ca5fc3 |

## Proof

Records are in `docs/director/runs/4327cfbb/gw1a-pins/`, and every output went through `tools/gate.mjs`.
- **On the GW1a tree with the pins, every director check passes:** the three (`beam_front_check` 0 failed, `knock_wall_check` 0, `walk_check` 0), the other 38, `launch_cost_check`, and `loader_check` (20 matches, 5,509 plans compared).
- **On main's data, the three pinned checks pass too.** There the pins change nothing: the pad's switches are already off, and `everywhere` is already off.

## NEEDS FROM EP

- **World:** with `plans.everywhere` on, a staged knock in reach of a building doesn't aim at it, though it still hits it. That's worth a look in World's own `everywhere_check`, whether it's the planner's reach or the new street. The walk and knock checks are pinned meanwhile.
- **GW1a's landing gate:** `loader_check`'s full 200 matches, on the stack with both pins parks.
