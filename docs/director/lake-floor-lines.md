# The director on the floor of a lake or the sea (Encounter, 2026-10-30)

Rulings: Game Design `docs/design/rulings-2026-10-30.md` rows 1, 3, 9, 11 and 12. World's half: `docs/world/lake-floor.md`. Everything here reads the ground to the bit with `water.json` `floor.enabled` off.

## Which read each line takes

| The line | The read | Lines |
| :--- | :--- | :--- |
| Asks whether a body stands on the ground | `WorldWater.floorAt` | `recoil` both ground tests, `launch.knock`'s, `brawl._thrownApart`'s and the pull's, `melee` both room tests, `rally.turn`, `blur`, `blast`, `bands._endOff`, the grapple's height test |
| Aims a rush | `SimFighter.floorFor` | `brawl._pop`, `_spike`, `_thrownApart`; `recoil` heavy, flip, pop flip; `launch.knock` (both); `wallkick`; `bands.meet`; `zip`'s way out |
| Sets a height at once | `DirWater.held` around `SimFighter.floorFor` | `brawl` closing steps, give, tell and pull; `melee._contact` and the dodge; the grapple's slam |
| Measured from the ground, unchanged (rows 7 and 8, row 11) | `WorldTerrain.groundY` | `bury.gd` 143, the planner (`launch.gd` 148 and 322), landings, `melee.gd` 264's crater, `brawl._walled`, `sigafter`, `beam`, `chase._sky`, `ai.gd` 232 |

**This differs from World's first conversion in two ways, both from the check below.** A rush's target is `floorFor`, not `floorAt`: a target on the floor, from below it, rises faster than the rate over a short rush. And the core has already spent the tick's rate when the director runs (fighters step first), so a line that sets a height adds nothing while he is under: `DirWater.held`. Without it the pull rose 30 a tick and a closing step 32.

## Row 11, the down throw

The height test and the placement read the floor. He is flat on it for the same `tc.bury` ticks of opening. On water there's a splash. The throw never dug a crater, so none was removed.

## Row 12, MARSH SWALLOW

`launch.gd` doesn't offer it where `WorldWater.burialOK` is false, read at `D.x`, the column of its mud test. With the floor off `burialOK` is always true.

## The check

`sim/director/tools/floorlift_check.gd`. A lift is a tick that starts with him below his floor and ends no higher than his floor, outside a drop's surfacing and a launch. It isn't a lift if he ends on the actual ground. A move's own height is counted apart, because dry land has it too: a rush at the rival, a bowed rush, a rush aimed above his floor, his own flight and a brawl's drift by their velocity, and a launch's last tick.
