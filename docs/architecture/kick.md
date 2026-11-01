# The kick and the coin turn

Simulation. The rule is Game Design's (`docs/design/rule-of-cool-map.md` section 5), the shape is Research's (`research/rule-of-cool/pitches.md` section 2), and the numbers are in `data/fight/kick.json`. Behind a switch: `enabled` there, or a setup's `"kick"`. Off, nothing runs, nothing is hashed and the file isn't in a replay's data hash.

## What it does

`SimKick.move` replaces the plain lag toward the stick in `SimFighter.stepFighter`, for a free fighter on his own flight.

- **The kick:** flat out, with the stick over, under half of top speed. He's at `instant` of top speed on the first tick, and climbs to top in a straight line over `climbTicks`. A setup's `"instant"` (0 to 1) and `"climbTicks"` (0 to 120) try other values for a match.
- **The coin turn:** a flip of the stick above half of top speed. `brakeTicks` at `brake` a tick, then `plantTicks` stopped with a small hop, then a kick the other way. Nothing here touches a hit, so he can be hit in the plant.

## The overspeed: its own switch, off

`overspeed.enabled` in the data. On, the climb goes to `topShare`, holds for `hold` and eases to top speed over `ease`, where it's allowed. Read each tick, from where he's going:

| | Overspeed |
| :--- | :--- |
| The stick's toward the rival | Always |
| Away, inside `chargeRange` | None |
| Away, beyond it | Yes |
| Away, within `afterZip` ticks of a zip | None |
| The third kick within `repeatTicks` | None, either way |

**The response is free in every row.** With no overspeed, the kick is the same shape up to top speed.

A brawl is always inside `chargeRange`, so "out of a brawl" needs no separate test. **The vanish has no state in the sim yet** (`sim/input/left_hand.gd` reads it, and nothing past the input uses it). When it does, it sets `f.kik.off` as the zip does.

## State

`f.kik`, a `KickState`, while `S.kickOn`. In the hash, the desync digest and a snapshot. Two events, for the view and the pad: `kick` and `coin_plant`.

## Checks

`sim/core/tools/kick_check.gd`: the shape at other values of the data, each row above with the overspeed forced on, two runs, a rollback across kicks, the switch.
