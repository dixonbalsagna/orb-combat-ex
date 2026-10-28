# Cloud brief: Simulation & Engine, the director forwards, tick_prof's ring, and the first-tick hitch

**Who you are.** You are the Simulation and Engine Director for Orb Combat EX, working as a cloud session. Read these in order:
- CLAUDE.md;
- your charter `docs/directors/simulation-engine.md`;
- **`docs/ep/cloud-workflow.md`**: commit and push only to `cloud/simulation-engine/*`, never to main, and report in the branch.

Godot: `$GODOT` if set, else the pinned Linux build as cloud-workflow.md says. Then read:
- World's W6 report `docs/world/cloud-reports/2026-10-28-biomes-w6.md`, NEEDS 2;
- Encounter's tick-skip report `docs/director/cloud-reports/2026-10-28-tick-skip.md`, NEEDS 2 and 3.

**Branch:** `cloud/simulation-engine/forwards-warmup` from origin/main. Your local session is fixing packed-structures in parallel, so keep this diff small and away from the structure storage.

**Build:**
1. **Named forwards.** Move `WorldContact.hookOf`'s and `_smashProp`'s three director calls (`flightHook`, `brokenProps`, `propBroke`) into `sim/core/dir.gd` as named forwards, so that load_split checks them by name. You are granted the lines in `sim/world/contact.gd` that make those calls, and nothing else in sim/world.
2. **tick_prof's ring.** `tick_prof.gd --gen2` passes `"arena": 2400`, but newMatch wants `{"cols": 2400}`. As it is, the run errors and plays the full arena. Fix it the way `dir_prof.gd` does.
3. **The first-tick hitch.** The first `DirInterrupt.on()` of a process parses the director's data (about 180 ms) on a match's first live tick. Warm it in `SimCore.newMatch`, or say why the loading screen is the better place. The warm-up must not change any state that's hashed. Report the first live tick's time before and after, from tick_prof.

**Acceptance criteria:**
- the golden is byte-identical, and tick_hash is identical over 43,200 ticks;
- determinism passes, plain and with `--intro`;
- load_split checks the three forwards by name, and its negative control catches a missing one;
- rollback_check passes, plain and `--ai`;
- `tick_prof --gen2` runs on a 2,400-column ring (say how you know);
- all World checks and the standard gate set pass, with each one's last line in the report.

**Report** as `docs/architecture/cloud-reports/2026-10-28-forwards-warmup.md`: SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT. Push and end your turn. Stay in the session while long runs finish.
