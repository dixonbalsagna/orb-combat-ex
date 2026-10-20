# The minimal HUD, on (parked)

Account: `docs/ui/minimal-hud.md` section 6. Apply from the repo root after the minimal-hud park: `patch -p1 < docs/ui/pending/minimal-hud-on/minimal-hud-on.patch` (a dry run is clean on main). It sets `minimal_hud` to true in `ui/data/features.json` and makes `hud_check` switch-aware (4,769 checks, 0 failed with it on).

Files: `ui/data/features.json` (the flip), `terms.json` (three hint lines), `ui/core/ui_event_hub.gd` (the launch hint is plain), `ui/hud/ui_hud.gd` (the compact legend, the demo hint, Orb's two hints), `ui/widgets/ui_hints.gd` (compact rows), `ui_incoming.gd` (the chip on the pane's bottom), `ui_reads.gd` (plain hints), `ui/tools/hud_check.gd`.
