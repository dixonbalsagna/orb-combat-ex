# Parked: biome effects, window 1 (impacts and landings in Art's plume language)

Orb (2026-10-23): every biome answers a fight in its own material. This window is part 1 (impact and landing debris by biome); ambient life and biome scars are the next windows. Design, numbers and limits: `docs/vfx/biome-fx.md` (in the patch). Pictures (private): `homework/biome-fx/`.

Status: **biome-fx, grant-flash-clips, biome-ambient, biome-scars and biome-fire are on main (f20018e4, 4eaaaca7); their patches are deleted. Only `grant-beam-clips.patch` remains, held for Tools' bisect of the failing `signature` clip.** The design is in `docs/vfx/biome-fx.md`.

## What it does
An impact on the ground is drawn in all of Art's fifteen biomes as Art's plume: a billowing column of overlapping faceted puffs (lit at the top, shaded at the foot), one flat pale burst star on the first frame, ejecta on arcs by the plume's kind, a skirt of low puffs, landed debris that stays a few seconds, and Art's flags (the sea ice's ring, the beach's wet ring, the jungle's steam, the volcanic ground's steady ember chips). Colours, heights and widths are read from Art's `data/art/biomes.json` by the fine biome's name; the villages and the city have no plume (nothing added) and the open ocean's is the water effects'. Scaled by the causer's power tier (0.7, 1, 1.45, 2), the event's speed, quality and reduced motion.

## The three beam clips (grant-beam-clips.patch, 2026-10-27)
`grant-beam-clips.patch` (sha1 a25013c8b05585c3609799fe9a44676634189489; applies after `grant-flash-clips.patch` on HEAD, touches the same three of Rendering's and Tools' files: `render/tools/flash_capture.gd`, `tools/flash/flash_worst.gd`, `tools/flash/sources.json`) adds three fixed clips for Tools' list, one per ground: **`beamdesert`, `beamice`, `beamvolc`**. Each is the `signature` scene (player one fires the signature on a cycle at the AI, 1,500 ticks, seed 12345, the default pairing) with the pair set down on the plains between the harbour village and the city (x 33,000) and the biome forced for the run (`VfxBiome.override_biome`, as the plume clips do: the default world has no ice or lava), so the beam's ground scorch throws sand glints and glass chips, melt steam and slate chips, or pale flakes and orange chips, and a plume rises where it lands. `minEvents` `beam_outcome` 1; native run: beam_outcome 2, 0 red, worst 6 in 60 ticks (normal) and 3 (reduced), register counts the same in the three (the sim is the same, only the VFX differ).

**Pixel result, `tools/flash/run-pixels.mjs` from the patched tree, both modes, 1024 x 768, one clip at a time:**

| Clip | Mode | Primary | General | Red | Area-15% | 2 s memory | Verdict |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| beamdesert | normal | 3 | 0 | 0 | 3 | 4 | NOT PASS (the 120-frame memory reads 4) |
| beamdesert | reduced | 4.5 | 0 | 0 | 4.5 | 4 | NOT PASS |
| beamice | normal | 4 | 0 | 0 | 4 | 4 | NOT PASS |
| beamice | reduced | 4.5 | 0 | 0 | 4.5 | 4 | NOT PASS |
| beamvolc | normal | 4 | 0 | 0 | 4 | 3 | NOT PASS |
| beamvolc | reduced | 4.5 | 0 | 0 | 4.5 | 4 | NOT PASS |

**They are not this window's.** The same scene with the biome effects switched off (`BIOMEFX_DEFAULT` false) reads 4 (normal) and 4.5 (reduced) over 3: the effects make it no worse (desert normal reads 3 with them, 4 without). And the **existing `signature` clip fails on its own on unmodified HEAD 3d0c0860**, no park applied: normal 3.5 primary and 5 at area-15% (NOT PASS), reduced 2.5 (PASS); the 2026-10 rehearsal (docs/tools/rehearsal-f15d7de3.md) had it at 2 / 2 / 2. So something between that commit and HEAD, or the machine's rendering, moves the signature beam over the line; the signature's own white (the charge outline and the beam) is what the analyser counts in these frames (a desert variant of the scene, on pale sand, reads 5). For the EP to route to Legal, Rendering and Tools; the clips are here, defined and proven to run, and read the same as the signature clip once that is settled.

