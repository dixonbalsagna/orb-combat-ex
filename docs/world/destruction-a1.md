# Destruction for A1: what each row needs, in order (World, 2026-11-14; A1 brief item 4)

Orb (2026-11-13): "the planet, terrain, destruction, clipping all worked on heading towards the A1"; decision 3: Alpha gets craters and trenches drawn where you stand, and the terrain-mesh overhaul comes after Alpha. Gap rows: A-WORLD-03 (step 2, parked: `pending/globe-step2`), A-WORLD-04, A-WORLD-05, A-WORLD-06, A-WORLD-07, A-WORLD-10. Buildings that break at every tier and the "ping pong" are one row (A-WORLD-10); Encounter is looking into the launch rebound.

| Row | What is wrong | What fixes it | Owner and size | Hash | State |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **A-WORLD-03** terrain step 2 | the shaft cap read a strip the globe never writes; no settling; no record list | the park | World | yes (the store's slots) | parked, re-cut so `chase_rush_check` passes; one open call: `settleGrooves` (Camera) |
| **A-WORLD-04** a hole below the shore line is sea | the sea is derived from ground height including the store, with no source test: a 132-deep crater inland whose floor ends 47 below the shore line reads as 47 of sea | `water.json flood.enabled`: the sea is the field's ground and a hole holds water only where it has a source | World + Simulation (one line, in the park) | no | parked, switch off; it needs Rendering's pool and a look gate before it flips (A-WORLD-05) |
| **A-WORLD-05** the ground drawn is not the ground stood on | the tile ground draws only the 16 newest crater bowls; trenches and scars are not drawn at all; a superseded bowl pops | Rendering bakes the store's records (`heightDelta` is the one function; trenches, scars, heaps and merges have readers since step 2) and subtracts the superseded bowl first | **Rendering**, L, with Animation for the feet | no (view) | not started; World's part is the records, ready |
| **A-WORLD-06** crater width at the top tier | X-14 asks 3 times the width at the top tier; an impact gains 25% energy a tier (1.32 times the width at tier 4), a shot 2.2 times the energy (1.48 times), and with the energy model on the tier term is gone | a tier table of energy in data (about 1, 2.1, 4.3, 9 for a 3-times radius), or the energy model's force term mapped so base to max is 3 to 3.5 times (the plan's 356 to 1,244) | World, S (the numbers are Game Design's); a check that asserts the ratio | yes (crater sizes) | not started: waits for Game Design's numbers |
| **A-WORLD-07** a slide trench is one fixed 32 wide | `crater.gd` cuts every skid at `SimConst.COL` | half width `56 + 24 sqrt(E)` (109 to 242 by force), longer with force, lips and a berm (slots exist), settled to the angle of repose (`settleGrooves`), depth cap | World with Encounter's slide, L | yes | not started: **the trench ground moves Camera's `chase_rush_check`** (jolt 0.15 with a shallower, wider landing trench), so this is the window Camera re-tunes in |
| **A-WORLD-10** a body bounces off a building like a ping-pong ball | `lodgeHold` "world", a quarter of his speed back, the fight frozen 0.5 s | five numbers in `brunt.json` | World, data: **parked** (`pending/wall-hold-on`: 0.00 s freeze, 18 units off the face instead of 1,154, and a tower falls to its third send); QA's read held it | yes (GW2) | parked |

## The order I would take

1. **The flip of what is built**, as GW1a and GW2 allow: `wall-hold-on` (data), then `flood` when Rendering can show a pool, then `globe.repeats` when Rendering subtracts the superseded bowl.
2. **A-WORLD-06**, with Game Design's numbers: a small data park and a check that asserts the ratio (nothing asserts one today).
3. **A-WORLD-07**, with Camera and Encounter in one window: the trench widths by force, `settleGrooves` on, `chase_rush_check` re-tuned. The records the trench needs (lip, water, supersede slots) are in step 2.
4. **A-WORLD-05** is Rendering's; the clipping Orb saw ("the terrain doesn't quite match up with the character's hitboxes") is the ground drawn against the ground stood on, and it is closed only when the drawn height is `heightDelta` everywhere a foot can stand.

## Things only a player can say

- Whether a tier-1 send should go through one tower (`towerPunches[0]`). It is the plan's open question and Game Design's.
- Whether the body held at a wall face is the feel: slides down it for the hold, then eases home. Nobody has played it with the pad.
