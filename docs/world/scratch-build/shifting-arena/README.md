# The shifting arena picture and the homes probe (World, 2026-10-19)

- `gen_shift.py <everhold_grid.json> <out.svg>` makes `homework/31b-shifting-arena.svg` (an animated SVG, SMIL, no script; a third argument freezes it at a time in the 40 s loop, for stills through `tools/machine/capture.mjs`).
- `everhold_grid.json`: planet 7's biome on a 2.5 degree grid and its places, from `planet_grid_dump.gd.txt` (copy it to `sim/world/tools/` of a scratch export and run it with `-- 7 out.json 2.5`).
- `homes_probe.gd.txt` and `homes_probe.out`: how often each of the four homes has a site by the strict rule (24 planets, 2,500 candidates): see `docs/world/homes-and-arenas.md` section 5. Scratch only; nothing in the tree.
