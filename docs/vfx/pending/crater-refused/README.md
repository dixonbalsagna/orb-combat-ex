# Park: crater-refused (VFX, 2026-11-23, finished 2026-11-25): READY, applies last on the GW1c stack

World's GW1c crater rule refuses the dig for a blow that lands on or near an earlier crater: `_dig` returns null (sim/world/crater.gd:304-305) before it emits `crater`, so a refused slam lost the crater's ejecta arc and rim dust (the contact's own dust, chips and rings stay). This plays them from a refusal event at a share of the crater's.

**Built on the GW1c stack** (a copy of the EP's s436), render only, nothing writes the sim. Five files, patch sha1 c6931f4793e9f876508fe3d1f462a4116f61525c (apply.patch):
- `render/vfx/earth.gd`: `on_crater_refused(e, S)`; `on_crater_ejecta` takes a strength (`count_k`, `speed_k`, minimums), and a refused crater skips the biome column (the contact slam's own is the picture). No bowl, no cracks, no holes, no blast tier-amp.
- `render/vfx/vfx_hub.gd`: `case "crater_refused"` beside `crater`.
- `data/vfx/earth.json` group `refused` (count_k 0.5, speed_k 0.8, min_chunks 2, min_dust 3) and its schema in `tools/schemas/vfx-earth.schema.json`.
- `render/vfx/tools/effects_check.gd`: `_crater_refused`, eight rows.

**The event (confirmed):** World's `crater_refused` (`SimFx.craterRefused`; `docs/world/pending/globe-step2/bury-refused.md`): `x`, `y`, `z`, `r` (the blow's radius), `depth` (the dent already there), `energy`, `cause`. The handler reads `x`, `y`, `energy`, `r` and `z`; `depth` and `cause` are not used. No change to the code was needed once the event existed.

**Apply:** last, after the 28 pieces of `docs/ep/reviews/GW1c-stack.txt` (clean there; the patch reverses clean on that tree).

**Checks** on that stack with this park last (`docs/vfx/runs/7720b10b/crater-refused.txt`): `validate` 325 files, 0 errors; `effects_check` 1,190 ok, 0 failing (the eight new rows: 17 pieces against a crater's 31; no column, star, cracks or holes; same bits twice; nothing with earth off; a small blow throws 6); `hash_check` with its default seeds passes (985 s).

**The look gate** (planet 7, default look: Reduce flashing on; World's repeated-slam scene, six slams on one spot; before = the stack without this park): `docs/vfx/img/crater-refused/` (pictures git-ignored: they show the fighters): stills at ticks 138, 148, 238, 338, 358 and `repeated-slam-reduced.gif` (ticks 120 to 360). The first slam still digs and the two builds are pixel-identical there. On every refused slam the build with this park throws more clods and dust off the spot. **The honest size of it: modest.** The contact's own dust column, clods and ring already carry most of the hit; this adds a visible scatter of earth around the buried fighter, more on the early slams than on the later ones where loose chips are already lying about. He reads as hit and held in the bowl on both sides; this does not hide him (chunks and puffs are small and behind or beside him). If Orb wants it bigger, `data/vfx/earth.json` `refused.count_k` (0.5) is the one number.

**Flash** (the same scene, 700 ticks, Tools' analyser): reduced before 1, after 1; normal before 2, after 2; all four PASS.
