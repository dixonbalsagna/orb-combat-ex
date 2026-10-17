# The HUD's texture cache (parked, UI, 2026-10-17)

`docs/ui/hud-cache.md`: read it first; it says plainly what is and is not proved. Behind `features.json` `hud_cache` (**off**). **Not applied.** Apply after `launch-anywhere` and `run-mode`:

```bash
patch -p1 --dry-run < docs/ui/pending/hud-cache/hud-cache.patch
patch -p1 < docs/ui/pending/hud-cache/hud-cache.patch
```

Rendering's one line (`render/core/main.gd`, `render_view()`: drop `ui_hud.queue_redraw()`, and redraw the greybox HUD every frame only in the legacy view and six times a second otherwise) is a separate patch for Rendering, `main-redraw.patch` (24 lines, dry run clean).

**Pixel match: proved** (seven cases, 0 pixels over 2 of 255, with a positive control; `docs/ui/hud-cache.md` section 5). **Open:** Performance's layer cut (the HUD's draw calls with the switch on; target 60). The switch stays off until it is read.

Files: `ui/hud/ui_layer.gd` (the cache), `ui/hud/ui_hud.gd` (the layers' rectangles), `ui/data/features.json`, `ui/demo/hud_demo.gd` (`cache`, `hold`), `ui/tools/hud_layers.gd`, `png_diff.mjs`, `hud_cache_stills.mjs`, `hud_check.gd` (`_hud_cache_rules`, 8 checks).
