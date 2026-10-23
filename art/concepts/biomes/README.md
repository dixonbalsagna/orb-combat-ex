# biomes

Concept art for the biome look bible (`docs/art/biomes.md`), written 2026-10-23 for Rendering, VFX and World on Orb's word ("pour resources into improving our planet generation, biomes, fighter animations"). **Biomes only, no character art: these may be shown to Orb and anyone else.** Flat faceted colours with a keyline; no gradients, no blur, no fades.

Regenerate from the repo root: `node art/concepts/biomes/gen.mjs` (deterministic, no packages). It writes the 13 biome sheets, `biomes-sheet.svg`, `orbit.svg`, `data/art/biomes.json` and `docs/art/biomes-pages.md`. One part: `node art/concepts/biomes/gen.mjs desert` (a biome id), `sheet`, `keys`, `cover`, `orbit` or `data`. The 1:1 PNG of the cover sheet is a capture of `cover-sheet.svg` through `tools/machine/capture.mjs`.

| File | What |
|---|---|
| `biome-<id>.svg` | One biome: the strip at fight distance, the palette, scorched, cratered and burned, three destruction frames, the transitions into each neighbour. ids: ocean, beach, plains, savanna, forest, jungle, wetland, desert, mountains, volcanic, tundra, ice, seaice |
| `biomes-sheet.svg` | All thirteen side by side at one scale, with a 75-unit grey figure for scale |
| `biomes-golden.svg`, `biomes-sunset.svg`, `biomes-dawn.svg`, `biomes-night.svg` | The same thirteen under each light key: the key's sky and the world-light tints on ground, trees and water (the keyline and the fighters are never dimmed) |
| `cover-sheet.svg`, `cover-sheet.png` | The 33 cover silhouettes, clean and charred, at true pixel size (1 unit = 1.147 px, a fighter 86 px) with triangle counts; `docs/art/biomes-cover.md` has the table |
| `orbit.svg` | The planet from orbit: three views, a flat map, the colour pairs (ground and orbit) |
| `spec.mjs` | The data: palettes, profiles, cover, damage and destruction notes, the neighbour pairs. **Edit this and regenerate** |
| `draw.mjs` | The renderer: ground profiles, the cover silhouettes, the far-land ladder, the damage states, the stepped transitions |
| `plume.mjs` | The destruction frames (burst, peak, settle) |
| `orbit.mjs`, `derive.mjs` | The orbit study and the derived colours (the far ladder, the orbit colours) |
| `measure.mjs`, `fix.mjs` | The readability measure (aura 20, body 15 CIEDE2000, every sky key) and a helper that nudges a failing tone the least |
| `cv.mjs`, `cvhue.mjs` | The colour-vision pass (protan, deutan, tritan against the preset lane auras, 14 or more) with `--fix` and `--apply`; `cvhue.mjs` also searches hue shifts |
| `covers.mjs`, `coverdoc.mjs` | The cover sheet and its triangle counts |
| `gen.mjs` | The sheets, the data and the generated page |
| `test*.mjs` | Scratch checks (a strip, the plumes, the orbit's biome shares); not part of the output |

Prompt record: `art/prompts/ART-0023-biomes.md`. Origin (proposed rows for `docs/legal/asset-origins.md`): the generators are procedural, AI-assisted (Claude Art Director session with direction from Orb via the EP, Claude Code claude-sonnet-5-5, 2026-10-23); each SVG is a procedural output. Licence: Orb decides. Status: proposed.
