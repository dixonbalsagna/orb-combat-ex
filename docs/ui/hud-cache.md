# The HUD's draw calls: a texture cache for the steady layers (UI, 2026-10-17)

Owner: UI & UX. **Built in scratch and parked, behind `features.json` `hud_cache` (off).** Against Performance's audit (`docs/perf/audit-2026-10-16.md`, af5151b5, hot spot 1): in the web build the HUD is **344 of 364 draw calls and 1.3 of 2.4 ms of drawing** (330 of 382 and 1.1 of 2.5 ms in the beam scene); the budget is **60 HUD draw calls and 0.5 ms**.

**Status, in one paragraph (2026-10-17, after the quiet window).** The mechanism, its switch, its tests and the proof tools are done and gated. **The pixel match is proved:** the same frame of the HUD demo, drawn directly and through the cache, differs by **0 pixels over a tolerance of 2 (of 255), and by 2 at most**, in all seven cases (desktop with and without the legend, a phone on its side, a phone upright, the toll chip with a count, the Empress against the Cyborg, the stress scenario), with a positive control (below). **The draw-call count is still not measured:** that is Performance's layer cut with `hud_cache` on (section 6); the switch stays off until it reads under the target.

## 1. Why the layers cost what they cost

Godot keeps a node's draw commands until the node is asked to redraw, so the HUD's cached layers already cost no GDScript at rest (`UiLayer`: a signature, and a redraw only when it changes). **That saves script time, not draw calls:** every retained command is still submitted to the GPU every frame. A plate is a dozen rectangles, a stripe texture, a score of text runs and the pips; each text run and each polygon is its own batch in the Compatibility renderer. So the number of draw calls is the number of retained commands in the layers that are showing, redrawn or not.

**What a real brawl shows** (`ui/tools/hud_layers.gd`, AI against AI through the real sim host with moving anchors, 1,439 frames, seed 4, headless; no renderer, so no draw calls: only how often each layer redraws and how often it has something to draw):

| Layer | Redraws | Of frames | Has something to draw |
| :--- | ---: | ---: | ---: |
| Plate, fighter 1 and 2 | 244, 230 | 17%, 16% | 100% |
| The YOU marker | 158 | 11% | 100% |
| The legend, fighter 1 | 152 | 11% | 62% |
| Cards, barks, banners | 141 | 10% | 10% |
| The beam struggle's tug | 47 | 3% | 25% |
| The prompt row, fighter 1 | 13 | 1% | 91% |
| The toll chip | 1 | 0% | 100% |
| The join note | 0 | 0% | 100% |

On average **6.9 layers are showing on a frame**, and **most of what they hold is the same frame after frame**: the plates redraw on one frame in six, the toll chip once in the whole run. (This scenario has no split record, so the strip, the ring map and the silhouettes, which the web build also draws, are not in it.) The 344 calls are therefore a few dozen commands in each of about a dozen steady layers.

## 2. The mechanism

