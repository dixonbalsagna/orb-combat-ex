# Cloud brief: World & Environment, biomes W4

**Who you are.** You are the World and Environment Director for Orb Combat EX, working as a cloud session. Read in this order: CLAUDE.md, your charter `docs/directors/world-environment.md`, and **`docs/ep/cloud-workflow.md`**. The cloud workflow overrides your charter where they differ: you commit and push, but only to `cloud/world-environment/*` branches, never to main, and you report in the branch because you can't message anyone. Then read `docs/combat/biomes.md` (§2 and §6) and `docs/world/after.md`.

**Base.** Make a branch `cloud/world-environment/biomes-w4` from origin/main. First, apply your W3 park as its own commit: `git -c core.autocrlf=false apply docs/world/pending/biomes-w3/biomes-w3.diff`, committed as "World: biomes W3 (trees on a path, the strips in lookAt and surfaceAt)". The EP is landing W3 on main separately with the same content, so a later rebase will be trivial. Then build W4 on top of it.

**W4, World's part (the EP has ruled on each point):**
1. **Crater shapes by material.** Add `data/biomes/craters.json` as World's own data, off by default. Copy Combat's numbers from biomes.md, cite them, and add a schema (see 5). contact.gd's slam dig reads it: radius, depth, rim, steep, refill, embedMul, fill and breakThrough. The embed threshold scales with the bowl's depth factor. Refill reuses the aftermath jobs.
2. **crater_shape.** No hash.gd grant. Make the shape data available; the director sends the event from `rec`.
3. **Breakable floes.** The sea-ice HIT, and a slam deeper than the floe, share the crater's breakThrough mechanism.
4. **Props.** Add the missing ground.json rows: bergs, and the lone-tree gaps for savanna and beach. Use your own sizes and mark them provisional for Art.
5. **Schema.** A new data file needs its schema in `tools/schemas/` and a map row in the same branch. You may write these Tools files under this brief; list them under CHANGES.
6. Ice's control point is already `data/biomes/skate.json` (off). Nothing to build there.

**Acceptance criteria:**
- every new piece is behind a switch, off by default;
- gen 1 and the hand-made world are bit-identical, and the golden byte-identical;
- a check stages each new piece on a gen 2 world and shows it applied;
- all World checks, gen2_soak, and the standard gate set in cloud-workflow.md pass, with each one's last line in your report.

**Report** as `docs/world/cloud-reports/2026-10-28-biomes-w4.md`: SUMMARY, CHANGES (every file, with the non-World ones marked), DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push the branch and end your turn.

**If you finish early with credit time left,** propose W5 under NEXT in your report: the props' placement on gen 2 planets, using the provisional rows. Don't build it unasked.
