# VFX's 7.3 ms HUD frame near tick 1546 (seed 4): not reproduced, and what the HUD costs (UI, 2026-10-17)

Owner: UI & UX. VFX's hitch probe (`docs/vfx/pending/warm-and-cat`) timed the HUD at 7.3 ms around tick 1,546 of seed 4. I looked for it with a new headless tool, `ui/tools/hud_hitch.gd` (in the tree): it plays AI against AI through the real sim host, one tick a frame, with a moving anchor for each fighter, and times each tick's `hud.consume_all` (the events), `UiSimBridge.patch`, the feed and `UiHud.advance`, and prints the median, the worst frames with what the HUD was doing, and a window around any tick (`--around=1546`).

**Result: the HUD does not spike at tick 1546.** Three runs, same seed:

| | Median (patch + feed + advance + events) | p99 | Tick 1546 (two hits that tick: a spark, a shake and a damage event for each) |
| :--- | ---: | ---: | ---: |
| run 1 | 0.57 ms | 1.14 ms | 0.60 ms |
| run 2 | 0.55 ms | 1.12 ms | 0.47 ms |
| run 3 | 0.63 ms | 1.60 ms | 0.85 ms |

Its neighbours, 1,542 to 1,550, are all 0.35 to 0.91 ms. **The slow frames in each run land on different ticks** (run 1: ticks 86, 0, 90; run 2: 122, 0, 867; run 3: 730, 1,396, 746; in other runs 256, 423, 1,137), 3 to 9 ms, each in a different part (the bridge's patch, the feed, `advance` or the event consume) and with no event in common: that is the machine (a busy PC, a garbage-collection pause or a preempted thread), not a HUD cost tied to a tick. The one frame that is slow every time is tick 0: 2.5 to 3.2 ms of script and 6 to 8 ms of first drawing (every layer draws for the first time and the font's glyphs are cached), which the game hides behind its opening.

**So the 7.3 ms in the probe is, most likely, one such frame landing near 1,546 in that run.** To be sure, VFX can run the probe three times and see whether the 7.3 moves (this is what moved here). If it stays at 1,546 in their probe, then the HUD's share there is something the probe times that mine does not (the HUD's *drawing*, which headless Godot cannot time: the layers' redraw is the engine's), and the layer cut with `hud_cache` on is the right instrument (`docs/ui/hud-cache.md`).

**What the HUD does cost, steadily:** 0.5 to 0.6 ms of script a frame (the bridge's patch about 0.2 to 0.3 ms of it, advance about 0.2 to 0.3 ms), a layer redraw on about one frame in six for each plate and on one in ten for the cards, the YOU marker and the legend, and nothing at rest.
