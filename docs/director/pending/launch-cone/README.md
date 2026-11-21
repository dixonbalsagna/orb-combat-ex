# Parked: every aimed launch stays inside the blow's 20° cone (GW1b rider, on wall-cone)

Encounter, 2026-11-15, sprint A1. Game Design's second ruling in `docs/design/buildings.md` section 10: the launch planner offers a candidate with a target only if its target lies inside the same 20° cone around the blow's line, in the ground plane, with the stick's lean in the line. **It's the likely fix for Orb's background ricochets.**

**Built on `../wall-cone/`** (and through it on gw1a-pins and index-stage, on the GW1a stack). There's no data change: it reads wall-cone's one number, `knockBack.wall.wallCone` ("the same 20° cone").

## What it measured today, on Orb's 9 November data

30 computer-against-computer matches, planet 7. Each launch aimed at a building was measured against the blow's line (the launch's direction, at the launched body's depth) at the tick it left.

| | Launches | Aimed at a building | More than 20° off the line | Worst | By 10° bins (0 to 90+) |
| :--- | ---: | ---: | ---: | ---: | :--- |
| **Today** | 214 | 37 | **26 (70%)** | 139.9° | 5, 6, 7, 4, 3, 2, 1, 3, 4, 2 |
| **With this rider** (the re-cut) | 209 | 20 | **0** | 18.7° | 10, 10, 0 … |
| The first cut (a running swing's remaining turn refused) | 207 | 18 | 0 | 18.7° | 8, 10, 0 … |

**Where they came from.** The planner's BUILDING SMASH offers buildings "in any row". A cone in the planner alone wasn't enough, because some wide aims came through **the choreographer's swing**:
- At a launch, the swing picks a building and turns the fight's ring so the building lies ahead, by up to `maxDeg` (180°).
- The planner then plans in the turned frame, where the building is straight ahead.
- Measured from the blow's own line, it's more than 100° off: the world swings round and the fighter is sent at a building that was behind him.
- That's the background ricochet of Orb's ping-pong, and it reaches the planner through the swing. With the cone in the planner alone, 10 of 25 aimed launches were still wide, the worst 147.6°.

**About half the building smashes go.** With the rider, 20 launches are aimed at a building where today there are 37. The ones that remain are the ones in front.

## What it does

| Where | Change |
| :--- | :--- |
| `DirLaunch` (the planner's building loop) | A building outside the cone isn't offered: neither the smash into it nor the send inside it. **The cone is measured from the blow's actual line at contact, wherever a running swing has got to** (GD's ruling, §10). The plan may read a turned line (the swing's pick for this launch, or the line a running swing ends on), so each building is placed in the frame as it is now, read from its pose and never written (new helper `_coneAt`, and `_inConeDeg`). The turn a running swing still has to make refuses nothing. No building in the cone: the launch flies its own line |
| `DirSwing._launchPick` | A launch's swing turn is capped at the cone (it was `maxDeg`, 180). With `bigMin` 16 the swing still makes a launch's big turn, 16° to 20°. Measured from the actual line, that turn counts against the 20° |
| `DirSwing.actualFrame` (new) | The frame as it is at contact, before any plan's turn |
| **MOUNTAINSIDE** | Unchanged: it aims at a slope on the line, forward only (the contact rule) |
| **The visit's places** | Unchanged: they have their own 4° turn cone, and the visit is off in data |
| `sim/director/tools/launch_cone_check.gd` (new) | Game Design's QA row: computer-against-computer matches (`--matches`, the default is 6), every aimed launch measured. `--cone=off` (the cone 0 in memory, today's planner) is the measurement and the negative control. With no aimed launch in the run it says so |
| `sim/director/tools/walk_check.gd` | Its buildings are those inside the cone from its staging (700 along). It runs on a lane world with the ring held still (`plans.everywhere` and the swing held off in memory, and put back after). See below |

### walk_check, and why it changes

On the 9 November data, with the rider, walk_check reached 0 of 10. A probe build (prints only, in `runs/…/walk-probe.txt`) showed why:
- **Today's passes there were never the walk.** Each "reach" was the planner's smash into another building, 27° to 64° off the line (pick b0, hit b317 at 55°). The walk's own building was never hit, and "switch off" reached as often as "leaning" did. Those are the sends the ruling removes.
- **With `plans.everywhere`, a street's front row stands 187.5 off the line.** It's inside the cone from 700 along (tan 20° × 700 is 255), but the walk brings the pair to 160 to 385 along, where it's 26° to 50° off. The ruling gives that reach to **the street turn** (terrain-plan step 7: Camera turns the shot so a street's front row lies along the line), not to an aimed send.
- **The swing turns the ring under the three blows** on that data (in 4 of the 10 runs it still had 30° to 48° to turn at B), so the walk's building moves against the line.

