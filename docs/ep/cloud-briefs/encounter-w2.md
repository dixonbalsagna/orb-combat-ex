# Cloud brief: Encounter Systems, biomes W2 (twists and aftermaths)

**Who you are.** You are the Encounter Systems Director for Orb Combat EX, working as a cloud session. Read in this order: CLAUDE.md, your charter `docs/directors/encounter-systems.md`, and **`docs/ep/cloud-workflow.md`**. The cloud workflow overrides your charter where they differ: you commit and push, but only to `cloud/encounter-systems/*` branches, never to main, and you report in the branch because you can't message anyone. Then read `docs/combat/biomes.md` (§2 and §6, rule 3 step 2), `docs/world/after.md`, `docs/vfx/after-fx.md`, and your W1 park's README, `docs/director/pending/biomes-w1/README.md`.

**Base.** Make a branch `cloud/encounter-systems/biomes-w2` from origin/main. **W1 (81462cf0), World's W3 (4be8f1d5) and World's W4 (bb5cdb43) are all on main already**, so there is nothing to apply first. If you started earlier and applied the W1 park yourself, rebase onto origin/main; the content is identical. World's W4 adds `WorldCraters.eventFor` for crater_shape: send it on a crater event whose `surface` is set. That was W4's NEEDS item 2, and it's now yours.

**W2, rule 3 step 2:**
1. **The six outcome twists.** Four HITs under the water rule (ocean, sea ice, wetland, beach) and two GUARD push-backs (ice sheet, tundra), as biomes.md specifies.
2. **Calling the aftermaths.** When the beam ends, call `WorldAfter.lay(S, a, x0, x1, fineId, z, defX)` with the row's `aftermath`, behind `aftermathOn`.
3. **The personality term,** behind `byPersonality`.
4. **Trees.** Pass the row's `trees` through `damageArea(..., treeMode)` (World's W3).
5. **An `aftermath` onset event** (kind, x0, x1) at lay time. VFX asked for it, for glints, dust and leaves.
6. **Defaults.** The landed sigvariants.json has `aftermathOn: true` and `byPersonality.enabled: true`. Decide each deliberately. Set both off until QA tunes them, unless you can show that on is safe. Either way, the switch stays the gate.
7. **Tools files.** A data change that changes a file's shape needs its schema in the same branch. You may write those Tools schema lines under this brief; list them under CHANGES.

**Acceptance criteria:**
- gen 1 and the hand-made world are bit-identical, and the golden byte-identical;
- a gen 2 probe shows each twist and each aftermath kind triggered by a real beam;
- `sigvariants_check` and the standard gate set in cloud-workflow.md pass;
- determinism plain and with `--intro` passes with the switches off and on.

**Report** as `docs/director/cloud-reports/2026-10-28-biomes-w2.md`: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push the branch and end your turn.

**If time is left, W3** (the eight launch candidates in chooseLaunch, with the surface terms) is the next brief. Propose it under NEXT; don't build it unasked.
