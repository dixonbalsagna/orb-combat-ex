# The launch cuts: Encounter's build plan (2026-11-07)

This is the EP's queue item after flight strikes. It builds the three cuts Game Design said yes to in `docs/design/buildings.md` section 8.

**One switch, off:** `data/director/launch.json` `aimCuts.enabled`. **The golden moves only with it on.** Its purpose is a single QA read of the city rows (sends into a building, places visited, buildings crossed per send), taken off and then on with the same seeds. If none of them moves beyond noise, the switch goes on and then goes away.

## 1. Aim at most 3 buildings (mine: `DirLaunch.chooseLaunch`)

- World's `WorldBrunt.candidates` still makes its list: the best 2 a side by the cheap score that clear his height, plus each side's nearest.
- From that list, keep the 3 with the best cheap score (World's `_cheap`). Ties go by World's order.
- When each side has a building, at least one a side is kept: if the top 3 are all from one side, the third gives way to the other side's best.
- The kept buildings are aimed in World's order, so nothing else about the order changes.

## 2. The cheap-score rejection, as a bound that can't change a pick (mine)

As section 8 rules it, the bound must never change a pick. Two things make that true:
- **The noise is keyed by candidate, with the switch on.** Today each candidate draws its 0 to 8 from the match's stream in candidate order, so a building left out would move every later candidate's noise and could change the pick. With the switch on each candidate's draw is keyed: by the launch number, its name and its building. A dropped building moves no one else's draw.
- **The bound is a real upper bound.** Before a building is aimed, an upper bound on any score its candidates could reach is set against a lower bound on the best building plan already in hand. The building is dropped only when the first is below the second.
  - The upper bound is built from what's known before the aim: `bruntScore`'s base and tier terms, its personality term at its largest over a chain, the drama cap, the pity ramp, the town and stick bonuses that could apply, the interior aim's score, the visit term's largest value and the noise's 8.
  - The lower bound on the plan in hand is its own `bruntScore` with those bonuses, the visit term's smallest value and no noise.
- **A dropped building counts as offered** for the pity counter (`hadBrunt`), as section 8 rules.

## 3. One flight across the aim arcs (World's file: a grant)

`WorldBrunt._aimBy` flies the launch once for each `AIM_UY` arc, for each building. On a flat world the flight's path doesn't depend on the building: it stops at the first face crossing it's asked about. The patch flies each arc once a side and reads every kept building's crossing from it. A building's plan is still its first arc that hits. On a flat world that's the same answer to the bit.
- **On a field world (depth on),** the body's depth follows each target's own waypoint, so a shared flight is only shared in x and y. Its depth, ground and sweep stay per building. The check is section 8's: the share of aimed buildings that get a plan, and buildings crossed per send, hold within noise on QA's city seeds.
- **World's file takes a flag from the caller**, so the world layer never reads the director's switch.
- **NEEDS FROM EP:** a grant to `sim/world/brunt.gd` (the flag and the shared flight), or World builds it to this plan.

## The check

`launch_cuts_check.gd`:
- the cap and its side rule on built rows;
- the bound never drops a building whose plan would have won: lockstep off and on over the same launches, picks equal;
- the pity counter counting a dropped building;
- keyed noise: the same candidate gets the same draw whatever else is offered;
- the shared flight's plans equal to today's on a flat world;
- off unchanged.

Also: the launch tick before and after, with Performance's timers.
