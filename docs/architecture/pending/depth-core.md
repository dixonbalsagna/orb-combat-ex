# Depth in the core: the plan for D1 (paper, 2026-10-12)

Owner: Simulation and Engine. **Paper only: nothing here is built.** It answers the EP's five asks on Orb's depth headline. It builds on Game Design's `docs/design/depth.md`, World's `docs/world/depth-streets.md`, Encounter's `docs/director/fight-lanes-director.md` and Rendering's `docs/rendering/fighters-in-depth.md`. Line numbers are HEAD's (f659a95a). bh is a fighter height, 75 units.

## Rulings (the EP, 2026-10-12)

- The depth file is `data/combat/depth.json`, and it is Simulation's. Encounter's plan follows it.
- The core may read `WorldLanes.limits()` in place of its two constants.
- Part (a) is planned on the split below, which is with Encounter. It is built in scratch next, bit-identical with depth off, for the L4 window with Encounter.
- Whether a shove's depth part is held to the cap is with Game Design.
- The camera's start is "the pair's middle less 100". Camera sends the lines, or Simulation writes them in the scratch build.
- **Part (c) is built** (`fx-events.md`, "Depth on events"). The weight on the damage event is parked as `weight_event.py` and rides with the next regeneration.

## In short

| Part | What | Size | Golden |
| :--- | :--- | :--- | :--- |
| (a) | A fighter's depth outside a flight: a depth velocity for a locked fighter, a capped ease for a free one, and the contact rule against buildings | about 80 lines in `fighter.gd`, 10 elsewhere, 8 parity cases | No match moves. One data-hash vector moves if the depth file joins the data hash |
| (b) | State and hash with depth on: one new number a fighter, hashed only when depth is on | 4 lines | None with depth off |
| (c) | A depth on the view's particles | about 12 lines in `view/fx.gd`, 1 parity case | None |
| (d) | The camera's start at a crossing | Camera's lines, my review and gate | None, if the default start gives the same bits |
| (e) | Snapshots | A design, below. The build is a window of its own, about 300 lines | None: it only reads and restores |

**One finding first.** The core clamps a fighter's depth to `SimConst.Z_FRONT` and `Z_BACK`: +5 and -27 bh. World's three streets run from +2.5 to -29.5 bh. With depth on today, a fighter could stand in the foreground row and could not reach the back of the back street. Part (a) reads the band from `WorldLanes.limits()` instead. With depth off nothing reads either.

## (a) A fighter's depth outside a flight

**Today** (L0 and L2, committed). `f.z` and `f.zT` exist and are hashed. `stepDepth` runs only when `S.depthOn`: a flight's depth is World's waypoint; in an exchange his home is `ex.z`; otherwise he eases to `zT` with no speed limit. A rush homes in depth. Nothing collides with a building, and every ground read is the plane's.

**The split.** Game Design asks for one sum and one cap. The director adds the causes. The core integrates, caps and collides.

| Fighter | Who sets what | What the core does |
| :--- | :--- | :--- |
| Locked, in a brawl | The director sets `f.vz`, as it sets `vx` and `vy` | Damps it with the same `lockedKeep` and moves him. A push along the line keeps its angle, because its x and z parts shrink alike |
| Free or charging | The director moves his home `zT`: the ease home, the magnet, the way out of a wreck. No stick steers depth | Eases `z` toward `zT`, at the cap at most |
| Launched, rushing, dropped | As today: World's waypoint, the rush's homing | No cap: a flight is not held to it |

- **The cap** is `depth.maxBhPerSec` (1.2), held where depth is integrated. So no cause can pass it, whoever adds one later.
- **The contact rule** is one function, called after the free, charging and locked moves when depth is on.
  - It asks World for the buildings along the step (`WorldStructures.along`) and sweeps the body from where he was to where he would be (`sweep`, with `WorldLanes.body()` and `depth.faceMarginBh`).
  - On a hit he is put at the face, and the part of his velocity that runs into it is ended: `vx` at a block's end, `vz` at a front or back face, `vy` on a roof. The rest of the step is swept once more, so a corner stops both. Two sweeps a fighter a tick at most.
  - This gives Game Design's four cases with no special code. In a street the depth part stops and the push goes on. At a crossing nothing is met. In an avenue the part along the street stops and he slides down the avenue. On a roof he stands.
  - Going up and over in a corner is the director's rule: it sets `vy`.
  - A wreck is not a standing building, so it is not met. A body that starts inside a standing box is put out by the face of least penetration, which `sweep` already reports.
- **In a street the test is skipped.** World builds nothing in a street lane. If his depth, with the margin, is inside one lane before and after the step, no sweep runs.
- **The ground is read at his depth.** The eight `groundY(S, f.x)` reads in `fighter.gd` gain `f.z`. World's function returns the plane's ground when depth is off or `z` is 0.
- **The switch.** `enabled` in the depth file sets `S.depthOn`, unless the setup says otherwise. A replay records its setup, so it replays the same. The core reads three numbers from the file: `enabled`, `maxBhPerSec`, `faceMarginBh`.

