# Depth in the core: the plan for D1, and part (a) as built in scratch (2026-10-12)

Owner: Simulation and Engine. **Part (a) is built and proved in scratch, and parked in `depth-a/` beside this page; part (c) is on main; the rest is paper.** It answers the EP's five asks on Orb's depth headline. It builds on Game Design's `docs/design/depth.md`, World's `docs/world/depth-streets.md`, Encounter's `docs/director/fight-lanes-director.md` and Rendering's `docs/rendering/fighters-in-depth.md`. Line numbers are HEAD's (f659a95a). bh is a fighter height, 75 units.

## Rulings (the EP, 2026-10-12)

- The depth file is `data/combat/depth.json`, and it is Simulation's. Encounter's plan follows it.
- The core may read `WorldLanes.limits()` in place of its two constants.
- Part (a) is planned on the split below, which is with Encounter. It is built in scratch next, bit-identical with depth off, for the L4 window with Encounter.
- A shove's depth part is not capped (Game Design, 03dfbebb): a knock-back is one motion along the line. The sidestep is assumed exempt and a give-ground step capped until Game Design rules; the cap's exemptions are data.
- Encounter agreed the split, with two additions: its closing step needs to move a fighter in depth, and a rush must be able to end a little to one side. Both are in the build.
- The camera's start is "the pair's middle less 100". Camera sends the lines, or Simulation writes them in the scratch build.
- **Part (c) is built** (`fx-events.md`, "Depth on events"). The weight on the damage event is parked as `weight_event.py` and rides with the next regeneration.

## In short

| Part | What | Size | Golden |
| :--- | :--- | :--- | :--- |
| (a) | A fighter's depth outside a flight: two depth velocities, a capped ease for a free fighter, the contact rule against buildings, the director's step call. **Built in scratch** | 170 lines in `fighter.gd`, a 115-line loader, 40 elsewhere, one parity check of ten cases | **None.** The golden regenerates byte for byte |
| (b) | State and hash with depth on: two numbers a fighter, one a rush and six of the director's, hashed only when depth is on. **Built in scratch** | 6 lines | None with depth off |
| (c) | A depth on the view's particles | about 12 lines in `view/fx.gd`, 1 parity case | None |
| (d) | The camera's start at a crossing. **Built in scratch** (Camera had sent no lines) | 5 lines in `view/camera.gd` | None: the default start gives the same bits |
| (e) | Snapshots | A design, below. The build is a window of its own, about 300 lines | None: it only reads and restores |

**One finding first.** The core clamps a fighter's depth to `SimConst.Z_FRONT` and `Z_BACK`: +5 and -27 bh. World's three streets run from +2.5 to -29.5 bh. With depth on today, a fighter could stand in the foreground row and could not reach the back of the back street. Part (a) reads the band from `WorldLanes.limits()` instead. With depth off nothing reads either.

## (a) A fighter's depth outside a flight: as built in scratch

**The build** is `depth-a/`: `depth_a.py` (the edits), `depth_a_checks.py` (the parity checks), `src/depth.gd` (the new `SimDepth`) and `src/depth.json` (the new `data/combat/depth.json`). From the repo root: `python docs/architecture/pending/depth-a/depth_a.py .`, then `depth_a_checks.py .`, then an import, because `SimDepth` is a new class. Nothing of it is in the tree.

**Before it** (L0 and L2). A fighter eased to his home depth with no speed limit, his home in an exchange was `ex.z`, nothing met a building, the band was two constants and every ground read was the plane's.

**Who sets what.**

| Fighter | The director | The core |
| :--- | :--- | :--- |
| Locked, in a brawl | Writes `f.vz` where it writes `vx` and `vy`. A cause the data exempts from the cap goes in `f.vzX` | Damps both with the same `lockedKeep` and moves him. A push along the line keeps its angle |
| Free or charging | Moves his home, `f.zT`. No stick steers depth | Eases him to it, at the cap at most. A velocity in depth carries his home along, so a shove leaves him where it sent him |
| Rushing | Sets the rush, with `Rush.offZ` to end a little to one side of the target | Homes, as before. No cap |
| A blow's closing step, a placement | Calls `SimFighter.stepTo(S, f, x, y, z)` | Moves him there through the contact rule. No cap |
| Launched | Nothing | World's waypoint, as before |

