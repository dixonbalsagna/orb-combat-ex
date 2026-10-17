# Planet window 2, a draft (World, 2026-10-17): in scratch, parked, not applied

The design, the evidence and the open decisions are in `docs/world/planet-window2.md`. Built on main af5151b5 **with the collateral window applied first** (the draft sets `Building.place` and `Building.plan`) and `WorldPlanet` (window 1).

| File | What |
| :--- | :--- |
| `window2-draft.diff` | The patch on HEAD plus the collateral window: `sim/world/planet_world.gd` (new, `WorldPlanetWorld.gen`), `sim/world/biomes.gd` (`planetCols`, read by `biomeAt`), `sim/core/sim.gd` (`newMatch`: the planet branch, the clearing of the table, the start astride the touch-down), `sim/world/tools/planet_world_check.gd` |
| `mk_window2.py`, `planet_world.gd`, `planet_world_check.gd` (+ `.uid`) | The script that makes it and the new files |

**Run:** in a scratch export of HEAD with the collateral window applied: `godot --headless --path . --script res://sim/world/tools/planet_world_check.gd -- 3600` (about 10 s; 0 failed). It also prints the golden keys.

**Lines in files that are not World's:** `sim/core/sim.gd` (two small hunks: Simulation's).

**The existing golden:** `node sim/core/tools/run-all.js --only=godot` on the draft tree passed (316 s): the 9 golden matches are identical, so nothing moves until a planet is a setup.
