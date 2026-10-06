# Colour vision

Concept art and data, working labels, pending Legal review. Direction: `docs/art/colour-vision.md`. Regenerate from the repo root: `node art/concepts/colour-vision/gen.mjs` (deterministic, no packages); it also writes `data/art/colour-vision.json`.

| File | What it is |
|---|---|
| `colour-vision-presets.svg` | The two fighters' lane colours (auras) for the protan, deutan and tritan presets, default against preset, with swatches as designed and as seen, the numbers, and the fighters over three skies through the simulated vision; and the rule for future fighters |
| `check.mjs` | `node art/concepts/colour-vision/check.mjs "#hex" "#hex" ...`: each colour as seen under each vision and the CIEDE2000 distance between every pair, against the rule (25 or more by default, 20 or more under each simulation) |
| `search.mjs`, `cues.mjs` | The search that picks a preset (a fixed grid, no randomness) and the cue set (the wound and guard marks) and the sky samples it checks against |

The simulation is Machado, Oliveira and Fernandes (2009), severity 1.0, in linear RGB (`../sky/colour.mjs`). Prompt record: `art/prompts/ART-0017-dynamic-sky-and-colour-vision.md`.
