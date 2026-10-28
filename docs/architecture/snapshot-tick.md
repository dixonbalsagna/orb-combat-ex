# A cheaper snapshot and a cheaper tick (for rollback)

Owner: Simulation and Engine. 2026-10-28, cloud brief `docs/ep/cloud-briefs/simulation-snapshot-tick.md` (Netcode's NEEDS 1 and 2 in `docs/net/cloud-reports/2026-10-28-rollback-core.md`). Report: `cloud-reports/2026-10-28-snapshot-tick.md`.

## 1. The snapshot: per-match constants are shared

- **A building's generation fields live in its `g`, a `SimState.BuildingGen`** (district, shape, landmark, floors, idx, place, plan, z, d, row, x, w, h, maxhp, kind, pop, seed). A tree's x and h live in its `SimState.TreeGen`.
- **They still read and write as fields of the building.** `b.x` is a property that reads `b.g.x`. About 500 lines in Rendering, UI, Audio, the director and the tools read these fields, so none of them changes. A read costs about 0.15 µs more than a plain field. On this machine the whole tick costs about 1 to 2% more from these reads, which the `pow` cache (section 2) more than pays back.
- **Copy on write.** A `g` is sealed at the end of the tick or match piece that made it (`SimState.sealFresh`, called by `SimCore.step` and by each `MatchJob` piece). A write to a sealed `g` first gives the building a fresh copy. So a `g` that a snapshot holds never changes. The calm turn's renumbering of districts and indices (`world/epoch.gd`, `world/structures.gd buildIndex`) writes this way, and no World line had to change.
- **`S.base` and `S.bIdx` are shared by contract.** Each is built whole before the match and only ever replaced whole, by the calm turn. A Godot packed array is a shared reference, not copy-on-write, so a write in place during play would be a desync. `rollback_check` would catch one. Every in-place write in `sim/world/` today is to a world under construction (terrain, planet_world, rivers).
- **What `net/snapshot.gd` reads: a class's `SNAPSHOT` constant**, `{"share": [...], "skip": [...]}`.
  - The copier assigns a "share" field (no copy).
  - It drops a "skip" field: the building's x is not a field of the copy, only a view of `g`.
  - `measure()` and `aliasAudit()` leave both kinds out.
  - `SimState`'s rule is `{"share": ["base", "bIdx"]}`. `Building` and `TreeState` share `g` and skip the names in their gen class's `FIELDS`.

## 2. The tick: where it goes

`sim/core/tools/tick_prof.gd` times `SimCore._step` part by part over a seeded match. A twin sim, stepped afterwards by `SimCore.step` with the same inputs, must reach the same `SimHash`, which proves the timed copy is the step.

```
godot --headless --path . --script res://sim/core/tools/tick_prof.gd -- [--ticks=3600] [--seed=1] [--planet|--gen2] [--bots]
```

Run the twin after the timed sim, never interleaved with it. Two sims stepped in turn rebuild World's per-world caches (`WorldContact._buildSurf`) every tick, and the profile then blames World for about 200 µs a tick that a real match never spends.

On an AI match (hand-made world, seed 1, 3,600 ticks):

| part | share |
|---|---|
| `DirExchange.dirUpdate` (Encounter) | about 45% |
| `SimControl.control`: the AI (`DirAI.aiInput`) and `requestAttack` (Encounter) | about 30 to 38% |
| `SimFighter.stepFighter` with World's contact | 8 to 16% |
| the mood, the tick's fx mark and the rest of the core | about 8% |

A self-time profile (every sim function wrapped, in a scratch copy) counts 845 function calls a tick. About 450 of them are the director's data accessors and its per-fighter integer accessors, through chains of four or five calls:

- `DirInterrupt.on()` → `DirData.perfectBlock()` → `_ensure` → `_prof` → `tplProfile`;
- `DirBrawl._s` → `_size` → `DirAlchemy._size` → `DirInterrupt.gi` → `_size`.

Each call costs 0.3 to 4 µs in GDScript.

- **Applied (sim/core):** `SimDetMath.pow` keeps its last 16 answers by argument. The tick asks `pow(0.55, dt)` and similar calls again and again, and a hit returns the double it computed, so nothing changes by a bit.
- **Pending (Encounter's files):** `pending/tick-accessors/apply-tick-accessors.cjs`, ten anchored edits in seven director scripts:
  - `DirData.perfectBlock` remembers its block for the data and profile it was read from;
  - `DirBrawl`, `DirRally` and `DirGrapple`'s `cfg()` remember their block for the data dictionary they read (tools edit those blocks in place, so the cached block is the same object);
  - the dirI accessors check the size before calling the sizing chain.

  It cuts the tick's calls from 845 to 625 and the AI match's p50 by about 15% (819 to 694 µs), and the golden stays byte-identical (checked in a scratch copy).
- **What would reach 0.3 ms:** only the director's own structure. Its `tick` functions run twenty sub-ticks a tick, and the AI's `_move` and `aiInput` bodies are the next largest. That needs Encounter's design, not caches.

## 3. What is left in the snapshot

With the split, the buildings and trees are still 80% of a pooled take. Most of that is about 5 µs of the copier's bookkeeping per object (the identity map, the pool, dispatch), against a field copy of about 1.4 µs. Halving the take means fewer objects. The next step would make the buildings and trees shared objects, with their per-tick fields (hp, alive, fmask, fdmg, marks, fled, popAlive, wear; alive, burn) as packed arrays on `SimState`. That is World's and Netcode's as much as mine, because a restore has to re-point the shared objects at the restored arrays.
