# Reduce flashing locked on (parked, behind `lock_reduce_flashing`)

Full account: `docs/ui/reduce-flashing-lock.md`. Legal's addendum 10 (RL-156): until full effects have a recorded pass, the interim build shows no Reduce flashing toggle and ignores a saved Off. When the toggle is shown, it carries "Turning it off restores full effects, which flash more."

Apply from the repo root: `patch -p1 < docs/ui/pending/rf-lock/rf-lock.patch` (a dry run is clean on HEAD, and before or after the launch-anywhere, run-mode, hud-cache and run-boons parks). The flag is off in the patch; set `lock_reduce_flashing` to true in the interim site's `ui/data/features.json`.

Files: `ui/core/ui_data.gd` (`rf_locked`), `ui/data/features.json`, `options.json`, `terms.json`, `ui/hud/ui_hud.gd`, `ui/widgets/ui_menu.gd`, `ui_settings.gd`, `ui/tools/hud_check.gd` (`_rf_lock_rules`). Not touched: `render/tools/flash_capture.gd` (the capture hook sets the option directly and must keep doing so).
