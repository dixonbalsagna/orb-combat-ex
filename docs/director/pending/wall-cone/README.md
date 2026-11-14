# Parked: a knock aims only at a wall inside its 20° cone, nearest by true distance (GW1b rider)

Encounter, 2026-11-15, sprint A1. Game Design's ruling is `docs/design/buildings.md` section 10. It's the background-ricochet half of Orb's ping-pong bug.
- **Built on the GW1a stack:** main + energy-on + gates-shipped + energy-on-pins + `../gw1a-pins/` + `../index-stage/`.
- `knock_wall_check` is re-cut on top of index-stage.

## What it does

**`DirLaunch._wall`:**
- A wall in reach and in the depth window, as before, is a candidate only when it is **inside the cone**: its depth off the blow's line is at most tan(`wallCone`) × its distance along it.
- Among those, the order is **true distance** (`wallBy` "trueDistance"). "line" is today's order, along x only.
- A walked wall (`DirWalk`) is held to the cone too.
- **No wall in the cone means no wall aim:** the knock flies its own line.
- Helpers: `_wallAt` (along, off, true distance), `_inCone`, and `_lineSlope`, the blow's depth slope.
  - `_lineSlope` reads 0 today: no knock carries a depth of its own (its flight is along x at the target's depth), and fighters in depth is off.
  - When a blow carries the stick's depth, that's the one function to read it.

**Data:** `launch.json` `knockBack.wall.wallCone` 20 and `wallBy` "trueDistance", with a comment key. With `wallCone` 0 or missing, today's rule.

**`knock_wall_check`:**
- `_firstWall` reads the same rule.
- The in-reach rows stand where the staged building is inside the cone (535 along for a building 188 deep).
- The in-reach row asserts that the knock aims where the rule says, a wall or none. "The wall takes him" applies when there's one.
- **New: Game Design's QA row.** Knocks are staged beside 24 indexed buildings, and each aim is measured against the blow's line: none may be more than 20° off it. **Negative control:** the cone off and the order along the line (today's rule) aims some far off it.

## The readings (`knock_wall_check`)

| Data | With the cone | Today's rule (the negative control) |
| :--- | :--- | :--- |
| The 9 November target (every place laid) | 14 of 24 aimed; **0 more than 20° off the line** (worst 18.1°) | 24 aimed; **24 more than 20° off** (worst 86.3°): every knock aimed into the background |
| Main's | 18 aimed; 0 more than 20° off (worst 19.5°) | 24 aimed; 24 more than 20° off (worst 87.9°) |

In reach, on the 9 November data the rule picks building 867 and the knock aims at it, and the wall takes him. On main's street the cone holds no wall a flight reaches from there, and the knock aims at none: the ruling's "no wall in the cone means it flies its line".

## Apply

On the stack above: `git -c core.autocrlf=false -c core.eol=lf apply wall-cone.diff grant-tools-schema.patch`.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `wall-cone.diff`: `sim/director/launch.gd`, `data/director/launch.json`, `sim/director/tools/knock_wall_check.gd` | Encounter | 4068751bb1cfa9b53dfc7b332157e7eb69d619ca |
| `grant-tools-schema.patch`: `tools/schemas/director-launch.schema.json`, the two keys in `knockBack.wall` (closed) | Tools | 39fe5bb27940ddbbebaa4a4342e5489c1387a14e |

## Proof

Records are in `docs/director/runs/4327cfbb/wall-cone/`, and every output went through `tools/gate.mjs`.
- **Every director check passes on the 9 November data with the rider:** 41 of 41.
- **The golden gives the same lines with and without the rider** on that data. Both fail against main's golden, which is energy-on's and the target data's move.
  - The rider changes nothing while the knock's wall aim is off, and **`knockBack.wall.enabled` is false in both main's data and the 9 November data**.
  - So in play today the cone acts only through the walk's walked wall (off in the build) and the checks that force the aim. It rides GW1b, with the golden re-recorded there if the aim is turned on.
- On main's data, with the cone's data in place, `knock_wall_check` and `walk_check` pass.
- Validate: 0 errors with the schema grant.

## NEEDS FROM EP

- **Tools:** the schema grant.
- **Game Design, a finding:** the knock's wall aim is off in the build that Orb plays, so the background ricochets Orb saw weren't knocks aimed at walls.
  - **The launch planner's BUILDING SMASH offers buildings "in any row"** (`DirLaunch`, `WorldBrunt.candidates`). Its only bend limit is the stick's tilt in the vertical plane. Nothing holds a launch's depth off its line, so a launch can still aim deep into the background.
  - Whether section 10's 20° cone also governs launches is GD's call. It would be the same `_wallAt` and `_inCone` in the planner's candidate loop, a small rider.
