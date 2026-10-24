# Prompt record: ART-0024, the energy colour lanes

Rules: `docs/art/ai-prompt-policy.md`. Record for `art/concepts/energy/` (`lanes.mjs`, `search.mjs`, `trial.mjs`, `gen.mjs`) and the outputs `energy-lanes.svg`, `data/art/energy-lanes.json`, `docs/art/energy-lanes.md`, `docs/art/pending/art-energy-lanes.schema.json`.

- asset id: ART-0024
- date (UTC): 2026-10-24
- tool, model and version: Claude Code (desktop app), model claude-sonnet-5-5. The session is titled "Meridian - Art"
- settings and seed (if any): none. Deterministic scripts; no randomness
- purpose: each fighter's energy colour lane (core, main, edge) for bolts, lobs, beams, grabs and traps, checked against the fifteen biomes, the colour-vision presets and Legal's saturated-red rule
- input images: none. The inputs are Combat's energy kits (docs/combat/pending/energy/), the biome palettes (art/concepts/biomes/spec.mjs), the sky and world-light data (data/art/sky.json) and the colour-vision rule (docs/art/colour-vision.md)
- outputs kept: the sheet, the data, the doc and the schema draft
- outputs rejected: a first Empress lane in deep gold (13 from the Cyborg's orange, 1.4 under protan sight); light violet for the Rival (15.6 from the Protagonist's cyan under deutan sight); the Cyborg placeholder #ff6a1a (0.87 red share on linear values)
- what a human changed: the EP's brief (relaying Orb) set the families; a human picks from the sheet
- originality checklist: cyan, violet and orange energy are generic genre colours; ivory with a deep gold rim and slag with scrap-metal grey are our own; no franchise colour scheme or shape
- reverse-image search (date, by whom, result): not applicable (procedural, colours and flat shapes)
- Legal review (date, RL id): pending (the Empress lane is built to Legal's red count 0, lines-not-balls and the Cyborg wreckage-only rules)
- disclosure category: development aid until built; ships once built

## Prompt (verbatim, complete)
The EP's brief of 2026-10-24: a small pick for the energy overhaul: each fighter's energy colour lane for bolts, lobs, beams, grabs and traps. Protagonist cyan to azure; Rival violet to magenta; Demon Cyborg wreckage and metal (molten slag oranges). The Empress has a crimson placeholder, but Legal's flash rule counts saturated red flashes strictly (red 0), so give her a lane that reads regal and distinct from the other three without saturated red (deep gold, ivory, or a dark rose that fails the red test, your call). Check it against the readability rule on all 15 biomes and the colour-vision presets. Put it in data/art/ (with a schema note for Tools) and a one-sheet in art/concepts/energy/. Standard report.

## Negative prompt (verbatim, complete)
None (no image model was used).
