# The surfacing rule (parked, window 15; behind `data/biomes/water.json` `surface.enabled`, off)

World and Environment, 2026-10-26. `surfacing.diff` (8 files, sha1 4a3035295526) is a git-apply diff on main with the window 13, wreck-toss, campaign-route and rivers diffs applied, in that order. Design: `../../surfacing.md`. **Off by default:** a dry state hashes as before, the golden is unchanged.

- Game Design 2026-10-23b item 7 (and rows 13 to 15): a fighter landing in water surfaces set within 30 ticks, no down state beyond, landed once he surfaces. A launched body under water (not waded) rises so as to arrive on the last of `surface.ticks` ticks and his flight ends there, set on the surface.
- World's: `sim/world/contact.gd` (`moveAir`; `Body.wetT`; the data hash carries the switch when on), `sim/world/fill.gd` (`surfaceOn`, `surfaceTicks`, `setSurface`), `data/biomes/water.json` (`surface`), Tools' `biomes-water.schema.json` (granted), `sim/world/tools/surface_check.gd` (9 checks).
- **Simulation's lines (grant approved on Orb's word):** `sim/core/state.gd` `Fighter.wetT` (1 line), `sim/core/hash.gd` (2 lines: hashed only while not 0).
- Proof (scratch export of the stack): all 44 World tools, lint, the self-test (9115/9115), run-all 5 of 5 with the golden unchanged, the gen 2 soak, and the render gates (cull and outline rc=2, "needs a window", the same on main).
