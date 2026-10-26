# Window 11: the owners' sea-rule lines for lakes at altitude (parked)

World and Environment, 2026-10-23. `gen2-w11.diff` (sha1 01c34d4ad7e2, 7 files) is a git-apply diff. Applies after window 10 (order 2, 2b, 3, 4, 5, 6, 7, 8, 9, 10, 11).

The sea's rules measured depth from absolute zero (`y < 0`, `y < 30`, `SURFACE_Y`), so a lake at altitude did not follow them (Game Design 23b rows 13 and 15). `WorldWater.seaTop(S, x)` (World's) is the surface they measure from: 0 over the sea, a gen 2 lake deep enough to hide in: its own surface, and `NO_SEA` (-1e18) where there is neither. On any world without a lake it is `y < 0 and seaAt` as the rules were written (the arithmetic is the same: 0 + 30, 0 + SURFACE_Y), so gen 1 is bit for bit.

**The owners' lines (grants approved on Orb's word):**
- Simulation's `sim/core/fighter.gd`, 1 line: `flightSpeed`'s 0.55 damping in water (was `f.y < 0.0 and seaAt`).
- Encounter's `sim/director/launch.gd`, 3 lines: `predictFlight`'s water entry and its landing flag, and `doLaunch`'s `wet` flag.
- Encounter's `sim/director/beam.gd`, 1 line: the beam's splash (`y < seaTop + 30`).
- Encounter's `sim/director/ai.gd`, 7 lines: the surface height the AI holds at (`top + SURFACE_Y`, five uses) and the dash for the surface.

New: `sim/world/tools/sea_rules_check.gd` (5 checks): seaTop is exactly 0 over the sea and NO_SEA elsewhere on the hand-made world; a fighter below the sea's surface flies at 0.55; a deep lake at altitude has its own surface; a fighter below it flies at 0.55 and above it at full; a launch falling into it is predicted to end in water.

Not built: "a fighter landing in water surfaces set within 30 ticks" (Game Design item 7, Combat's biome step: no code exists for it yet, sea or lake).
