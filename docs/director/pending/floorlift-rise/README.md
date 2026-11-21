# Parked: floorlift_check reads World's floor-rise rule (GW1b, with the GW1b riders)

Encounter, 2026-11-20, sprint A1. World's grant (`docs/world/pending/floor-rise/`, GW1b) makes `floorFor` lift a body under his floor by `riseMax` **plus the floor's climb** from where his tick began. That broke `floorlift_check`'s "fight" row: the largest lift was 144.54 a tick against the 7.5 limit, 1,758 ticks over. This re-reads the row under the new rule. **Checks only: nothing in the sim changes.**

## What it does (`sim/director/tools/floorlift_check.gd`)

- **The limit is `riseMax` plus the floor's climb, wherever he ends**, on his floor or still under it. The old row took the climb off only when he ended exactly on his floor. The climb runs from the floor where his tick began to the larger of the floor where his own step put him and the floor where he ends (below).
- **Each over-limit line names both floors**, where his tick began and where it ended, and the row prints the steepest climb it allowed for.
- **The `"power": false` pin on the table's matches stays.** With the model on, the table's control (riseTicks 1, no limit) sees no pop: 0.00 at 45.4 and 64.1 deep, where it was first measured at 15.81 and 53.17. The control can't show the pop it guards against, and the fight row runs under the model.

## The place World named, verified

The rival, free, at tick 49,914, moved 53 units:
- The floor was **2,228.6 where his tick began and 2,365.7 where it ended: a climb of 137.04** (2.6 in 1).
- He rose from 2,207.4 to 2,352.0, which is **144.6: exactly 7.5 plus the climb**.
- He still ends 13.7 inside the bank, not on it. World's reading ("standing on the bank instead of 19 ticks inside it") is right about the lift. The last 13.7 comes back the next tick.

## Why "where his own step put him" (a finding for World)

With the limit at `riseMax` plus the climb from the start to the end place, the row still failed: largest lift 9.14 (79 ticks over on the 9 November data, 155 on main's), always a body locked in a brawl. A scratch probe in `floorFor` (not in this park) showed why. In the tick named:
- the core's own step moved him from 48,812.7 to 48,821.4, and the clamp there allowed 7.5 plus a 1.80 climb;
- then the brawl's pull took him back to 48,813, where the climb from his start is 0.2;
- a floor only lifts, so he keeps the extra 1.6.

So the grant's ceiling is the climb **to where the core's step puts him**, before the director's lines move him again. The row now allows the larger of that climb and the climb to where he ends. With it, the largest lift is exactly 7.50 on both data sets, so the rule holds to the unit. Whether a pull back down the slope in the same tick should lower him is World's call: it's at most a step's climb (1.6 here).

## Proof

On main 4327cfbb + energy-on + gates-shipped + energy-on-pins + GW1a's checks, on Orb's 9 November data and on main's data. Records are in `docs/director/runs/4327cfbb/floorlift-rise/`; every output went through `tools/gate.mjs`, no script error.

| Tree | The fight row | Every other row |
| :--- | :--- | :--- |
| World's grant, today's check (9 November data) | FAIL: 144.54, 1,758 over | pass |
| World's grant, today's check (main's data) | FAIL: 8.88, 2,959 over | pass |
| World's grant, limit with the end place's climb only (both) | FAIL: 9.14 and 8.42 (79 and 155 over) | pass |
| **World's grant, this park (9 November data)** | **pass: 7.50, 0 over** (steepest climb 137.04, the named place) | pass |
| **World's grant, this park (main's data)** | **pass: 7.50, 0 over** | pass |
| No grant, this park (main's data) | pass: 7.50, 0 over | pass |
| This park with the pin off (main's data) | as above | the table's control FAILS (no pop): the pin stays |

## Apply

On main + energy-on-pins (the re-cut), before or after World's grant: `git -c core.autocrlf=false -c core.eol=lf apply floorlift-rise.diff`. Checked on main 42b683ab + energy-on-pins.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `floorlift-rise.diff` (`sim/director/tools/floorlift_check.gd`) | Encounter | 0228351542c12551948edead229967c5aa78503b |

## NEEDS FROM EP

- **With the GW1b riders and World's grant.** It passes with or without the grant, so the order doesn't matter.
- **World:** the grant's ceiling is the climb to where the core's step puts him, not to where his tick ends (above). That's fine by me, and the check now reads it that way. Say if you want it the other way.