**What must stay bit-identical with depth off:** every match, replay and checkpoint in `golden.json`; the 30-match batch digest; the determinism checks. Every new line sits under `if S.depthOn`. Proof: parity against the untouched golden, then the golden regenerated and compared byte for byte.

**Checks** (parity, depth on, on a seed with a city):
1. A locked fighter's `vz` is damped and integrated as his `vx` is: the line's angle holds over 60 ticks.
2. The cap: no tick moves him more than 1.2 bh a second in depth outside a flight.
3. In a street: the depth part stops 0.5 bh from the kerb, and the part along the street goes on.
4. At a crossing: he passes the kerb line into the avenue.
5. In an avenue: the part along the street stops at the block's end, and the depth part goes on.
6. A corner stops both. A roof holds him.
7. Two thousand seeded pushes in a city: he is never inside a standing footprint below its roof, and never outside the band.
8. Three depth-on matches replay to the same hash.

**Cost a tick, depth on** (estimates from World's measured calls; the window measures them with the bench). In a street: a lane lookup, about 2 µs a fighter. In an avenue, over roofs or beside a block: `along` and one or two sweeps, 20 to 60 µs a fighter. The sim's tick is 120 to 350 µs on Orb's PC today.

**Sizes.** `fighter.gd` about 80 lines; `state.gd` 1; `hash.gd` 3; `sim.gd` 3; a loader for the three numbers, about 30; `parity.gd` about 160. One window, a day. It can be built in scratch now against a probe that sets `vz`, and applied when Encounter's D1 is ready to call it.

## (b) What state and the hash gain with depth on

| What | Where | Hashed |
| :--- | :--- | :--- |
| `f.z`, `f.zT`, `f.zWay`, the aim's depths, `ex.z`, `S.depthOn` | There since L0 | Always |
| The eight rows of ground | There since T | Only when depth is on |
| The buildings' district, shape and landmark | There since World's lanes window | Always |
| **New: `f.vz`** | `state.gd` | **Only when depth is on,** as the rows are. So the hash of a match with depth off does not change |
| The director's own (Encounter's to name): the line's angle and side, the carry and its ticks, the wait before the ease home | `DirS`, by my lines in `hash.gd` | Four to six numbers, only when depth is on |

The hash is taken at checkpoints, not every tick, so two more numbers cost nothing. The cost a tick is the contact rule's, above.

## (c) A depth on the view's particles

- `SimFxView.Part` gains `z`, set from the event's `z` at each of its eight spawn sites. A part does not move in depth.
- The ground a part lands on is read at its depth (`view/fx.gd` line 163).
- With depth off every event's `z` is 0, so every part's is 0 and the ground read is the plane's: the view is the same to the bit.
- Then Rendering's one line in `particle_view.gd`.
- Size: about 12 lines and one parity case (a spark at depth spawns its parts at that depth). No regeneration. **It needs nothing else, so it can go first,** with the tier cap or right after it. Game Design lists it as a condition of the switch-on.

## (d) The camera's start at a crossing

- `SimCamera` starts at `START_X + 350` (lines 11 and 17), and `reset()` reads no state. With `setup.start == "crossing"` the fighters stand 40,000 units away.
- The lines are Camera's. Under the sim's gate they must meet three things.
  1. The camera reads the state and writes nothing.
  2. The pair's middle is taken along the shortest arc (`x0 + sdx(x0, x1) / 2`), so a crossing near the seam is right.
  3. **For the default start the result is the same bits as today.** The goldens record the camera at every checkpoint. The default pair stands at 89,600 and 90,500, so "the middle less 100" is 89,950, which is `START_X + 350` exactly. "The middle" alone is 100 units off and would move every golden's camera record.
- `reset` has one caller, Rendering's `sim_host.gd` line 81, which must pass the state.
- My part: the review and the gate run. No golden should move.

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

## Order I suggest

1. The tier cap (built and proved in scratch; it waits for the tree).
2. (c), the particles' depth: small, and nothing else needs to land first.
3. (a) and (b): built in scratch against a probe, applied when Encounter's D1 calls it.
4. (d): when Camera sends its lines.
5. (e): on a go of its own.

## Questions

| For | Question |
| :--- | :--- |
| Encounter | Is the split right: the director sets `vz` on a locked fighter and moves `zT` for a free one, and writes depth nowhere else but a rush? What does it keep in `DirS` for the line and the carry? |
| The EP | The depth file's home. The brief says `data/combat/depth.json`; Encounter's plan says `data/director/depth.json`. One file: the core needs three of its keys, and its hash joins the data hash |
| Game Design | Is a shove's depth part held to the 1.2 cap? It is not a flight, so the core would cap it: a 1 bh shove then takes most of a second in depth |
| World | The band: may the core read `WorldLanes.limits()` in place of its two constants? |
