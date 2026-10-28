# Park: the desert's tone-on-tone palette (Art, 2026-10-27)

**Shelved, not landed.** The palette route to the `signature` flash clip's fix did not pass the last combined check in either mode (the EP, 2026-10-27 night); what remains is a camera cut over open desert (Camera). This folder keeps the whole pass so it can be re-applied. The working tree was restored to HEAD after it was saved.

## The three passes (all in `desert-tone-on-tone.patch`)

Full figures, luminances and gaps: `ground-ladders.md` inside the patch (it becomes `docs/art/ground-ladders.md`).

1. **Ladders and scar.** Desert, beach, savanna and plains grounds cut so the three faces stay within `PATTERN_BUDGET` (0.085) of each other as drawn (the stored colour times the depth step), told apart by hue; the glass scar on sand (desert, beach) lifted from near-black to a pale sea-glass at about the sand's value. Cleared the split's opening and the scar second (reduced 2.5 / 2.5 / 2.5).
2. **Rock and crater.** The desert rock (and so its mesa and boulder cover) re-cut to the sand's value as a terracotta; the crater's inside given its own three faces (`palette.subsoil_faces`, desert and beach only) instead of one subsoil colour with a derived lite and dark. Needs the schema line (`art-biomes-subsoil-faces.schema.json`, Tools) and the render patch (`biome-look-subsoil-faces.patch`, Rendering's `render/core/biome_look.gd`); the far mesas keep their old colour (`derive.mjs` `FAR_BASE`).
3. **Adjustment.** The crater's faces stored at the luminance of the ground's own faces of the same tone (so, with the depth step applied to both, they draw as the sand does at every step), and the desert rock warmed toward sand-terracotta at the same value (#feb970, #feb179, #fda982).

## Files

- `desert-tone-on-tone.patch`: against HEAD c5e94322. Changes `art/concepts/biomes/{spec,derive,gen}.mjs`, `data/art/biomes.json`, `docs/art/{README,biomes,biomes-pages}.md`; adds `art/concepts/biomes/ground.mjs` and `docs/art/ground-ladders.md`. It does not carry the regenerated sheets (35 MB as a patch: the SVGs are one line each); `node art/concepts/biomes/gen.mjs` rebuilds them, `data/art/biomes.json` and `docs/art/biomes-pages.md` from the patched sources. Checked in a scratch copy of HEAD: apply, regenerate, and `data/art/biomes.json` (sha1 956c3b06...) and `docs/art/biomes-pages.md` (d59a5d3d...) and all 22 sheets come out byte-identical to the working tree this was saved from.
- `art-biomes-subsoil-faces.schema.json`: the optional `palette.subsoil_faces` line for `tools/schemas/art-biomes.schema.json`.
- `biome-look-subsoil-faces.patch`: Rendering's 8 lines.

## To re-apply

From a scratch export of main (never the repo root for a check): `git apply desert-tone-on-tone.patch`, then `node art/concepts/biomes/gen.mjs`, then `node tools/validate.js` (two unknown-property errors for `subsoil_faces` until the schema line is in). Rendering's other pieces from the same run (strata factor, the crater taking the depth step, `DEPTH_STEP` 1.07 / 0.97 or 1.04 / 0.98) are in `docs/rendering/pending/2026-10-27k/`.

## What was learned (for the next try)

- On the front depth step the desert faces draw as the stored colour times 1.10; the flip rule counts 0.1 of relative luminance where the darker side is under 0.8; so every surface that meets another on screen needs to stay within about 0.1 of it at every depth step, including the crater's inside (it was drawn after the depth step, flat) and rock (strata lines at 0.62 of the face step about 0.35).
- A tone-on-tone ground leans entirely on hue; the mesas, boulders and crater lose most of their face shading, and the beam on sand reads by sea-green, not darkness. Both were for Orb's eye before landing.
