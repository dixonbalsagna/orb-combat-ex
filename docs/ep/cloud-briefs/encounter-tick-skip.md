# Cloud brief: Encounter Systems, the director's tick (accessors, then skipping idle sub-ticks)

**Who you are.** You are the Encounter Systems Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/encounter-systems.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/encounter-systems/*`, never main; report in the branch.

Godot: `$GODOT` if set, else the pinned Linux build as cloud-workflow.md says. Then read Simulation's report `docs/architecture/cloud-reports/2026-10-28-snapshot-tick.md`, NEEDS 2 and 3.

**Branch:** `cloud/encounter-systems/tick-skip` from origin/main.

**Build:**
1. **Simulation's tick accessors,** with your grant. In a scratch copy of the branch, never anywhere else, run `node docs/architecture/pending/tick-accessors/apply-tick-accessors.cjs <your checkout>`. It touches alchemy, brawl, data, grapple, interrupt, rally and zip.gd. Calls drop from 845 to 625 a tick, and the golden stays byte-identical. If it no longer applies cleanly on main, because W2 and W3 changed data.gd and brawl.gd since it was written, apply its intent by hand and say so. Commit this step on its own.
2. **Skip idle sub-ticks.** `DirBrawl.tick` and its twenty sub-ticks, `DirBrawl.aiInput` and `_move`, and `DirAI.aiInput` are now the largest items. Make a sub-tick with nothing to do return before its work, with a cheap guard on the state it reads. Every guard must be provably equivalent: same RNG draws, same order, same state. The target from Simulation's report is about 0.3 ms a tick. Measure before and after with `tick_prof.gd` on the same machine, in the same run.

**Acceptance criteria:**
- the golden is byte-identical, and the state hash is identical tick by tick on seeded matches: hand-made, gen 2, and with `--intro`;
- `npm test --prefix sim` (the JS parity oracle) passes;
- the rollback check passes;
- these all pass, each with its last line in the report:
  - all World checks;
  - the launchbiome and sigafter probes;
  - campaign_episode;
  - the standard gate set.

If a skip can't be made equivalent, leave that sub-tick alone and list it.

**Report** as `docs/director/cloud-reports/2026-10-28-tick-skip.md`: SUMMARY, CHANGES (non-Encounter lines marked), DECISIONS, NEEDS FROM EP, RISKS, NEXT, with the tick numbers before and after. Push and end your turn. Stay in the session while long runs finish.