## Re-cut for Legal's fx07, and proved on HEAD 6daac9c0 (2026-10-26)
- **The luminance rule floors at full weight:** a puff whose relative luminance (linear, the standard's) steps 10% or more from the ground's counts at weight 1.0 in the pool's area budget; under 10% it counts 0.3 to 1 (`VfxBiome.puff_weight`, per puff colour). Tests: a white and a black puff on green are 1.0; a puff of the ground's own colour is 0.3; in all fifteen biomes every plume colour with a 10% step has weight 1.0.
- **The star** never repeats within a second (test: a second crater within a second has no star); refused under Reduce flashing; its counted area is the disc as drawn at the framing in use. Embers are a steady chunk in Art's orange.
- **World's fine ids** come from `S.fineCols` (gen 2) when non-empty, else the stored biome's name.
- **Proof on HEAD 6daac9c0** (this patch + the grant, scratch export, headless): `effects_check` passes (the floor, the star spacing and `fineCols` included); `validate` 267/0/0; the flash self-test (drift check) passes; render gates after, city (reports), cue, depth, flash, flash_reg, flight, ground, hud_words, lane, open, pane, patch, shape, sky, stage all pass; **not run: `cull_check` and `outline_check`, which need a window.**
- **The flash register in the real matches** (`hash_check`), unmodified HEAD against this patch: granted 384 on both, never more than 3 in any second, weight 1.00; refused 9,028 against 9,232: the 204 extra are burst stars asked for under the reduced register and refused (`biome_star` is a low-priority source).
- **The three fixed plume clips** (`plumedesert`, `plumeice`, `plumevolc`: 1,500 ticks, a crater every 150 ticks at the game's close framing, tier 3, the biome forced), through `tools/flash/run-pixels.mjs` one clip at a time, both modes, at 1024 x 768, one browser, below-normal priority, the register counts agreeing with the headless run:

| Clip | Mode | Primary | General | Red | Area-15% | 2 s memory | Margin | Dips | Verdict |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| plumedesert | normal | 2 | 0 | 0 | 2 | 2 | 0/4 | 0 | PASS |
| plumedesert | reduced | 2 | 0 | 0 | 2 | 2 | 0/4 | 0 | PASS |
| plumeice | normal | 2 | 0 | 0 | 2 | 2 | 0/4 | 0 | PASS |
| plumeice | reduced | 2 | 0 | 0 | 2 | 2 | 0/4 | 0 | PASS |
| plumevolc | normal | 2 | 0 | 0 | 2 | 2 | 0/4 | 0 | PASS |
| plumevolc | reduced | 2 | 0 | 0 | 3 | 2 | 0/4 | 0 | PASS (the sensitivity run is at 3, not over it) |

  Stills from them: `homework/watch-no-answer-needed/effects/biome-fx/8-the-plume-clips-stills.png`. The embers read red 0 in the volcanic clips. Not run: a clip at the middle or far framing, and a plume clip in a beam or a clash.

## Checks on the previous cut (scratch HEAD 2c1b7c3c + the patch, headless)
- `effects_check` passes (26 new lines: Art's fifteen all drawable; specs; villages and city nothing; a crater's one column and one star; Art's colours in the puffs; one column for a slam and its crater; tier and speed scaling; reduced motion; each family's ejecta; sea ice ring, beach ring, steam, steady embers; determinism; debris stays then goes; the pool's cap under a flood). `validate` 254/0/0.
- Render gates: after, city (reports), cue, depth, flash, flash_reg, flight, ground, hud_words, lane, open, pane, patch, shape, sky, stage all pass. **Not run: `cull_check` and `outline_check`, which need a window.**
- **The flash register in the real matches** (`hash_check`): granted 384, never more than 3 in any second, weight 1.00 (2.5 at most): identical with the effects on and off. Refused rises from 9,028 to 9,232: 204 burst stars asked for under the reduced register and refused (`biome_star` is a low-priority source, so the star is only drawn in normal mode when the register has room).
- Collapse clip in both modes (tools/flash/run-pixels.mjs, the staged city collapse, 1,500 ticks each): see "Flash clips" below.

## Flash clips
The staged city collapse, 1,500 ticks, at 1024 x 768 (`tools/flash/run-pixels.mjs --only collapse`, one browser at a time, below-normal priority), the patch's build against an unmodified build of the same commit 2c1b7c3c:

| Clip | With the patch | Unmodified commit |
| :--- | :--- | :--- |
| collapse-normal | primary 3, area-15% 3.5, 2 s memory 2, 0 dips: not PASS | primary 3, area-15% 3.5, 2 s memory 2, 0 dips: **the same numbers, not PASS** |
| collapse-reduced | primary 3, area-15% 3.5, 2 s memory 3, 0 dips: not PASS | **not run** (stopped for the EP's quiet window); to repeat after it |

So the collapse clip's "area-15% 3.5 over 3" is **not the patch's**: the collapse is staged in the city, where the biome effects add nothing, and the normal-mode reading is identical to the commit's own. Whether the commit's collapse should read 3.5 on the sensitivity run is Tools' and Legal's question (it is not new). I have not run a clip that stages a plume (a crater in the desert, the ice or the volcanic ground): the register's own count above is the check I have for those, and Legal's glance is asked for.

## For the EP
- **World's fine ids:** read from `S.fineCols` (gen 2, World's window 7) when non-empty, else the stored biome's name; until a match is gen 2 it shows only the plumes of the seven stored names (desert, forest, mountains, plains, ocean, villages, city).
- **NEEDS THE EP'S GRANT:** `grant-beam-clips.patch` (Rendering's `render/tools/flash_capture.gd`; Tools' `tools/flash/flash_worst.gd` and `sources.json`), held until the `signature` bisect.
- **Window 2 (ambient life) is a separate park on top of this one:** `docs/vfx/pending/biome-ambient/` (authored, never run).
- **Legal** passed the plumes with conditions (RL-176, fx07): all of them are above.
- Files outside VFX's folders: `tools/schemas/map.json` (one rule line, as every VFX data file adds), nothing else.

## Honest limits
The column is held to about five to eight puffs at a close framing by that budget, and reads fully at the middle and far framings. Sizes of the ejecta were tuned by eye. The plume's lower puffs sit behind the ejecta cluster in the camera's usual framing, so the column reads mostly by its upper puffs. Not a Legal clearance.
