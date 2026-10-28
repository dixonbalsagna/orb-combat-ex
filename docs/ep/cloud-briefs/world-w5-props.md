# Cloud brief: World & Environment, biomes W5 (props on gen 2 planets)

**Who you are.** You are the World and Environment Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/world-environment.md`;
- **`docs/ep/cloud-workflow.md`**. It overrides your charter where they differ: commit and push only to `cloud/world-environment/*`, never to main, and report in the branch.

Godot: use `$GODOT` if set, else install the pinned Linux build as cloud-workflow.md says. Then read the W5 proposal under NEXT in your W4 report (`docs/world/cloud-reports/2026-10-28-biomes-w4.md`), and `docs/combat/biomes.md` §2.

**Branch:** `cloud/world-environment/biomes-w5` from origin/main (W3 and W4 are on main).

**W5, as you proposed it:**
1. **Bergs** on sea ice and in open water within the pack's band. Use the planet's own berg cells where they exist.
2. **Lone trees** on savanna and beach. Keep each row's `gap` from the sim's trees and from each other: a keyed draw per column, rejected inside the gap.
3. **`propsNear(S, x, reachBh)`** for Combat's PROP SMASH, with shortest-arc wrap math.
4. Use the provisional rows in ground.json. Art sets the final sizes later, and `provisionalProps` stays the switch.

**Acceptance criteria:**
- props are pure functions of the planet: the same twice, across a turn and across the seam;
- nothing in the sim reads them until the director's switch, and every new piece is off by default;
- gen 1 and the hand-made world are bit-identical, and the golden is byte-identical;
- a check stages each prop kind on a gen 2 world and shows it placed, with the gap rule held. Extend `props_check` or write a new one;
- these all pass, each one's last line in the report:
  - all World checks and gen2_soak;
  - determinism, plain and `--intro`;
  - the standard gate set in cloud-workflow.md.

**Not in scope:** drawing the props (Rendering's) and PROP SMASH itself (Combat's and Encounter's). Put the hand-off lines under NEEDS FROM EP.

**Report** as `docs/world/cloud-reports/2026-10-28-biomes-w5.md` with these sections: SUMMARY, CHANGES (mark the non-World files), DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push the branch and end your turn.
