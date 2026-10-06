# Sky

Concept art and data, working labels, pending Legal review. Direction: `docs/art/dynamic-sky.md`. Regenerate from the repo root: `node art/concepts/sky/gen.mjs` (deterministic, no packages); it also writes `data/art/sky.json`.

| Sheet | What it shows |
|---|---|
| `sky-keys.svg` | The five keys (noon, golden, sunset = the current look, night, dawn) with hex values, the blend round the planet (one cycle a lap), the slow drift (minute 0 to 40), the rate limit and its measured numbers |
| `sky-mood.svg` | Each key calm, frenzied, wrecked, both, and over a burning town; the rates and what the sky must never do |
| `sky-stills.svg` | The two fighters over each key and the mood extremes, for Rendering |
| `sky-contrast.svg` | CIEDE2000 and WCAG contrast of both aura colours against every band of every key, and the worst cases |

| `world-light.svg` | The world lit by each key (as built against directed, calm and frenzied-and-wrecked), with lit windows at night |
| `world-light-numbers.svg` | The tints per layer and key, the mood on the world, the readability checks, the rate with the world in it, and what Rendering needs |
| `sky-glow.svg` | The town glow larger and higher (open horizon and from inside a town) and what "burning" should mean |

Files: `world.mjs` (the world's light and the slew with it), `gen-world.mjs` (the three world sheets), `keys.mjs` (the keys, the blend, the mood, `slewStep`: the single source), `colour.mjs` (colour maths: OKLab, CIEDE2000, the Machado vision matrices), `draw.mjs` (the sheets' drawing helpers), `gen.mjs`.

Origin (proposed rows for `docs/legal/asset-origins.md`): ART-0017-GEN is `art/concepts/sky/*.mjs` and `art/concepts/colour-vision/*.mjs` (procedural generators, AI-assisted, Claude Art Director session with human direction from Orb via the EP, Claude Code claude-sonnet-5-5, 2026-10-06); each SVG and data file is a procedural output. Licence: Orb decides. Status: proposed.
