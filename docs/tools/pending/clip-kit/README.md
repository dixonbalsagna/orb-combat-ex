# The clip kit: what changed and what lands (Tools, 2026-11-06)

How to use it: `docs/tools/clips.md`. What this file lists is what the EP lands, in order.

## In my own paths (already in the working tree; the EP commits)

| Path | What |
|---|---|
| `tools/clips/` (new) | `make.mjs` (the one command), `clips.json` (the recipes: Orb's eleven GIFs, a self-test, two event examples, the bookmark windows), `encode.py` (Pillow: one palette, size limit, real transparency for unchanged pixels, crop, blur; GIF, PNG sequence, prepared frames), `webm.html` (the browser's own recorder), `mockups/globes.py` and `pan.py`, `clips-selftest.mjs` |
| `render/tools/flash_capture.gd` | The film scenes `chase`, `chargehold`, `towers` and Camera's `beamduel` (with its film camera), in a list of their own, `FILM_SCENES`, so `SCENARIOS` and `AI_SLOTS` stay as `sources.json` has them (`tools/flash/selftest.js` passes, 95 checks); the film words `nohud`, `peak`, `tier`, `power`, `flatout` (a clip with none of them starts with the same empty setup as before); the event log (`window.__flashcap.events`, read only, taken from the host's `drained` signal before it clears); and the `ai` scene stages nothing into a replay of a saved match. The hook exists only with `?flashcap=1`. The 18 existing scenes are unchanged. |
| `tools/preview/blackbox.mjs` | The clip button (F9, or View + RB; a 1.5 s note in the page's corner), the automatic bookmarks (launch, crater, building fall, beam clash end, KO: the host tells the page, reading `S.out.fx`, writing nothing), `marks` in the saved match file, and Encounter's two replay fixes (the playback starts the recorded match itself; the hook's `ai` scene stages nothing into it). Page patch only: the black box is a preview-page feature, nothing in the shipped game or the sim or its hash changes. |
| `docs/tools/clips.md`, this folder | The plain doc for Orb, and this note |

## Camera's park (granted by the EP)

`camera-rest.patch` here is Camera's `docs/camera/pending/clip-scenes/clip-scenes.patch` without its `flash_capture.gd` hunk (that hunk is folded into the hook above): the `render/core/main.gd` and `render/core/sim_host.gd` hunks only (`film_cam`, `film_in`). It applies on HEAD 72a4d1e4. **Land it with the hook:** the hook sets `film_cam` and `film_in` through `set(...)`, so it compiles without them, and `beamduel` does nothing until they are in.

## Proof

- `node tools/clips/clips-selftest.mjs`: the recipes, the event names, the encoder, and the `selftest` clip end to end on the kept build `orb-first-play-10d8b8cf-68ee07cc`.
- On a test export of HEAD + the hook + Camera's rest (key 8e361bc5...): `charged-strike`, `chase` and `beam-clash-1-low-side-on` made (528, 539 and 434 KB, flash PASS); the event window `first-launch` found its launch from the sim's events and cut 60 ticks before to 90 after (530 KB); a match recorded on that page got its bookmarks and an F9 mark (`marks` in the replay's page state), and `--from-match` cut three GIFs (527, 553, 538 KB, flash PASS) and a 15-second WebM (2 MB, the browser's recorder) from them.
- Not run: the replay's checkpoint compare (the test match had no checkpoints: it was read mid-match); the recipes on a build with the film scenes AND the parks they show (chase tap, power, tiles): the test export has none of the parks, so `chase`, `top-power-towers` and the beam clash look as a plain HEAD plays them. Re-run `node tools/clips/make.mjs all` on the next kept build.

## Notes for the EP

- The v6 patch (`docs/tools/pending/preview-stack-v6/`) has its own copy of `blackbox.mjs`: its hunks need a re-cut on top of this one (the marks block and the two replay fixes are new here; v6 carries the replay fixes too, so those hunks will report as already applied).
- No CI line added: `clips-selftest.mjs` needs Pillow and a kept build, neither of which the CI runner has. `--no-e2e` runs its first half anywhere with Pillow.
