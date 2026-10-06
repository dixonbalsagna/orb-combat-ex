# Prompt record: ART-0018, the world's light, the town glow, and the lane marks and biome patterns

Rules: `docs/art/ai-prompt-policy.md`. Record for `art/concepts/sky/world.mjs`, `gen-world.mjs` and the sheets `world-light.svg`, `world-light-numbers.svg`, `sky-glow.svg`; for `art/concepts/colour-vision/marks.mjs`, `gen-marks.mjs` and the sheets `fighter-marks.svg`, `biome-patterns.svg`; and for the data written into `data/art/sky.json` (`_world_light`, `_town_glow`, `_burning`, `mood._amounts`) and `data/art/colour-vision.json` (`_non_colour_marks`, `_biome_patterns`, `_ui_wound_sets`, `_guard_cue`, the revised presets).

- asset id: ART-0018
- date (UTC): 2026-10-07
- tool, model and version: Claude Code (desktop app), model claude-sonnet-5-5. The session is titled "Meridian - Art"
- settings and seed (if any): none. Deterministic
- purpose: make the world's light follow the sky's key, direct the town glow and what burning means, put the mood's amounts in the data, and answer UI: the guard cue, UI's wound sets, a non-colour mark per fighter and a pattern per biome
- input images: none. The inputs are the game's own colours (render/core/look.gd, ui/core/ui_look.gd, ui/data/colour_vision.json, data/fighters), Rendering's still, and published colour-science formulas
- outputs kept: the sheets and data above
- outputs rejected: a night ground that came out neutral grey (cooled with a blue lift); a glow gradient centred under the horizon that hid the glow (recentred); the first glow amounts at noon, which turned the lower band slate near the rival's violet (scaled by the key's glow_reach)
- what a human changed: Orb's decisions and the EP's brief direct the work
- originality checklist: the tints and glyphs are our own; no franchise looks; no masks
- reverse-image search: not applicable
- Legal review: pending (the burning glow, the firelight, the preset hues)
- disclosure category: development aid until Rendering and UI build it

## Prompt (the brief, as relayed by the EP on 2026-10-07)

> At the night key a daylit ground and daylit buildings stand under a black sky, because only the sky's bands change. Direct the fix: the world's light per key (a tint and a level for the ground, buildings, water and fighters' bodies at each of the five keys and the mood extremes), inside the existing look, a multiply tint per layer, the fighters readable at every key, the auras and lane colours never dimmed, lit windows at night if cheap; the same hard limit (give the rate); the mood's amounts as data; the town glow (larger, higher or left as a far-off cue; what burning should mean); from UI: confirm the guard cue, confirm UI's wound sets, a non-colour mark per fighter body, a pattern per biome on the planet strip.

## Negative prompt

None. No franchise names, no franchise images, no masks.
