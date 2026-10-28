# Cloud brief: Encounter Systems, biomes W3 (the launch candidates)

**Who you are.** You are the Encounter Systems Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/encounter-systems.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/encounter-systems/*`, never to main, and report in the branch.

Godot: `$GODOT` if set, else the pinned Linux build as cloud-workflow.md says. Then read:
- `docs/combat/biomes.md` §3;
- the launch biome data (`launch.biome.json`; find it under `data/` or `docs/combat/pending/biomes/`);
- your W2 report `docs/director/cloud-reports/2026-10-28-biomes-w2.md`;
- `sim/director/launch.gd` (`chooseLaunch`).

**Branch:** `cloud/encounter-systems/biomes-w3` from origin/main. W2 landed as 035b730b.

**W3, your proposal:**
1. Add the eight launch candidates in `chooseLaunch`, with the surface terms, behind the `biome` block's `enabled` (off by default).
2. If the data still sits in a pending folder, move it to `data/` as Combat's file. Its schema goes in `tools/schemas/` with a map row, in the same branch; you may write those Tools lines under this brief. List them under CHANGES.
3. The candidates' scores print in the debug feed with the existing top-three line.

**Acceptance criteria:**
- with the switch off, gen 1 and the hand-made world are bit-identical, and the golden is byte-identical;
- a gen 2 probe shows each of the eight candidates chosen at least once by real launches;
- in a gen 2 batch with the switch on, no candidate takes more than 40% of launches (QA's variety bound). Report the shares;
- these all pass, each with its last line in the report:
  - determinism, plain and `--intro`, with the switch off and on;
  - sigvariants_check and the sigafter probe;
  - all World checks and gen2_soak;
  - the standard gate set in cloud-workflow.md.

**Report** as `docs/director/cloud-reports/2026-10-28-biomes-w3.md` with these sections: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push the branch and end your turn. Stay in the session while long runs finish.
