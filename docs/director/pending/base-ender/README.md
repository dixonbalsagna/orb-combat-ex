# Parked: the row "a base string's ender launches" (it passes on main), and the finding behind it

Encounter, 2026-11-21. Game Design asked (`docs/design/buildings.md`, the mashdummy paragraph) whether, since GW1a turned the energy model on, a base string's ender falls under a launch threshold and becomes a knock-back. **It doesn't: the rule holds on main, and the new check guards it.**

## The check: `sim/director/tools/base_ender_check.gd` (4 of 4 on main b0e20f9a)

A base fighter in reach of an idle dummy throws a flurry of X. Its close staggers the dummy and opens the launcher. B, thrown into the opening, is the launcher. (Pad B is the layout's signature action, which `DirBrawl.isB` reads as the heavy; Controls named the press.)

| Row | On main |
| :--- | :--- |
| The close's stagger reaches `launcher.minStagger`, so a base flurry opens the launcher | ok: 12 against 12 (the margin is printed) |
| **A base string's ender launches:** B three ticks after the opening | ok: UPPERCUT, speed 1,433 |
| ... and the same B pressed inside the close's hit-stop, kept as the host keeps it | ok: the same launch |
| Negative control: `minStagger` one above the close's stagger | ok: nothing opens and nothing launches, so the rows can fail |

**The row passes on main today: there was no regression to catch.** It's the guard the rule lost when Tools changed its CI scene, and it watches the 12 = 12 edge.

**The B at +1 or +2 that Controls saw swallowed comes from the test harness, not the game.**
- The close leaves 2 ticks of hit-stop, and `SimCore.step` returns not-live through it.
- The host consumes a pad's edges only after a live tick (`render/core/sim_host.gd`: "A hit-stop is a few frames: its presses are kept for the next live tick"). So in play the B is read on the first live tick, and it launches.
- Harnesses that consume edges on every tick lose it: Controls' input tests and my first probe.
- With the host's rule, B at +1 and at +2 both launch (`runs/b0e20f9a/base-ender-row/buf1.txt`, `buf2.txt`). Nothing to fix in the brawl.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `base-ender.diff` (the new `sim/director/tools/base_ender_check.gd`) | Encounter | 78c3b470e7e7c57afa88a5c6bada9b24a0b80110 |

Records:
- `docs/director/runs/b0e20f9a/base-ender-row/`: the check, and the presses at +1, +2 and +3 with and without the host's rule.
- `base-ender/`: the scene's trace below.

## What Tools' scene showed

On main b0e20f9a, I ran Tools' own `mashdummy` scene (`tools/flash/flash_worst.gd`, all four runs) with the energy model on and off. A scratch tree carried temporary print lines on the ender's path; nothing else was changed.

1. **The scene's one launch wasn't the player's ender.**
   - With the model off, the launch is the REFERENCE dummy's: slot 1, the computer. Its B lands at tick 347 inside a launcher opening, so it's "the launcher", a forced launch.
   - The player's end-of-cycle B never throws a brawl blow in either mode.
2. **No threshold is crossed.**
   - A flurry's close staggers its rival 12 ticks against `launcher.minStagger` 12, with the model on and off alike.
   - Openings open the same way in both modes: the player gets 4 to 6, the dummy 16 to 20.
   - The launcher's ki price (5) is met at 59 to 73 ki.
3. **What changed is the timeline, by chance.**
   - With the model on, the dummy's only B in 1,800 ticks (tick 937) falls outside any opening, so it's a plain heavy and staggers under the one rule.
   - The computer takes an opening with a keyed draw at its level's `brawl.launcher` share (0.25 at Medium). Tools' new staging (a heavy every 45 ticks) gets the launch back for that reason.

## NEEDS FROM EP

- **CI:** add `base_ender_check` to the director checks (Tools' check-scripts table).
- **Controls:** your input tests consume a pad's edges on every tick; the host consumes them only after a live tick. A press inside a hit-stop is lost in the test and kept in play, which may matter to other rows that press during a hit-stop.
- **Simulation** (already routed): the close's stagger sits exactly at `minStagger`. The new row's first line fails the moment it drops below.