**Decisions.**
- **The director never writes a fighter's depth.** For its closing step it calls `stepTo`. So every move in depth that is not a flight goes through the contact rule in one place.
- **Two velocities, and not one with a flag.** `vz` is always held to the cap and `vzX` never is, so QA's hard row on the drift can be read off one field. Which cause goes where is data: `capExempt` in the depth file, read by `SimFighter.addDepth(f, cause, v)` and `SimDepth.isExempt(cause)`.
- **The core no longer takes `ex.z` as the home of a fighter in an exchange.** That rule would pull both fighters of a brawl to one depth and flatten the line. `ex.z` stays the director's, hashed as before.
- **The band is World's table** (`WorldLanes.limits()`), read once into `SimDepth.zFront` and `zBack`.
- **The depth file joins a replay's data hash only once its switch is on.** A match with depth off reads none of it, so the golden's data vectors did not move.

**The contact rule** (`SimFighter.contact`, after the free, charging, dropped and locked moves, and inside `stepTo`).
- His step this tick is swept against the standing buildings along it, with World's `along` and `sweep`. His centre keeps the body's half extents from a face, and `faceMarginBh` at least: 0.5 bh, which leaves 4 bh of depth in a street.
- At a face he is put there, the part of his velocity into it ends, and the rest of the step is swept again: three times at most, once an axis.
- In a street the depth part stops at a block's face and the part along the street goes on. At a crossing nothing is met. In an avenue the part along the street stops at a block's end and he slides down the avenue. A roof holds him, and he walks on it.
- A wreck is not a standing building. A body that starts inside a standing one is put out by its nearest face.
- **In a street lane no sweep is made.** World builds nothing there, and a check holds World to that.
- **What it does not do.** Going up and over in a corner is the director's: it sets `vy`. Keeping a brawl out of a gap between two buildings of a block is the director's too, with World's `depthRoom`: the core stops a body at buildings, and not at a lane's edge where nothing stands.

**The ground** is read at his depth in every branch of his step. World's function gives the plane's ground when depth is off. A downed fighter lies on the surface under him, which may be a roof.

**What Encounter's D1a calls.**

| For | Call or field |
| :--- | :--- |
| The switch | `enabled` in `data/combat/depth.json`, or `"depth": true` in a match's setup |
| A push, the carry, the ease home of a locked pair | `f.vz`, or `SimFighter.addDepth(f, "push", v)` |
| A shove, a sidestep | `f.vzX`, or `addDepth` with the cause |
| A free fighter's home | `f.zT` |
| A rush that ends to one side | `Rush.offZ` |
| A closing step or a placement | `SimFighter.stepTo(S, f, x, y, z)`. It returns false when a face stopped it short. With depth off it is the plain assignment of x and y |
| A drop with a depth part | `SimFighter.drop(S, f, ticks, vx, vy, vz)` |
| Its own state | `S.dirS.lineSin`, `lineSide`, `carryZ`, `homeWait`, `sideT`, `sideWay`: reset at a new match, hashed only with depth on |
| The numbers | `SimDepth.cap` (units a second), `margin`, `rx`, `ry`, `rz`, `zFront`, `zBack`, `lanes` |

After a face stops him in depth, his velocity into it is 0 and his home is where he stands. The pair's spacing is the director's: each fighter meets a face by himself.

**Proof, on a clean export of 33c6f5bd.**
- Parity against the committed golden, unregenerated: 52 of 52. The golden regenerated is byte-identical.
- npm's five stages, determinism (plain, and with intros), the seam sweep, the loader check, Rendering's depth check and World's lane and depth checks all pass.
- The new check, "a fighter's depth outside a flight, and the contact rule", has ten cases: the data and the camera's start; a push along a line keeps its angle; the cap holds `vz` and not `vzX`; the street; the crossing; the avenue; a roof, and a body put out of a building; 2,000 seeded pushes through the city with no tick inside a standing building or outside the band; the director's step; the hash; three matches with depth on replayed to the same hash.
- The old check, "depth in the core", is brought to the new rules: the ease is capped, the band is World's, a rush's offset, and an exchange's depth moves nobody's home.
- Proved again on f4e57e63 after the schema word went in: parity 52 of 52 on the committed golden, and the golden regenerated byte-identical.

