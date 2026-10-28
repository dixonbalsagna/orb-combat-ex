# Cloud brief: Simulation & Engine, buildings and trees as packed arrays

**Who you are.** You are the Simulation and Engine Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/simulation-engine.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/simulation-engine/*`, never to main, and report in the branch.

Godot: `$GODOT` if set, else the pinned Linux build as cloud-workflow.md says. Then read your report `docs/architecture/cloud-reports/2026-10-28-snapshot-tick.md` (NEXT 1) and `docs/net/cloud-reports/2026-10-28-desync-spectate.md`.

**Branch:** `cloud/simulation-engine/packed-structures` from origin/main.

**Goal.** This is your NEXT 1. Buildings and trees are 80% of the snapshot's take: 1.37 ms and 0.43 ms of 2.16. Move their per-tick fields into packed arrays on `SimState`:
- buildings: hp, alive, fmask, fdmg, marks, fled, popAlive, wear;
- trees: alive, burn.

Add a restore hook that points the shared objects at the restored arrays, so a snapshot copies arrays instead of walking objects.

**Grant (the EP's, for this brief only).** You may change the lines in `sim/world/` that read or write those fields, and the share-and-skip rule for them in `net/snapshot.gd`. List every non-Simulation line under CHANGES so World and Netcode can review it. No other director's files.

**Acceptance criteria:**
- the golden is byte-identical, and the state hash is identical tick by tick on a seeded match (hash order unchanged);
- `npm test --prefix sim` (the JS parity oracle) passes;
- the rollback, desync and spectator checks pass, and their negative controls still fail as they should;
- the take before and after, measured with `net/tools/rollback_bench.gd` and `tick_prof.gd` on the same machine, in the same run, on a quiet machine, and reported as numbers;
- these all pass, each with its last line in the report:
  - determinism, plain and `--intro`;
  - all World checks, gen2_soak and campaign_episode;
  - the standard gate set in cloud-workflow.md.

**If it can't be done without a hash change,** stop and report why instead of changing the hash.

**Report** as `docs/architecture/cloud-reports/2026-10-28-packed-structures.md` with these sections: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push the branch and end your turn.
