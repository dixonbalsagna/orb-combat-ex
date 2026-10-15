# World's side of more than two bodies (World, 2026-10-15): parked patches, not applied

EP's brief: four items, in scratch on main's HEAD, parked, each with a test and the 1v1 golden identical where it should be. Built on main 2b047018. **Not applied** (the game stays frozen for the demo's flash run). Simulation's N-body stage 1 interface was not in the tree, so everything keeps to its **slots-by-index shape** (`S.fighters.size()`, `a.get("team")` with a fallback): nothing reads a name that Simulation has not published.

## Apply order (a chain: each on the one before)

| # | Patch | What | Check |
| :--- | :--- | :--- | :--- |
| 1 to 3 | `n-bodies/nbody.diff` (`mk_nbody.py`) | the token per flight, the launcher by foe, the per-body lodge hold | `sim/world/tools/nbody_check.gd` (`nbody_check.gd` here): 0 failed |
| B | `windows-bc/stage-b.diff` | breaches with the held hit's side (as parked; re-cut on the line above) | `bc_check.gd` |
| 4 + C | `windows-bc/stage-c.diff` | the failing state, `failHurt` by fighter count, "rival" as a team test | `bc_check.gd`: 0 failed (four-body tests added) |

`git apply` of the three in order on a clean export of 2b047018 gives the tree the scratch gates ran on (verified byte for byte). B no longer applies on a bare HEAD (its context is the `lodgeHold` line the first patch changes): if B goes first, I re-cut the first patch on it.

## What each does

1. **A set-piece token per flight.** `S.world.evtToken/evtKind/evtLeft/evtDead/evtEvac` stays the first slot (one set piece: exactly as before); further set pieces open in `World.evtMore` (five numbers each), keyed by the token the flight holds (`Fighter.chainEvt`, `Fighter.slideEvt`). Two overlapping chains each borrow their own allowance and each `endEvent` returns its own casualties. A token no fighter holds any more is closed by the next `beginEvent` (the old single slot overwrote it: this keeps 1v1 behaviour) and the oldest extra is promoted into the first slot.
2. **The launcher.** `WorldCollateral.launcherOf(S, f)` = `launchBy` if set, else the nearest foe (`foes`: by `team` when both have one, else any other body); with two bodies it is `SimRoster.opp`'s answer. Replaces the three `SimRoster.opp` calls in `brunt.hit`, `contact` and `slide`, and the one in stage C's `_failHurt`.
3. **The lodge hold.** `lodgeHold` is now `world`, `body` or `auto`; the data default is `auto`: a hit-stop of the sim with two bodies (today, byte for byte), a per-body pin with more. A pinned body keeps `Fighter.holdT` ticks (not moving, no gravity, the fight goes on) and then falls. A wall (not a lodge) in body mode only staggers, as before.
4. **`failHurt` by count, "rival" by team.** `failHurt` is sized `max(fighters, 2)`; "rival" is `not foes(f, causer)`, so the causer and his team are spared and the cap of 100 stays per fighter per building; an out-of-range slot is skipped.

## Golden and cost (what moves)

- **1v1, patch 1 to 3 only:** the parity golden (9 matches, `sim/core/tools/parity.gd`) is byte-identical at 8; **one checkpoint of one match moves** (default-flip seed 2, tick 15480, where two set pieces genuinely overlap and the old single slot was overwritten): its final digest is identical to HEAD. The 30-match batch (`batch.gd -- 30`): every aggregate identical (length, KOs, collateral), the digest string differs (`add18dc44be1ccdb` to `0dcade1645892a9e`). So: **a golden regeneration when applied**, gameplay otherwise unchanged. With more than two bodies behaviour is new by design.
- **State and hash lines in Simulation's files** (one number each, written only when set so a 1v1 stream is unchanged): `state.gd` `World.evtMore`, `Fighter.holdT`; `hash.gd` both as conditional appends; `brunt.json` `lodgeHold` `"auto"` and its schema enum. Stage C adds the `failHurt` array to the hash as before.
- **Gates on the whole chain (scratch):** probe, lane_check, isect_check, probe_collide, brunt_check, bc_check, depthreads_check, stagecheck, blockcheck, directcheck, minecheck, and the render checks (stage, shape, ground, patch, depth, effects): all pass.

## What this does not settle (routed, not World's)

- **The pin hook lives only in the contact path** (`S.contactOn`, true in data); with contact off a pinned body would not hold.
- **A wall in body mode only staggers** (no pin: the rebound velocity is set the same tick). Whether a wall should pin like a lodge is Orb's homework 5f.
- **The collateral budget for four bodies** and **the street spacing for N bodies** are Game Design's; the world takes either as data (the window by tier is unchanged here: four bodies means more launches into the same window).
- **Whose first move after a wall slam** with three bodies near: Encounter's.
