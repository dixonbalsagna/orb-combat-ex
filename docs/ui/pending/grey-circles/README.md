# The two grey circles, cut (parked, behind `tug_rings` and `ring_map`, both off)

Account and findings: `docs/ui/grey-circles.md`. Apply from the repo root: `patch -p1 < docs/ui/pending/grey-circles/grey-circles.patch` (a dry run is clean on HEAD, and before or after launch-anywhere, run-mode, hud-cache and run-boons).

Files: `ui/data/features.json` (two flags, off), `ui/hud/ui_hud.gd` (the ring map's layers need `ring_map`), `ui/widgets/ui_tug.gd` (the steady rings need `tug_rings`; the bar moves closer without them), `ui/tools/hud_check.gd` (the older ring-map rules run with the switch on; `_cut_rules`).
