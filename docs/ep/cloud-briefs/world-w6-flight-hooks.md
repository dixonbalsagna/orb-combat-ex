# Cloud brief: World & Environment, W6 (the launch candidates' flight hooks, and a prop query the sim owns)

**Who you are.** You are the World and Environment Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/world-environment.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/world-environment/*`, never main; report in the branch.

Godot: `$GODOT` if set, else the pinned Linux build as cloud-workflow.md says. Then read:
- `docs/combat/biomes.md` §3;
- Encounter's W3 report `docs/director/cloud-reports/2026-10-28-biomes-w3.md`, NEEDS 2 and 3;
- `sim/director/launch.gd`: the plan fields that `_landTerms` and `_biomeCands` set, and `_propSeed`;
- your W5 report `docs/world/cloud-reports/2026-10-28-biomes-w5.md`.

**Branch:** `cloud/world-environment/biomes-w6` from origin/main. W5 is on main as 70c1ab3e, and Encounter W3 as d0d91c29.

**Build:**
1. **The flight hooks.** While a launched fighter flies, read the plan's fields, so that each candidate plays as biomes.md §3 says:
   - MARSH SWALLOW always embeds, ×1.8 deep;
   - each trunk on TREE LINE's path snaps and brakes him 12%;
   - PROP SMASH: the prop breaks and he stops at it;
   - a `soft` landing multiplies impact damage;
   - ICE SKID slides on your ice brake (`skate.json`), with control back at the rock stop.
   All of this runs only when the plan carries the fields, and they are set only with Combat's `biome.enabled`, which stays off.
2. **A prop query the sim owns.** Give the director (and later the renderer) one function for the props in a match, keyed by the director's seed (`_propSeed`: an FNV hash of the fine biome map) or by a seed you define that the director then uses. That way the props the sim reads and the props drawn later are the same ones. If the director's call must change, write the director's lines under this brief's grant (`sim/director/launch.gd` only) and list them under CHANGES as Encounter's.

**Acceptance criteria:**
- with the switch off, gen 1, the hand-made world and the golden are bit-identical;
- a gen 2 probe with the switch on shows each hook played by a real launch:
  - the embed depth;
  - the trunks snapped and the speed lost;
  - the prop broken and the stop;
  - the soft multiplier;
  - the skid ending at a rock stop;
- these all pass, each with its last line in the report:
  - determinism, plain and `--intro`, with the switch off and on;
  - `launchbiome_probe`, `sigafter_probe` and `ground_props_check`;
  - all World checks and gen2_soak;
  - the standard gate set.

**Report** as `docs/world/cloud-reports/2026-10-28-biomes-w6.md`: SUMMARY, CHANGES (non-World lines marked), DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push and end your turn. Stay in the session while long runs finish.