So walk_check now tests the walk on a lane world with the ring still, which is what it was written for. There it reaches 7 of 10, on both data sets. The walk itself is off in the 9 November build (`wallPush`).

## Apply

On the stack with wall-cone: `git -c core.autocrlf=false -c core.eol=lf apply launch-cone.diff`.

| Patch | Owner | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `launch-cone.diff` (re-cut for B-17; before it 0dfc6cc9, and the first cut 031c647c): `sim/director/launch.gd`, `swing.gd`, `tools/walk_check.gd`, the new `tools/launch_cone_check.gd`, and five seeds in `tools/bark_reads_check.gd` | Encounter | a541d1fdff785928bf0eac12269db97c2bdbfd81 | 800973e08eb1 |

## Proof

Run on main 4327cfbb + energy-on + gates-shipped + energy-on-pins + gw1a-pins + index-stage + wall-cone + this park, on two data sets: Orb's 9 November target data, and main's data with wall-cone's keys. Records are in `docs/director/runs/4327cfbb/launch-cone/` (`lcga` the 9 November data, `lcgm` main's, `lc` the counts and the walk probe), and every output went through `tools/gate.mjs`, with no script error in any.

- **Game Design's QA row, 30 matches on the 9 November data:** 0 of 18 aimed launches more than 20° off (worst 18.7°). Today's planner (`--cone=off`): 26 of 37 (worst 139.9°).
- **The cone in the planner alone** (no swing cap and no turn taken off, a scratch variant): 10 of 25 still wide, worst 147.6°. So the swing half is needed.
- **Every director check passes on both data sets:** 42 of 42 (the 41, and `launch_cone_check`). On main's data, `launch_cone_check` saw no aimed launch in its 6 matches, and it says so.
- `walk_check` 7 of 10 on both, `knock_wall_check` 0 failed on both.
- **The golden moves, as expected.** With the rider on and off (`wallCone` 0) on the same tree, 1 of 11 rows differs on each data set, late in one match (the 9 November data: match 6 from checkpoint 130 of 151; main's: match 0 from checkpoint 133). The other 8 matches, the 2 replays and tick 0 are the same.
- `parity.gd` fails on both trees, and every failing line comes before any launch: tick-0 state, the roster hash, the intros and a planet slice. That's the stack's data against main's committed golden, not this park.
- Validate: 0 errors. The determinism lint is clean. The two-fighter count is 365 of 365.

## NEEDS FROM EP

- **The golden moves:** it changes which launches are offered whenever buildings are near, so it rides GW1b with its re-record.
- **Game Design confirmed both readings** (§10): the blow's line is the line before the launch's own turn, so a launch's big swing is held to 16° to 20°; and a front-row building on a plan-streets world is the street turn's, not the walk's. Nothing here stops the swing's other causes (the chase, the brawl, the story) from turning the world.

## Re-cut for B-17 (2026-11-21): bark_reads_check's seeds

On the GW1b stack (main b0e20f9a), `bark_reads_check` failed from this park on: its row "low_health_swing fired in the seeded matches" saw none in its three seeded matches, because the cone changes those matches. The check now runs five seeds (12345, 777, 31337, 4242, 2026), and all three beats fire across them. On the GW1a data this park moves the golden in 1 of 11 rows (match 2, from checkpoint 91). The lane is in `docs/director/runs/b0e20f9a/b17-lane/`.

## Re-cut (2026-11-15): Game Design's ruling on a running swing

The first cut took a running swing's remaining turn off the cone, so while a swing still had more than 20° to turn, no building was offered at all (4 of walk_check's 10 runs on the 9 November data). Game Design ruled that the cone is measured from the blow's actual line at contact, wherever the swing has got to, and that the turn still to come refuses nothing. The re-cut measures each building in the frame as it is at contact (`_coneAt`, `DirSwing.actualFrame`) and drops `DirSwing.planTurn`.

**Proof of the re-cut** (records in `docs/director/runs/4327cfbb/launch-cone-v2/`, every output gated, no script error):
- GD's QA row, 30 matches on the 9 November data: 0 of 20 aimed launches more than 20° off (worst 18.7°).
- Every director check passes on both data sets: 42 of 42. `walk_check` reaches 7 of 10 on both.
- The golden moves as the first cut's did: with the rider on and off on the same tree, 1 of 11 rows differs on each data set (the 9 November data: match 6 from checkpoint 130; main's: match 0 from checkpoint 133).
- `parity.gd`'s lines are identical to the first cut's on both trees (all before any launch: the stack's data against main's golden).
- Validate: 0 errors. The determinism lint is clean. The two-fighter count is 365 of 365.
