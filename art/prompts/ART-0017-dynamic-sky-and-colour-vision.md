# Prompt record: ART-0017, the dynamic sky and the colour-blind presets

Rules: `docs/art/ai-prompt-policy.md`. Record for `art/concepts/sky/` (`colour.mjs`, `keys.mjs`, `draw.mjs`, `gen.mjs` and the four sheets), `art/concepts/colour-vision/` (`cues.mjs`, `search.mjs`, `check.mjs`, `gen.mjs` and the sheet), and the data files `data/art/sky.json` and `data/art/colour-vision.json`.

- asset id: ART-0017
- date (UTC): 2026-10-06
- tool, model and version: Claude Code (desktop app), model claude-sonnet-5-5. The session is titled "Meridian - Art"
- settings and seed (if any): none. Deterministic (fixed grids, no randomness)
- purpose: direct the game's dynamic sky (keys, blends, drift, mood and damage, the rate limit) and the colour-blind presets for the two fighters' lane colours
- input images: none. No reference image of any kind was used. The only inputs are the game's own colours (`render/core/look.gd` SKY, `ui/core/ui_look.gd`, `data/fighters/*/fighter.json`) and published colour-science formulas (OKLab, CIEDE2000, the Machado et al. 2009 vision matrices)
- outputs kept: the sheets and data files above
- outputs rejected: an earlier sky that blended sunset to night through an olive green (replaced by a straight blend); a ruin that greyed noon toward the rival's violet (replaced by a brown smoke); frenzy and glow tints that turned the noon lower band slate-blue (replaced by a deepening and a horizon-only glow)
- what a human changed: Orb's decisions (a dynamic sky driven by place, mood and damage and time; colour-blind options, no stylistic palette change) and the EP's brief direct the work
- originality checklist: the keys extend the game's own sunset; no franchise colours or looks; no masks
- reverse-image search: not applicable (colours and gradients from the game's own look)
- Legal review: pending (the horizon ember glow, ruin's slow darkening, the preset hues)
- disclosure category: development aid until Rendering builds it

## Prompt (the brief, as relayed by the EP on 2026-10-06)

> Orb: colour-blind options yes, stylistic palette changes no; the sky should be dynamic and colour-changing, driven by where you are on the planet, the fight's mood and damage, and time passing (not the match's acts). 1. Direct the dynamic sky inside the existing look (the sunset bands are the reference): keys for noon, golden hour, dusk, night and dawn with hex values and how they blend round the planet; a slow drift over a match; what the sky does as the fight turns frenzied and the world is wrecked, and what it must never do (nothing fast: the flash limit; the fastest allowed rate; contrast with the fighters' lane colours at every key); the keys as data, the blend rules and stills of the two fighters over each key. 2. Colour-blind presets (protan, deutan, tritan) remapping the two fighters' lane colours and auras so they stay distinct from each other, from every sky key and from the wound and guard marks; swatches and a simulated-vision check for each preset; a rule for future fighters; no change to the default look.

## Negative prompt

None. No franchise names, no franchise images, no masks.