**Cost, measured** (the same export, Orb's PC under load, where a whole tick is about 390 µs).
- AI matches started at the crossing, 20,000 ticks, twice: 396 and 392 µs a tick with depth off, 393 and 413 with it on. The difference is inside the noise.
- One fighter pushed through the city for 20,000 ticks, two thirds of them outside a street lane: his step is 15 µs with depth off and 33 µs with it on. So the contact rule is about 26 µs for a tick that sweeps, and nothing in a street. The 99th percentile of his step is about 120 µs.

**Limits.**
- A body put out of a building it starts inside can move by the whole penetration in one tick.
- A dropped fighter who lands on a roof stops there but sends no `drop_land`.
- **A body's point.** World's sweep took a fighter's point as the body's middle, and the core's is his feet. World is moving its sweep and `blocked` to his feet. `depth_a.py` reads World's file and writes the contact rule for whichever the tree has, so it applies before that window and after it. With World's uncommitted files laid over an export, both depth checks pass.
- With depth forced on today, before D1a, fighters no longer return to the plane in an exchange. World's and Rendering's probes with depth on will read differently.
- Tools has no schema for the depth file yet: the validator warns, and does not fail.

## (b) What state and the hash gain with depth on

| What | Where | Hashed |
| :--- | :--- | :--- |
| `f.z`, `f.zT`, `f.zWay`, the aim's depths, `ex.z`, `S.depthOn` | There since L0 | Always |
| The eight rows of ground | There since T | Only when depth is on |
| The buildings' district, shape and landmark | There since World's lanes window | Always |
| **New: `f.vz` and `f.vzX`** | `state.gd` | **Only when depth is on,** as the rows are. So the hash of a match with depth off does not change |
| **New: `Rush.offZ`** | `state.gd` | Only when depth is on |
| **New, the director's:** `lineSin`, `lineSide`, `carryZ`, `homeWait`, `sideT`, `sideWay` | `DirS` | Only when depth is on |

The hash is taken at checkpoints, not every tick, so the new numbers cost nothing there. The cost a tick is the contact rule's, above.

## (c) A depth on the view's particles

- `SimFxView.Part` gains `z`, set from the event's `z` at each of its eight spawn sites. A part does not move in depth.
- The ground a part lands on is read at its depth (`view/fx.gd` line 163).
- With depth off every event's `z` is 0, so every part's is 0 and the ground read is the plane's: the view is the same to the bit.
- Then Rendering's one line in `particle_view.gd`.
- Size: about 12 lines and one parity case (a spark at depth spawns its parts at that depth). No regeneration. **It needs nothing else, so it can go first,** with the tier cap or right after it. Game Design lists it as a condition of the switch-on.

## (d) The camera's start at a crossing

- `SimCamera` starts at `START_X + 350` (lines 11 and 17), and `reset()` reads no state. With `setup.start == "crossing"` the fighters stand 40,000 units away.
- **Built in scratch** (in `depth-a/`), because Camera had sent no lines: `reset(S = null)` puts the camera on the pair's middle less 100 when it is given the match, and is today's `reset()` when it is not. The file is Camera's. Under the sim's gate the lines meet three things.
  1. The camera reads the state and writes nothing.
  2. The pair's middle is taken along the shortest arc (`x0 + sdx(x0, x1) / 2`), so a crossing near the seam is right.
  3. **For the default start the result is the same bits as today.** The goldens record the camera at every checkpoint. The default pair stands at 89,600 and 90,500, so "the middle less 100" is 89,950, which is `START_X + 350` exactly. "The middle" alone is 100 units off and would move every golden's camera record.
- `reset` has one caller, Rendering's `sim_host.gd` line 81. It must pass the state after `newMatch` for a crossing start to be framed; until then nothing changes.
- No golden moved: the check asserts the default start's number to the bit, flipped or not.

## (e) Snapshots: a design, no build

**Why.** Rollback for online versus saves the state every tick and restores it to re-run up to about eight ticks. The co-op study needs the world block saved between encounters (`docs/research/co-op-brawler-part-2.md` section E). There is no snapshot today: a replay re-runs from the seed.

**What the state is.** One object tree, `SimState`, with 25 small classes inside it in `state.gd`, holding numbers, strings, flags, arrays, packed arrays and references to each other (a fighter and his exchange, who launched him, a rush's target). The random stream is one integer. The director's state is inside it.

**The design.**
- `SimSnapshot.take(S)` returns a copy, and `SimSnapshot.put(S, snap)` restores it in place, so every holder of `S` stays valid.
- **The copier is built from the classes themselves, not written field by field.** At start it reads each class's property list once and makes a copy plan: a value is copied, a packed array is assigned (Godot copies it only when it is next written, so the terrain costs nothing until a crater digs), an array of state objects is walked, and a reference to another state object is kept as an identity through a map. A new field is picked up with no upkeep.
- **Derived parts** that the hash leaves out but the step reads (the lanes table, the lowest-ground row, World's spatial indexes) are copied too, or rebuilt by the function that builds them. Each is listed once, and the test below catches a miss.
- **The world block** for a campaign is a subset by name (World's list: deformation, craters, scorch, water, rubble, each building's stage and floors, trees, civilians; a player's wounds, energy and forms). Only this form goes to disk, as bytes with a version and the data hash. Rollback never leaves memory.

**The proof** (a parity check, and the build's acceptance).
1. On every golden match, at twenty ticks spread over it: take; run 600 ticks, keeping each tick's hash and event digest; put; the hash at once equals the hash at the take; run again; every hash and digest is the same.
2. Take, then overwrite every field with noise, then put: the hash is the take's.
3. The cost of a take and a put: mean and 99th percentile, from the bench.

**What it costs, as estimates.** A take should be 50 to 150 µs in GDScript, because the large arrays are shared until written. Re-running eight ticks is 1 to 3 ms on Orb's PC, and 5 to 10 times that on the slowest targets, which is over a frame. So the rollback window on slow devices is Net's question, not the snapshot's.

**Risks to settle before the build.**
- **State outside `S`.** The sim has 192 static variables. They should all be data read at load and tables. One that held match state would break a restore without a trace, so the build starts with an audit of them.
- **Events on a re-run.** A re-run tick sends its effect events again. The host must mark such ticks so Rendering and Audio do not play them twice. That is the host's and Net's.
- **The view.** The camera and the particle view sit outside the gameplay state. A rollback either snapshots them too or lets them run on. Camera and Rendering say which.

**Size.** The copier and its checks are about 300 lines, in a window of their own. Nothing in the step changes, so no golden moves.

## Order

1. Done: the tier cap and part (c), on main (9a8b3a2c).
2. Parked: parts (a), (b) and (d), for the depth window with Encounter's D1a.
3. Paper: (e), on a go of its own.

## Open

| For | Question |
| :--- | :--- |
| Game Design | Whether the sidestep and a give-ground step are under the cap. The build takes the sidestep as exempt and the give-ground step as capped; either is one word in the data |
| Tools | A schema for `data/combat/depth.json`: `schema` (the word `combat.depth/1`, which the loader checks), `enabled` (true or false), `maxBhPerSec` (a number above 0), `faceMarginBh` (a number, 0 or more), `capExempt` (a list of distinct causes from push, carry, home, magnet, shove, sidestep, giveGround), and the notes |
| Rendering | Its host's `cam.reset()` passes the state after `newMatch`, so a start at a crossing is framed |
| Encounter | The director's own depth numbers join `data/combat/depth.json`, which is Simulation's: it lists them and Simulation adds them |
