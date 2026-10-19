# The minimal HUD (parked, behind `minimal_hud`, off)

Account, audit and pictures: `docs/ui/minimal-hud.md`. Apply from the repo root: `patch -p1 < docs/ui/pending/minimal-hud/minimal-hud.patch` (a dry run is clean on main with the grey-circles park in). Then set `minimal_hud` to true in `ui/data/features.json` once Orb has seen the pictures.

Files: `ui/core/ui_event_hub.gd` (the cue caption's state; no CHAIN banner), `ui/data/features.json`, `options.json` (Cue captions), `settings.json`, `terms.json` (two caption lines), `ui/hud/ui_hud.gd` (the switches, the caption layer), `ui/widgets/ui_incoming.gd`, `ui_pause.gd` (the toll on the pause screen), `ui_plate.gd` (the trimmed plate), `ui_split.gd` (the chips on the bottom edge, the pointer only while he is off screen), `ui/tools/hud_check.gd` (`_minimal_hud_rules`, 16 checks).
