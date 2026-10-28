# Cloud brief: Simulation & Engine, a cheaper snapshot and a cheaper tick (for rollback)

**Who you are.** You are the Simulation and Engine Director for Orb Combat EX, working as a cloud session. Read in this order: CLAUDE.md, your charter `docs/directors/simulation-engine.md`, and **`docs/ep/cloud-workflow.md`**. The cloud workflow overrides your charter where they differ: you commit and push, but only to `cloud/simulation-engine/*` branches, never to main, and you report in the branch. Then read `docs/net/rollback.md` and `docs/net/cloud-reports/2026-10-28-rollback-core.md`: the rollback core landed on main, and its NEEDS items 1 and 2 are this brief.

**Branch:** `cloud/simulation-engine/snapshot-tick`, from origin/main.

**1. The snapshot.** Per-match constants should leave the per-tick state, so every rollback snapshot shares them instead of copying them:
- a building's generation fields: x, w, h, kind, seed, district, shape, landmark, floors, idx, place, plan, z, d, row, maxhp and pop;
- a tree's x and h;
- `S.bIdx` and `S.base`.

Move them into one immutable per-match object that SimState references, so net/snapshot.gd's copier can share that reference. Buildings are 118 of about 210 objects and about 3,000 of 5,000 scalars. The goal is roughly half the snapshot's cost and size.

The EP grants the lines in `sim/world/` that read or write these fields, as long as every line's meaning is unchanged. List each one under CHANGES as World's, and keep `sim/world/tools/*` behaviour identical.

**2. The tick.** Profile `SimCore.step` natively, headless, over a seeded AI match and a gen 2 planet match. Today it averages 0.60 ms with a p99 of 1.53 ms on this kind of machine. Cut the top items without changing a single bit of the state; the golden is the proof. The aim is about 0.3 ms native, so a phone at x4 can afford rollback.

**Acceptance criteria:**
- the golden byte-identical, and parity passing;
- determinism plain and with `--intro`;
- the standard gate set in cloud-workflow.md;
- `net/tools/rollback_check.gd` (the default profiles plus `--negative-control`) passes;
- `net/tools/rollback_bench.gd` before and after, with the snapshot's take and restore times, its bytes, and the tick's mean and p99.

**Report** as `docs/architecture/cloud-reports/2026-10-28-snapshot-tick.md`: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push and end your turn.
