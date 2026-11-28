# Which turn system ran in build 0.1.1 (Encounter, 2026-11-28)

**The answer: the turntable ran, and the calm turn never did.** Brief 3, item 1 of the combat-overhaul directive (`docs/ep/proposals/combat-overhaul-directive.md` section 5).

## Why
- **Both are switched on in 0.1.1's data** (5dbd89ca): `data/director/swing.json` `enabled: true` (the turntable) and `data/director/interrupts.json` `calmTurn.enabled: true`.
- **Every default match is a field world.** `WorldDefault` sets planet generation 3, so the sim has `S.frame`, which the turntable needs (`DirSwing.on`).
- **The calm turn needs an epoch ring** (`DirCalm.on`: `S.epoch != null`). Only the older ring worlds have one. On a field world it is `null`, so the calm turn never asks.

## The numbers
**How I measured:** `sim/director/tools/turn_probe.gd` (scratch) on a tree of 5dbd89ca.
- Each seed's own default world, as the game sets it up (`WorldDefault.apply`).
- Computer against computer, at Easy (Orb's level) and Medium.
- Every run reached the 36,000-tick cap with no knockout, about 9 minutes of fight each.
- Degrees are each swing's planned size, as `SimSwing.ask` reports it.

| Match | Swings | All degrees (a minute) | Small (4.5-8°) | Launch | Chase | Brawl | Form | 20° or more | Calm turns |
| :--- | ---: | ---: | ---: | :--- | :--- | :--- | :--- | ---: | ---: |
| Easy 1 | 36 | 461 (51) | 23 | 1: 5° | 4: 9-103° | 6: 3-35° | 2: 7-25° | 5 | 0 |
| Easy 2 | 38 | 524 (59) | 24 | none | 4: 23-104° | 7: 4-27° | 3: 11-29° | 7 | 0 |
| Easy 3 | 33 | 357 (40) | 24 | 2: 9-15° | 2: 40-46° | 3: 6-30° | 2: 17-60° | 4 | 0 |
| Easy 4 | 42 | 835 (92) | 23 | none | 6: 3-122° | 9: 4-55° | 4: 10-81° | 11 | 0 |
| Easy 5 | 34 | 477 (53) | 22 | 1: 2° | 3: 58-91° | 5: 2-9° | 3: 7-70° | 5 | 0 |
| Medium 1 | 48 | 604 (69) | 25 | 2: 7-19° | 7: 6-86° | 10: 2-28° | 4: 6-38° | 8 | 0 |
| Medium 2 | 50 | 739 (83) | 32 | 1: 3° | 7: 18-76° | 8: 5-42° | 2: 10-16° | 10 | 0 |
| Medium 3 | 34 | 357 (40) | 20 | 2: 2-14° | 4: 3-30° | 5: 3-40° | 3: 7-65° | 4 | 0 |

## What it means for Orb's note
Orb's note: "I may have noticed the angle of the fight changing, but it was so subtle it may have been a placebo effect".
- **Most turns were too small to see.** About two thirds of the swings were "small": 4.5 to 8 degrees each, over 14 ticks.
- **Launches barely turned the world.** Zero to two launch swings a match, of 2 to 19 degrees.
- **The large swings came from chases and forms.** Those are moments when a player watches the fighters, not the horizon.
- **Only 4 to 11 swings a match reached 20 degrees.**
- **Caveat:** these are computer-against-computer matches. A human match has different launches and chases, but the same rules choose the size.

This supports the directive's section 5: a launch should swing clearly (20 degrees or more) toward the biggest place in view, and the small drift should not count as a turn.

Records: `docs/director/runs/5dbd89ca/turn-probe/` (the probe's output per match and this summary).
