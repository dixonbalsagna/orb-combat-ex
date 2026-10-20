# The full-charge hint where it is true, and the caption's hold (parked)

Account: `docs/ui/minimal-hud.md` section 7. Apply after `docs/ui/pending/minimal-hud-on/`: `patch -p1 < docs/ui/pending/minimal-hud-hints/minimal-hud-hints.patch` (a dry run is clean). Files: `ui/hud/ui_hud.gd` (the hint's condition; the caption's 0.8 s hold) and `ui/tools/hud_check.gd` (a medium and a ready launcher stay silent; the caption holds then goes).