**A steady layer is painted into a small texture when its signature changes and drawn as one textured rectangle every frame.**
- `UiLayer` gets an optional `rect_fn` (the layout's rectangle for the layer). With `hud_cache` on, a layer that has one paints its painter, unchanged, into a `SubViewport` the size of that rectangle (grown by 16 px so an edge or ring that overhangs it is kept), updates the viewport once, and draws its texture in a single `draw_texture_rect`. **A layer of fifty commands becomes one.**
- The painter does not know. It is called with a canvas the size of the layer, in the layer's own coordinates; the viewport's canvas transform shifts the picture so only the rectangle is captured.
- The texture holds premultiplied colour (a transparent viewport), so the rectangle is drawn with a premultiplied-alpha material: translucent plates and text edges composite as they do directly, to within one level of rounding.
- **Nothing is repainted at rest:** a layer repaints when its signature changes (the same signature that decides a redraw today) or the layout changes.
- **Which layers:** the two plates, the toll chip, the two prompt rows, the two legends, the two silhouettes, the strip's base and the ring map's base: the ones whose picture is stable and bounded. Each rectangle is the layout's (`plate[i]`, `toll`, `prompts[i]`, `hints[i]`, `silhouette[i]`, `strip`, `ring`).
- **Not cached, on purpose:** the layers that follow a fighter (the YOU marker, the crown, the beat ring, the edge chips, the tug, the many-body markers) and the full-screen ones (cards, barks, the overlays), whose picture or place changes most frames or whose rectangle is the whole screen. A layer whose rectangle is over 400,000 px is never cached.
- **Memory:** every cached rectangle together is under 2 million pixels at the five sizes tested (about 8 MB at most; 1.5 to 1.65 million on the 1080p and the dense-phone sizes, well under a million at 720p). Performance's audit puts the page at 495 to 537 MB, so this is under 2%.

**Phase two (not built):** the layers that follow a fighter can be cached too, by painting them around their own origin and moving the texture's sprite instead of repainting. That needs each painter's signature split into "what it looks like" and "where it is"; it is a separate window.

## 3. What is proved today, and how

- **`hud_check` stays green with the switch off** (4,727 checks on the scratch copy with this patch alone, 4,758 with all three parks of this round stacked; the layers' normal path is unchanged), and **a new `_hud_cache_rules` (8 checks) runs with the switch on:** the layer paints into a texture; its words are drawn through the texture's canvas as through the layer (headless does run the viewport's canvas, so the painters really run); thirty still frames repaint it at most once and a state change repaints it; every cached rectangle holds its layout's and stays on screen; the total memory is bounded; a full-screen layer is not cached; switching off returns to direct drawing.
- **`determinism`, plain and `--intro`, `hud_words_check` and `pane_check`** pass.

## 4. What is not proved, and the risks

- **Pixel identity: proved** on the seven cases above (section 5). A painter that draws further than its 16 px margin in a case the stills do not show would be clipped; the cases cover the plates, the legend, the prompts, the toll chip, the silhouettes and the strip.
- **The cost of the extra passes.** Each repaint is a render pass into a texture. At one plate repaint in six frames that is cheap, but a layer that changes every frame (not the cached ones today) would cost more than it saves; the cache list is chosen from the redraw counts above for that reason.
- **The web build's Compatibility renderer** supports render targets, but a render-target switch is not free on a phone's GPU. Performance's layer cut on the integrated Radeon and a phone decides whether the saving holds there.
- **If it fails,** the switch is off and the HUD is as it is.

## 5. The pixel proof (done, 2026-10-17)

`ui/tools/hud_cache_stills.mjs` took the same frame of the HUD demo twice per case (`?cache` off and on; `at=` fast-forwards the mock feed and `hold` stops its clock) from a web export of the demo scene, with `tools/machine/capture.mjs` (software rendering, one capture at a time), and `ui/tools/png_diff.mjs` compared them pixel by pixel:

| Case | Size | Pixels over 2 of 255 | Largest difference |
| :--- | :--- | ---: | ---: |
| desktop, no legend | 1280x720 | 0 of 921,600 | 2 |
| desktop, with the legend | 1280x720 | 0 | 2 |
| phone on its side | 844x390 | 0 of 329,160 | 2 |
| phone upright | 390x844 | 0 of 329,160 | 2 |
| the toll chip with a count | 1280x720 | 0 | 2 |
| the Empress against the Cyborg | 1280x720 | 0 | 2 |
| the stress scenario | 1280x720 | 0 | 2 |

**The positive control:** the same frame with the cached layers tinted red on purpose (a scratch-only switch) differs from the direct frame in **66,957 pixels (7%), by up to 179**, so the cache path really is what draws those layers in the web build, and the zero above is a true match and not a flag that never applied. The largest difference of 2 is one level of 8-bit rounding in the premultiplied blend on a translucent edge.

## 6. The draw-call proof, for Performance

With the switch on, re-run the audit's layer cut (section 5 of `audit-2026-10-16.md`: the HUD hidden, then shown, on the city brawl and the beam scene at tick 104) and read the HUD's draw calls: the target is at most 60 and 0.5 ms. `hud_cache` is read from `features.json`; for a scratch export set it true there. **My estimate, which the measurement will confirm or correct:** the cached layers (about ten showing at once) become about ten calls, which leaves the moving layers (the crown, the YOU marker, the chips) as the remainder; whether that is under 60 depends on how many commands those hold. If it is not, phase two caches them.

## 7. For Rendering: one patch

`render/core/main.gd`, `render_view()`: `ui_hud.queue_redraw()` is removed (UiHud draws nothing itself; its layers redraw when their own signature changes, so the call only rebuilt an empty canvas item every frame), and the greybox HUD's `queue_redraw()` runs every frame only in the legacy view (F2) and six times a second otherwise (its text is the key help and the legacy panels, which change slowly). `docs/ui/pending/hud-cache/main-redraw.patch`: 24 lines, a dry run is clean. Rendering owns the file; I did not touch it.

## 8. What is in the park

`docs/ui/pending/hud-cache/` (the patch and a README). Files: `ui/hud/ui_layer.gd` (the cache), `ui/hud/ui_hud.gd` (the layers' rectangles), `ui/data/features.json` (`hud_cache`), `ui/demo/hud_demo.gd` (`cache` and `hold`), `ui/tools/hud_layers.gd` (the redraw counter), `ui/tools/png_diff.mjs`, `ui/tools/hud_cache_stills.mjs`, `ui/tools/hud_check.gd` (`_hud_cache_rules`), and for Rendering `render/core/main.gd` (separate patch).
