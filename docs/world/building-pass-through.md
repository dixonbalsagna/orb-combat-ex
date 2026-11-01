# A building pass-through for the meteor (World, 2026-11-01)

Simulation's order, for Encounter's row 5 of `rule-of-cool-map.md` and the meteor park (`docs/director/pending/meteor`): going through a building on the way down must keep the body **on its curve**. Today `WorldBrunt.hit` is the only door a flying body has into a building, and it decides everything about what happens next: `keep` scales `f.vx` and `f.vy`, `next` picks a chain link, the lodge ends him inside the building (`f.vx = 0`, `_hold`), `WorldInterior.begin` takes him into a tower, and the stop freezes the tick. Encounter's park works around it with its own damage (`towerShare` 0.6 of the building's hit points, once), without `buildings.md`'s ladder, events, `levelCapShare` or the wear.

## What it is

`WorldBrunt.through(S, f, b, y, edge, dir)`: `hit`'s building half and none of its fighter half.

| `hit` does | `through` does |
| :--- | :--- |
| `outcomeOf` the tier ladder, `applyFloors` or `damageBuilding` (and the collapse and pancake texts) | the same, so the building falls, floors go and the toll is the ladder's; the damage is the outcome's with `towerShare` as the data's cap of the building's hit points |
| `b.marks += 1`, `f.flightHits += 1`, `f.splashed` | the same, so repeat strikes still escalate and the splash is once per launch |
| `SimFx.buildingHitB2` (the event Audio, VFX and the camera read), `_splash`, debris | the same, with the text "through" (or "collapse" / "pancake" when the ladder says so) |
| `keep`, `next`, the chain, the lodge, the interior, the stop, `f.vx`/`f.vy`/`f.x` writes, `hurt` the fighter | **none**: no velocity or position write, no chain, no lodge, no interior, and the hit stop by data (`throughStop`, 0 by default) |

**Where it is called.** The flight sweep (`flight.gd`, Simulation's) calls `WorldBrunt.hit` for a flying body that meets a building. It becomes: `if f.passThrough: WorldBrunt.through(...) else: WorldBrunt.hit(...)`, one line at each of the (one or two) call sites, with `f.passThrough` a plain flag Encounter's `DirArc` sets when it puts him on the curve and clears at the crest. Encounter drops its own tower damage.

## Cost

| | |
| :--- | :--- |
| World | about 45 lines in `sim/world/brunt.gd`, extracted from `hit` (the building half moves into a function both call, so `hit`'s behaviour is byte-identical: the golden holds), plus `brunt.json`'s `throughShare` and `throughStop` and its schema |
| Simulation | the call-site line (above) and the one flag on the fighter; nothing in the hash beyond the flag, which is state |
| Encounter | deletes the curve's own building damage; sets and clears the flag |
| Per tick | 0 when nothing is struck. A struck building costs what `hit`'s does **less** the chain search (`next`, the expensive part) and the interior: estimate half of it; measure on the build |
| Rollback | no new state beyond the flag: the building's hit points and marks and `f.splashed` are hashed already |
| Flash | the building's own debris and fall, as a hit has them; no hit stop, so a meteor through a row of towers does not stutter. A collapse of the third tower in a second is the same register ask the ladder already makes |

## What I need

Encounter: the number to take (the ladder's tier-4 damage on its own, or `towerShare` as a cap on it; I default to the ladder with the cap, because a meteor that takes 0.6 of a tower once is a smaller thing than a tier-4 send through it), and whether the meteor wears (his own hit points) through a building: I default to no, so `hpFloor` need not hold him up. Simulation: the call-site line. I will build it behind `brunt.json through.enabled` (off) when Encounter says go.
