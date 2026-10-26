# Water v2 (parked, behind a switch)

World and Environment, 2026-10-23. `gen2-w10.diff` (sha1 90294075535c, 12 files) is a git-apply diff. Applies after window 9 (order 2, 2b, 3, 4, 5, 6, 7, 8, 9, 10). Design and numbers: `../../water-v2.md` (a one-page summary for Orb at the top).

**Off by default** (`data/biomes/water.json` `enabled: false`): with it off the water module is exactly as it was (every new path is behind `WorldFill.on()`), so gen 1 and the golden are unchanged.

- New: `sim/world/fill.gd` (WorldFill: fill windows for holes where water would come from, the cue events, the crater wave, the douse, wading), `data/biomes/water.json`, `sim/world/tools/fill_check.gd` (16 checks), `tools/schemas/biomes-water.schema.json` (Tools', granted).
- Edited: `sim/world/water.gd` (`touched` opens a fill; `step` runs fill and wave windows; the flow windows' merge skips them), `sim/world/crater.gd` (a slam throws the wave), `sim/world/contact.gd` (shallow water is waded; the data hash carries the switch when on), Tools': `map.json`, `cases.json`.
- **Simulation's one line:** `sim/core/hash.gd` FX_FIELDS: the three events' field lists (`water_fill`, `water_wave`, `water_douse`).
- The cue shapes are in the doc, section 2.
